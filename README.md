# typed_params

[![CI](https://github.com/keygen-sh/typed_params/actions/workflows/test.yml/badge.svg)](https://github.com/keygen-sh/typed_params/actions)
[![Gem Version](https://badge.fury.io/rb/typed_params.svg)](https://badge.fury.io/rb/typed_params)

`typed_params` is an alternative to Rails strong parameters for controller params,
offering an intuitive DSL for defining structured and strongly-typed controller
parameter schemas for Rails APIs.

This gem was extracted from [Keygen](https://keygen.sh) and is being used in production
to serve millions of API requests per day.

Sponsored by:

[![Keygen logo](https://github.com/keygen-sh/typed_params/assets/6979737/f2947915-2956-4415-a9c0-5411c388ea96)](https://keygen.sh)

_An open, source-available software licensing and distribution API._

Links:

- [Installing `typed_params`](#installation)
- [Supported Ruby versions](#supported-rubies)
- [RubyDoc](#documentation)
- [Usage](#usage)
  - [Parameter schemas](#parameter-schemas)
  - [Query schemas](#query-schemas)
  - [Defining schemas](#defining-schemas)
  - [Shared schemas](#shared-schemas)
  - [Configuration](#configuration)
  - [Unpermitted parameters](#unpermitted-parameters)
  - [Invalid parameters](#invalid-parameters)
  - [Parameter options](#parameter-options)
  - [Shared options](#shared-options)
  - [Scalar types](#scalar-types)
  - [Non-scalar types](#non-scalar-types)
  - [Custom types](#custom-types)
- [Contributing](#contributing)
- [License](#license)

## Installation

Add this line to your application's `Gemfile`:

```ruby
gem 'typed_params'
```

And then execute:

```bash
$ bundle
```

Or install it yourself as:

```bash
$ gem install typed_params
```

## Supported Rubies

**`typed_params` supports Ruby 3.1 and above.** We encourage you to upgrade if you're
on an older version. Ruby 3 provides a lot of great features, like pattern matching and
a new shorthand hash syntax.

## Documentation

You can find the documentation on [RubyDoc](https://rubydoc.info/github/keygen-sh/typed_params).

_We're working on improving the docs._

## Features

- An intuitive DSL — a breath of fresh air coming from strong parameters.
- Define structured, strongly-typed parameter schemas for controllers.
- Reuse schemas across controllers by defining named schemas.
- Run validations on params, similar to active model validations.
- Run transforms on params before they hit your controller.

## Usage

`typed_params` can be used to define a parameter schema per-action
on controllers.

To start, include the controller module:

```ruby
class ApplicationController < ActionController::API
  include TypedParams::Controller
end
```

### Parameter schemas

To define a parameter schema, you can use the `.typed_params` method.
These parameters will be pulled from the request body. It accepts a
block containing the schema definition, as well as [options](#parameter-options).

The parameters will be available inside of the controller action with
the following methods:

- `#{controller_name.singularize}_params`
- `typed_params`

```ruby
class UsersController < ApplicationController
  typed_params {
    param :user, type: :hash do
      param :first_name, type: :string, optional: true
      param :last_name, type: :string, optional: true
      param :email, type: :string
      param :password, type: :string
      param :roles, type: :array, if: :admin? do
        items type: :string
      end
    end
  }
  def create
    user = User.new(user_params)

    if user.save
      render_created user, location: v1_user_url(user)
    else
      render_unprocessable_resource user
    end
  end
end
```

### Query schemas

To define a query schema, you can use the `.typed_query` method. These
parameters will be pulled from the request query parameters. It
accepts a block containing the schema definition.

The parameters will be available inside of the controller action with
the following methods:

- `#{controller_name.singularize}_query`
- `#typed_query`

```ruby
class PostsController < ApplicationController
  typed_query {
    param :limit, type: :integer, coerce: true, allow_nil: true, optional: true
    param :page, type: :integer, coerce: true, allow_nil: true, optional: true
  }
  def index
    posts = Post.paginate(
      post_query.fetch(:limit, 10),
      post_query.fetch(:page, 1),
    )

    render_ok posts
  end
end
```

### Defining schemas

The easiest way to define a schema is by decorating a specific controller action,
which we exemplified above. You can use `.typed_params` or `.typed_query` to
decorate a controller action.

```ruby
class PostsController < ApplicationController
  typed_params {
    param :author_id, type: :integer
    param :title, type: :string, length: { within: 10..80 }
    param :content, type: :string, length: { minimum: 100 }
    param :published_at, type: :time, optional: true, allow_nil: true
    param :tag_ids, type: :array, optional: true, length: { maximum: 10 } do
      items type: :integer
    end
  }
  def create
    # ...
  end
end
```

As an alternative to decorated schemas, you can define schemas after an action
has been defined.

```ruby
class PostsController < ApplicationController
  def create
    # ...
  end

  typed_params on: :create do
    param :author_id, type: :integer
    param :title, type: :string, length: { within: 10..80 }
    param :content, type: :string, length: { minimum: 100 }
    param :published_at, type: :time, optional: true, allow_nil: true
    param :tag_ids, type: :array, optional: true, length: { maximum: 10 } do
      items type: :integer
    end
  end
end
```

By default, all root schemas are a [`:hash`](#hash-type) schema. This is because both
`request.request_parameters` and `request.query_parameters` are hashes. Eventually,
we'd like [to make that configurable](https://github.com/keygen-sh/typed_params/blob/67e9a34ce62c9cddbd2bd313e4e9f096f8744b83/lib/typed_params/controller.rb#L24-L27),
so that you could use a top-level array schema. You can create nested schemas via
the [`:hash`](#hash-type) and [`:array`](#array-type) types.

### Shared schemas

If you need to share a specific schema between multiple actions, you can define
a named schema.

```ruby
class PostsController < ApplicationController
  typed_schema :post do
    param :author_id, type: :integer
    param :title, type: :string, length: { within: 10..80 }
    param :content, type: :string, length: { minimum: 100 }
    param :published_at, type: :time, optional: true, allow_nil: true
    param :tag_ids, type: :array, optional: true, length: { maximum: 10 } do
      items type: :integer
    end
  end

  typed_params schema: :post
  def create
    # ...
  end

  typed_params schema: :post
  def update
    # ...
  end
end
```

### Configuration

```ruby
TypedParams.configure do |config|
  # Ignore nil params that are marked optional and non-nil in the schema.
  #
  # For example, given the following schema:
  #
  #   typed_params {
  #     param :optional_key, type: :string, optional: true
  #     param :required_key, type: :string
  #   }
  #
  # And the following curl request:
  #
  #   curl -X POST http://localhost:3000 -d '{"optional_key":null,"required_key":"value"}'
  #
  # Within the controller, the params would be:
  #
  #   puts typed_params # => { required_key: 'value' }
  #
  config.ignore_nil_optionals = true

  # Key transformation applied to the parameters after validation.
  #
  # One of:
  #
  #   - :underscore
  #   - :camel
  #   - :lower_camel
  #   - :dash
  #   - nil
  #
  # For example, given the following schema:
  #
  #   typed_params {
  #     param :someKey, type: :string
  #   }
  #
  # And the following curl request:
  #
  #   curl -X POST http://localhost:3000 -d '{"someKey":"value"}'
  #
  # Within the controller, the params would be:
  #
  #   puts typed_params # => { some_key: 'value' }
  #
  config.key_transform = :underscore

  # Path transformation applied to error paths e.g. UnpermittedParameterError.
  #
  # One of:
  #
  #   - :underscore
  #   - :camel
  #   - :lower_camel
  #   - :dash
  #   - nil
  #
  # For example, given the following schema:
  #
  #   typed_params {
  #     param :parent_key, type: :hash do
  #       param :child_key, type: :string
  #     end
  #   }
  #
  # With an invalid `child_key`, the path would be:
  #
  #   rescue_from TypedParams::UnpermittedParameterError, err -> {
  #     puts err.path.to_s # => parentKey.childKey
  #   }
  #
  config.path_transform = :lower_camel
end
```

### Unpermitted parameters

By default, `.typed_params` is [`:strict`](#strict-parameter). This means that if any unpermitted parameters
are provided, a `TypedParams::UnpermittedParameterError` will be raised.

For `.typed_query`, the default is non-strict. This means that any unpermitted parameters
will be ignored.

You can rescue this error at the application-level like so:

```ruby
class ApplicationController < ActionController::API
  rescue_from TypedParams::UnpermittedParameterError, err -> {
    render_bad_request "unpermitted parameter: #{err.path.to_jsonapi_pointer}"
  }
end
```

The `TypedParams::UnpermittedParameterError` error object has the following attributes:

- `#message` - the error message, e.g. `unpermitted parameter`.
- `#path` - a `Path` object with a pointer to the unpermitted parameter.
- `#source` - either `:params` or `:query`, depending on where the unpermitted parameter came from (i.e. request body vs URL, respectively).

### Invalid parameters

When a parameter is provided, but it fails validation (e.g. a type mismatch), a
`TypedParams::InvalidParameterError` error will be raised.

You can rescue this error at the application-level like so:

```ruby
class ApplicationController < ActionController::API
  rescue_from TypedParams::InvalidParameterError, err -> {
    render_bad_request "invalid parameter: #{err.message}", parameter: err.path.to_dot_notation
  }
end
```

The `TypedParams::InvalidParameterError` error object has the following attributes:

- `#message` - the error message, e.g. `type mismatch (received string expected integer)`.
- `#path` - a `Path` object with a pointer to the invalid parameter.
- `#source` - either `:params` or `:query`, depending on where the invalid parameter came from (i.e. request body vs URL, respectively).

### Parameter options

Parameters can have validations, transforms, and more.

- [`:key`](#parameter-key)
- [`:type`](#parameter-type)
- [`:strict`](#strict-parameter)
- [`:optional`](#optional-parameter)
- [`:if` and `:unless`](#conditional-parameter)
- [`:as`](#alias-parameter)
- [`:noop`](#noop-parameter)
- [`:coerce`](#coerced-parameter)
- [`:allow_blank`](#allow-blank)
- [`:allow_nil`](#allow-nil)
- [`:allow_non_scalars`](#allow-non-scalars)
- [`:nilify_blanks`](#nilify-blanks)
- [`:inclusion`](#inclusion-validation)
- [`:exclusion`](#exclusion-validation)
- [`:format`](#format-validation)
- [`:length`](#length-validation)
- [`:transform`](#transform-parameter)
- [`:validate`](#validate-parameter)

#### Parameter key

The parameter's key.

```ruby
param :foo
```

This is required.

#### Parameter type

The parameter's type. Please see [Types](#scalar-types) for more information. Some
types may accept a block, e.g. `:hash` and `:array`.

```ruby
param :email, type: :string
```

This is required.

#### Strict parameter

When `true`, a `TypedParams::UnpermittedParameterError` error is raised for
unpermitted parameters. When `false`, unpermitted parameters are ignored.

```ruby
param :user, type: :hash, strict: true do
  # ...
end
```

By default, the entire `.typed_params` schema is strict, and `.typed_query` is not.

#### Optional parameter

The parameter is optional. An invalid parameter error will not be raised in its absence.

```ruby
param :first_name, type: :string, optional: true
```

By default, parameters are required.

#### Conditional parameter

You can define conditional parameters using `:if` and `:unless`. The parameter will
only be evaluated when the condition to `true`.

```ruby
param :role, type: :string, if: -> { admin? }
param :role, type: :string, if: :admin?
param :role, type: :string, unless: -> { guest? }
param :role, type: :string, unless: :guest?
```

The lambda will be evaled within the current controller context.

#### Alias parameter

Apply a transformation that renames the parameter.

```ruby
param :user, type: :integer, as: :user_id

typed_params # => { user_id: '...' }
```

In this example, the parameter would be accepted as `:user`, but renamed
to `:user_id` for use inside of the controller.

#### Noop parameter

The parameter is accepted but immediately thrown out.

```ruby
param :foo, type: :string, noop: true
```

By default, this is `false`.

#### Coerced parameter

The parameter will be coerced if its type is coercible and the parameter has a
type mismatch. The coercion can fail, e.g. `:integer` to `:hash`, and if it does,
a `TypedParams::InvalidParameterError` will be raised.

```ruby
param :age, type: :integer, coerce: true
```

The default is `false`.

#### Allow blank

The parameter can be `#blank?`.

```ruby
param :title, type: :string, allow_blank: true
```

By default, blank params are rejected with a `TypedParams::InvalidParameterError`
error.

#### Allow nil

The parameter can be `#nil?`.

```ruby
param :tag, type: :string, allow_nil: true
```

By default, nil params are rejected with a `TypedParams::InvalidParameterError`
error.

#### Allow non-scalars

Only applicable to the `:hash` type and its subtypes. Allow non-scalar values in
a `:hash` parameter. Scalar types can be found under [Types](#scalar-types).

```ruby
param :metadata, type: :hash, allow_non_scalars: true
```

By default, non-scalar parameters are rejected with a `TypedParams::InvalidParameterError`
error.

#### Nilify blanks

Automatically convert `#blank?` values to `nil`.

```ruby
param :phone_number, type: :string, nilify_blanks: true
```

By default, this is disabled.

#### Inclusion validation

The parameter must be included in the array or range.

```ruby
param :log_level, type: :string,  inclusion: { in: %w[DEBUG INFO WARN ERROR FATAL] }
param :priority, type: :integer, inclusion: { in: 0..9 }
```

#### Exclusion validation

The parameter must be excluded from the array or range.

```ruby
param :custom_log_level, type: :string,  exclusion: { in: %w[DEBUG INFO WARN ERROR FATAL] }
param :custom_priority, type: :integer, exclusion: { in: 0..9 }
```

#### Format validation

The parameter must be a certain regular expression format.

```ruby
param :first_name, type: :string, format: { with: /foo/ }
param :last_name, type: :string, format: { without: /bar/ }
```

#### Length validation

The parameter must be a certain length.

```ruby
param :content, type: :string, length: { minimum: 100 }
param :title, type: :string, length: { maximum: 10 }
param :tweet, type: :string, length: { within: ..160 }
param :odd, type: :string, length: { in: [2, 4, 6, 8] }
param :ten, type: :string, length: { is: 10 }
```

#### Transform parameter

Transform the parameter using a lambda. This is commonly used to transform a
parameter into a nested attributes hash or array.

```ruby
param :user, type: :string, transform: -> _key, email {
  [:user_attributes, { email: }]
}
```

The lambda must accept a key (the current parameter key), and a value (the
current parameter value).

The lamda must return a tuple with the new key and value.

#### Validate parameter

Define a custom validation for the parameter, outside of the default
validations.

```ruby
param :user, type: :integer, validate: -> id {
  User.exists?(id)
}
```

The lambda should accept a value and return a boolean. When the boolean
evaluates to `false`, a `TypedParams::InvalidParameterError` will
be raised.

### Shared options

You can define a set of options that will be applied to immediate
children parameters (i.e. not grandchilden).

```ruby
with if: :admin? do
  param :referrer, type: :string, optional: true
  param :role, type: :string
end
```

### Scalar types

- [`:string`](#string-type)
- [`:boolean`](#boolean-type)
- [`:integer`](#integer-type)
- [`:float`](#float-type)
- [`:decimal`](#decimal-type)
- [`:number`](#number-type)
- [`:symbol`](#symbol-type)
- [`:time`](#time-type)
- [`:date`](#date-type)

#### String type

Defines a string parameter. Must be a `String`.

#### Boolean type

Defines a boolean parameter. Must be `TrueClass` or `FalseClass`.

#### Integer type

Defines an integer parameter. Must be an `Integer`.

#### Float type

Defines a float parameter. Must be a `Float`.

#### Decimal type

Defines a decimal parameter. Must be a `BigDecimal`.

#### Number type

Defines a number parameter. Must be either an `Integer`, a `Float`, or a `BigDecimal`.

#### Symbol type

Defines a symbol parameter. Must be a `Symbol`.

#### Time type

Defines a time parameter. Must be a `Time`.

#### Date type

Defines a time parameter. Must be a `Date`.

### Non-scalar types

- [`:array`](#array-type)
- [`:hash`](#hash-type)

#### Array type

Defines an array parameter. Must be an `Array`.

Arrays are a special type. They can accept a block that defines its item types,
which may be a nested schema.

```ruby
# array of hashes
param :boundless_array, type: :array do
  item type: :hash do
    # ...
  end
end
# array of 1 integer and 1 string
param :bounded_array, type: :array do
  item type: :integer
  item type: :string
end
```

#### Hash type

Defines a hash parameter. Must be a `Hash`.

Hashes are a special type. They can accept a block that defines a nested schema.

```ruby
# define a nested schema
param :parent, type: :hash do
  param :child, type: :hash do
    # ...
  end
end

# non-schema hash
param :only_scalars, type: :hash
param :non_scalars_too, type: :hash, allow_non_scalars: true
```

### Custom types

You may register custom types that can be utilized in your schemas.

Each type consists of, at minimum, a `match:` lambda. For more usage
examples, see [the default types](https://github.com/keygen-sh/typed_params/tree/master/lib/typed_params/types).

```ruby
TypedParams.types.register(:metadata,
  archetype: :hash,
  match: -> value {
    return false unless
      value.is_a?(Hash)

    # Metadata can have one layer of nested arrays/hashes
    value.values.all? { |v|
      case v
      when Hash
        v.values.none? { _1.is_a?(Array) || _1.is_a?(Hash) }
      when Array
        v.none? { _1.is_a?(Array) || _1.is_a?(Hash) }
      else
        true
      end
    }
  },
)
```

## Is it any good?

[Yes.](https://news.ycombinator.com/item?id=3067434)

## Contributing

If you have an idea, or have discovered a bug, please open an issue or create a pull request.

For security issues, please see [`SECURITY.md`](https://github.com/keygen-sh/typed_params/blob/master/SECURITY.md)

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
