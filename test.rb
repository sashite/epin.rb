# frozen_string_literal: true

require "simplecov"

SimpleCov.command_name "Unit Tests"
SimpleCov.start

# Tests for Sashite::Epin (Extended Piece Identifier Notation)
#
# Comprehensive test suite covering:
# - EPIN validation and parsing with derivation markers
# - Style derivation (native vs foreign)
# - PIN compatibility and extension
# - Terminal marker integration with derivation
# - Immutability and transformations with style
# - Cross-style game scenarios

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
puts "Tests for Sashite::Epin (Extended Piece Identifier Notation)"
puts

# ==============================================================================
# MODULE-LEVEL VALIDATION TESTS
# ==============================================================================

run_test("Module EPIN validation accepts valid notations") do
  valid_epins = [
    # Native pieces (PIN compatible)
    "K", "k", "Q", "q", "R", "r", "B", "b", "N", "n", "P", "p",
    "+K", "+k", "-P", "-p",
    # Terminal pieces
    "K^", "k^", "+R^", "-p^",
    # Foreign/derived pieces
    "K'", "k'", "Q'", "q'", "R'", "r'",
    "+K'", "+k'", "-P'", "-p'",
    # Foreign terminal pieces
    "K^'", "k^'", "+R^'", "-p^'"
  ]

  valid_epins.each do |epin|
    raise "#{epin.inspect} should be valid" unless Sashite::Epin.valid?(epin)
  end
end

run_test("Module EPIN validation rejects invalid notations") do
  invalid_epins = [
    # Invalid PIN part
    "", "KK", "++K", "--K",
    # Invalid derivation position (must be after terminal marker)
    "K'^", "k'^", "+R'^", "'K", "'k",
    # Multiple derivation markers
    "K''", "k''",
    # Other invalid patterns
    "K+", "K-", "1", "!", "K K", " K'"
  ]

  invalid_epins.each do |epin|
    raise "#{epin.inspect} should be invalid" if Sashite::Epin.valid?(epin)
  end
end

run_test("Module EPIN validation handles non-string input") do
  non_strings = [nil, 123, :king, [], {}, true, false]

  non_strings.each do |input|
    raise "#{input.inspect} should be invalid" if Sashite::Epin.valid?(input)
  end
end

# ==============================================================================
# PARSING TESTS
# ==============================================================================

run_test("EPIN parse creates correct native instances") do
  test_cases = {
    "K" => { type: :K, side: :first, state: :normal, native: true, terminal: false },
    "k" => { type: :K, side: :second, state: :normal, native: true, terminal: false },
    "+R" => { type: :R, side: :first, state: :enhanced, native: true, terminal: false },
    "-p" => { type: :P, side: :second, state: :diminished, native: true, terminal: false },
    "K^" => { type: :K, side: :first, state: :normal, native: true, terminal: true },
    "+K^" => { type: :K, side: :first, state: :enhanced, native: true, terminal: true }
  }

  test_cases.each do |epin_string, expected|
    piece = Sashite::Epin.parse(epin_string)

    raise "#{epin_string}: wrong type" unless piece.type == expected[:type]
    raise "#{epin_string}: wrong side" unless piece.side == expected[:side]
    raise "#{epin_string}: wrong state" unless piece.state == expected[:state]
    raise "#{epin_string}: wrong native" unless piece.native == expected[:native]
    raise "#{epin_string}: wrong terminal" unless piece.terminal? == expected[:terminal]
  end
end

