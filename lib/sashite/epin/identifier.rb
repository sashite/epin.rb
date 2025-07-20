# frozen_string_literal: true

require "sashite/pin"

module Sashite
  module Epin
    # Represents an identifier in EPIN (Extended Piece Identifier Notation) format.
    #
    # An identifier consists of a PIN component with an optional derivation marker:
    # - PIN component: [<state>]<letter> (from PIN specification)
    # - Derivation marker: "'" (foreign style) or none (native style)
    #
    # The case of the letter determines ownership:
    # - Uppercase (A-Z): first player
    # - Lowercase (a-z): second player
    #
    # Style derivation logic:
    # - No suffix: piece has the native style of its current side
    # - Apostrophe suffix: piece has the foreign style (opposite side's native style)
    #
    # All instances are immutable - state manipulation methods return new instances.
    # This extends the Game Protocol's piece model with Style support through derivation.
    class Identifier
      # Valid derivation suffixes
      DERIVATION_SUFFIX = "'"
      NATIVE_SUFFIX = ""

      # Derivation constants
      NATIVE = true
      FOREIGN = false

      # Valid derivations
      VALID_DERIVATIONS = [NATIVE, FOREIGN].freeze

      # Error messages
      ERROR_INVALID_EPIN = "Invalid EPIN string: %s"
      ERROR_INVALID_DERIVATION = "Derivation must be true (native) or false (foreign), got: %s"

      # @return [Symbol] the piece type (:A to :Z)
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

      # @return [Boolean] the style derivation (true for native, false for foreign)
      attr_reader :native

      # Create a new identifier instance
      #
      # @param type [Symbol] piece type (:A to :Z)
      # @param side [Symbol] player side (:first or :second)
      # @param state [Symbol] piece state (:normal, :enhanced, or :diminished)
      # @param native [Boolean] style derivation (true for native, false for foreign)
      # @raise [ArgumentError] if parameters are invalid
      # @example
      #   Identifier.new(:K, :first, :normal, true)
      #   Identifier.new(:P, :second, :enhanced, false)
      def initialize(type, side, state = Pin::Identifier::NORMAL_STATE, native = NATIVE)
        # Validate using PIN class methods for type, side, and state
        Pin::Identifier.validate_type(type)
        Pin::Identifier.validate_side(side)
        Pin::Identifier.validate_state(state)
        self.class.validate_derivation(native)

        @pin_identifier = Pin::Identifier.new(type, side, state)
        @native = native

        freeze
      end

      # Parse an EPIN string into an Identifier object
      #
      # @param epin_string [String] EPIN notation string
      # @return [Identifier] new identifier instance
      # @raise [ArgumentError] if the EPIN string is invalid
      # @example
      #   Epin::Identifier.parse("k")     # => #<Epin::Identifier type=:K side=:second state=:normal native=true>
      #   Epin::Identifier.parse("+R'")   # => #<Epin::Identifier type=:R side=:first state=:enhanced native=false>
      #   Epin::Identifier.parse("-p")    # => #<Epin::Identifier type=:P side=:second state=:diminished native=true>
      def self.parse(epin_string)
        string_value = String(epin_string)

        # Check for derivation suffix
        if string_value.end_with?(DERIVATION_SUFFIX)
          pin_part = string_value[0...-1] # Remove the apostrophe
          foreign = true
        else
          pin_part = string_value
          foreign = false
        end

        # Validate and parse the PIN part using existing PIN logic
        raise ::ArgumentError, format(ERROR_INVALID_EPIN, string_value) unless Pin::Identifier.valid?(pin_part)

        pin_identifier = Pin::Identifier.parse(pin_part)
        identifier_native = !foreign

        new(pin_identifier.type, pin_identifier.side, pin_identifier.state, identifier_native)
      end

      # Check if a string is a valid EPIN notation
      #
      # @param epin_string [String] The string to validate
      # @return [Boolean] true if valid EPIN, false otherwise
      #
      # @example
      #   Sashite::Epin::Identifier.valid?("K")    # => true
      #   Sashite::Epin::Identifier.valid?("+R'")  # => true
      #   Sashite::Epin::Identifier.valid?("-p")   # => true
      #   Sashite::Epin::Identifier.valid?("KK")   # => false
      #   Sashite::Epin::Identifier.valid?("++K")  # => false
      def self.valid?(epin_string)
        return false unless epin_string.is_a?(::String)
        return false if epin_string.empty?

        # Check for derivation suffix
        if epin_string.end_with?(DERIVATION_SUFFIX)
          pin_part = epin_string[0...-1] # Remove the apostrophe
          return false if pin_part.empty? # Can't have just an apostrophe
        else
          pin_part = epin_string
        end

        # Validate the PIN part using existing PIN validation
        Pin::Identifier.valid?(pin_part)
      end

      # Convert the identifier to its EPIN string representation
      #
      # @return [String] EPIN notation string
      # @example
      #   identifier.to_s  # => "+R'"
      #   identifier.to_s  # => "-p"
      #   identifier.to_s  # => "K"
      def to_s
        "#{prefix}#{letter}#{suffix}"
      end

      # Get the letter representation (inherited from PIN logic)
      #
      # @return [String] letter representation combining type and side
      def letter
        @pin_identifier.letter
      end

      # Get the prefix representation (inherited from PIN logic)
      #
      # @return [String] prefix representing the state
      def prefix
        @pin_identifier.prefix
      end

      # Get the suffix representation
      #
      # @return [String] suffix representing the derivation
      def suffix
        native? ? NATIVE_SUFFIX : DERIVATION_SUFFIX
      end

      # Create a new identifier with enhanced state
      #
      # @return [Identifier] new identifier instance with enhanced state
      # @example
      #   identifier.enhance  # (:K, :first, :normal, true) => (:K, :first, :enhanced, true)
      def enhance
        return self if enhanced?

        self.class.new(type, side, Pin::Identifier::ENHANCED_STATE, native)
      end

      # Create a new identifier without enhanced state
      #
      # @return [Identifier] new identifier instance without enhanced state
      # @example
      #   identifier.unenhance  # (:K, :first, :enhanced, true) => (:K, :first, :normal, true)
      def unenhance
        return self unless enhanced?

        self.class.new(type, side, Pin::Identifier::NORMAL_STATE, native)
      end

      # Create a new identifier with diminished state
      #
      # @return [Identifier] new identifier instance with diminished state
      # @example
      #   identifier.diminish  # (:K, :first, :normal, true) => (:K, :first, :diminished, true)
      def diminish
        return self if diminished?

        self.class.new(type, side, Pin::Identifier::DIMINISHED_STATE, native)
      end

      # Create a new identifier without diminished state
      #
      # @return [Identifier] new identifier instance without diminished state
      # @example
      #   identifier.undiminish  # (:K, :first, :diminished, true) => (:K, :first, :normal, true)
      def undiminish
        return self unless diminished?

        self.class.new(type, side, Pin::Identifier::NORMAL_STATE, native)
      end

      # Create a new identifier with normal state (no modifiers)
      #
      # @return [Identifier] new identifier instance with normal state
      # @example
      #   identifier.normalize  # (:K, :first, :enhanced, true) => (:K, :first, :normal, true)
      def normalize
        return self if normal?

        self.class.new(type, side, Pin::Identifier::NORMAL_STATE, native)
      end

      # Create a new identifier with opposite side
      #
      # @return [Identifier] new identifier instance with opposite side
      # @example
      #   identifier.flip  # (:K, :first, :normal, true) => (:K, :second, :normal, true)
      def flip
        self.class.new(type, opposite_side, state, native)
      end

      # Create a new identifier with foreign style (derivation marker)
      #
      # @return [Identifier] new identifier instance with foreign style
      # @example
      #   identifier.derive  # (:K, :first, :normal, true) => (:K, :first, :normal, false)
      def derive
        return self if derived?

        self.class.new(type, side, state, FOREIGN)
      end

      # Create a new identifier with native style (no derivation marker)
      #
      # @return [Identifier] new identifier instance with native style
      # @example
      #   identifier.underive  # (:K, :first, :normal, false) => (:K, :first, :normal, true)
      def underive
        return self if native?

        self.class.new(type, side, state, NATIVE)
      end

      # Create a new identifier with a different type (keeping same side, state, and derivation)
      #
      # @param new_type [Symbol] new type (:A to :Z)
      # @return [Identifier] new identifier instance with different type
      # @example
      #   identifier.with_type(:Q)  # (:K, :first, :normal, true) => (:Q, :first, :normal, true)
      def with_type(new_type)
        Pin::Identifier.validate_type(new_type)
        return self if type == new_type

        self.class.new(new_type, side, state, native)
      end

      # Create a new identifier with a different side (keeping same type, state, and derivation)
      #
      # @param new_side [Symbol] :first or :second
      # @return [Identifier] new identifier instance with different side
      # @example
      #   identifier.with_side(:second)  # (:K, :first, :normal, true) => (:K, :second, :normal, true)
      def with_side(new_side)
        Pin::Identifier.validate_side(new_side)
        return self if side == new_side

        self.class.new(type, new_side, state, native)
      end

      # Create a new identifier with a different state (keeping same type, side, and derivation)
      #
      # @param new_state [Symbol] :normal, :enhanced, or :diminished
      # @return [Identifier] new identifier instance with different state
      # @example
      #   identifier.with_state(:enhanced)  # (:K, :first, :normal, true) => (:K, :first, :enhanced, true)
      def with_state(new_state)
        Pin::Identifier.validate_state(new_state)
        return self if state == new_state

        self.class.new(type, side, new_state, native)
      end

      # Create a new identifier with a different derivation (keeping same type, side, and state)
      #
      # @param new_native [Boolean] true for native, false for foreign
      # @return [Identifier] new identifier instance with different derivation
      # @example
      #   identifier.with_derivation(false)  # (:K, :first, :normal, true) => (:K, :first, :normal, false)
      def with_derivation(new_native)
        self.class.validate_derivation(new_native)
        return self if native == new_native

        self.class.new(type, side, state, new_native)
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

      # Check if the identifier has normal state (no modifiers)
      #
      # @return [Boolean] true if no modifiers are present
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

      # Check if the identifier has native style (no derivation marker)
      #
      # @return [Boolean] true if native style
      def native?
        native == NATIVE
      end

      # Check if the identifier has foreign style (derivation marker)
      #
      # @return [Boolean] true if foreign style
      def derived?
        native == FOREIGN
      end

      # Alias for derived? to match the specification terminology
      alias foreign? derived?

      # Check if this identifier is the same type as another (ignoring side, state, and derivation)
      #
      # @param other [Identifier] identifier to compare with
      # @return [Boolean] true if same type
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
