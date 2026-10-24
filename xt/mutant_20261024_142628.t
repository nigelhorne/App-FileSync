#!/usr/bin/env perl
# Auto-generated mutant test stubs
# Generated: 2026-10-24 14:26:28
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

# --- SURVIVOR: BOOL_NEGATE_49_2 (MEDIUM) line 49 ---
# Hint:    Add tests asserting both true and false outcomes
# Mutations on this line (1 variant):
#   Negate boolean return expression
TODO: {
    local $TODO = 'Complete: BOOL_NEGATE_49_2 line 49';
    # NOTE: App::FileSync has no constructor — call class methods directly.
    # e.g. my $result = App::FileSync->method(...);
    # TODO: exercise line 49 to detect the mutant
    fail('BOOL_NEGATE_49_2: replace with real assertion');
}

# --- SURVIVOR: BOOL_NEGATE_68_2 (MEDIUM) line 68 ---
# Source:  } elsif (defined($_[0]) && !ref($_[0]) && utf8::is_utf8($_[0])) {
# Hint:    Add tests asserting both true and false outcomes
# Mutations on this line (1 variant):
#   Negate boolean return expression
TODO: {
    local $TODO = 'Complete: BOOL_NEGATE_68_2 line 68';
    # NOTE: App::FileSync has no constructor — call class methods directly.
    # e.g. my $result = App::FileSync->method(...);
    # TODO: exercise line 68 to detect the mutant
    fail('BOOL_NEGATE_68_2: replace with real assertion');
}

# --- SURVIVOR: BOOL_NEGATE_70_2 (MEDIUM) line 70 ---
# Source:  }
# Hint:    Add tests asserting both true and false outcomes
# Mutations on this line (1 variant):
#   Negate boolean return expression
TODO: {
    local $TODO = 'Complete: BOOL_NEGATE_70_2 line 70';
    # NOTE: App::FileSync has no constructor — call class methods directly.
    # e.g. my $result = App::FileSync->method(...);
    # TODO: exercise line 70 to detect the mutant
    fail('BOOL_NEGATE_70_2: replace with real assertion');
}

# --- SURVIVOR: BOOL_NEGATE_78_2 (MEDIUM) line 78 ---
# Source:  App::FileSync - cron-driven file synchronisation without a daemon
# Hint:    Add tests asserting both true and false outcomes
# Mutations on this line (1 variant):
#   Negate boolean return expression
TODO: {
    local $TODO = 'Complete: BOOL_NEGATE_78_2 line 78';
    # NOTE: App::FileSync has no constructor — call class methods directly.
    # e.g. my $result = App::FileSync->method(...);
    # TODO: exercise line 78 to detect the mutant
    fail('BOOL_NEGATE_78_2: replace with real assertion');
}

# --- SURVIVOR: BOOL_NEGATE_106_2 (MEDIUM) line 106 ---
# Source:  (L<App::FileSync::I18N>), so a translation is one new catalogue.
# Hint:    Add tests asserting both true and false outcomes
# Mutations on this line (1 variant):
#   Negate boolean return expression
TODO: {
    local $TODO = 'Complete: BOOL_NEGATE_106_2 line 106';
    # NOTE: App::FileSync has no constructor — call class methods directly.
    # e.g. my $result = App::FileSync->method(...);
    # TODO: exercise line 106 to detect the mutant
    fail('BOOL_NEGATE_106_2: replace with real assertion');
}

# --- SURVIVOR: BOOL_NEGATE_155_28 (MEDIUM) line 155 in json_encode() ---
# Source:  return $JSON->encode($data);
# Hint:    Add tests asserting both true and false outcomes
# Mutations on this line (1 variant):
#   Negate boolean return expression
TODO: {
    local $TODO = 'Complete: BOOL_NEGATE_155_28 line 155 in json_encode()';
    # NOTE: App::FileSync has no constructor — call class methods directly.
    # e.g. my $result = App::FileSync->method(...);
    # TODO: exercise line 155 in json_encode() to detect the mutant
    fail('BOOL_NEGATE_155_28: replace with real assertion');
}

# --- SURVIVOR: BOOL_NEGATE_184_5 (MEDIUM) line 184 in json_encode() ---
# Source:  =head4 OUTPUT
# Hint:    Add tests asserting both true and false outcomes
# Mutations on this line (1 variant):
#   Negate boolean return expression
TODO: {
    local $TODO = 'Complete: BOOL_NEGATE_184_5 line 184 in json_encode()';
    # NOTE: App::FileSync has no constructor — call class methods directly.
    # e.g. my $result = App::FileSync->method(...);
    # TODO: exercise line 184 in json_encode() to detect the mutant
    fail('BOOL_NEGATE_184_5: replace with real assertion');
}

