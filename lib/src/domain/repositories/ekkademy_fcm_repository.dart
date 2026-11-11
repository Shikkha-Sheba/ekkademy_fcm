import 'package:firebase_messaging/firebase_messaging.dart';

abstract interface class EkkademyFcmRepository {
  Future<NotificationSettings> initialize();

  Future<String?> getToken();

  Future<void> syncToken({String? token});

  Future<void> deleteToken();

  Future<void> unregisterToken({String? token});

  Future<void> subscribeToTopic(String topic);

  Future<void> unsubscribeFromTopic(String topic);

  Stream<String> get onTokenRefresh;

  Stream<RemoteMessage> get onForegroundMessage;

  Stream<RemoteMessage> get onNotificationTap;

  Future<RemoteMessage?> getInitialMessage();
}
