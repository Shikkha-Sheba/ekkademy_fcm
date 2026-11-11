import 'package:firebase_messaging/firebase_messaging.dart';

/// Call this from the host app's top-level background handler.
///
/// The host app must initialize its own Firebase app/options first.
/// Background handlers run in a separate isolate, so do not use Riverpod,
/// BuildContext, navigation, or app-scoped services here.
Future<void> handleEkkademyFcmBackgroundMessage(
  RemoteMessage message, {
  Future<void> Function(RemoteMessage message)? onMessage,
}) async {
  await onMessage?.call(message);
}
