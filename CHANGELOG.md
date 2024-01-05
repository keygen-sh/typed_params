# Changelog

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
