#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "../helper"
require_relative "../../lib/sashite/epin"

puts
puts "=== Epin Module Tests ==="
puts

# ============================================================================
# PARSE METHOD
# ============================================================================

puts "parse method:"

Test("parses native EPIN") do
  epin = Sashite::Epin.parse("K")
  raise "wrong class" unless Sashite::Epin::Identifier === epin
  raise "wrong abbr" unless epin.pin.abbr == :K
  raise "should be native" unless epin.native?
end

Test("parses derived EPIN") do
  epin = Sashite::Epin.parse("K'")
  raise "wrong class" unless Sashite::Epin::Identifier === epin
  raise "wrong abbr" unless epin.pin.abbr == :K
  raise "should be derived" unless epin.derived?
end

Test("parses EPIN with all modifiers") do
  epin = Sashite::Epin.parse("+K^'")
  raise "wrong abbr" unless epin.pin.abbr == :K
  raise "wrong side" unless epin.pin.side == :first
  raise "wrong state" unless epin.pin.state == :enhanced
  raise "should be terminal" unless epin.pin.terminal?
  raise "should be derived" unless epin.derived?
end

Test("parses lowercase EPIN") do
  epin = Sashite::Epin.parse("-p^'")
  raise "wrong abbr" unless epin.pin.abbr == :P
  raise "wrong side" unless epin.pin.side == :second
  raise "wrong state" unless epin.pin.state == :diminished
  raise "should be terminal" unless epin.pin.terminal?
  raise "should be derived" unless epin.derived?
end

Test("parse returns cached instance") do
  a = Sashite::Epin.parse("K^'")
  b = Sashite::Epin.parse("K^'")
  raise "should be identical object" unless a.equal?(b)
end

Test("raises on invalid input") do
  Sashite::Epin.parse("invalid")
  raise "should have raised"
rescue Sashite::Epin::Errors::Argument
  # Expected
end

Test("raises on empty string") do
  Sashite::Epin.parse("")
  raise "should have raised"
rescue Sashite::Epin::Errors::Argument
  # Expected
end

Test("raises on invalid derivation marker") do
  Sashite::Epin.parse("K''")
  raise "should have raised"
rescue Sashite::Epin::Errors::Argument
  # Expected
end

# ============================================================================
# SAFE_PARSE METHOD
# ============================================================================

puts
puts "safe_parse method:"

Test("returns Identifier for valid native EPIN") do
  epin = Sashite::Epin.safe_parse("K")
  raise "should not be nil" if epin.nil?
  raise "wrong class" unless Sashite::Epin::Identifier === epin
  raise "wrong abbr" unless epin.pin.abbr == :K
  raise "should be native" unless epin.native?
end

Test("returns Identifier for valid derived EPIN") do
  epin = Sashite::Epin.safe_parse("K^'")
  raise "should not be nil" if epin.nil?
  raise "should be derived" unless epin.derived?
  raise "should be terminal" unless epin.pin.terminal?
end

Test("returns cached instance") do
  a = Sashite::Epin.safe_parse("+R^'")
  b = Sashite::Epin.safe_parse("+R^'")
  raise "should be identical object" unless a.equal?(b)
end

Test("returns nil for empty string") do
  raise "should be nil" unless Sashite::Epin.safe_parse("").nil?
end

Test("returns nil for invalid string") do
  raise "should be nil" unless Sashite::Epin.safe_parse("invalid").nil?
end

Test("returns nil for multiple derivation markers") do
  raise "should be nil" unless Sashite::Epin.safe_parse("K''").nil?
end

Test("returns nil for nil input") do
  raise "should be nil" unless Sashite::Epin.safe_parse(nil).nil?
end

Test("returns nil for non-string input") do
  raise "should be nil" unless Sashite::Epin.safe_parse(123).nil?
  raise "should be nil" unless Sashite::Epin.safe_parse(:K).nil?
end

# ============================================================================
# FETCH METHOD
# ============================================================================

puts
puts "fetch method:"

Test("fetches native Identifier by PIN component") do
  pin = Sashite::Pin.parse("K^")
  epin = Sashite::Epin.fetch(pin)
  raise "wrong class" unless Sashite::Epin::Identifier === epin
  raise "should be native" unless epin.native?
  raise "wrong PIN" unless epin.pin.equal?(pin)
end

Test("fetches derived Identifier by PIN component") do
  pin = Sashite::Pin.parse("K^")
  epin = Sashite::Epin.fetch(pin, derived: true)
  raise "should be derived" unless epin.derived?
  raise "wrong string" unless epin.to_s == "K^'"
end

Test("fetch returns cached instance") do
  pin = Sashite::Pin.parse("+R")
  a = Sashite::Epin.fetch(pin, derived: true)
  b = Sashite::Epin.fetch(pin, derived: true)
  raise "should be identical object" unless a.equal?(b)
end

Test("fetch returns same instance as parse") do
  pin = Sashite::Pin.parse("K^")
  from_fetch = Sashite::Epin.fetch(pin, derived: true)
  from_parse = Sashite::Epin.parse("K^'")
  raise "should be identical object" unless from_fetch.equal?(from_parse)
end

Test("fetch raises on nil PIN") do
  Sashite::Epin.fetch(nil)
  raise "should have raised"
rescue Sashite::Epin::Errors::Argument => e
  raise "wrong message" unless e.message == Sashite::Epin::Errors::Argument::Messages::INVALID_PIN
end

Test("fetch raises on string PIN") do
  Sashite::Epin.fetch("K")
  raise "should have raised"
