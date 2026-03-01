#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "../../helper"
require_relative "../../../lib/sashite/epin/parser"

puts
puts "=== Parser Tests ==="
puts

# ============================================================================
# PARSE - VALID INPUTS - NATIVE (NO DERIVATION MARKER)
# ============================================================================

puts "parse - valid inputs - native (no derivation marker):"

Test("parses simple PIN 'K'") do
  result = Sashite::Epin::Parser.parse("K")
  raise "wrong class" unless Sashite::Epin::Identifier === result
  raise "wrong abbr" unless result.pin.abbr == :K
  raise "wrong side" unless result.pin.side == :first
  raise "wrong state" unless result.pin.state == :normal
  raise "should not be terminal" if result.pin.terminal?
  raise "should be native" unless result.native?
end

Test("parses lowercase PIN 'k'") do
  result = Sashite::Epin::Parser.parse("k")
  raise "wrong abbr" unless result.pin.abbr == :K
  raise "wrong side" unless result.pin.side == :second
  raise "should be native" unless result.native?
end

Test("parses enhanced PIN '+R'") do
  result = Sashite::Epin::Parser.parse("+R")
  raise "wrong abbr" unless result.pin.abbr == :R
  raise "wrong state" unless result.pin.state == :enhanced
  raise "should be native" unless result.native?
end

Test("parses diminished PIN '-p'") do
  result = Sashite::Epin::Parser.parse("-p")
  raise "wrong abbr" unless result.pin.abbr == :P
  raise "wrong side" unless result.pin.side == :second
  raise "wrong state" unless result.pin.state == :diminished
  raise "should be native" unless result.native?
end

Test("parses terminal PIN 'K^'") do
  result = Sashite::Epin::Parser.parse("K^")
  raise "wrong abbr" unless result.pin.abbr == :K
  raise "should be terminal" unless result.pin.terminal?
  raise "should be native" unless result.native?
end

Test("parses PIN with all modifiers '+K^'") do
  result = Sashite::Epin::Parser.parse("+K^")
  raise "wrong abbr" unless result.pin.abbr == :K
  raise "wrong state" unless result.pin.state == :enhanced
  raise "should be terminal" unless result.pin.terminal?
  raise "should be native" unless result.native?
end

# ============================================================================
# PARSE - VALID INPUTS - DERIVED (WITH DERIVATION MARKER)
# ============================================================================

puts
puts "parse - valid inputs - derived (with derivation marker):"

Test("parses derived PIN \"K'\"") do
  result = Sashite::Epin::Parser.parse("K'")
  raise "wrong abbr" unless result.pin.abbr == :K
  raise "wrong side" unless result.pin.side == :first
  raise "should be derived" unless result.derived?
end

Test("parses derived lowercase PIN \"k'\"") do
  result = Sashite::Epin::Parser.parse("k'")
  raise "wrong abbr" unless result.pin.abbr == :K
  raise "wrong side" unless result.pin.side == :second
  raise "should be derived" unless result.derived?
end

Test("parses derived enhanced PIN \"+R'\"") do
  result = Sashite::Epin::Parser.parse("+R'")
  raise "wrong abbr" unless result.pin.abbr == :R
  raise "wrong state" unless result.pin.state == :enhanced
  raise "should be derived" unless result.derived?
end

Test("parses derived terminal PIN \"K^'\"") do
  result = Sashite::Epin::Parser.parse("K^'")
  raise "wrong abbr" unless result.pin.abbr == :K
  raise "should be terminal" unless result.pin.terminal?
  raise "should be derived" unless result.derived?
end

Test("parses derived PIN with all modifiers \"+K^'\"") do
  result = Sashite::Epin::Parser.parse("+K^'")
  raise "wrong abbr" unless result.pin.abbr == :K
  raise "wrong state" unless result.pin.state == :enhanced
  raise "should be terminal" unless result.pin.terminal?
  raise "should be derived" unless result.derived?
end

# ============================================================================
# PARSE - VALID INPUTS - ALL LETTERS
# ============================================================================

puts
puts "parse - valid inputs - all letters:"

Test("parses all uppercase letters A-Z") do
  ("A".."Z").each do |letter|
    result = Sashite::Epin::Parser.parse(letter)
    raise "wrong abbr for #{letter}" unless result.pin.abbr == letter.to_sym
    raise "wrong side for #{letter}" unless result.pin.side == :first
  end
