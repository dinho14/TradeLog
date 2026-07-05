import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // ── REPLACE these with your actual values from Firebase Console ──────────────
  // After running `flutterfire configure`, this file will be auto-populated.

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: "AIzaSyDRMALHwpU2Bk5aZZD4RzlGDMvjempXrbk",
    authDomain: "tradelog-6a8b7.firebaseapp.com",
    projectId: "tradelog-6a8b7",
    storageBucket: "tradelog-6a8b7.firebasestorage.app",
    messagingSenderId: "290689204126",
    appId: "1:290689204126:web:37477523b7b8421d71208f",
    measurementId: "G-H71LZQW4TW",
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyD0WfFAIcmn9JfoGP49iQsWQOy9vdGmITo',
    appId: '1:290689204126:android:0911a1b8d9acad4d71208f',
    messagingSenderId: '290689204126',
    projectId: 'tradelog-6a8b7',
    storageBucket: 'tradelog-6a8b7.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBXyrsLH-rvsgL2tAsGv4q6MR16mCyu8FY',
    appId: '1:290689204126:ios:610af5ebb8721b0f71208f',
    messagingSenderId: '290689204126',
    projectId: 'tradelog-6a8b7',
    storageBucket: 'tradelog-6a8b7.firebasestorage.app',
    iosBundleId: 'trading.journal.app',
  );
}
