/// Base class for every kind of error in the app.
///
/// [Failure] is a sealed class, which means the compiler knows every possible
/// subtype and forces every `switch` to handle all of them. This makes
/// error handling exhaustive and hard to forget.
///
/// All failures carry a [message] that is safe to show in the UI.
sealed class Failure {
  const Failure(this.message);

  /// A human-readable description of what went wrong.
  final String message;
}

/// A business-rule violation — the user attempted something they are not
/// allowed to do (e.g. checking in twice on the same day).
class RuleFailure extends Failure {
  const RuleFailure(super.message);
}

/// A form or input validation error.
///
/// The optional [field] name identifies which form field failed so the UI can
/// display the error directly under the right input widget.
class ValidationFailure extends Failure {
  const ValidationFailure(super.message, {this.field});

  /// The name of the form field that failed (e.g. `'startDate'`, `'reason'`).
  /// `null` means the error is not tied to a single field.
  final String? field;
}

/// A network communication error — the device could not reach the server
/// (no internet, timeout, DNS failure, etc.).
class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

/// An error returned by the server (HTTP 4xx / 5xx responses).
///
/// [statusCode] holds the HTTP status code (e.g. 409, 422, 500).
/// [code] holds an optional machine-readable error code from the response body
/// (e.g. `'ALREADY_EXISTS'`, `'INVALID_ORDER'`).
class ServerFailure extends Failure {
  const ServerFailure(super.message, {this.statusCode, this.code});

  /// HTTP status code from the server response.
  final int? statusCode;

  /// Machine-readable error code from the response body, if provided.
  final String? code;
}

/// A GPS / location error — the device could not determine the user's position
/// (permission denied, GPS disabled, hardware unavailable).
class LocationFailure extends Failure {
  const LocationFailure(super.message);
}

/// A local database or file-system error — something went wrong while reading
/// from or writing to the local SQLite database.
class StorageFailure extends Failure {
  const StorageFailure(super.message);
}

// ── Result ────────────────────────────────────────────────────────────────────

/// A discriminated union that wraps the result of any operation that can fail.
///
/// Every method that might fail returns `Result<T>` instead of throwing an
/// exception. The caller must check whether it is a [Success] or a
/// [FailureResult] before using the value.
///
/// Example:
/// ```dart
/// final result = await repository.getEmployee();
/// if (result is Success<Employee>) {
///   showEmployee(result.value);
/// } else if (result is FailureResult<Employee>) {
///   showError(result.failure.message);
/// }
/// ```
sealed class Result<T> {
  const Result();
}

/// Represents a successful operation. Holds the returned [value].
class Success<T> extends Result<T> {
  const Success(this.value);

  /// The value produced by the successful operation.
  final T value;
}

/// Represents a failed operation. Holds the [failure] that explains why.
class FailureResult<T> extends Result<T> {
  const FailureResult(this.failure);

  /// Details about what went wrong.
  final Failure failure;
}
