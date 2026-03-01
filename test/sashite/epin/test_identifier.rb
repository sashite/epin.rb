#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "../../helper"
require_relative "../../../lib/sashite/epin/identifier"

puts
puts "=== Identifier Tests ==="
puts

# ============================================================================
# CONSTRUCTOR TESTS
# ============================================================================

puts "Constructor:"

Test("creates identifier with PIN component") do
  pin = Sashite::Pin.parse("K")
  epin = Sashite::Epin::Identifier.new(pin)
  raise "wrong pin" unless epin.pin == pin
  raise "should be native by default" unless epin.native?
end

Test("creates identifier with derived: true") do
  pin = Sashite::Pin.parse("K")
  epin = Sashite::Epin::Identifier.new(pin, derived: true)
  raise "should be derived" unless epin.derived?
end

Test("creates identifier with derived: false") do
  pin = Sashite::Pin.parse("K")
  epin = Sashite::Epin::Identifier.new(pin, derived: false)
  raise "should be native" unless epin.native?
end

Test("creates identifier with enhanced PIN") do
  pin = Sashite::Pin.parse("+R")
  epin = Sashite::Epin::Identifier.new(pin)
  raise "wrong state" unless epin.pin.state == :enhanced
end

Test("creates identifier with terminal PIN") do
  pin = Sashite::Pin.parse("K^")
  epin = Sashite::Epin::Identifier.new(pin)
  raise "should be terminal" unless epin.pin.terminal?
end

Test("creates identifier with all PIN modifiers") do
  pin = Sashite::Pin.parse("+K^")
  epin = Sashite::Epin::Identifier.new(pin, derived: true)
  raise "wrong state" unless epin.pin.state == :enhanced
  raise "should be terminal" unless epin.pin.terminal?
  raise "should be derived" unless epin.derived?
end

Test("raises on nil PIN") do
  Sashite::Epin::Identifier.new(nil)
  raise "should have raised"
rescue Sashite::Epin::Errors::Argument => e
  raise "wrong message" unless e.message == Sashite::Epin::Errors::Argument::Messages::INVALID_PIN
end

Test("raises on string PIN") do
  Sashite::Epin::Identifier.new("K")
  raise "should have raised"
rescue Sashite::Epin::Errors::Argument => e
  raise "wrong message" unless e.message == Sashite::Epin::Errors::Argument::Messages::INVALID_PIN
end

Test("raises on invalid derived value") do
  pin = Sashite::Pin.parse("K")
  Sashite::Epin::Identifier.new(pin, derived: "true")
  raise "should have raised"
rescue Sashite::Epin::Errors::Argument => e
  raise "wrong message" unless e.message == Sashite::Epin::Errors::Argument::Messages::INVALID_DERIVED
end

Test("raises on nil derived value") do
  pin = Sashite::Pin.parse("K")
  Sashite::Epin::Identifier.new(pin, derived: nil)
  raise "should have raised"
rescue Sashite::Epin::Errors::Argument => e
  raise "wrong message" unless e.message == Sashite::Epin::Errors::Argument::Messages::INVALID_DERIVED
end

# ============================================================================
# IMMUTABILITY TESTS
# ============================================================================

puts
puts "Immutability:"

Test("identifier is frozen after creation") do
  pin = Sashite::Pin.parse("K")
  epin = Sashite::Epin::Identifier.new(pin)
  raise "should be frozen" unless epin.frozen?
end

Test("to_s returns a frozen string") do
  pin = Sashite::Pin.parse("K")
  epin = Sashite::Epin::Identifier.new(pin, derived: true)
  raise "string should be frozen" unless epin.to_s.frozen?
end

# ============================================================================
# FLYWEIGHT POOL TESTS
# ============================================================================

puts
puts "Flyweight pool:"

Test("fetch returns a cached Identifier for native") do
  pin = Sashite::Pin.parse("K")
  result = Sashite::Epin::Identifier.fetch(pin, false)
  raise "wrong class" unless Sashite::Epin::Identifier === result
  raise "should be native" unless result.native?
  raise "wrong PIN" unless result.pin.equal?(pin)
end

Test("fetch returns a cached Identifier for derived") do
  pin = Sashite::Pin.parse("K")
  result = Sashite::Epin::Identifier.fetch(pin, true)
  raise "wrong class" unless Sashite::Epin::Identifier === result
  raise "should be derived" unless result.derived?
end

Test("fetch returns same object on repeated calls") do
  pin = Sashite::Pin.parse("+R^")
  a = Sashite::Epin::Identifier.fetch(pin, true)
  b = Sashite::Epin::Identifier.fetch(pin, true)
  raise "should be identical object" unless a.equal?(b)
