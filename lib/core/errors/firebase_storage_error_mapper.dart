import 'package:firebase_core/firebase_core.dart';

import 'failure.dart';

/// Traduce un error de subida a Firebase Storage al [Failure]
/// correspondiente. Extraído de `FirebaseFoodAnalysisRepository` (Épica 8)
/// al aparecer su segundo consumidor (`FirebaseIngredientAnalysisRepository`,
/// Épica 9) — mismo criterio que `mapFirebaseFunctionsException`.
Failure mapFirebaseStorageException(FirebaseException e) {
  switch (e.code) {
    case 'unauthorized':
      return PermissionFailure(message: e.message, cause: e);
    case 'canceled':
    case 'retry-limit-exceeded':
      return NetworkFailure(message: e.message, cause: e);
    default:
      return ServerFailure(message: e.message, cause: e);
  }
}
