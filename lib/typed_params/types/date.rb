# frozen_string_literal: true

module TypedParams
  module Types
    register(:date,
      coerce: -> v { v.blank? ? nil : v.to_date },
      match: -> v { v.is_a?(Date) },
    )
  end
end