end

Test("fetch returns different objects for native vs derived") do
  pin = Sashite::Pin.parse("K")
  native = Sashite::Epin::Identifier.fetch(pin, false)
  derived = Sashite::Epin::Identifier.fetch(pin, true)
  raise "should not be identical" if native.equal?(derived)
  raise "should not be equal" if native == derived
end

Test("pool covers all 624 tokens") do
  count = 0
  Sashite::Pin::Constants::VALID_ABBRS.each do |abbr|
    Sashite::Pin::Constants::VALID_SIDES.each do |side|
      Sashite::Pin::Constants::VALID_STATES.each do |state|
        [false, true].each do |terminal|
          pin = Sashite::Pin.fetch(abbr, side, state, terminal: terminal)
          native = Sashite::Epin::Identifier.fetch(pin, false)
          derived = Sashite::Epin::Identifier.fetch(pin, true)
          raise "native should not be nil" if native.nil?
          raise "derived should not be nil" if derived.nil?
          count += 2
        end
      end
    end
  end
  raise "wrong pool size: #{count}" unless count == Sashite::Epin::Constants::POOL_SIZE
end

# ============================================================================
# STRING CONVERSION TESTS
# ============================================================================

puts
puts "String conversion:"

Test("to_s returns PIN string for native") do
  pin = Sashite::Pin.parse("K")
  epin = Sashite::Epin::Identifier.new(pin)
  raise "wrong string" unless epin.to_s == "K"
end

Test("to_s returns PIN string with derivation marker for derived") do
  pin = Sashite::Pin.parse("K")
  epin = Sashite::Epin::Identifier.new(pin, derived: true)
  raise "wrong string" unless epin.to_s == "K'"
end

Test("to_s with lowercase PIN") do
  pin = Sashite::Pin.parse("k")
  epin = Sashite::Epin::Identifier.new(pin, derived: true)
  raise "wrong string" unless epin.to_s == "k'"
end

Test("to_s with state modifier") do
  pin = Sashite::Pin.parse("+R")
  epin = Sashite::Epin::Identifier.new(pin, derived: true)
  raise "wrong string" unless epin.to_s == "+R'"
end

Test("to_s with terminal marker") do
  pin = Sashite::Pin.parse("K^")
  epin = Sashite::Epin::Identifier.new(pin, derived: true)
  raise "wrong string" unless epin.to_s == "K^'"
end

Test("to_s with all modifiers") do
  pin = Sashite::Pin.parse("+K^")
  epin = Sashite::Epin::Identifier.new(pin, derived: true)
  raise "wrong string" unless epin.to_s == "+K^'"
end

Test("to_s native with all PIN modifiers") do
  pin = Sashite::Pin.parse("+K^")
  epin = Sashite::Epin::Identifier.new(pin, derived: false)
  raise "wrong string" unless epin.to_s == "+K^"
end

Test("to_s is pre-computed and returns same object") do
  pin = Sashite::Pin.parse("K")
  epin = Sashite::Epin::Identifier.new(pin, derived: true)
  raise "should return same string object" unless epin.to_s.equal?(epin.to_s)
end

# ============================================================================
# DERIVED/NATIVE QUERY TESTS
# ============================================================================

puts
puts "Derived/Native queries:"

Test("derived? returns true for derived") do
  pin = Sashite::Pin.parse("K")
  epin = Sashite::Epin::Identifier.new(pin, derived: true)
  raise "should be true" unless epin.derived?
end

Test("derived? returns false for native") do
  pin = Sashite::Pin.parse("K")
  epin = Sashite::Epin::Identifier.new(pin, derived: false)
  raise "should be false" if epin.derived?
end

Test("native? returns true for native") do
  pin = Sashite::Pin.parse("K")
  epin = Sashite::Epin::Identifier.new(pin, derived: false)
  raise "should be true" unless epin.native?
end

Test("native? returns false for derived") do
  pin = Sashite::Pin.parse("K")
  epin = Sashite::Epin::Identifier.new(pin, derived: true)
  raise "should be false" if epin.native?
end

Test("derived? and native? are mutually exclusive") do
  pin = Sashite::Pin.parse("K")
  epin1 = Sashite::Epin::Identifier.new(pin, derived: true)
  epin2 = Sashite::Epin::Identifier.new(pin, derived: false)
  raise "should be exclusive" if epin1.derived? == epin1.native?
  raise "should be exclusive" if epin2.derived? == epin2.native?
end

# ============================================================================
# DERIVE TRANSFORMATION TESTS
# ============================================================================

puts
puts "Derive transformation:"