end

Test("parses all lowercase letters a-z") do
  ("a".."z").each do |letter|
    result = Sashite::Epin::Parser.parse(letter)
    raise "wrong abbr for #{letter}" unless result.pin.abbr == letter.upcase.to_sym
    raise "wrong side for #{letter}" unless result.pin.side == :second
  end
end

Test("parses all uppercase letters with derivation marker") do
  ("A".."Z").each do |letter|
    result = Sashite::Epin::Parser.parse("#{letter}'")
    raise "wrong abbr for #{letter}'" unless result.pin.abbr == letter.to_sym
    raise "should be derived for #{letter}'" unless result.derived?
  end
end

# ============================================================================
# PARSE - RETURNS CACHED INSTANCES
# ============================================================================

puts
puts "parse - returns cached instances:"

Test("parse returns cached Identifier") do
  a = Sashite::Epin::Parser.parse("K^'")
  b = Sashite::Epin::Parser.parse("K^'")
  raise "should be identical object" unless a.equal?(b)
end

Test("parse returns Identifier with cached PIN") do
  result = Sashite::Epin::Parser.parse("+R")
  pin = Sashite::Pin.parse("+R")
  raise "PIN should be identical object" unless result.pin.equal?(pin)
end

# ============================================================================
# SAFE_PARSE - VALID INPUTS
# ============================================================================

puts
puts "safe_parse - valid inputs:"

Test("safe_parse returns Identifier for native") do
  result = Sashite::Epin::Parser.safe_parse("K")
  raise "should not be nil" if result.nil?
  raise "wrong class" unless Sashite::Epin::Identifier === result
  raise "wrong abbr" unless result.pin.abbr == :K
  raise "should be native" unless result.native?
end

Test("safe_parse returns Identifier for derived") do
  result = Sashite::Epin::Parser.safe_parse("K^'")
  raise "should not be nil" if result.nil?
  raise "should be derived" unless result.derived?
  raise "should be terminal" unless result.pin.terminal?
end

Test("safe_parse returns cached instance") do
  a = Sashite::Epin::Parser.safe_parse("+R^'")
  b = Sashite::Epin::Parser.safe_parse("+R^'")
  raise "should be identical object" unless a.equal?(b)
end

# ============================================================================
# SAFE_PARSE - INVALID INPUTS (RETURNS NIL)
# ============================================================================

puts
puts "safe_parse - invalid inputs (returns nil):"

Test("safe_parse returns nil for empty string") do
  raise "should be nil" unless Sashite::Epin::Parser.safe_parse("").nil?
end

Test("safe_parse returns nil for invalid string") do
  raise "should be nil" unless Sashite::Epin::Parser.safe_parse("invalid").nil?
end

Test("safe_parse returns nil for multiple derivation markers") do
  raise "should be nil" unless Sashite::Epin::Parser.safe_parse("K''").nil?
end

Test("safe_parse returns nil for misplaced derivation marker") do
  raise "should be nil" unless Sashite::Epin::Parser.safe_parse("K'^").nil?
end

Test("safe_parse returns nil for nil input") do
  raise "should be nil" unless Sashite::Epin::Parser.safe_parse(nil).nil?
end

Test("safe_parse returns nil for non-string input") do
  raise "should be nil" unless Sashite::Epin::Parser.safe_parse(123).nil?
  raise "should be nil" unless Sashite::Epin::Parser.safe_parse(:K).nil?
  raise "should be nil" unless Sashite::Epin::Parser.safe_parse([:K]).nil?
end

Test("safe_parse returns nil for too-long input") do
  raise "should be nil" unless Sashite::Epin::Parser.safe_parse("+K^'X").nil?
end

# ============================================================================
# VALID? METHOD
# ============================================================================

puts
puts "valid? method:"

Test("returns true for valid native EPIN") do
  raise "should be valid" unless Sashite::Epin::Parser.valid?("K")
  raise "should be valid" unless Sashite::Epin::Parser.valid?("+R")
  raise "should be valid" unless Sashite::Epin::Parser.valid?("K^")
  raise "should be valid" unless Sashite::Epin::Parser.valid?("+K^")
end

Test("returns true for valid derived EPIN") do
  raise "should be valid" unless Sashite::Epin::Parser.valid?("K'")
  raise "should be valid" unless Sashite::Epin::Parser.valid?("+R'")
  raise "should be valid" unless Sashite::Epin::Parser.valid?("K^'")
  raise "should be valid" unless Sashite::Epin::Parser.valid?("+K^'")
