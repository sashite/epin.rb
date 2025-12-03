#!/usr/bin/env ruby
# frozen_string_literal: true

require "simplecov"

SimpleCov.command_name "Unit Tests"
SimpleCov.start

# Tests for Sashite::Epin (Extended Piece Identifier Notation)
#
# Tests the EPIN implementation for Ruby, focusing on the minimal API
# with pure composition of PIN primitives conforming to EPIN v1.0.0 specification.
#
# Note: PIN functionality (type, side, state, terminal, transformations) is NOT tested here
# as it's already thoroughly tested in the PIN project. These tests focus only on:
# - EPIN-specific validation (with derivation marker)
# - Derivation status tracking and transformation
# - PIN component composition
# - Backward compatibility with PIN
#
# This test assumes the existence of:
# - lib/sashite-epin.rb

require_relative "lib/sashite-epin"
require "set"

# Helper function to run a test and report errors
def run_test(name)
  print "  #{name}... "
  yield
  puts "✓ Success"
rescue StandardError => e
  warn "✗ Failure: #{e.message}"
  warn "    #{e.backtrace.first}"
  exit(1)
end

puts
puts "Tests for Sashite::Epin (Extended Piece Identifier Notation) v1.0.0"
puts

# ==============================================================================
# MODULE-LEVEL VALIDATION TESTS
# ==============================================================================

run_test("Module EPIN validation accepts valid notations") do
  valid_epins = [
    # Basic pieces (native)
    "K", "k", "Q", "q", "R", "r", "B", "b", "N", "n", "P", "p",
    # With terminal markers (native)
    "K^", "k^", "Q^", "q^", "R^", "r^",
    # Enhanced pieces (native)
    "+K", "+k", "+Q", "+q", "+R", "+r",
    # Enhanced terminal (native)
    "+K^", "+k^", "+R^", "+r^",
    # Diminished pieces (native)
    "-K", "-k", "-P", "-p",
    # Diminished terminal (native)
    "-K^", "-k^", "-P^", "-p^",
    # Basic pieces (derived)
    "K'", "k'", "Q'", "q'", "R'", "r'", "B'", "b'", "N'", "n'", "P'", "p'",
    # With terminal markers (derived)
    "K^'", "k^'", "Q^'", "q^'", "R^'", "r^'",
    # Enhanced pieces (derived)
    "+K'", "+k'", "+Q'", "+q'", "+R'", "+r'",
    # Enhanced terminal (derived)
    "+K^'", "+k^'", "+R^'", "+r^'",
    # Diminished pieces (derived)
    "-K'", "-k'", "-P'", "-p'",
    # Diminished terminal (derived)
    "-K^'", "-k^'", "-P^'", "-p^'",
    # All letters
    "A", "Z", "a", "z", "A'", "Z'", "a'", "z'"
  ]

  valid_epins.each do |epin|
    raise "#{epin.inspect} should be valid" unless Sashite::Epin.valid?(epin)
  end
end

run_test("Module EPIN validation rejects invalid notations") do
  invalid_epins = [
    # Empty and duplicates
    "", "KK", "KK'", "++K", "--K", "K+", "K-",
    # Multiple derivation markers
    "K''", "K^''", "+K''", "+K^''", "k''", "+k^''",
    # Invalid marker positions
    "'K", "'K^", "'+K", "K'^", "+K'^", "K^+'",
    # Numbers and special characters
    "1", "9", "0", "1'", "K1'", "1K'",
    # Whitespace
    " K", "K ", "K' ", " K'", "K '", " +K'", "+K' ",
    # Invalid combinations
    "123", "ABC", "KKK'", "+++K'", "K^+'"
  ]

  invalid_epins.each do |epin|
    raise "#{epin.inspect} should be invalid" if Sashite::Epin.valid?(epin)
  end
end

