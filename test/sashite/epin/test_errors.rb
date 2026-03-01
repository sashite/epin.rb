#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "../../helper"
require_relative "../../../lib/sashite/epin/errors"

puts
puts "=== Errors Tests ==="
puts

# ============================================================================
# PARSING ERROR MESSAGES
# ============================================================================

puts "Parsing error messages:"

Test("INVALID_DERIVATION_MARKER is defined") do
  raise "wrong value" unless Sashite::Epin::Errors::Argument::Messages::INVALID_DERIVATION_MARKER == "invalid derivation marker"
end

# ============================================================================
# VALIDATION ERROR MESSAGES
# ============================================================================

puts
puts "Validation error messages:"

Test("INVALID_PIN is defined") do
  raise "wrong value" unless Sashite::Epin::Errors::Argument::Messages::INVALID_PIN == "pin must be a Sashite::Pin::Identifier"
end

Test("INVALID_DERIVED is defined") do
  raise "wrong value" unless Sashite::Epin::Errors::Argument::Messages::INVALID_DERIVED == "derived must be true or false"
end

# ============================================================================
# ERROR CLASS
# ============================================================================

puts
puts "Error class:"

Test("Argument inherits from ArgumentError") do
  raise "wrong inheritance" unless Sashite::Epin::Errors::Argument < ArgumentError
end

Test("Argument can be raised with message") do
  raise Sashite::Epin::Errors::Argument, Sashite::Epin::Errors::Argument::Messages::INVALID_DERIVATION_MARKER
rescue Sashite::Epin::Errors::Argument => e
  raise "wrong message" unless e.message == "invalid derivation marker"
end

Test("Argument can be rescued as ArgumentError") do
  raise Sashite::Epin::Errors::Argument, "test"
rescue ArgumentError => e
  raise "should be rescuable as ArgumentError" unless e.message == "test"
end

# ============================================================================
# ERROR MESSAGES ARE FROZEN
# ============================================================================

puts
puts "Immutability:"

Test("INVALID_DERIVATION_MARKER is frozen") do
  raise "should be frozen" unless Sashite::Epin::Errors::Argument::Messages::INVALID_DERIVATION_MARKER.frozen?
end

Test("INVALID_PIN is frozen") do
  raise "should be frozen" unless Sashite::Epin::Errors::Argument::Messages::INVALID_PIN.frozen?
end

Test("INVALID_DERIVED is frozen") do
  raise "should be frozen" unless Sashite::Epin::Errors::Argument::Messages::INVALID_DERIVED.frozen?
end

puts
puts "All Errors tests passed!"
puts
