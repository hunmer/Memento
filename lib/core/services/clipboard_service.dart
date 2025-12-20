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

  /// 是否启用剪贴板监听
  bool enabled = true;

  /// 注册处理器
  void registerHandler(String method, ClipboardMethodHandler handler) {
    _handlers[method] = handler;
    debugPrint('[ClipboardService] 注册处理器: $method');
  }

  /// 注销处理器
  void unregisterHandler(String method) {
    _handlers.remove(method);
    debugPrint('[ClipboardService] 注销处理器: $method');
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
        debugPrint('[ClipboardService] 剪贴板不可用');
        return false;
      }

      final data = ClipboardData(method: method, args: args);
      final jsonStr = jsonEncode(data.toJson());

      final item = DataWriterItem();
      item.add(Formats.plainText(jsonStr));
      await clipboard.write([item]);

      debugPrint('[ClipboardService] 已写入剪贴板: $method');
      return true;
    } catch (e) {
      debugPrint('[ClipboardService] 写入剪贴板失败: $e');
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
    debugPrint('[ClipboardService] 开始检查剪贴板');
    if (!enabled) {
      debugPrint('[ClipboardService] 剪贴板监听已禁用');
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
        debugPrint('[ClipboardService] 未找到处理器: ${data.method}');
        return false;
      }

      // 记录已处理内容
      _lastProcessedContent = text;

      // 调用处理器
      debugPrint('[ClipboardService] 处理剪贴板数据: ${data.method}');
      await handler(data.args);
      return true;
    } catch (e) {
      debugPrint('[ClipboardService] 处理剪贴板失败: $e');
      return false;
    }
  }

  /// 清除上次处理记录（允许重新处理相同内容）
  void clearLastProcessed() {
    _lastProcessedContent = null;
  }
}
