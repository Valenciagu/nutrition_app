import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/firebase_instances.dart';
import '../../../../core/utils/date_key.dart';
import '../../../authentication/presentation/providers/auth_providers.dart';
import '../../../plan/domain/entities/planned_meal.dart';
import '../../../plan/presentation/providers/plan_providers.dart';
import '../../data/repositories/firebase_grocery_list_repository.dart';
import '../../domain/entities/grocery_item.dart';
import '../../domain/grocery_categorizer.dart';
import '../../domain/repositories/grocery_list_repository.dart';

final groceryListRepositoryProvider = Provider<GroceryListRepository>((ref) {
  return FirebaseGroceryListRepository(ref.watch(firestoreProvider));
});

/// Lunes de la semana actual (YYYY-MM-DD) — identifica
/// `shoppingLists/{weekKey}`, misma semana que `weekPlansProvider`/`DayStrip`.
String currentWeekKey() => dateKey(currentWeekdays().first);

class GroceryListData {
  const GroceryListData({required this.items, required this.mealsWithoutRecipe});

  final List<GroceryItem> items;

  /// Comidas pendientes de la semana que todavía no tienen una receta
  /// generada — sus ingredientes reales se desconocen, así que NO se
  /// inventan (ver `documentation/grocery_list.md`); se listan aparte como
  /// aviso, cada una con lo necesario para navegar a su D3 y generarla.
  final List<MissingRecipeMeal> mealsWithoutRecipe;
}

class MissingRecipeMeal {
  const MissingRecipeMeal({required this.name, required this.date, required this.mealId});

  final String name;
  final String date;
  final String mealId;
}

/// Agrega los ingredientes de todas las recetas YA GENERADAS de las comidas
/// pendientes de la semana — sin Cloud Function ni IA: solo lecturas de
/// Firestore ya permitidas por `firestore.rules` (Épicas 6/7) más
/// categorización determinística (`categorizeIngredient`). Se recalcula
/// entero en cada `invalidate` (p. ej. al generarse una receta nueva) — no
/// vale la pena cachear algo tan barato de recomputar.
final groceryListProvider = FutureProvider.autoDispose<GroceryListData>((ref) async {
  final uid = ref.watch(authStateChangesProvider).valueOrNull?.uid;
  if (uid == null) return const GroceryListData(items: [], mealsWithoutRecipe: []);

  final planRepo = ref.watch(planRepositoryProvider);
  final groceryRepo = ref.watch(groceryListRepositoryProvider);

  final weekDates = currentWeekdays();
  final plans = await planRepo.getPlansForDates(userId: uid, dates: weekDates.map(dateKey).toList());

  final pending = <({DateTime date, PlannedMeal meal})>[];
  for (final date in weekDates) {
    final plan = plans[dateKey(date)];
    if (plan == null) continue;
    for (final meal in plan.meals) {
      if (meal.status == MealStatus.pending) pending.add((date: date, meal: meal));
    }
  }

  final withRecipe = pending.where((e) => e.meal.recipeId != null).toList();
  final mealsWithoutRecipe = pending
      .where((e) => e.meal.recipeId == null)
      .map((e) => MissingRecipeMeal(name: e.meal.name, date: dateKey(e.date), mealId: e.meal.id))
      .toList();

  final recipeIds = withRecipe.map((e) => e.meal.recipeId!).toSet().toList();
  final recipes = await groceryRepo.getRecipesByIds(userId: uid, recipeIds: recipeIds);
  final recipeById = {for (final recipe in recipes) recipe.id: recipe};

  final checkedKeys = await groceryRepo.getCheckedItemKeys(userId: uid, weekKey: currentWeekKey());
  final extraItems = await groceryRepo.getExtraItems(userId: uid, weekKey: currentWeekKey());

  final byKey = <String, ({String name, GroceryCategory category, List<GroceryItemSource> sources})>{};
  for (final entry in withRecipe) {
    final recipe = recipeById[entry.meal.recipeId];
    if (recipe == null) continue; // `recipeId` inconsistente — mismo caso raro que `generateRecipe.ts` documenta.
    for (final ingredient in recipe.ingredients) {
      final key = ingredient.name.trim().toLowerCase();
      final source = GroceryItemSource(quantity: ingredient.quantity, slotLabelKey: entry.meal.slotLabelKey, date: entry.date);
      final existing = byKey[key];
      if (existing == null) {
        byKey[key] = (name: ingredient.name.trim(), category: categorizeIngredient(ingredient.name), sources: [source]);
      } else {
        existing.sources.add(source);
      }
    }
  }

  // Ítems añadidos a mano (Épica 9): si ya están porque una receta del plan
  // los pide, no se duplican; si no, entran sin origen.
  for (final name in extraItems) {
    final key = name.trim().toLowerCase();
    if (key.isEmpty || byKey.containsKey(key)) continue;
    byKey[key] = (name: name.trim(), category: categorizeIngredient(name), sources: <GroceryItemSource>[]);
  }

  final items = byKey.entries
      .map((e) => GroceryItem(
            key: e.key,
            name: e.value.name,
            category: e.value.category,
            sources: e.value.sources,
            checked: checkedKeys.contains(e.key),
          ))
      .toList()
    ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

  return GroceryListData(items: items, mealsWithoutRecipe: mealsWithoutRecipe);
});

/// "Añadir X a la lista de compra" desde una receta sugerida (Épica 9, F2).
final addToGroceryListControllerProvider =
    AsyncNotifierProvider.autoDispose<AddToGroceryListController, void>(AddToGroceryListController.new);

class AddToGroceryListController extends AutoDisposeAsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> add(List<String> names) async {
    final uid = ref.read(authStateChangesProvider).valueOrNull?.uid;
    if (uid == null || names.isEmpty) return;

    state = const AsyncLoading();
    state = await AsyncValue.guard(() {
      return ref.read(groceryListRepositoryProvider).addExtraItems(userId: uid, weekKey: currentWeekKey(), names: names);
    });
    if (!state.hasError) ref.invalidate(groceryListProvider);
  }
}

/// Marca/desmarca un ítem como "ya tengo/compré" — invalida solo el estado
/// marcado, no toda `groceryListProvider` (que releería todas las recetas de
/// la semana solo para un toggle).
final groceryItemCheckControllerProvider =
    AsyncNotifierProvider<GroceryItemCheckController, void>(GroceryItemCheckController.new);

class GroceryItemCheckController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> toggle(GroceryItem item) async {
    final uid = ref.read(authStateChangesProvider).valueOrNull?.uid;
    if (uid == null) return;

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(groceryListRepositoryProvider).setItemChecked(
            userId: uid,
            weekKey: currentWeekKey(),
            itemKey: item.key,
            checked: !item.checked,
          );
    });
    if (!state.hasError) {
      ref.invalidate(groceryListProvider);
    }
  }
}
