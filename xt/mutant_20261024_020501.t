#!/usr/bin/env perl
# Auto-generated mutant test stubs
# Generated: 2026-10-24 02:05:01
# Generator: scripts/test-generator-index
#
# DO NOT COMMIT without completing the TODO sections.
#
# HIGH/MEDIUM difficulty survivors have TODO stubs — these need real tests.
# LOW difficulty survivors appear as comment hints — worth improving.
#
# Stubs call new() for modules with a constructor, or show a class method
# placeholder for modules without one. Add arguments as needed.

use strict;
use warnings;
use Test::More;

use_ok('App::FileSync');
use_ok('App::FileSync::Settings');

################################################################
# FILE: lib/App/FileSync.pm
################################################################
# --- SURVIVORS (TODO stubs) ---

# --- SURVIVOR: BOOL_NEGATE_49_2 (MEDIUM) line 49 in _to_bytes() ---
# Source:  return 1;
# Hint:    Add tests asserting both true and false outcomes
# Mutations on this line (1 variant):
#   Negate boolean return expression
TODO: {
    local $TODO = 'Complete: BOOL_NEGATE_49_2 line 49 in _to_bytes()';
    # NOTE: App::FileSync has no constructor — call class methods directly.
    # e.g. my $result = App::FileSync->method(...);
    # TODO: exercise line 49 in _to_bytes() to detect the mutant
    fail('BOOL_NEGATE_49_2: replace with real assertion');
}

# --- SURVIVOR: BOOL_NEGATE_68_2 (MEDIUM) line 68 in set_mtime() ---
# Source:  return 1 unless defined $mtime;
# Hint:    Add tests asserting both true and false outcomes
# Mutations on this line (1 variant):
#   Negate boolean return expression
TODO: {
    local $TODO = 'Complete: BOOL_NEGATE_68_2 line 68 in set_mtime()';
    # NOTE: App::FileSync has no constructor — call class methods directly.
    # e.g. my $result = App::FileSync->method(...);
    # TODO: exercise line 68 in set_mtime() to detect the mutant
    fail('BOOL_NEGATE_68_2: replace with real assertion');
}

# --- SURVIVOR: BOOL_NEGATE_70_2 (MEDIUM) line 70 in set_mtime() ---
# Source:  return 1 if eval { Time::HiRes::utime($mtime, $mtime, $path); 1 };
# Hint:    Add tests asserting both true and false outcomes
# Mutations on this line (1 variant):
#   Negate boolean return expression
TODO: {
    local $TODO = 'Complete: BOOL_NEGATE_70_2 line 70 in set_mtime()';
    # NOTE: App::FileSync has no constructor — call class methods directly.
    # e.g. my $result = App::FileSync->method(...);
    # TODO: exercise line 70 in set_mtime() to detect the mutant
    fail('BOOL_NEGATE_70_2: replace with real assertion');
}

# --- SURVIVOR: BOOL_NEGATE_78_2 (MEDIUM) line 78 in set_mtime() ---
# Source:  return 1;
# Hint:    Add tests asserting both true and false outcomes
# Mutations on this line (1 variant):
#   Negate boolean return expression
TODO: {
    local $TODO = 'Complete: BOOL_NEGATE_78_2 line 78 in set_mtime()';
    # NOTE: App::FileSync has no constructor — call class methods directly.
    # e.g. my $result = App::FileSync->method(...);
    # TODO: exercise line 78 in set_mtime() to detect the mutant
    fail('BOOL_NEGATE_78_2: replace with real assertion');
}

# --- SURVIVOR: BOOL_NEGATE_106_2 (MEDIUM) line 106 in write_atomic() ---
# Source:  return 1;
# Hint:    Add tests asserting both true and false outcomes
# Mutations on this line (1 variant):
#   Negate boolean return expression
TODO: {
    local $TODO = 'Complete: BOOL_NEGATE_106_2 line 106 in write_atomic()';
    # NOTE: App::FileSync has no constructor — call class methods directly.
    # e.g. my $result = App::FileSync->method(...);
    # TODO: exercise line 106 in write_atomic() to detect the mutant
    fail('BOOL_NEGATE_106_2: replace with real assertion');
}