Test("derive returns derived identifier") do
  pin = Sashite::Pin.parse("K")
  epin = Sashite::Epin::Identifier.new(pin)
  result = epin.derive
  raise "should be derived" unless result.derived?
  raise "wrong string" unless result.to_s == "K'"
end

Test("derive returns self if already derived") do
  pin = Sashite::Pin.parse("K")
  epin = Sashite::Epin::Identifier.new(pin, derived: true)
  result = epin.derive
  raise "should return same object" unless epin.equal?(result)
end

Test("derive does not modify original") do
  pin = Sashite::Pin.parse("K")
  epin = Sashite::Epin::Identifier.new(pin)
  epin.derive
  raise "original should be unchanged" unless epin.native?
end

Test("derive preserves PIN component") do
  pin = Sashite::Pin.parse("+K^")
  epin = Sashite::Epin::Identifier.new(pin)
  result = epin.derive
  raise "PIN should be preserved" unless result.pin == pin
end

Test("derive returns cached pool instance") do
  pin = Sashite::Pin.parse("K")
  epin = Sashite::Epin::Identifier.new(pin)
  result = epin.derive
  pool_instance = Sashite::Epin::Identifier.fetch(pin, true)
  raise "should be pool instance" unless result.equal?(pool_instance)
end

# ============================================================================
# NATIVE TRANSFORMATION TESTS
# ============================================================================

puts
puts "Native transformation:"

Test("native returns native identifier") do
  pin = Sashite::Pin.parse("K")
  epin = Sashite::Epin::Identifier.new(pin, derived: true)
  result = epin.native
  raise "should be native" unless result.native?
  raise "wrong string" unless result.to_s == "K"
end

Test("native returns self if already native") do
  pin = Sashite::Pin.parse("K")
  epin = Sashite::Epin::Identifier.new(pin, derived: false)
  result = epin.native
  raise "should return same object" unless epin.equal?(result)
end

Test("native does not modify original") do
  pin = Sashite::Pin.parse("K")
  epin = Sashite::Epin::Identifier.new(pin, derived: true)
  epin.native
  raise "original should be unchanged" unless epin.derived?
end

Test("native preserves PIN component") do
  pin = Sashite::Pin.parse("+K^")
  epin = Sashite::Epin::Identifier.new(pin, derived: true)
  result = epin.native
  raise "PIN should be preserved" unless result.pin == pin
end

Test("native returns cached pool instance") do
  pin = Sashite::Pin.parse("K")
  epin = Sashite::Epin::Identifier.new(pin, derived: true)
  result = epin.native
  pool_instance = Sashite::Epin::Identifier.fetch(pin, false)
  raise "should be pool instance" unless result.equal?(pool_instance)
end

# ============================================================================
# WITH_PIN TRANSFORMATION TESTS
# ============================================================================

puts
puts "with_pin transformation:"

Test("with_pin replaces PIN component") do
  pin1 = Sashite::Pin.parse("K")
  pin2 = Sashite::Pin.parse("Q")
  epin = Sashite::Epin::Identifier.new(pin1)
  result = epin.with_pin(pin2)
  raise "wrong PIN" unless result.pin == pin2
  raise "wrong string" unless result.to_s == "Q"
end

Test("with_pin preserves derived status") do
  pin1 = Sashite::Pin.parse("K")
  pin2 = Sashite::Pin.parse("Q")
  epin = Sashite::Epin::Identifier.new(pin1, derived: true)
  result = epin.with_pin(pin2)
  raise "should be derived" unless result.derived?
  raise "wrong string" unless result.to_s == "Q'"
end

Test("with_pin returns self if same PIN") do
  pin = Sashite::Pin.parse("K")
  epin = Sashite::Epin::Identifier.new(pin)
  result = epin.with_pin(pin)
  raise "should return same object" unless epin.equal?(result)
end

Test("with_pin does not modify original") do
  pin1 = Sashite::Pin.parse("K")
  pin2 = Sashite::Pin.parse("Q")
  epin = Sashite::Epin::Identifier.new(pin1)
  epin.with_pin(pin2)
  raise "original should be unchanged" unless epin.pin == pin1
end

Test("with_pin raises on invalid PIN") do
  pin = Sashite::Pin.parse("K")
  epin = Sashite::Epin::Identifier.new(pin)
  epin.with_pin("Q")
  raise "should have raised"
rescue Sashite::Epin::Errors::Argument => e
  raise "wrong message" unless e.message == Sashite::Epin::Errors::Argument::Messages::INVALID_PIN
end

