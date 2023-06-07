# frozen_string_literal: true

module TypedParams
  module Types
    register(:symbol,
      coerce: -> v { v.to_sym },
      match: -> v { v.is_a?(Symbol) },
    )
  end
end
