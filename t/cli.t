use strict;
use warnings;
use Test::Most;

use File::Spec;
use FindBin qw($Bin);

use lib 't/lib';
use TestSync;

my $root = File::Spec->catdir($Bin, '..');
my $perl = $^X;
my $filesync = File::Spec->catfile($root, 'bin', 'filesync');
my $admin = File::Spec->catfile($root, 'bin', 'filesync-admin');

my $env = TestSync->new_env();
$env->write_file('client', 'a.txt', "alpha\n", 1_700_000_000);

my $output = `$perl $filesync sync --repo docs 2>&1`;
is($?, 0, 'filesync sync exits 0');
like($output, qr/docs: pulled 0, pushed 1/, 'sync reports what it did');

$output = `$perl $filesync sync --repo docs 2>&1`;
is($?, 0, 'a second run exits 0');
like($output, qr/docs: pulled 0, pushed 0/, 'a second run has nothing to do');

$output = `$perl $filesync version 2>&1`;
is($?, 0, 'version exits 0');
like($output, qr/filesync \d/, 'version is printed');

$output = `$perl $filesync status --json 2>&1`;
is($?, 0, 'status exits 0');
like($output, qr/"repo":"docs"/, 'status is valid JSON mentioning the repo');

$output = `$perl $admin --root $env->{server} repo list 2>&1`;
is($?, 0, 'admin repo list exits 0');
like($output, qr/^docs$/m, 'the repo is listed');

$output = `$perl $filesync sync --repo nosuchrepo 2>&1`;
isnt($?, 0, 'an unknown repo is an error');
like($output, qr/No repo 'nosuchrepo'/, 'the error names the repo');

$output = `$perl $filesync sync --dry-run 2>&1`;
is($?, 0, 'a dry run with nothing to do exits 0');

done_testing();
