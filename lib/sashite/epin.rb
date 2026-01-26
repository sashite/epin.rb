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
    # Parses an EPIN string into an Identifier.
    #
    # @param string [String] The EPIN string to parse
    # @return [Identifier] A new Identifier instance
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
      components = Parser.parse(string)

      pin = ::Sashite::Pin::Identifier.new(
        components[:pin][:abbr],
        components[:pin][:side],
        components[:pin][:state],
        terminal: components[:pin][:terminal]
      )

      Identifier.new(pin, derived: components[:derived])
    end

    # Checks if a string is a valid EPIN notation.
    #
    # @param string [String] The string to validate
    # @return [Boolean] true if valid, false otherwise
    #
    # @example
    #   Sashite::Epin.valid?("K")        # => true
    #   Sashite::Epin.valid?("K^'")      # => true
    #   Sashite::Epin.valid?("invalid")  # => false
    def self.valid?(string)
      Parser.valid?(string)
    end
  end
end
