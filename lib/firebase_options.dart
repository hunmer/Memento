/// Firebase 配置文件
///
/// 重要：此文件包含 Firebase 项目的配置信息。
/// 你需要使用 FlutterFire CLI 生成你自己的配置文件：
///
/// 1. 安装 FlutterFire CLI:
///    dart pub global activate flutterfire_cli
///
/// 2. 运行配置命令:
///    flutterfire configure --project=your-firebase-project-id
///
/// 或者手动替换下面的配置值为你的 Firebase 项目配置。
///
/// 从 Firebase Console 获取配置：
/// - Android: 项目设置 -> 你的应用 -> google-services.json
/// - iOS: 项目设置 -> 你的应用 -> GoogleService-Info.plist

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// 默认 Firebase 配置选项
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
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for windows.',
        );
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

  /// TODO: 替换为你的 Firebase Web 配置
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'YOUR_WEB_API_KEY',
    appId: 'YOUR_WEB_APP_ID',
    messagingSenderId: 'YOUR_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
    authDomain: 'YOUR_PROJECT_ID.firebaseapp.com',
    storageBucket: 'YOUR_PROJECT_ID.appspot.com',
  );

  /// TODO: 替换为你的 Firebase Android 配置
  /// 从 google-services.json 获取：
  /// - apiKey: client[0].api_key[0].current_key
  /// - appId: client[0].client_info.mobilesdk_app_id
  /// - messagingSenderId: project_info.project_number
  /// - projectId: project_info.project_id
  /// - storageBucket: project_info.storage_bucket
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'YOUR_ANDROID_API_KEY',
    appId: 'YOUR_ANDROID_APP_ID',
    messagingSenderId: 'YOUR_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
    storageBucket: 'YOUR_PROJECT_ID.appspot.com',
  );

  /// TODO: 替换为你的 Firebase iOS 配置
  /// 从 GoogleService-Info.plist 获取：
  /// - apiKey: API_KEY
  /// - appId: GOOGLE_APP_ID
  /// - messagingSenderId: GCM_SENDER_ID
  /// - projectId: PROJECT_ID
  /// - storageBucket: STORAGE_BUCKET
  /// - iosClientId: CLIENT_ID (可选)
  /// - iosBundleId: BUNDLE_ID
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'YOUR_IOS_API_KEY',
    appId: 'YOUR_IOS_APP_ID',
    messagingSenderId: 'YOUR_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
    storageBucket: 'YOUR_PROJECT_ID.appspot.com',
    iosClientId: 'YOUR_IOS_CLIENT_ID',
    iosBundleId: 'github.hunmer.memento',
  );

  /// TODO: 替换为你的 Firebase macOS 配置
  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'YOUR_IOS_API_KEY',
    appId: 'YOUR_IOS_APP_ID',
    messagingSenderId: 'YOUR_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
    storageBucket: 'YOUR_PROJECT_ID.appspot.com',
    iosClientId: 'YOUR_IOS_CLIENT_ID',
    iosBundleId: 'github.hunmer.memento',
  );
}
