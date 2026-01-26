#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "../../lib/sashite/epin"

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
puts "=== Epin Module Tests ==="
puts

# ============================================================================
# PARSE METHOD
# ============================================================================

puts "parse method:"

run_test("parses native EPIN") do
  epin = Sashite::Epin.parse("K")
  raise "wrong class" unless Sashite::Epin::Identifier === epin
  raise "wrong abbr" unless epin.pin.abbr == :K
  raise "should be native" unless epin.native?
end

run_test("parses derived EPIN") do
  epin = Sashite::Epin.parse("K'")
  raise "wrong class" unless Sashite::Epin::Identifier === epin
  raise "wrong abbr" unless epin.pin.abbr == :K
  raise "should be derived" unless epin.derived?
end

run_test("parses EPIN with all modifiers") do
  epin = Sashite::Epin.parse("+K^'")
  raise "wrong abbr" unless epin.pin.abbr == :K
  raise "wrong side" unless epin.pin.side == :first
  raise "wrong state" unless epin.pin.state == :enhanced
  raise "should be terminal" unless epin.pin.terminal?
  raise "should be derived" unless epin.derived?
end

run_test("parses lowercase EPIN") do
  epin = Sashite::Epin.parse("-p^'")
  raise "wrong abbr" unless epin.pin.abbr == :P
  raise "wrong side" unless epin.pin.side == :second
  raise "wrong state" unless epin.pin.state == :diminished
  raise "should be terminal" unless epin.pin.terminal?
  raise "should be derived" unless epin.derived?
end

run_test("raises on invalid input") do
  Sashite::Epin.parse("invalid")
  raise "should have raised"
rescue Sashite::Epin::Errors::Argument
  # Expected
end

run_test("raises on empty string") do
  Sashite::Epin.parse("")
  raise "should have raised"
rescue Sashite::Epin::Errors::Argument
  # Expected
end

run_test("raises on invalid derivation marker") do
  Sashite::Epin.parse("K''")
  raise "should have raised"
rescue Sashite::Epin::Errors::Argument
  # Expected
end

# ============================================================================
# VALID? METHOD
# ============================================================================

puts
puts "valid? method:"

run_test("returns true for valid native EPIN") do
  raise "should be valid" unless Sashite::Epin.valid?("K")
  raise "should be valid" unless Sashite::Epin.valid?("+R")
  raise "should be valid" unless Sashite::Epin.valid?("K^")
  raise "should be valid" unless Sashite::Epin.valid?("+K^")
end

run_test("returns true for valid derived EPIN") do
  raise "should be valid" unless Sashite::Epin.valid?("K'")
  raise "should be valid" unless Sashite::Epin.valid?("+R'")
  raise "should be valid" unless Sashite::Epin.valid?("K^'")
  raise "should be valid" unless Sashite::Epin.valid?("+K^'")
end

run_test("returns false for empty string") do
  raise "should be invalid" if Sashite::Epin.valid?("")
end

run_test("returns false for invalid EPIN") do
  raise "should be invalid" if Sashite::Epin.valid?("invalid")
  raise "should be invalid" if Sashite::Epin.valid?("K''")
  raise "should be invalid" if Sashite::Epin.valid?("K'^")
  raise "should be invalid" if Sashite::Epin.valid?("'K")
end

run_test("returns false for nil") do
  raise "should be invalid" if Sashite::Epin.valid?(nil)
end

run_test("returns false for non-string") do
  raise "should be invalid" if Sashite::Epin.valid?(123)
  raise "should be invalid" if Sashite::Epin.valid?(:K)
  raise "should be invalid" if Sashite::Epin.valid?([:K])
end

# ============================================================================
# ROUND-TRIP TESTS
# ============================================================================

puts
puts "Round-trip tests:"

run_test("round-trip native EPIN strings") do
  %w[K k +R -p K^ +K^ -k^].each do |epin_string|
    epin = Sashite::Epin.parse(epin_string)
    raise "round-trip failed for #{epin_string}" unless epin.to_s == epin_string
  end
end

run_test("round-trip derived EPIN strings") do
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

run_test("every valid PIN is a valid EPIN") do
  %w[K +R -p K^ +R^ -p^].each do |pin_string|
    raise "#{pin_string} should be valid EPIN" unless Sashite::Epin.valid?(pin_string)
    epin = Sashite::Epin.parse(pin_string)
    raise "should be native" unless epin.native?
    raise "round-trip failed" unless epin.to_s == pin_string
  end
end

# ============================================================================
# INTEGRATION WITH IDENTIFIER
# ============================================================================

puts
puts "Integration with Identifier:"

run_test("parsed identifier supports transformations") do
  epin = Sashite::Epin.parse("K^")
  derived = epin.derive
  raise "should be derived" unless derived.derived?
  raise "wrong string" unless derived.to_s == "K^'"
end

run_test("parsed identifier supports PIN access") do
  epin = Sashite::Epin.parse("+R^'")
  raise "wrong abbr" unless epin.pin.abbr == :R
  raise "wrong state" unless epin.pin.state == :enhanced
  raise "should be terminal" unless epin.pin.terminal?
  raise "should be first player" unless epin.pin.first_player?
end

run_test("parsed identifier supports with_pin") do
  epin = Sashite::Epin.parse("K'")
  new_pin = Sashite::Pin.parse("+Q^")
  result = epin.with_pin(new_pin)
  raise "wrong string" unless result.to_s == "+Q^'"
  raise "should be derived" unless result.derived?
end

puts
puts "All Epin module tests passed!"
puts
