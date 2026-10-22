use strict;
use warnings;
use Test::Most;

use File::Spec;
use FindBin qw($Bin);

use lib 't/lib';
use TestSync;
use App::FileSync;
use App::FileSync::Config;
use App::FileSync::Lock;
use App::FileSync::Store;

my $T0 = 1_700_000_000;
my $filesync = File::Spec->catfile($Bin, '..', 'bin', 'filesync');

# ------------------------------------------------------- recording runs
{
    my $env = TestSync->new_env();
    $env->write_file('client', 'a.txt', "alpha\n", $T0);

    my $empty = $env->log();
    is(scalar @{ $empty->{runs} }, 0, 'nothing has been recorded yet');
    ok(!-e $empty->{path}, 'there is no log file until the first run');

    my $first = $env->sync();
    is($first->{summary}{pushed}, 1, 'the first run pushes a file');

    my $log = $env->log();
    is(scalar @{ $log->{runs} }, 1, 'the run is recorded');
    is($log->{runs}[0]{exit}, 0, 'the exit code is recorded');
    is($log->{runs}[0]{summary}{pushed}, 1, 'the summary is recorded');
    is($log->{runs}[0]{summary}{pulled}, 0, 'zero counts are kept');
    ok($log->{runs}[0]{ts} > 0, 'a timestamp is recorded');
    ok(!$log->{runs}[0]{dry_run}, 'a real run is not marked as a dry run');
    is_deeply($log->{runs}[0]{warnings}, [], 'a quiet run has no warnings');

    $env->sync();
    is(scalar @{ $env->log()->{runs} }, 2, 'a second run is appended');
    is($env->log()->{runs}[-1]{summary}{pushed}, 0, 'the newest run is last');

    # A killed run can leave a torn line; the rest of the log still counts.
    open my $fh, '>>', $log->{path} or die $!;
    print {$fh} '{"ts":';
    close $fh;
    is(scalar @{ $env->log()->{runs} }, 2, 'a torn final line is ignored');

    $env->write_file('client', 'a.txt', "changed\n", $T0 + 100);
    my $dry = $env->sync(dry_run => 1);
    ok($dry->{dry_run}, 'the dry run happened');

    my $after_dry = $env->log()->{runs}[-1];
    ok($after_dry->{dry_run}, 'a dry run is recorded as such');
    is($after_dry->{summary}{pushed}, 1, 'the planned actions are counted');

    # A conflict run records its warnings, so the log explains an exit 3.
    $env->write_file('server', 'a.txt', "master version\n", $T0 + 200);
    my $conflict = $env->sync();
    is($conflict->{exit}, 3, 'the conflict run exits 3');

    my $last = $env->log()->{runs}[-1];
    is($last->{exit}, 3, 'the warning exit code is recorded');
    is($last->{summary}{conflicts}, 1, 'the conflict is counted');
    ok(@{ $last->{warnings} }, 'the warnings are recorded');
    like(join(' ', @{ $last->{warnings} }), qr/conflict/,
        'the recorded warning names the conflict');
}

# A lock refusal did nothing, but cron tried it, so the attempt is audited.
{
    my $env = TestSync->new_env();
    $env->write_file('client', 'a.txt', "alpha\n", $T0);
    $env->sync();

    my $lock = App::FileSync::Lock::acquire(
        path     => File::Spec->catfile($env->{home}, 'locks', 'docs.lock'),
        nonblock => 1,
    );
    ok($lock, 'the test holds the lock');

    my $blocked = $env->sync();
    is($blocked->{exit}, 2, 'the locked run reports exit 2');
    undef $lock;

    my $runs = $env->log()->{runs};
    is(scalar @{ $runs }, 2, 'the locked attempt is recorded');
    is($runs->[-1]{exit}, 2, 'it is recorded with exit 2');
    ok($runs->[-1]{locked}, 'it is marked as a lock refusal');
    like($runs->[-1]{error}, qr/holds the lock/, 'the reason is recorded');
    is($runs->[-1]{summary}{pushed}, 0, 'a refused attempt counts nothing');

    my $output = `$^X $filesync log --repo docs 2>&1`;
    is($?, 0, 'log prints the refused attempt');
    like($output, qr/exit 2/, 'the refusal is shown with its exit code');
    like($output, qr/holds the lock/, 'the refusal message is shown');

    $output = `$^X $filesync log --repo docs --json 2>&1`;
    my $data = App::FileSync::json_decode($output);
    my $entry = $data->{results}[0]{runs}[-1];
    ok($entry->{locked}, 'the JSON marks the lock refusal');
    like($entry->{error}, qr/holds the lock/, 'the JSON carries the reason');
}