Test("with_pin returns cached pool instance") do
  pin1 = Sashite::Pin.parse("K")
  pin2 = Sashite::Pin.parse("+Q^")
  epin = Sashite::Epin::Identifier.new(pin1, derived: true)
  result = epin.with_pin(pin2)
  pool_instance = Sashite::Epin::Identifier.fetch(pin2, true)
  raise "should be pool instance" unless result.equal?(pool_instance)
end

# ============================================================================
# COMPARISON QUERY TESTS
# ============================================================================

puts
puts "Comparison queries:"

Test("same_derived? returns true for same derived status") do
  pin1 = Sashite::Pin.parse("K")
  pin2 = Sashite::Pin.parse("Q")
  epin1 = Sashite::Epin::Identifier.new(pin1, derived: true)
  epin2 = Sashite::Epin::Identifier.new(pin2, derived: true)
  raise "should be true" unless epin1.same_derived?(epin2)
end

Test("same_derived? returns true for both native") do
  pin1 = Sashite::Pin.parse("K")
  pin2 = Sashite::Pin.parse("Q")
  epin1 = Sashite::Epin::Identifier.new(pin1, derived: false)
  epin2 = Sashite::Epin::Identifier.new(pin2, derived: false)
  raise "should be true" unless epin1.same_derived?(epin2)
end

Test("same_derived? returns false for different derived status") do
  pin1 = Sashite::Pin.parse("K")
  pin2 = Sashite::Pin.parse("K")
  epin1 = Sashite::Epin::Identifier.new(pin1, derived: true)
  epin2 = Sashite::Epin::Identifier.new(pin2, derived: false)
  raise "should be false" if epin1.same_derived?(epin2)
end

# ============================================================================
# EQUALITY TESTS
# ============================================================================

puts
puts "Equality:"

Test("identifiers with same attributes are equal") do
  pin = Sashite::Pin.parse("K")
  epin1 = Sashite::Epin::Identifier.new(pin, derived: true)
  epin2 = Sashite::Epin::Identifier.new(pin, derived: true)
  raise "should be equal" unless epin1 == epin2
end

Test("identifiers with different PIN are not equal") do
  pin1 = Sashite::Pin.parse("K")
  pin2 = Sashite::Pin.parse("Q")
  epin1 = Sashite::Epin::Identifier.new(pin1, derived: true)
  epin2 = Sashite::Epin::Identifier.new(pin2, derived: true)
  raise "should not be equal" if epin1 == epin2
end

Test("identifiers with different derived status are not equal") do
  pin = Sashite::Pin.parse("K")
  epin1 = Sashite::Epin::Identifier.new(pin, derived: true)
  epin2 = Sashite::Epin::Identifier.new(pin, derived: false)
  raise "should not be equal" if epin1 == epin2
end

Test("eql? is aliased to ==") do
  pin = Sashite::Pin.parse("K")
  epin1 = Sashite::Epin::Identifier.new(pin, derived: true)
  epin2 = Sashite::Epin::Identifier.new(pin, derived: true)
  raise "eql? should work" unless epin1.eql?(epin2)
end

Test("equal identifiers have same hash") do
  pin = Sashite::Pin.parse("K")
  epin1 = Sashite::Epin::Identifier.new(pin, derived: true)
  epin2 = Sashite::Epin::Identifier.new(pin, derived: true)
  raise "hash should match" unless epin1.hash == epin2.hash
end

Test("different identifiers may have different hash") do
  pin1 = Sashite::Pin.parse("K")
  pin2 = Sashite::Pin.parse("Q")
  epin1 = Sashite::Epin::Identifier.new(pin1, derived: true)
  epin2 = Sashite::Epin::Identifier.new(pin2, derived: true)
  # Note: hash collision is possible but unlikely for different inputs
  # This test just verifies hash is computed
  epin1.hash
  epin2.hash
end

Test("native vs derived of same PIN have different hash") do
  pin = Sashite::Pin.parse("K")
  native = Sashite::Epin::Identifier.fetch(pin, false)
  derived = Sashite::Epin::Identifier.fetch(pin, true)
  raise "hashes should differ" if native.hash == derived.hash
end

# ============================================================================
# INSPECT TESTS
# ============================================================================

puts
puts "Inspect:"

Test("inspect returns readable representation") do
  pin = Sashite::Pin.parse("K^")
  epin = Sashite::Epin::Identifier.new(pin, derived: true)
  result = epin.inspect
  raise "wrong format" unless result == "#<Sashite::Epin::Identifier K^'>"
end

Test("inspect for native identifier") do
  pin = Sashite::Pin.parse("+R")
  epin = Sashite::Epin::Identifier.new(pin)
  result = epin.inspect
  raise "wrong format" unless result == "#<Sashite::Epin::Identifier +R>"
end

puts
puts "All Identifier tests passed!"
puts
