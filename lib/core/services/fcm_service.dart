import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:universal_platform/universal_platform.dart';
import 'package:Memento/firebase_options.dart';

/// 后台消息处理器（必须是顶级函数）
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('[FCM] 后台消息: ${message.notification?.title}');
  debugPrint('[FCM] 数据: ${message.data}');
}

class FcmService {
  static final FcmService instance = FcmService._();
  FcmService._();

  FirebaseMessaging? _messaging;
  String? _token;
  bool _initialized = false;

  /// Token 刷新回调
  void Function(String newToken)? onTokenRefresh;

  String? get token => _token;
  bool get isInitialized => _initialized;

  /// Token 获取配置
  static const int _maxRetries = 3;
  static const Duration _retryBaseDelay = Duration(seconds: 2);
  static const Duration _tokenTimeout = Duration(seconds: 30);

  /// 初始化 FCM
  Future<void> initialize() async {
    // 仅在移动端启用
    if (!UniversalPlatform.isAndroid && !UniversalPlatform.isIOS) {
      debugPrint('[FCM] 非移动平台，跳过初始化');
      return;
    }

    if (_initialized) {
      debugPrint('[FCM] 已初始化，跳过');
      return;
    }

    try {
      // 初始化 Firebase（如果尚未初始化）
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }

      _messaging = FirebaseMessaging.instance;

      // 请求通知权限
      await _requestPermission();

      // 获取 FCM Token（带重试）
      debugPrint('[FCM] 正在获取 Token...');
      _token = await _getTokenWithRetry();
      if (_token != null) {
        debugPrint('[FCM] Token: $_token');
      } else {
        debugPrint('[FCM] Token 获取失败，将在后台继续尝试');
      }

      // 监听 Token 刷新
      _messaging!.onTokenRefresh.listen((newToken) {
        _token = newToken;
        debugPrint('[FCM] Token 刷新: $newToken');
        // 调用回调
        onTokenRefresh?.call(newToken);
      });

      // 设置前台消息处理
      setupForegroundHandler();

      // 设置消息打开应用处理
      _setupOnMessageOpenedAppHandler();

      // 获取初始消息（冷启动）
      await _getInitialMessage();

      _initialized = true;
      debugPrint('[FCM] 初始化完成');
    } catch (e, stack) {
      debugPrint('[FCM] 初始化失败: $e');
      debugPrint('[FCM] 堆栈: $stack');
    }
  }

  /// 带重试的 Token 获取
  Future<String?> _getTokenWithRetry() async {
    for (int attempt = 1; attempt <= _maxRetries; attempt++) {
      try {
        final token = await _messaging!.getToken().timeout(
          _tokenTimeout,
          onTimeout: () => throw TimeoutException('获取 Token 超时'),
        );
        debugPrint('[FCM] Token 获取成功 (第 $attempt 次)');
        return token;
      } catch (e) {
        debugPrint('[FCM] 获取 Token 失败 (第 $attempt/$_maxRetries 次): $e');

        if (attempt < _maxRetries) {
          // 指数退避：2s, 4s, 6s...
          final delay = Duration(
            seconds: _retryBaseDelay.inSeconds * attempt,
          );
          debugPrint('[FCM] ${delay.inSeconds} 秒后重试...');
          await Future.delayed(delay);
        }
      }
    }

    // 所有重试失败后，启动后台重试
    _startBackgroundRetry();
    return null;
  }

  /// 后台持续重试获取 Token
  void _startBackgroundRetry() {
    debugPrint('[FCM] 启动后台 Token 重试...');

    // 延迟 30 秒后开始后台重试
    Future.delayed(const Duration(seconds: 30), () async {
      if (_token != null) return; // 已获取到 Token，无需重试

      int retryCount = 0;
      while (_token == null && retryCount < 10) {
        retryCount++;
        try {
          final token = await _messaging!.getToken().timeout(_tokenTimeout);
          _token = token;
          debugPrint('[FCM] 后台重试成功，Token: $token');
          return;
        } catch (e) {
          debugPrint('[FCM] 后台重试失败 ($retryCount/10): $e');
          await Future.delayed(const Duration(minutes: 1));
        }
      }

      if (_token == null) {
        debugPrint('[FCM] 后台重试已达上限，放弃获取 Token');
      }
    });
  }

  Future<void> _requestPermission() async {
    if (_messaging == null) return;

    final settings = await _messaging!.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    debugPrint('[FCM] 权限状态: ${settings.authorizationStatus}');

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('[FCM] 用户已授权通知');
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      debugPrint('[FCM] 用户已授权临时通知');
    } else {
      debugPrint('[FCM] 用户未授权通知');
    }
  }

  /// 设置前台消息处理器
  void setupForegroundHandler() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('[FCM] 前台收到消息');
      debugPrint('[FCM] 标题: ${message.notification?.title}');
      debugPrint('[FCM] 内容: ${message.notification?.body}');
      debugPrint('[FCM] 数据: ${message.data}');

      // 可以在这里显示本地通知
      // _showLocalNotification(message);
    });
  }

  void _setupOnMessageOpenedAppHandler() {
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('[FCM] 从通知栏点击打开');
      debugPrint('[FCM] 数据: ${message.data}');

      // 处理导航或其他逻辑
      _handleMessageNavigation(message);
    });
  }

  Future<void> _getInitialMessage() async {
    final initialMessage = await _messaging?.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('[FCM] 冷启动通知: ${initialMessage.data}');
      _handleMessageNavigation(initialMessage);
    }
  }

  void _handleMessageNavigation(RemoteMessage message) {
    final data = message.data;
    if (data.isEmpty) return;

    // 根据 data 中的 type 和 id 等字段进行导航
    final type = data['type'];
    final id = data['id'];

    debugPrint('[FCM] 处理导航: type=$type, id=$id');

    // 示例：根据类型导航到不同页面
    // switch (type) {
    //   case 'chat':
    //     navigatorKey.currentState?.pushNamed('/chat', arguments: {'channelId': id});
    //     break;
    //   case 'todo':
    //     navigatorKey.currentState?.pushNamed('/todo', arguments: {'taskId': id});
    //     break;
    // }
  }

  /// 订阅主题
  Future<void> subscribeToTopic(String topic) async {
    if (_messaging == null) return;
    try {
      await _messaging!.subscribeToTopic(topic);
      debugPrint('[FCM] 已订阅主题: $topic');
    } catch (e) {
      debugPrint('[FCM] 订阅主题失败: $e');
    }
  }

  /// 取消订阅主题
  Future<void> unsubscribeFromTopic(String topic) async {
    if (_messaging == null) return;
    try {
      await _messaging!.unsubscribeFromTopic(topic);
      debugPrint('[FCM] 已取消订阅主题: $topic');
    } catch (e) {
      debugPrint('[FCM] 取消订阅主题失败: $e');
    }
  }

  /// 删除 Token
  Future<void> deleteToken() async {
    if (_messaging == null) return;
    try {
      await _messaging!.deleteToken();
      _token = null;
      debugPrint('[FCM] Token 已删除');
    } catch (e) {
      debugPrint('[FCM] 删除 Token 失败: $e');
    }
  }
}
