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
- Riverpod providers
- Top-level background message handler helper

The host app owns Firebase initialization, Firebase options, backend API calls,
authentication state, and app-specific navigation.

## Requirements

- Flutter >= 3.27
- Dart >= 3.8
- Riverpod 3.x
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

## Configure ProviderScope

```dart
ProviderScope(
  overrides: [
    ekkademyFcmConfigProvider.overrideWithValue(
      EkkademyFcmConfig(
        isAuthenticated: () async => authState.isAuthenticated,
        showLocalNotificationOnForeground: true, // Enables heads-up banner in foreground
        androidNotificationChannelId: 'ekkademy_fcm_channel',
        androidNotificationChannelName: 'Ekkademy Notifications',
        androidNotificationIcon: '@mipmap/ic_launcher',
        onTokenSync: (token) async {
          await dio.post(
            '/your-real-device-token-endpoint',
            data: {'token': token},
          );
        },
        onTokenDelete: (token) async {
          await dio.delete(
            '/your-real-device-token-endpoint',
            data: {'token': token},
          );
        },
        onForegroundMessage: (message) async {
          // Update in-app state or handle message.
        },
        onNotificationTap: (message) async {
          // Navigate using this app's own router.
        },
        onError: (error, stackTrace) {
          // Send to Crashlytics/Sentry if desired.
        },
      ),
    ),
  ],
  child: const App(),
)
```

`authState` and `dio` above are examples from the host application. Do not put
those app-specific objects inside this package.

## Usage Guide

### 1. Initialize once
Call after `Firebase.initializeApp()` and inside the configured `ProviderScope`:

```dart
ref.read(ekkademyFcmControllerProvider).initialize();
```

A convenient place is a small `ConsumerStatefulWidget` mounted once near the
root of the app. Do not initialize it on every screen.

### 2. Login Flow (Sync Token)
After login or authentication handoff succeeds, call:

```dart
await ref.read(ekkademyFcmControllerProvider).syncToken();
```

This ensures the token is synced to the backend if initialization happened before login or while offline.

### 3. Logout Flow (Unregister Token)
When the user logs out, call:

```dart
await ref.read(ekkademyFcmControllerProvider).unregisterToken();
```

This invokes `onTokenDelete` (unlinking the token from your backend) and deletes the FCM token from the local device instance to prevent unwanted notifications after logout.

### 4. Topic Subscriptions
To subscribe or unsubscribe from FCM topics (e.g., `all_students`, `classroom_101`):

```dart
final controller = ref.read(ekkademyFcmControllerProvider);

// Subscribe
await controller.subscribeToTopic('classroom_101');

// Unsubscribe
await controller.unsubscribeFromTopic('classroom_101');
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
