# frozen_string_literal: true

require "sashite/pin"

require_relative "constants"
require_relative "errors"
require_relative "identifier"

module Sashite
  module Epin
    # Parser for EPIN (Extended Piece Identifier Notation) strings.
    #
    # Dual-path architecture for performance:
    # - {safe_parse}: core path — returns a cached Identifier or nil.
    #   Never raises, never allocates exceptions, never captures backtraces.
    # - {parse}: public API — delegates to safe_parse, raises once at boundary on failure.
    # - {valid?}: boolean wrapper around safe_parse — never raises.
    #
    # @example
    #   Parser.safe_parse("K^'")  # => #<Sashite::Epin::Identifier K^'>
    #   Parser.safe_parse("bad")  # => nil
    #   Parser.parse("K^'")      # => #<Sashite::Epin::Identifier K^'>
    #   Parser.valid?("K^'")     # => true
    #
    # @see https://sashite.dev/specs/epin/1.0.0/
    module Parser
      # ASCII byte value of the derivation marker.
      APOSTROPHE_BYTE = 39 # ' = 0x27

      private_constant :APOSTROPHE_BYTE

      # Parses an EPIN string without raising an exception.
      # This is the core parsing path — all other methods delegate here.
      #
      # @param input [String] The EPIN string to parse
      # @return [Identifier, nil] A cached Identifier on success, nil on failure
      def self.safe_parse(input)
        return nil unless ::String === input

        len = input.bytesize
        return nil if len == 0 || len > Constants::MAX_STRING_LENGTH

        # Check derivation marker: single byte check on last position.
        if input.getbyte(len - 1) == APOSTROPHE_BYTE
          pin = ::Sashite::Pin.safe_parse(input.byteslice(0, len - 1))
          return nil if pin.nil?

          Identifier.fetch(pin, true)
        else
          pin = ::Sashite::Pin.safe_parse(input)
          return nil if pin.nil?

          Identifier.fetch(pin, false)
        end
      end

      # Parses an EPIN string into a cached Identifier.
      # Delegates to {safe_parse} for the happy path.
      # On failure, performs detailed validation to raise a precise error.
      #
      # @param input [String] The EPIN string to parse
      # @return [Identifier] A cached Identifier
      # @raise [Errors::Argument] If the input is not a valid EPIN string
      def self.parse(input)
        result = safe_parse(input)
        return result unless result.nil?

        # Slow path: detailed validation for precise error messages.
        raise_parse_error!(input)
      end

      # Validates an EPIN string without raising an exception.
      #
      # @param input [String] The EPIN string to validate
      # @return [Boolean] true if valid, false otherwise
      def self.valid?(input)
        !safe_parse(input).nil?
      end

      class << self
        private

        # Performs detailed validation on an already-known-invalid input
        # to produce a precise error message.
        #
        # @param input [Object] The invalid input
        # @raise [Errors::Argument] Always raises with a descriptive message
        def raise_parse_error!(input)
          unless ::String === input
            raise Errors::Argument, "invalid PIN component: must contain exactly one letter"
          end

          # Check derivation marker issues first.
          if input.include?(Constants::DERIVATION_SUFFIX)
            count = input.count(Constants::DERIVATION_SUFFIX)

            unless count == 1 && input.getbyte(input.bytesize - 1) == APOSTROPHE_BYTE
              raise Errors::Argument, Errors::Argument::Messages::INVALID_DERIVATION_MARKER
            end

            pin_string = input.chop
          else
            pin_string = input
          end

          # Delegate to PIN's raising parser for a precise PIN error message.
          begin
            ::Sashite::Pin::Parser.parse(pin_string)
          rescue ::Sashite::Pin::Errors::Argument => e
            raise Errors::Argument, "invalid PIN component: #{e.message}"
          end

          # Unreachable in normal operation: if safe_parse returned nil,
          # one of the checks above should have raised. Guard against edge cases.
          raise Errors::Argument, "invalid EPIN token"
        end
      end
    end
  end
end
