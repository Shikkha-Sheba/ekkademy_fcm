import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';

import '../config/ekkademy_fcm_config.dart';
import '../domain/repositories/ekkademy_fcm_repository.dart';
import '../services/ekkademy_local_notification_service.dart';

/// Coordinates FCM listeners and delegates platform/API work to the repository.
class EkkademyFcmController {
  EkkademyFcmController({
    required EkkademyFcmRepository repository,
    required EkkademyFcmConfig config,
    EkkademyLocalNotificationService? localNotificationService,
  })  : _repository = repository,
        _config = config,
        _localNotificationService = localNotificationService;

  final EkkademyFcmRepository _repository;
  final EkkademyFcmConfig _config;
  final EkkademyLocalNotificationService? _localNotificationService;

  StreamSubscription<String>? _tokenSubscription;
  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  StreamSubscription<RemoteMessage>? _tapSubscription;
  Future<void>? _initializeFuture;
  bool _disposed = false;
  String? _pendingUnsyncedToken;

  /// Holds a token that failed to sync due to network error or unauthenticated state.
  String? get pendingUnsyncedToken => _pendingUnsyncedToken;

  Future<void> initialize() {
    if (_disposed) {
      throw StateError('EkkademyFcmController has already been disposed.');
    }
    return _initializeFuture ??= _initialize();
  }

  Future<void> _initialize() async {
    try {
      await _repository.initialize();

      if (_config.showLocalNotificationOnForeground) {
        await _localNotificationService?.initialize(
          channelId: _config.androidNotificationChannelId,
          channelName: _config.androidNotificationChannelName,
          channelDescription: _config.androidNotificationChannelDescription,
          defaultIcon: _config.androidNotificationIcon,
        );
      }

      _tokenSubscription ??= _repository.onTokenRefresh.listen(
        (token) => unawaited(_syncTokenSafely(token)),
        onError: _reportStreamError,
      );

      _foregroundSubscription ??= _repository.onForegroundMessage.listen(
        (message) => unawaited(_handleForegroundMessage(message)),
        onError: _reportStreamError,
      );

      _tapSubscription ??= _repository.onNotificationTap.listen(
        (message) => unawaited(_dispatchMessage(
          message,
          _config.onNotificationTap,
        )),
        onError: _reportStreamError,
      );

      final initialMessage = await _repository.getInitialMessage();
      if (initialMessage != null) {
        await _dispatchMessage(initialMessage, _config.onNotificationTap);
      }

      if (_config.syncTokenOnInitialize) {
        await syncToken();
      }
    } catch (error, stackTrace) {
      _reportError(error, stackTrace);
      rethrow;
    }
  }

  /// Call this after login/authentication becomes valid or to retry a failed token sync.
  /// This is important when initialize() ran before login or while offline.
  Future<void> syncToken({String? token}) async {
    final targetToken = token ?? _pendingUnsyncedToken;
    try {
      await _repository.syncToken(token: targetToken);
      _pendingUnsyncedToken = null;
    } catch (error, stackTrace) {
      _pendingUnsyncedToken = targetToken ?? await _getTokenSafely();
      _reportError(error, stackTrace);
      rethrow;
    }
  }

  Future<void> _syncTokenSafely(String token) async {
    try {
      await _repository.syncToken(token: token);
      _pendingUnsyncedToken = null;
    } catch (error, stackTrace) {
      _pendingUnsyncedToken = token;
      _reportError(error, stackTrace);
    }
  }

  Future<String?> _getTokenSafely() async {
    try {
      return await _repository.getToken();
    } catch (_) {
      return null;
    }
  }

  /// Call this when the user logs out. Unlinks token from host backend (via `onTokenDelete`)
  /// and deletes the FCM token from the device.
  Future<void> unregisterToken({String? token}) async {
    try {
      await _repository.unregisterToken(token: token);
      _pendingUnsyncedToken = null;
    } catch (error, stackTrace) {
      _reportError(error, stackTrace);
      rethrow;
    }
  }

  /// Subscribe to an FCM topic (e.g. 'all_users', 'classroom_101').
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _repository.subscribeToTopic(topic);
    } catch (error, stackTrace) {
      _reportError(error, stackTrace);
      rethrow;
    }
  }

  /// Unsubscribe from an FCM topic.
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _repository.unsubscribeFromTopic(topic);
    } catch (error, stackTrace) {
      _reportError(error, stackTrace);
      rethrow;
    }
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    if (_config.showLocalNotificationOnForeground) {
      try {
        await _localNotificationService?.showNotification(
          message: message,
          channelId: _config.androidNotificationChannelId,
          channelName: _config.androidNotificationChannelName,
          channelDescription: _config.androidNotificationChannelDescription,
          defaultIcon: _config.androidNotificationIcon,
        );
      } catch (error, stackTrace) {
        _reportError(error, stackTrace);
      }
    }
    await _dispatchMessage(message, _config.onForegroundMessage);
  }

  Future<void> _dispatchMessage(
    RemoteMessage message,
    FcmMessageCallback? callback,
  ) async {
    if (callback == null) return;
    try {
      await callback(message);
    } catch (error, stackTrace) {
      _reportError(error, stackTrace);
    }
  }

  void _reportStreamError(Object error, StackTrace stackTrace) {
    _reportError(error, stackTrace);
  }

  void _reportError(Object error, StackTrace stackTrace) {
    _config.onError?.call(error, stackTrace);
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;

    await _tokenSubscription?.cancel();
    await _foregroundSubscription?.cancel();
    await _tapSubscription?.cancel();
  }
}