rescue Sashite::Epin::Errors::Argument => e
  raise "wrong message" unless e.message == Sashite::Epin::Errors::Argument::Messages::INVALID_PIN
end

Test("fetch raises on invalid derived value") do
  pin = Sashite::Pin.parse("K")
  Sashite::Epin.fetch(pin, derived: nil)
  raise "should have raised"
rescue Sashite::Epin::Errors::Argument => e
  raise "wrong message" unless e.message == Sashite::Epin::Errors::Argument::Messages::INVALID_DERIVED
end

# ============================================================================
# VALID? METHOD
# ============================================================================

puts
puts "valid? method:"

Test("returns true for valid native EPIN") do
  raise "should be valid" unless Sashite::Epin.valid?("K")
  raise "should be valid" unless Sashite::Epin.valid?("+R")
  raise "should be valid" unless Sashite::Epin.valid?("K^")
  raise "should be valid" unless Sashite::Epin.valid?("+K^")
end

Test("returns true for valid derived EPIN") do
  raise "should be valid" unless Sashite::Epin.valid?("K'")
  raise "should be valid" unless Sashite::Epin.valid?("+R'")
  raise "should be valid" unless Sashite::Epin.valid?("K^'")
  raise "should be valid" unless Sashite::Epin.valid?("+K^'")
end

Test("returns false for empty string") do
  raise "should be invalid" if Sashite::Epin.valid?("")
end

Test("returns false for invalid EPIN") do
  raise "should be invalid" if Sashite::Epin.valid?("invalid")
  raise "should be invalid" if Sashite::Epin.valid?("K''")
  raise "should be invalid" if Sashite::Epin.valid?("K'^")
  raise "should be invalid" if Sashite::Epin.valid?("'K")
end

Test("returns false for nil") do
  raise "should be invalid" if Sashite::Epin.valid?(nil)
end

Test("returns false for non-string") do
  raise "should be invalid" if Sashite::Epin.valid?(123)
  raise "should be invalid" if Sashite::Epin.valid?(:K)
  raise "should be invalid" if Sashite::Epin.valid?([:K])
end

# ============================================================================
# ROUND-TRIP TESTS
# ============================================================================

puts
puts "Round-trip tests:"

Test("round-trip native EPIN strings") do
  %w[K k +R -p K^ +K^ -k^].each do |epin_string|
    epin = Sashite::Epin.parse(epin_string)
    raise "round-trip failed for #{epin_string}" unless epin.to_s == epin_string
  end
end

Test("round-trip derived EPIN strings") do
  ["K'", "k'", "+R'", "-p'", "K^'", "+K^'", "-k^'"].each do |epin_string|
    epin = Sashite::Epin.parse(epin_string)
    raise "round-trip failed for #{epin_string}" unless epin.to_s == epin_string
  end
end

# ============================================================================
# PIN COMPATIBILITY
# ============================================================================

puts
puts "PIN compatibility:"

Test("every valid PIN is a valid EPIN") do
  %w[K +R -p K^ +R^ -p^].each do |pin_string|
    raise "#{pin_string} should be valid EPIN" unless Sashite::Epin.valid?(pin_string)
    epin = Sashite::Epin.parse(pin_string)
    raise "should be native" unless epin.native?
    raise "round-trip failed" unless epin.to_s == pin_string
  end
end

# ============================================================================
# FLYWEIGHT CONSISTENCY
# ============================================================================

puts
puts "Flyweight consistency:"

Test("parse, safe_parse, and fetch return identical objects") do
  pin = Sashite::Pin.parse("K")
  from_parse = Sashite::Epin.parse("K'")
  from_safe  = Sashite::Epin.safe_parse("K'")
  from_fetch = Sashite::Epin.fetch(pin, derived: true)
  raise "parse vs safe_parse mismatch" unless from_parse.equal?(from_safe)
  raise "parse vs fetch mismatch" unless from_parse.equal?(from_fetch)
end

Test("transformations return same objects as parse") do
  native = Sashite::Epin.parse("K")
  derived = Sashite::Epin.parse("K'")
  raise "derive mismatch" unless native.derive.equal?(derived)
  raise "native mismatch" unless derived.native.equal?(native)
end

# ============================================================================
# INTEGRATION WITH IDENTIFIER
# ============================================================================

puts
puts "Integration with Identifier:"

Test("parsed identifier supports transformations") do
  epin = Sashite::Epin.parse("K^")
  derived = epin.derive
  raise "should be derived" unless derived.derived?
  raise "wrong string" unless derived.to_s == "K^'"
end

Test("parsed identifier supports PIN access") do
  epin = Sashite::Epin.parse("+R^'")
  raise "wrong abbr" unless epin.pin.abbr == :R
  raise "wrong state" unless epin.pin.state == :enhanced
  raise "should be terminal" unless epin.pin.terminal?
  raise "should be first player" unless epin.pin.first_player?
end

Test("parsed identifier supports with_pin") do
  epin = Sashite::Epin.parse("K'")
  new_pin = Sashite::Pin.parse("+Q^")
  result = epin.with_pin(new_pin)
  raise "wrong string" unless result.to_s == "+Q^'"
  raise "should be derived" unless result.derived?
end

Test("chained transformations via PIN are allocation-free") do
  epin = Sashite::Epin.parse("K^'")
  result = epin.with_pin(epin.pin.flip).native
  expected = Sashite::Epin.parse("k^")
  raise "should be identical object" unless result.equal?(expected)
end

puts
puts "All Epin module tests passed!"
puts
