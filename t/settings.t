use strict;
use warnings;
use Test::Most;
use Test::Exception;

use File::Spec;
use File::Temp qw(tempdir);
use FindBin qw($Bin);

use lib 't/lib';
use TestSync;
use App::FileSync;
use App::FileSync::Config;
use App::FileSync::Settings;
use Log::Abstraction;

my $filesync = File::Spec->catfile($Bin, '..', 'bin', 'filesync');

sub write_json {
    my ($path, $text) = @_;
    open my $fh, '>', $path or die "Cannot write $path: $!";
    print {$fh} $text;
    close $fh;
    return $path;
}

sub slurp {
    my ($path) = @_;
    open my $fh, '<', $path or die "Cannot read $path: $!";
    local $/;
    my $text = <$fh>;
    close $fh;
    return $text;
}

# --------------------------------------------------------------- settings
{
    my $dir = tempdir(CLEANUP => 1);
    my $empty = write_json(File::Spec->catfile($dir, 'empty.json'), "{}\n");

    my $defaults = App::FileSync::Settings::load(config_file => $empty);
    is($defaults->{log_level}, 'warning', 'the default level is warning');
    is($defaults->{log_format}, '%level%: %message%', 'the default format is compact');
    is($defaults->{log_file}, '', 'the default destination is standard error');
    is($defaults->{ssh_identity}, '', 'no identity is imposed on ssh by default');
    is($defaults->{ssh_known_hosts}, '', 'no known-hosts file is imposed by default');
    is($defaults->{server_command}, 'filesync-server',
        'the remote program defaults to filesync-server');

    my $config = write_json(
        File::Spec->catfile($dir, 'configured.json'),
        qq({"App__FileSync":{"log_level":"debug","log_format":"[%level%] %message%","log_file":"/tmp/x.log","ssh_identity":"/home/me/.ssh/id_filesync","ssh_known_hosts":"/home/me/.ssh/known_hosts_filesync"}}\n),
    );

    my $settings = App::FileSync::Settings::load(config_file => $config);
    is($settings->{log_level}, 'debug', 'the file sets the level');
    is($settings->{log_format}, '[%level%] %message%', 'the file sets the format');
    is($settings->{log_file}, '/tmp/x.log', 'the file sets the destination');
    is($settings->{ssh_identity}, '/home/me/.ssh/id_filesync', 'the file sets the identity');
    is($settings->{ssh_known_hosts}, '/home/me/.ssh/known_hosts_filesync',
        'the file sets the known-hosts file');

    local $ENV{App__FileSync__log_level} = 'error';
    my $overridden = App::FileSync::Settings::load(config_file => $config);
    is($overridden->{log_level}, 'error', 'an environment variable beats the file');
    delete $ENV{App__FileSync__log_level};

    local $ENV{App__FileSync__server_command} = '/opt/fs/filesync-server';
    is(App::FileSync::Settings::load(config_file => $config)->{server_command},
        '/opt/fs/filesync-server', 'the environment sets the remote program');

    my $bad = write_json(
        File::Spec->catfile($dir, 'bad.json'),
        qq({"App__FileSync":{"log_level":"loud"}}\n),
    );
    throws_ok { App::FileSync::Settings::logger(config_file => $bad) }
        qr/Invalid log_level 'loud'/, 'an unknown level is rejected';

    is(App::FileSync::Settings::config_file($config), $config, 'an explicit file is used');

    throws_ok { App::FileSync::Settings::load(config_file => '/nonexistent/nope.json') }
        qr/No such file or directory/, 'a missing explicit settings file is reported';

    local $ENV{FILESYNC_SETTINGS} = '/nonexistent/nope.json';
    is(App::FileSync::Settings::config_file(), undef,
        'a settings path from the environment is only used when it exists');
    is(App::FileSync::Settings::load()->{log_level}, 'warning',
        'so a stale environment path falls back to the defaults');
}

