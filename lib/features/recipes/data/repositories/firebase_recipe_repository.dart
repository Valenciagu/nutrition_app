import 'package:cloud_functions/cloud_functions.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/errors/firebase_functions_error_mapper.dart';
import '../../domain/entities/recipe.dart';
import '../../domain/repositories/recipe_repository.dart';

/// Implementación de [RecipeRepository] — llama a `generateRecipe`
/// (`functions/src/recipes/generateRecipe.ts`). Sin lecturas directas a
/// Firestore: el callable ya devuelve la receta completa (cacheada o recién
/// generada), así que no hace falta un segundo viaje. Mismo criterio que
/// `FirebasePlanRepository` (Épica 6): un repositorio concreto, sin una
/// capa de "data source" aparte.
class FirebaseRecipeRepository implements RecipeRepository {
  FirebaseRecipeRepository(this._functions);

  final FirebaseFunctions _functions;

  @override
  Future<Recipe> getOrGenerateRecipe({
    required String userId,
    required String date,
    required String mealId,
  }) async {
    try {
      final callable = _functions.httpsCallable('generateRecipe');
      final result = await callable.call<Object?>({'date': date, 'mealId': mealId});
      return Recipe.fromJson(Map<String, dynamic>.from(result.data as Map));
    } on FirebaseFunctionsException catch (e) {
      throw mapFirebaseFunctionsException(e);
    } on TypeError catch (e) {
      throw AiValidationFailure(message: 'generateRecipe devolvió una respuesta con forma inesperada', cause: e);
    }
  }
}
