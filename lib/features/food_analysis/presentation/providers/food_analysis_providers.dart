import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/analytics/firebase_analytics_service.dart';
import '../../../../core/services/firebase_instances.dart';
import '../../../authentication/presentation/providers/auth_providers.dart';
import '../../data/repositories/firebase_food_analysis_repository.dart';
import '../../domain/entities/food_analysis_result.dart';
import '../../domain/repositories/food_analysis_repository.dart';

final foodAnalysisRepositoryProvider = Provider<FoodAnalysisRepository>((ref) {
  return FirebaseFoodAnalysisRepository(
    ref.watch(firebaseStorageProvider),
    ref.watch(firebaseFunctionsProvider),
    ref.watch(firestoreProvider),
  );
});

/// Mismo patrón `AsyncNotifier` que `MealAlternativesController` (Épica 6):
/// el estado ES el resultado, no un `void` — la pantalla lo pinta
/// directamente con `.when`.
final foodAnalysisControllerProvider =
    AsyncNotifierProvider<FoodAnalysisController, FoodAnalysisResult?>(FoodAnalysisController.new);

class FoodAnalysisController extends AsyncNotifier<FoodAnalysisResult?> {
  @override
  FutureOr<FoodAnalysisResult?> build() => null;

  Future<void> analyze(Uint8List imageBytes) async {
    final uid = ref.read(authStateChangesProvider).valueOrNull?.uid;
    if (uid == null) return;

    state = const AsyncLoading();
    state = await AsyncValue.guard(() {
      return ref.read(foodAnalysisRepositoryProvider).analyzePhoto(userId: uid, imageBytes: imageBytes);
    });
    final result = state.valueOrNull;
    if (result != null) {
      ref.read(analyticsServiceProvider).logFoodPhotoAnalyzed(isFoodPhoto: result.isFoodPhoto);
    }
  }
}
