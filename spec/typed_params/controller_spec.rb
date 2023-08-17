# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TypedParams::Controller do
  subject {
    Class.new ActionController::Base do
      @controller_name = 'users'
      include TypedParams::Controller
    end
  }

  it 'should not raise when included in Metal controller' do
    expect { Class.new(ActionController::Metal) { include TypedParams::Controller } }
      .to_not raise_error
  end

  it 'should not raise when included in Base controller' do
    expect { Class.new(ActionController::Base) { include TypedParams::Controller } }
      .to_not raise_error
  end

  it 'should not raise when included in API controller' do
    expect { Class.new(ActionController::API) { include TypedParams::Controller } }
      .to_not raise_error
  end

  it 'should raise when included outside controller' do
    expect { Class.new { include TypedParams::Controller } }
      .to raise_error ArgumentError
  end

  it 'should raise when duplicate schema is defined' do
    subject.typed_schema(:foo) { param :bar, type: :string }

    expect { subject.typed_schema(:foo) { param :baz, type: :string } }
      .to raise_error ArgumentError
  end

  it 'should define local schema' do
    subject.typed_schema(:foo) { param :bar, type: :string }

    expect(subject.typed_schemas[subject, :foo]).to be_a TypedParams::Schema
  end

  it 'should support inherited schema' do
    subject.typed_schema(:foo) { param :bar, type: :string }
    child = Class.new(subject)

    expect(child.typed_schemas[child, :foo]).to eq subject.typed_schemas[subject, :foo]
  end

  it 'should define global schema' do
    subject.typed_schema(:foo, namespace: nil) { param :bar, type: :string }

    expect(subject.typed_schemas[nil, :foo]).to be_a TypedParams::Schema
  end

  it 'should define namespaced schema' do
    subject.typed_schema(:foo, namespace: :bar) { param :baz, type: :string }

    expect(subject.typed_schemas[:bar, :foo]).to be_a TypedParams::Schema
  end

  it 'should define singular params handler' do
    subject.typed_params(on: :foo) { param :bar, type: :string }

    expect(subject.typed_handlers.params[subject, :foo]).to be_a TypedParams::Handler
  end

  it 'should define multiple params handlers' do
    subject.typed_params(on: %i[foo bar baz]) { param :qux, type: :string }

    params = subject.typed_handlers.params

    expect(params[subject, :foo]).to be_a TypedParams::Handler
    expect(params[subject, :bar]).to be_a TypedParams::Handler
    expect(params[subject, :baz]).to be_a TypedParams::Handler
  end

  it 'should support inherited params' do
    subject.typed_params(on: :foo) { param :bar, type: :string }
    child = Class.new(subject)

    expect(child.typed_handlers.params[child, :foo]).to eq subject.typed_handlers.params[subject, :foo]
  end

  it 'should define singular query param handler' do
    subject.typed_query(on: :foo) { param :bar, type: :string }

    expect(subject.typed_handlers.query[subject, :foo]).to be_a TypedParams::Handler
  end

  it 'should define multiple query param handlers' do
    subject.typed_query(on: %i[foo bar baz]) { param :qux, type: :string }

    query = subject.typed_handlers.query

    expect(query[subject, :foo]).to be_a TypedParams::Handler
    expect(query[subject, :bar]).to be_a TypedParams::Handler
    expect(query[subject, :baz]).to be_a TypedParams::Handler
  end

  it 'should support inherited query' do
    subject.typed_query(on: :foo) { param :bar, type: :string }
    child = Class.new(subject)

    expect(child.typed_handlers.query[child, :foo]).to eq subject.typed_handlers.query[subject, :foo]
  end

  context 'without inheritance' do
    describe '.typed_schema' do
      it('should respond') { expect(subject).to respond_to :typed_schema }
    end

    describe '.typed_params' do
      it('should respond') { expect(subject).to respond_to :typed_params }
    end

    describe '.typed_query' do
      it('should respond') { expect(subject).to respond_to :typed_query }
    end

    describe '#typed_params' do
      it('should respond') { expect(subject.new).to respond_to :typed_params }
    end

    describe '#x_params' do
      it('should respond') { expect(subject.new).to respond_to :user_params }
    end

    describe '#typed_query' do
      it('should respond') { expect(subject.new).to respond_to :typed_query }
    end

    describe '#x_query' do
      it('should respond') { expect(subject.new).to respond_to :user_query }
    end
  end

  context 'with inheritance' do
    subject {
      parent = Class.new ActionController::Base do
        @controller_name = 'base'
        include TypedParams::Controller
      end

      Class.new parent do
        @controller_name = 'users'
      end
    }

    describe '.typed_schema' do
      it('should respond') { expect(subject).to respond_to :typed_schema }
    end

    describe '.typed_params' do
      it('should respond') { expect(subject).to respond_to :typed_params }
    end

    describe '.typed_query' do
      it('should respond') { expect(subject).to respond_to :typed_query }
    end

    describe '#typed_params' do
      it('should respond') { expect(subject.new).to respond_to :typed_params }
    end

    describe '#x_params' do
      it('should not respond') { expect(subject.new).to_not respond_to :base_params }
      it('should respond') { expect(subject.new).to respond_to :user_params }
    end

    describe '#typed_query' do
      it('should respond') { expect(subject.new).to respond_to :typed_query }
    end

    describe '#x_query' do
      it('should not respond') { expect(subject.new).to_not respond_to :base_query }
      it('should respond') { expect(subject.new).to respond_to :user_query }
    end
  end