run_test("Module EPIN validation handles non-string input") do
  non_strings = [nil, 123, :king, [], {}, true, false, 1.5]

  non_strings.each do |input|
    raise "#{input.inspect} should be invalid" if Sashite::Epin.valid?(input)
  end
end

# ==============================================================================
# MODULE-LEVEL PARSING TESTS
# ==============================================================================

run_test("Module parse delegates to Identifier class") do
  epin_string = "K^'"
  epin = Sashite::Epin.parse(epin_string)

  raise "parse should return Identifier instance" unless epin.is_a?(Sashite::Epin::Identifier)
  raise "epin should have correct EPIN string" unless epin.to_s == epin_string
end

run_test("Module parse handles native and derived pieces") do
  native = Sashite::Epin.parse("K^")
  derived = Sashite::Epin.parse("K^'")

  raise "native should not be derived" if native.derived?
  raise "native should be native" unless native.native?
  raise "derived should be derived" unless derived.derived?
  raise "derived should not be native" if derived.native?
end

run_test("Module new creates identifier from PIN component") do
  pin = Sashite::Pin.parse("K^")

  native = Sashite::Epin.new(pin, derived: false)
  raise "new should return Identifier instance" unless native.is_a?(Sashite::Epin::Identifier)
  raise "native should have correct PIN" unless native.pin == pin
  raise "native should not be derived" if native.derived?
  raise "native should have correct EPIN string" unless native.to_s == "K^"

  derived = Sashite::Epin.new(pin, derived: true)
  raise "derived should have correct PIN" unless derived.pin == pin
  raise "derived should be derived" unless derived.derived?
  raise "derived should have correct EPIN string" unless derived.to_s == "K^'"
end

# ==============================================================================
# IDENTIFIER CREATION AND PARSING TESTS
# ==============================================================================

run_test("Identifier.parse creates correct instances from EPIN strings") do
  test_cases = {
    "K" => { derived: false, pin_string: "K" },
    "K'" => { derived: true, pin_string: "K" },
    "K^" => { derived: false, pin_string: "K^" },
    "K^'" => { derived: true, pin_string: "K^" },
    "+R" => { derived: false, pin_string: "+R" },
    "+R'" => { derived: true, pin_string: "+R" },
    "+R^" => { derived: false, pin_string: "+R^" },
    "+R^'" => { derived: true, pin_string: "+R^" },
    "-p" => { derived: false, pin_string: "-p" },
    "-p'" => { derived: true, pin_string: "-p" },
    "-p^" => { derived: false, pin_string: "-p^" },
    "-p^'" => { derived: true, pin_string: "-p^" }
  }

  test_cases.each do |epin_string, expected|
    epin = Sashite::Epin.parse(epin_string)

    raise "#{epin_string}: wrong derived status" unless epin.derived? == expected[:derived]
    raise "#{epin_string}: wrong PIN string" unless epin.pin.to_s == expected[:pin_string]
    raise "#{epin_string}: wrong EPIN string" unless epin.to_s == epin_string
  end
end

run_test("Identifier constructor with PIN component") do
  test_cases = [
    ["K^", false, "K^"],
    ["K^", true, "K^'"],
    ["+R", false, "+R"],
    ["+R", true, "+R'"],
    ["-p", false, "-p"],
    ["-p", true, "-p'"]
  ]

  test_cases.each do |pin_string, derived, expected_epin|
    pin = Sashite::Pin.parse(pin_string)
    epin = Sashite::Epin::Identifier.new(pin, derived: derived)

    raise "PIN should be #{pin_string}" unless epin.pin.to_s == pin_string
    raise "derived should be #{derived}" unless epin.derived? == derived
    raise "EPIN string should be #{expected_epin}" unless epin.to_s == expected_epin
  end
end

# ==============================================================================
# PIN COMPONENT ACCESS TESTS
# ==============================================================================

