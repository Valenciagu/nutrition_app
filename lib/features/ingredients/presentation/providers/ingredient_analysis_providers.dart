import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/analytics/firebase_analytics_service.dart';
import '../../../../core/services/firebase_instances.dart';
import '../../../authentication/presentation/providers/auth_providers.dart';
import '../../data/repositories/firebase_ingredient_analysis_repository.dart';
import '../../domain/entities/ingredient_suggestions.dart';
import '../../domain/repositories/ingredient_analysis_repository.dart';

final ingredientAnalysisRepositoryProvider = Provider<IngredientAnalysisRepository>((ref) {
  return FirebaseIngredientAnalysisRepository(
    ref.watch(firebaseStorageProvider),
    ref.watch(firebaseFunctionsProvider),
    ref.watch(firestoreProvider),
  );
});

/// Mismo patrón que `FoodAnalysisController` (Épica 8): el estado ES el
/// resultado. No es `autoDispose` a propósito — la receta sugerida (y su modo
/// cocina) se abren encima de esta pantalla y reciben su `SuggestedRecipe`
/// por `extra`, pero volver atrás debe mostrar las mismas 3 sugerencias, no
/// gastar otra consulta del límite diario.
final ingredientAnalysisControllerProvider =
    AsyncNotifierProvider<IngredientAnalysisController, IngredientSuggestions?>(IngredientAnalysisController.new);

class IngredientAnalysisController extends AsyncNotifier<IngredientSuggestions?> {
  @override
  FutureOr<IngredientSuggestions?> build() => null;

  Future<void> analyze(Uint8List imageBytes) async {
    final uid = ref.read(authStateChangesProvider).valueOrNull?.uid;
    if (uid == null) return;

    state = const AsyncLoading();
    state = await AsyncValue.guard(() {
      return ref.read(ingredientAnalysisRepositoryProvider).suggestRecipes(userId: uid, imageBytes: imageBytes);
    });
    final result = state.valueOrNull;
    if (result != null) {
      ref
          .read(analyticsServiceProvider)
          .logIngredientPhotoAnalyzed(isIngredientPhoto: result.isIngredientPhoto, recipeCount: result.recipes.length);
    }
  }
}
