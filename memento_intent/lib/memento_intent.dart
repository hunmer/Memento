import 'dart:async';
import 'package:flutter/material.dart';
import 'memento_intent_platform_interface.dart';

/// 共享媒体文件模型
class SharedMediaFile {
  final String path;
  final SharedMediaType type;

  SharedMediaFile(this.path, this.type);

  Map<String, dynamic> toJson() => {
    'path': path,
    'type': type.toString().split('.').last,
  };

  factory SharedMediaFile.fromJson(Map<String, dynamic> json) => SharedMediaFile(
    json['path'] ?? '',
    SharedMediaType.values.firstWhere(
      (e) => e.toString().split('.').last == json['type'],
      orElse: () => SharedMediaType.file,
    ),
  );
}

enum SharedMediaType { image, video, file }

/// Intent 数据模型
class IntentData {
  final String? action;
  final String? data;
  final String? type;
  final Map<String, dynamic>? extras;

  IntentData({this.action, this.data, this.type, this.extras});

  Map<String, dynamic> toJson() => {
    'action': action,
    'data': data,
    'type': type,
    'extras': extras,
  };

  factory IntentData.fromJson(Map<String, dynamic> json) => IntentData(
    action: json['action'],
    data: json['data'],
    type: json['type'],
    extras: json['extras'],
  );
}

/// 深度链接处理器回调
typedef DeepLinkHandler = void Function(Uri uri);
/// 分享文件处理器回调
typedef SharedFilesHandler = void Function(List<SharedMediaFile> files);
/// 分享文本处理器回调
typedef SharedTextHandler = void Function(String text);
/// Intent 数据处理器回调
typedef IntentDataHandler = void Function(IntentData data);

/// MementoIntent 主类
class MementoIntent {
  static final MementoIntent _instance = MementoIntent._internal();
  static MementoIntent get instance => _instance;

  factory MementoIntent() => _instance;
  MementoIntent._internal();

  final MementoIntentPlatform _platform = MementoIntentPlatform.instance;

  // 回调函数
  DeepLinkHandler? onDeepLink;
  SharedFilesHandler? onSharedFiles;
  SharedTextHandler? onSharedText;
  IntentDataHandler? onIntentData;

  // Stream Subscriptions
  StreamSubscription<Uri>? _linkSubscription;
  StreamSubscription<String>? _textSubscription;
  StreamSubscription<List<SharedMediaFile>>? _mediaSubscription;
  StreamSubscription<IntentData>? _intentSubscription;

  /// 初始化插件
  ///
  /// 必须在 main() 中尽早调用，或在应用启动时调用
  Future<void> init() async {
    // 注册事件流处理器
    _registerEventHandlers();
  }

  /// 注册事件处理器
  void _registerEventHandlers() {
    try {
      // 设置深度链接监听
      _platform.onDeepLink.listen((uri) {
        onDeepLink?.call(uri);
      });

      // 设置分享文本监听
      _platform.onSharedText.listen((text) {
        onSharedText?.call(text);
      });

      // 设置分享文件监听
      _platform.onSharedFiles.listen((files) {
        onSharedFiles?.call(files);
      });

      // 设置 Intent 数据监听
      _platform.onIntentData.listen((data) {
        onIntentData?.call(data);
      });
    } catch (e) {
      debugPrint('Error registering event handlers: $e');
    }
  }

  /// 动态注册深度链接 Scheme
  ///
  /// [scheme] - URL Scheme (例如: "myapp")
  /// [host] - 主机名 (可选，例如: "example.com")
  /// [pathPrefix] - 路径前缀 (可选，例如: "/app")
  Future<bool> registerDynamicScheme({
    required String scheme,
    String? host,
    String? pathPrefix,
  }) async {
    try {
      return await _platform.registerDynamicScheme(
        scheme: scheme,
        host: host,
        pathPrefix: pathPrefix,
      );
    } catch (e) {
      debugPrint('Error registering dynamic scheme: $e');
      return false;
    }
  }

  /// 注销动态注册的 Scheme
  Future<bool> unregisterDynamicScheme() async {
    try {
      return await _platform.unregisterDynamicScheme();
    } catch (e) {
      debugPrint('Error unregistering dynamic scheme: $e');
      return false;
    }
  }

  /// 获取所有已注册的动态 Schemes
  Future<List<String>> getDynamicSchemes() async {
    try {
      return await _platform.getDynamicSchemes();
    } catch (e) {
      debugPrint('Error getting dynamic schemes: $e');
      return [];
    }
  }

  /// 清理资源
  void dispose() {
    _linkSubscription?.cancel();
    _textSubscription?.cancel();
    _mediaSubscription?.cancel();
    _intentSubscription?.cancel();
  }

  /// 获取平台版本
  Future<String?> getPlatformVersion() {
    return _platform.getPlatformVersion();
  }
}