end

Test("returns false for invalid inputs") do
  raise "should be invalid" if Sashite::Epin::Parser.valid?("")
  raise "should be invalid" if Sashite::Epin::Parser.valid?("invalid")
  raise "should be invalid" if Sashite::Epin::Parser.valid?("K''")
  raise "should be invalid" if Sashite::Epin::Parser.valid?("K'^")
  raise "should be invalid" if Sashite::Epin::Parser.valid?(nil)
end

# ============================================================================
# ERROR CASES - EMPTY INPUT
# ============================================================================

puts
puts "Error cases - empty input:"

Test("raises on empty string") do
  Sashite::Epin::Parser.parse("")
  raise "should have raised"
rescue Sashite::Epin::Errors::Argument => e
  raise "wrong message" unless e.message.include?("invalid PIN component")
end

# ============================================================================
# ERROR CASES - INVALID DERIVATION MARKER
# ============================================================================

puts
puts "Error cases - invalid derivation marker:"

Test("raises on multiple derivation markers") do
  Sashite::Epin::Parser.parse("K''")
  raise "should have raised"
rescue Sashite::Epin::Errors::Argument => e
  raise "wrong message" unless e.message == Sashite::Epin::Errors::Argument::Messages::INVALID_DERIVATION_MARKER
end

Test("raises on derivation marker not at end") do
  Sashite::Epin::Parser.parse("K'^")
  raise "should have raised"
rescue Sashite::Epin::Errors::Argument => e
  raise "wrong message" unless e.message == Sashite::Epin::Errors::Argument::Messages::INVALID_DERIVATION_MARKER
end

Test("raises on derivation marker at start") do
  Sashite::Epin::Parser.parse("'K")
  raise "should have raised"
rescue Sashite::Epin::Errors::Argument => e
  raise "wrong message" unless e.message == Sashite::Epin::Errors::Argument::Messages::INVALID_DERIVATION_MARKER
end

Test("raises on derivation marker in middle") do
  Sashite::Epin::Parser.parse("K'^")
  raise "should have raised"
rescue Sashite::Epin::Errors::Argument => e
  raise "wrong message" unless e.message == Sashite::Epin::Errors::Argument::Messages::INVALID_DERIVATION_MARKER
end

# ============================================================================
# ERROR CASES - INVALID PIN COMPONENT
# ============================================================================

puts
puts "Error cases - invalid PIN component:"

Test("raises on digit") do
  Sashite::Epin::Parser.parse("1")
  raise "should have raised"
rescue Sashite::Epin::Errors::Argument => e
  raise "wrong message" unless e.message.include?("invalid PIN component")
end

Test("raises on multiple letters") do
  Sashite::Epin::Parser.parse("KQ")
  raise "should have raised"
rescue Sashite::Epin::Errors::Argument => e
  raise "wrong message" unless e.message.include?("invalid PIN component")
end

Test("raises on invalid state modifier") do
  Sashite::Epin::Parser.parse("++K")
  raise "should have raised"
rescue Sashite::Epin::Errors::Argument => e
  raise "wrong message" unless e.message.include?("invalid PIN component")
end

# ============================================================================
# SECURITY TESTS - NULL BYTE INJECTION
# ============================================================================

puts
puts "Security - null byte injection:"

Test("rejects null byte alone") do
  raise "should be invalid" if Sashite::Epin::Parser.valid?("\x00")
end

Test("rejects null byte in PIN") do
  raise "should be invalid" if Sashite::Epin::Parser.valid?("K\x00")
  raise "should be invalid" if Sashite::Epin::Parser.valid?("\x00K")
end

Test("rejects null byte before derivation marker") do
  raise "should be invalid" if Sashite::Epin::Parser.valid?("K\x00'")
end

# ============================================================================
# SECURITY TESTS - CONTROL CHARACTERS
# ============================================================================

puts
puts "Security - control characters:"

Test("rejects newline") do
  raise "should be invalid" if Sashite::Epin::Parser.valid?("K\n")
  raise "should be invalid" if Sashite::Epin::Parser.valid?("K'\n")
end

Test("rejects carriage return") do
  raise "should be invalid" if Sashite::Epin::Parser.valid?("K\r")
  raise "should be invalid" if Sashite::Epin::Parser.valid?("\rK")
