import '../../domain/entities/onboarding_answers.dart';
import '../../domain/repositories/onboarding_repository.dart';
import '../datasources/onboarding_local_data_source.dart';
import '../datasources/onboarding_remote_data_source.dart';

class OnboardingRepositoryImpl implements OnboardingRepository {
  OnboardingRepositoryImpl(this._local, this._remote);

  final OnboardingLocalDataSource _local;
  final OnboardingRemoteDataSource _remote;

  @override
  Future<void> saveDraft(OnboardingAnswers answers) => _local.saveDraft(answers);

  @override
  Future<OnboardingAnswers> loadDraft() async => await _local.loadDraft() ?? const OnboardingAnswers();

  @override
  Future<void> clearDraft() => _local.clearDraft();

  @override
  Future<bool> migrateDraftToProfile(String userId) async {
    final draft = await _local.loadDraft();
    if (draft == null || !draft.isComplete) return false;
    await _remote.saveProfile(userId, draft);
    await _local.clearDraft();
    return true;
  }

  @override
  Future<void> updateProfile(String userId, OnboardingAnswers answers) {
    return _remote.saveProfile(userId, answers);
  }
}
