# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TypedParameters::Pipeline do
  it 'should reduce the pipeline steps in order' do
    pipeline = TypedParameters::Pipeline.new
    input    = 1

    pipeline << -> v { v += 1 }
    pipeline << -> v { v -= 2 }
    pipeline << -> v { v *= 3 }

    output = pipeline.call(input)

    expect(output).to eq 0
  end
end