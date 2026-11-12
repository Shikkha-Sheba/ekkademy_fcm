import 'package:flutter_test/flutter_test.dart';
import 'package:ekkademy_fcm/ekkademy_fcm.dart';

void main() {
  tearDown(() async {
    await EkkademyFcm.dispose();
  });

  test('config requires app callbacks', () {
    var tokenDeleted = false;
    final config = EkkademyFcmConfig(
      isAuthenticated: () async => false,
      onTokenSync: (token) async {},
      onTokenDelete: (token) async {
        tokenDeleted = true;
      },
    );

    expect(config.requestPermissionOnInitialize, isTrue);
    expect(config.foregroundPresentationEnabled, isTrue);
    expect(config.syncTokenOnInitialize, isTrue);
    expect(config.showLocalNotificationOnForeground, isTrue);
    expect(config.androidNotificationChannelId, equals('ekkademy_fcm_channel'));
    expect(config.onTokenDelete, isNotNull);

    config.onTokenDelete?.call('test_token');
    expect(tokenDeleted, isTrue);
  });

  test('EkkademyFcm throws StateError when accessed before initialize', () {
    expect(EkkademyFcm.isInitialized, isFalse);
    expect(() => EkkademyFcm.instance, throwsStateError);
  });
}