end

Test("rejects tab") do
  raise "should be invalid" if Sashite::Epin::Parser.valid?("K\t")
  raise "should be invalid" if Sashite::Epin::Parser.valid?("\tK")
end

Test("rejects other control characters") do
  raise "should be invalid" if Sashite::Epin::Parser.valid?("\x01K")
  raise "should be invalid" if Sashite::Epin::Parser.valid?("K\x1b")
  raise "should be invalid" if Sashite::Epin::Parser.valid?("K\x7f")
end

# ============================================================================
# SECURITY TESTS - UNICODE LOOKALIKES
# ============================================================================

puts
puts "Security - Unicode lookalikes:"

Test("rejects Cyrillic lookalikes") do
  # Cyrillic 'К' (U+041A) looks like Latin 'K'
  raise "should be invalid" if Sashite::Epin::Parser.valid?("\xD0\x9A")
  # Cyrillic 'а' (U+0430) looks like Latin 'a'
  raise "should be invalid" if Sashite::Epin::Parser.valid?("\xD0\xB0")
end

Test("rejects Greek lookalikes") do
  # Greek 'Α' (U+0391) looks like Latin 'A'
  raise "should be invalid" if Sashite::Epin::Parser.valid?("\xCE\x91")
end

Test("rejects full-width characters") do
  # Full-width 'K' (U+FF2B)
  raise "should be invalid" if Sashite::Epin::Parser.valid?("\xEF\xBC\xAB")
end

# ============================================================================
# SECURITY TESTS - COMBINING CHARACTERS
# ============================================================================

puts
puts "Security - combining characters:"

Test("rejects combining acute accent") do
  # 'K' + combining acute accent (U+0301)
  raise "should be invalid" if Sashite::Epin::Parser.valid?("K\xCC\x81")
end

Test("rejects combining diaeresis") do
  # 'K' + combining diaeresis (U+0308)
  raise "should be invalid" if Sashite::Epin::Parser.valid?("K\xCC\x88")
end

# ============================================================================
# SECURITY TESTS - ZERO-WIDTH CHARACTERS
# ============================================================================

puts
puts "Security - zero-width characters:"

Test("rejects zero-width space") do
  # Zero-width space (U+200B)
  raise "should be invalid" if Sashite::Epin::Parser.valid?("\xE2\x80\x8B")
  raise "should be invalid" if Sashite::Epin::Parser.valid?("K\xE2\x80\x8B")
end

Test("rejects zero-width non-joiner") do
  # Zero-width non-joiner (U+200C)
  raise "should be invalid" if Sashite::Epin::Parser.valid?("\xE2\x80\x8C")
end

Test("rejects BOM") do
  # Byte order mark (U+FEFF)
  raise "should be invalid" if Sashite::Epin::Parser.valid?("\xEF\xBB\xBF")
  raise "should be invalid" if Sashite::Epin::Parser.valid?("\xEF\xBB\xBFK")
end

# ============================================================================
# SECURITY TESTS - NON-STRING INPUT
# ============================================================================

puts
puts "Security - non-string input:"

Test("rejects nil") do
  raise "should be invalid" if Sashite::Epin::Parser.valid?(nil)
end

Test("rejects integer") do
  raise "should be invalid" if Sashite::Epin::Parser.valid?(123)
end

Test("rejects array") do
  raise "should be invalid" if Sashite::Epin::Parser.valid?([:K])
end

Test("rejects hash") do
  raise "should be invalid" if Sashite::Epin::Parser.valid?({ pin: "K" })
end

Test("rejects symbol") do
  raise "should be invalid" if Sashite::Epin::Parser.valid?(:K)
end

# ============================================================================
# ROUND-TRIP TESTS
# ============================================================================

puts
puts "Round-trip tests:"

Test("round-trip native EPIN") do
  %w[K k +R -p K^ +K^ -k^].each do |epin_string|
    result = Sashite::Epin::Parser.parse(epin_string)
    raise "round-trip failed for #{epin_string}" unless result.to_s == epin_string
  end
end

Test("round-trip derived EPIN") do
  ["K'", "k'", "+R'", "-p'", "K^'", "+K^'", "-k^'"].each do |epin_string|
    result = Sashite::Epin::Parser.parse(epin_string)
    raise "round-trip failed for #{epin_string}" unless result.to_s == epin_string
  end
end

puts
puts "All Parser tests passed!"
puts