# --- SURVIVOR: BOOL_NEGATE_155_28 (MEDIUM) line 155 in validate_client_id() ---
# Source:  sub validate_client_id   { return _validate_id('client id',   $_[0]) }
# Hint:    Add tests asserting both true and false outcomes
# Mutations on this line (1 variant):
#   Negate boolean return expression
TODO: {
    local $TODO = 'Complete: BOOL_NEGATE_155_28 line 155 in validate_client_id()';
    # NOTE: App::FileSync has no constructor — call class methods directly.
    # e.g. my $result = App::FileSync->method(...);
    # TODO: exercise line 155 in validate_client_id() to detect the mutant
    fail('BOOL_NEGATE_155_28: replace with real assertion');
}

# --- SURVIVOR: BOOL_NEGATE_184_5 (MEDIUM) line 184 in parse_until() ---
# Source:  return undef unless defined $epoch;
# Hint:    Add tests asserting both true and false outcomes
# Mutations on this line (1 variant):
#   Negate boolean return expression
TODO: {
    local $TODO = 'Complete: BOOL_NEGATE_184_5 line 184 in parse_until()';
    # NOTE: App::FileSync has no constructor — call class methods directly.
    # e.g. my $result = App::FileSync->method(...);
    # TODO: exercise line 184 in parse_until() to detect the mutant
    fail('BOOL_NEGATE_184_5: replace with real assertion');
}

# --- SURVIVOR: NUM_BOUNDARY_219_25_> (HIGH) line 219 in conflict_name() ---
# Source:  $room = 16 if $room < 16;
# Hint:    Likely missing edge-case test (boundary value)
# Mutations on this line (3 variants — one test should kill all):
#   Numeric boundary flip < to >
#   Numeric boundary flip < to <=
#   Numeric boundary flip < to >=
TODO: {
    local $TODO = 'Complete: NUM_BOUNDARY_219_25_> line 219 in conflict_name()';
    # Suggested boundary values to test: 15, 16, 17
    # NOTE: App::FileSync has no constructor — call class methods directly.
    # e.g. my $result = App::FileSync->method(...);
    # TODO: exercise line 219 in conflict_name() to detect the mutant
    fail('NUM_BOUNDARY_219_25_>: replace with real assertion');
}

# --- SURVIVOR: NUM_BOUNDARY_220_54_< (HIGH) line 220 in conflict_name() ---
# Source:  $stem = substr($stem, 0, $room) if length($stem) > $room;
# Hint:    Likely missing edge-case test (boundary value)
# Mutations on this line (3 variants — one test should kill all):
#   Numeric boundary flip > to <
#   Numeric boundary flip > to >=
#   Numeric boundary flip > to <=
TODO: {
    local $TODO = 'Complete: NUM_BOUNDARY_220_54_< line 220 in conflict_name()';
    # NOTE: App::FileSync has no constructor — call class methods directly.
    # e.g. my $result = App::FileSync->method(...);
    # TODO: exercise line 220 in conflict_name() to detect the mutant
    fail('NUM_BOUNDARY_220_54_<: replace with real assertion');
}

# --- LOW DIFFICULTY HINTS (comment stubs) ---

# --- LOW HINT: RETURN_UNDEF_49_2 line 49 in _to_bytes() ---
# Source:  return 1;
# Hint:    Mutation survived, but impact may be minor
# Mutations on this line (1 variant):
#   Replace return expression with undef
# NOTE: App::FileSync has no constructor — call class methods directly.
# e.g. my $result = App::FileSync->method(...);
# ok($result, 'RETURN_UNDEF_49_2: add assertion here');

# --- LOW HINT: RETURN_UNDEF_68_2 line 68 in set_mtime() ---
# Source:  return 1 unless defined $mtime;
# Hint:    Mutation survived, but impact may be minor
# Mutations on this line (1 variant):
#   Replace return expression with undef
# NOTE: App::FileSync has no constructor — call class methods directly.
# e.g. my $result = App::FileSync->method(...);
# ok($result, 'RETURN_UNDEF_68_2: add assertion here');

