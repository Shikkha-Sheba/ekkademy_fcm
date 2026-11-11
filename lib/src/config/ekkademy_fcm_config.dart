import 'package:firebase_messaging/firebase_messaging.dart';

typedef FcmTokenSyncCallback = Future<void> Function(String token);
typedef FcmTokenDeleteCallback = Future<void> Function(String token);
typedef FcmAuthenticationCheck = Future<bool> Function();
typedef FcmMessageCallback = Future<void> Function(RemoteMessage message);
typedef FcmErrorCallback = void Function(Object error, StackTrace stackTrace);

/// App-specific callbacks and behavior for the reusable FCM module.
///
/// Firebase initialization and backend API implementation remain the
/// responsibility of the host application.
class EkkademyFcmConfig {
  const EkkademyFcmConfig({
    required this.isAuthenticated,
    required this.onTokenSync,
    this.onTokenDelete,
    this.onForegroundMessage,
    this.onNotificationTap,
    this.onError,
    this.requestPermissionOnInitialize = true,
    this.foregroundPresentationEnabled = true,
    this.syncTokenOnInitialize = true,
    this.showLocalNotificationOnForeground = true,
    this.androidNotificationChannelId = 'ekkademy_fcm_channel',
    this.androidNotificationChannelName = 'Ekkademy Notifications',
    this.androidNotificationChannelDescription =
        'Channel for Ekkademy foreground notifications',
    this.androidNotificationIcon = '@mipmap/ic_launcher',
  });

  /// Returns true only when the current app user is authenticated.
  final FcmAuthenticationCheck isAuthenticated;

  /// Host app sends the token to its own backend from this callback.
  /// Prefer an idempotent upsert operation on the backend.
  final FcmTokenSyncCallback onTokenSync;

  /// Host app deletes/unlinks the token from its own backend during logout.
  final FcmTokenDeleteCallback? onTokenDelete;

  /// Called when a message arrives while the app is foregrounded.
  final FcmMessageCallback? onForegroundMessage;

  /// Called when the user opens a notification from background/terminated state.
  final FcmMessageCallback? onNotificationTap;

  /// Optional centralized error reporting.
  final FcmErrorCallback? onError;

  final bool requestPermissionOnInitialize;
  final bool foregroundPresentationEnabled;

  /// If true, tries to sync the current token during initialize.
  /// The authentication callback is checked before the backend callback.
  final bool syncTokenOnInitialize;

  /// If true, displays a local notification heads-up banner when an FCM message arrives in foreground.
  final bool showLocalNotificationOnForeground;

  final String androidNotificationChannelId;
  final String androidNotificationChannelName;
  final String androidNotificationChannelDescription;
  final String androidNotificationIcon;
}
