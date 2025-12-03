# frozen_string_literal: true

require_relative "epin/identifier"

module Sashite
  # EPIN (Extended Piece Identifier Notation) implementation for Ruby
  #
  # Extends PIN (Piece Identifier Notation) with a derivation marker to track piece style
  # in cross-style games. EPIN is simply: PIN + optional style derivation marker (').
  #
  # ## Core Concept
  #
  # EPIN addresses the need to distinguish between:
  # - **Native pieces**: Using their own side's native style (no marker)
  # - **Derived pieces**: Using the opponent's native style (marked with ')
  #
  # This distinction is essential for cross-style games where different players use
  # different game traditions (e.g., Chess vs Makruk, Chess vs Shogi).
  #
  # ## Pure Composition
  #
  # EPIN doesn't reimplement PIN - it's pure composition:
  #
  #   EPIN = PIN + derived flag
  #
  # All piece attributes (name, side, state, terminal) come from the PIN component.
  # EPIN adds only the 5th attribute: piece style (native vs derived).
  #
  # ## Minimal API
  #
  # Module-level methods (3 total):
  # 1. valid?(epin_string) - validate EPIN string
  # 2. parse(epin_string) - parse into Identifier
  # 3. new(pin, derived: false) - create from PIN component
  #
  # ## Five Fundamental Attributes
  #
  # EPIN represents all five piece attributes from the Sashité Game Protocol:
  #
  # From PIN component (4 attributes):
  # - **Piece Name**: epin.pin.type
  # - **Piece Side**: epin.pin.side
  # - **Piece State**: epin.pin.state
  # - **Terminal Status**: epin.pin.terminal?
  #
  # From EPIN (5th attribute):
  # - **Piece Style**: epin.derived? (native vs derived)
  #
  # ## Format Structure
  #
  # Structure: `<pin>[']`
  #
  # Grammar (BNF):
  #   <epin> ::= <pin> | <pin> "'"
  #   <pin> ::= ["+" | "-"] <letter> ["^"]
  #   <letter> ::= "A" | ... | "Z" | "a" | ... | "z"
  #
  # Regular Expression: `/\A[-+]?[A-Za-z]\^?'?\z/`
  #
  # ## Semantics
  #
  # ### Native vs Derived
  #
  # In cross-style games (e.g., Chess vs Makruk):
  # - First player's native style: Chess
  # - Second player's native style: Makruk
  #
  # Then:
  # - "K" = First player king in Chess style (native)
  # - "K'" = First player king in Makruk style (derived from opponent)
  # - "k" = Second player king in Makruk style (native)
  # - "k'" = Second player king in Chess style (derived from opponent)
  #
  # ### Backward Compatibility
  #
  # Every valid PIN token is a valid EPIN token:
  # - "K" is valid PIN and valid EPIN (native)
  # - "+R^" is valid PIN and valid EPIN (native)
  # - All PIN semantics preserved
  #
  # EPIN extends PIN by adding the optional derivation marker:
  # - "K'" is valid EPIN (derived)
  # - "+R^'" is valid EPIN (enhanced, terminal, derived)
  #
  # ## Examples
  #
  # ### Basic Usage
  #
  #   # Parse EPIN strings
  #   native = Sashite::Epin.parse("K^")      # Native king
  #   derived = Sashite::Epin.parse("K^'")    # Derived king
  #
  #   # Access attributes via PIN component
  #   native.pin.type       # => :K
  #   native.pin.terminal?  # => true
  #   native.derived?       # => false
  #
  #   # Create from PIN component
  #   pin = Sashite::Pin.parse("K^")
  #   epin = Sashite::Epin.new(pin, derived: false)
  #   epin.to_s             # => "K^"
  #
  # ### Transformations
  #
  #   epin = Sashite::Epin.parse("K^")
  #
  #   # Mark as derived
  #   derived = epin.mark_derived
  #   derived.to_s          # => "K^'"
  #
  #   # Transform PIN component
  #   queen = epin.with_pin(epin.pin.with_type(:Q))
  #   queen.to_s            # => "Q^"
  #
  #   # Transform both
  #   derived_queen = epin
  #     .with_pin(epin.pin.with_type(:Q))
  #     .mark_derived
  #   derived_queen.to_s    # => "Q^'"
  #
  # ### Cross-Style Games
  #
  #   # Chess vs Makruk match
  #   # First player = Chess, Second player = Makruk
  #
  #   chess_king = Sashite::Epin.parse("K^")     # Native Chess king
  #   makruk_pawn = Sashite::Epin.parse("P'")    # Derived Makruk pawn
  #
  #   chess_king.native?       # => true (uses Chess style)
  #   makruk_pawn.derived?     # => true (uses Makruk style)
  #
  # ## Design Properties
  #
  # - **Rule-agnostic**: Independent of game mechanics
  # - **Pure composition**: Extends PIN minimally (PIN + derived flag)
  # - **Minimal API**: Only 3 module methods, 6 instance methods
  # - **Component transparency**: Direct PIN access via epin.pin
  # - **Backward compatible**: All PIN tokens are valid EPIN tokens
  # - **Immutable**: All instances frozen, transformations return new objects
  # - **Type-safe**: Full PIN type preservation
  # - **Style-aware**: Tracks native vs derived pieces
  # - **Compact**: Single character overhead for style information
  #
  # @see https://sashite.dev/specs/epin/1.0.0/ EPIN Specification v1.0.0
  # @see https://sashite.dev/specs/epin/1.0.0/examples/ EPIN Examples
  # @see https://sashite.dev/specs/pin/1.0.0/ PIN Specification (base component)
  module Epin
    # Check if a string is a valid EPIN notation
    #
    # Validates both the EPIN format and the underlying PIN component.
    #
    # @param epin_string [String] the string to validate
    # @return [Boolean] true if valid EPIN, false otherwise
    #
    # @example Validate EPIN strings
    #   Sashite::Epin.valid?("K^")     # => true (valid PIN, native)
    #   Sashite::Epin.valid?("K^'")    # => true (valid PIN with derivation)
    #   Sashite::Epin.valid?("+R'")    # => true (enhanced derived rook)
    #   Sashite::Epin.valid?("K^''")   # => false (multiple markers)
    #   Sashite::Epin.valid?("KK'")    # => false (invalid PIN part)
    #   Sashite::Epin.valid?("invalid") # => false (invalid format)
    def self.valid?(epin_string)
      Identifier.valid?(epin_string)
    end

    # Parse an EPIN string into an Identifier object
    #
    # Creates a new EPIN identifier by parsing the string, extracting the PIN part
    # and derivation marker, validating the PIN component, and creating an identifier
    # with the appropriate derivation status.
    #
    # @param epin_string [String] EPIN notation string (format: <pin>['])
    # @return [Epin::Identifier] parsed identifier with PIN component and derivation flag
    # @raise [ArgumentError] if the EPIN string is invalid
    #
    # @example Parse different EPIN formats
    #   Sashite::Epin.parse("K^")   # => Native king, terminal
    #   Sashite::Epin.parse("K^'")  # => Derived king, terminal
    #   Sashite::Epin.parse("+R")   # => Native rook, enhanced
    #   Sashite::Epin.parse("+R'")  # => Derived rook, enhanced
    #   Sashite::Epin.parse("-p")   # => Native pawn, diminished
    #
    # @example Access all five attributes
    #   epin = Sashite::Epin.parse("+R^'")
    #   epin.pin.type       # => :R (Piece Name)
    #   epin.pin.side       # => :first (Piece Side)
    #   epin.pin.state      # => :enhanced (Piece State)
    #   epin.pin.terminal?  # => true (Terminal Status)
    #   epin.derived?       # => true (Piece Style)
    def self.parse(epin_string)
      Identifier.parse(epin_string)
    end

    # Create a new identifier from a PIN component and derivation flag
    #
    # Constructs an EPIN identifier by combining a PIN component (which provides
    # the four base attributes: name, side, state, terminal) with a derivation flag
    # (which provides the fifth attribute: style).
    #
    # @param pin [Pin::Identifier] PIN component providing base attributes
    # @param derived [Boolean] whether the piece uses derived style (default: false)
    # @return [Epin::Identifier] new immutable identifier instance
    # @raise [ArgumentError] if pin is not a Pin::Identifier
    #
    # @example Create identifiers from PIN components
    #   pin = Sashite::Pin.parse("K^")
    #   native = Sashite::Epin.new(pin, derived: false)
    #   native.to_s         # => "K^"
    #
    #   derived = Sashite::Epin.new(pin, derived: true)
    #   derived.to_s        # => "K^'"
    #
    # @example Cross-style game setup
    #   # First player uses Chess style, second uses Makruk style
    #   chess_king = Sashite::Epin.new(Sashite::Pin.parse("K^"), derived: false)
    #   makruk_pawn = Sashite::Epin.new(Sashite::Pin.parse("P"), derived: true)
    #
    #   chess_king.native?    # => true (uses own Chess style)
    #   makruk_pawn.derived?  # => true (uses opponent's Makruk style)
    def self.new(pin, derived: false)
      Identifier.new(pin, derived: derived)
    end
  end
end
