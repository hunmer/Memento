import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Firebase 配置选项
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for linux.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyA77l-270PNx_skoHu-hhsI0kQt8Vx_4Ls',
    appId: '1:726933167202:android:5571b7be2f51964723853b',
    messagingSenderId: '726933167202',
    projectId: 'test-3f050',
    storageBucket: 'test-3f050.firebasestorage.app',
  );

  /// Android 配置 (从 google-services.json 获取)

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDpKOXscpzTBHSqw9vlhU3V9gybCNetMP8',
    appId: '1:726933167202:ios:ada0ea4bd67b1c3323853b',
    messagingSenderId: '726933167202',
    projectId: 'test-3f050',
    storageBucket: 'test-3f050.firebasestorage.app',
    iosBundleId: 'github.hunmer.memento',
  );

  /// iOS 配置 (从 GoogleService-Info.plist 获取)

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDpKOXscpzTBHSqw9vlhU3V9gybCNetMP8',
    appId: '1:726933167202:ios:ada0ea4bd67b1c3323853b',
    messagingSenderId: '726933167202',
    projectId: 'test-3f050',
    storageBucket: 'test-3f050.firebasestorage.app',
    iosBundleId: 'github.hunmer.memento',
  );

  /// macOS 配置 (与 iOS 相同)

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDw15MNFgyIAUcgJamop8sMUHTTWdBFokg',
    appId: '1:726933167202:web:557decce46d5783323853b',
    messagingSenderId: '726933167202',
    projectId: 'test-3f050',
    authDomain: 'test-3f050.firebaseapp.com',
    storageBucket: 'test-3f050.firebasestorage.app',
    measurementId: 'G-G07P5X975B',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyCidefejMpDJ5eZ5aaIqVDCdvjSW_tsIng',
    appId: '1:726933167202:web:35d642491a400cc223853b',
    messagingSenderId: '726933167202',
    projectId: 'test-3f050',
    authDomain: 'test-3f050.firebaseapp.com',
    storageBucket: 'test-3f050.firebasestorage.app',
    measurementId: 'G-2Y7S21NBSF',
  );

}