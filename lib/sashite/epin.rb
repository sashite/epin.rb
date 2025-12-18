# frozen_string_literal: true

require "sashite/pin"

module Sashite
  # EPIN (Extended Piece Identifier Notation) implementation for Ruby.
  #
  # EPIN extends PIN by adding a **derivation marker** to track piece style
  # in cross-style games.
  #
  # **EPIN is simply: PIN + optional style derivation marker (`'`)**
  #
  # == Format
  #
  #   <pin-token>[<derivation-marker>]
  #
  # Where +<pin-token>+ is a valid PIN token and +<derivation-marker>+ is
  # an optional trailing apostrophe (<tt>'</tt>).
  #
  # == Five Fundamental Attributes
  #
  # EPIN exposes all five attributes from the SashitÃ© Game Protocol:
  #
  # - *Piece Name* â†' +epin.pin.type+
  # - *Piece Side* â†' +epin.pin.side+
  # - *Piece State* â†' +epin.pin.state+
  # - *Terminal Status* â†' +epin.pin.terminal+
  # - *Piece Style* â†' +epin.derived+ (native vs derived)
  #
  # == Examples
  #
  #   epin = Sashite::Epin.parse("K^'")
  #   epin.pin.type      # => :K
  #   epin.pin.terminal  # => true
  #   epin.derived       # => true
  #
  #   pin = Sashite::Pin.parse("K^")
  #   epin = Sashite::Epin.new(pin, derived: true)
  #   epin.to_s  # => "K^'"
  #
  #   Sashite::Epin.valid?("K^'")   # => true
  #   Sashite::Epin.valid?("K'^")   # => false
  #
  # See the EPIN Specification (https://sashite.dev/specs/epin/1.0.0/) for details.
  class Epin
    # Pattern for validating EPIN strings
    EPIN_PATTERN = /\A(?<pin>[-+]?[A-Za-z]\^?)(?<derived>')?\z/

    # @return [Sashite::Pin] The underlying PIN component
    attr_reader :pin

    # @return [Boolean] Derivation status (true = derived, false = native)
    attr_reader :derived

    # ========================================================================
    # Creation and Parsing
    # ========================================================================

    # Creates a new EPIN instance from a PIN component.
    #
    # @param pin [Sashite::Pin] The underlying PIN instance
    # @param derived [Boolean] Derivation status (default: false)
    # @return [Epin] A new frozen Epin instance
    #
    # @example
    #   pin = Sashite::Pin.parse("K^")
    #   Sashite::Epin.new(pin)
    #   # => #<Sashite::Epin K^>
    #
    #   Sashite::Epin.new(pin, derived: true)
    #   # => #<Sashite::Epin K^'>
    def initialize(pin, derived: false)
      raise ArgumentError, "Expected a Sashite::Pin instance, got: #{pin.inspect}" unless pin.is_a?(Pin)

      @pin = pin
      @derived = !!derived

      freeze
    end

    # Parses an EPIN string into an Epin instance.
    #
    # @param epin_string [String] The EPIN string to parse
    # @return [Epin] A new Epin instance
    # @raise [ArgumentError] If the string is not a valid EPIN
    #
    # @example
    #   Sashite::Epin.parse("K")
    #   # => #<Sashite::Epin K>
    #
    #   Sashite::Epin.parse("K'")
    #   # => #<Sashite::Epin K'>
    #
    #   Sashite::Epin.parse("+R^'")
    #   # => #<Sashite::Epin +R^'>
    #
    #   Sashite::Epin.parse("invalid")
    #   # => ArgumentError: Invalid EPIN string: invalid
    def self.parse(epin_string)
      raise ArgumentError, "Invalid EPIN string: #{epin_string.inspect}" unless epin_string.is_a?(String)

      match = EPIN_PATTERN.match(epin_string)
      raise ArgumentError, "Invalid EPIN string: #{epin_string}" unless match

      pin_string = match[:pin]
      derived_marker = match[:derived]

      pin = Pin.parse(pin_string)
      derived = derived_marker == "'"

      new(pin, derived: derived)
    end

    # Checks if a string is a valid EPIN notation.
    #
    # @param epin_string [String] The string to validate
    # @return [Boolean] true if valid, false otherwise
    #
    # @example
    #   Sashite::Epin.valid?("K")      # => true
    #   Sashite::Epin.valid?("K'")     # => true
    #   Sashite::Epin.valid?("+R^'")   # => true
    #   Sashite::Epin.valid?("K'^")    # => false
    #   Sashite::Epin.valid?("K''")    # => false
    #   Sashite::Epin.valid?("invalid") # => false
    def self.valid?(epin_string)
      return false unless epin_string.is_a?(String)

      EPIN_PATTERN.match?(epin_string)
    end

    # ========================================================================
    # Conversion
    # ========================================================================

    # Converts the Epin to its string representation.
    #
    # @return [String] The EPIN string
    #
    # @example
    #   pin = Sashite::Pin.parse("K^")
    #   Sashite::Epin.new(pin).to_s
    #   # => "K^"
    #
    #   Sashite::Epin.new(pin, derived: true).to_s
    #   # => "K^'"
    def to_s
      "#{pin}#{derivation_suffix}"
    end

    # ========================================================================
    # Transformations
    # ========================================================================

    # Returns a new Epin with a different PIN component.
    #
    # @param new_pin [Sashite::Pin] The new PIN component
    # @return [Epin] A new Epin with the specified PIN
    #
    # @example
    #   epin = Sashite::Epin.parse("K^'")
    #   new_pin = epin.pin.with_type(:Q)
    #   epin.with_pin(new_pin).to_s
    #   # => "Q^'"
    def with_pin(new_pin)
      return self if pin == new_pin

      self.class.new(new_pin, derived: derived)
    end

    # Returns a new Epin with a different derivation status.
    #
    # @param new_derived [Boolean] The new derivation status
    # @return [Epin] A new Epin with the specified derivation status
    #
    # @example
    #   epin = Sashite::Epin.parse("K^")
    #   epin.with_derived(true).to_s
    #   # => "K^'"
    #
    #   epin = Sashite::Epin.parse("K^'")
    #   epin.with_derived(false).to_s
    #   # => "K^"
    def with_derived(new_derived)
      return self if derived == !!new_derived

      self.class.new(pin, derived: !!new_derived)
    end

    # Returns a new Epin marked as derived.
    #
    # @return [Epin] A new Epin with derived: true
    #
    # @example
    #   epin = Sashite::Epin.parse("K^")
    #   epin.mark_derived.derived
    #   # => true
    def mark_derived
      return self if derived

      self.class.new(pin, derived: true)
    end

    # Returns a new Epin marked as native (not derived).
    #
    # @return [Epin] A new Epin with derived: false
    #
    # @example
    #   epin = Sashite::Epin.parse("K^'")
    #   epin.unmark_derived.derived
    #   # => false
    def unmark_derived
      return self unless derived

      self.class.new(pin, derived: false)
    end

    # ========================================================================
    # Queries
    # ========================================================================

    # Checks if the Epin is derived (uses opponent's style).
    #
    # @return [Boolean] true if derived
    #
    # @example
    #   Sashite::Epin.parse("K^'").derived?  # => true
    #   Sashite::Epin.parse("K^").derived?   # => false
    def derived?
      derived
    end

    # Checks if the Epin is native (uses own side's style).
    #
    # @return [Boolean] true if native
    #
    # @example
    #   Sashite::Epin.parse("K^").native?   # => true
    #   Sashite::Epin.parse("K^'").native?  # => false
    def native?
      !derived
    end

    # Checks if two Epins have the same derivation status.
    #
    # @param other [Epin] The other Epin to compare
    # @return [Boolean] true if same derivation status
    #
    # @example
    #   epin1 = Sashite::Epin.parse("K^'")
    #   epin2 = Sashite::Epin.parse("Q'")
    #   epin1.same_derived?(epin2)
    #   # => true
    #
    #   epin3 = Sashite::Epin.parse("K^")
    #   epin1.same_derived?(epin3)
    #   # => false
    def same_derived?(other)
      derived == other.derived
    end

    # ========================================================================
    # Comparison
    # ========================================================================

    # Checks equality with another Epin.
    #
    # @param other [Object] The object to compare
    # @return [Boolean] true if equal
    def ==(other)
      return false unless other.is_a?(self.class)

      pin == other.pin && derived == other.derived
    end

    alias eql? ==

    # Returns a hash code for the Epin.
    #
    # @return [Integer] Hash code
    def hash
      [pin, derived].hash
    end

    # Returns an inspect string for the Epin.
    #
    # @return [String] Inspect representation
    def inspect
      "#<#{self.class} #{self}>"
    end

    private

    # Returns the derivation suffix for string representation.
    #
    # @return [String] "'" if derived, "" otherwise
    def derivation_suffix
      derived ? "'" : ""
    end
  end
end