# A run that fails on the server side is an attempt too.
{
    my $env = TestSync->new_env();
    $env->write_file('client', 'a.txt', "alpha\n", $T0);
    $env->sync();

    my $store = App::FileSync::Store->new(root => $env->{server}, repo => 'docs');
    my $server_lock = App::FileSync::Lock::acquire(
        path     => $store->lock_path(),
        nonblock => 1,
    );
    ok($server_lock, 'the test holds the server lock');

    my $blocked = $env->sync();
    is($blocked->{exit}, 2, 'a server-held lock reports exit 2');
    close $server_lock;

    my $last = $env->log()->{runs}[-1];
    is($last->{exit}, 2, 'the server refusal is recorded');
    ok($last->{locked}, 'it is marked as a lock refusal');
    like($last->{error}, qr/holds the lock/, 'the server reason is recorded');
}

# A run that fails before the session starts is recorded with exit 1.
{
    my $env = TestSync->new_env();
    $env->write_file('client', 'a.txt', "alpha\n", $T0);
    $env->sync();

    unlink File::Spec->catfile($env->{client}, '.filesync-root') or die "$!";

    my $error = '';
    eval { $env->sync(); 1 } or $error = $@;
    like($error, qr/\.filesync-root/, 'the run fails on the missing marker');

    my $runs = $env->log()->{runs};
    is(scalar @{ $runs }, 2, 'the failed attempt is recorded');
    is($runs->[-1]{exit}, 1, 'a fatal attempt is recorded with exit 1');
    like($runs->[-1]{error}, qr/\.filesync-root/, 'the recorded entry carries the reason');
    ok(!$runs->[-1]{locked}, 'a configuration failure is not a lock refusal');
    is($runs->[-1]{summary}{pulled}, 0, 'no counts are invented for a failed run');
}

# The log is bounded.
{
    my $env = TestSync->new_env();
    $env->write_file('client', 'a.txt', "alpha\n", $T0);

    local $App::FileSync::Client::LOG_LIMIT = 3;

    $env->sync() for 1 .. 5;

    my $log = $env->log();
    is(scalar @{ $log->{runs} }, 3, 'the log is trimmed to the limit');
    is($log->{runs}[-1]{summary}{pushed}, 0, 'the newest run is kept');

    my $text = App::FileSync::read_text($log->{path});
    my @lines = grep { length } split /\n/, $text;
    is(scalar @lines, 3, 'the file on disk is trimmed too');
}

# ------------------------------------------------------------- the CLI
{
    my $env = TestSync->new_env();
    $env->write_file('client', 'a.txt', "alpha\n", $T0);

    my $output = `$^X $filesync log --repo docs 2>&1`;
    is($?, 0, 'log on a repo that has never run exits 0');
    like($output, qr/docs: no runs recorded/, 'it says there is nothing to show');

    $env->sync();
    $env->sync();

    $output = `$^X $filesync log --repo docs 2>&1`;
    is($?, 0, 'filesync log exits 0');
    my @lines = grep { /^docs / } split /\n/, $output;
    is(scalar @lines, 2, 'both runs are printed');
    like($lines[-1], qr/pushed 0, deleted 0, conflicts 0/, 'the newest run is last');

    $output = `$^X $filesync log --repo docs -n 1 2>&1`;
    is($?, 0, '-n is accepted');
    @lines = grep { /^docs / } split /\n/, $output;
    is(scalar @lines, 1, '-n limits the output');

    $output = `$^X $filesync log --repo nosuch 2>&1`;
    isnt($?, 0, 'an unknown repo is an error');
    like($output, qr/No repo 'nosuch'/, 'the error names the repo');

    $output = `$^X $filesync log --repo docs -n 0 2>&1`;
    isnt($?, 0, 'a zero limit is an error');
    like($output, qr/-n must be positive/, 'the error explains the limit');
}

# Without --repo the log covers every configured repo.
{
    my $env = TestSync->new_env();
    $env->write_file('client', 'a.txt', "alpha\n", $T0);
    $env->sync();

    my $config = App::FileSync::Config::load_client($env->{config_path});
    $config->{repos}{mirror} = { %{ $config->{repos}{docs} } };
    App::FileSync::Config::save_client($config, $env->{config_path});

    my    $output = `$^X $filesync log 2>&1`;
    is($?, 0, 'log with no --repo exits 0');
    like($output, qr/^docs /m, 'the repo with a run is shown');
    like($output, qr/^mirror: no runs recorded$/m, 'the other repo is reported as empty');

    $output = `$^X $filesync log --json 2>&1`;
    is($?, 0, 'log --json with no --repo exits 0');
    my $data = App::FileSync::json_decode($output);
    is(scalar @{ $data->{results} }, 2, 'every configured repo appears in the JSON');
    my ($mirror) = grep { $_->{repo} eq 'mirror' } @{ $data->{results} };
    is_deeply($mirror->{runs}, [], 'a repo that never ran has an empty run list');
    unlike($output, qr/no runs recorded/, '--json prints no human prose');
}