# --- LOW HINT: RETURN_UNDEF_70_2 line 70 in set_mtime() ---
# Source:  return 1 if eval { Time::HiRes::utime($mtime, $mtime, $path); 1 };
# Hint:    Mutation survived, but impact may be minor
# Mutations on this line (1 variant):
#   Replace return expression with undef
# NOTE: App::FileSync has no constructor — call class methods directly.
# e.g. my $result = App::FileSync->method(...);
# ok($result, 'RETURN_UNDEF_70_2: add assertion here');

# --- LOW HINT: RETURN_UNDEF_78_2 line 78 in set_mtime() ---
# Source:  return 1;
# Hint:    Mutation survived, but impact may be minor
# Mutations on this line (1 variant):
#   Replace return expression with undef
# NOTE: App::FileSync has no constructor — call class methods directly.
# e.g. my $result = App::FileSync->method(...);
# ok($result, 'RETURN_UNDEF_78_2: add assertion here');

# --- LOW HINT: RETURN_UNDEF_106_2 line 106 in write_atomic() ---
# Source:  return 1;
# Hint:    Mutation survived, but impact may be minor
# Mutations on this line (1 variant):
#   Replace return expression with undef
# NOTE: App::FileSync has no constructor — call class methods directly.
# e.g. my $result = App::FileSync->method(...);
# ok($result, 'RETURN_UNDEF_106_2: add assertion here');

# --- LOW HINT: RETURN_UNDEF_155_28 line 155 in validate_client_id() ---
# Source:  sub validate_client_id   { return _validate_id('client id',   $_[0]) }
# Hint:    Mutation survived, but impact may be minor
# Mutations on this line (1 variant):
#   Replace return expression with undef
# NOTE: App::FileSync has no constructor — call class methods directly.
# e.g. my $result = App::FileSync->method(...);
# ok($result, 'RETURN_UNDEF_155_28: add assertion here');

# --- LOW HINT: RETURN_UNDEF_184_5 line 184 in parse_until() ---
# Source:  return undef unless defined $epoch;
# Hint:    Mutation survived, but impact may be minor
# Mutations on this line (1 variant):
#   Replace return expression with undef
# NOTE: App::FileSync has no constructor — call class methods directly.
# e.g. my $result = App::FileSync->method(...);
# ok($result, 'RETURN_UNDEF_184_5: add assertion here');

################################################################
# FILE: lib/App/FileSync/Settings.pm
################################################################
# --- SURVIVORS (TODO stubs) ---

# --- SURVIVOR: BOOL_NEGATE_49_5 (MEDIUM) line 49 in use_plain_end_of_scope_hook() ---
# Source:  # ~/.filesync/config.json, which "filesync init" writes and the admin tool edits.
# Hint:    Add tests asserting both true and false outcomes
# Mutations on this line (1 variant):
#   Negate boolean return expression
TODO: {
    local $TODO = 'Complete: BOOL_NEGATE_49_5 line 49 in use_plain_end_of_scope_hook()';
    # NOTE: App::FileSync::Settings has no constructor — call class methods directly.
    # e.g. my $result = App::FileSync::Settings->method(...);
    # TODO: exercise line 49 in use_plain_end_of_scope_hook() to detect the mutant
    fail('BOOL_NEGATE_49_5: replace with real assertion');
}

# --- SURVIVOR: BOOL_NEGATE_51_5 (MEDIUM) line 51 in use_plain_end_of_scope_hook() ---
# Source:  our $DEFAULT_LEVEL   = 'warning';
# Hint:    Add tests asserting both true and false outcomes
# Mutations on this line (1 variant):
#   Negate boolean return expression
TODO: {
    local $TODO = 'Complete: BOOL_NEGATE_51_5 line 51 in use_plain_end_of_scope_hook()';
    # NOTE: App::FileSync::Settings has no constructor — call class methods directly.
    # e.g. my $result = App::FileSync::Settings->method(...);
    # TODO: exercise line 51 in use_plain_end_of_scope_hook() to detect the mutant
    fail('BOOL_NEGATE_51_5: replace with real assertion');
}

