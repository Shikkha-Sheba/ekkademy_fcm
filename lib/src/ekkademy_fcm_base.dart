import 'package:firebase_messaging/firebase_messaging.dart';

import 'config/ekkademy_fcm_config.dart';
import 'controllers/ekkademy_fcm_controller.dart';
import 'data/repositories/ekkademy_fcm_repository_impl.dart';
import 'services/ekkademy_fcm_service.dart';
import 'services/ekkademy_local_notification_service.dart';

/// Main entry point for initializing and interacting with Ekkademy FCM.
class EkkademyFcm {
  EkkademyFcm._();

  static EkkademyFcmController? _instance;

  /// Returns the singleton [EkkademyFcmController] instance.
  /// Throws [StateError] if [initialize] has not been called.
  static EkkademyFcmController get instance {
    final controller = _instance;
    if (controller == null) {
      throw StateError(
        'EkkademyFcm is not initialized. Call await EkkademyFcm.initialize(...) first.',
      );
    }
    return controller;
  }

  /// Whether [EkkademyFcm] has been initialized.
  static bool get isInitialized => _instance != null;

  /// Initializes Ekkademy FCM module with the provided [config].
  ///
  /// Typically called in `main()` after `Firebase.initializeApp()`:
  /// ```dart
  /// await EkkademyFcm.initialize(
  ///   EkkademyFcmConfig(...),
  /// );
  /// ```
  static Future<EkkademyFcmController> initialize(
    EkkademyFcmConfig config, {
    FirebaseMessaging? messaging,
    EkkademyLocalNotificationService? localNotificationService,
  }) async {
    if (_instance != null) {
      return _instance!;
    }

    final repository = EkkademyFcmRepositoryImpl(
      service: EkkademyFcmService(messaging ?? FirebaseMessaging.instance),
      config: config,
    );

    final notificationService =
        localNotificationService ?? EkkademyLocalNotificationService();

    final controller = EkkademyFcmController(
      repository: repository,
      config: config,
      localNotificationService: notificationService,
    );

    await controller.initialize();
    _instance = controller;
    return controller;
  }

  /// Syncs the FCM token to backend, or retries pending token sync.
  static Future<void> syncToken({String? token}) =>
      instance.syncToken(token: token);

  /// Unregisters FCM token on logout and deletes local token.
  static Future<void> unregisterToken({String? token}) =>
      instance.unregisterToken(token: token);

  /// Subscribes to an FCM topic.
  static Future<void> subscribeToTopic(String topic) =>
      instance.subscribeToTopic(topic);

  /// Unsubscribes from an FCM topic.
  static Future<void> unsubscribeFromTopic(String topic) =>
      instance.unsubscribeFromTopic(topic);

  /// Disposes and resets the singleton instance (mainly for testing or reset).
  static Future<void> dispose() async {
    await _instance?.dispose();
    _instance = null;
  }
}