run_test("Identifier provides access to PIN component") do
  test_cases = ["K^", "K^'", "+R", "+R'", "-p", "-p'"]

  test_cases.each do |epin_string|
    epin = Sashite::Epin.parse(epin_string)

    raise "#{epin_string}: should have PIN component" unless epin.pin.is_a?(Sashite::Pin::Identifier)
    raise "#{epin_string}: PIN component should be frozen" unless epin.pin.frozen?

    # Verify PIN string matches (remove derivation marker if present)
    expected_pin = epin_string.end_with?("'") ? epin_string[0...-1] : epin_string
    raise "#{epin_string}: PIN string mismatch" unless epin.pin.to_s == expected_pin
  end
end

run_test("Identifier PIN component access is direct reference") do
  pin = Sashite::Pin.parse("K^")
  epin = Sashite::Epin.new(pin, derived: false)

  # PIN component should be the same object
  raise "PIN component should be same object" unless epin.pin.equal?(pin)
end

# ==============================================================================
# STRING REPRESENTATION TESTS
# ==============================================================================

run_test("Identifier to_s returns correct EPIN string") do
  test_cases = [
    ["K^", false, "K^"],
    ["K^", true, "K^'"],
    ["+R", false, "+R"],
    ["+R", true, "+R'"],
    ["-p", false, "-p"],
    ["-p", true, "-p'"]
  ]

  test_cases.each do |pin_string, derived, expected|
    pin = Sashite::Pin.parse(pin_string)
    epin = Sashite::Epin::Identifier.new(pin, derived: derived)
    result = epin.to_s

    raise "#{pin_string}, #{derived} should be #{expected}, got #{result}" unless result == expected
  end
end

run_test("Identifier suffix method returns correct derivation marker") do
  native = Sashite::Epin.parse("K^")
  derived = Sashite::Epin.parse("K^'")

  raise "native suffix should be empty" unless native.suffix == ""
  raise "derived suffix should be '" unless derived.suffix == "'"
end

# ==============================================================================
# DERIVATION TRANSFORMATION TESTS
# ==============================================================================

run_test("Identifier derivation transformations return new instances") do
  epin = Sashite::Epin.parse("K^")

  # Test mark_derived
  derived = epin.mark_derived
  raise "mark_derived should return new instance" if derived.equal?(epin)
  raise "derived should be derived" unless derived.derived?
  raise "original should be unchanged" if epin.derived?
  raise "derived should have correct string" unless derived.to_s == "K^'"

  # Test unmark_native
  back_to_native = derived.unmark_native
  raise "unmark_native should return new instance" if back_to_native.equal?(derived)
  raise "back to native should not be derived" if back_to_native.derived?
  raise "back to native should have correct string" unless back_to_native.to_s == "K^"

  # Test with_derived
  toggled = epin.with_derived(true)
  raise "with_derived should return new instance" if toggled.equal?(epin)
  raise "toggled should be derived" unless toggled.derived?
  raise "toggled should have correct string" unless toggled.to_s == "K^'"
end

run_test("Identifier derivation transformations preserve PIN component") do
  pin_string = "+R^"
  epin = Sashite::Epin.parse(pin_string)

  # mark_derived should preserve PIN
  derived = epin.mark_derived
  raise "mark_derived should preserve PIN" unless derived.pin.to_s == pin_string
  raise "derived should have correct string" unless derived.to_s == "+R^'"

  # unmark_native should preserve PIN
  back = derived.unmark_native
  raise "unmark_native should preserve PIN" unless back.pin.to_s == pin_string
  raise "back should have correct string" unless back.to_s == "+R^"

  # with_derived should preserve PIN
  toggled = epin.with_derived(true)
  raise "with_derived should preserve PIN" unless toggled.pin.to_s == pin_string
end