# --- SURVIVOR: NUM_BOUNDARY_219_25_> (HIGH) line 219 in json_decode() ---
# Source:  Side Effects: none.
# Hint:    Likely missing edge-case test (boundary value)
# Mutations on this line (3 variants — one test should kill all):
#   Numeric boundary flip < to >
#   Numeric boundary flip < to <=
#   Numeric boundary flip < to >=
TODO: {
    local $TODO = 'Complete: NUM_BOUNDARY_219_25_> line 219 in json_decode()';
    # NOTE: App::FileSync has no constructor — call class methods directly.
    # e.g. my $result = App::FileSync->method(...);
    # TODO: exercise line 219 in json_decode() to detect the mutant
    fail('NUM_BOUNDARY_219_25_>: replace with real assertion');
}

# --- SURVIVOR: NUM_BOUNDARY_220_54_< (HIGH) line 220 in json_decode() ---
# Hint:    Likely missing edge-case test (boundary value)
# Mutations on this line (3 variants — one test should kill all):
#   Numeric boundary flip > to <
#   Numeric boundary flip > to >=
#   Numeric boundary flip > to <=
TODO: {
    local $TODO = 'Complete: NUM_BOUNDARY_220_54_< line 220 in json_decode()';
    # NOTE: App::FileSync has no constructor — call class methods directly.
    # e.g. my $result = App::FileSync->method(...);
    # TODO: exercise line 220 in json_decode() to detect the mutant
    fail('NUM_BOUNDARY_220_54_<: replace with real assertion');
}

# --- LOW DIFFICULTY HINTS (comment stubs) ---

# --- LOW HINT: RETURN_UNDEF_49_2 line 49 ---
# Hint:    Mutation survived, but impact may be minor
# Mutations on this line (1 variant):
#   Replace return expression with undef
# NOTE: App::FileSync has no constructor — call class methods directly.
# e.g. my $result = App::FileSync->method(...);
# ok($result, 'RETURN_UNDEF_49_2: add assertion here');

# --- LOW HINT: RETURN_UNDEF_68_2 line 68 ---
# Source:  } elsif (defined($_[0]) && !ref($_[0]) && utf8::is_utf8($_[0])) {
# Hint:    Mutation survived, but impact may be minor
# Mutations on this line (1 variant):
#   Replace return expression with undef
# NOTE: App::FileSync has no constructor — call class methods directly.
# e.g. my $result = App::FileSync->method(...);
# ok($result, 'RETURN_UNDEF_68_2: add assertion here');

# --- LOW HINT: RETURN_UNDEF_70_2 line 70 ---
# Source:  }
# Hint:    Mutation survived, but impact may be minor
# Mutations on this line (1 variant):
#   Replace return expression with undef
# NOTE: App::FileSync has no constructor — call class methods directly.
# e.g. my $result = App::FileSync->method(...);
# ok($result, 'RETURN_UNDEF_70_2: add assertion here');

# --- LOW HINT: RETURN_UNDEF_78_2 line 78 ---
# Source:  App::FileSync - cron-driven file synchronisation without a daemon
# Hint:    Mutation survived, but impact may be minor
# Mutations on this line (1 variant):
#   Replace return expression with undef
# NOTE: App::FileSync has no constructor — call class methods directly.
# e.g. my $result = App::FileSync->method(...);
# ok($result, 'RETURN_UNDEF_78_2: add assertion here');

# --- LOW HINT: RETURN_UNDEF_106_2 line 106 ---
# Source:  (L<App::FileSync::I18N>), so a translation is one new catalogue.
# Hint:    Mutation survived, but impact may be minor
# Mutations on this line (1 variant):
#   Replace return expression with undef
# NOTE: App::FileSync has no constructor — call class methods directly.
# e.g. my $result = App::FileSync->method(...);
# ok($result, 'RETURN_UNDEF_106_2: add assertion here');

# --- LOW HINT: RETURN_UNDEF_155_28 line 155 in json_encode() ---
# Source:  return $JSON->encode($data);
# Hint:    Mutation survived, but impact may be minor
# Mutations on this line (1 variant):
#   Replace return expression with undef
# NOTE: App::FileSync has no constructor — call class methods directly.
# e.g. my $result = App::FileSync->method(...);
# ok($result, 'RETURN_UNDEF_155_28: add assertion here');

