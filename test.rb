# frozen_string_literal: true

# Tests for Sashite::Epin (Extended Piece Identifier Notation)
#
# Tests the EPIN implementation for Ruby, focusing on the modern object-oriented API
# with the Identifier class using symbol-based attributes and style derivation support.

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

# Test basic validation (module level)
run_test("Module EPIN validation accepts valid notations") do
  valid_epins = [
    # Native pieces (PIN compatible)
    "K", "k", "Q", "q", "R", "r", "B", "b", "N", "n", "P", "p",
    "A", "a", "Z", "z",
    "+K", "+k", "+Q", "+q", "+R", "+r", "+B", "+b", "+N", "+n", "+P", "+p",
    "-K", "-k", "-Q", "-q", "-R", "-r", "-B", "-b", "-N", "-n", "-P", "-p",
    # Foreign pieces (with derivation suffix)
    "K'", "k'", "Q'", "q'", "R'", "r'", "B'", "b'", "N'", "n'", "P'", "p'",
    "A'", "a'", "Z'", "z'",
    "+K'", "+k'", "+Q'", "+q'", "+R'", "+r'", "+B'", "+b'", "+N'", "+n'", "+P'", "+p'",
    "-K'", "-k'", "-Q'", "-q'", "-R'", "-r'", "-B'", "-b'", "-N'", "-n'", "-P'", "-p'"
  ]

  valid_epins.each do |epin|
    raise "#{epin.inspect} should be valid" unless Sashite::Epin.valid?(epin)
  end
end