run_test("Identifier derivation transformations return self when appropriate") do
  native = Sashite::Epin.parse("K^")
  derived = Sashite::Epin.parse("K^'")

  # mark_derived on already derived should return self
  raise "mark_derived on derived should return self" unless derived.mark_derived.equal?(derived)

  # unmark_native on already native should return self
  raise "unmark_native on native should return self" unless native.unmark_native.equal?(native)

  # with_derived with same value should return self
  raise "with_derived(false) on native should return self" unless native.with_derived(false).equal?(native)
  raise "with_derived(true) on derived should return self" unless derived.with_derived(true).equal?(derived)
end

# ==============================================================================
# PIN REPLACEMENT TESTS
# ==============================================================================

run_test("Identifier with_pin replaces PIN component") do
  epin = Sashite::Epin.parse("K^'")
  new_pin = Sashite::Pin.parse("Q^")

  result = epin.with_pin(new_pin)

  raise "with_pin should return new instance" if result.equal?(epin)
  raise "result should have new PIN" unless result.pin == new_pin
  raise "result should preserve derivation" unless result.derived?
  raise "result should have correct string" unless result.to_s == "Q^'"
  raise "original should be unchanged" unless epin.to_s == "K^'"
end

run_test("Identifier with_pin preserves derivation status") do
  test_cases = [
    ["K^", false, "Q^", "Q^"],
    ["K^'", true, "Q^", "Q^'"],
    ["+R", false, "-P", "-P"],
    ["+R'", true, "-P", "-P'"]
  ]

  test_cases.each do |original_epin, original_derived, new_pin_str, expected|
    epin = Sashite::Epin.parse(original_epin)
    new_pin = Sashite::Pin.parse(new_pin_str)
    result = epin.with_pin(new_pin)

    raise "#{original_epin}: derived status should be preserved" unless result.derived? == original_derived
    raise "#{original_epin}: result should be #{expected}" unless result.to_s == expected
  end
end

run_test("Identifier with_pin returns self when PIN is same") do
  epin = Sashite::Epin.parse("K^'")
  same_pin = epin.pin

  result = epin.with_pin(same_pin)
  raise "with_pin with same PIN should return self" unless result.equal?(epin)
end

run_test("Identifier with_pin validates PIN component") do
  epin = Sashite::Epin.parse("K^")

  begin
    epin.with_pin("not a pin")
    raise "Should have raised error for invalid PIN"
  rescue ArgumentError => e
    raise "Error should mention PIN" unless e.message.include?("Pin::Identifier")
  end
end

# ==============================================================================
# TRANSFORMATION CHAINS TESTS
# ==============================================================================

run_test("Identifier transformation chains work correctly") do
  epin = Sashite::Epin.parse("K^")

  # Chain: change PIN then mark derived
  result1 = epin
    .with_pin(epin.pin.with_type(:Q))
    .mark_derived
  raise "chain 1 should work" unless result1.to_s == "Q^'"

  # Chain: mark derived then change PIN
  result2 = epin
    .mark_derived
    .with_pin(epin.pin.with_type(:Q))
  raise "chain 2 should work" unless result2.to_s == "Q^'"

  # Chain: complex
  result3 = epin
    .mark_derived
    .with_pin(epin.pin.with_type(:Q).with_state(:enhanced))
    .unmark_native
    .mark_derived
  raise "chain 3 should work" unless result3.to_s == "+Q^'"

  # Original unchanged
  raise "original should be unchanged" unless epin.to_s == "K^"
end

# ==============================================================================
# IMMUTABILITY TESTS
# ==============================================================================

run_test("Identifier immutability") do
  epin = Sashite::Epin.parse("K^'")

  # Test that epin is frozen
  raise "epin should be frozen" unless epin.frozen?

  # Test that mutations don't affect original
  original_string = epin.to_s
  derived = epin.mark_derived
  native = epin.unmark_native
  changed_pin = epin.with_pin(epin.pin.with_type(:Q))

  raise "original should be unchanged after mark_derived" unless epin.to_s == original_string
  raise "original should be unchanged after unmark_native" unless epin.to_s == original_string
  raise "original should be unchanged after with_pin" unless epin.to_s == original_string
