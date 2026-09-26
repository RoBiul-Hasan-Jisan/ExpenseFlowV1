//rename and fill  all value lib\firebase_options.dart

// Web and Android platforms are configured with your real

//
// iOS/macOS temporarily reuse the `web` FirebaseOptions (see the switch
// below) instead of having their own registered Firebase app — this
// works fine for Firebase Auth (the web API key isn't restricted to a
// bundle ID by default), so sign-in/sign-up will work as-is on iOS/macOS
// with zero extra setup. The only thing you lose this way is anything
// that depends on a *native* iOS app registration specifically (e.g.
// Dynamic Links, iOS-specific Analytics, APNs-based push via FCM) — none
// of which this app currently uses.
//
// To give iOS/macOS their own proper app later: Firebase Console ->
// Project settings -> Add app -> iOS, download GoogleService-Info.plist
// into ios/Runner/, then either add an `ios`/`macos` FirebaseOptions
// block back here with its real apiKey/appId, or just run:
//
//   dart pub global activate flutterfire_cli
//   flutterfire configure
//
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        // Temporary: reusing the web config until iOS/macOS get their
        // own registered Firebase app — see the file header comment.
        return web;
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for this platform. '
          'Run `flutterfire configure` from the project root.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: '',
    appId: '',
    messagingSenderId: '',
    projectId: '',
    authDomain: '',
    storageBucket: '',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: '',
    appId: '',
    messagingSenderId: '',
    projectId: '',
    storageBucket: '',
  );
}
