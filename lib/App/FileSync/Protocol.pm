package App::FileSync::Protocol;

use strict;
use warnings;

use IO::Handle ();

use App::FileSync qw(json_encode json_decode);

# One connection, strictly one request in flight at a time.
# Control messages are JSON on one line; binary payloads are announced by "len" and
# follow the header immediately.
sub new {
    my ($class, %args) = @_;

    my $in  = $args{in};
    my $out = $args{out};
    die "Protocol: no input handle\n"  unless $in;
    die "Protocol: no output handle\n" unless $out;

    binmode $in;
    binmode $out;
    $out->autoflush(1);

    return bless {
        in     => $in,
        out    => $out,
        buffer => '',
        closed => 0,
    }, $class;
}

sub send {
    my ($self, $message) = @_;
    die "Protocol: connection is closed\n" if $self->{closed};

    my $line = json_encode($message);
    print { $self->{out} } $line, "\n"
        or die "Protocol: cannot write to the connection: $!\n";

    return 1;
}

sub recv {
    my ($self) = @_;

    my $line = $self->read_line();
    my $message = eval { json_decode($line) };
    if ($@) {
        die "Protocol: malformed message from the peer: $@";
    }
    die "Protocol: message is not an object\n" unless ref($message) eq 'HASH';

    return $message;
}

sub send_bytes {
    my ($self, $bytes) = @_;
    die "Protocol: connection is closed\n" if $self->{closed};
    return 1 unless defined $bytes && length $bytes;

    print { $self->{out} } $bytes
        or die "Protocol: cannot write payload: $!\n";

    return 1;
}

sub read_line {
    my ($self) = @_;

    my $position;
    while (($position = index($self->{buffer}, "\n")) < 0) {
        $self->_fill();
    }

    my $line = substr($self->{buffer}, 0, $position);
    substr($self->{buffer}, 0, $position + 1, '');

    return $line;
}

sub read_bytes {
    my ($self, $length) = @_;

    die "Protocol: negative payload length\n" if $length < 0;
    while (length($self->{buffer}) < $length) {
        $self->_fill();
    }

    return substr($self->{buffer}, 0, $length, '');
}

sub _fill {
    my ($self) = @_;

    my $read = sysread($self->{in}, my $chunk, 65536);
    if (!defined $read) {
        die "Protocol: read error: $!\n";
    }
    if ($read == 0) {
        $self->{closed} = 1;
        die "Protocol: connection closed by the peer\n";
    }

    $self->{buffer} .= $chunk;
    return 1;
}

sub close {
    my ($self) = @_;
    return if $self->{closed};
    $self->{closed} = 1;
    close $self->{in};
    close $self->{out};
    return 1;
}

1;
