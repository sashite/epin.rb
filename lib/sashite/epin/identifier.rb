# frozen_string_literal: true

require_relative "constants"
require_relative "errors"

module Sashite
  module Epin
    # Represents a parsed EPIN (Extended Piece Identifier Notation) identifier.
    #
    # An Identifier combines a PIN component with a derivation status:
    # - PIN: encodes abbr, side, state, and terminal status
    # - Derived: indicates whether the piece uses native or derived style
    #
    # Instances are immutable (frozen after creation).
    #
    # @example Creating identifiers
    #   pin = Sashite::Pin.parse("K^")
    #   epin = Identifier.new(pin)
    #   epin = Identifier.new(pin, derived: true)
    #
    # @example String conversion
    #   Identifier.new(pin).to_s                  # => "K^"
    #   Identifier.new(pin, derived: true).to_s   # => "K^'"
    #
    # @see https://sashite.dev/specs/epin/1.0.0/
    class Identifier
      # @return [Sashite::Pin::Identifier] PIN component
      attr_reader :pin

      # Creates a new Identifier instance.
      #
      # @param pin [Sashite::Pin::Identifier] PIN component
      # @param derived [Boolean] Derived status
      # @return [Identifier] A new frozen Identifier instance
      # @raise [Errors::Argument] If any attribute is invalid
      #
      # @example
      #   pin = Sashite::Pin.parse("K^")
      #   Identifier.new(pin)
      #   Identifier.new(pin, derived: true)
      def initialize(pin, derived: false)
        validate_pin!(pin)
        validate_derived!(derived)

        @pin = pin
        @derived = derived

        freeze
      end

      # Returns the derived status.
      #
      # @return [Boolean] true if derived style, false otherwise
      #
      # @example
      #   Identifier.new(pin).derived?                  # => false
      #   Identifier.new(pin, derived: true).derived?   # => true
      def derived?
        @derived
      end

      # Returns the native status.
      #
      # @return [Boolean] true if native style, false otherwise
      #
      # @example
      #   Identifier.new(pin).native?                  # => true
      #   Identifier.new(pin, derived: true).native?   # => false
      def native?
        !@derived
      end

      # ========================================================================
      # String Conversion
      # ========================================================================

      # Returns the EPIN string representation.
      #
      # @return [String] The EPIN string
      #
      # @example
      #   Identifier.new(pin).to_s                  # => "K^"
      #   Identifier.new(pin, derived: true).to_s   # => "K^'"
      def to_s
        derived? ? "#{pin}#{Constants::DERIVATION_SUFFIX}" : pin.to_s
      end

      # ========================================================================
      # Transformations
      # ========================================================================

      # Returns a new Identifier with a different PIN component.
      #
      # @param new_pin [Sashite::Pin::Identifier] The new PIN component
      # @return [Identifier] A new Identifier with the specified PIN
      # @raise [Errors::Argument] If the PIN is invalid
      #
      # @example
      #   epin = Identifier.new(pin, derived: true)
      #   new_pin = Sashite::Pin.parse("+Q^")
      #   epin.with_pin(new_pin).to_s  # => "+Q^'"
      def with_pin(new_pin)
        return self if pin == new_pin

        self.class.new(new_pin, derived: @derived)
      end

      # Returns a new Identifier marked as derived.
      #
      # @return [Identifier] A new Identifier with derived: true
      #
      # @example
      #   epin = Identifier.new(pin)
      #   epin.derive.to_s  # => "K^'"
      def derive
        return self if derived?

        self.class.new(pin, derived: true)
      end

      # Returns a new Identifier marked as native.
      #
      # @return [Identifier] A new Identifier with derived: false
      #
      # @example
      #   epin = Identifier.new(pin, derived: true)
      #   epin.native.to_s  # => "K^"
      def native
        return self if native?

        self.class.new(pin, derived: false)
      end

      # ========================================================================
      # Comparison Queries
      # ========================================================================

      # Checks if two Identifiers have the same derived status.
      #
      # @param other [Identifier] The other Identifier to compare
      # @return [Boolean] true if same derived status
      #
      # @example
      #   epin1 = Identifier.new(pin1, derived: true)
      #   epin2 = Identifier.new(pin2, derived: true)
      #   epin1.same_derived?(epin2)  # => true
      def same_derived?(other)
        @derived == other.derived?
      end

      # ========================================================================
      # Equality
      # ========================================================================

      # Checks equality with another Identifier.
      #
      # @param other [Object] The object to compare
      # @return [Boolean] true if equal
      def ==(other)
        return false unless self.class === other

        pin == other.pin && @derived == other.derived?
      end

      alias eql? ==

      # Returns a hash code for the Identifier.
      #
      # @return [Integer] Hash code
      def hash
        [pin, @derived].hash
      end

      # Returns an inspect string for the Identifier.
      #
      # @return [String] Inspect representation
      def inspect
        "#<#{self.class} #{self}>"
      end

      private

      # ========================================================================
      # Private Validation
      # ========================================================================

      def validate_pin!(pin)
        return if ::Sashite::Pin::Identifier === pin

        raise Errors::Argument, Errors::Argument::Messages::INVALID_PIN
      end

      def validate_derived!(derived)
        return if ::TrueClass === derived || ::FalseClass === derived

        raise Errors::Argument, Errors::Argument::Messages::INVALID_DERIVED
      end
    end
  end
end
