import 'package:firebase_messaging/firebase_messaging.dart';

typedef FcmTokenSyncCallback = Future<void> Function(String token);
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
    this.onForegroundMessage,
    this.onNotificationTap,
    this.onError,
    this.requestPermissionOnInitialize = true,
    this.foregroundPresentationEnabled = true,
    this.syncTokenOnInitialize = true,
  });

  /// Returns true only when the current app user is authenticated.
  final FcmAuthenticationCheck isAuthenticated;

  /// Host app sends the token to its own backend from this callback.
  /// Prefer an idempotent upsert operation on the backend.
  final FcmTokenSyncCallback onTokenSync;

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
}
