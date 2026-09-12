import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/onboarding_answers.dart';

/// Única clase del proyecto que escribe el perfil de Onboarding en
/// Firestore. Documento `users/{userId}` — mismo doc que usará el resto del
/// perfil (Épica 11) más adelante, por eso se hace `set(..., merge: true)`
/// en vez de crear una subcolección aparte.
class OnboardingRemoteDataSource {
  OnboardingRemoteDataSource(this._firestore);

  final FirebaseFirestore _firestore;

  Future<void> saveProfile(String userId, OnboardingAnswers answers) async {
    await _firestore.collection('users').doc(userId).set({
      'onboarding': answers.toJson(),
      'onboardingCompletedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