# -------------------------------------------- --since and --json (one repo)
{
    is(App::FileSync::parse_since('1970-01-01'), 0, "a date parses to that day's start");
    is(App::FileSync::parse_since('1700000000'), 1_700_000_000, 'an epoch passes through');
    ok(!defined App::FileSync::parse_since(undef), 'no cutoff means no filter');
    throws_ok { App::FileSync::parse_since('yesterday') } qr/Bad --since 'yesterday'/,
        'an unparseable cutoff is rejected';
    throws_ok { App::FileSync::parse_since('') } qr/Bad --since/, 'an empty cutoff is rejected';

    my $env = TestSync->new_env();
    $env->write_file('client', 'a.txt', "alpha\n", $T0);
    $env->sync();
    $env->sync();

    my $ts = $env->log()->{runs}[0]{ts};

    my $output = `$^X $filesync log --repo docs --json 2>&1`;
    is($?, 0, 'log --json exits 0');
    my $data = eval { App::FileSync::json_decode($output) };
    ok(ref($data) eq 'HASH', 'log --json prints JSON');
    is(scalar @{ $data->{results} }, 1, 'one result per requested repo');
    is($data->{results}[0]{repo}, 'docs', 'the result names the repo');
    like($data->{results}[0]{path}, qr/logs\/docs\.jsonl\z/, 'the result names its file');
    is(scalar @{ $data->{results}[0]{runs} }, 2, 'both runs are in the JSON');
    is($data->{results}[0]{runs}[0]{exit}, 0, 'the exit code is in the JSON');
    is($data->{results}[0]{runs}[0]{summary}{pushed}, 1, 'the counts are in the JSON');
    is_deeply($data->{results}[0]{runs}[0]{warnings}, [], 'warnings are in the JSON');

    $output = `$^X $filesync log --repo docs --json -n 1 2>&1`;
    $data = App::FileSync::json_decode($output);
    is(scalar @{ $data->{results}[0]{runs} }, 1, '-n applies to JSON too');
    is($data->{results}[0]{runs}[0]{ts}, $env->log()->{runs}[-1]{ts},
        '-n keeps the newest run');

    $output = `$^X $filesync log --repo docs --since $ts 2>&1`;
    is($?, 0, '--since accepts an epoch');
    my @lines = grep { /^docs / } split /\n/, $output;
    is(scalar @lines, 2, 'runs at or after the epoch are shown');

    $output = `$^X $filesync log --repo docs --since 0 2>&1`;
    @lines = grep { /^docs / } split /\n/, $output;
    is(scalar @lines, 2, 'epoch zero includes everything');

    my $future = $ts + 3600;
    $output = `$^X $filesync log --repo docs --since $future 2>&1`;
    is($?, 0, 'a cutoff in the future exits 0');
    like($output, qr/docs: no runs recorded/, 'it reports that nothing is that new');

    my @g = gmtime($ts);
    my $today = sprintf('%04d-%02d-%02d', $g[5] + 1900, $g[4] + 1, $g[3]);
    $output = `$^X $filesync log --repo docs --since $today 2>&1`;
    @lines = grep { /^docs / } split /\n/, $output;
    is(scalar @lines, 2, 'a date cutoff starts at midnight UTC');

    $output = `$^X $filesync log --repo docs --since 2999-01-01 2>&1`;
    like($output, qr/no runs recorded/, 'a cutoff beyond every run shows nothing');

    $output = `$^X $filesync log --repo docs --json --since $future 2>&1`;
    is($?, 0, '--json with an empty window exits 0');
    $data = App::FileSync::json_decode($output);
    is_deeply($data->{results}[0]{runs}, [], 'the JSON has an empty run list');
    is($data->{results}[0]{since}, $future, 'the cutoff is echoed in the JSON');
    unlike($output, qr/no runs recorded/, 'even an empty window prints no prose');

    $output = `$^X $filesync log --repo docs --since yesterday 2>&1`;
    isnt($?, 0, 'an unparseable --since is an error');
    like($output, qr/Bad --since 'yesterday'/, 'the error explains the cutoff');
}

