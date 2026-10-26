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

// Ninguno de estos providers es `autoDispose` a propósito: F1 → F2 → receta
// → modo cocina se apilan, y volver atrás debe mostrar lo mismo sin gastar
// otra consulta del límite diario. `IngredientDetectionController.detect`
// los reinicia al empezar con una foto nueva.

/// F1 — análisis de la foto (Fase 6). El estado ES el resultado.
final ingredientDetectionControllerProvider =
    AsyncNotifierProvider<IngredientDetectionController, IngredientDetection?>(IngredientDetectionController.new);

class IngredientDetectionController extends AsyncNotifier<IngredientDetection?> {
  @override
  FutureOr<IngredientDetection?> build() => null;

  Future<void> detect(Uint8List imageBytes) async {
    final uid = ref.read(authStateChangesProvider).valueOrNull?.uid;
    if (uid == null) return;

    ref.invalidate(ingredientListProvider);
    ref.invalidate(ingredientRecipesControllerProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() {
      return ref.read(ingredientAnalysisRepositoryProvider).detectIngredients(userId: uid, imageBytes: imageBytes);
    });

    final result = state.valueOrNull;
    if (result != null) {
      ref.read(ingredientListProvider.notifier).replaceAll(result.ingredients);
      ref.read(analyticsServiceProvider).logIngredientPhotoAnalyzed(
            isIngredientPhoto: result.isIngredientPhoto,
            ingredientCount: result.ingredients.length,
          );
    }
  }
}

/// La lista editable de F1: arranca con lo detectado; el usuario quita,
/// confirma dudosos y añade a mano. Solo los confirmados van a las recetas.
final ingredientListProvider =
    NotifierProvider<IngredientListController, List<DetectedIngredient>>(IngredientListController.new);

class IngredientListController extends Notifier<List<DetectedIngredient>> {
  @override
  List<DetectedIngredient> build() => const [];

  void replaceAll(List<DetectedIngredient> items) => state = List.unmodifiable(items);

  void remove(String name) => state = [for (final item in state) if (item.name != name) item];

  void confirm(String name) => state = [for (final item in state) item.name == name ? item.confirmed() : item];

  /// Añadido a mano = confirmado. Ignora vacíos y repetidos (sin distinguir
  /// mayúsculas); si ya estaba como dudoso, lo confirma.
  void add(String rawName) {
    final name = rawName.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (name.isEmpty) return;
    final existing = state.where((item) => item.name.toLowerCase() == name.toLowerCase()).firstOrNull;
    if (existing != null) {
      confirm(existing.name);
      return;
    }
    state = [...state, DetectedIngredient(name: name, confident: true)];
  }

  List<String> get confirmedNames => [for (final item in state) if (item.confident) item.name];
}

/// F2 — recetas sobre la lista confirmada. "Pedir más ideas" reemplaza las
/// actuales por otras distintas (las excluye por nombre).
final ingredientRecipesControllerProvider =
    AsyncNotifierProvider<IngredientRecipesController, IngredientRecipeSuggestions?>(IngredientRecipesController.new);

class IngredientRecipesController extends AsyncNotifier<IngredientRecipeSuggestions?> {
  /// Todo lo ya mostrado en esta sesión de F2, no solo la última tanda: así
  /// "más ideas" dos veces seguidas no vuelve a las primeras.
  final List<String> _shownNames = [];

  @override
  FutureOr<IngredientRecipeSuggestions?> build() {
    _shownNames.clear();
    return null;
  }

  Future<void> suggest() => _load(exclude: const []);

  Future<void> moreIdeas() => _load(exclude: List.of(_shownNames));

  Future<void> _load({required List<String> exclude}) async {
    final ingredients = ref.read(ingredientListProvider.notifier).confirmedNames;
    if (ingredients.isEmpty) return;

    state = const AsyncLoading();
    state = await AsyncValue.guard(() {
      return ref
          .read(ingredientAnalysisRepositoryProvider)
          .suggestRecipes(ingredients: ingredients, excludeRecipeNames: exclude);
    });
    final result = state.valueOrNull;
    if (result != null) _shownNames.addAll(result.recipes.map((s) => s.recipe.name));
  }
}
