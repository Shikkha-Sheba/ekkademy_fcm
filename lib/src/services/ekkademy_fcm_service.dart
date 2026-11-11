import 'package:firebase_messaging/firebase_messaging.dart';

class EkkademyFcmService {
  EkkademyFcmService(this._messaging);

  final FirebaseMessaging _messaging;

  Future<NotificationSettings> initialize({
    required bool requestPermission,
    required bool foregroundPresentationEnabled,
  }) async {
    if (requestPermission) {
      await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        announcement: false,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
      );
    }

    if (foregroundPresentationEnabled) {
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    return _messaging.getNotificationSettings();
  }
  Future<String?> getToken() => _messaging.getToken();

  Future<void> deleteToken() => _messaging.deleteToken();

  Future<void> subscribeToTopic(String topic) =>
      _messaging.subscribeToTopic(topic);

  Future<void> unsubscribeFromTopic(String topic) =>
      _messaging.unsubscribeFromTopic(topic);

  Stream<String> get onTokenRefresh => _messaging.onTokenRefresh;

  Stream get onForegroundMessage => FirebaseMessaging.onMessage;

  Stream get onNotificationTap => FirebaseMessaging.onMessageOpenedApp;

  Future<RemoteMessage?> getInitialMessage() =>
      _messaging.getInitialMessage();
}