end

RSpec.describe 'controller', type: :controller do
  context 'with explicit action' do
    class self::UsersController < ActionController::Base; end

    controller self::UsersController do
      include TypedParams::Controller

      typed_schema :explicit do
        param :email, type: :string, format: { with: /@/ }
        param :password, type: :string, length: { minimum: 8 }
      end

      def create = render json: user_params
      typed_params schema: :explicit,
                   on: :create
    end

    it 'should not raise' do
      expect { post :create, params: { email: 'foo@example.com', password: SecureRandom.hex } }
        .to_not raise_error
    end

    it 'should raise' do
      expect { post :create, params: { email: 'foo', password: SecureRandom.hex } }
        .to raise_error TypedParams::InvalidParameterError
    end
  end

  context 'with deferred action' do
    class self::UsersController < ActionController::Base; end

    controller self::UsersController do
      include TypedParams::Controller

      typed_schema :deferred do
        param :email, type: :string, format: { with: /@/ }
        param :password, type: :string, length: { minimum: 8 }
      end

      typed_params schema: :deferred
      def create = render json: user_params
    end

    it 'should not raise' do
      expect { post :create, params: { email: 'bar@example.com', password: SecureRandom.hex } }
        .to_not raise_error
    end

    it 'should raise' do
      expect { post :create, params: { password: 'secret' } }
        .to raise_error TypedParams::InvalidParameterError
    end
  end

  context 'with multiple actions' do
    class self::UsersController < ActionController::Base; end

    controller self::UsersController do
      include TypedParams::Controller

      def create = render json: user_params
      def update = render json: user_params

      typed_params on: %i[create update] do
        param :email, type: :string, format: { with: /@/ }
        param :password, type: :string, length: { minimum: 8 }
      end
    end

    describe 'create' do
      it 'should not raise' do
        expect { post :create, params: { email: 'bar@example.com', password: SecureRandom.hex } }
          .to_not raise_error
      end

      it 'should raise' do
        expect { post :create, params: { password: 'secret' } }
          .to raise_error TypedParams::InvalidParameterError
      end
    end

    describe 'update' do
      it 'should not raise' do
        expect { patch :update, params: { id: 1, email: 'bar@example.com', password: SecureRandom.hex } }
          .to_not raise_error
      end

      it 'should raise' do
        expect { patch :update, params: { id: 1, password: 'secret' } }
          .to raise_error TypedParams::InvalidParameterError
      end
    end
  end

  context 'with no schema' do
    class self::UsersController < ActionController::Base; end

    controller self::UsersController do
      include TypedParams::Controller

      def create = render json: user_params
    end

    it 'should raise' do
      expect { post :create }
        .to raise_error TypedParams::UndefinedActionError
    end
  end

  context 'with multiple schemas' do
    class self::MentionsController < ActionController::Base; end

    controller self::MentionsController do
      include TypedParams::Controller

      typed_query { param :dry_run, type: :boolean, optional: true }
      typed_params do
        param :username, type: :string, format: { with: /^@/ }
      end
      def create = render json: { params: mention_params, query: mention_query }
    end

    it 'should have correct params' do
      params = { username: "@#{SecureRandom.hex}" }
      query  = { dry_run: true }

      # FIXME(ezekg) There doesn't seem to be any other way to specify
      #              POST body and query parameters separately in a
      #              test request. Thus, we have this hack.
      allow_any_instance_of(request.class).to receive(:request_parameters).and_return(params)
      allow_any_instance_of(request.class).to receive(:query_parameters).and_return(query)

      post :create

      body = JSON.parse(response.body, symbolize_names: true)

      # FIXME(ezekg) Use rails-controller-testing gem for assigns[]?
      expect(body[:params]).to eq params
      expect(body[:query]).to eq query
    end
  end

  context 'with JSONAPI schema' do
    class self::PostsController < ActionController::Base; end

    controller self::PostsController do
      include TypedParams::Controller

      typed_params {
        format :jsonapi

        param :meta, type: :array, optional: true do
          items type: :hash do
            param :footnote, type: :string
          end
        end

        param :data, type: :hash do
          param :type, type: :string, inclusion: { in: %w[posts] }
          param :id, type: :string
        end
      }
      def create
        render json: {
          data: post_params(format: nil)[:data],
          meta: post_meta,
          params: post_params,
        }
      end
    end

    it 'should have correct params' do
      meta = [{ footnote: '[1] foo' }, { footnote: '[2] bar' }]
      data = { type: 'posts', id: SecureRandom.base58 }

      post :create, params: { meta:, data: }

      body = JSON.parse(response.body, symbolize_names: true)

      # FIXME(ezekg) Use rails-controller-testing gem for assigns[]?
      expect(body[:params]).to eq data.slice(:id)
      expect(body[:meta]).to eq meta
      expect(body[:data]).to eq data
    end

    it 'should decorate controller' do
      expect(controller).to respond_to :typed_meta
      expect(controller).to respond_to :post_meta
    end
  end

  context 'with inherited schema' do
    class self::ApplicationController < ActionController::Base
      include TypedParams::Controller

      typed_schema :user do
        param :first_name, type: :string, optional: true
        param :last_name, type: :string, optional: true
        param :email, type: :string
        param :password, type: :string
      end
    end

    controller self::ApplicationController do
      typed_params schema: :user
      def create = render json: typed_params
    end

    it 'should be a valid schema' do
      user = {
        first_name: 'Jane',
        email: 'jane@doe.example',
        password: SecureRandom.hex,
      }

      post :create, params: user

      body = JSON.parse(response.body, symbolize_names: true)

      # FIXME(ezekg) Use rails-controller-testing gem for assigns[]?
      expect(body).to eq user
    end
  end

  context 'with namespaced schema' do
    module self::V1; end
    module self::V2; end

    class self::ApplicationController < ActionController::Base
      include TypedParams::Controller
    end

    class self::V1::UsersController < self::ApplicationController
      typed_schema :user, namespace: :v1 do
        param :first_name, type: :string, optional: true
        param :last_name, type: :string, optional: true
        param :email, type: :string
        param :password, type: :string
      end
    end

    class self::V2::UsersController < self::ApplicationController
      typed_params schema: %i[v1 user]
      def create = render json: typed_params
    end

    controller self::V2::UsersController do
    end

    it 'should be a valid schema' do
      user = {
        first_name: 'Jane',
        email: 'jane@doe.example',
        password: SecureRandom.hex,
      }

      post :create, params: user

      body = JSON.parse(response.body, symbolize_names: true)

      # FIXME(ezekg) Use rails-controller-testing gem for assigns[]?
      expect(body).to eq user
    end
  end

  context 'with key casing' do
    controller do
      include TypedParams::Controller

      typed_params casing: :underscore do
        param :parentKey, type: :hash do
          param :childKey, type: :string
        end
      end
      def create = render json: typed_params
    end

    it 'should have correct casing' do
      post :create, params: {
        parentKey: {
          childKey: 'value',
        }
      }

      body = JSON.parse(response.body, symbolize_names: true)

      # FIXME(ezekg) Use rails-controller-testing gem for assigns[]?
      expect(body).to eq parent_key: { child_key: 'value' }
    end
  end

  context 'with caching' do
    controller do
      include TypedParams::Controller

      typed_params { param :hex, type: :string }
      def create = render json: [typed_params, typed_params]
    end

    it 'should cache params' do
      expect(TypedParams::Processor).to receive(:new).exactly(3).times.and_call_original

      post :create, params: { hex: a = SecureRandom.hex }
      expect(response.body).to include a

      post :create, params: { hex: b = SecureRandom.hex }
      expect(response.body).to include b

      post :create, params: { hex: c = SecureRandom.hex }
      expect(response.body).to include c
    end
  end
end
