use strict;
use warnings;
use Test::Most;

use JSON::PP ();

use App::FileSync qw(json_encode json_decode);

# json_encode and json_decode use Cpanel::JSON::XS when it is installed and
# JSON::PP otherwise.  A client and a server may differ, so whichever backend
# is in use here must read what either one writes, and paths must come back
# as the bytes they were.

my $backend = $INC{'Cpanel/JSON/XS.pm'} ? 'Cpanel::JSON::XS' : 'JSON::PP';
note("backend in use: $backend");

my %paths = (
	'UTF-8 bytes'       => "caf\xc3\xa9.txt",
	'a Latin-1 byte'    => "caf\xe9.txt",
	'invalid UTF-8'     => "bad\xff\xfe\x80",
	'plain ASCII'       => 'dir/file.txt',
);

# --- round trips with the backend in use ----------------------------------

for my $label (sort keys %paths) {
	my $path = $paths{$label};
	my $back = json_decode(json_encode({ $path => { p => $path } }));
	my ($key) = keys %{$back};
	is($key, $path, "$label: a key comes back as the same bytes");
	ok(!utf8::is_utf8($key), "$label: and without the UTF-8 flag");
	is($back->{$key}{p}, $path, "$label: a value comes back as the same bytes");
	ok(!utf8::is_utf8($back->{$key}{p}), "$label: and without the UTF-8 flag");
}

is(json_encode({ b => 1, a => 2, c => { z => 1, y => 2 } }), '{"a":2,"b":1,"c":{"y":2,"z":1}}',
	'keys are sorted at every level');
is(json_encode('scalar'), '"scalar"', 'a bare scalar encodes');
throws_ok { json_decode('{"open":') } qr/\S/, 'malformed JSON raises';

# --- reading what each backend writes --------------------------------------

# Values whose text differs between the encoders: Cpanel::JSON::XS writes a
# whole-valued float as 1000.0 and negative zero as -0.0.
my $data = {
	"caf\xc3\xa9.txt" => { s => 12, m => 1_700_000_000.0, h => 'a' x 64, t => 'f' },
	"caf\xe9.txt"     => { m => 1_792_689_244.19712, whole => 1000.0, neg => -0.0, int => 1000, str => '007' },
	flag              => JSON::PP::true(),
	list              => [ 1, 'two', undef, 2.5 ],
};

my %writers = (
	'JSON::PP' => JSON::PP->new->canonical->allow_nonref,
);
$writers{'Cpanel::JSON::XS'} = Cpanel::JSON::XS->new->canonical->allow_nonref
	if eval { require Cpanel::JSON::XS; 1 };

my $expected = json_decode(json_encode($data));
for my $writer (sort keys %writers) {
	my $got = json_decode($writers{$writer}->encode($data));
	for my $path ("caf\xc3\xa9.txt", "caf\xe9.txt") {
		ok(exists $got->{$path}, "$backend finds a byte-string path written by $writer");
		for my $field (sort keys %{ $expected->{$path} }) {
			my ($want, $have) = ($expected->{$path}{$field}, $got->{$path}{$field});
			if ($want =~ /\A-?[\d.]+\z/) {
				cmp_ok($have, '==', $want, "$writer: $field has the same numeric value");
			} else {
				is($have, $want, "$writer: $field is the same string");
			}
		}
	}
	ok($got->{flag}, "$writer: a true value stays true");
	is_deeply($got->{list}, $expected->{list}, "$writer: a list keeps its values and nulls");
}

SKIP: {
	skip('Cpanel::JSON::XS is not installed', 1) unless $writers{'Cpanel::JSON::XS'};
	is(json_encode({ "caf\xc3\xa9.txt" => 1, list => [ 1, 'two' ] }),
		JSON::PP->new->canonical->allow_nonref->encode({ "caf\xc3\xa9.txt" => 1, list => [ 1, 'two' ] }),
		'for strings and integers both encoders write the same text');
}

done_testing();
