import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:super_clipboard/super_clipboard.dart';

/// 剪贴板数据处理器类型
typedef ClipboardMethodHandler = Future<void> Function(Map<String, dynamic> args);

/// 剪贴板数据结构
class ClipboardData {
  final String method;
  final Map<String, dynamic> args;

  ClipboardData({required this.method, required this.args});

  factory ClipboardData.fromJson(Map<String, dynamic> json) {
    return ClipboardData(
      method: json['method'] as String,
      args: json['args'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() => {
    'method': method,
    'args': args,
  };
}

/// 剪贴板服务
/// 提供统一的剪贴板读写和 method/args 协议处理
class ClipboardService {
  static final ClipboardService _instance = ClipboardService._();
  static ClipboardService get instance => _instance;

  ClipboardService._();

  /// 注册的处理器
  final Map<String, ClipboardMethodHandler> _handlers = {};

  /// 上次处理的剪贴板内容（避免重复处理）
  String? _lastProcessedContent;

  /// 是否启用剪贴板监听（自动读取）
  bool _autoReadEnabled = false;

  /// 获取自动读取状态
  bool get autoReadEnabled => _autoReadEnabled;

  /// 设置自动读取状态
  set autoReadEnabled(bool value) {
    _autoReadEnabled = value;
  }

  /// 是否启用剪贴板监听（已废弃，保留以兼容旧代码）
  @Deprecated('Use autoReadEnabled instead')
  bool get enabled => _autoReadEnabled;

  @Deprecated('Use autoReadEnabled instead')
  set enabled(bool value) {
    _autoReadEnabled = value;
  }

  /// 注册处理器
  void registerHandler(String method, ClipboardMethodHandler handler) {
    _handlers[method] = handler;
  }

  /// 注销处理器
  void unregisterHandler(String method) {
    _handlers.remove(method);
  }

  /// 检查是否有指定 method 的处理器
  bool hasHandler(String method) => _handlers.containsKey(method);

  /// 写入剪贴板（统一格式）
  Future<bool> copyToClipboard({
    required String method,
    required Map<String, dynamic> args,
  }) async {
    try {
      final clipboard = SystemClipboard.instance;
      if (clipboard == null) {
        return false;
      }

      final data = ClipboardData(method: method, args: args);
      final jsonStr = jsonEncode(data.toJson());

      final item = DataWriterItem();
      item.add(Formats.plainText(jsonStr));
      await clipboard.write([item]);

      return true;
    } catch (e) {
      return false;
    }
  }

  /// 读取剪贴板并解析
  Future<ClipboardData?> readFromClipboard() async {
    try {
      final clipboard = SystemClipboard.instance;
      if (clipboard == null) {
        return null;
      }

      final reader = await clipboard.read();
      if (!reader.canProvide(Formats.plainText)) {
        return null;
      }

      final text = await reader.readValue(Formats.plainText);
      if (text == null || text.isEmpty) {
        return null;
      }

      // 尝试解析为 JSON
      final json = jsonDecode(text) as Map<String, dynamic>;

      // 验证是否有 method 字段
      if (!json.containsKey('method')) {
        return null;
      }

      return ClipboardData.fromJson(json);
    } catch (e) {
      // JSON 解析失败或其他错误，静默忽略
      return null;
    }
  }

  /// 处理剪贴板数据（调用注册的 handler）
  /// 返回 true 如果成功处理了数据
  Future<bool> processClipboard() async {
    if (!_autoReadEnabled) {
      return false;
    }

    try {
      final clipboard = SystemClipboard.instance;
      if (clipboard == null) {
        return false;
      }

      final reader = await clipboard.read();
      if (!reader.canProvide(Formats.plainText)) {
        return false;
      }

      final text = await reader.readValue(Formats.plainText);
      if (text == null || text.isEmpty) {
        return false;
      }

      // 检查是否与上次相同（避免重复处理）
      if (text == _lastProcessedContent) {
        return false;
      }

      // 尝试解析
      final data = await readFromClipboard();
      if (data == null) {
        return false;
      }

      // 查找处理器
      final handler = _handlers[data.method];
      if (handler == null) {
        return false;
      }

      // 记录已处理内容
      _lastProcessedContent = text;

      // 调用处理器
      await handler(data.args);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 清除上次处理记录（允许重新处理相同内容）
  void clearLastProcessed() {
    _lastProcessedContent = null;
  }
}
