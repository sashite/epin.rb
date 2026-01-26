# frozen_string_literal: true

require_relative "constants"
require_relative "errors"

module Sashite
  module Epin
    # Parser for EPIN (Extended Piece Identifier Notation) strings.
    #
    # This parser extracts the derivation marker and delegates PIN parsing
    # to the sashite-pin library.
    #
    # @example
    #   Parser.parse("K")    # => { pin: { abbr: :K, side: :first, ... }, derived: false }
    #   Parser.parse("K^'")  # => { pin: { abbr: :K, side: :first, ..., terminal: true }, derived: true }
    #
    # @see https://sashite.dev/specs/epin/1.0.0/
    module Parser
      # Parses an EPIN string into its components.
      #
      # @param input [String] The EPIN string to parse
      # @return [Hash] A hash with :pin (PIN components hash) and :derived keys
      # @raise [Errors::Argument] If the input is not a valid EPIN string
      def self.parse(input)
        validate_string!(input)

        derived = has_derivation_marker?(input)

        if derived
          validate_derivation_marker!(input)
          pin_string = input.chop
        else
          pin_string = input
        end

        pin_components = parse_pin_component(pin_string)

        { pin: pin_components, derived: derived }
      end

      # Validates an EPIN string without raising an exception.
      #
      # @param input [String] The EPIN string to validate
      # @return [Boolean] true if valid, false otherwise
      def self.valid?(input)
        return false unless ::String === input

        parse(input)
        true
      rescue Errors::Argument
        false
      end

      class << self
        private

        # Validates that input is a String.
        #
        # @param input [Object] The input to validate
        # @raise [Errors::Argument] If input is not a String
        def validate_string!(input)
          return if ::String === input

          raise Errors::Argument, "invalid PIN component: must contain exactly one letter"
        end

        # Checks if the input contains a derivation marker.
        #
        # @param input [String] The input to check
        # @return [Boolean] true if contains derivation marker
        def has_derivation_marker?(input)
          input.include?(Constants::DERIVATION_SUFFIX)
        end

        # Validates derivation marker position and uniqueness.
        #
        # @param input [String] The input to validate
        # @raise [Errors::Argument] If derivation marker is invalid
        def validate_derivation_marker!(input)
          count = input.count(Constants::DERIVATION_SUFFIX)
          last_char = input[-1]

          return if count == 1 && last_char == Constants::DERIVATION_SUFFIX

          raise Errors::Argument, Errors::Argument::Messages::INVALID_DERIVATION_MARKER
        end

        # Parses the PIN component using sashite-pin.
        #
        # @param pin_string [String] The PIN string to parse
        # @return [Hash] PIN components hash
        # @raise [Errors::Argument] If PIN parsing fails
        def parse_pin_component(pin_string)
          ::Sashite::Pin::Parser.parse(pin_string)
        rescue ::Sashite::Pin::Errors::Argument => e
          raise Errors::Argument, "invalid PIN component: #{e.message}"
        end
      end
    end
  end
end
