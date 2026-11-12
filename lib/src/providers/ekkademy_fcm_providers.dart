import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/ekkademy_fcm_config.dart';
import '../controllers/ekkademy_fcm_controller.dart';
import '../data/repositories/ekkademy_fcm_repository_impl.dart';
import '../domain/repositories/ekkademy_fcm_repository.dart';
import '../ekkademy_fcm_base.dart';
import '../services/ekkademy_fcm_service.dart';
import '../services/ekkademy_local_notification_service.dart';

/// Override this provider once in the host app's ProviderScope if not using [EkkademyFcm.initialize].
final ekkademyFcmConfigProvider = Provider<EkkademyFcmConfig>((ref) {
  throw StateError(
    'Override ekkademyFcmConfigProvider with EkkademyFcmConfig '
    'or call await EkkademyFcm.initialize(...) before reading providers.',
  );
});

final ekkademyFcmServiceProvider = Provider<EkkademyFcmService>((ref) {
  return EkkademyFcmService(FirebaseMessaging.instance);
});

final ekkademyLocalNotificationServiceProvider =
    Provider<EkkademyLocalNotificationService>((ref) {
  return EkkademyLocalNotificationService();
});

final ekkademyFcmRepositoryProvider =
    Provider<EkkademyFcmRepository>((ref) {
  return EkkademyFcmRepositoryImpl(
    service: ref.watch(ekkademyFcmServiceProvider),
    config: ref.watch(ekkademyFcmConfigProvider),
  );
});

final ekkademyFcmControllerProvider =
    Provider<EkkademyFcmController>((ref) {
  if (EkkademyFcm.isInitialized) {
    return EkkademyFcm.instance;
  }

  final controller = EkkademyFcmController(
    repository: ref.watch(ekkademyFcmRepositoryProvider),
    config: ref.watch(ekkademyFcmConfigProvider),
    localNotificationService:
        ref.watch(ekkademyLocalNotificationServiceProvider),
  );

  ref.onDispose(() {
    unawaited(controller.dispose());
  });

  return controller;
});

