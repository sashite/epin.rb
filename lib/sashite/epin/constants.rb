# frozen_string_literal: true

module Sashite
  module Epin
    # Constants for EPIN (Extended Piece Identifier Notation).
    #
    # EPIN extends PIN with a single derivation marker.
    # PIN constants (VALID_ABBRS, VALID_SIDES, VALID_STATES, etc.)
    # are accessed through the sashite-pin dependency.
    module Constants
      # Derivation marker suffix.
      DERIVATION_SUFFIX = "'"

      # Maximum length of a valid EPIN string: [+-]?[A-Za-z]\^?'?
      MAX_STRING_LENGTH = 4

      # Total number of valid EPIN tokens (312 PIN tokens × 2 derivation statuses).
      POOL_SIZE = 624
    end
  end
end
