import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';

import '../config/ekkademy_fcm_config.dart';
import '../domain/repositories/ekkademy_fcm_repository.dart';

/// Coordinates FCM listeners and delegates platform/API work to the repository.
class EkkademyFcmController {
  EkkademyFcmController({
    required EkkademyFcmRepository repository,
    required EkkademyFcmConfig config,
  })  : _repository = repository,
        _config = config;

  final EkkademyFcmRepository _repository;
  final EkkademyFcmConfig _config;

  StreamSubscription<String>? _tokenSubscription;
  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  StreamSubscription<RemoteMessage>? _tapSubscription;
  Future<void>? _initializeFuture;
  bool _disposed = false;

  Future<void> initialize() {
    if (_disposed) {
      throw StateError('EkkademyFcmController has already been disposed.');
    }
    return _initializeFuture ??= _initialize();
  }

  Future<void> _initialize() async {
    try {
      await _repository.initialize();

      _tokenSubscription ??= _repository.onTokenRefresh.listen(
        (token) => unawaited(_syncTokenSafely(token)),
        onError: _reportStreamError,
      );

      _foregroundSubscription ??= _repository.onForegroundMessage.listen(
        (message) => unawaited(_dispatchMessage(
          message,
          _config.onForegroundMessage,
        )),
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

  /// Call this after login/authentication becomes valid.
  /// This is important when initialize() ran before login.
  Future<void> syncToken({String? token}) async {
    try {
      await _repository.syncToken(token: token);
    } catch (error, stackTrace) {
      _reportError(error, stackTrace);
      rethrow;
    }
  }

  Future<void> _syncTokenSafely(String token) async {
    try {
      await _repository.syncToken(token: token);
    } catch (error, stackTrace) {
      _reportError(error, stackTrace);
    }
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
