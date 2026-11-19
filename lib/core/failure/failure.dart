sealed class Failure {
  const Failure(this.message);

  final String message;
}

class RuleFailure extends Failure {
  const RuleFailure(super.message);
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message, {this.field});

  final String? field;
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

class ServerFailure extends Failure {
  const ServerFailure(super.message, {this.statusCode, this.code});

  final int? statusCode;
  final String? code;
}

class LocationFailure extends Failure {
  const LocationFailure(super.message);
}

class StorageFailure extends Failure {
  const StorageFailure(super.message);
}

sealed class Result<T> {
  const Result();
}

class Success<T> extends Result<T> {
  const Success(this.value);

  final T value;
}

class FailureResult<T> extends Result<T> {
  const FailureResult(this.failure);

  final Failure failure;
}
