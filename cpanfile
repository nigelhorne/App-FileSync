# Generated from Makefile.PL using makefilepl2cpanfile

requires 'perl', '5.020';

requires 'Carp';
requires 'Digest::SHA';
requires 'Encode';
requires 'Exporter';
requires 'Fcntl';
requires 'File::Basename';
requires 'File::Copy';
requires 'File::Path';
requires 'File::Spec';
requires 'File::Temp';
requires 'Getopt::Long';
requires 'IO::Handle';
requires 'IPC::Open3';
requires 'JSON::PP';
requires 'Log::Abstraction';
requires 'Object::Configure';
requires 'POSIX';
requires 'Time::HiRes';
requires 'Time::Local';

on 'configure' => sub {
	requires 'ExtUtils::MakeMaker', '6.64';   # Minimum version for TEST_REQUIRES
};

on 'test' => sub {
	requires 'File::Temp';
	requires 'Test::Deep';
	requires 'Test::Exception';
	requires 'Test::Most';
};