end

# ==============================================================================
# EQUALITY AND HASH TESTS
# ==============================================================================

run_test("Identifier equality and hash") do
  epin1 = Sashite::Epin.parse("K^")
  epin2 = Sashite::Epin.parse("K^")
  epin3 = Sashite::Epin.parse("K^'")
  epin4 = Sashite::Epin.parse("Q^")

  # Test equality
  raise "identical epins should be equal" unless epin1 == epin2
  raise "different derivation should not be equal" if epin1 == epin3
  raise "different PIN should not be equal" if epin1 == epin4

  # Test hash consistency
  raise "equal epins should have same hash" unless epin1.hash == epin2.hash

  # Test in hash/set
  epins_set = Set.new([epin1, epin2, epin3, epin4])
  raise "set should contain 3 unique epins" unless epins_set.size == 3
end

run_test("Identifier equality considers both PIN and derivation") do
  pin = Sashite::Pin.parse("K^")
  native = Sashite::Epin.new(pin, derived: false)
  derived = Sashite::Epin.new(pin, derived: true)

  raise "same PIN but different derivation should not be equal" if native == derived
  raise "different derivation should have different hash" if native.hash == derived.hash
end

# ==============================================================================
# QUERY METHODS TESTS
# ==============================================================================

run_test("Identifier native? and derived? methods") do
  native = Sashite::Epin.parse("K^")
  derived = Sashite::Epin.parse("K^'")

  # Test derived?
  raise "native should not be derived" if native.derived?
  raise "derived should be derived" unless derived.derived?

  # Test native?
  raise "native should be native" unless native.native?
  raise "derived should not be native" if derived.native?

  # Test that they are opposites
  raise "native? should be opposite of derived?" unless native.native? == !native.derived?
  raise "derived? should be opposite of native?" unless derived.derived? == !derived.native?
end

run_test("Identifier same_derivation? method") do
  native1 = Sashite::Epin.parse("K^")
  native2 = Sashite::Epin.parse("Q^")
  derived1 = Sashite::Epin.parse("K^'")
  derived2 = Sashite::Epin.parse("Q^'")

  raise "native pieces should have same derivation" unless native1.same_derivation?(native2)
  raise "derived pieces should have same derivation" unless derived1.same_derivation?(derived2)
  raise "native and derived should not have same derivation" if native1.same_derivation?(derived1)
end

# ==============================================================================
# ERROR HANDLING TESTS
# ==============================================================================

run_test("Identifier error handling for invalid PIN component") do
  begin
    Sashite::Epin::Identifier.new("not a pin", derived: false)
    raise "Should have raised error for non-PIN"
  rescue ArgumentError => e
    raise "Error should mention Pin::Identifier" unless e.message.include?("Pin::Identifier")
  end

  begin
    Sashite::Epin::Identifier.new(nil, derived: false)
    raise "Should have raised error for nil"
  rescue ArgumentError => e
    raise "Error should mention Pin::Identifier" unless e.message.include?("Pin::Identifier")
  end
end

run_test("Identifier error handling for invalid EPIN strings") do
  invalid_epins = ["", "KK'", "K''", "'K", "K^''", "+++K'", "invalid"]

  invalid_epins.each do |epin|
    begin
      Sashite::Epin.parse(epin)
      raise "Should have raised error for #{epin.inspect}"
    rescue ArgumentError
      # Expected
    end
  end
end

# ==============================================================================
# BACKWARD COMPATIBILITY TESTS
# ==============================================================================

