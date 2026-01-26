# frozen_string_literal: true

require_relative "argument/messages"

module Sashite
  module Epin
    module Errors
      # Error raised when EPIN parsing or validation fails.
      #
      # @example
      #   raise Argument, Argument::Messages::INVALID_DERIVATION_MARKER
      class Argument < ::ArgumentError
      end
    end
  end
end