# --- SURVIVOR: BOOL_NEGATE_60_5 (MEDIUM) line 60 in use_plain_end_of_scope_hook() ---
# Source:  crit critical fatal alert emerg emergency panic
# Hint:    Add tests asserting both true and false outcomes
# Mutations on this line (1 variant):
#   Negate boolean return expression
TODO: {
    local $TODO = 'Complete: BOOL_NEGATE_60_5 line 60 in use_plain_end_of_scope_hook()';
    # NOTE: App::FileSync::Settings has no constructor — call class methods directly.
    # e.g. my $result = App::FileSync::Settings->method(...);
    # TODO: exercise line 60 in use_plain_end_of_scope_hook() to detect the mutant
    fail('BOOL_NEGATE_60_5: replace with real assertion');
}

# --- SURVIVOR: BOOL_NEGATE_275_5 (MEDIUM) line 275 in explain_repos() ---
# Hint:    Add tests asserting both true and false outcomes
# Mutations on this line (1 variant):
#   Negate boolean return expression
TODO: {
    local $TODO = 'Complete: BOOL_NEGATE_275_5 line 275 in explain_repos()';
    # NOTE: App::FileSync::Settings has no constructor — call class methods directly.
    # e.g. my $result = App::FileSync::Settings->method(...);
    # TODO: exercise line 275 in explain_repos() to detect the mutant
    fail('BOOL_NEGATE_275_5: replace with real assertion');
}

# --- SURVIVOR: BOOL_NEGATE_276_5 (MEDIUM) line 276 in explain_repos() ---
# Source:  $entry->{ssh} = \@rows;
# Hint:    Add tests asserting both true and false outcomes
# Mutations on this line (1 variant):
#   Negate boolean return expression
TODO: {
    local $TODO = 'Complete: BOOL_NEGATE_276_5 line 276 in explain_repos()';
    # NOTE: App::FileSync::Settings has no constructor — call class methods directly.
    # e.g. my $result = App::FileSync::Settings->method(...);
    # TODO: exercise line 276 in explain_repos() to detect the mutant
    fail('BOOL_NEGATE_276_5: replace with real assertion');
}

# --- SURVIVOR: BOOL_NEGATE_308_5 (MEDIUM) line 308 in _differs() ---
# Source:  my ($left, $right) = @_;
# Hint:    Add tests asserting both true and false outcomes
# Mutations on this line (1 variant):
#   Negate boolean return expression
TODO: {
    local $TODO = 'Complete: BOOL_NEGATE_308_5 line 308 in _differs()';
    # NOTE: App::FileSync::Settings has no constructor — call class methods directly.
    # e.g. my $result = App::FileSync::Settings->method(...);
    # TODO: exercise line 308 in _differs() to detect the mutant
    fail('BOOL_NEGATE_308_5: replace with real assertion');
}

# --- SURVIVOR: BOOL_NEGATE_348_5 (MEDIUM) line 348 in _pick() ---
# Source:  sub _pick {
# Hint:    Add tests asserting both true and false outcomes
# Mutations on this line (1 variant):
#   Negate boolean return expression
TODO: {
    local $TODO = 'Complete: BOOL_NEGATE_348_5 line 348 in _pick()';
    # NOTE: App::FileSync::Settings has no constructor — call class methods directly.
    # e.g. my $result = App::FileSync::Settings->method(...);
    # TODO: exercise line 348 in _pick() to detect the mutant
    fail('BOOL_NEGATE_348_5: replace with real assertion');
}

# --- SURVIVOR: BOOL_NEGATE_371_5 (MEDIUM) line 371 in _labels_for() ---
# Source:  my (%seen, @labels);
# Hint:    Add tests asserting both true and false outcomes
# Mutations on this line (1 variant):
#   Negate boolean return expression
TODO: {
    local $TODO = 'Complete: BOOL_NEGATE_371_5 line 371 in _labels_for()';
    # NOTE: App::FileSync::Settings has no constructor — call class methods directly.
    # e.g. my $result = App::FileSync::Settings->method(...);
    # TODO: exercise line 371 in _labels_for() to detect the mutant
    fail('BOOL_NEGATE_371_5: replace with real assertion');
}