# --- LOW HINT: RETURN_UNDEF_184_5 line 184 in json_encode() ---
# Source:  =head4 OUTPUT
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

# --- SURVIVOR: BOOL_NEGATE_49_5 (MEDIUM) line 49 ---
# Source:  trace debug info informational notice warn warning error err
# Hint:    Add tests asserting both true and false outcomes
# Mutations on this line (1 variant):
#   Negate boolean return expression
TODO: {
    local $TODO = 'Complete: BOOL_NEGATE_49_5 line 49';
    # NOTE: App::FileSync::Settings has no constructor — call class methods directly.
    # e.g. my $result = App::FileSync::Settings->method(...);
    # TODO: exercise line 49 to detect the mutant
    fail('BOOL_NEGATE_49_5: replace with real assertion');
}

# --- SURVIVOR: BOOL_NEGATE_51_5 (MEDIUM) line 51 ---
# Source:  );
# Hint:    Add tests asserting both true and false outcomes
# Mutations on this line (1 variant):
#   Negate boolean return expression
TODO: {
    local $TODO = 'Complete: BOOL_NEGATE_51_5 line 51';
    # NOTE: App::FileSync::Settings has no constructor — call class methods directly.
    # e.g. my $result = App::FileSync::Settings->method(...);
    # TODO: exercise line 51 to detect the mutant
    fail('BOOL_NEGATE_51_5: replace with real assertion');
}

# --- SURVIVOR: BOOL_NEGATE_60_5 (MEDIUM) line 60 ---
# Source:  # to.  The names differ only because the repo config uses shorter keys.
# Hint:    Add tests asserting both true and false outcomes
# Mutations on this line (1 variant):
#   Negate boolean return expression
TODO: {
    local $TODO = 'Complete: BOOL_NEGATE_60_5 line 60';
    # NOTE: App::FileSync::Settings has no constructor — call class methods directly.
    # e.g. my $result = App::FileSync::Settings->method(...);
    # TODO: exercise line 60 to detect the mutant
    fail('BOOL_NEGATE_60_5: replace with real assertion');
}

# --- SURVIVOR: BOOL_NEGATE_275_5 (MEDIUM) line 275 in load() ---
# Source:  =head2 explain
# Hint:    Add tests asserting both true and false outcomes
# Mutations on this line (1 variant):
#   Negate boolean return expression
TODO: {
    local $TODO = 'Complete: BOOL_NEGATE_275_5 line 275 in load()';
    # NOTE: App::FileSync::Settings has no constructor — call class methods directly.
    # e.g. my $result = App::FileSync::Settings->method(...);
    # TODO: exercise line 275 in load() to detect the mutant
    fail('BOOL_NEGATE_275_5: replace with real assertion');
}

# --- SURVIVOR: BOOL_NEGATE_276_5 (MEDIUM) line 276 in load() ---
# Hint:    Add tests asserting both true and false outcomes
# Mutations on this line (1 variant):
#   Negate boolean return expression
TODO: {
    local $TODO = 'Complete: BOOL_NEGATE_276_5 line 276 in load()';
    # NOTE: App::FileSync::Settings has no constructor — call class methods directly.
    # e.g. my $result = App::FileSync::Settings->method(...);
    # TODO: exercise line 276 in load() to detect the mutant
    fail('BOOL_NEGATE_276_5: replace with real assertion');
}

# --- SURVIVOR: BOOL_NEGATE_308_5 (MEDIUM) line 308 in load() ---
# Source:  {
# Hint:    Add tests asserting both true and false outcomes
# Mutations on this line (1 variant):
#   Negate boolean return expression
TODO: {
    local $TODO = 'Complete: BOOL_NEGATE_308_5 line 308 in load()';
    # NOTE: App::FileSync::Settings has no constructor — call class methods directly.
    # e.g. my $result = App::FileSync::Settings->method(...);
    # TODO: exercise line 308 in load() to detect the mutant
    fail('BOOL_NEGATE_308_5: replace with real assertion');
}

# --- SURVIVOR: BOOL_NEGATE_348_5 (MEDIUM) line 348 in explain() ---
# Hint:    Add tests asserting both true and false outcomes
# Mutations on this line (1 variant):
#   Negate boolean return expression
TODO: {
    local $TODO = 'Complete: BOOL_NEGATE_348_5 line 348 in explain()';
    # NOTE: App::FileSync::Settings has no constructor — call class methods directly.
    # e.g. my $result = App::FileSync::Settings->method(...);
    # TODO: exercise line 348 in explain() to detect the mutant
    fail('BOOL_NEGATE_348_5: replace with real assertion');
}

