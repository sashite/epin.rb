#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "../../../lib/sashite/epin/identifier"

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
puts "=== Identifier Tests ==="
puts

# ============================================================================
# CONSTRUCTOR TESTS
# ============================================================================

puts "Constructor:"

run_test("creates identifier with PIN component") do
  pin = Sashite::Pin.parse("K")
  epin = Sashite::Epin::Identifier.new(pin)
  raise "wrong pin" unless epin.pin == pin
  raise "should be native by default" unless epin.native?
end

run_test("creates identifier with derived: true") do
  pin = Sashite::Pin.parse("K")
  epin = Sashite::Epin::Identifier.new(pin, derived: true)
  raise "should be derived" unless epin.derived?
end

run_test("creates identifier with derived: false") do
  pin = Sashite::Pin.parse("K")
  epin = Sashite::Epin::Identifier.new(pin, derived: false)
  raise "should be native" unless epin.native?
end

run_test("creates identifier with enhanced PIN") do
  pin = Sashite::Pin.parse("+R")
  epin = Sashite::Epin::Identifier.new(pin)
  raise "wrong state" unless epin.pin.state == :enhanced
end

run_test("creates identifier with terminal PIN") do
  pin = Sashite::Pin.parse("K^")
  epin = Sashite::Epin::Identifier.new(pin)
  raise "should be terminal" unless epin.pin.terminal?
end

run_test("creates identifier with all PIN modifiers") do
  pin = Sashite::Pin.parse("+K^")
  epin = Sashite::Epin::Identifier.new(pin, derived: true)
  raise "wrong state" unless epin.pin.state == :enhanced
  raise "should be terminal" unless epin.pin.terminal?
  raise "should be derived" unless epin.derived?
end

run_test("raises on nil PIN") do
  Sashite::Epin::Identifier.new(nil)
  raise "should have raised"
rescue Sashite::Epin::Errors::Argument => e
  raise "wrong message" unless e.message == Sashite::Epin::Errors::Argument::Messages::INVALID_PIN
end

run_test("raises on string PIN") do
  Sashite::Epin::Identifier.new("K")
  raise "should have raised"
rescue Sashite::Epin::Errors::Argument => e
  raise "wrong message" unless e.message == Sashite::Epin::Errors::Argument::Messages::INVALID_PIN
end

run_test("raises on invalid derived value") do
  pin = Sashite::Pin.parse("K")
  Sashite::Epin::Identifier.new(pin, derived: "true")
  raise "should have raised"
rescue Sashite::Epin::Errors::Argument => e
  raise "wrong message" unless e.message == Sashite::Epin::Errors::Argument::Messages::INVALID_DERIVED
end

run_test("raises on nil derived value") do
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

run_test("identifier is frozen after creation") do
  pin = Sashite::Pin.parse("K")
  epin = Sashite::Epin::Identifier.new(pin)
  raise "should be frozen" unless epin.frozen?
end

# ============================================================================
# STRING CONVERSION TESTS
# ============================================================================

puts
puts "String conversion:"

run_test("to_s returns PIN string for native") do
  pin = Sashite::Pin.parse("K")
  epin = Sashite::Epin::Identifier.new(pin)
  raise "wrong string" unless epin.to_s == "K"
end

run_test("to_s returns PIN string with derivation marker for derived") do
  pin = Sashite::Pin.parse("K")
  epin = Sashite::Epin::Identifier.new(pin, derived: true)
  raise "wrong string" unless epin.to_s == "K'"
end

run_test("to_s with lowercase PIN") do
  pin = Sashite::Pin.parse("k")
  epin = Sashite::Epin::Identifier.new(pin, derived: true)
  raise "wrong string" unless epin.to_s == "k'"
end

run_test("to_s with state modifier") do
  pin = Sashite::Pin.parse("+R")
  epin = Sashite::Epin::Identifier.new(pin, derived: true)
  raise "wrong string" unless epin.to_s == "+R'"
end

run_test("to_s with terminal marker") do
  pin = Sashite::Pin.parse("K^")
  epin = Sashite::Epin::Identifier.new(pin, derived: true)
  raise "wrong string" unless epin.to_s == "K^'"
end

run_test("to_s with all modifiers") do
  pin = Sashite::Pin.parse("+K^")
  epin = Sashite::Epin::Identifier.new(pin, derived: true)
  raise "wrong string" unless epin.to_s == "+K^'"
end

