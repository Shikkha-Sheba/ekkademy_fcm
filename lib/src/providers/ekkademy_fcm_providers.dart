import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/ekkademy_fcm_config.dart';
import '../controllers/ekkademy_fcm_controller.dart';
import '../data/repositories/ekkademy_fcm_repository_impl.dart';
import '../services/ekkademy_fcm_service.dart';
import '../domain/repositories/ekkademy_fcm_repository.dart';

/// Override this provider once in the host app's ProviderScope.
final ekkademyFcmConfigProvider = Provider<EkkademyFcmConfig>((ref) {
  throw StateError(
    'Override ekkademyFcmConfigProvider with EkkademyFcmConfig '
    'in the host app ProviderScope.',
  );
});

final ekkademyFcmServiceProvider = Provider<EkkademyFcmService>((ref) {
  return EkkademyFcmService(FirebaseMessaging.instance);
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
  final controller = EkkademyFcmController(
    repository: ref.watch(ekkademyFcmRepositoryProvider),
    config: ref.watch(ekkademyFcmConfigProvider),
  );

  ref.onDispose(() {
    unawaited(controller.dispose());
  });

  return controller;
});