run_test("All valid PIN tokens are valid EPIN tokens") do
  # Test that all PIN tokens can be parsed as EPIN (native)
  pin_tokens = [
    "K", "k", "Q", "q", "R", "r", "B", "b", "N", "n", "P", "p",
    "K^", "k^", "+R", "+r", "-p", "-P", "+K^", "+k^", "-P^", "-p^"
  ]

  pin_tokens.each do |token|
    # Should be valid EPIN
    raise "PIN token #{token} should be valid EPIN" unless Sashite::Epin.valid?(token)

    # Should parse as native EPIN
    epin = Sashite::Epin.parse(token)
    raise "PIN token #{token} should parse as native" if epin.derived?
    raise "PIN token #{token} should preserve string" unless epin.to_s == token

    # PIN component should match
    raise "PIN token #{token} should have matching PIN component" unless epin.pin.to_s == token
  end
end

run_test("EPIN can be created from any PIN identifier") do
  # Test that any PIN identifier can be wrapped in EPIN
  pin_tokens = ["K^", "+R", "-p", "+K^", "-P^"]

  pin_tokens.each do |token|
    pin = Sashite::Pin.parse(token)

    # Create native EPIN
    native = Sashite::Epin.new(pin, derived: false)
    raise "native EPIN should preserve PIN string" unless native.to_s == token

    # Create derived EPIN
    derived = Sashite::Epin.new(pin, derived: true)
    expected_derived = "#{token}'"
    raise "derived EPIN should add marker" unless derived.to_s == expected_derived
  end
end

# ==============================================================================
# ROUNDTRIP PARSING TESTS
# ==============================================================================

run_test("Roundtrip parsing consistency") do
  test_cases = [
    "K", "K'", "k", "k'",
    "K^", "K^'", "k^", "k^'",
    "+R", "+R'", "+r", "+r'",
    "+R^", "+R^'", "+r^", "+r^'",
    "-P", "-P'", "-p", "-p'",
    "-P^", "-P^'", "-p^", "-p^'"
  ]

  test_cases.each do |epin_string|
    # Parse -> to_s -> parse -> compare
    epin1 = Sashite::Epin.parse(epin_string)
    string = epin1.to_s
    epin2 = Sashite::Epin.parse(string)

    raise "Roundtrip failed for #{epin_string}: string mismatch" unless string == epin_string
    raise "Roundtrip failed for #{epin_string}: epin mismatch" unless epin1 == epin2
    raise "Roundtrip failed for #{epin_string}: PIN mismatch" unless epin1.pin == epin2.pin
    raise "Roundtrip failed for #{epin_string}: derivation mismatch" unless epin1.derived? == epin2.derived?
  end
end

# ==============================================================================
# PRACTICAL USAGE TESTS
# ==============================================================================

run_test("Practical usage - piece collections") do
  epins = [
    Sashite::Epin.parse("K^"),    # Native king
    Sashite::Epin.parse("K^'"),   # Derived king
    Sashite::Epin.parse("+R"),    # Native enhanced rook
    Sashite::Epin.parse("+R'"),   # Derived enhanced rook
    Sashite::Epin.parse("P"),     # Native pawn
    Sashite::Epin.parse("P'")     # Derived pawn
  ]

  # Filter by derivation
  native_pieces = epins.select(&:native?)
  derived_pieces = epins.select(&:derived?)
  raise "Should have 3 native pieces" unless native_pieces.size == 3
  raise "Should have 3 derived pieces" unless derived_pieces.size == 3

  # Filter by PIN attributes (via component)
  terminal_pieces = epins.select { |e| e.pin.terminal? }
  enhanced_pieces = epins.select { |e| e.pin.enhanced? }
  raise "Should have 2 terminal pieces" unless terminal_pieces.size == 2
  raise "Should have 2 enhanced pieces" unless enhanced_pieces.size == 2

  # Group by derivation
  by_derivation = epins.group_by(&:derived?)
  raise "Should have native group" unless by_derivation[false].size == 3
  raise "Should have derived group" unless by_derivation[true].size == 3
end

