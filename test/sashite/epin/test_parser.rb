#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "../../../lib/sashite/epin/parser"

# Helper function to run a test and report errors
def run_test(name)
  print "  #{name}... "
  yield
  puts "✓"
rescue StandardError => e
  warn "✗ Failure: #{e.message}"
  warn "    #{e.backtrace.first}"
  exit(1)
end unless defined?(run_test)

puts
puts "=== Parser Tests ==="
puts

# ============================================================================
# VALID INPUTS - NATIVE (NO DERIVATION MARKER)
# ============================================================================

puts "Valid inputs - native (no derivation marker):"

run_test("parses simple PIN 'K'") do
  result = Sashite::Epin::Parser.parse("K")
  raise "wrong abbr" unless result[:pin][:abbr] == :K
  raise "wrong side" unless result[:pin][:side] == :first
  raise "wrong state" unless result[:pin][:state] == :normal
  raise "wrong terminal" unless result[:pin][:terminal] == false
  raise "should be native" unless result[:derived] == false
end

run_test("parses lowercase PIN 'k'") do
  result = Sashite::Epin::Parser.parse("k")
  raise "wrong abbr" unless result[:pin][:abbr] == :K
  raise "wrong side" unless result[:pin][:side] == :second
  raise "should be native" unless result[:derived] == false
end

run_test("parses enhanced PIN '+R'") do
  result = Sashite::Epin::Parser.parse("+R")
  raise "wrong abbr" unless result[:pin][:abbr] == :R
  raise "wrong state" unless result[:pin][:state] == :enhanced
  raise "should be native" unless result[:derived] == false
end

run_test("parses diminished PIN '-p'") do
  result = Sashite::Epin::Parser.parse("-p")
  raise "wrong abbr" unless result[:pin][:abbr] == :P
  raise "wrong side" unless result[:pin][:side] == :second
  raise "wrong state" unless result[:pin][:state] == :diminished
  raise "should be native" unless result[:derived] == false
end

run_test("parses terminal PIN 'K^'") do
  result = Sashite::Epin::Parser.parse("K^")
  raise "wrong abbr" unless result[:pin][:abbr] == :K
  raise "wrong terminal" unless result[:pin][:terminal] == true
  raise "should be native" unless result[:derived] == false
end

run_test("parses PIN with all modifiers '+K^'") do
  result = Sashite::Epin::Parser.parse("+K^")
  raise "wrong abbr" unless result[:pin][:abbr] == :K
  raise "wrong state" unless result[:pin][:state] == :enhanced
  raise "wrong terminal" unless result[:pin][:terminal] == true
  raise "should be native" unless result[:derived] == false
end

# ============================================================================
# VALID INPUTS - DERIVED (WITH DERIVATION MARKER)
# ============================================================================

puts
puts "Valid inputs - derived (with derivation marker):"

run_test("parses derived PIN \"K'\"") do
  result = Sashite::Epin::Parser.parse("K'")
  raise "wrong abbr" unless result[:pin][:abbr] == :K
  raise "wrong side" unless result[:pin][:side] == :first
  raise "should be derived" unless result[:derived] == true
end

run_test("parses derived lowercase PIN \"k'\"") do
  result = Sashite::Epin::Parser.parse("k'")
  raise "wrong abbr" unless result[:pin][:abbr] == :K
  raise "wrong side" unless result[:pin][:side] == :second
  raise "should be derived" unless result[:derived] == true
end

run_test("parses derived enhanced PIN \"+R'\"") do
  result = Sashite::Epin::Parser.parse("+R'")
  raise "wrong abbr" unless result[:pin][:abbr] == :R
  raise "wrong state" unless result[:pin][:state] == :enhanced
  raise "should be derived" unless result[:derived] == true
end

run_test("parses derived terminal PIN \"K^'\"") do
  result = Sashite::Epin::Parser.parse("K^'")
  raise "wrong abbr" unless result[:pin][:abbr] == :K
  raise "wrong terminal" unless result[:pin][:terminal] == true
  raise "should be derived" unless result[:derived] == true
end

run_test("parses derived PIN with all modifiers \"+K^'\"") do
  result = Sashite::Epin::Parser.parse("+K^'")
  raise "wrong abbr" unless result[:pin][:abbr] == :K
  raise "wrong state" unless result[:pin][:state] == :enhanced
  raise "wrong terminal" unless result[:pin][:terminal] == true
  raise "should be derived" unless result[:derived] == true
end

# ============================================================================
# VALID INPUTS - ALL LETTERS
# ============================================================================

puts
puts "Valid inputs - all letters:"

