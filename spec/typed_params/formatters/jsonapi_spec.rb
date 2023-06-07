# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TypedParams::Formatters::JSONAPI do
  let :schema do
    TypedParams::Schema.new(type: :hash) do
      format :jsonapi

      param :meta, type: :hash, allow_non_scalars: true, optional: true
      param :data, type: :hash do
        param :type, type: :string, inclusion: { in: %w[users user] }
        param :id, type: :string
        param :attributes, type: :hash do
          param :first_name, type: :string, optional: true
          param :last_name, type: :string, optional: true
          param :email, type: :string, format: { with: /@/ }
          param :password, type: :string
        end
        param :relationships, type: :hash do
          param :inviter, type: :hash do
            param :data, type: :hash do
              param :type, type: :string, inclusion: { in: %w[users user] }
              param :id, type: :string
            end
          end
          param :note, type: :hash do
            param :data, type: :hash do
              param :type, type: :string, inclusion: { in: %w[notes note] }
              param :id, type: :string
              param :attributes, type: :hash, optional: true do
                param :content, type: :string, length: { minimum: 80 }
              end
            end
          end
          param :team, type: :hash do
            param :data, type: :hash do
              param :type, type: :string, inclusion: { in: %w[teams team] }
              param :id, type: :string
            end
          end
          param :posts, type: :hash do
            param :data, type: :array do
              items type: :hash do
                param :type, type: :string, inclusion: { in: %w[posts post] }
                param :id, type: :string
                param :attributes, type: :hash, optional: true do
                  param :title, type: :string, length: { maximum: 80 }
                  param :content, type: :string, length: { minimum: 80 }, optional: true
                end
              end
            end
          end
          param :friends, type: :hash do
            param :data, type: :array do
              items type: :hash do
                param :type, type: :string, inclusion: { in: %w[users user] }
                param :id, type: :string
              end
            end
          end
        end
      end
    end
  end

  let :data do
    {
      type: 'users',
      id: SecureRandom.base58,
      attributes: {
        email: 'foo@keygen.example',
        password: SecureRandom.hex,
      },
      relationships: {
        inviter: {
          data: { type: 'users', id: SecureRandom.base58 },
        },
        note: {
          data: { type: 'notes', id: SecureRandom.base58, attributes: { content: 'Test' } },
        },
        team: {
          data: { type: 'teams', id: SecureRandom.base58 },
        },
        posts: {
          data: [
            { type: 'posts', id: SecureRandom.base58 },
            { type: 'posts', id: SecureRandom.base58, attributes: { title: 'Testing! 1, 2, 3!' } },
            { type: 'posts', id: SecureRandom.base58 },
            { type: 'posts', id: SecureRandom.base58 },
          ],
        },
        friends: {
          data: [
            { type: 'users', id: SecureRandom.base58 },
            { type: 'users', id: SecureRandom.base58 },
          ],
        },
      },
    }
  end

  let :meta do
    {
      key: {
        key: 'value',
      },
    }
  end

  it 'should format params' do
    params = TypedParams::Parameterizer.new(schema:).call(value: { meta:, data: })

    expect(params.unwrap).to eq(
      id: data[:id],
      email: data[:attributes][:email],
      password: data[:attributes][:password],
      inviter_type: data[:relationships][:inviter][:data][:type].classify,
      inviter_id: data[:relationships][:inviter][:data][:id],
      note_attributes: {
        id: data[:relationships][:note][:data][:id],
        content: data[:relationships][:note][:data][:attributes][:content],
      },
      team_id: data[:relationships][:team][:data][:id],
      posts_attributes: [
        { id: data[:relationships][:posts][:data][0][:id] },
        { id: data[:relationships][:posts][:data][1][:id], title: data[:relationships][:posts][:data][1][:attributes][:title] },
        { id: data[:relationships][:posts][:data][2][:id] },
        { id: data[:relationships][:posts][:data][3][:id] },
      ],
      friend_ids: [
        data[:relationships][:friends][:data][0][:id],
        data[:relationships][:friends][:data][1][:id],
      ],
    )
  end

  it 'should not format params' do
    params = TypedParams::Parameterizer.new(schema:).call(value: { meta:, data: })

    expect(params.unwrap(formatter: nil)).to eq(
      meta:,
      data:,
    )
  end

  context 'when formatting linkage' do
    let :schema do
      TypedParams::Schema.new(type: :hash) do
        format :jsonapi

        param :data, type: :hash do
          param :type, type: :string, inclusion: { in: %w[users user] }
          param :id, type: :string, optional: true
        end
      end
    end

    it 'should format full linkage' do
      data   = { type: 'user', id: SecureRandom.base58 }
      params = TypedParams::Parameterizer.new(schema:).call(value: { data: })

      expect(params.unwrap).to eq(data.slice(:id))
    end

    it 'should format partial linkage' do
      data   = { type: 'user' }
      params = TypedParams::Parameterizer.new(schema:).call(value: { data: })

      expect(params.unwrap).to be_empty
    end
  end
end