package App::FileSync::Admin;

use strict;
use warnings;

use Digest::SHA ();
use File::Path qw(make_path);
use File::Spec;
use Time::HiRes ();

use App::FileSync qw(json_encode json_decode validate_relpath parse_since);
use App::FileSync::Config;
use App::FileSync::Ignore;
use App::FileSync::Settings;
use App::FileSync::Store;
use App::FileSync::Trash;
use App::FileSync::Verify;

sub new {
    my ($class, %args) = @_;

    my $root = $args{root};
    $root = $ENV{FILESYNC_ROOT} if !defined($root) || !length($root);
    $root = '/srv/filesync' if !defined($root) || !length($root);

    return bless {
        root   => $root,
        logger => $args{logger} || App::FileSync::Settings::logger(),
    }, $class;
}

sub root { $_[0]{root} }

sub repo_create {
    my ($self, %args) = @_;

    my $name = $args{name};
    die "Repo name is required\n" unless defined $name && length $name;
    die "Invalid repo name '$name'\n"
        unless $name =~ /\A[A-Za-z0-9][A-Za-z0-9._-]*\z/;

    my $config_path = App::FileSync::Config::repo_config_path($self->{root}, $name);
    die "Repo '$name' already exists at $config_path\n" if -e $config_path;

    my $config = App::FileSync::Config::default_repo_config($name);
    $config->{trash_days} = $args{trash_days} + 0
        if defined $args{trash_days};
    $config->{max_deletes} = $args{max_deletes} + 0
        if defined $args{max_deletes};
    $config->{max_delete_percent} = $args{max_delete_percent} + 0
        if defined $args{max_delete_percent};

    if (ref($args{ignore}) eq 'ARRAY' && @{ $args{ignore} }) {
        $config->{ignore} = [ @{ $args{ignore} } ];
    }

    my $master = File::Spec->catdir($self->{root}, 'master', $name);
    make_path($master) unless -d $master;

    my $meta = App::FileSync::Config::repo_meta_dir($self->{root}, $name);
    for my $sub (qw(clients trash journal locks)) {
        my $dir = File::Spec->catdir($meta, $sub);
        make_path($dir) unless -d $dir;
    }

    App::FileSync::Config::save_repo($self->{root}, $name, $config);

    my $store = App::FileSync::Store->new(
        root => $self->{root}, repo => $name, config => $config,
    );
    $store->save_index({});

    return {
        name   => $name,
        master => $master,
        config => $config_path,
    };
}

sub repo_list {
    my ($self) = @_;

    my $root = File::Spec->catdir($self->{root}, '.filesync', 'repos');
    my $dh;
    return [] unless opendir($dh, $root);

    my @names = sort grep { $_ ne '.' && $_ ne '..' && -d File::Spec->catdir($root, $_) }
        readdir($dh);
    closedir $dh;

    return \@names;
}

sub repo_show {
    my ($self, $name) = @_;

    my $config = App::FileSync::Config::load_repo($self->{root}, $name);
    my $store = App::FileSync::Store->new(root => $self->{root}, repo => $name, config => $config);

    return {
        config => $config,
        master => $store->master_dir(),
        meta   => $store->meta_dir(),
        clients => [ sort keys %{ $config->{clients} || {} } ],
    };
}

sub client_allow {
    my ($self, %args) = @_;

    my $repo = $args{repo};
    my $client = $args{client};
    my $role = $args{role} || 'client';

    die "Client id is required\n" unless defined $client && length $client;
    die "Invalid client id '$client'\n" unless $client =~ /\A[A-Za-z0-9][A-Za-z0-9._-]*\z/;
    die "Invalid role '$role'\n" unless $role eq 'client' || $role eq 'replica';

    my $config = App::FileSync::Config::load_repo($self->{root}, $repo);
    $config->{clients} = {} unless ref($config->{clients}) eq 'HASH';
    $config->{clients}{$client} = { role => $role };

    App::FileSync::Config::save_repo($self->{root}, $repo, $config);

    return { client => $client, role => $role };
}

sub client_list {
    my ($self, $repo) = @_;

    my $config = App::FileSync::Config::load_repo($self->{root}, $repo);
    my $clients = $config->{clients} || {};

    my $store = App::FileSync::Store->new(root => $self->{root}, repo => $repo, config => $config);

    return [
        map {
            {
                client => $_,
                role   => ref($clients->{$_}) eq 'HASH' ? ($clients->{$_}{role} || 'client') : 'client',
                base   => -e $store->base_path($_) ? 1 : 0,
            }
        } sort keys %{$clients}
    ];
}

sub journal_read {
    my ($self, %args) = @_;

    my $store = App::FileSync::Store->new(root => $self->{root}, repo => $args{repo});
    my $dir = File::Spec->catdir($store->meta_dir(), 'journal');

    my @files = sort glob(File::Spec->catfile($dir, '*.jsonl'));
    my @events;

    for my $file (@files) {
        open my $fh, '<', $file or die "Cannot read $file: $!\n";
        while (my $line = <$fh>) {
            chomp $line;
            next unless length $line;

            my $event = eval { json_decode($line) };
            next unless ref($event) eq 'HASH';   # a torn final line from a killed run

            push @events, $event;
        }
        close $fh;
    }

    if (defined $args{client} && length $args{client}) {
        @events = grep { defined $_->{client} && $_->{client} eq $args{client} } @events;
    }

    if (defined $args{since}) {
        my $since = parse_since($args{since});
        @events = grep { ($_->{ts} || 0) >= $since } @events;
    }

    @events = sort { ($a->{ts} || 0) <=> ($b->{ts} || 0) } @events;

    my $limit = $args{limit};
    if (defined $limit && $limit > 0 && @events > $limit) {
        @events = @events[ -$limit .. -1 ];
    }

    return \@events;
}