# --- SURVIVOR: BOOL_NEGATE_371_5 (MEDIUM) line 371 in explain() ---
# Source:  $row{source} = $entry->{type};
# Hint:    Add tests asserting both true and false outcomes
# Mutations on this line (1 variant):
#   Negate boolean return expression
TODO: {
    local $TODO = 'Complete: BOOL_NEGATE_371_5 line 371 in explain()';
    # NOTE: App::FileSync::Settings has no constructor — call class methods directly.
    # e.g. my $result = App::FileSync::Settings->method(...);
    # TODO: exercise line 371 in explain() to detect the mutant
    fail('BOOL_NEGATE_371_5: replace with real assertion');
}

# --- LOW DIFFICULTY HINTS (comment stubs) ---

# --- LOW HINT: RETURN_UNDEF_49_5 line 49 ---
# Source:  trace debug info informational notice warn warning error err
# Hint:    Mutation survived, but impact may be minor
# Mutations on this line (1 variant):
#   Replace return expression with undef
# NOTE: App::FileSync::Settings has no constructor — call class methods directly.
# e.g. my $result = App::FileSync::Settings->method(...);
# ok($result, 'RETURN_UNDEF_49_5: add assertion here');

# --- LOW HINT: RETURN_UNDEF_51_5 line 51 ---
# Source:  );
# Hint:    Mutation survived, but impact may be minor
# Mutations on this line (1 variant):
#   Replace return expression with undef
# NOTE: App::FileSync::Settings has no constructor — call class methods directly.
# e.g. my $result = App::FileSync::Settings->method(...);
# ok($result, 'RETURN_UNDEF_51_5: add assertion here');

# --- LOW HINT: RETURN_UNDEF_60_5 line 60 ---
# Source:  # to.  The names differ only because the repo config uses shorter keys.
# Hint:    Mutation survived, but impact may be minor
# Mutations on this line (1 variant):
#   Replace return expression with undef
# NOTE: App::FileSync::Settings has no constructor — call class methods directly.
# e.g. my $result = App::FileSync::Settings->method(...);
# ok($result, 'RETURN_UNDEF_60_5: add assertion here');

# --- LOW HINT: RETURN_UNDEF_275_5 line 275 in load() ---
# Source:  =head2 explain
# Hint:    Mutation survived, but impact may be minor
# Mutations on this line (1 variant):
#   Replace return expression with undef
# NOTE: App::FileSync::Settings has no constructor — call class methods directly.
# e.g. my $result = App::FileSync::Settings->method(...);
# ok($result, 'RETURN_UNDEF_275_5: add assertion here');

# --- LOW HINT: RETURN_UNDEF_276_5 line 276 in load() ---
# Hint:    Mutation survived, but impact may be minor
# Mutations on this line (1 variant):
#   Replace return expression with undef
# NOTE: App::FileSync::Settings has no constructor — call class methods directly.
# e.g. my $result = App::FileSync::Settings->method(...);
# ok($result, 'RETURN_UNDEF_276_5: add assertion here');

# --- LOW HINT: RETURN_UNDEF_308_5 line 308 in load() ---
# Source:  {
# Hint:    Mutation survived, but impact may be minor
# Mutations on this line (1 variant):
#   Replace return expression with undef
# NOTE: App::FileSync::Settings has no constructor — call class methods directly.
# e.g. my $result = App::FileSync::Settings->method(...);
# ok($result, 'RETURN_UNDEF_308_5: add assertion here');

# --- LOW HINT: RETURN_UNDEF_348_5 line 348 in explain() ---
# Hint:    Mutation survived, but impact may be minor
# Mutations on this line (1 variant):
#   Replace return expression with undef
# NOTE: App::FileSync::Settings has no constructor — call class methods directly.
# e.g. my $result = App::FileSync::Settings->method(...);
# ok($result, 'RETURN_UNDEF_348_5: add assertion here');

# --- LOW HINT: RETURN_UNDEF_371_5 line 371 in explain() ---
# Source:  $row{source} = $entry->{type};
# Hint:    Mutation survived, but impact may be minor
# Mutations on this line (1 variant):
#   Replace return expression with undef
# NOTE: App::FileSync::Settings has no constructor — call class methods directly.
# e.g. my $result = App::FileSync::Settings->method(...);
# ok($result, 'RETURN_UNDEF_371_5: add assertion here');

done_testing();
