# ekkademy_fcm

Reusable Firebase Cloud Messaging module for Ekkademy Flutter applications.

## Responsibilities

- FCM permission request
- FCM token retrieval and refresh listener
- Auth-aware token sync callback
- Foreground message callback
- Notification tap callbacks (background and terminated launch)
- Riverpod providers
- Background-handler helper

The host app owns Firebase initialization, Firebase options, backend API calls,
authentication state, and app-specific navigation.

## Requirements

- Flutter >= 3.27
- Dart >= 3.8
- Riverpod 3.x
- Firebase Messaging 16.x or 17.x

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
        onTokenSync: (token) async {
          await dio.post(
            '/your-real-device-token-endpoint',
            data: {'token': token},
          );
        },
        onForegroundMessage: (message) async {
          // Update in-app state or show an in-app banner.
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

## Initialize once

Call after Firebase.initializeApp() and inside the configured ProviderScope:

```dart
ref.read(ekkademyFcmControllerProvider).initialize();
```

A convenient place is a small ConsumerStatefulWidget mounted once near the
root of the app. Do not initialize it on every screen.

After login or auth handoff succeeds, call:

```dart
await ref.read(ekkademyFcmControllerProvider).syncToken();
```

This is necessary if FCM initialization happened before authentication.

## Background handler

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

## Platform setup

### Android

- Add the app's `google-services.json` for each application/flavor.
- Ensure the Google Services Gradle plugin is configured.
- Android 13+ requires notification permission. This package requests it when
  `requestPermissionOnInitialize` is true.
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

## Important behavior

- `onForegroundMessage` is a callback; this package does not create Android
  local notifications. Add a local-notifications implementation in the host
  app if you need a visible notification while the app is open.
- `onNotificationTap` handles notification-open events from background and
  terminated launch.
- Notification navigation must be implemented by each host app.
- Token sync is skipped while `isAuthenticated()` returns false.
- Call `syncToken()` after login/auth handoff to sync the existing token.
- Backend token sync should be idempotent (upsert by user/device/token).
- On logout, the host app should unlink the token from its backend if that is
  part of the backend contract.
- Do not log full FCM tokens in production.