run_test("parses all uppercase letters A-Z") do
  ("A".."Z").each do |letter|
    result = Sashite::Epin::Parser.parse(letter)
    raise "wrong abbr for #{letter}" unless result[:pin][:abbr] == letter.to_sym
    raise "wrong side for #{letter}" unless result[:pin][:side] == :first
  end
end

run_test("parses all lowercase letters a-z") do
  ("a".."z").each do |letter|
    result = Sashite::Epin::Parser.parse(letter)
    raise "wrong abbr for #{letter}" unless result[:pin][:abbr] == letter.upcase.to_sym
    raise "wrong side for #{letter}" unless result[:pin][:side] == :second
  end
end

run_test("parses all uppercase letters with derivation marker") do
  ("A".."Z").each do |letter|
    result = Sashite::Epin::Parser.parse("#{letter}'")
    raise "wrong abbr for #{letter}'" unless result[:pin][:abbr] == letter.to_sym
    raise "should be derived for #{letter}'" unless result[:derived] == true
  end
end

# ============================================================================
# VALID? METHOD
# ============================================================================

puts
puts "valid? method:"

run_test("returns true for valid native EPIN") do
  raise "should be valid" unless Sashite::Epin::Parser.valid?("K")
  raise "should be valid" unless Sashite::Epin::Parser.valid?("+R")
  raise "should be valid" unless Sashite::Epin::Parser.valid?("K^")
  raise "should be valid" unless Sashite::Epin::Parser.valid?("+K^")
end

run_test("returns true for valid derived EPIN") do
  raise "should be valid" unless Sashite::Epin::Parser.valid?("K'")
  raise "should be valid" unless Sashite::Epin::Parser.valid?("+R'")
  raise "should be valid" unless Sashite::Epin::Parser.valid?("K^'")
  raise "should be valid" unless Sashite::Epin::Parser.valid?("+K^'")
end

run_test("returns false for invalid inputs") do
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

run_test("raises on empty string") do
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

run_test("raises on multiple derivation markers") do
  Sashite::Epin::Parser.parse("K''")
  raise "should have raised"
rescue Sashite::Epin::Errors::Argument => e
  raise "wrong message" unless e.message == Sashite::Epin::Errors::Argument::Messages::INVALID_DERIVATION_MARKER
end

run_test("raises on derivation marker not at end") do
  Sashite::Epin::Parser.parse("K'^")
  raise "should have raised"
rescue Sashite::Epin::Errors::Argument => e
  raise "wrong message" unless e.message == Sashite::Epin::Errors::Argument::Messages::INVALID_DERIVATION_MARKER
end

run_test("raises on derivation marker at start") do
  Sashite::Epin::Parser.parse("'K")
  raise "should have raised"
rescue Sashite::Epin::Errors::Argument => e
  raise "wrong message" unless e.message == Sashite::Epin::Errors::Argument::Messages::INVALID_DERIVATION_MARKER
end

run_test("raises on derivation marker in middle") do
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

run_test("raises on digit") do
  Sashite::Epin::Parser.parse("1")
  raise "should have raised"
rescue Sashite::Epin::Errors::Argument => e
  raise "wrong message" unless e.message.include?("invalid PIN component")
end

run_test("raises on multiple letters") do
  Sashite::Epin::Parser.parse("KQ")
  raise "should have raised"
rescue Sashite::Epin::Errors::Argument => e
  raise "wrong message" unless e.message.include?("invalid PIN component")
end

run_test("raises on invalid state modifier") do
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

run_test("rejects null byte alone") do
  raise "should be invalid" if Sashite::Epin::Parser.valid?("\x00")
end

run_test("rejects null byte in PIN") do
  raise "should be invalid" if Sashite::Epin::Parser.valid?("K\x00")
  raise "should be invalid" if Sashite::Epin::Parser.valid?("\x00K")
end

run_test("rejects null byte before derivation marker") do
  raise "should be invalid" if Sashite::Epin::Parser.valid?("K\x00'")
end

# ============================================================================
# SECURITY TESTS - CONTROL CHARACTERS
# ============================================================================

puts
puts "Security - control characters:"

run_test("rejects newline") do
  raise "should be invalid" if Sashite::Epin::Parser.valid?("K\n")
  raise "should be invalid" if Sashite::Epin::Parser.valid?("K'\n")
end

run_test("rejects carriage return") do
  raise "should be invalid" if Sashite::Epin::Parser.valid?("K\r")
  raise "should be invalid" if Sashite::Epin::Parser.valid?("\rK")
end

run_test("rejects tab") do
  raise "should be invalid" if Sashite::Epin::Parser.valid?("K\t")
  raise "should be invalid" if Sashite::Epin::Parser.valid?("\tK")
end

