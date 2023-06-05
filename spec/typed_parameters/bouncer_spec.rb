# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TypedParameters::Bouncer do
  context 'with lenient schema' do
    it 'should bounce params with :if guard' do
      schema = TypedParameters::Schema.new type: :hash, strict: false do
        param :foo, type: :integer, if: :admin?
        param :bar, type: :integer, unless: :admin?
      end

      controller = Class.new(ActionController::Base) { def admin? = false }.new
      params     = TypedParameters::Parameterizer.new(schema:).call(value: { foo: 1, bar: 2 })
      bouncer    = TypedParameters::Bouncer.new(controller:, schema:)

      bouncer.call(params)

      expect(params).to_not have_keys :foo
      expect(params).to have_keys :bar
    end

    it 'should bounce params with :unless guard' do
      schema = TypedParameters::Schema.new type: :hash, strict: false do
        param :foo, type: :integer, if: -> { admin? }
        param :bar, type: :integer, unless: -> { admin? }
      end

      controller = Class.new(ActionController::Base) { def admin? = true }.new
      params     = TypedParameters::Parameterizer.new(schema:).call(value: { foo: 1, bar: 2 })
      bouncer    = TypedParameters::Bouncer.new(controller:, schema:)

      bouncer.call(params)

      expect(params).to have_keys :foo
      expect(params).to_not have_keys :bar
    end

    it 'should raise for invalid guard' do
      schema     = TypedParameters::Schema.new(type: :hash, strict: false) { param :foo, type: :integer, if: 'foo?' }
      controller = Class.new(ActionController::Base).new
      params     = TypedParameters::Parameterizer.new(schema:).call(value: { foo: 1 })
      bouncer    = TypedParameters::Bouncer.new(controller:, schema:)

      expect { bouncer.call(params) }.to raise_error TypedParameters::InvalidMethodError
    end

    it 'should not bounce branches' do
      schema = TypedParameters::Schema.new type: :hash, strict: false do
        param :user, type: :hash, if: -> { true } do
          param :email, type: :string
          param :roles, type: :array, if: :admin? do
            items type: :string
          end
        end
      end

      controller = Class.new(ActionController::Base) { def admin? = true }.new
      user       = { user: { email: 'foo@keygen.example', roles: %w[admin] } }
      params     = TypedParameters::Parameterizer.new(schema:).call(value: user)
      bouncer    = TypedParameters::Bouncer.new(controller:, schema:)

      bouncer.call(params)

      expect(params.unwrap).to eq user
    end

    it 'should bounce branches' do
      schema = TypedParameters::Schema.new type: :hash, strict: false do
        param :user, type: :hash, if: -> { true } do
          param :email, type: :string
          param :roles, type: :array, if: :admin? do
            items type: :string
          end
        end
      end

      controller = Class.new(ActionController::Base) { def admin? = false }.new
      params     = TypedParameters::Parameterizer.new(schema:).call(value: { user: { email: 'foo@keygen.example', roles: %w[admin] } })
      bouncer    = TypedParameters::Bouncer.new(controller:, schema:)

      bouncer.call(params)

      expect(params.unwrap).to eq user: { email: 'foo@keygen.example' }
    end

    it 'should bounce group' do
      schema = TypedParameters::Schema.new type: :hash, strict: false do
        param :user, type: :hash, unless: -> { false } do
          param :first_name, type: :string
          param :last_name, type: :string
          with if: :admin? do
            param :password, type: :string
            param :roles, type: :array do
              items type: :string
            end
          end
          param :email, type: :string
        end
      end

      controller = Class.new(ActionController::Base) { def admin? = false }.new
      bouncer    = TypedParameters::Bouncer.new(controller:, schema:)
      params     = TypedParameters::Parameterizer.new(schema:).call(
        value: {
          user: {
            first_name: 'John',
            last_name: 'Doe',
            email: 'foo@keygen.example',
            password: 'secret',
            roles: %w[admin],
          },
        },
      )

      bouncer.call(params)

      expect(params.unwrap).to eq user: {
        first_name: 'John',
        last_name: 'Doe',
        email: 'foo@keygen.example',
      }
    end
  end

  context 'with strict schema' do
    it 'should bounce params with :if guard' do
      schema = TypedParameters::Schema.new type: :hash, strict: true do
        param :foo, type: :integer, if: :admin?
        param :bar, type: :integer, unless: :admin?
      end

      controller = Class.new(ActionController::Base) { def admin? = false }.new
      params     = TypedParameters::Parameterizer.new(schema:).call(value: { foo: 1, bar: 2 })
      bouncer    = TypedParameters::Bouncer.new(controller:, schema:)

      expect { bouncer.call(params) }.to raise_error { |err|
        expect(err).to be_a TypedParameters::UnpermittedParameterError
        expect(err.path.to_json_pointer).to eq '/foo'
      }
    end

    it 'should bounce params with :unless guard' do
      schema = TypedParameters::Schema.new type: :hash, strict: true do
        param :foo, type: :integer, if: -> { admin? }
        param :bar, type: :integer, unless: -> { admin? }
      end

      controller = Class.new(ActionController::Base) { def admin? = true }.new
      params     = TypedParameters::Parameterizer.new(schema:).call(value: { foo: 1, bar: 2 })
      bouncer    = TypedParameters::Bouncer.new(controller:, schema:)

      expect { bouncer.call(params) }.to raise_error { |err|
        expect(err).to be_a TypedParameters::UnpermittedParameterError
        expect(err.path.to_json_pointer).to eq '/bar'
      }
    end

    it 'should raise for invalid guard' do
      schema     = TypedParameters::Schema.new(type: :hash, strict: true) { param :foo, type: :integer, if: false }
      controller = Class.new(ActionController::Base).new
      params     = TypedParameters::Parameterizer.new(schema:).call(value: { foo: 1 })
      bouncer    = TypedParameters::Bouncer.new(controller:, schema:)

      expect { bouncer.call(params) }.to raise_error TypedParameters::InvalidMethodError
    end

    it 'should not bounce branches' do
      schema = TypedParameters::Schema.new type: :hash, strict: true do
        param :user, type: :hash, if: -> { true } do
          param :email, type: :string
          param :roles, type: :array, if: :admin? do
            items type: :string
          end
        end
      end

      controller = Class.new(ActionController::Base) { def admin? = true }.new
      user       = { user: { email: 'foo@keygen.example', roles: %w[admin] } }
      params     = TypedParameters::Parameterizer.new(schema:).call(value: user)
      bouncer    = TypedParameters::Bouncer.new(controller:, schema:)

      expect { bouncer.call(params) }.to_not raise_error
    end

    it 'should bounce branches' do
      schema = TypedParameters::Schema.new type: :hash, strict: true do
        param :user, type: :hash, if: -> { true } do
          param :email, type: :string
          param :roles, type: :array, if: :admin? do
            items type: :string
          end
        end
      end

      controller = Class.new(ActionController::Base) { def admin? = false }.new
      params     = TypedParameters::Parameterizer.new(schema:).call(value: { user: { email: 'foo@keygen.example', roles: %w[admin] } })
      bouncer    = TypedParameters::Bouncer.new(controller:, schema:)

      expect { bouncer.call(params) }.to raise_error { |err|
        expect(err).to be_a TypedParameters::UnpermittedParameterError
        expect(err.path.to_json_pointer).to eq '/user/roles'
      }
    end

    it 'should bounce group' do
      schema = TypedParameters::Schema.new type: :hash, strict: true do
        param :user, type: :hash, unless: -> { false } do
          param :first_name, type: :string
          param :last_name, type: :string
          with if: :admin? do
            param :password, type: :string
            param :roles, type: :array do
              items type: :string
            end
          end
          param :email, type: :string
        end
      end

      controller = Class.new(ActionController::Base) { def admin? = false }.new
      bouncer    = TypedParameters::Bouncer.new(controller:, schema:)
      params     = TypedParameters::Parameterizer.new(schema:).call(
        value: {
          user: {
            first_name: 'John',
            last_name: 'Doe',
            email: 'foo@keygen.example',
            password: 'secret',
            roles: %w[admin],
          },
        },
      )

      expect { bouncer.call(params) }.to raise_error { |err|
        expect(err).to be_a TypedParameters::UnpermittedParameterError
        expect(err.path.to_json_pointer).to eq '/user/password'
      }
    end
  end

  context 'with :params source' do
    let(:schema)     { TypedParameters::Schema.new(type: :array, source: :params, if: :allowed?) }
    let(:controller) { Class.new(ActionController::Base) { def allowed? = false }.new }

    it 'should have a correct source' do
      params     = TypedParameters::Parameterizer.new(schema:).call(value: [])
      bouncer    = TypedParameters::Bouncer.new(controller:, schema:)

      expect { bouncer.call(params) }.to raise_error { |err|
        expect(err).to be_a TypedParameters::UnpermittedParameterError
        expect(err.source).to eq :params
      }
    end
  end

  context 'with :query source' do
    let(:schema)     { TypedParameters::Schema.new(type: :array, source: :query, if: :allowed?) }
    let(:controller) { Class.new(ActionController::Base) { def allowed? = false }.new }

    it 'should have a correct source' do
      params     = TypedParameters::Parameterizer.new(schema:).call(value: [])
      bouncer    = TypedParameters::Bouncer.new(controller:, schema:)

      expect { bouncer.call(params) }.to raise_error { |err|
        expect(err).to be_a TypedParameters::UnpermittedParameterError
        expect(err.source).to eq :query
      }
    end
  end

  context 'with nil source' do
    let(:schema)     { TypedParameters::Schema.new(type: :array, if: :allowed?) }
    let(:controller) { Class.new(ActionController::Base) { def allowed? = false }.new }

    it 'should have a correct source' do
      params     = TypedParameters::Parameterizer.new(schema:).call(value: [])
      bouncer    = TypedParameters::Bouncer.new(controller:, schema:)

      expect { bouncer.call(params) }.to raise_error { |err|
        expect(err).to be_a TypedParameters::UnpermittedParameterError
        expect(err.source).to be nil
      }
    end
  end
end