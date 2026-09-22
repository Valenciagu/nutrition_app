import '../entities/notification_preferences.dart';

abstract class NotificationPreferencesRepository {
  Future<NotificationPreferences> get(String userId);

  Future<void> save(String userId, NotificationPreferences prefs);
}
