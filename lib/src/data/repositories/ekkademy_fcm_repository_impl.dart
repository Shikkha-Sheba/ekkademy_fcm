import 'package:firebase_messaging/firebase_messaging.dart';

import '../../config/ekkademy_fcm_config.dart';
import '../../domain/repositories/ekkademy_fcm_repository.dart';
import '../../services/ekkademy_fcm_service.dart';

class EkkademyFcmRepositoryImpl implements EkkademyFcmRepository {
  EkkademyFcmRepositoryImpl({
    required EkkademyFcmService service,
    required EkkademyFcmConfig config,
  })  : _service = service,
        _config = config;

  final EkkademyFcmService _service;
  final EkkademyFcmConfig _config;

  @override
  Future<NotificationSettings> initialize() {
    return _service.initialize(
      requestPermission: _config.requestPermissionOnInitialize,
      foregroundPresentationEnabled:
          _config.foregroundPresentationEnabled,
    );
  }

  @override
  Future<String?> getToken() => _service.getToken();

  @override
  Future<void> syncToken({String? token}) async {
    final authenticated = await _config.isAuthenticated();
    if (!authenticated) return;

    final value = token ?? await getToken();
    if (value == null || value.trim().isEmpty) return;

    await _config.onTokenSync(value);
  }

  @override
  Stream<String> get onTokenRefresh => _service.onTokenRefresh;

  @override
  Stream<RemoteMessage> get onForegroundMessage =>
      _service.onForegroundMessage.cast<RemoteMessage>();

  @override
  Stream<RemoteMessage> get onNotificationTap =>
      _service.onNotificationTap.cast<RemoteMessage>();

  @override
  Future<RemoteMessage?> getInitialMessage() =>
      _service.getInitialMessage();
}