run_test("EPIN parse creates correct foreign instances") do
  test_cases = {
    "K'" => { type: :K, side: :first, state: :normal, native: false, terminal: false },
    "k'" => { type: :K, side: :second, state: :normal, native: false, terminal: false },
    "+R'" => { type: :R, side: :first, state: :enhanced, native: false, terminal: false },
    "-p'" => { type: :P, side: :second, state: :diminished, native: false, terminal: false },
    "K^'" => { type: :K, side: :first, state: :normal, native: false, terminal: true },
    "+K^'" => { type: :K, side: :first, state: :enhanced, native: false, terminal: true }
  }

  test_cases.each do |epin_string, expected|
    piece = Sashite::Epin.parse(epin_string)

    raise "#{epin_string}: wrong type" unless piece.type == expected[:type]
    raise "#{epin_string}: wrong side" unless piece.side == expected[:side]
    raise "#{epin_string}: wrong state" unless piece.state == expected[:state]
    raise "#{epin_string}: wrong native" unless piece.native == expected[:native]
    raise "#{epin_string}: wrong terminal" unless piece.terminal? == expected[:terminal]
  end
end

run_test("EPIN constructor with native and foreign parameters") do
  native_piece = Sashite::Epin::Identifier.new(:K, :first, :normal, true, terminal: false)
  foreign_piece = Sashite::Epin::Identifier.new(:K, :first, :normal, false, terminal: false)

  raise "native piece should be native" unless native_piece.native?
  raise "foreign piece should be foreign" unless foreign_piece.derived?
  raise "native piece should output K" unless native_piece.to_s == "K"
  raise "foreign piece should output K'" unless foreign_piece.to_s == "K'"
end

# ==============================================================================
# TO_STRING AND DISPLAY TESTS
# ==============================================================================

run_test("EPIN to_s returns correct notation") do
  test_cases = [
    [:K, :first, :normal, true, false, "K"],
    [:K, :first, :normal, false, false, "K'"],
    [:K, :second, :normal, true, false, "k"],
    [:K, :second, :normal, false, false, "k'"],
    [:R, :first, :enhanced, true, false, "+R"],
    [:R, :first, :enhanced, false, false, "+R'"],
    [:P, :second, :diminished, true, false, "-p"],
    [:P, :second, :diminished, false, false, "-p'"],
    [:K, :first, :normal, true, true, "K^"],
    [:K, :first, :normal, false, true, "K^'"],
    [:R, :first, :enhanced, true, true, "+R^"],
    [:R, :first, :enhanced, false, true, "+R^'"]
  ]

  test_cases.each do |type, side, state, native, terminal, expected|
    piece = Sashite::Epin::Identifier.new(type, side, state, native, terminal: terminal)
    result = piece.to_s

    raise "#{expected}: got #{result}" unless result == expected
  end
end

run_test("EPIN derivation_marker method") do
  native = Sashite::Epin.parse("K")
  foreign = Sashite::Epin.parse("K'")

  raise "native should have empty derivation marker" unless native.derivation_marker == ""
  raise "foreign should have ' derivation marker" unless foreign.derivation_marker == "'"
end

run_test("EPIN suffix is alias for derivation_marker") do
  native = Sashite::Epin.parse("K")
  foreign = Sashite::Epin.parse("K'")

  raise "suffix should equal derivation_marker for native" unless native.suffix == native.derivation_marker
  raise "suffix should equal derivation_marker for foreign" unless foreign.suffix == foreign.derivation_marker
end

# ==============================================================================
# STYLE DERIVATION TESTS
# ==============================================================================

run_test("EPIN derive and underive transformations") do
  native_piece = Sashite::Epin::Identifier.new(:K, :first, :normal, true, terminal: false)

  # Derive
  foreign = native_piece.derive
  raise "derive should return new instance" if foreign.equal?(native_piece)
  raise "derived piece should be foreign" unless foreign.derived?
  raise "derived piece should output K'" unless foreign.to_s == "K'"
  raise "original should be unchanged" unless native_piece.native?

  # Underive
  back_to_native = foreign.underive
  raise "underive should return new instance" if back_to_native.equal?(foreign)
  raise "underived piece should be native" unless back_to_native.native?
  raise "underived piece should output K" unless back_to_native.to_s == "K"
  raise "original foreign should be unchanged" unless foreign.derived?
end

