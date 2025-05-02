# frozen_string_literal: true

module TypedParams
  module Types
    register(:any,
      abstract: true,
      match: -> _ {},
    )
  end
end
