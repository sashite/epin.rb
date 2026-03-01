# frozen_string_literal: true

require "sashite/pin"

require_relative "epin/constants"
require_relative "epin/errors"
require_relative "epin/identifier"
require_relative "epin/parser"

module Sashite
  # EPIN (Extended Piece Identifier Notation) implementation for Ruby.
  #
  # EPIN extends PIN with an optional derivation marker (') that flags
  # whether a piece uses a native or derived style.
  #
  # All 624 possible identifiers (312 PIN tokens × 2 derivation statuses)
  # are pre-instantiated and frozen at load time. Every public method
  # returns a cached instance — zero allocation on the hot path.
  #
  # == Format
  #
  #   <pin>[']
  #
  # - *PIN*: Any valid PIN token (abbr, side, state, terminal)
  # - *Derivation marker*: <tt>'</tt> (derived) or absent (native)
  #
  # == Examples
  #
  #   epin = Sashite::Epin.parse("K^'")
  #   epin.pin.abbr      # => :K
  #   epin.pin.side      # => :first
  #   epin.pin.terminal? # => true
  #   epin.derived?      # => true
  #
  #   epin = Sashite::Epin.parse("+R")
  #   epin.to_s  # => "+R"
  #
  #   Sashite::Epin.valid?("K^'")     # => true
  #   Sashite::Epin.valid?("invalid") # => false
  #
  # @see https://sashite.dev/specs/epin/1.0.0/
  module Epin
    # Parses an EPIN string into a cached Identifier.
    # Returns a pre-instantiated, frozen instance.
    # Raises ArgumentError if the string is not valid.
    #
    # @param string [String] The EPIN string to parse
    # @return [Identifier] A cached Identifier instance
    # @raise [Errors::Argument] If the string is not a valid EPIN
    #
    # @example
    #   Sashite::Epin.parse("K")
    #   # => #<Sashite::Epin::Identifier K>
    #
    #   Sashite::Epin.parse("K^'")
    #   # => #<Sashite::Epin::Identifier K^'>
    #
    #   Sashite::Epin.parse("invalid")
    #   # => raises Errors::Argument
    def self.parse(string)
      Parser.parse(string)
    end

    # Parses an EPIN string without raising.
    # Returns a cached Identifier on success, nil on failure.
    # Never allocates exception objects or captures backtraces.
    # Delegates to Pin.safe_parse for the PIN component.
    #
    # @param string [String] The EPIN string to parse
    # @return [Identifier, nil] A cached Identifier or nil
    #
    # @example
    #   Sashite::Epin.safe_parse("K^'")    # => #<Sashite::Epin::Identifier K^'>
    #   Sashite::Epin.safe_parse("+R")     # => #<Sashite::Epin::Identifier +R>
    #   Sashite::Epin.safe_parse("")       # => nil
    #   Sashite::Epin.safe_parse("K''")    # => nil
    #   Sashite::Epin.safe_parse(nil)      # => nil
    def self.safe_parse(string)
      Parser.safe_parse(string)
    end

    # Retrieves a cached Identifier by PIN component and derivation status.
    # Bypasses string parsing entirely — direct hash lookup.
    # Raises ArgumentError if the PIN is invalid.
    #
    # @param pin [Sashite::Pin::Identifier] PIN component
    # @param derived [Boolean] Derived status (default: false)
    # @return [Identifier] A cached Identifier
    # @raise [Errors::Argument] If the PIN is not a Sashite::Pin::Identifier
    #
    # @example
    #   pin = Sashite::Pin.parse("K^")
    #   Sashite::Epin.fetch(pin)                  # => #<Sashite::Epin::Identifier K^>
    #   Sashite::Epin.fetch(pin, derived: true)   # => #<Sashite::Epin::Identifier K^'>
    def self.fetch(pin, derived: false)
      raise Errors::Argument, Errors::Argument::Messages::INVALID_PIN unless ::Sashite::Pin::Identifier === pin
      raise Errors::Argument, Errors::Argument::Messages::INVALID_DERIVED unless true == derived || false == derived

      Identifier.fetch(pin, derived)
    end

    # Reports whether string is a valid EPIN.
    # Never raises; returns false for any invalid input.
    # Uses an exception-free code path internally for performance.
    #
    # @param string [String] The EPIN string to validate
    # @return [Boolean] true if valid, false otherwise
    #
    # @example
    #   Sashite::Epin.valid?("K")        # => true
    #   Sashite::Epin.valid?("K^'")      # => true
    #   Sashite::Epin.valid?("invalid")  # => false
    #   Sashite::Epin.valid?(nil)        # => false
    def self.valid?(string)
      Parser.valid?(string)
    end
  end
end
