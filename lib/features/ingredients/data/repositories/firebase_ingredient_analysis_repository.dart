import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/errors/firebase_functions_error_mapper.dart';
import '../../../../core/errors/firebase_storage_error_mapper.dart';
import '../../domain/entities/ingredient_suggestions.dart';
import '../../domain/repositories/ingredient_analysis_repository.dart';

/// Mismo pipeline que `FirebaseFoodAnalysisRepository` (Épica 8): sube la foto
/// a `users/{uid}/ingredientPhotos/{photoId}.jpg` y llama al callable solo
/// con el id. `_firestore` solo genera ese id (`.doc().id`, sin escribir).
class FirebaseIngredientAnalysisRepository implements IngredientAnalysisRepository {
  FirebaseIngredientAnalysisRepository(this._storage, this._functions, this._firestore);

  final FirebaseStorage _storage;
  final FirebaseFunctions _functions;
  final FirebaseFirestore _firestore;

  @override
  Future<IngredientSuggestions> suggestRecipes({required String userId, required Uint8List imageBytes}) async {
    final photoId = _firestore.collection('users').doc(userId).collection('ingredientPhotos').doc().id;

    try {
      await _storage
          .ref('users/$userId/ingredientPhotos/$photoId.jpg')
          .putData(imageBytes, SettableMetadata(contentType: 'image/jpeg'));
    } on FirebaseException catch (e) {
      throw mapFirebaseStorageException(e);
    }

    try {
      // Tres recetas completas + visión tardan más que un análisis de comida:
      // el timeout del cliente acompaña al de la función (120 s).
      final callable = _functions.httpsCallable(
        'suggestRecipesFromIngredients',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 120)),
      );
      final result = await callable.call<Object?>({'photoId': photoId});
      return IngredientSuggestions.fromJson(Map<String, dynamic>.from(result.data as Map));
    } on FirebaseFunctionsException catch (e) {
      throw mapFirebaseFunctionsException(e);
    } on TypeError catch (e) {
      throw AiValidationFailure(
        message: 'suggestRecipesFromIngredients devolvió una respuesta con forma inesperada',
        cause: e,
      );
    }
  }
}
