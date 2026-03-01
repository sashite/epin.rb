# frozen_string_literal: true

require "sashite/pin"

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
    # All 624 possible instances (312 PIN tokens × 2 derivation statuses) are
    # pre-instantiated and frozen at load time. Parsing, fetching, and all
    # transformation methods return these cached instances via hash lookup —
    # no Identifier is ever allocated after the module loads.
    #
    # @example Access via module methods (recommended)
    #   epin = Sashite::Epin.parse("K^'")
    #   epin = Sashite::Epin.fetch(pin, derived: true)
    #
    # @example Direct construction (mainly for tests / pool building)
    #   pin = Sashite::Pin.parse("K^")
    #   epin = Identifier.new(pin)
    #   epin = Identifier.new(pin, derived: true)
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
        raise Errors::Argument, Errors::Argument::Messages::INVALID_PIN unless ::Sashite::Pin::Identifier === pin
        raise Errors::Argument, Errors::Argument::Messages::INVALID_DERIVED unless true == derived || false == derived

        @pin = pin
        @derived = derived
        @string = (derived ? "#{pin}#{Constants::DERIVATION_SUFFIX}" : pin.to_s).freeze
        @hash = (pin.hash ^ (derived ? 1 : 0).hash).freeze

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
      # Pre-computed at construction time — zero allocation.
      #
      # @return [String] The EPIN string
      #
      # @example
      #   Identifier.new(pin).to_s                  # => "K^"
      #   Identifier.new(pin, derived: true).to_s   # => "K^'"
      def to_s
        @string
      end

      # ========================================================================
      # Transformations (pool lookups — zero allocation)
      # ========================================================================

      # Returns a cached Identifier with a different PIN component.
      #
      # @param new_pin [Sashite::Pin::Identifier] The new PIN component
      # @return [Identifier] A cached Identifier with the specified PIN
      # @raise [Errors::Argument] If the PIN is invalid
      #
      # @example
      #   epin = Sashite::Epin.parse("K^'")
      #   new_pin = Sashite::Pin.parse("+Q^")
      #   epin.with_pin(new_pin).to_s  # => "+Q^'"
      def with_pin(new_pin)
        return self if pin.equal?(new_pin)

        raise Errors::Argument, Errors::Argument::Messages::INVALID_PIN unless ::Sashite::Pin::Identifier === new_pin

        self.class.fetch(new_pin, @derived)
      end

      # Returns a cached Identifier marked as derived.
      #
      # @return [Identifier] A cached Identifier with derived: true
      #
      # @example
      #   epin = Sashite::Epin.parse("K^")
      #   epin.derive.to_s  # => "K^'"
      def derive
        return self if @derived

        self.class.fetch(pin, true)
      end

      # Returns a cached Identifier marked as native.
      #
      # @return [Identifier] A cached Identifier with derived: false
      #
      # @example
      #   epin = Sashite::Epin.parse("K^'")
      #   epin.native.to_s  # => "K^"
      def native
        return self if !@derived

        self.class.fetch(pin, false)
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
      #   epin1 = Sashite::Epin.parse("K'")
      #   epin2 = Sashite::Epin.parse("Q'")
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

      # Returns a pre-computed hash code for the Identifier.
      #
      # @return [Integer] Hash code
      def hash
        @hash
      end

      # Returns an inspect string for the Identifier.
      #
      # @return [String] Inspect representation
      def inspect
        "#<#{self.class} #{self}>"
      end

      # ========================================================================
      # Flyweight Pool (class-level)
      # ========================================================================

      class << self
        # Retrieves a cached Identifier from the flyweight pool.
        # Direct hash lookup — no validation, no allocation.
        #
        # @param pin [Sashite::Pin::Identifier] PIN component (must be from PIN's pool)
        # @param derived [Boolean] Derived status
        # @return [Identifier] A cached Identifier
        # @api private
        def fetch(pin, derived)
          derived ? @derived_pool[pin] : @native_pool[pin]
        end
      end

      # Build the flyweight pool at load time.
      # Two separate hashes (native/derived) keyed by PIN instance
      # for single-lookup access with no Array allocation for the key.
      @native_pool = {}
      @derived_pool = {}

      ::Sashite::Pin::Constants::VALID_ABBRS.each do |abbr|
        ::Sashite::Pin::Constants::VALID_SIDES.each do |side|
          ::Sashite::Pin::Constants::VALID_STATES.each do |state|
            [false, true].each do |terminal|
              pin = ::Sashite::Pin.fetch(abbr, side, state, terminal: terminal)
              @native_pool[pin]  = new(pin, derived: false)
              @derived_pool[pin] = new(pin, derived: true)
            end
          end
        end
      end

      @native_pool.freeze
      @derived_pool.freeze
    end
  end
end
