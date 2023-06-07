# frozen_string_literal: true

module TypedParams
  module Types
    register(:number,
      match: -> v { v.is_a?(Numeric) },
      abstract: true,
    )
  end
end