run_test("rejects other control characters") do
  raise "should be invalid" if Sashite::Epin::Parser.valid?("\x01K")
  raise "should be invalid" if Sashite::Epin::Parser.valid?("K\x1b")
  raise "should be invalid" if Sashite::Epin::Parser.valid?("K\x7f")
end

# ============================================================================
# SECURITY TESTS - UNICODE LOOKALIKES
# ============================================================================

puts
puts "Security - Unicode lookalikes:"

run_test("rejects Cyrillic lookalikes") do
  # Cyrillic 'К' (U+041A) looks like Latin 'K'
  raise "should be invalid" if Sashite::Epin::Parser.valid?("\xD0\x9A")
  # Cyrillic 'а' (U+0430) looks like Latin 'a'
  raise "should be invalid" if Sashite::Epin::Parser.valid?("\xD0\xB0")
end

run_test("rejects Greek lookalikes") do
  # Greek 'Α' (U+0391) looks like Latin 'A'
  raise "should be invalid" if Sashite::Epin::Parser.valid?("\xCE\x91")
end

run_test("rejects full-width characters") do
  # Full-width 'K' (U+FF2B)
  raise "should be invalid" if Sashite::Epin::Parser.valid?("\xEF\xBC\xAB")
end

# ============================================================================
# SECURITY TESTS - COMBINING CHARACTERS
# ============================================================================

puts
puts "Security - combining characters:"

run_test("rejects combining acute accent") do
  # 'K' + combining acute accent (U+0301)
  raise "should be invalid" if Sashite::Epin::Parser.valid?("K\xCC\x81")
end

run_test("rejects combining diaeresis") do
  # 'K' + combining diaeresis (U+0308)
  raise "should be invalid" if Sashite::Epin::Parser.valid?("K\xCC\x88")
end

# ============================================================================
# SECURITY TESTS - ZERO-WIDTH CHARACTERS
# ============================================================================

puts
puts "Security - zero-width characters:"

run_test("rejects zero-width space") do
  # Zero-width space (U+200B)
  raise "should be invalid" if Sashite::Epin::Parser.valid?("\xE2\x80\x8B")
  raise "should be invalid" if Sashite::Epin::Parser.valid?("K\xE2\x80\x8B")
end

run_test("rejects zero-width non-joiner") do
  # Zero-width non-joiner (U+200C)
  raise "should be invalid" if Sashite::Epin::Parser.valid?("\xE2\x80\x8C")
end

run_test("rejects BOM") do
  # Byte order mark (U+FEFF)
  raise "should be invalid" if Sashite::Epin::Parser.valid?("\xEF\xBB\xBF")
  raise "should be invalid" if Sashite::Epin::Parser.valid?("\xEF\xBB\xBFK")
end

# ============================================================================
# SECURITY TESTS - NON-STRING INPUT
# ============================================================================

puts
puts "Security - non-string input:"

run_test("rejects nil") do
  raise "should be invalid" if Sashite::Epin::Parser.valid?(nil)
end

run_test("rejects integer") do
  raise "should be invalid" if Sashite::Epin::Parser.valid?(123)
end

run_test("rejects array") do
  raise "should be invalid" if Sashite::Epin::Parser.valid?([:K])
end

run_test("rejects hash") do
  raise "should be invalid" if Sashite::Epin::Parser.valid?({ pin: "K" })
end

run_test("rejects symbol") do
  raise "should be invalid" if Sashite::Epin::Parser.valid?(:K)
end

# ============================================================================
# ROUND-TRIP TESTS
# ============================================================================

puts
puts "Round-trip tests:"

run_test("round-trip native EPIN") do
  %w[K k +R -p K^ +K^ -k^].each do |epin_string|
    result = Sashite::Epin::Parser.parse(epin_string)
    pin = Sashite::Pin::Identifier.new(
      result[:pin][:abbr],
      result[:pin][:side],
      result[:pin][:state],
      terminal: result[:pin][:terminal]
    )
    identifier = Sashite::Epin::Identifier.new(pin, derived: result[:derived])
    raise "round-trip failed for #{epin_string}" unless identifier.to_s == epin_string
  end
end

run_test("round-trip derived EPIN") do
  ["K'", "k'", "+R'", "-p'", "K^'", "+K^'", "-k^'"].each do |epin_string|
    result = Sashite::Epin::Parser.parse(epin_string)
    pin = Sashite::Pin::Identifier.new(
      result[:pin][:abbr],
      result[:pin][:side],
      result[:pin][:state],
      terminal: result[:pin][:terminal]
    )
    identifier = Sashite::Epin::Identifier.new(pin, derived: result[:derived])
    raise "round-trip failed for #{epin_string}" unless identifier.to_s == epin_string
  end
end

puts
puts "All Parser tests passed!"
puts