run_test("EPIN derive returns self if already foreign") do
  foreign_piece = Sashite::Epin::Identifier.new(:K, :first, :normal, false, terminal: false)
  result = foreign_piece.derive

  raise "derive on foreign piece should return self" unless result.equal?(foreign_piece)
end

run_test("EPIN underive returns self if already native") do
  native_piece = Sashite::Epin::Identifier.new(:K, :first, :normal, true, terminal: false)
  result = native_piece.underive

  raise "underive on native piece should return self" unless result.equal?(native_piece)
end

run_test("EPIN with_derivation transformation") do
  piece = Sashite::Epin::Identifier.new(:K, :first, :normal, true, terminal: false)

  foreign = piece.with_derivation(false)
  raise "with_derivation(false) should return new instance" if foreign.equal?(piece)
  raise "new piece should be foreign" unless foreign.derived?

  back_to_native = foreign.with_derivation(true)
  raise "with_derivation(true) should return new instance" if back_to_native.equal?(foreign)
  raise "new piece should be native" unless back_to_native.native?
end

run_test("EPIN with_derivation returns self if same derivation") do
  native = Sashite::Epin::Identifier.new(:K, :first, :normal, true, terminal: false)
  foreign = Sashite::Epin::Identifier.new(:K, :first, :normal, false, terminal: false)

  raise "with_derivation(true) on native should return self" unless native.with_derivation(true).equal?(native)
  raise "with_derivation(false) on foreign should return self" unless foreign.with_derivation(false).equal?(foreign)
end

# ==============================================================================
# STYLE QUERIES TESTS
# ==============================================================================

run_test("EPIN style queries") do
  native = Sashite::Epin::Identifier.new(:K, :first, :normal, true, terminal: false)
  foreign = Sashite::Epin::Identifier.new(:K, :first, :normal, false, terminal: false)

  raise "native piece should be native?" unless native.native?
  raise "native piece should not be derived?" if native.derived?
  raise "native piece should not be foreign?" if native.foreign?

  raise "foreign piece should be derived?" unless foreign.derived?
  raise "foreign piece should be foreign?" unless foreign.foreign?
  raise "foreign piece should not be native?" if foreign.native?
end

run_test("EPIN same_style? comparison") do
  native1 = Sashite::Epin::Identifier.new(:K, :first, :normal, true, terminal: false)
  native2 = Sashite::Epin::Identifier.new(:Q, :second, :enhanced, true, terminal: false)
  foreign1 = Sashite::Epin::Identifier.new(:K, :first, :normal, false, terminal: false)
  foreign2 = Sashite::Epin::Identifier.new(:R, :second, :diminished, false, terminal: false)

  raise "native pieces should be same_style" unless native1.same_style?(native2)
  raise "foreign pieces should be same_style" unless foreign1.same_style?(foreign2)
  raise "native and foreign should not be same_style" if native1.same_style?(foreign1)
end

# ==============================================================================
# STATE AND TERMINAL PRESERVATION WITH DERIVATION
# ==============================================================================

run_test("EPIN state transformations preserve derivation") do
  native = Sashite::Epin::Identifier.new(:K, :first, :normal, true, terminal: false)
  foreign = Sashite::Epin::Identifier.new(:K, :first, :normal, false, terminal: false)

  # Test enhance preserves derivation
  enhanced_native = native.enhance
  enhanced_foreign = foreign.enhance
  raise "enhance should preserve native" unless enhanced_native.native?
  raise "enhance should preserve foreign" unless enhanced_foreign.derived?
  raise "enhanced native should be +K" unless enhanced_native.to_s == "+K"
  raise "enhanced foreign should be +K'" unless enhanced_foreign.to_s == "+K'"

  # Test diminish preserves derivation
  diminished_native = native.diminish
  diminished_foreign = foreign.diminish
  raise "diminish should preserve native" unless diminished_native.native?
  raise "diminish should preserve foreign" unless diminished_foreign.derived?
