# avoid_non_null_assertion_operator

A custom lint package for Dart/Flutter that helps enforce safer null handling by prohibiting the use of the non-null assertion operator (!).

## Features

- Detects and reports usage of the non-null assertion operator (!)
- Helps enforce safer null handling practices
- Integrates with Dart's analyzer

## Getting started

Add this to your package's `pubspec.yaml` file:

```yaml
dev_dependencies:
  custom_lint:
  avoid_non_null_assertion_operator:
```

## Usage

Add the following to your `analysis_options.yaml`:

```yaml
analyzer:
  plugins:
    - custom_lint
  errors:
    avoid_non_null_assertion_operator: error
```

The lint will now report errors for code like this:

```dart
String? nullable = "test";
String nonNullable = nullable!; // Error: Avoid using the non-null assertion operator (!)
```

Instead, use safer alternatives like:

```dart
String? nullable = "test";
String nonNullable = nullable ?? "default"; // Use null coalescing
// or
if (nullable != null) {
  String nonNullable = nullable; // Use null check
}
```

## Additional information

This package is designed to help maintain safer null handling practices in Dart/Flutter projects. It encourages the use of explicit null checks and null coalescing operators instead of force-unwrapping nullable values.

For more information about null safety in Dart, visit the [official documentation](https://dart.dev/null-safety).
