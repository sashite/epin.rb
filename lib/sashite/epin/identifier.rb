# frozen_string_literal: true

require "sashite/pin"

module Sashite
  module Epin
    # Represents an identifier in EPIN (Extended Piece Identifier Notation) format.
    #
    # EPIN extends PIN by adding a derivation marker to track piece style in cross-style games.
    # An EPIN identifier is simply a PIN identifier plus a boolean flag indicating whether
    # the piece uses its own side's native style (native) or the opponent's style (derived).
    #
    # ## Pure Composition Design
    #
    # EPIN doesn't reimplement PIN features - it's pure composition:
    # - All piece attributes (name, side, state, terminal) come from the PIN component
    # - EPIN adds only style derivation tracking (native vs derived)
    # - Zero code duplication
    #
    # ## Minimal API
    #
    # Core methods (6 total):
    # 1. new(pin, derived: false) - create from PIN component
    # 2. pin - get PIN component
    # 3. derived? - check derivation status
    # 4. to_s - serialize
    # 5. with_pin(new_pin) - replace PIN component
    # 6. with_derived(boolean) - change derivation status
    #
    # Everything else uses the PIN component API directly.
    #
    # All instances are immutable - transformation methods return new instances.
    #
    # @example Basic usage
    #   # Create from PIN component
    #   pin = Sashite::Pin.parse("K^")
    #   epin = Sashite::Epin::Identifier.new(pin, derived: false)
    #   epin.to_s           # => "K^" (native)
    #
    #   # Mark as derived
    #   derived = epin.mark_derived
    #   derived.to_s        # => "K^'" (derived from opponent's style)
    #
    # @example Accessing attributes via PIN component
    #   epin = Sashite::Epin.parse("+R^'")
    #   epin.pin.type       # => :R (Piece Name)
    #   epin.pin.side       # => :first (Piece Side)
    #   epin.pin.state      # => :enhanced (Piece State)
    #   epin.pin.terminal?  # => true (Terminal Status)
    #   epin.derived?       # => true (Piece Style)
    #
    # @example Transformations
    #   epin = Sashite::Epin.parse("K^")
    #
    #   # Transform PIN component
    #   epin.with_pin(epin.pin.with_type(:Q))  # => "Q^"
    #
    #   # Transform derivation
    #   epin.mark_derived                       # => "K^'"
    #   epin.with_derived(true)                 # => "K^'"
    #
    # @see https://sashite.dev/specs/epin/1.0.0/ EPIN Specification v1.0.0
    class Identifier
      # EPIN validation pattern matching the specification
      # Grammar: <epin> ::= <pin> | <pin> "'"
      EPIN_PATTERN = /\A[-+]?[A-Za-z]\^?'?\z/

      # Derivation marker character
      DERIVATION_MARKER = "'"

      # Error messages
      ERROR_INVALID_EPIN = "Invalid EPIN string: %s"
      ERROR_INVALID_PIN = "PIN component must be a Pin::Identifier, got: %s"
      ERROR_MULTIPLE_MARKERS = "EPIN string cannot have multiple derivation markers: %s"

      # @return [Pin::Identifier] the PIN component
      attr_reader :pin

      # @return [Boolean] whether the piece uses derived style (opponent's native style)
      def derived?
        @derived
      end

      # Create a new EPIN identifier from PIN component and derivation flag
      #
      # @param pin [Pin::Identifier] the PIN component
      # @param derived [Boolean] whether the piece uses derived style (default: false)
      # @raise [ArgumentError] if pin is not a Pin::Identifier
      #
      # @example Create EPIN identifiers
      #   pin = Sashite::Pin.parse("K^")
      #   native = Sashite::Epin::Identifier.new(pin, derived: false)  # => "K^"
      #   derived = Sashite::Epin::Identifier.new(pin, derived: true)  # => "K^'"
      def initialize(pin, derived: false)
        raise ::ArgumentError, format(ERROR_INVALID_PIN, pin.class) unless pin.is_a?(Pin::Identifier)

        @pin = pin
        @derived = !!derived

        freeze
      end

      # Parse an EPIN string into an Identifier object
      #
      # @param epin_string [String] EPIN notation string
      # @return [Identifier] new identifier instance
      # @raise [ArgumentError] if the EPIN string is invalid
      #
      # @example Parse EPIN strings
      #   Sashite::Epin::Identifier.parse("K^")   # => Native king
      #   Sashite::Epin::Identifier.parse("K^'")  # => Derived king
      #   Sashite::Epin::Identifier.parse("+R'")  # => Derived enhanced rook
      def self.parse(epin_string)
        string_value = String(epin_string)
        validate_epin_string(string_value)

        # Check for derivation marker
        has_marker = string_value.end_with?(DERIVATION_MARKER)

        # Extract PIN part (remove derivation marker if present)
        pin_part = has_marker ? string_value[0...-1] : string_value

        # Parse PIN component
        pin_identifier = Pin::Identifier.parse(pin_part)

        new(pin_identifier, derived: has_marker)
      end

      # Check if a string is a valid EPIN notation
      #
      # @param epin_string [String] the string to validate
      # @return [Boolean] true if valid EPIN, false otherwise
      #
      # @example Validate EPIN strings
      #   Sashite::Epin::Identifier.valid?("K^")     # => true
      #   Sashite::Epin::Identifier.valid?("K^'")    # => true
      #   Sashite::Epin::Identifier.valid?("+R'")    # => true
      #   Sashite::Epin::Identifier.valid?("K^''")   # => false (multiple markers)
      #   Sashite::Epin::Identifier.valid?("KK'")    # => false (invalid PIN)
      def self.valid?(epin_string)
        return false unless epin_string.is_a?(::String)
        return false unless epin_string.match?(EPIN_PATTERN)

        # Check for multiple derivation markers
        marker_count = epin_string.count(DERIVATION_MARKER)
        return false if marker_count > 1

        # Validate PIN part
        has_marker = epin_string.end_with?(DERIVATION_MARKER)
        pin_part = has_marker ? epin_string[0...-1] : epin_string

        Pin::Identifier.valid?(pin_part)
      end

      # Convert the identifier to its EPIN string representation
      #
      # @return [String] EPIN notation string
      #
      # @example Serialize identifiers
      #   native.to_s   # => "K^"
      #   derived.to_s  # => "K^'"
      def to_s
        pin.to_s + suffix
      end

      # Get the derivation marker suffix
      #
      # @return [String] derivation marker if derived, empty string if native
      def suffix
        derived? ? DERIVATION_MARKER : ""
      end

      # Create a new identifier with a different PIN component
      #
      # @param new_pin [Pin::Identifier] new PIN component
      # @return [Identifier] new identifier with different PIN
      # @raise [ArgumentError] if new_pin is not a Pin::Identifier
      #
      # @example Replace PIN component
      #   epin = Sashite::Epin.parse("K^'")
      #   new_pin = epin.pin.with_type(:Q)
      #   epin.with_pin(new_pin).to_s  # => "Q^'"
      def with_pin(new_pin)
        raise ::ArgumentError, format(ERROR_INVALID_PIN, new_pin.class) unless new_pin.is_a?(Pin::Identifier)
        return self if pin == new_pin

        self.class.new(new_pin, derived: derived?)
      end

      # Create a new identifier with different derivation status
      #
      # @param new_derived [Boolean] new derivation status
      # @return [Identifier] new identifier with different derivation
      #
      # @example Change derivation status
      #   native = Sashite::Epin.parse("K^")
      #   derived = native.with_derived(true)
      #   derived.to_s  # => "K^'"
      def with_derived(new_derived)
        new_derived_bool = !!new_derived
        return self if derived? == new_derived_bool

        self.class.new(pin, derived: new_derived_bool)
      end

      # Create a new identifier marked as derived (opponent's native style)
      #
      # @return [Identifier] new identifier marked as derived
      #
      # @example Mark as derived
      #   native = Sashite::Epin.parse("K^")
      #   derived = native.mark_derived
      #   derived.to_s  # => "K^'"
      def mark_derived
        return self if derived?

        self.class.new(pin, derived: true)
      end

      # Create a new identifier marked as native (own side's native style)
      #
      # @return [Identifier] new identifier marked as native
      #
      # @example Mark as native
      #   derived = Sashite::Epin.parse("K^'")
      #   native = derived.unmark_native
      #   native.to_s  # => "K^"
      def unmark_native
        return self unless derived?

        self.class.new(pin, derived: false)
      end

      # Check if the identifier uses native style (own side's native style)
      #
      # @return [Boolean] true if native (not derived)
      def native?
        !derived?
      end

      # Check if this identifier has the same derivation status as another
      #
      # @param other [Identifier] identifier to compare with
      # @return [Boolean] true if same derivation status
      #
      # @example Compare derivation status
      #   native = Sashite::Epin.parse("K^")
      #   derived = Sashite::Epin.parse("K^'")
      #   native.same_derivation?(derived)  # => false
      def same_derivation?(other)
        return false unless other.is_a?(self.class)

        derived? == other.derived?
      end

      # Custom equality comparison
      #
      # @param other [Object] object to compare with
      # @return [Boolean] true if identifiers are equal
      def ==(other)
        return false unless other.is_a?(self.class)

        pin == other.pin && derived? == other.derived?
      end

      # Alias for == to ensure Set functionality works correctly
      alias eql? ==

      # Custom hash implementation for use in collections
      #
      # @return [Integer] hash value
      def hash
        [self.class, pin, derived?].hash
      end

      # Validate EPIN string format
      #
      # @param string [String] string to validate
      # @raise [ArgumentError] if string doesn't match EPIN pattern or has multiple markers
      def self.validate_epin_string(string)
        raise ::ArgumentError, format(ERROR_INVALID_EPIN, string) unless string.match?(EPIN_PATTERN)

        # Check for multiple derivation markers
        marker_count = string.count(DERIVATION_MARKER)
        return unless marker_count > 1

        raise ::ArgumentError, format(ERROR_MULTIPLE_MARKERS, string)
      end

      private_class_method :validate_epin_string
    end
  end
end
