# frozen_string_literal: true

module Sashite
  module Epin
    module Errors
      class Argument < ::ArgumentError
        # Centralized error messages for EPIN parsing and validation.
        #
        # PIN-related errors (empty input, must contain exactly one letter, etc.)
        # are propagated from the sashite-pin dependency.
        #
        # @example
        #   raise Errors::Argument, Messages::INVALID_DERIVATION_MARKER
        module Messages
          # Parsing error
          INVALID_DERIVATION_MARKER = "invalid derivation marker"

          # Validation errors (constructor)
          INVALID_PIN = "pin must be a Sashite::Pin::Identifier"
          INVALID_DERIVED = "derived must be true or false"
        end
      end
    end
  end
end
