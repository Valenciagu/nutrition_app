import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/firebase_instances.dart';
import '../../../authentication/presentation/providers/auth_providers.dart';
import '../../../onboarding/domain/calorie_estimate.dart';
import '../../../onboarding/domain/entities/onboarding_answers.dart';
import '../../../onboarding/presentation/providers/onboarding_providers.dart';

/// Meta diaria de calorías para el anillo de Home. Reusa el mismo cálculo
/// determinista de Onboarding (`calorie_estimate.dart`) — no hay
/// duplicación de lógica, solo de dónde vienen las respuestas:
/// - Con sesión: se leen del documento `users/{uid}.onboarding` en Firestore.
/// - Sin sesión (invitado con un borrador local completo): se lee
///   directamente `onboardingControllerProvider` (en memoria, esta sesión).
/// - Si no hay ninguno de los dos (se llegó a Home sin pasar por
///   Onboarding, p. ej. Login → SignUp → "Seguir sin cuenta"),
///   `estimateDailyCalories` ya tiene valores por defecto razonables.
///
/// Cruzar features (Home → Onboarding) aquí es deliberado: son funciones de
/// dominio puras y una entidad, no un acoplamiento de UI/estado.
final homeDailyCalorieGoalProvider = FutureProvider<int>((ref) async {
  final authState = ref.watch(authStateChangesProvider);
  final uid = authState.valueOrNull?.uid;

  OnboardingAnswers answers;
  if (uid != null) {
    final doc = await ref.read(firestoreProvider).collection('users').doc(uid).get();
    final raw = doc.data()?['onboarding'];
    answers = raw is Map ? OnboardingAnswers.fromJson(Map<String, dynamic>.from(raw)) : const OnboardingAnswers();
  } else {
    answers = ref.read(onboardingControllerProvider);
  }

  return estimateDailyCalories(
    sex: answers.sex,
    age: answers.age,
    heightCm: answers.heightCm,
    weightKg: answers.weightKg,
    activityLevel: answers.activityLevel ?? ActivityLevel.moderate,
  );
});
