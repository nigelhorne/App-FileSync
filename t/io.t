use strict;
use warnings;
use Test::Most;

use Errno qw(ENOSPC);
use File::Spec;
use File::Temp qw(tempdir);

use App::FileSync::IO qw(write_atomic read_text);

# The names in a directory, so a test can see that no temporary file is left.
sub names {
	my ($dir) = @_;
	opendir my $dh, $dir or die "Cannot read $dir: $!";
	my @names = sort grep { !/\A\.\.?\z/ } readdir $dh;
	closedir $dh;
	return \@names;
}

# --- write_atomic on a full disk ---------------------------------------------

# /dev/full refuses every write with ENOSPC.  temp_file still makes its real
# temporary file (which write_atomic must then remove), but the handle it
# returns writes to /dev/full.  A short write only fails when close flushes
# the buffer; a large one fails in print itself.
SKIP: {
	skip 'no /dev/full here', 12 unless -c '/dev/full' && -w _;

	my $real = \&App::FileSync::IO::temp_file;
	my $full = sub {
		my $pair = $real->(@_);
		close $pair->[0];
		open my $fh, '>', '/dev/full' or die "Cannot open /dev/full: $!";
		binmode $fh;
		return [ $fh, $pair->[1] ];
	};
	my $enospc = do { local $! = ENOSPC; "$!" };

	my %data = (
		'a short write (close fails)' => "new\n",
		'a large write (print fails)' => 'x' x (4 * 1024 * 1024),
	);
	for my $case (sort keys %data) {
		my $dir = tempdir(CLEANUP => 1);
		my $path = File::Spec->catfile($dir, 'state.json');
		write_atomic($path, "old\n");

		{
			no warnings 'redefine';
			local *App::FileSync::IO::temp_file = $full;
			throws_ok { write_atomic($path, $data{$case}) }
				qr/\ACannot write \Q$dir\E\S+: \Q$enospc\E$/m, "$case: io.write with the OS reason";
		}
		is(read_text($path), "old\n", "$case: the old contents are untouched");
		is_deeply(names($dir), ['state.json'], "$case: the temporary file is discarded");

		lives_ok { write_atomic($path, "after\n") } "$case: a later write succeeds";
		is(read_text($path), "after\n", "$case: with the new contents");
		is_deeply(names($dir), ['state.json'], "$case: and leaves no temporary file");
	}
}

# --- write_atomic when the rename fails ----------------------------------------

# A directory in the way cannot be replaced by a file.
{
	my $dir = tempdir(CLEANUP => 1);
	my $path = File::Spec->catfile($dir, 'state.json');
	mkdir $path or die "Cannot mkdir $path: $!";
	open my $fh, '>', File::Spec->catfile($path, 'keep') or die $!;
	close $fh;

	throws_ok { write_atomic($path, "new\n") }
		qr/\ACannot move \Q$dir\E\S+ to \Q$path\E: /, 'a failed rename is io.rename';
	ok(-d $path && -e File::Spec->catfile($path, 'keep'), 'the directory in the way is untouched');
	is_deeply(names($dir), ['state.json'], 'and the temporary file is discarded');
}

done_testing();