run_test("Module EPIN validation rejects invalid notations") do
  invalid_epins = [
    # Basic invalid patterns
    "", "KK", "++K", "--K", "+-K", "-+K", "K+", "K-", "+", "-",
    "1", "9", "0", "!", "@", "#", "$", "%", "^", "&", "*", "(", ")",
    " K", "K ", " +K", "+K ", "k+", "k-", "Kk", "kK",
    "123", "ABC", "abc", "K1", "1K", "+1", "-1", "1+", "1-",
    # EPIN-specific invalid patterns
    "'", "K''", "K'+", "+カ'", "+'K", "''K", "K'K", "'K'",
    " K'", "K' ", " +K'", "+K' ", "++K'", "--K'", "K'+"
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

# Test module parse method delegates to Identifier
run_test("Module parse delegates to Identifier class") do
  epin_string = "+R'"
  identifier = Sashite::Epin.parse(epin_string)

  raise "parse should return Identifier instance" unless identifier.is_a?(Sashite::Epin::Identifier)
  raise "identifier should have correct EPIN string" unless identifier.to_s == epin_string
end

# Test module identifier factory method
run_test("Module identifier factory method creates correct instances") do
  identifier = Sashite::Epin.identifier(:K, :first, :enhanced, false)

  raise "identifier factory should return Identifier instance" unless identifier.is_a?(Sashite::Epin::Identifier)
  raise "identifier should have correct type" unless identifier.type == :K
  raise "identifier should have correct side" unless identifier.side == :first
  raise "identifier should have correct state" unless identifier.state == :enhanced
  raise "identifier should have correct native" unless identifier.native == false
  raise "identifier should have correct EPIN string" unless identifier.to_s == "+K'"
end

# Test the Identifier class with EPIN-specific features
run_test("Identifier.parse creates correct instances with all attributes") do
  test_cases = {
    "K" => { type: :K, side: :first, state: :normal, native: true, letter: "K", suffix: "" },
    "k" => { type: :K, side: :second, state: :normal, native: true, letter: "k", suffix: "" },
    "+R" => { type: :R, side: :first, state: :enhanced, native: true, letter: "R", suffix: "" },
    "-p" => { type: :P, side: :second, state: :diminished, native: true, letter: "p", suffix: "" },
    "K'" => { type: :K, side: :first, state: :normal, native: false, letter: "K", suffix: "'" },
    "k'" => { type: :K, side: :second, state: :normal, native: false, letter: "k", suffix: "'" },
    "+R'" => { type: :R, side: :first, state: :enhanced, native: false, letter: "R", suffix: "'" },
    "-p'" => { type: :P, side: :second, state: :diminished, native: false, letter: "p", suffix: "'" }
  }

  test_cases.each do |epin_string, expected|
    identifier = Sashite::Epin.parse(epin_string)

    raise "#{epin_string}: wrong type" unless identifier.type == expected[:type]
    raise "#{epin_string}: wrong side" unless identifier.side == expected[:side]
    raise "#{epin_string}: wrong state" unless identifier.state == expected[:state]
    raise "#{epin_string}: wrong native" unless identifier.native == expected[:native]
    raise "#{epin_string}: wrong letter" unless identifier.letter == expected[:letter]
    raise "#{epin_string}: wrong suffix" unless identifier.suffix == expected[:suffix]
  end
end

run_test("Identifier constructor with all parameters") do
  test_cases = [
    [:K, :first, :normal, true, "K"],
    [:K, :second, :normal, true, "k"],
    [:R, :first, :enhanced, true, "+R"],
    [:P, :second, :diminished, true, "-p"],
    [:K, :first, :normal, false, "K'"],
    [:K, :second, :normal, false, "k'"],
    [:R, :first, :enhanced, false, "+R'"],
    [:P, :second, :diminished, false, "-p'"]
  ]

  test_cases.each do |type, side, state, native, expected_epin|
    identifier = Sashite::Epin::Identifier.new(type, side, state, native)

    raise "type should be #{type}" unless identifier.type == type
    raise "side should be #{side}" unless identifier.side == side
    raise "state should be #{state}" unless identifier.state == state
    raise "native should be #{native}" unless identifier.native == native
    raise "EPIN string should be #{expected_epin}" unless identifier.to_s == expected_epin
  end
end

run_test("Identifier to_s returns correct EPIN string") do
  test_cases = [
    [:K, :first, :normal, true, "K"],
    [:K, :second, :normal, true, "k"],
    [:R, :first, :enhanced, true, "+R"],
    [:P, :second, :diminished, true, "-p"],
    [:K, :first, :normal, false, "K'"],
    [:K, :second, :normal, false, "k'"],
    [:R, :first, :enhanced, false, "+R'"],
    [:P, :second, :diminished, false, "-p'"]
  ]

  test_cases.each do |type, side, state, native, expected|
    identifier = Sashite::Epin::Identifier.new(type, side, state, native)
    result = identifier.to_s

    raise "#{type}, #{side}, #{state}, #{native} should be #{expected}, got #{result}" unless result == expected
  end
end

run_test("Identifier letter, prefix, and suffix methods") do
  test_cases = [
    ["K", "K", "", ""],
    ["k", "k", "", ""],
    ["+R", "R", "+", ""],
    ["-p", "p", "-", ""],
    ["K'", "K", "", "'"],
    ["k'", "k", "", "'"],
    ["+R'", "R", "+", "'"],
    ["-p'", "p", "-", "'"]
  ]

  test_cases.each do |epin_string, expected_letter, expected_prefix, expected_suffix|
    identifier = Sashite::Epin.parse(epin_string)

    raise "#{epin_string}: wrong letter" unless identifier.letter == expected_letter
    raise "#{epin_string}: wrong prefix" unless identifier.prefix == expected_prefix
    raise "#{epin_string}: wrong suffix" unless identifier.suffix == expected_suffix
    raise "#{epin_string}: to_s should equal prefix + letter + suffix" unless identifier.to_s == "#{identifier.prefix}#{identifier.letter}#{identifier.suffix}"
  end
end

run_test("Identifier state mutations return new instances") do
  identifier = Sashite::Epin::Identifier.new(:K, :first, :normal, true)

  # Test enhance
  enhanced = identifier.enhance
  raise "enhance should return new instance" if enhanced.equal?(identifier)
  raise "enhanced identifier should be enhanced" unless enhanced.enhanced?
  raise "enhanced identifier state should be :enhanced" unless enhanced.state == :enhanced
  raise "enhanced identifier should preserve derivation" unless enhanced.native == identifier.native
  raise "original identifier should be unchanged" unless identifier.state == :normal

  # Test diminish
  diminished = identifier.diminish
  raise "diminish should return new instance" if diminished.equal?(identifier)
  raise "diminished identifier should be diminished" unless diminished.diminished?
  raise "diminished identifier state should be :diminished" unless diminished.state == :diminished
  raise "diminished identifier should preserve derivation" unless diminished.native == identifier.native
  raise "original identifier should be unchanged" unless identifier.state == :normal

  # Test flip
  flipped = identifier.flip
  raise "flip should return new instance" if flipped.equal?(identifier)
  raise "flipped identifier should have opposite side" unless flipped.side == :second
  raise "flipped identifier should preserve type, state, and derivation" unless flipped.type == identifier.type && flipped.state == identifier.state && flipped.native == identifier.native
  raise "original identifier should be unchanged" unless identifier.side == :first
end

run_test("Identifier style mutations return new instances") do
  identifier = Sashite::Epin::Identifier.new(:K, :first, :normal, true)

  # Test derive
  derived = identifier.derive
  raise "derive should return new instance" if derived.equal?(identifier)
  raise "derived identifier should be derived" unless derived.derived?
  raise "derived identifier native should be false" unless derived.native == false
  raise "derived identifier should preserve type, side, and state" unless derived.type == identifier.type && derived.side == identifier.side && derived.state == identifier.state
  raise "original identifier should be unchanged" unless identifier.native == true

  # Test underive
  foreign_identifier = Sashite::Epin::Identifier.new(:Q, :second, :enhanced, false)
  underived = foreign_identifier.underive
  raise "underive should return new instance" if underived.equal?(foreign_identifier)
  raise "underived identifier should be native" unless underived.native?
  raise "underived identifier native should be true" unless underived.native == true
  raise "underived identifier should preserve type, side, and state" unless underived.type == foreign_identifier.type && underived.side == foreign_identifier.side && underived.state == foreign_identifier.state
  raise "original identifier should be unchanged" unless foreign_identifier.native == false
end

run_test("Identifier attribute transformations") do
  identifier = Sashite::Epin::Identifier.new(:K, :first, :normal, true)

  # Test with_type
  queen = identifier.with_type(:Q)
  raise "with_type should return new instance" if queen.equal?(identifier)
  raise "new identifier should have different type" unless queen.type == :Q
  raise "new identifier should have same side, state, and derivation" unless queen.side == identifier.side && queen.state == identifier.state && queen.native == identifier.native

  # Test with_side
  black_king = identifier.with_side(:second)
  raise "with_side should return new instance" if black_king.equal?(identifier)
  raise "new identifier should have different side" unless black_king.side == :second
  raise "new identifier should have same type, state, and derivation" unless black_king.type == identifier.type && black_king.state == identifier.state && black_king.native == identifier.native

  # Test with_state
  enhanced_king = identifier.with_state(:enhanced)
  raise "with_state should return new instance" if enhanced_king.equal?(identifier)
  raise "new identifier should have different state" unless enhanced_king.state == :enhanced
  raise "new identifier should have same type, side, and derivation" unless enhanced_king.type == identifier.type && enhanced_king.side == identifier.side && enhanced_king.native == identifier.native

  # Test with_derivation
  foreign_king = identifier.with_derivation(false)
  raise "with_derivation should return new instance" if foreign_king.equal?(identifier)
  raise "new identifier should have different derivation" unless foreign_king.native == false
  raise "new identifier should have same type, side, and state" unless foreign_king.type == identifier.type && foreign_king.side == identifier.side && foreign_king.state == identifier.state
end

run_test("Identifier immutability") do
  identifier = Sashite::Epin::Identifier.new(:R, :first, :enhanced, false)

  # Test that identifier is frozen
  raise "identifier should be frozen" unless identifier.frozen?

  # Test that mutations don't affect original
  original_string = identifier.to_s
  normalized = identifier.normalize
  derived = identifier.underive

  raise "original identifier should be unchanged after normalize" unless identifier.to_s == original_string
  raise "normalized identifier should be different" unless normalized.to_s == "R'"
  raise "underived identifier should be different" unless derived.to_s == "+R"
end

run_test("Identifier equality and hash") do
  identifier1 = Sashite::Epin::Identifier.new(:K, :first, :normal, true)
  identifier2 = Sashite::Epin::Identifier.new(:K, :first, :normal, true)
  identifier3 = Sashite::Epin::Identifier.new(:K, :second, :normal, true)
  identifier4 = Sashite::Epin::Identifier.new(:K, :first, :enhanced, true)
  identifier5 = Sashite::Epin::Identifier.new(:K, :first, :normal, false)

  # Test equality
  raise "identical identifiers should be equal" unless identifier1 == identifier2
  raise "different side should not be equal" if identifier1 == identifier3
  raise "different state should not be equal" if identifier1 == identifier4
  raise "different derivation should not be equal" if identifier1 == identifier5

  # Test hash consistency
  raise "equal identifiers should have same hash" unless identifier1.hash == identifier2.hash

  # Test in hash/set
  identifiers_set = Set.new([identifier1, identifier2, identifier3, identifier4, identifier5])
  raise "set should contain 4 unique identifiers" unless identifiers_set.size == 4
end

run_test("Identifier type and side identification") do
  test_cases = [
    ["K", :K, :first, true, false],
    ["k", :K, :second, false, true],
    ["+R'", :R, :first, true, false],
    ["-p'", :P, :second, false, true]
  ]

  test_cases.each do |epin_string, expected_type, expected_side, is_first, is_second|
    identifier = Sashite::Epin.parse(epin_string)

    raise "#{epin_string}: wrong type" unless identifier.type == expected_type
    raise "#{epin_string}: wrong side" unless identifier.side == expected_side
    raise "#{epin_string}: wrong first_player?" unless identifier.first_player? == is_first
    raise "#{epin_string}: wrong second_player?" unless identifier.second_player? == is_second
  end
end

run_test("Identifier same_type?, same_side?, same_state?, and same_style? methods") do
  king1 = Sashite::Epin::Identifier.new(:K, :first, :normal, true)
  king2 = Sashite::Epin::Identifier.new(:K, :second, :enhanced, false)
  queen = Sashite::Epin::Identifier.new(:Q, :first, :normal, true)
  foreign_queen = Sashite::Epin::Identifier.new(:Q, :second, :enhanced, false)

  # same_type? tests
  raise "K and K should be same type" unless king1.same_type?(king2)
  raise "K and Q should not be same type" if king1.same_type?(queen)

  # same_side? tests
  raise "first player identifiers should be same side" unless king1.same_side?(queen)
  raise "different side identifiers should not be same side" if king1.same_side?(king2)

  # same_state? tests
  raise "normal identifiers should be same state" unless king1.same_state?(queen)
  raise "enhanced identifiers should be same state" unless king2.same_state?(foreign_queen)
  raise "different state identifiers should not be same state" if king1.same_state?(king2)

  # same_style? tests
  raise "native identifiers should be same style" unless king1.same_style?(queen)
  raise "foreign identifiers should be same style" unless king2.same_style?(foreign_queen)
  raise "different style identifiers should not be same style" if king1.same_style?(king2)
end

run_test("Identifier state and style methods") do
  normal_native = Sashite::Epin::Identifier.new(:K, :first, :normal, true)
  enhanced_foreign = Sashite::Epin::Identifier.new(:K, :first, :enhanced, false)
  diminished_native = Sashite::Epin::Identifier.new(:K, :first, :diminished, true)

  # Test state identification
  raise "normal identifier should be normal" unless normal_native.normal?
  raise "normal identifier should not be enhanced" if normal_native.enhanced?
  raise "normal identifier should not be diminished" if normal_native.diminished?
  raise "normal identifier state should be :normal" unless normal_native.state == :normal

  raise "enhanced identifier should be enhanced" unless enhanced_foreign.enhanced?
  raise "enhanced identifier should not be normal" if enhanced_foreign.normal?
  raise "enhanced identifier state should be :enhanced" unless enhanced_foreign.state == :enhanced

  raise "diminished identifier should be diminished" unless diminished_native.diminished?
  raise "diminished identifier should not be normal" if diminished_native.normal?
  raise "diminished identifier state should be :diminished" unless diminished_native.state == :diminished

  # Test style identification
  raise "native identifier should be native" unless normal_native.native?
  raise "native identifier should not be derived" if normal_native.derived?
  raise "native identifier should not be foreign" if normal_native.foreign?

  raise "foreign identifier should be derived" unless enhanced_foreign.derived?
  raise "foreign identifier should be foreign" unless enhanced_foreign.foreign?
  raise "foreign identifier should not be native" if enhanced_foreign.native?
end

run_test("Identifier transformation methods return self when appropriate") do
  normal_native = Sashite::Epin::Identifier.new(:K, :first, :normal, true)
  enhanced_foreign = Sashite::Epin::Identifier.new(:K, :first, :enhanced, false)
  diminished_native = Sashite::Epin::Identifier.new(:K, :first, :diminished, true)

  # Test state methods that should return self
  raise "unenhance on normal identifier should return self" unless normal_native.unenhance.equal?(normal_native)
  raise "undiminish on normal identifier should return self" unless normal_native.undiminish.equal?(normal_native)
  raise "normalize on normal identifier should return self" unless normal_native.normalize.equal?(normal_native)
  raise "enhance on enhanced identifier should return self" unless enhanced_foreign.enhance.equal?(enhanced_foreign)
  raise "diminish on diminished identifier should return self" unless diminished_native.diminish.equal?(diminished_native)

  # Test style methods that should return self
  raise "underive on native identifier should return self" unless normal_native.underive.equal?(normal_native)
  raise "derive on foreign identifier should return self" unless enhanced_foreign.derive.equal?(enhanced_foreign)

  # Test with_* methods that should return self
  raise "with_type with same type should return self" unless normal_native.with_type(:K).equal?(normal_native)
  raise "with_side with same side should return self" unless normal_native.with_side(:first).equal?(normal_native)
  raise "with_state with same state should return self" unless normal_native.with_state(:normal).equal?(normal_native)
  raise "with_derivation with same derivation should return self" unless normal_native.with_derivation(true).equal?(normal_native)
end

run_test("Identifier transformation chains") do
  identifier = Sashite::Epin::Identifier.new(:K, :first, :normal, true)

  # Test enhance then unenhance
  enhanced = identifier.enhance
  back_to_normal = enhanced.unenhance
  raise "enhance then unenhance should equal original" unless back_to_normal == identifier

  # Test diminish then undiminish
  diminished = identifier.diminish
  back_to_normal2 = diminished.undiminish
  raise "diminish then undiminish should equal original" unless back_to_normal2 == identifier

  # Test derive then underive
  derived = identifier.derive
  back_to_native = derived.underive
  raise "derive then underive should equal original" unless back_to_native == identifier

  # Test complex chain
  transformed = identifier.flip.derive.enhance.with_type(:Q).diminish
  raise "complex chain should work" unless transformed.to_s == "-q'"
  raise "original should be unchanged" unless identifier.to_s == "K"
end

run_test("Identifier error handling for invalid parameters") do
  # Invalid types
  invalid_types = [:invalid, :k, :"1", :AA, "K", 1, nil]

  invalid_types.each do |type|
    begin
      Sashite::Epin::Identifier.new(type, :first, :normal, true)
      raise "Should have raised error for invalid type #{type.inspect}"
    rescue ArgumentError => e
      raise "Error message should mention invalid type" unless e.message.include?("Type must be")
    end
  end

  # Invalid sides
  invalid_sides = [:invalid, :player1, :white, "first", 1, nil]

  invalid_sides.each do |side|
    begin
      Sashite::Epin::Identifier.new(:K, side, :normal, true)
      raise "Should have raised error for invalid side #{side.inspect}"
    rescue ArgumentError => e
      raise "Error message should mention invalid side" unless e.message.include?("Side must be")
    end
  end

  # Invalid states
  invalid_states = [:invalid, :promoted, :active, "normal", 1, nil]

  invalid_states.each do |state|
    begin
      Sashite::Epin::Identifier.new(:K, :first, state, true)
      raise "Should have raised error for invalid state #{state.inspect}"
    rescue ArgumentError => e
      raise "Error message should mention invalid state" unless e.message.include?("State must be")
    end
  end

  # Invalid derivations
  invalid_derivations = [:invalid, "true", "false", 1, 0, nil, "native"]

  invalid_derivations.each do |derivation|
    begin
      Sashite::Epin::Identifier.new(:K, :first, :normal, derivation)
      raise "Should have raised error for invalid derivation #{derivation.inspect}"
    rescue ArgumentError => e
      raise "Error message should mention invalid derivation" unless e.message.include?("Derivation must be")
    end
  end
end

run_test("Identifier error handling for invalid EPIN strings") do
  # Invalid EPIN strings
  invalid_epins = ["", "KK", "++K", "123", nil, :symbol, "'", "K''", "++K'"]

  invalid_epins.each do |epin|
    begin
      Sashite::Epin.parse(epin)
      raise "Should have raised error for #{epin.inspect}"
    rescue ArgumentError => e
      raise "Error message should mention invalid EPIN" unless e.message.include?("Invalid EPIN")
    end
  end
end

# Test PIN compatibility
run_test("PIN compatibility - all PIN strings are valid EPIN") do
  pin_strings = [
    "K", "k", "Q", "q", "R", "r", "B", "b", "N", "n", "P", "p",
    "A", "a", "Z", "z",
    "+K", "+k", "+Q", "+q", "+R", "+r", "+B", "+b", "+N", "+n", "+P", "+p",
    "-K", "-k", "-Q", "-q", "-R", "-r", "-B", "-b", "-N", "-n", "-P", "-p"
  ]

  pin_strings.each do |pin|
    # Should be valid as EPIN
    raise "PIN string #{pin.inspect} should be valid EPIN" unless Sashite::Epin.valid?(pin)

    # Should parse correctly as native identifier
    identifier = Sashite::Epin.parse(pin)
    raise "PIN string should parse as native identifier" unless identifier.native?

    # Should round-trip correctly
    raise "PIN string should round-trip" unless identifier.to_s == pin
  end
end

# Test cross-style game examples
run_test("Cross-style Chess vs. Shōgi identifiers") do
  # Native identifiers (no derivation suffix)
  white_king = Sashite::Epin.identifier(:K, :first, :normal, true)          # Chess king
  black_king = Sashite::Epin.identifier(:K, :second, :normal, true)         # Shōgi king

  # Foreign identifiers (with derivation suffix)
  white_shogi_king = Sashite::Epin.identifier(:K, :first, :normal, false)   # Shōgi king for white
  black_chess_king = Sashite::Epin.identifier(:K, :second, :normal, false)  # Chess king for black

  raise "White native king should be 'K'" unless white_king.to_s == "K"
  raise "Black native king should be 'k'" unless black_king.to_s == "k"
  raise "White foreign king should be 'K''" unless white_shogi_king.to_s == "K'"
  raise "Black foreign king should be 'k''" unless black_chess_king.to_s == "k'"

  # Promoted identifiers in cross-style context
  white_promoted_rook = Sashite::Epin.parse("+R'")  # White shōgi rook promoted to Dragon King
  black_promoted_pawn = Sashite::Epin.parse("+p")   # Black shōgi pawn promoted to Tokin

  raise "White promoted rook should be enhanced" unless white_promoted_rook.enhanced?
  raise "White promoted rook should be foreign" unless white_promoted_rook.derived?
  raise "Black promoted pawn should be enhanced" unless black_promoted_pawn.enhanced?
  raise "Black promoted pawn should be native" unless black_promoted_pawn.native?
end

run_test("Style mutation during gameplay simulation") do
  # Simulate capture with style change (Ōgi rules)
  chess_queen = Sashite::Epin.parse("q'")           # Black chess queen (foreign for shōgi player)
  captured = chess_queen.flip.with_type(:P).underive  # Becomes white native pawn

  raise "Original should be black foreign queen" unless chess_queen.to_s == "q'"
  raise "Captured should be white native pawn" unless captured.to_s == "P"

  # Style derivation changes during gameplay
  shogi_identifier = Sashite::Epin.parse("r")           # Black shōgi rook (native)
  foreign_identifier = shogi_identifier.derive              # Convert to foreign style

  raise "Original should be native" unless shogi_identifier.native?
  raise "Converted should be foreign" unless foreign_identifier.derived?
  raise "Foreign identifier should be 'r''" unless foreign_identifier.to_s == "r'"
end

# Test practical usage scenarios
run_test("Practical usage - identifier collections with derivation") do
  identifiers = [
    Sashite::Epin.identifier(:K, :first, :normal, true),    # Native white king
    Sashite::Epin.identifier(:Q, :first, :normal, false),   # Foreign white queen
    Sashite::Epin.identifier(:R, :first, :enhanced, true),  # Native white promoted rook
    Sashite::Epin.identifier(:K, :second, :normal, false),  # Foreign black king
    Sashite::Epin.identifier(:P, :second, :normal, true)    # Native black pawn
  ]

  # Filter by side
  first_player_identifiers = identifiers.select(&:first_player?)
  raise "Should have 3 first player identifiers" unless first_player_identifiers.size == 3

  # Group by style derivation
  native_identifiers = identifiers.select(&:native?)
  foreign_identifiers = identifiers.select(&:derived?)
  raise "Should have 3 native identifiers" unless native_identifiers.size == 3
  raise "Should have 2 foreign identifiers" unless foreign_identifiers.size == 2

  # Find promoted identifiers
  promoted = identifiers.select(&:enhanced?)
  raise "Should have 1 promoted identifier" unless promoted.size == 1
  raise "Promoted identifier should be rook" unless promoted.first.type == :R
end

run_test("Practical usage - game state simulation with style") do
  # Simulate promoting a pawn with style considerations
  native_pawn = Sashite::Epin.identifier(:P, :first, :normal, true)
  foreign_pawn = Sashite::Epin.identifier(:P, :first, :normal, false)

  raise "Native pawn should be normal initially" unless native_pawn.normal?
  raise "Foreign pawn should be normal initially" unless foreign_pawn.normal?

  # Promote to queen using with_type and enhance, preserving style
  native_promoted = native_pawn.with_type(:Q).enhance
  foreign_promoted = foreign_pawn.with_type(:Q).enhance

  raise "Native promoted identifier should be queen" unless native_promoted.type == :Q
  raise "Native promoted identifier should be enhanced" unless native_promoted.enhanced?
  raise "Native promoted identifier should remain native" unless native_promoted.native?
  raise "Native promoted should be '+Q'" unless native_promoted.to_s == "+Q"

  raise "Foreign promoted identifier should be queen" unless foreign_promoted.type == :Q
  raise "Foreign promoted identifier should be enhanced" unless foreign_promoted.enhanced?
  raise "Foreign promoted identifier should remain foreign" unless foreign_promoted.derived?
  raise "Foreign promoted should be '+Q''" unless foreign_promoted.to_s == "+Q'"

  # Simulate capturing and flipping with style preservation
  captured_native = native_promoted.flip  # Becomes enemy identifier, keeps native style
  captured_foreign = foreign_promoted.flip  # Becomes enemy identifier, keeps foreign style

  raise "Captured native should be second player" unless captured_native.second_player?
  raise "Captured native should still be enhanced" unless captured_native.enhanced?
  raise "Captured native should still be queen" unless captured_native.type == :Q
  raise "Captured native should remain native" unless captured_native.native?
  raise "Captured native should be '+q'" unless captured_native.to_s == "+q"

  raise "Captured foreign should be second player" unless captured_foreign.second_player?
  raise "Captured foreign should still be enhanced" unless captured_foreign.enhanced?
  raise "Captured foreign should still be queen" unless captured_foreign.type == :Q
  raise "Captured foreign should remain foreign" unless captured_foreign.derived?
  raise "Captured foreign should be '+q''" unless captured_foreign.to_s == "+q'"
end

# Test edge cases
run_test("Edge case - all letters of alphabet with derivation") do
  letters = ("A".."Z").to_a

  letters.each do |letter|
    type_symbol = letter.to_sym

    # Test first player native
    identifier1 = Sashite::Epin.identifier(type_symbol, :first, :normal, true)
    raise "#{letter} should create valid native identifier" unless identifier1.type == type_symbol
    raise "#{letter} should be first player" unless identifier1.first_player?
    raise "#{letter} should be native" unless identifier1.native?
    raise "#{letter} should have correct letter" unless identifier1.letter == letter
    raise "#{letter} should have correct EPIN" unless identifier1.to_s == letter

    # Test first player foreign
    identifier2 = Sashite::Epin.identifier(type_symbol, :first, :normal, false)
    raise "#{letter} should create valid foreign identifier" unless identifier2.type == type_symbol
    raise "#{letter} should be first player" unless identifier2.first_player?
    raise "#{letter} should be foreign" unless identifier2.derived?
    raise "#{letter} should have correct letter" unless identifier2.letter == letter
    raise "#{letter} should have correct EPIN" unless identifier2.to_s == "#{letter}'"

    # Test second player native
    identifier3 = Sashite::Epin.identifier(type_symbol, :second, :normal, true)
    raise "#{letter} should create valid native identifier" unless identifier3.type == type_symbol
    raise "#{letter} should be second player" unless identifier3.second_player?
    raise "#{letter} should be native" unless identifier3.native?
    raise "#{letter} should have correct letter" unless identifier3.letter == letter.downcase
    raise "#{letter} should have correct EPIN" unless identifier3.to_s == letter.downcase

    # Test second player foreign
    identifier4 = Sashite::Epin.identifier(type_symbol, :second, :normal, false)
    raise "#{letter} should create valid foreign identifier" unless identifier4.type == type_symbol
    raise "#{letter} should be second player" unless identifier4.second_player?
    raise "#{letter} should be foreign" unless identifier4.derived?
    raise "#{letter} should have correct letter" unless identifier4.letter == letter.downcase
    raise "#{letter} should have correct EPIN" unless identifier4.to_s == "#{letter.downcase}'"

    # Test enhanced native state
    enhanced = identifier1.enhance
    raise "#{letter} enhanced should work" unless enhanced.enhanced?
    raise "#{letter} enhanced should have + prefix" unless enhanced.prefix == "+"
    raise "#{letter} enhanced should preserve style" unless enhanced.native?
    raise "#{letter} enhanced should have correct EPIN" unless enhanced.to_s == "+#{letter}"

    # Test enhanced foreign state
    enhanced_foreign = identifier2.enhance
    raise "#{letter} enhanced foreign should work" unless enhanced_foreign.enhanced?
    raise "#{letter} enhanced foreign should have + prefix" unless enhanced_foreign.prefix == "+"
    raise "#{letter} enhanced foreign should preserve style" unless enhanced_foreign.derived?
    raise "#{letter} enhanced foreign should have correct EPIN" unless enhanced_foreign.to_s == "+#{letter}'"

    # Test diminished state
    diminished = identifier1.diminish
    raise "#{letter} diminished should work" unless diminished.diminished?
    raise "#{letter} diminished should have - prefix" unless diminished.prefix == "-"
    raise "#{letter} diminished should preserve style" unless diminished.native?
    raise "#{letter} diminished should have correct EPIN" unless diminished.to_s == "-#{letter}"
  end
end

run_test("Edge case - unicode and special characters still invalid") do
  unicode_chars = ["α", "β", "♕", "♔", "🀄", "象", "將"]

  unicode_chars.each do |char|
    raise "#{char.inspect} should be invalid (not ASCII)" if Sashite::Epin.valid?(char)
    raise "#{char.inspect} with + should be invalid" if Sashite::Epin.valid?("+#{char}")
    raise "#{char.inspect} with - should be invalid" if Sashite::Epin.valid?("-#{char}")
    raise "#{char.inspect} with ' should be invalid" if Sashite::Epin.valid?("#{char}'")
    raise "#{char.inspect} with +' should be invalid" if Sashite::Epin.valid?("+#{char}'")
  end
end

run_test("Edge case - whitespace handling still works") do
  whitespace_cases = [
    " K", "K ", " +K", "+K ", " -K", "-K ",
    " K'", "K' ", " +K'", "+K' ", " -K'", "-K' ",
    "\tK", "K\t", "\n+K", "+K\n", " K ", "\t+K'\t"
  ]

  whitespace_cases.each do |epin|
    raise "#{epin.inspect} should be invalid (whitespace)" if Sashite::Epin.valid?(epin)
  end
end

run_test("Edge case - multiple suffixes and invalid combinations") do
  invalid_combinations = [
    "K''", "K'''", "+K''", "-K''", "++K'", "--K'", "+-K'", "-+K'",
    "'K", "K'+", "K'-", "'", "''", "'''", "K'K", "'K'"
  ]

  invalid_combinations.each do |epin|
    raise "#{epin.inspect} should be invalid (invalid combination)" if Sashite::Epin.valid?(epin)
  end
end

# Test validation behavior with edge cases specific to EPIN
run_test("EPIN validation edge cases") do
  # Empty derivation suffix cases
  edge_cases = [
    ["'", false],        # Just apostrophe
    ["", false],         # Empty string
    ["K''", false],      # Double apostrophe
    ["'K", false],       # Apostrophe before letter
    ["K'K", false],      # Letter after apostrophe
    ["K'+'", false],     # Invalid characters after apostrophe
    ["+", false],        # Just plus
    ["-", false],        # Just minus
    ["+'", false],       # Plus with apostrophe but no letter
    ["-'", false]        # Minus with apostrophe but no letter
  ]

  edge_cases.each do |epin_string, should_be_valid|
    result = Sashite::Epin.valid?(epin_string)
    if should_be_valid
      raise "#{epin_string.inspect} should be valid" unless result
    else
      raise "#{epin_string.inspect} should be invalid" if result
    end
  end
end

# Test performance with EPIN extensions
run_test("Performance - repeated operations with EPIN features") do
  # Test performance with many repeated calls including derivation
  1000.times do
    identifier = Sashite::Epin.identifier(:K, :first, :normal, true)
    enhanced = identifier.enhance
    derived = identifier.derive
    flipped = identifier.flip
    queen = identifier.with_type(:Q)
    foreign_enhanced = identifier.derive.enhance

    raise "Performance test failed" unless Sashite::Epin.valid?("K")
    raise "Performance test failed" unless Sashite::Epin.valid?("K'")
    raise "Performance test failed" unless enhanced.enhanced?
    raise "Performance test failed" unless derived.derived?
    raise "Performance test failed" unless flipped.second_player?
    raise "Performance test failed" unless queen.type == :Q
    raise "Performance test failed" unless foreign_enhanced.to_s == "+K'"
  end
end

# Test constants validation
run_test("EPIN class constants are properly defined") do
  identifier_class = Sashite::Epin::Identifier

  # Test derivation constants
  raise "NATIVE should be true" unless identifier_class::NATIVE == true
  raise "FOREIGN should be false" unless identifier_class::FOREIGN == false

  # Test suffix constants
  raise "DERIVATION_SUFFIX should be \"'\"" unless identifier_class::DERIVATION_SUFFIX == "'"
end

# Test roundtrip parsing consistency with derivation
run_test("Roundtrip parsing consistency including derivation") do
  test_cases = [
    [:K, :first, :normal, true],
    [:Q, :second, :enhanced, false],
    [:P, :first, :diminished, true],
    [:Z, :second, :normal, false],
    [:A, :first, :enhanced, false],
    [:B, :second, :diminished, true]
  ]

  test_cases.each do |type, side, state, native|
    # Create identifier -> to_s -> parse -> compare
    original = Sashite::Epin::Identifier.new(type, side, state, native)
    epin_string = original.to_s
    parsed = Sashite::Epin.parse(epin_string)

    raise "Roundtrip failed: original != parsed" unless original == parsed
    raise "Roundtrip failed: different type" unless original.type == parsed.type
    raise "Roundtrip failed: different side" unless original.side == parsed.side
    raise "Roundtrip failed: different state" unless original.state == parsed.state
    raise "Roundtrip failed: different derivation" unless original.native == parsed.native
  end
end

# Test delegation to PIN identifier for core functionality
run_test("PIN delegation works correctly") do
  epin_identifier = Sashite::Epin.identifier(:K, :first, :enhanced, false)

  # Test that PIN-related methods work correctly
  raise "Type should work via delegation" unless epin_identifier.type == :K
  raise "Side should work via delegation" unless epin_identifier.side == :first
  raise "State should work via delegation" unless epin_identifier.state == :enhanced
  raise "Enhanced? should work via delegation" unless epin_identifier.enhanced?
  raise "First player? should work via delegation" unless epin_identifier.first_player?
  raise "Letter should work via delegation" unless epin_identifier.letter == "K"
  raise "Prefix should work via delegation" unless epin_identifier.prefix == "+"

  # Test that EPIN-specific attributes work
  raise "Native should be EPIN-specific" unless epin_identifier.native == false
  raise "Derived? should work" unless epin_identifier.derived?
  raise "Suffix should be EPIN-specific" unless epin_identifier.suffix == "'"
end

# Test conversion between PIN and EPIN
run_test("PIN to EPIN conversion and compatibility") do
  # Test that PIN identifiers can be represented in EPIN as native identifiers
  pin_examples = ["K", "+R", "-p", "q"]

  pin_examples.each do |pin_string|
    # Parse as EPIN (should work since PIN is subset of EPIN)
    epin_identifier = Sashite::Epin.parse(pin_string)

    # Should be native style
    raise "PIN identifier should parse as native in EPIN" unless epin_identifier.native?

    # Should round-trip back to same string
    raise "PIN->EPIN should round-trip" unless epin_identifier.to_s == pin_string

    # Should match PIN validation
    raise "EPIN should validate same as PIN for PIN strings" unless Sashite::Epin.valid?(pin_string)
  end
end

# Test error handling for edge cases
run_test("Error handling for EPIN-specific edge cases") do
  # Test that apostrophe-only strings fail gracefully
  apostrophe_cases = ["'", "''", "'''", "'K", "K'K", "+'", "-'"]

  apostrophe_cases.each do |case_string|
    raise "#{case_string.inspect} should be invalid" if Sashite::Epin.valid?(case_string)

    begin
      Sashite::Epin.parse(case_string)
      raise "#{case_string.inspect} should raise ArgumentError"
    rescue ArgumentError => e
      raise "Error should mention invalid EPIN" unless e.message.include?("Invalid EPIN")
    end
  end
end

puts
puts "All EPIN tests passed!"
puts
