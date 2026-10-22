use strict;
use warnings;
use Test::Most;

use File::Spec;
use FindBin qw($Bin);

use lib 't/lib';
use TestSync;

use App::FileSync::Admin;

my $env = TestSync->new_env();
my $admin = App::FileSync::Admin->new(root => $env->{server});

sub events {
    my (%args) = @_;
    return $admin->journal_read(repo => 'docs', %args);
}

sub actions {
    return [ map { $_->{action} } @{ events(@_) } ];
}

# A quiet repo journals nothing beyond what happened.
is_deeply(actions(), [], 'a fresh repo has no journal entries');

# --- push, then delete ----------------------------------------------------

$env->write_file('client', 'a.txt', "alpha\n", 1_700_000_000);
$env->write_file('client', 'dir/b.txt', "beta\n", 1_700_000_000);
my $result = $env->sync();
is($result->{summary}{pushed}, 2, 'two files were pushed');

my $pushed = events();
ok(@{$pushed}, 'the sync was journalled');

my @push_events = grep { $_->{action} eq 'push' } @{$pushed};
is(scalar @push_events, 2, 'both pushes are journalled');

for my $event (@push_events) {
    ok(defined $event->{ts} && $event->{ts} =~ /\A\d+\z/, "$event->{path} has a timestamp");
    is($event->{client}, 'test-1', "$event->{path} names the client");
    like($event->{sha256}, qr/\A[0-9a-f]{64}\z/, "$event->{path} records the hash");
    ok($event->{size} > 0, "$event->{path} records the size");
}

my ($session) = grep { $_->{action} eq 'session' } @{$pushed};
ok($session, 'the session is journalled');
is($session->{pushed}, 2, 'the session summary counts the pushes');
ok(!$session->{dry_run}, 'a real run is not marked as a dry run');

is_deeply(
    [ sort map { $_->{path} } @push_events ],
    [ 'a.txt', 'dir/b.txt' ],
    'the journalled paths are the ones that were pushed',
);

unlink $env->client_path('dir/b.txt');
$result = $env->sync();
is($result->{summary}{deleted}, 1, 'the deletion was propagated');

my ($deleted) = grep { $_->{action} eq 'delete' } @{ events() };
ok($deleted, 'the deletion is journalled');
is($deleted->{path}, 'dir/b.txt', 'the deleted path is recorded');
like($deleted->{trash}, qr{dir/b\.txt\z}, 'the journal records where it was trashed');

# --- a conflict is journalled with both sides -----------------------------

$env->write_file('server', 'a.txt', "server version\n", 1_700_000_200);
$env->write_file('client', 'a.txt', "client version\n", 1_700_000_900);

$result = $env->sync();
is($result->{summary}{conflicts}, 1, 'the two edits conflicted');
is($result->{exit}, 3, 'a conflict exits 3');

my ($conflict) = grep { $_->{action} eq 'conflict' } @{ events() };
ok($conflict, 'the conflict is journalled');
is($conflict->{path}, 'a.txt', 'the conflicted path is named');
is($conflict->{winner}, 'client', 'the newer client version won');
like($conflict->{loser_name}, qr{a\.conflict-test-1-\d{8}T\d{6}Z\.txt\z},
    'the conflict copy is named in the journal');
like($conflict->{winner_sha256}, qr/\A[0-9a-f]{64}\z/, 'the winner hash is recorded');
like($conflict->{loser_sha256}, qr/\A[0-9a-f]{64}\z/, 'the loser hash is recorded');
ok($conflict->{winner_mtime} > $conflict->{loser_mtime},
    'both mtimes are recorded and the winner is the newer one');

my ($copy) = grep { $_->{action} eq 'conflict_copy' } @{ events() };
ok($copy, 'the preserved copy is journalled');
is($copy->{from}, 'a.txt', 'the copy names the original path');

# --- filtering ------------------------------------------------------------

is_deeply(events(client => 'someone-else'), [], 'another client has no events');
is_deeply(events(since => time + 86_400), [], 'nothing happened in the future');
ok(scalar @{ events(since => 1) } > 0, 'a past --since matches everything');
is(scalar @{ events(limit => 2) }, 2, 'the limit is applied');
is((events(limit => 2))->[1]{action}, (events())->[-1]{action},
    'the limit keeps the newest events');
is_deeply(events(since => '2999-01-01'), [], 'a date --since is accepted');

throws_ok { events(since => 'last tuesday') } qr/Bad --since/,
    'a nonsensical --since is refused';

# --- a dry run neither changes anything nor writes to the journal -------

$env->write_file('client', 'dry.txt', "dry\n", 1_700_001_000);
my $before = scalar @{ events() };

$result = $env->sync(dry_run => 1);
is($result->{exit}, 0, 'the dry run succeeded');
ok(!$env->exists_in('server', 'dry.txt'), 'the dry run pushed nothing');

is(scalar(@{ events() }), $before, 'the dry run wrote no journal entries');
my ($planned) = grep { $_->{p} eq 'dry.txt' } @{ $result->{actions} };
ok($planned && $planned->{a} eq 'push', 'the dry run planned the push it did not do');

# --- filesync-admin log ---------------------------------------------------

my $perl = $^X;
my $admin_bin = File::Spec->catfile($Bin, '..', 'bin', 'filesync-admin');
my $output = qx{$perl $admin_bin --root $env->{server} log docs 2>&1};
is($?, 0, 'filesync-admin log exits 0');
like($output, qr/\d{8}T\d{6}Z\s+test-1\s+conflict\s+a\.txt/, 'log shows the conflict');
like($output, qr/\d{8}T\d{6}Z\s+test-1\s+push\s+a\.txt/, 'log shows the push');
like($output, qr/winner=client/, 'log shows who won');
like($output, qr/loser=a\.conflict-test-1-/, 'log shows the conflict copy');

$output = qx{$perl $admin_bin --root $env->{server} log docs -n 1 2>&1};
is(scalar(grep { /\d{8}T\d{6}Z/ } split /\n/, $output), 1, '-n 1 prints one entry');

$output = qx{$perl $admin_bin --root $env->{server} log docs --client nobody 2>&1};
like($output, qr/No journal entries/, 'a filter that matches nothing says so');

done_testing();
