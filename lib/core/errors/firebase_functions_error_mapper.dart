import 'package:cloud_functions/cloud_functions.dart';

import 'failure.dart';

/// Traduce el `code` de una [FirebaseFunctionsException] (cualquier función
/// `onCall`) al [Failure] correspondiente. Extraído de `FirebaseAiService`
/// (Épica 5) cuando `FirebasePlanRepository` (Épica 6) se convirtió en el
/// segundo consumidor real — mismo mapeo, sin duplicarlo.
Failure mapFirebaseFunctionsException(FirebaseFunctionsException e) {
  switch (e.code) {
    case 'unauthenticated':
      return AuthFailure(message: e.message, code: e.code, cause: e);
    case 'invalid-argument':
    case 'failed-precondition':
      return ValidationFailure(message: e.message, cause: e);
    case 'resource-exhausted':
      return AiQuotaExceededFailure(message: e.message, cause: e);
    case 'unavailable':
    case 'deadline-exceeded':
      return NetworkFailure(message: e.message, cause: e);
    default:
      return ServerFailure(message: e.message, cause: e);
  }
}
