import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/notification_preferences.dart';
import '../../domain/repositories/notification_preferences_repository.dart';

/// Igual que `OnboardingRepository.updateProfile`: escritura directa del
/// cliente a `users/{userId}` (merge) — es preferencia propia del usuario,
/// no contenido generado por IA, así que no necesita pasar por una Cloud
/// Function (mismo criterio que `shoppingLists`, Épica 10). La regla amplia
/// `allow read, write: if request.auth.uid == userId` de `firestore.rules`
/// ya cubre este campo nuevo, no hace falta tocar las reglas.
class FirebaseNotificationPreferencesRepository implements NotificationPreferencesRepository {
  FirebaseNotificationPreferencesRepository(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Future<NotificationPreferences> get(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    final raw = doc.data()?['notificationPreferences'];
    return raw is Map ? NotificationPreferences.fromJson(Map<String, dynamic>.from(raw)) : const NotificationPreferences();
  }

  @override
  Future<void> save(String userId, NotificationPreferences prefs) {
    return _firestore.collection('users').doc(userId).set({
      'notificationPreferences': prefs.toJson(),
    }, SetOptions(merge: true));
  }
}
