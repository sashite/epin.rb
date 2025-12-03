# frozen_string_literal: true

require "sashite/pin"

module Sashite
  module Epin
    # Represents an identifier in EPIN (Extended Piece Identifier Notation) format.
    #
    # EPIN extends PIN by adding a derivation marker to encode Piece Style relative to Piece Side.
    #
    # Format: [<state>]<letter>[<terminal>][<derivation>]
    # - State modifier: "+" (enhanced), "-" (diminished), or none (normal)
    # - Letter: A-Z (first player), a-z (second player)
    # - Terminal marker: "^" (terminal piece)
    # - Derivation marker: "'" (foreign/derived style) or none (native style)
    #
    # Style Derivation Logic:
    # - No apostrophe suffix: piece has the native style of its current side
    # - Apostrophe suffix: piece has the foreign style (opposite side's native style)
    #
    # All instances are immutable - transformations return new instances.
    # This extends the Game Protocol's piece model with Style support through derivation.
    #
    # @see https://sashite.dev/specs/epin/1.0.0/
    class Identifier
      # EPIN validation pattern matching the specification: /\A[-+]?[A-Za-z]\^?'?\z/
      EPIN_PATTERN = /\A[-+]?[A-Za-z]\^?'?\z/

      # Derivation marker for foreign/derived style
      DERIVATION_MARKER = "'"

      # No derivation marker (native style)
      NATIVE_MARKER = ""

      # Style constants
      NATIVE = true
      FOREIGN = false

      # Valid derivation values
      VALID_DERIVATIONS = [NATIVE, FOREIGN].freeze

      # Error messages
      ERROR_INVALID_EPIN = "Invalid EPIN string: %s"
      ERROR_INVALID_DERIVATION = "Derivation must be true (native) or false (foreign), got: %s"

      # @return [Symbol] the piece type (:A to :Z, always uppercase)
      def type
        @pin_identifier.type
      end

      # @return [Symbol] the player side (:first or :second)
      def side
        @pin_identifier.side
      end

      # @return [Symbol] the piece state (:normal, :enhanced, or :diminished)
      def state
        @pin_identifier.state
      end

      # @return [Boolean] whether the piece is a terminal piece
      def terminal
        @pin_identifier.terminal
      end

      # @return [Boolean] the style derivation (true for native, false for foreign)
      attr_reader :native

      # Create a new EPIN identifier instance
      #
      # @param type [Symbol] piece type (:A to :Z)
      # @param side [Symbol] player side (:first or :second)
      # @param state [Symbol] piece state (:normal, :enhanced, or :diminished)
      # @param native [Boolean] style derivation (true for native, false for foreign)
      # @param terminal [Boolean] whether the piece is a terminal piece
      # @raise [ArgumentError] if parameters are invalid
      #
      # @example
      #   Identifier.new(:K, :first, :normal, true)           # => "K"
      #   Identifier.new(:K, :first, :normal, true, terminal: true)  # => "K^"
      #   Identifier.new(:K, :first, :normal, false, terminal: true) # => "K^'"
      #   Identifier.new(:P, :second, :enhanced, false)       # => "+p'"
      def initialize(type, side, state = Pin::Identifier::NORMAL_STATE, native = NATIVE, terminal: false)
        # Validate using PIN class methods for type, side, and state
        Pin::Identifier.validate_type(type)
        Pin::Identifier.validate_side(side)
        Pin::Identifier.validate_state(state)
        self.class.validate_derivation(native)

        @pin_identifier = Pin::Identifier.new(type, side, state, terminal: terminal)
        @native = native

        freeze
      end

      # Parse an EPIN string into an Identifier object
      #
      # EPIN format: [<state>]<letter>[<terminal>][<derivation>]
      # where terminal marker (^) comes BEFORE derivation marker (')
      #
      # @param epin_string [String] EPIN notation string
      # @return [Identifier] new identifier instance
      # @raise [ArgumentError] if the EPIN string is invalid
      #
      # @example
      #   Epin::Identifier.parse("k")       # => native second player king
      #   Epin::Identifier.parse("K^")      # => native terminal first player king
      #   Epin::Identifier.parse("+R'")     # => foreign enhanced first player rook
      #   Epin::Identifier.parse("+K^'")    # => foreign enhanced terminal first player king
      #   Epin::Identifier.parse("-p")      # => native diminished second player pawn
      def self.parse(epin_string)
        string_value = String(epin_string)

        # Validate EPIN pattern first
        raise ::ArgumentError, format(ERROR_INVALID_EPIN, string_value) unless string_value.match?(EPIN_PATTERN)

        # Check for derivation marker (must be at the end)
        if string_value.end_with?(DERIVATION_MARKER)
          pin_part = string_value[0...-1] # Remove the apostrophe
          derived = true
        else
          pin_part = string_value
          derived = false
        end

        # Validate and parse the PIN part using existing PIN logic
        raise ::ArgumentError, format(ERROR_INVALID_EPIN, string_value) unless Pin::Identifier.valid?(pin_part)

        pin_identifier = Pin::Identifier.parse(pin_part)
        identifier_native = !derived

        new(pin_identifier.type, pin_identifier.side, pin_identifier.state, identifier_native, terminal: pin_identifier.terminal)
      end

      # Check if a string is a valid EPIN notation
      #
      # Valid EPIN format: [<state>]<letter>[<terminal>][<derivation>]
      # - State: + or - (optional)
      # - Letter: A-Z or a-z (required)
      # - Terminal: ^ (optional)
      # - Derivation: ' (optional)
      #
      # @param epin_string [String] The string to validate
      # @return [Boolean] true if valid EPIN, false otherwise
      #
      # @example
      #   Sashite::Epin::Identifier.valid?("K")      # => true
      #   Sashite::Epin::Identifier.valid?("K^")     # => true
      #   Sashite::Epin::Identifier.valid?("+R'")    # => true
      #   Sashite::Epin::Identifier.valid?("+K^'")   # => true
      #   Sashite::Epin::Identifier.valid?("KK")     # => false
      #   Sashite::Epin::Identifier.valid?("++K")    # => false
      #   Sashite::Epin::Identifier.valid?("K'^")    # => false (wrong order)
      def self.valid?(epin_string)
        return false unless epin_string.is_a?(::String)
        return false if epin_string.empty?

        # Check EPIN pattern
        return false unless epin_string.match?(EPIN_PATTERN)

        # Extract PIN part (remove derivation marker if present)
        pin_part = epin_string.end_with?(DERIVATION_MARKER) ? epin_string[0...-1] : epin_string
        return false if pin_part.empty? # Can't have just an apostrophe

        # Validate the PIN part using existing PIN validation
        Pin::Identifier.valid?(pin_part)
      end

      # Convert the identifier to its EPIN string representation
      #
      # Format: [<state>]<letter>[<terminal>][<derivation>]
      #
      # @return [String] EPIN notation string
      #
      # @example
      #   identifier.to_s  # => "+R'"
      #   identifier.to_s  # => "K^"
      #   identifier.to_s  # => "+K^'"
      #   identifier.to_s  # => "-p"
      def to_s
        "#{prefix}#{letter}#{terminal_marker}#{derivation_marker}"
      end

      # Get the letter representation (inherited from PIN logic)
      #
      # @return [String] letter representation combining type and side
      def letter
        @pin_identifier.letter
      end

      # Get the state prefix (inherited from PIN logic)
      #
      # @return [String] prefix representing the state ("+" / "-" / "")
      def prefix
        @pin_identifier.prefix
      end

      # Get the terminal marker (inherited from PIN logic)
      #
      # @return [String] terminal marker ("^" or "")
      def terminal_marker
        @pin_identifier.suffix
      end

      # Get the derivation marker (EPIN-specific)
      #
      # @return [String] derivation marker ("'" for foreign, "" for native)
      def derivation_marker
        native? ? NATIVE_MARKER : DERIVATION_MARKER
      end

      # Alias for backward compatibility
      alias suffix derivation_marker

      # Create a new identifier with enhanced state
      #
      # Preserves type, side, terminal status, and derivation.
      #
      # @return [Identifier] new identifier instance with enhanced state
      #
      # @example
      #   identifier.enhance  # (:K, :first, :normal, true) => (:K, :first, :enhanced, true)
      def enhance
        return self if enhanced?

        self.class.new(type, side, Pin::Identifier::ENHANCED_STATE, native, terminal: terminal)
      end

      # Create a new identifier without enhanced state
      #
      # @return [Identifier] new identifier instance with normal state
      #
      # @example
      #   identifier.unenhance  # (:K, :first, :enhanced, true) => (:K, :first, :normal, true)
      def unenhance
        return self unless enhanced?

        self.class.new(type, side, Pin::Identifier::NORMAL_STATE, native, terminal: terminal)
      end

      # Create a new identifier with diminished state
      #
      # @return [Identifier] new identifier instance with diminished state
      #
      # @example
      #   identifier.diminish  # (:K, :first, :normal, true) => (:K, :first, :diminished, true)
      def diminish
        return self if diminished?

        self.class.new(type, side, Pin::Identifier::DIMINISHED_STATE, native, terminal: terminal)
      end

      # Create a new identifier without diminished state
      #
      # @return [Identifier] new identifier instance with normal state
      #
      # @example
      #   identifier.undiminish  # (:K, :first, :diminished, true) => (:K, :first, :normal, true)
      def undiminish
        return self unless diminished?

        self.class.new(type, side, Pin::Identifier::NORMAL_STATE, native, terminal: terminal)
      end

      # Create a new identifier with normal state (no state modifiers)
      #
      # @return [Identifier] new identifier instance with normal state
      #
      # @example
      #   identifier.normalize  # (:K, :first, :enhanced, true) => (:K, :first, :normal, true)
      def normalize
        return self if normal?

        self.class.new(type, side, Pin::Identifier::NORMAL_STATE, native, terminal: terminal)
      end

      # Create a new identifier marked as terminal
      #
      # @return [Identifier] new identifier instance marked as terminal
      #
      # @example
      #   identifier.mark_terminal  # "K" => "K^"
      #   identifier.mark_terminal  # "K'" => "K^'"
      def mark_terminal
        return self if terminal?

        self.class.new(type, side, state, native, terminal: true)
      end

      # Create a new identifier unmarked as terminal
      #
      # @return [Identifier] new identifier instance unmarked as terminal
      #
      # @example
      #   identifier.unmark_terminal  # "K^" => "K"
      #   identifier.unmark_terminal  # "K^'" => "K'"
      def unmark_terminal
        return self unless terminal?

        self.class.new(type, side, state, native, terminal: false)
      end

      # Create a new identifier with opposite side
      #
      # @return [Identifier] new identifier instance with opposite side
      #
      # @example
      #   identifier.flip  # (:K, :first, :normal, true) => (:K, :second, :normal, true)
      def flip
        self.class.new(type, opposite_side, state, native, terminal: terminal)
      end

      # Create a new identifier with foreign/derived style
      #
      # Converts a native piece to foreign style (opposite side's native style).
      #
      # @return [Identifier] new identifier instance with foreign style
      #
      # @example
      #   identifier.derive  # (:K, :first, :normal, true) => (:K, :first, :normal, false)
      #   # "K" => "K'"
      def derive
        return self if derived?

        self.class.new(type, side, state, FOREIGN, terminal: terminal)
      end

      # Create a new identifier with native style
      #
      # Converts a foreign piece to native style (current side's native style).
      #
      # @return [Identifier] new identifier instance with native style
      #
      # @example
      #   identifier.underive  # (:K, :first, :normal, false) => (:K, :first, :normal, true)
      #   # "K'" => "K"
      def underive
        return self if native?

        self.class.new(type, side, state, NATIVE, terminal: terminal)
      end

      # Create a new identifier with a different type
      #
      # Preserves side, state, terminal status, and derivation.
      #
      # @param new_type [Symbol] new type (:A to :Z)
      # @return [Identifier] new identifier instance with different type
      #
      # @example
      #   identifier.with_type(:Q)  # (:K, :first, :normal, true) => (:Q, :first, :normal, true)
      def with_type(new_type)
        Pin::Identifier.validate_type(new_type)
        return self if type == new_type

        self.class.new(new_type, side, state, native, terminal: terminal)
      end

      # Create a new identifier with a different side
      #
      # Preserves type, state, terminal status, and derivation.
      #
      # @param new_side [Symbol] :first or :second
      # @return [Identifier] new identifier instance with different side
      #
      # @example
      #   identifier.with_side(:second)  # (:K, :first, :normal, true) => (:K, :second, :normal, true)
      def with_side(new_side)
        Pin::Identifier.validate_side(new_side)
        return self if side == new_side

        self.class.new(type, new_side, state, native, terminal: terminal)
      end

      # Create a new identifier with a different state
      #
      # Preserves type, side, terminal status, and derivation.
      #
      # @param new_state [Symbol] :normal, :enhanced, or :diminished
      # @return [Identifier] new identifier instance with different state
      #
      # @example
      #   identifier.with_state(:enhanced)  # (:K, :first, :normal, true) => (:K, :first, :enhanced, true)
      def with_state(new_state)
        Pin::Identifier.validate_state(new_state)
        return self if state == new_state

        self.class.new(type, side, new_state, native, terminal: terminal)
      end

      # Create a new identifier with a different derivation
      #
      # Preserves type, side, state, and terminal status.
      #
      # @param new_native [Boolean] true for native, false for foreign
      # @return [Identifier] new identifier instance with different derivation
      #
      # @example
      #   identifier.with_derivation(false)  # (:K, :first, :normal, true) => (:K, :first, :normal, false)
      def with_derivation(new_native)
        self.class.validate_derivation(new_native)
        return self if native == new_native

        self.class.new(type, side, state, new_native, terminal: terminal)
      end

      # Create a new identifier with a different terminal status
      #
      # Preserves type, side, state, and derivation.
      #
      # @param new_terminal_bool [Boolean] terminal status
      # @return [Identifier] new identifier instance with different terminal status
      #
      # @example
      #   identifier.with_terminal(true)  # "K" => "K^"
      def with_terminal(new_terminal_bool)
        raise ::TypeError unless [true, false].include?(new_terminal_bool)

        return self if terminal? == new_terminal_bool

        self.class.new(type, side, state, native, terminal: new_terminal_bool)
      end

      # Check if the identifier has enhanced state
      #
      # @return [Boolean] true if enhanced
      def enhanced?
        @pin_identifier.enhanced?
      end

      # Check if the identifier has diminished state
      #
      # @return [Boolean] true if diminished
      def diminished?
        @pin_identifier.diminished?
      end

      # Check if the identifier has normal state (no state modifiers)
      #
      # @return [Boolean] true if normal
      def normal?
        @pin_identifier.normal?
      end

      # Check if the identifier belongs to the first player
      #
      # @return [Boolean] true if first player
      def first_player?
        @pin_identifier.first_player?
      end

      # Check if the identifier belongs to the second player
      #
      # @return [Boolean] true if second player
      def second_player?
        @pin_identifier.second_player?
      end

      # Check if the identifier is a terminal piece
      #
      # A terminal piece is one whose presence, condition, or capacity for action
      # determines whether the match can continue.
      #
      # @return [Boolean] true if terminal
      def terminal?
        @pin_identifier.terminal?
      end

      # Check if the identifier has native style
      #
      # A native piece has the native style of its current side.
      #
      # @return [Boolean] true if native style
      def native?
        native == NATIVE
      end

      # Check if the identifier has foreign/derived style
      #
      # A derived piece has the foreign style (opposite side's native style).
      #
      # @return [Boolean] true if foreign/derived style
      def derived?
        native == FOREIGN
      end

      # Alias for derived? to match specification terminology
      alias foreign? derived?

      # Check if this identifier is the same type as another
      #
      # Ignores side, state, terminal status, and derivation.
      #
      # @param other [Identifier] identifier to compare with
      # @return [Boolean] true if same type
      #
      # @example
      #   king1.same_type?(king2)  # (:K, :first, :normal, true) and (:K, :second, :enhanced, false) => true
      def same_type?(other)
        return false unless other.is_a?(self.class)

        @pin_identifier.same_type?(other.instance_variable_get(:@pin_identifier))
      end

      # Check if this identifier belongs to the same side as another
      #
      # @param other [Identifier] identifier to compare with
      # @return [Boolean] true if same side
      def same_side?(other)
        return false unless other.is_a?(self.class)

        @pin_identifier.same_side?(other.instance_variable_get(:@pin_identifier))
      end

      # Check if this identifier has the same state as another
      #
      # @param other [Identifier] identifier to compare with
      # @return [Boolean] true if same state
      def same_state?(other)
        return false unless other.is_a?(self.class)

        @pin_identifier.same_state?(other.instance_variable_get(:@pin_identifier))
      end

      # Check if this identifier has the same terminal status as another
      #
      # @param other [Identifier] identifier to compare with
      # @return [Boolean] true if same terminal status
      def same_terminal?(other)
        return false unless other.is_a?(self.class)

        @pin_identifier.same_terminal?(other.instance_variable_get(:@pin_identifier))
      end

      # Check if this identifier has the same style derivation as another
      #
      # @param other [Identifier] identifier to compare with
      # @return [Boolean] true if same style derivation
      def same_style?(other)
        return false unless other.is_a?(self.class)

        native == other.native
      end

      # Custom equality comparison
      #
      # Two identifiers are equal if they have the same type, side, state,
      # terminal status, and derivation.
      #
      # @param other [Object] object to compare with
      # @return [Boolean] true if identifiers are equal
      def ==(other)
        return false unless other.is_a?(self.class)

        @pin_identifier == other.instance_variable_get(:@pin_identifier) && native == other.native
      end

      # Alias for == to ensure Set functionality works correctly
      alias eql? ==

      # Custom hash implementation for use in collections
      #
      # @return [Integer] hash value
      def hash
        [self.class, @pin_identifier, native].hash
      end

      # Validate that the derivation is a valid boolean
      #
      # @param derivation [Boolean] the derivation to validate
      # @raise [ArgumentError] if invalid
      def self.validate_derivation(derivation)
        return if VALID_DERIVATIONS.include?(derivation)

        raise ::ArgumentError, format(ERROR_INVALID_DERIVATION, derivation.inspect)
      end

      private

      # Get the opposite side of the current identifier
      #
      # @return [Symbol] :first if current side is :second, :second if current side is :first
      def opposite_side
        @pin_identifier.send(:opposite_side)
      end
    end
  end
end
