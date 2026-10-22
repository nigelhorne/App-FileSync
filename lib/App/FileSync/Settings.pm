package App::FileSync::Settings;

use strict;
use warnings;

use File::Basename qw(dirname);
use File::Path qw(make_path);
use File::Spec;
use Log::Abstraction;
use Object::Configure;

# Process-wide settings live in Object::Configure; the repos themselves stay in
# ~/.filesync/config.json, which "filesync init" writes and the admin tool edits.
our $DEFAULT_FORMAT  = '%level%: %message%';
our $DEFAULT_LEVEL   = 'warning';
our $CONFIG_BASENAME = 'app-filesync.json';

# Defaults for every SSH repo.  A repo's own config still wins, so one machine
# can point at another identity without repeating the common settings.
our $DEFAULT_SERVER_COMMAND = 'filesync-server';

our @VALID_LEVELS = qw(
    trace debug info informational notice warn warning error err
    crit critical fatal alert emerg emergency panic
);

sub _default_config_path {
    my $path = $ENV{FILESYNC_SETTINGS};
    return $path if defined $path && length $path;

    my $home = $ENV{HOME};
    $home = $ENV{USERPROFILE} if !defined $home || !length $home;
    return undef unless defined $home && length $home;

    return File::Spec->catfile($home, '.conf', $CONFIG_BASENAME);
}

sub config_file {
    my ($given) = @_;

    return $given if defined $given && length $given;

    my $path = _default_config_path();
    return undef unless defined $path && length $path;
    return -e $path ? $path : undef;
}

# Merge the settings file (if any), the UNIVERSAL section and the
# App__FileSync__* environment variables over the built-in defaults.
sub load {
    my (%args) = @_;

    my $config_file = exists $args{config_file}
        ? config_file($args{config_file})
        : config_file();

    my %params = (
        log_level       => $DEFAULT_LEVEL,
        log_format      => $DEFAULT_FORMAT,
        log_file        => '',
        ssh_identity    => '',
        ssh_known_hosts => '',
        server_command  => $DEFAULT_SERVER_COMMAND,
        # We build the logger ourselves; this keeps Object::Configure from
        # constructing its default Log::Log4perl backend as a side effect.
        logger     => [],
    );

    $params{config_file} = $config_file if defined $config_file && length $config_file;
    $params{config_dirs} = $args{config_dirs} if ref($args{config_dirs}) eq 'ARRAY';

    my $settings = Object::Configure::configure('App::FileSync', \%params);
    delete $settings->{logger};

    return $settings;
}

sub logger {
    my (%args) = @_;

    my $settings = load(%args);

    my $level = defined $args{level} && length $args{level}
        ? $args{level}
        : (defined $settings->{log_level} && length $settings->{log_level}
            ? $settings->{log_level}
            : $DEFAULT_LEVEL);

    die "Invalid log_level '$level' (want " . join(', ', @VALID_LEVELS) . ")\n"
        unless grep { lc($_) eq lc($level) } @VALID_LEVELS;

    my $format = defined $settings->{log_format} && length $settings->{log_format}
        ? $settings->{log_format}
        : $DEFAULT_FORMAT;

    my $destination;
    if (defined $settings->{log_file} && length $settings->{log_file}) {
        my $path = $settings->{log_file};
        my $directory = dirname($path);
        make_path($directory) unless -d $directory;
        $destination = { file => $path };
    } else {
        $destination = { fd => \*STDERR };
    }

    my $logger = Log::Abstraction->new(
        level          => $level,
        format         => $format,
        # Logging must never turn a handled error into a second, uncaught one.
        croak_on_error => 0,
        logger         => $destination,
    );

    # A command-line flag describes this run, so it beats the settings file.
    $logger = $logger->new(level => 'debug') if $args{verbose};
    $logger = $logger->new(level => 'error') if $args{quiet};

    return $logger;
}

1;

__END__

=head1 NAME

App::FileSync::Settings - process-wide settings and logging for App::FileSync

=head1 SYNOPSIS

    use App::FileSync::Settings;

    my $logger = App::FileSync::Settings::logger(verbose => 1);
    $logger->error('...');

    my $settings = App::FileSync::Settings::load();
    my $level = $settings->{log_level};

=head1 DESCRIPTION

Settings that apply to the process rather than to one repo - the log level,
format and destination, plus the SSH identity, known-hosts file and remote
server command - are read through L<Object::Configure>.  The repos themselves
remain in F<~/.filesync/config.json>, which C<filesync init> writes; this
module does not replace that store.

The settings file is F<~/.conf/app-filesync.json> when it exists, or the path in
C<FILESYNC_SETTINGS>.  The section key is C<App__FileSync>, and a C<UNIVERSAL>
section in the same directory applies to every class that uses
Object::Configure.  Environment variables named C<App__FileSync__I<key>>
override the file:

    # ~/.conf/app-filesync.json
    { "App__FileSync": { "log_level": "debug", "log_format": "%level%: %message%" } }

    # or
    export App__FileSync__log_level=debug

C<log_file> sends the log to a file instead of standard error; leading
directories are created.  C<log_format> is a L<Log::Abstraction> format string.

C<ssh_identity>, C<ssh_known_hosts> and C<server_command> are the defaults for
every SSH repo, so a per-repo C<identity>, C<known_hosts> or C<server_command>
(written by C<filesync init --identity> and friends) only has to be set when it
differs.  C<server_command> defaults to C<filesync-server>:

    { "App__FileSync": {
        "ssh_identity"    : "~/.ssh/filesync_ed25519",
        "ssh_known_hosts" : "~/.ssh/filesync_known_hosts",
        "server_command"  : "/usr/local/bin/filesync-server"
    } }

Command output (sync summaries, plans, C<--json>) is written to standard output
by the commands themselves; the logger carries diagnostics on standard error,
so a cron job can separate the two.  C<--verbose> raises the level to C<debug>
and C<--quiet> lowers it to C<error> for that run, overriding the file.

=head1 FUNCTIONS

=head2 logger

    my $logger = App::FileSync::Settings::logger(%args);

Returns a L<Log::Abstraction> writing to standard error (or C<log_file>).
C<config_file>, C<config_dirs>, C<level>, C<verbose> and C<quiet> may be passed.

=head2 load

Returns the merged settings hashref (without the Object::Configure logger).

=head2 config_file

Returns the settings file that would be used, or C<undef>.

=head1 LICENCE

GPL v2 for personal single-user, single-computer use.  All other users must
apply in writing to the author.

=cut