# --- LOW DIFFICULTY HINTS (comment stubs) ---

# --- LOW HINT: RETURN_UNDEF_49_5 line 49 in use_plain_end_of_scope_hook() ---
# Source:  # ~/.filesync/config.json, which "filesync init" writes and the admin tool edits.
# Hint:    Mutation survived, but impact may be minor
# Mutations on this line (1 variant):
#   Replace return expression with undef
# NOTE: App::FileSync::Settings has no constructor — call class methods directly.
# e.g. my $result = App::FileSync::Settings->method(...);
# ok($result, 'RETURN_UNDEF_49_5: add assertion here');

# --- LOW HINT: RETURN_UNDEF_51_5 line 51 in use_plain_end_of_scope_hook() ---
# Source:  our $DEFAULT_LEVEL   = 'warning';
# Hint:    Mutation survived, but impact may be minor
# Mutations on this line (1 variant):
#   Replace return expression with undef
# NOTE: App::FileSync::Settings has no constructor — call class methods directly.
# e.g. my $result = App::FileSync::Settings->method(...);
# ok($result, 'RETURN_UNDEF_51_5: add assertion here');

# --- LOW HINT: RETURN_UNDEF_60_5 line 60 in use_plain_end_of_scope_hook() ---
# Source:  crit critical fatal alert emerg emergency panic
# Hint:    Mutation survived, but impact may be minor
# Mutations on this line (1 variant):
#   Replace return expression with undef
# NOTE: App::FileSync::Settings has no constructor — call class methods directly.
# e.g. my $result = App::FileSync::Settings->method(...);
# ok($result, 'RETURN_UNDEF_60_5: add assertion here');

# --- LOW HINT: RETURN_UNDEF_275_5 line 275 in explain_repos() ---
# Hint:    Mutation survived, but impact may be minor
# Mutations on this line (1 variant):
#   Replace return expression with undef
# NOTE: App::FileSync::Settings has no constructor — call class methods directly.
# e.g. my $result = App::FileSync::Settings->method(...);
# ok($result, 'RETURN_UNDEF_275_5: add assertion here');

# --- LOW HINT: RETURN_UNDEF_276_5 line 276 in explain_repos() ---
# Source:  $entry->{ssh} = \@rows;
# Hint:    Mutation survived, but impact may be minor
# Mutations on this line (1 variant):
#   Replace return expression with undef
# NOTE: App::FileSync::Settings has no constructor — call class methods directly.
# e.g. my $result = App::FileSync::Settings->method(...);
# ok($result, 'RETURN_UNDEF_276_5: add assertion here');

# --- LOW HINT: RETURN_UNDEF_308_5 line 308 in _differs() ---
# Source:  my ($left, $right) = @_;
# Hint:    Mutation survived, but impact may be minor
# Mutations on this line (1 variant):
#   Replace return expression with undef
# NOTE: App::FileSync::Settings has no constructor — call class methods directly.
# e.g. my $result = App::FileSync::Settings->method(...);
# ok($result, 'RETURN_UNDEF_308_5: add assertion here');

# --- LOW HINT: RETURN_UNDEF_348_5 line 348 in _pick() ---
# Source:  sub _pick {
# Hint:    Mutation survived, but impact may be minor
# Mutations on this line (1 variant):
#   Replace return expression with undef
# NOTE: App::FileSync::Settings has no constructor — call class methods directly.
# e.g. my $result = App::FileSync::Settings->method(...);
# ok($result, 'RETURN_UNDEF_348_5: add assertion here');

# --- LOW HINT: RETURN_UNDEF_371_5 line 371 in _labels_for() ---
# Source:  my (%seen, @labels);
# Hint:    Mutation survived, but impact may be minor
# Mutations on this line (1 variant):
#   Replace return expression with undef
# NOTE: App::FileSync::Settings has no constructor — call class methods directly.
# e.g. my $result = App::FileSync::Settings->method(...);
# ok($result, 'RETURN_UNDEF_371_5: add assertion here');

done_testing();