# Rehash the master against its index and report what no longer agrees.
sub verify {
    my ($self, %args) = @_;

    my $repo = $args{repo};
    my $config = App::FileSync::Config::load_repo($self->{root}, $repo);
    my $store = App::FileSync::Store->new(
        root => $self->{root}, repo => $repo, config => $config,
    );

    my $report = App::FileSync::Verify::verify(
        root    => $store->master_dir(),
        entries => $store->load_index(),
        ignore  => App::FileSync::Ignore->new(patterns => $config->{ignore}),
        deep    => $args{deep},
        sample  => $args{sample},
    );

    $report->{repo} = $repo;
    $report->{master} = $store->master_dir();

    $self->{logger}->debug('verify finished', {
        repo     => $repo,
        files    => $report->{files},
        modified => scalar @{ $report->{modified} },
        missing  => scalar @{ $report->{missing} },
        extra    => scalar @{ $report->{extra} },
        ok       => $report->{ok} ? 1 : 0,
    });

    return $report;
}

# Put a path back from the server trash: into the master by default, or into
# --to DIR as an export.  The trash entry is kept, so this is repeatable.
sub restore {
    my ($self, %args) = @_;

    my $repo = $args{repo};
    my $path = $args{path};

    my ($safe, $reason) = validate_relpath($path);
    die "Unsafe path '$path': $reason\n" unless $safe;

    my $config = App::FileSync::Config::load_repo($self->{root}, $repo);
    my $store = App::FileSync::Store->new(
        root => $self->{root}, repo => $repo, config => $config,
    );

    my $versions = App::FileSync::Trash::versions(
        root => $store->trash_dir(), rel => $path,
    );

    if ($args{list}) {
        return {
            repo     => $repo,
            path     => $path,
            versions => [ map { _version_info($_) } @{$versions} ],
        };
    }

    die "No trashed version of '$path' in repo '$repo'\n" unless @{$versions};

    my $chosen;
    if (defined $args{date} && length $args{date}) {
        die "Bad --date '$args{date}' (want YYYY-MM-DD)\n"
            unless $args{date} =~ /\A\d{4}-\d{2}-\d{2}\z/;

        my @matching = grep { App::FileSync::Trash::date_of($_) eq $args{date} }
            @{$versions};
        die "No version of '$path' in the trash for $args{date}\n" unless @matching;
        $chosen = $matching[0];
    } else {
        $chosen = $versions->[0];
    }

    my $into_master = !(defined $args{to} && length $args{to});
    my $destination;
    if ($into_master) {
        $destination = File::Spec->catfile($store->master_dir(), split m{/}, $path);
    } else {
        make_path($args{to}) unless -d $args{to};
        die "Restore target $args{to} is not a directory\n" unless -d $args{to};
        $destination = File::Spec->catfile($args{to}, split m{/}, $path);
    }

    die "Refusing to overwrite $destination; move it aside first\n"
        if -e $destination || -l $destination;

    App::FileSync::Trash::restore(src => $chosen, to => $destination);

    my $sha = -f $destination ? _hash($destination) : undef;

    if ($into_master) {
        # The index is a cache; rebuild it so verify and the next sync agree
        # that the restored tree is what the master now holds.
        my ($manifest) = $store->walk_master($store->load_index());
        $store->save_index($manifest);
    }

    $store->journal({
        action => 'restore',
        path   => $path,
        trash  => $chosen,
        to     => $destination,
        (defined $sha ? (sha256 => $sha) : ()),
        result => 'ok',
    });

    $self->{logger}->info('restored path', {
        repo => $repo,
        path => $path,
        from => $chosen,
        to   => $destination,
    });

    return {
        repo => $repo,
        path => $path,
        from => $chosen,
        to   => $destination,
        date => App::FileSync::Trash::date_of($chosen),
        (defined $sha ? (sha256 => $sha) : ()),
        into_master => $into_master ? 1 : 0,
    };
}

sub _version_info {
    my ($path) = @_;

    my @stat = Time::HiRes::stat($path);

    return {
        path  => $path,
        date  => App::FileSync::Trash::date_of($path),
        size  => @stat ? $stat[7] : undef,
        mtime => @stat ? $stat[9] : undef,
    };
}

sub _hash {
    my ($path) = @_;

    my $sha = Digest::SHA->new(256);
    $sha->addfile($path, 'b');
    return $sha->hexdigest();
}

sub client_forget {
    my ($self, %args) = @_;

    my $store = App::FileSync::Store->new(root => $self->{root}, repo => $args{repo});
    my $path = $store->base_path($args{client});

    return { removed => 0, path => $path } unless -e $path;
    unlink $path or die "Cannot remove $path: $!\n";

    return { removed => 1, path => $path };
}

1;
