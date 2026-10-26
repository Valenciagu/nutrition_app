import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/errors/firebase_functions_error_mapper.dart';
import '../../../../core/errors/firebase_storage_error_mapper.dart';
import '../../domain/entities/ingredient_suggestions.dart';
import '../../domain/repositories/ingredient_analysis_repository.dart';

/// F1 usa el mismo pipeline que `FirebaseFoodAnalysisRepository` (Épica 8):
/// sube la foto a `users/{uid}/ingredientPhotos/{photoId}.jpg` y llama al
/// callable solo con el id (`_firestore` solo genera ese id, sin escribir).
/// F2 es un callable de texto, sin Storage.
class FirebaseIngredientAnalysisRepository implements IngredientAnalysisRepository {
  FirebaseIngredientAnalysisRepository(this._storage, this._functions, this._firestore);

  final FirebaseStorage _storage;
  final FirebaseFunctions _functions;
  final FirebaseFirestore _firestore;

  @override
  Future<IngredientDetection> detectIngredients({required String userId, required Uint8List imageBytes}) async {
    final photoId = _firestore.collection('users').doc(userId).collection('ingredientPhotos').doc().id;

    try {
      await _storage
          .ref('users/$userId/ingredientPhotos/$photoId.jpg')
          .putData(imageBytes, SettableMetadata(contentType: 'image/jpeg'));
    } on FirebaseException catch (e) {
      throw mapFirebaseStorageException(e);
    }

    final data = await _call('detectIngredients', {'photoId': photoId});
    return _parse('detectIngredients', () => IngredientDetection.fromJson(data));
  }

  @override
  Future<IngredientRecipeSuggestions> suggestRecipes({
    required List<String> ingredients,
    List<String> excludeRecipeNames = const [],
  }) async {
    // Tres recetas completas tardan más que una llamada normal: el timeout
    // del cliente acompaña al de la función (120 s).
    final data = await _call(
      'suggestRecipesFromIngredients',
      {'ingredients': ingredients, 'excludeRecipeNames': excludeRecipeNames},
      timeout: const Duration(seconds: 120),
    );
    return _parse('suggestRecipesFromIngredients', () => IngredientRecipeSuggestions.fromJson(data));
  }

  Future<Map<String, dynamic>> _call(String name, Map<String, Object> payload, {Duration? timeout}) async {
    try {
      final callable = _functions.httpsCallable(
        name,
        options: timeout == null ? null : HttpsCallableOptions(timeout: timeout),
      );
      final result = await callable.call<Object?>(payload);
      return Map<String, dynamic>.from(result.data as Map);
    } on FirebaseFunctionsException catch (e) {
      throw mapFirebaseFunctionsException(e);
    } on TypeError catch (e) {
      throw AiValidationFailure(message: '$name devolvió una respuesta con forma inesperada', cause: e);
    }
  }

  T _parse<T>(String name, T Function() parse) {
    try {
      return parse();
    } on TypeError catch (e) {
      throw AiValidationFailure(message: '$name devolvió una respuesta con forma inesperada', cause: e);
    }
  }
}