end

run_test("EPIN terminal transformations preserve derivation") do
  native = Sashite::Epin::Identifier.new(:K, :first, :normal, true, terminal: false)
  foreign = Sashite::Epin::Identifier.new(:K, :first, :normal, false, terminal: false)

  terminal_native = native.mark_terminal
  terminal_foreign = foreign.mark_terminal

  raise "mark_terminal should preserve native" unless terminal_native.native?
  raise "mark_terminal should preserve foreign" unless terminal_foreign.derived?
  raise "terminal native should be K^" unless terminal_native.to_s == "K^"
  raise "terminal foreign should be K^'" unless terminal_foreign.to_s == "K^'"
end

run_test("EPIN derivation transformations preserve terminal") do
  terminal_native = Sashite::Epin::Identifier.new(:K, :first, :normal, true, terminal: true)
  terminal_foreign = Sashite::Epin::Identifier.new(:K, :first, :normal, false, terminal: true)

  derived = terminal_native.derive
  underived = terminal_foreign.underive

  raise "derive should preserve terminal" unless derived.terminal?
  raise "underive should preserve terminal" unless underived.terminal?
  raise "derived terminal should be K^'" unless derived.to_s == "K^'"
  raise "underived terminal should be K^" unless underived.to_s == "K^"
end

run_test("EPIN attribute transformations preserve derivation") do
  foreign = Sashite::Epin::Identifier.new(:K, :first, :normal, false, terminal: false)

  with_type = foreign.with_type(:Q)
  with_side = foreign.with_side(:second)
  with_state = foreign.with_state(:enhanced)

  raise "with_type should preserve foreign" unless with_type.derived?
  raise "with_side should preserve foreign" unless with_side.derived?
  raise "with_state should preserve foreign" unless with_state.derived?
end

# ==============================================================================
# EQUALITY AND HASH TESTS
# ==============================================================================

run_test("EPIN equality includes derivation") do
  native = Sashite::Epin::Identifier.new(:K, :first, :normal, true, terminal: false)
  foreign = Sashite::Epin::Identifier.new(:K, :first, :normal, false, terminal: false)
  native2 = Sashite::Epin::Identifier.new(:K, :first, :normal, true, terminal: false)

  raise "identical native pieces should be equal" unless native == native2
  raise "native and foreign should not be equal" if native == foreign
end

run_test("EPIN hash consistency with derivation") do
  native = Sashite::Epin::Identifier.new(:K, :first, :normal, true, terminal: false)
  foreign = Sashite::Epin::Identifier.new(:K, :first, :normal, false, terminal: false)
  native2 = Sashite::Epin::Identifier.new(:K, :first, :normal, true, terminal: false)

  raise "equal pieces should have same hash" unless native.hash == native2.hash
  raise "different derivation should have different hash" if native.hash == foreign.hash
end

run_test("EPIN in collections") do
  native = Sashite::Epin::Identifier.new(:K, :first, :normal, true, terminal: false)
  foreign = Sashite::Epin::Identifier.new(:K, :first, :normal, false, terminal: false)
  native_duplicate = Sashite::Epin::Identifier.new(:K, :first, :normal, true, terminal: false)

  pieces_set = Set.new([native, foreign, native_duplicate])
  raise "set should contain 2 unique pieces" unless pieces_set.size == 2
end

# ==============================================================================
# PIN COMPATIBILITY TESTS
# ==============================================================================

run_test("EPIN accepts all valid PIN strings as native pieces") do
  pin_strings = ["K", "k", "+R", "-p", "K^", "+K^", "-p^"]

  pin_strings.each do |pin|
    raise "#{pin} should be valid EPIN" unless Sashite::Epin.valid?(pin)

    epin_piece = Sashite::Epin.parse(pin)
    raise "#{pin} should be parsed as native" unless epin_piece.native?
    raise "#{pin} should roundtrip correctly" unless epin_piece.to_s == pin
  end
