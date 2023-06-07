# frozen_string_literal: true

module TypedParams
  module Types
    register(:string,
      coerce: -> v { v.to_s },
      match: -> v { v.is_a?(String) },
    )
  end
end
