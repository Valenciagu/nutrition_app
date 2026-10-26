import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrition_app/features/onboarding/domain/entities/onboarding_answers.dart';
import 'package:nutrition_app/features/profile/presentation/providers/profile_providers.dart';

// BUG-P01: con el perfil YA cargado (como cuando se abre la edición encima
// de ProfilePage), el controlador de edición tiene que nacer con esos datos,
// no vacío.
void main() {
  const saved = OnboardingAnswers(
    goal: NutritionGoal.gainMuscle,
    avoidFoods: {'nuts', 'gluten'},
    likedFoods: {'chicken'},
  );

  test('el formulario nace con el perfil ya cargado', () async {
    final container = ProviderContainer(overrides: [userProfileProvider.overrideWith((ref) async => saved)]);
    addTearDown(container.dispose);

    // ProfilePage mantiene vivo el perfil antes de abrir la edición.
    container.listen(userProfileProvider, (_, _) {});
    await container.read(userProfileProvider.future);

    container.listen(profileEditControllerProvider, (_, _) {});
    final editing = container.read(profileEditControllerProvider);
    expect(editing.goal, NutritionGoal.gainMuscle);
    expect(editing.avoidFoods, {'nuts', 'gluten'});
    expect(editing.likedFoods, {'chicken'});
    expect(container.read(profileEditControllerProvider.notifier).isSeeded, isTrue);
  });

  test('sin perfil cargado queda marcado como no sembrado (no se puede guardar)', () {
    final container = ProviderContainer(
      overrides: [userProfileProvider.overrideWith((ref) => Future<OnboardingAnswers>.delayed(const Duration(days: 1), () => saved))],
    );
    addTearDown(container.dispose);

    container.listen(profileEditControllerProvider, (_, _) {});
    expect(container.read(profileEditControllerProvider.notifier).isSeeded, isFalse);
  });
}