end

run_test("EPIN extends PIN with derivation markers") do
  # Native pieces (PIN compatible)
  native = Sashite::Epin.parse("K")
  raise "native piece should have no derivation marker" unless native.to_s == "K"

  # Foreign pieces (EPIN extension)
  foreign = Sashite::Epin.parse("K'")
  raise "foreign piece should have derivation marker" unless foreign.to_s == "K'"

  # Both should have same PIN attributes
  raise "same type" unless native.type == foreign.type
  raise "same side" unless native.side == foreign.side
  raise "same state" unless native.state == foreign.state
end

run_test("EPIN to PIN conversion for native pieces") do
  test_cases = ["K", "k", "+R", "-p", "K^", "+K^'"]

  test_cases.each do |epin_string|
    epin_piece = Sashite::Epin.parse(epin_string)

    # For native pieces, we can strip derivation to get PIN
    if epin_piece.native?
      pin_equivalent = "#{epin_piece.prefix}#{epin_piece.letter}#{epin_piece.terminal_marker}"
      raise "native EPIN should convert to PIN" unless Sashite::Pin.valid?(pin_equivalent)
    end
  end
end

# ==============================================================================
# CROSS-STYLE GAME SCENARIOS
# ==============================================================================

run_test("Cross-style Chess vs ShÅgi scenario") do
  # First player: Chess (native)
  # Second player: ShÅgi (native)

  white_chess_king = Sashite::Epin.parse("K")       # Native Chess king
  white_shogi_king = Sashite::Epin.parse("K'")      # Foreign ShÅgi king
  black_shogi_king = Sashite::Epin.parse("k")       # Native ShÅgi king
  black_chess_king = Sashite::Epin.parse("k'")      # Foreign Chess king

  raise "white chess king should be native" unless white_chess_king.native?
  raise "white shogi king should be foreign" unless white_shogi_king.derived?
  raise "black shogi king should be native" unless black_shogi_king.native?
  raise "black chess king should be foreign" unless black_chess_king.derived?

  # Promoted pieces in cross-style context
  white_promoted_rook = Sashite::Epin.parse("+R'")  # ShÅgi rook promoted
  black_promoted_pawn = Sashite::Epin.parse("+p")   # ShÅgi pawn promoted

  raise "promoted rook should be enhanced and foreign" unless white_promoted_rook.enhanced? && white_promoted_rook.derived?
  raise "promoted pawn should be enhanced and native" unless black_promoted_pawn.enhanced? && black_promoted_pawn.native?
end

run_test("Cross-style capture with style change") do
  # Simulate ÅŒgi-style capture where piece changes side and returns to native style
  enemy_piece = Sashite::Epin.parse("q'")  # Black foreign queen

  # Capture and convert
  captured = enemy_piece.flip.underive.with_type(:P)

  raise "captured should change side" unless captured.first_player?
  raise "captured should become native" unless captured.native?
  raise "captured should change type" unless captured.type == :P
  raise "captured should be P" unless captured.to_s == "P"
end

run_test("Complex transformation chain with style") do
  piece = Sashite::Epin::Identifier.new(:K, :first, :normal, true, terminal: false)

  # Chain: flip -> derive -> enhance -> with_type -> mark_terminal
  transformed = piece.flip.derive.enhance.with_type(:Q).mark_terminal

  raise "transformed should be second player" unless transformed.second_player?
  raise "transformed should be foreign" unless transformed.derived?
  raise "transformed should be enhanced" unless transformed.enhanced?
  raise "transformed should be Q type" unless transformed.type == :Q
  raise "transformed should be terminal" unless transformed.terminal?
  raise "transformed should be +q^'" unless transformed.to_s == "+q^'"

  # Original should be unchanged
  raise "original should be unchanged" unless piece.to_s == "K"
end

# ==============================================================================
# ERROR HANDLING TESTS
# ==============================================================================