run_test("to_s native with all PIN modifiers") do
  pin = Sashite::Pin.parse("+K^")
  epin = Sashite::Epin::Identifier.new(pin, derived: false)
  raise "wrong string" unless epin.to_s == "+K^"
end

# ============================================================================
# DERIVED/NATIVE QUERY TESTS
# ============================================================================

puts
puts "Derived/Native queries:"

run_test("derived? returns true for derived") do
  pin = Sashite::Pin.parse("K")
  epin = Sashite::Epin::Identifier.new(pin, derived: true)
  raise "should be true" unless epin.derived?
end

run_test("derived? returns false for native") do
  pin = Sashite::Pin.parse("K")
  epin = Sashite::Epin::Identifier.new(pin, derived: false)
  raise "should be false" if epin.derived?
end

run_test("native? returns true for native") do
  pin = Sashite::Pin.parse("K")
  epin = Sashite::Epin::Identifier.new(pin, derived: false)
  raise "should be true" unless epin.native?
end

run_test("native? returns false for derived") do
  pin = Sashite::Pin.parse("K")
  epin = Sashite::Epin::Identifier.new(pin, derived: true)
  raise "should be false" if epin.native?
end

run_test("derived? and native? are mutually exclusive") do
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

run_test("derive returns derived identifier") do
  pin = Sashite::Pin.parse("K")
  epin = Sashite::Epin::Identifier.new(pin)
  result = epin.derive
  raise "should be derived" unless result.derived?
  raise "wrong string" unless result.to_s == "K'"
end

run_test("derive returns self if already derived") do
  pin = Sashite::Pin.parse("K")
  epin = Sashite::Epin::Identifier.new(pin, derived: true)
  result = epin.derive
  raise "should return same object" unless epin.equal?(result)
end

run_test("derive does not modify original") do
  pin = Sashite::Pin.parse("K")
  epin = Sashite::Epin::Identifier.new(pin)
  epin.derive
  raise "original should be unchanged" unless epin.native?
end

run_test("derive preserves PIN component") do
  pin = Sashite::Pin.parse("+K^")
  epin = Sashite::Epin::Identifier.new(pin)
  result = epin.derive
  raise "PIN should be preserved" unless result.pin == pin
end

# ============================================================================
# NATIVE TRANSFORMATION TESTS
# ============================================================================

puts
puts "Native transformation:"

run_test("native returns native identifier") do
  pin = Sashite::Pin.parse("K")
  epin = Sashite::Epin::Identifier.new(pin, derived: true)
  result = epin.native
  raise "should be native" unless result.native?
  raise "wrong string" unless result.to_s == "K"
end

run_test("native returns self if already native") do
  pin = Sashite::Pin.parse("K")
  epin = Sashite::Epin::Identifier.new(pin, derived: false)
  result = epin.native
  raise "should return same object" unless epin.equal?(result)
end

run_test("native does not modify original") do
  pin = Sashite::Pin.parse("K")
  epin = Sashite::Epin::Identifier.new(pin, derived: true)
  epin.native
  raise "original should be unchanged" unless epin.derived?
end

run_test("native preserves PIN component") do
  pin = Sashite::Pin.parse("+K^")
  epin = Sashite::Epin::Identifier.new(pin, derived: true)
  result = epin.native
  raise "PIN should be preserved" unless result.pin == pin
end

# ============================================================================
# WITH_PIN TRANSFORMATION TESTS
# ============================================================================

puts
puts "with_pin transformation:"

run_test("with_pin replaces PIN component") do
  pin1 = Sashite::Pin.parse("K")
  pin2 = Sashite::Pin.parse("Q")
  epin = Sashite::Epin::Identifier.new(pin1)
  result = epin.with_pin(pin2)
  raise "wrong PIN" unless result.pin == pin2
  raise "wrong string" unless result.to_s == "Q"
end

run_test("with_pin preserves derived status") do
  pin1 = Sashite::Pin.parse("K")
  pin2 = Sashite::Pin.parse("Q")
  epin = Sashite::Epin::Identifier.new(pin1, derived: true)
  result = epin.with_pin(pin2)
  raise "should be derived" unless result.derived?
  raise "wrong string" unless result.to_s == "Q'"
end

run_test("with_pin returns self if same PIN") do
  pin = Sashite::Pin.parse("K")
  epin = Sashite::Epin::Identifier.new(pin)
  result = epin.with_pin(pin)
  raise "should return same object" unless epin.equal?(result)
