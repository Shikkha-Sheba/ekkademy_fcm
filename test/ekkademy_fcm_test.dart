import 'package:flutter_test/flutter_test.dart';
import 'package:ekkademy_fcm/ekkademy_fcm.dart';

void main() {
  test('config requires app callbacks', () {
    final config = EkkademyFcmConfig(
      isAuthenticated: () async => false,
      onTokenSync: (token) async {},
    );

    expect(config.requestPermissionOnInitialize, isTrue);
    expect(config.foregroundPresentationEnabled, isTrue);
    expect(config.syncTokenOnInitialize, isTrue);
  });
}