run_test("Practical usage - cross-style game simulation") do
  # Simulate Chess vs Makruk match
  # First player uses Chess style (native), can have Makruk pieces (derived)
  # Second player uses Makruk style (native), can have Chess pieces (derived)

  chess_king = Sashite::Epin.parse("K^")      # Native Chess king
  makruk_pawn = Sashite::Epin.parse("P'")     # Derived Makruk pawn (captured/promoted)

  raise "chess_king should be native" unless chess_king.native?
  raise "makruk_pawn should be derived" unless makruk_pawn.derived?

  # Simulate capturing opponent's piece and converting it
  opponent_piece = Sashite::Epin.parse("p")   # Opponent's native pawn
  captured = Sashite::Epin.new(
    opponent_piece.pin.flip,                  # Flip side
    derived: true                              # Now derived for captor
  )
  raise "captured piece should be derived" unless captured.derived?
  raise "captured piece should be first player" unless captured.pin.first_player?
end

# ==============================================================================
# ALL 26 LETTERS TESTS
# ==============================================================================

run_test("All 26 ASCII letters work correctly with derivation") do
  letters = ("A".."Z").to_a

  letters.each do |letter|
    # Test uppercase (first player)
    native_upper = Sashite::Epin.parse(letter)
    derived_upper = Sashite::Epin.parse("#{letter}'")

    raise "#{letter} native should be valid" unless native_upper.pin.to_s == letter
    raise "#{letter} derived should be valid" unless derived_upper.pin.to_s == letter
    raise "#{letter} native should not be derived" if native_upper.derived?
    raise "#{letter} derived should be derived" unless derived_upper.derived?

    # Test lowercase (second player)
    lower = letter.downcase
    native_lower = Sashite::Epin.parse(lower)
    derived_lower = Sashite::Epin.parse("#{lower}'")

    raise "#{lower} native should be valid" unless native_lower.pin.to_s == lower
    raise "#{lower} derived should be valid" unless derived_lower.pin.to_s == lower
    raise "#{lower} native should not be derived" if native_lower.derived?
    raise "#{lower} derived should be derived" unless derived_lower.derived?
  end
end

# ==============================================================================
# REGEX COMPLIANCE TESTS
# ==============================================================================

run_test("Regex pattern compliance with spec") do
  # Test against the specification regex: \A[-+]?[A-Za-z]\^?'?\z
  spec_regex = /\A[-+]?[A-Za-z]\^?'?\z/

  test_strings = [
    "K", "k", "K'", "k'", "K^", "K^'", "+K", "+K'", "-k", "-k'", "+K^", "+K^'",
    "", "KK", "K''", "++K", "K+", "'K", "123", "K1", "KING"
  ]

  test_strings.each do |string|
    spec_match = string.match?(spec_regex)
    epin_valid = Sashite::Epin.valid?(string)

    # For valid regex matches, also check PIN validity
    if spec_match
      has_marker = string.end_with?("'")
      pin_part = has_marker ? string[0...-1] : string
      pin_valid = Sashite::Pin.valid?(pin_part)

      # EPIN should only be valid if PIN part is valid
      expected = pin_valid && string.count("'") <= 1
      raise "#{string.inspect}: expected #{expected}, got #{epin_valid}" unless epin_valid == expected
    else
      raise "#{string.inspect}: should be invalid" if epin_valid
    end
  end
end

# ==============================================================================
# PERFORMANCE TESTS
# ==============================================================================

run_test("Performance - repeated operations") do
  pin = Sashite::Pin.parse("K^")

  1000.times do
    epin = Sashite::Epin.new(pin, derived: false)
    derived = epin.mark_derived
    native = derived.unmark_native
    changed = epin.with_pin(epin.pin.with_type(:Q))

    raise "Performance test failed" unless Sashite::Epin.valid?("K^")
    raise "Performance test failed" unless Sashite::Epin.valid?("K^'")
    raise "Performance test failed" unless derived.derived?
    raise "Performance test failed" unless native.native?
    raise "Performance test failed" unless changed.pin.type == :Q
  end
end

puts
puts "All EPIN v1.0.0 tests passed!"
puts
