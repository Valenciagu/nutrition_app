import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/firebase_instances.dart';
import '../../../authentication/presentation/providers/auth_providers.dart';
import '../../data/repositories/firebase_recipe_repository.dart';
import '../../domain/entities/recipe.dart';
import '../../domain/repositories/recipe_repository.dart';

final recipeRepositoryProvider = Provider<RecipeRepository>((ref) {
  return FirebaseRecipeRepository(ref.watch(firebaseFunctionsProvider));
});

/// Identifica una receta por la comida que la originó — una `.family` por
/// `(date, mealId)` en vez de por `recipeId` porque D3 se navega ANTES de
/// saber si ya existe una receta generada (ver `PlannedMeal.recipeId`); el
/// backend decide cachear o generar. Un record como parámetro de familia
/// tiene igualdad estructural automática, sin necesitar una clase aparte.
final recipeProvider = FutureProvider.autoDispose.family<Recipe, ({String date, String mealId})>((ref, args) async {
  final uid = ref.watch(authStateChangesProvider).valueOrNull?.uid;
  if (uid == null) {
    throw StateError('recipeProvider requiere una sesión activa — Recipes no tiene un camino de invitado.');
  }
  return ref.watch(recipeRepositoryProvider).getOrGenerateRecipe(userId: uid, date: args.date, mealId: args.mealId);
});
