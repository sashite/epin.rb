# frozen_string_literal: true

require_relative "epin/identifier"

module Sashite
  # EPIN (Extended Piece Identifier Notation) implementation for Ruby
  #
  # Provides style-aware ASCII-based format for representing pieces in abstract strategy board games.
  # EPIN extends PIN by adding derivation markers that distinguish pieces by their style origin,
  # enabling cross-style game scenarios and piece origin tracking.
  #
  # Format: [<state>]<letter>[<terminal>][<derivation>]
  # - State modifier: "+" (enhanced), "-" (diminished), or none (normal)
  # - Letter: A-Z (first player), a-z (second player)
  # - Terminal marker: "^" (terminal piece)
  # - Derivation marker: "'" (foreign style), or none (native style)
  #
  # Examples:
  #   "K"    - First player king (native style, normal state, non-terminal)
  #   "K^"   - First player king (native style, normal state, terminal)
  #   "k'"   - Second player king (foreign style, normal state, non-terminal)
  #   "k^'"  - Second player king (foreign style, normal state, terminal)
  #   "+R'"  - First player rook (foreign style, enhanced state, non-terminal)
  #   "+K^'" - First player king (foreign style, enhanced state, terminal)
  #   "-p"   - Second player pawn (native style, diminished state, non-terminal)
  #
  # @see https://sashite.dev/specs/epin/1.0.0/
  module Epin
    # Check if a string is a valid EPIN notation
    #
    # @param epin_string [String] The string to validate
    # @return [Boolean] true if valid EPIN, false otherwise
    #
    # @example
    #   Sashite::Epin.valid?("K")      # => true
    #   Sashite::Epin.valid?("K^")     # => true
    #   Sashite::Epin.valid?("+R'")    # => true
    #   Sashite::Epin.valid?("+K^'")   # => true
    #   Sashite::Epin.valid?("-p")     # => true
    #   Sashite::Epin.valid?("KK")     # => false
    #   Sashite::Epin.valid?("++K")    # => false
    #   Sashite::Epin.valid?("K'^")    # => false (wrong order)
    def self.valid?(epin_string)
      Identifier.valid?(epin_string)
    end

    # Parse an EPIN string into an Identifier object
    #
    # @param epin_string [String] EPIN notation string
    # @return [Epin::Identifier] new identifier instance
    # @raise [ArgumentError] if the EPIN string is invalid
    #
    # @example
    #   Sashite::Epin.parse("K")       # => #<Epin::Identifier type=:K side=:first state=:normal native=true terminal=false>
    #   Sashite::Epin.parse("K^")      # => #<Epin::Identifier type=:K side=:first state=:normal native=true terminal=true>
    #   Sashite::Epin.parse("+R'")     # => #<Epin::Identifier type=:R side=:first state=:enhanced native=false terminal=false>
    #   Sashite::Epin.parse("+K^'")    # => #<Epin::Identifier type=:K side=:first state=:enhanced native=false terminal=true>
    #   Sashite::Epin.parse("-p")      # => #<Epin::Identifier type=:P side=:second state=:diminished native=true terminal=false>
    def self.parse(epin_string)
      Identifier.parse(epin_string)
    end

    # Create a new identifier instance
    #
    # @param type [Symbol] piece type (:A to :Z)
    # @param side [Symbol] player side (:first or :second)
    # @param state [Symbol] piece state (:normal, :enhanced, or :diminished)
    # @param native [Boolean] style derivation (true for native, false for foreign)
    # @param terminal [Boolean] whether the piece is a terminal piece
    # @return [Epin::Identifier] new identifier instance
    # @raise [ArgumentError] if parameters are invalid
    #
    # @example
    #   Sashite::Epin.identifier(:K, :first, :normal, true)                     # => "K"
    #   Sashite::Epin.identifier(:K, :first, :normal, true, terminal: true)     # => "K^"
    #   Sashite::Epin.identifier(:R, :first, :enhanced, false)                  # => "+R'"
    #   Sashite::Epin.identifier(:K, :first, :enhanced, false, terminal: true)  # => "+K^'"
    #   Sashite::Epin.identifier(:P, :second, :diminished, true)                # => "-p"
    def self.identifier(type, side, state, native, terminal: false)
      Identifier.new(type, side, state, native, terminal: terminal)
    end
  end
end