# -------------------------------------------- --exit and --until
{
    is(App::FileSync::parse_until('1970-01-01'), 86_399,
        "a date's end is the last second of that day");
    is(App::FileSync::parse_until('1700000000'), 1_700_000_000,
        'an epoch is used as given');
    throws_ok { App::FileSync::parse_until('yesterday') } qr/Bad --until 'yesterday'/,
        'an unparseable end is rejected';

    my $env = TestSync->new_env();
    $env->write_file('client', 'a.txt', "alpha\n", $T0);
    $env->sync();                                  # exit 0

    # exit 2: another run holds the local lock.
    my $lock = App::FileSync::Lock::acquire(
        path     => File::Spec->catfile($env->{home}, 'locks', 'docs.lock'),
        nonblock => 1,
    );
    $env->sync();
    undef $lock;

    # exit 1: the sync root lost its marker.
    my $marker = File::Spec->catfile($env->{client}, '.filesync-root');
    unlink $marker or die "Cannot remove $marker: $!";
    eval { $env->sync() };
    open my $restore, '>', $marker or die "Cannot create $marker: $!";
    print {$restore} "test marker\n";
    close $restore;

    # exit 3: both sides changed the same file.
    $env->write_file('client', 'a.txt', "local change\n", $T0 + 100);
    $env->write_file('server', 'a.txt', "master change\n", $T0 + 200);
    my $conflict = $env->sync();
    is($conflict->{exit}, 3, 'the conflict run exits 3');

    my @all = @{ $env->log()->{runs} };
    is(scalar @all, 4, 'four attempts are recorded');

    my $output = `$^X $filesync log --repo docs --exit 0 2>&1`;
    is($?, 0, '--exit exits 0');
    my @lines = grep { /^docs / } split /\n/, $output;
    is(scalar @lines, 1, '--exit 0 selects only the successful run');

    $output = `$^X $filesync log --repo docs --exit 3 2>&1`;
    @lines = grep { /^docs / } split /\n/, $output;
    is(scalar @lines, 1, '--exit 3 selects the conflict run');
    like($lines[0], qr/conflicts 1/, 'the conflict is visible');

    $output = `$^X $filesync log --repo docs --exit 1 2>&1`;
    @lines = grep { /^docs / } split /\n/, $output;
    is(scalar @lines, 1, '--exit 1 selects the failure');
    like($lines[0], qr/\.filesync-root/, 'the failure message is shown');

    $output = `$^X $filesync log --repo docs --exit 2 2>&1`;
    @lines = grep { /^docs / } split /\n/, $output;
    is(scalar @lines, 1, '--exit 2 selects the lock refusal');
    like($lines[0], qr/holds the lock/, 'the refusal message is shown');

    $output = `$^X $filesync log --repo docs --exit 1 --exit 2 2>&1`;
    @lines = grep { /^docs / } split /\n/, $output;
    is(scalar @lines, 2, '--exit can be repeated');

    $output = `$^X $filesync log --repo docs --exit 9 2>&1`;
    like($output, qr/no runs recorded/, 'an exit code with no runs shows nothing');

    $output = `$^X $filesync log --repo docs --exit 300 2>&1`;
    isnt($?, 0, 'an impossible exit code is an error');
    like($output, qr/--exit must be between 0 and 255/, 'the error explains the range');

    # --until includes the whole day it names and drops anything later.
    $output = `$^X $filesync log --repo docs --until 2999-01-01 2>&1`;
    @lines = grep { /^docs / } split /\n/, $output;
    is(scalar @lines, 4, '--until in the future keeps every run');

    $output = `$^X $filesync log --repo docs --until 1970-01-01 2>&1`;
    like($output, qr/no runs recorded/, '--until in the past keeps nothing');

    my @g = gmtime($all[-1]{ts});
    my $today = sprintf('%04d-%02d-%02d', $g[5] + 1900, $g[4] + 1, $g[3]);
    $output = `$^X $filesync log --repo docs --until $today 2>&1`;
    @lines = grep { /^docs / } split /\n/, $output;
    is(scalar @lines, 4, '--until TODAY includes runs from today');

    $output = `$^X $filesync log --repo docs --since 0 --until 0 2>&1`;
    like($output, qr/no runs recorded/, 'a window before every run shows nothing');

    $output = `$^X $filesync log --repo docs --exit 3 --json 2>&1`;
    my $data = App::FileSync::json_decode($output);
    is(scalar @{ $data->{results}[0]{runs} }, 1, 'the JSON is filtered too');
    is($data->{results}[0]{runs}[0]{exit}, 3, 'the selected run is the conflict');
    is_deeply($data->{results}[0]{exits}, [3], 'the exit filter is echoed');

    $output = `$^X $filesync log --repo docs --until 2999-01-01 --json 2>&1`;
    $data = App::FileSync::json_decode($output);
    is(scalar @{ $data->{results}[0]{runs} }, 4, '--until works with --json');
    ok(defined $data->{results}[0]{until}, 'the cutoff is echoed');
}

done_testing();