end

run_test("with_pin does not modify original") do
  pin1 = Sashite::Pin.parse("K")
  pin2 = Sashite::Pin.parse("Q")
  epin = Sashite::Epin::Identifier.new(pin1)
  epin.with_pin(pin2)
  raise "original should be unchanged" unless epin.pin == pin1
end

run_test("with_pin raises on invalid PIN") do
  pin = Sashite::Pin.parse("K")
  epin = Sashite::Epin::Identifier.new(pin)
  epin.with_pin("Q")
  raise "should have raised"
rescue Sashite::Epin::Errors::Argument => e
  raise "wrong message" unless e.message == Sashite::Epin::Errors::Argument::Messages::INVALID_PIN
end

# ============================================================================
# COMPARISON QUERY TESTS
# ============================================================================

puts
puts "Comparison queries:"

run_test("same_derived? returns true for same derived status") do
  pin1 = Sashite::Pin.parse("K")
  pin2 = Sashite::Pin.parse("Q")
  epin1 = Sashite::Epin::Identifier.new(pin1, derived: true)
  epin2 = Sashite::Epin::Identifier.new(pin2, derived: true)
  raise "should be true" unless epin1.same_derived?(epin2)
end

run_test("same_derived? returns true for both native") do
  pin1 = Sashite::Pin.parse("K")
  pin2 = Sashite::Pin.parse("Q")
  epin1 = Sashite::Epin::Identifier.new(pin1, derived: false)
  epin2 = Sashite::Epin::Identifier.new(pin2, derived: false)
  raise "should be true" unless epin1.same_derived?(epin2)
end

run_test("same_derived? returns false for different derived status") do
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

run_test("identifiers with same attributes are equal") do
  pin = Sashite::Pin.parse("K")
  epin1 = Sashite::Epin::Identifier.new(pin, derived: true)
  epin2 = Sashite::Epin::Identifier.new(pin, derived: true)
  raise "should be equal" unless epin1 == epin2
end

run_test("identifiers with different PIN are not equal") do
  pin1 = Sashite::Pin.parse("K")
  pin2 = Sashite::Pin.parse("Q")
  epin1 = Sashite::Epin::Identifier.new(pin1, derived: true)
  epin2 = Sashite::Epin::Identifier.new(pin2, derived: true)
  raise "should not be equal" if epin1 == epin2
end

run_test("identifiers with different derived status are not equal") do
  pin = Sashite::Pin.parse("K")
  epin1 = Sashite::Epin::Identifier.new(pin, derived: true)
  epin2 = Sashite::Epin::Identifier.new(pin, derived: false)
  raise "should not be equal" if epin1 == epin2
end

run_test("eql? is aliased to ==") do
  pin = Sashite::Pin.parse("K")
  epin1 = Sashite::Epin::Identifier.new(pin, derived: true)
  epin2 = Sashite::Epin::Identifier.new(pin, derived: true)
  raise "eql? should work" unless epin1.eql?(epin2)
end

run_test("equal identifiers have same hash") do
  pin = Sashite::Pin.parse("K")
  epin1 = Sashite::Epin::Identifier.new(pin, derived: true)
  epin2 = Sashite::Epin::Identifier.new(pin, derived: true)
  raise "hash should match" unless epin1.hash == epin2.hash
end

run_test("different identifiers may have different hash") do
  pin1 = Sashite::Pin.parse("K")
  pin2 = Sashite::Pin.parse("Q")
  epin1 = Sashite::Epin::Identifier.new(pin1, derived: true)
  epin2 = Sashite::Epin::Identifier.new(pin2, derived: true)
  # Note: hash collision is possible but unlikely for different inputs
  # This test just verifies hash is computed
  epin1.hash
  epin2.hash
end

# ============================================================================
# INSPECT TESTS
# ============================================================================

puts
puts "Inspect:"

run_test("inspect returns readable representation") do
  pin = Sashite::Pin.parse("K^")
  epin = Sashite::Epin::Identifier.new(pin, derived: true)
  result = epin.inspect
  raise "wrong format" unless result == "#<Sashite::Epin::Identifier K^'>"
end

run_test("inspect for native identifier") do
  pin = Sashite::Pin.parse("+R")
  epin = Sashite::Epin::Identifier.new(pin)
  result = epin.inspect
  raise "wrong format" unless result == "#<Sashite::Epin::Identifier +R>"
end

puts
puts "All Identifier tests passed!"
puts
