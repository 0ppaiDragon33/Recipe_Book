// lib/services/firebase_options.dart
// ─────────────────────────────────────────────────────────────────────────────
// ⚠️  REPLACE ALL PLACEHOLDER VALUES BELOW WITH YOUR OWN KEYS.
//
// HOW TO GET YOUR KEYS:
//   1. Go to https://console.firebase.google.com
//   2. Create a project (or open existing)
//   3. Click the gear icon → Project Settings
//   4. Under "Your apps", click Web (</>), register app, copy the config
//   5. For Android: download google-services.json → place in android/app/
//   6. For iOS:     download GoogleService-Info.plist → place in ios/Runner/
//
// ALTERNATIVELY run: flutterfire configure
//   which auto-generates this file for you.
// ─────────────────────────────────────────────────────────────────────────────

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
        return web;
    }
  }

  // ── Web ───────────────────────────────────────────────────────────────────
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDO5J2_kh3nUrW2hjJGPP5bnh9-U7Tuvbg',
    authDomain: 'recipe-book-20cdf.firebaseapp.com',
    projectId: 'recipe-book-20cdf',
    storageBucket: 'recipe-book-20cdf.firebasestorage.app',
    messagingSenderId: '349142247977',
    appId: '1:349142247977:web:112446abd2aa7d149dca38',
  );

  // ── Android ───────────────────────────────────────────────────────────────
  // Also place google-services.json in android/app/
  // Get it from: Firebase Console → Project Settings → Android app
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDO5J2_kh3nUrW2hjJGPP5bnh9-U7Tuvbg',
    authDomain: 'recipe-book-20cdf.firebaseapp.com',
    projectId: 'recipe-book-20cdf',
    storageBucket: 'recipe-book-20cdf.firebasestorage.app',
    messagingSenderId: '349142247977',
    appId: '1:349142247977:android:ca1674058568ee919dca38',
  );

  // ── iOS ───────────────────────────────────────────────────────────────────
  // Also place GoogleService-Info.plist in ios/Runner/
  // Get it from: Firebase Console → Project Settings → iOS app
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDO5J2_kh3nUrW2hjJGPP5bnh9-U7Tuvbg',
    authDomain: 'recipe-book-20cdf.firebaseapp.com',
    projectId: 'recipe-book-20cdf',
    storageBucket: 'recipe-book-20cdf.firebasestorage.app',
    messagingSenderId: '349142247977',
    appId: '1:349142247977:web:112446abd2aa7d149dca38',
    iosBundleId: 'com.example.recipeBook',
  );
}