run_test("EPIN error handling for invalid derivation") do
  invalid_derivations = [:invalid, "native", 1, nil, []]

  invalid_derivations.each do |derivation|
    begin
      Sashite::Epin::Identifier.new(:K, :first, :normal, derivation)
      raise "Should have raised error for invalid derivation #{derivation.inspect}"
    rescue ArgumentError => e
      raise "Error should mention derivation" unless e.message.include?("Derivation")
    end
  end
end

run_test("EPIN error handling for invalid strings") do
  invalid_epins = ["", "K'^", "''", "K''", "++'K", "^K'"]

  invalid_epins.each do |epin|
    begin
      Sashite::Epin.parse(epin)
      raise "Should have raised error for #{epin.inspect}"
    rescue ArgumentError => e
      raise "Error should mention invalid EPIN" unless e.message.include?("Invalid EPIN")
    end
  end
end

# ==============================================================================
# ROUNDTRIP CONSISTENCY
# ==============================================================================

run_test("EPIN roundtrip parsing consistency") do
  test_cases = [
    [:K, :first, :normal, true, false],
    [:K, :first, :normal, false, false],
    [:Q, :second, :enhanced, true, false],
    [:P, :first, :diminished, false, false],
    [:K, :first, :normal, true, true],
    [:K, :first, :normal, false, true],
    [:R, :second, :enhanced, false, true]
  ]

  test_cases.each do |type, side, state, native, terminal|
    original = Sashite::Epin::Identifier.new(type, side, state, native, terminal: terminal)
    epin_string = original.to_s
    parsed = Sashite::Epin.parse(epin_string)

    raise "Roundtrip failed for #{epin_string}" unless original == parsed
    raise "Roundtrip to_s differs" unless original.to_s == parsed.to_s
  end
end

# ==============================================================================
# IMMUTABILITY TESTS
# ==============================================================================

run_test("EPIN immutability") do
  piece = Sashite::Epin::Identifier.new(:K, :first, :normal, true, terminal: false)

  raise "piece should be frozen" unless piece.frozen?

  original_string = piece.to_s
  derived = piece.derive
  enhanced = piece.enhance
  flipped = piece.flip

  raise "original should be unchanged after derive" unless piece.to_s == original_string
  raise "derive should create new instance" if derived.equal?(piece)
  raise "enhance should create new instance" if enhanced.equal?(piece)
  raise "flip should create new instance" if flipped.equal?(piece)
end

# ==============================================================================
# CONSTANTS
# ==============================================================================

run_test("EPIN constants are correctly defined") do
  identifier_class = Sashite::Epin::Identifier

  raise "NATIVE should be true" unless identifier_class::NATIVE == true
  raise "FOREIGN should be false" unless identifier_class::FOREIGN == false
  raise "DERIVATION_MARKER should be '" unless identifier_class::DERIVATION_MARKER == "'"
  raise "NATIVE_MARKER should be ''" unless identifier_class::NATIVE_MARKER == ""
end

run_test("EPIN pattern matches specification") do
  spec_regex = /\A[-+]?[A-Za-z]\^?'?\z/

  test_strings = [
    "K", "k", "+K", "-k", "K'", "k'", "+K'", "-k'",
    "K^", "k^", "K^'", "+K^'",
    "", "KK", "K'^", "''K", "K''"
  ]

  test_strings.each do |string|
    spec_match = string.match?(spec_regex)
    epin_valid = Sashite::Epin.valid?(string)

    # For valid patterns, also check PIN part validity
    if spec_match
      pin_part = string.end_with?("'") ? string[0...-1] : string
      pin_valid = Sashite::Pin.valid?(pin_part)
      expected_valid = pin_valid
    else
      expected_valid = false
    end

    raise "#{string.inspect}: expected #{expected_valid}, got #{epin_valid}" unless epin_valid == expected_valid
  end
end

puts
puts "All EPIN tests passed!"
puts
