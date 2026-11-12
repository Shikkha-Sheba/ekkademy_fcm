# ekkademy_fcm

Reusable Firebase Cloud Messaging module for Ekkademy Flutter applications.

## Responsibilities

- FCM permission request & foreground presentation setup
- Built-in Local Notification service for heads-up foreground banners (`flutter_local_notifications`)
- FCM token retrieval, auto-refresh listener, and in-memory retry on sync failure
- Auth-aware token sync callback (`onTokenSync`)
- Logout token unregister callback (`onTokenDelete`)
- Topic subscription and unsubscription (`subscribeToTopic` / `unsubscribeFromTopic`)
- Foreground message callback (`onForegroundMessage`)
- Notification tap callbacks (`onNotificationTap` - background and terminated launch)
- Optional Riverpod provider integration (`ekkademyFcmControllerProvider`)
- Top-level background message handler helper

The host app owns Firebase initialization, Firebase options, backend API calls,
authentication state, and app-specific navigation.

## Requirements

- Flutter >= 3.27
- Dart >= 3.8
- Firebase Messaging 16.x or 17.x
- Flutter Local Notifications 18.x or 19.x

## Install from Git

```yaml
dependencies:
  ekkademy_fcm:
    git:
      url: git@github.com:Shikkha-Sheba/ekkademy_fcm.git
      ref: v1.0.0
```

Replace the repository URL with the actual Git remote. For a private repository,
make sure CI and developer machines have Git access.

## Quick Initialization (Recommended)

Call `EkkademyFcm.initialize(...)` once during app startup (e.g. in `main()` after `Firebase.initializeApp()`):

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  await EkkademyFcm.initialize(
    EkkademyFcmConfig(
      isAuthenticated: () async {
        // Return current user authentication state
        return authState.isAuthenticated;
      },
      showLocalNotificationOnForeground: true, // Enables heads-up banner in foreground
      androidNotificationChannelId: 'ekkademy_fcm_channel',
      androidNotificationChannelName: 'Ekkademy Notifications',
      androidNotificationIcon: '@mipmap/ic_launcher',
      onTokenSync: (token) async {
        AppLogger.info('FCM token: $token');
        await dio.post('/device-token', data: {'token': token});
      },
      onTokenDelete: (token) async {
        AppLogger.info('FCM token deletion requested: $token');
        await dio.delete('/device-token', data: {'token': token});
      },
      onForegroundMessage: (message) async {
        AppLogger.info('FCM foreground message: ${message.messageId}');
        // Handle in-app notification updates.
      },
      onNotificationTap: (message) async {
        AppLogger.info('FCM notification tapped: ${message.messageId}');
        // Navigate using app's router.
      },
      onError: (error, stackTrace) {
        AppLogger.error('FCM error: $error');
        // Send to Crashlytics.
      },
    ),
  );

  runApp(const MyApp());
}
```

No widget wrapper (`FcmInitializer`), `ref.read`, or `ProviderScope` override required!

## Usage Guide

### 1. Login Flow (Sync Token)
After login or authentication handoff succeeds, call:

```dart
await EkkademyFcm.syncToken();
```
(Or via Riverpod: `await ref.read(ekkademyFcmControllerProvider).syncToken();`)

This ensures the token is synced to the backend if initialization happened before login or while offline.

### 2. Logout Flow (Unregister Token)
When the user logs out, call:

```dart
await EkkademyFcm.unregisterToken();
```

This invokes `onTokenDelete` (unlinking the token from your backend) and deletes the FCM token from the local device instance to prevent unwanted notifications after logout.

### 3. Topic Subscriptions
To subscribe or unsubscribe from FCM topics (e.g., `all_students`, `classroom_101`):

```dart
// Subscribe
await EkkademyFcm.subscribeToTopic('classroom_101');

// Unsubscribe
await EkkademyFcm.unsubscribeFromTopic('classroom_101');
```

### 4. Optional Riverpod Integration
If your app uses Riverpod, `ekkademyFcmControllerProvider` will automatically return `EkkademyFcm.instance` once initialized:

```dart
final controller = ref.watch(ekkademyFcmControllerProvider);
```

## Background Handler

Each host app must register its own top-level entry point in `main.dart`:

```dart
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(
  RemoteMessage message,
) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await handleEkkademyFcmBackgroundMessage(
    message,
    onMessage: (message) async {
      // Optional background data processing only.
      // Do not navigate or use Riverpod/BuildContext here.
    },
  );
}
```

Register it after importing `firebase_messaging` and the package:

```dart
FirebaseMessaging.onBackgroundMessage(
  firebaseMessagingBackgroundHandler,
);
```

Register the handler before `runApp`. If Firebase is initialized using native
default configuration in your app, use that same initialization strategy here.
Do not initialize Firebase twice with conflicting options.

## Platform Setup

### Android

- Add the app's `google-services.json` for each application/flavor.
- Ensure the Google Services Gradle plugin is configured.
- Android 13+ requires notification permission. This package requests it when
  `requestPermissionOnInitialize` is true.
- Ensure `@mipmap/ic_launcher` or your custom notification icon exists in `android/app/src/main/res/drawable` or `mipmap`.
- For OS-rendered notifications while backgrounded/terminated, backend FCM
  messages should include a `notification` payload. Data-only messages do not
  automatically create a visible notification.

### iOS

- Add the correct `GoogleService-Info.plist` for each app/flavor.
- Enable Push Notifications capability.
- Enable Background Modes > Remote notifications if background data processing
  is required.
- Configure APNs authentication key/certificate in Firebase.
- Request notification permission and test on a physical device.
- iOS force-quit behavior can prevent background processing until the user
  opens the app again.

## Important Behavior & Security Notes

- **Foreground Heads-Up Notifications**: Built-in support is included via `EkkademyLocalNotificationService`. Set `showLocalNotificationOnForeground: true` in `EkkademyFcmConfig` to automatically display heads-up banner notifications when an FCM message arrives in foreground.
- `onNotificationTap` handles notification-open events from background and
  terminated launch.
- Notification navigation must be implemented by each host app.
- Token sync is skipped while `isAuthenticated()` returns `false`.
- In-memory retry is performed if token sync fails due to network error or unauthenticated state. Calling `syncToken()` will retry pending tokens safely.
- Backend token sync should be idempotent (upsert by user/device/token).
- On logout, call `unregisterToken()` to remove the token on backend and delete the FCM token locally.
- Do not log full FCM tokens in production logs.
