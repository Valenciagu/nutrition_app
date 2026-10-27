import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/utils/date_key.dart';
import '../../../authentication/presentation/providers/auth_providers.dart';
import '../../../meal_log/domain/entities/extra_meal.dart';
import '../../../meal_log/presentation/providers/extra_meal_providers.dart';
import '../../../plan/domain/entities/nutrition_plan.dart';
import '../../../plan/domain/entities/planned_meal.dart';
import '../../../plan/presentation/providers/plan_providers.dart';

/// Última comida extra que ya tuvo su propuesta C2 resuelta ("Recalcular mi
/// día" o "Ahora no"), por usuario. Local al dispositivo a propósito: es
/// una preferencia de interfaz efímera, no un dato del usuario — en otro
/// teléfono, a lo sumo, la propuesta se vuelve a ofrecer una vez.
final handledSuggestionMealIdProvider =
    AsyncNotifierProvider.autoDispose<HandledSuggestionMealId, String?>(HandledSuggestionMealId.new);

class HandledSuggestionMealId extends AutoDisposeAsyncNotifier<String?> {
  String? get _key {
    final uid = ref.read(authStateChangesProvider).valueOrNull?.uid;
    return uid == null ? null : 'home.aiSuggestion.handledExtraMealId.$uid';
  }

  @override
  Future<String?> build() async {
    ref.watch(authStateChangesProvider);
    final key = _key;
    if (key == null) return null;
    return (await SharedPreferences.getInstance()).getString(key);
  }

  Future<void> markHandled(String extraMealId) async {
    state = AsyncData(extraMealId);
    final key = _key;
    if (key != null) await (await SharedPreferences.getInstance()).setString(key, extraMealId);
  }
}

/// La comida extra que motiva la propuesta C2, o `null` si no toca
/// mostrarla. Ver [pickSuggestionMeal].
final homeAiSuggestionProvider = Provider.autoDispose<ExtraMeal?>((ref) {
  final plan = ref.watch(todayPlanProvider).valueOrNull;
  final extras = ref.watch(extraMealsForDateProvider(dateKey(DateTime.now()))).valueOrNull ?? const <ExtraMeal>[];
  final handled = ref.watch(handledSuggestionMealIdProvider);
  // Mientras no se sabe qué se resolvió, no se muestra: mejor un instante
  // sin tarjeta que una tarjeta que aparece y desaparece.
  if (handled.isLoading) return null;
  return pickSuggestionMeal(plan, extras, handled.valueOrNull);
});

/// C2 aparece solo si recalcular sirve de algo: hay plan hoy con comidas
/// pendientes que ajustar, y la comida extra más reciente todavía no tuvo
/// su propuesta resuelta. Una comida extra nueva vuelve a ofrecerla.
ExtraMeal? pickSuggestionMeal(NutritionPlan? plan, List<ExtraMeal> extras, String? handledMealId) {
  if (plan == null || extras.isEmpty) return null;
  if (!plan.meals.any((meal) => meal.status == MealStatus.pending)) return null;
  final latest = extras.reduce(
    (a, b) => (b.createdAt ?? DateTime(0)).isAfter(a.createdAt ?? DateTime(0)) ? b : a,
  );
  return latest.id == handledMealId ? null : latest;
}
