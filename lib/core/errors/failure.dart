/// Base type for all recoverable, user-facing failures surfaced from the
/// domain/presentation layers. Repositories map data-layer [AppException]s
/// to a [Failure] before returning a `Result`-like type upward — widgets
/// must never see raw exceptions.
sealed class Failure {
  const Failure({this.message, this.cause});

  /// Optional technical detail for logging. Never shown to the user directly —
  /// user-facing copy is always resolved through the localization layer
  /// (see `core/localization`), keyed off the concrete [Failure] type.
  final String? message;

  /// The original error/exception, kept for logging/Crashlytics only.
  final Object? cause;
}

/// The backend (Cloud Functions / REST) returned an error response.
final class ServerFailure extends Failure {
  const ServerFailure({super.message, super.cause, this.statusCode});

  final int? statusCode;
}

/// No connectivity, timeout, or other transport-level failure.
final class NetworkFailure extends Failure {
  const NetworkFailure({super.message, super.cause});
}

/// Firebase Authentication failed (bad credentials, expired session, etc).
final class AuthFailure extends Failure {
  const AuthFailure({super.message, super.cause, this.code});

  final String? code;
}

/// Client-side or server-side input validation rejected the request.
final class ValidationFailure extends Failure {
  const ValidationFailure({super.message, super.cause});
}

/// The current user is not allowed to perform the requested action
/// (Firestore/Storage rules rejection, missing subscription tier, etc).
final class PermissionFailure extends Failure {
  const PermissionFailure({super.message, super.cause});
}

/// The requested resource does not exist.
final class NotFoundFailure extends Failure {
  const NotFoundFailure({super.message, super.cause});
}

/// An AI response failed schema/safety validation and could not be
/// safely shown to the user. See `nutrition-app-security` skill.
final class AiValidationFailure extends Failure {
  const AiValidationFailure({super.message, super.cause});
}

/// Anything not classified above. Should be rare — prefer a specific
/// [Failure] subtype so the UI can react appropriately.
final class UnknownFailure extends Failure {
  const UnknownFailure({super.message, super.cause});
}