# ---------------------------------------------------------------- logger
{
    my $dir = tempdir(CLEANUP => 1);
    my $log = File::Spec->catfile($dir, 'run.log');
    my $config = write_json(
        File::Spec->catfile($dir, 'settings.json'),
        qq({"App__FileSync":{"log_level":"debug","log_file":"$log"}}\n),
    );

    my $logger = App::FileSync::Settings::logger(config_file => $config);
    lives_ok { $logger->error('kept going') } 'error() logs instead of dying';
    $logger->info('an info line');
    $logger->warn('a warning line');

    my $text = slurp($log);
    like($text, qr/^INFO: an info line$/m, 'info reaches the configured file');
    like($text, qr/^WARN: a warning line$/m, 'warnings reach the configured file');
    like($text, qr/^ERROR: kept going$/m, 'errors reach the configured file');

    # --verbose beats a quieter file; --quiet beats a louder one.
    my $quiet_config = write_json(
        File::Spec->catfile($dir, 'quiet.json'),
        qq({"App__FileSync":{"log_level":"warning","log_file":"$log"}}\n),
    );

    my $verbose = App::FileSync::Settings::logger(config_file => $quiet_config, verbose => 1);
    $verbose->info('verbose info');

    my $silent = App::FileSync::Settings::logger(config_file => $config, quiet => 1);
    $silent->info('quiet info');
    $silent->warn('quiet warning');
    $silent->error('quiet error');

    my $after = slurp($log);
    like($after, qr/^INFO: verbose info$/m, '--verbose logs info');
    unlike($after, qr/quiet info/, '--quiet suppresses info');
    unlike($after, qr/quiet warning/, '--quiet suppresses warnings');
    like($after, qr/^ERROR: quiet error$/m, '--quiet keeps errors');
}

# ------------------------------------------------ the client uses the logger
{
    my $env = TestSync->new_env();
    $env->write_file('client', 'a.txt', "alpha\n", 1_700_000_000);

    my @captured;
    my $logger = Log::Abstraction->new(level => 'debug', logger => \@captured);

    my $config = App::FileSync::Config::load_client($env->{config_path});
    my $result = App::FileSync::Client->new(
        config => $config,
        name   => 'docs',
        logger => $logger,
    )->sync();

    is($result->{summary}{pushed}, 1, 'the sync still works with an injected logger');

    my @messages = map { $_->{message} } @captured;
    ok((grep { $_ eq 'plan received' } @messages), 'the plan is logged');
    ok((grep { $_ eq 'sync finished' } @messages), 'the completed run is logged');

    my ($finished) = grep { $_->{message} eq 'sync finished' } @captured;
    is($finished->{level}, 'info', 'a completed run is logged at info');
    is($finished->{fields}{repo}, 'docs', 'the log entry names the repo');
    is($finished->{fields}{pushed}, 1, 'the log entry carries the counts');

    my ($plan) = grep { $_->{message} eq 'plan received' } @captured;
    is($plan->{level}, 'debug', 'the plan is logged at debug');
    is($plan->{fields}{actions}, 1, 'the plan entry counts the actions');
}

# --------------------------------------------------------------- the CLI
{
    my $env = TestSync->new_env();
    $env->write_file('client', 'a.txt', "alpha\n", 1_700_000_000);
    $env->sync();

    my $output = `$^X $filesync sync --repo docs --verbose 2>&1`;
    is($?, 0, 'sync --verbose exits 0');
    like($output, qr/DEBUG: plan received/, '--verbose shows debug logging');
    like($output, qr/INFO: sync finished/, '--verbose shows the run summary in the log');

    $output = `$^X $filesync sync --repo nosuch 2>&1`;
    is($? >> 8, 1, 'a fatal error exits 1');
    like($output, qr/ERROR: No repo 'nosuch'/, 'fatal errors go through the logger');

    my $dir = tempdir(CLEANUP => 1);
    my $settings = write_json(
        File::Spec->catfile($dir, 'settings.json'),
        qq({"App__FileSync":{"log_level":"debug"}}\n),
    );

    local $ENV{FILESYNC_SETTINGS} = $settings;
    $env->write_file('client', 'a.txt', "changed\n", 1_700_000_100);

    $output = `$^X $filesync sync --repo docs 2>&1`;
    is($?, 0, 'a configured debug level still exits 0');
    like($output, qr/INFO: sync finished/, 'the settings file raises the log level');

    $output = `$^X $filesync sync --repo docs --quiet 2>&1`;
    is($?, 0, '--quiet exits 0');
    unlike($output, qr/INFO: sync finished/, '--quiet wins over the settings file');
}

done_testing();
