use strict;
use warnings;
use Test::Most;

use Digest::SHA ();
use File::Path qw(make_path);
use File::Spec;

use lib 't/lib';
use TestSync;
use App::FileSync::Protocol;
use App::FileSync::Transport::Local;

my $T0 = 1_700_000_000;

my $env = TestSync->new_env(client_id => 'backup-1', role => 'replica');

# Populate the master (an administrator can drop files in directly).
$env->write_file('server', 'a.txt', "master a\n", $T0);
$env->write_file('server', 'sub/b.txt', "master b\n", $T0 + 1);
make_path(File::Spec->catdir($env->{server}, 'master', 'docs', 'empty'));

my $first = $env->sync();
is($first->{summary}{pulled}, 3, 'replica pulls the files and the empty directory');
is($env->read_file('client', 'a.txt'), "master a\n", 'content mirrored');
ok($env->exists_in('client', 'sub/b.txt'), 'nested file mirrored');
ok($env->exists_in('client', 'empty'), 'empty directory mirrored');

my $again = $env->sync();
is($again->{summary}{pulled}, 0, 'nothing to do on a second run');

# A local edit is overwritten, not pushed.
$env->write_file('client', 'a.txt', "local edit\n", $T0 + 500);
my $overwrite = $env->sync();
is($overwrite->{summary}{pulled}, 1, 'local replica edit is pulled over');
is($overwrite->{summary}{pushed}, 0, 'replica never pushes');
is($env->read_file('client', 'a.txt'), "master a\n", 'master version restored on the replica');
is($env->read_file('server', 'a.txt'), "master a\n", 'master unchanged');
is($overwrite->{exit}, 3, 'the overwrite is reported as a warning');
like(join(' ', @{ $overwrite->{warnings} }), qr/changed on the replica/, 'warning explains the overwrite');

# A file that disappears from the master goes to the replica's trash.
unlink $env->server_path('sub/b.txt');
my $deleted = $env->sync();
is($deleted->{summary}{deleted}, 1, 'replica removes a file the master no longer has');
ok(!$env->exists_in('client', 'sub/b.txt'), 'replica file removed');
my @trash = glob(File::Spec->catfile($env->{home}, 'trash', '*', '*', '*', 'sub', 'b.txt'));
ok(@trash, 'removed replica file is in the local trash');
is(do { local $/; open my $fh, '<', $trash[0] or die $!; <$fh> }, "master b\n", 'trash preserves the content');

# A local extra file is removed as well.
$env->write_file('client', 'rogue.txt', "not on the master\n", $T0 + 600);
my $extra = $env->sync();
is($extra->{summary}{deleted}, 1, 'replica removes a local extra');
ok(!$env->exists_in('client', 'rogue.txt'), 'extra file removed');

# And the replica never pushes even when the master changes.
$env->write_file('server', 'a.txt', "master changed\n", $T0 + 700);
my $pull = $env->sync();
is($pull->{summary}{pulled}, 1, 'master changes reach the replica');
is($env->read_file('server', 'a.txt'), "master changed\n", 'master content untouched by the replica');

# A hostile or confused replica cannot write, even by talking the protocol
# directly: the plan it is given contains no write actions at all.
{
    my $env = TestSync->new_env(client_id => 'backup-2', role => 'replica');
    $env->write_file('server', 'a.txt', "master\n", $T0);

    my $transport = App::FileSync::Transport::Local->new(
        root   => $env->{server},
        repo   => 'docs',
        client => 'backup-2',
        role   => 'replica',
    );

    my $conn = App::FileSync::Protocol->new(
        in  => $transport->reader(),
        out => $transport->writer(),
    );

    $conn->send({
        cmd => 'hello', proto => 2, client => 'backup-2', host => 'test', os => $^O,
        role => 'replica', repo => 'docs', case_insensitive => 0, now => time,
    });
    ok($conn->recv()->{ok}, 'the replica session opens');

    my $content = "evil\n";
    my $sha = Digest::SHA->new(256);
    $sha->add($content);
    my $hash = $sha->hexdigest();

    $conn->send({
        cmd => 'manifest', part => 0, of => 1,
        entries => [
            { p => 'evil.txt', t => 'f', s => length $content, m => $T0, h => $hash, mode => 0644 },
        ],
    });
    ok($conn->recv()->{ok}, 'the manifest is accepted');

    $conn->send({ cmd => 'plan' });
    my $plan = $conn->recv();
    ok($plan->{ok}, 'a plan is produced');
    ok(!(grep { $_->{a} eq 'push' } @{ $plan->{actions} }),
        'a replica plan never contains a push');
    ok(!(grep { $_->{a} eq 'delete_remote' } @{ $plan->{actions} }),
        'a replica plan never deletes from the master');

    $conn->send({
        cmd => 'put', p => 'evil.txt', s => length $content, h => $hash,
        m => $T0, mode => 0644,
    });
    my $reply = $conn->recv();
    ok(!$reply->{ok}, 'the write is refused');
    like($reply->{error}, qr/not in the plan/, 'the refusal explains itself');
    ok(!$env->exists_in('server', 'evil.txt'), 'nothing was written to the master');

    $transport->close();
}

done_testing();
