# Changelog

## 1.4.0

- Add `depth:` validator for asserting maximum depth of `hash` and `array` params.

## 1.3.0

- Add `any` type to skip type validation for a given param.

## 1.2.7

- Fix issue where the JSONAPI formatter did not ignore `meta` when `data` is omitted.

## 1.2.6

- Fix issue where an empty param of type `hash` or `array` would not raise when a required but `allow_nil` child param was missing.

## 1.2.5

- Fix issue where a `minimum` and `maximum` constraint combo was not asserted by the `length:` validator.

## 1.2.4

- Fix issue where both `minimum` and `maximum` constraints could not be added to a `length:` validator.

## 1.2.3

- Remove `alias` from child lookup criteria in JSONAPI formatter.

## 1.2.2

- Fix issue where `as:` keyword was not handled in JSONAPI relationship formatter.

## 1.2.1

- Update JSONAPI formatter to simplify logic for polymorphic relationships.

## 1.2.0

- Add `aliases:` keyword to `#param` to allow the schema to be accessible by different names.
- Add `polymorphic:` keyword to `#param` to define a polymorphic schema.

## 1.1.1

- Fix compatibility with Ruby 3.3.0 due to [#20091](https://bugs.ruby-lang.org/issues/20091).

## 1.1.0

- Add memoization to `#typed_params` and `#typed_query` methods.

## 1.0.3

- Revert 0b0aaa6b66edd3e4c3336e51fa340592e7ef9e86.

## 1.0.2

- Fix parameterization of nil children.

## 1.0.1

- Fix namespaced schemas.

## 1.0.0

- Initial release.

## 0.2.0

- Test release.
