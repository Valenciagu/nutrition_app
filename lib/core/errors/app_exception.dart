/// Base type for exceptions thrown by the data layer (data sources,
/// Firebase/Dio calls). Repository implementations catch these and map
/// them to a [Failure] (see `failure.dart`) — the domain/presentation
/// layers never deal with [AppException] directly.
sealed class AppException implements Exception {
  const AppException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => '$runtimeType: $message';
}

final class ServerException extends AppException {
  const ServerException(super.message, {super.cause, this.statusCode});

  final int? statusCode;
}

final class NetworkException extends AppException {
  const NetworkException(super.message, {super.cause});
}

final class AuthException extends AppException {
  const AuthException(super.message, {super.cause, this.code});

  final String? code;
}

final class CacheException extends AppException {
  const CacheException(super.message, {super.cause});
}

final class AiResponseException extends AppException {
  const AiResponseException(super.message, {super.cause});
}
