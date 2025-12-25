import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:intelligence/intelligence.dart';
import 'package:Memento/plugins/agent_chat/agent_chat_plugin.dart';
import 'package:Memento/plugins/agent_chat/models/conversation.dart';
import 'package:Memento/plugins/agent_chat/screens/chat_screen/chat_screen.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
import 'package:Memento/core/app_initializer.dart';
import 'package:Memento/core/js_bridge/js_bridge_manager.dart';

/// iOS Shortcuts 动作处理服务
class ShortcutsHandlerService {
  static final ShortcutsHandlerService instance = ShortcutsHandlerService._();
  ShortcutsHandlerService._();

  StreamSubscription<String>? _subscription;
  static const MethodChannel _shortcutChannel = MethodChannel(
    'github.hunmer.memento/shortcut_plugin_call',
  );

  /// 初始化监听器
  void initialize() {
    // 监听来自 iOS AppIntent 的消息（用于 send_to_agent_chat）
    _subscription = Intelligence().selectionsStream().listen((
      String jsonString,
    ) {
      _handleShortcutAction(jsonString);
    });

    // 注册 MethodChannel 处理器（用于 call_plugin_method）
    _shortcutChannel.setMethodCallHandler(_handleMethodCall);

    debugPrint('[ShortcutsHandler] iOS Shortcuts 监听器已启动');
  }

  /// 处理来自 MethodChannel 的调用
  Future<dynamic> _handleMethodCall(MethodCall call) async {
    debugPrint('[ShortcutsHandler] ========== MethodChannel 调用开始 ==========');
    debugPrint('[ShortcutsHandler] 方法: ${call.method}');
    debugPrint('[ShortcutsHandler] 参数: ${call.arguments}');

    try {
      switch (call.method) {
        case 'callPluginMethod':
          final result = await _handleCallPluginMethodSync(call.arguments);
          debugPrint('[ShortcutsHandler] ========== 返回结果给 Swift ==========');
          debugPrint('[ShortcutsHandler] 结果类型: ${result.runtimeType}');
          debugPrint('[ShortcutsHandler] 结果内容: $result');
          return result;
        default:
          throw PlatformException(
            code: 'UNKNOWN_METHOD',
            message: '未知的方法: ${call.method}',
          );
      }
    } catch (e, stackTrace) {
      debugPrint('[ShortcutsHandler] ========== MethodChannel 异常 ==========');
      debugPrint('[ShortcutsHandler] 错误: $e');
      debugPrint('[ShortcutsHandler] 堆栈: $stackTrace');
      rethrow;
    }
  }

  /// 处理"调用插件方法"动作（同步版本，通过 MethodChannel）
  Future<Map<String, dynamic>> _handleCallPluginMethodSync(
    Map<dynamic, dynamic> arguments,
  ) async {
    final pluginId = arguments['pluginId'] as String?;
    final methodName = arguments['methodName'] as String?;
    final params = arguments['params'] as Map<dynamic, dynamic>?;

    debugPrint('[ShortcutsHandler] 同步调用插件方法: $pluginId.$methodName');
    debugPrint('[ShortcutsHandler] 参数: $params');

    // 验证必填参数
    if (pluginId == null || pluginId.isEmpty) {
      return {'success': false, 'error': 'pluginId 为空'};
    }

    if (methodName == null || methodName.isEmpty) {
      return {'success': false, 'error': 'methodName 为空'};
    }

    // 检查 JS Bridge 是否已初始化
    if (!JSBridgeManager.instance.isSupported) {
      return {'success': false, 'error': 'JS Bridge 未初始化'};
    }

    try {
      // 转换参数类型
      final Map<String, dynamic> typedParams =
          params != null ? Map<String, dynamic>.from(params) : {};

      // 构建 JavaScript 代码
      final jsCode = _buildJSCode(pluginId, methodName, typedParams);
      debugPrint('[ShortcutsHandler] 生成的 JS 代码:\n$jsCode');

      // 通过 JS Bridge 执行
      final result = await JSBridgeManager.instance.evaluateWhenReady(
        jsCode,
        description: 'Shortcuts: $pluginId.$methodName',
      );

      debugPrint('[ShortcutsHandler] 执行结果: ${result.result}');
      debugPrint('[ShortcutsHandler] 执行状态: ${result.success ? "成功" : "失败"}');

      if (!result.success && result.error != null) {
        return {'success': false, 'error': result.error};
      }

      // 解析 JSON 结果
      try {
        final parsedResult = jsonDecode(result.result ?? '{}');

        // 如果解析结果是 Map，递归解析嵌套的 JSON 字符串
        if (parsedResult is Map) {
          return _deepDecodeJson(Map<String, dynamic>.from(parsedResult));
        }

        return {'success': true, 'data': parsedResult};
      } catch (e) {
        // 如果不是 JSON，直接返回字符串结果
        return {'success': true, 'data': result.result};
      }
    } catch (e, stackTrace) {
      debugPrint('[ShortcutsHandler] 调用插件方法失败: $e');
      debugPrint('[ShortcutsHandler] 堆栈: $stackTrace');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// 处理 Shortcut 动作
  Future<void> _handleShortcutAction(String jsonString) async {
    try {
      debugPrint('[ShortcutsHandler] 收到 Shortcut 数据: $jsonString');

      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      final action = data['action'] as String?;

      switch (action) {
        case 'send_to_agent_chat':
          await _handleSendToAgentChat(data);
          break;
        case 'call_plugin_method':
          await _handleCallPluginMethod(data);
          break;
        default:
          debugPrint('[ShortcutsHandler] 未知的 action: $action');
      }
    } catch (e, stackTrace) {
      debugPrint('[ShortcutsHandler] 处理 Shortcut 失败: $e');
      debugPrint('[ShortcutsHandler] 堆栈: $stackTrace');
    }
  }

  /// 处理"发送消息到AI聊天"动作
  Future<void> _handleSendToAgentChat(Map<String, dynamic> data) async {
    final messageText = data['message'] as String?;
    final conversationId = data['conversationId'] as String?;
    final imagePaths = data['imagePaths'] as List?;

    if (messageText == null || messageText.isEmpty) {
      debugPrint('[ShortcutsHandler] 消息内容为空，忽略');
      return;
    }

    // 获取 AgentChat 插件实例
    final plugin = AgentChatPlugin.instance;
    if (!plugin.isInitialized) {
      debugPrint('[ShortcutsHandler] 插件未初始化，等待初始化...');
      await Future.delayed(const Duration(seconds: 1));

      if (!plugin.isInitialized) {
        debugPrint('[ShortcutsHandler] 插件初始化超时，放弃处理');
        return;
      }
    }

    final controller = plugin.conversationController;
    if (controller == null) {
      debugPrint('[ShortcutsHandler] ConversationController 未初始化');
      return;
    }

    // 1. 确定目标会话
    Conversation targetConversation;

    if (conversationId != null && conversationId.isNotEmpty) {
      // 使用指定的频道
      final existing = controller.conversations
          .cast<Conversation?>()
          .firstWhere((c) => c?.id == conversationId, orElse: () => null);

      if (existing != null) {
        targetConversation = existing;
        debugPrint('[ShortcutsHandler] 使用已有频道: ${existing.title}');
      } else {
        // 频道不存在，创建临时会话
        targetConversation = await controller.conversationService
            .createTemporaryConversation(
              title: '快捷指令消息',
              routeName: 'shortcuts',
            );
        debugPrint('[ShortcutsHandler] 频道不存在，创建临时会话');
      }
    } else {
      // 未指定频道，创建临时会话
      targetConversation = await controller.conversationService
          .createTemporaryConversation(title: '快捷指令消息', routeName: 'shortcuts');
      debugPrint('[ShortcutsHandler] 未指定频道，创建临时会话');
    }

    // 2. 处理图片附件
    final List<File> attachmentFiles = [];

    if (imagePaths != null && imagePaths.isNotEmpty) {
      for (final pathStr in imagePaths) {
        final path = pathStr as String;
        final file = File(path);

        if (await file.exists()) {
          attachmentFiles.add(file);
        } else {
          debugPrint('[ShortcutsHandler] 图片文件不存在: $path');
        }
      }

      debugPrint('[ShortcutsHandler] 处理了 ${attachmentFiles.length} 张图片');
    }

    // 3. 导航到聊天界面
    final context = navigatorKey.currentContext;
    if (context != null) {
      // 导航到聊天界面并自动发送消息（支持文本和图片）
      await NavigationHelper.push(
        context,
        ChatScreen(
          conversation: targetConversation,
          storage: plugin.storage,
          conversationService: controller.conversationService,
          getSettings: () => plugin.settings,
          initialMessage: messageText, // 传递消息文本
          initialFiles:
              attachmentFiles.isNotEmpty ? attachmentFiles : null, // 传递图片文件
          autoSend: true, // 自动发送消息
        ),
      );

      debugPrint(
        '[ShortcutsHandler] 已导航到聊天界面，消息将自动发送'
        '${attachmentFiles.isNotEmpty ? "（包含 ${attachmentFiles.length} 张图片）" : ""}',
      );
    } else {
      debugPrint(
        '[ShortcutsHandler] 警告：navigatorKey.currentContext 为 null，无法导航',
      );
    }
  }

  /// 处理"调用插件方法"动作
  ///
  /// 通过 JS Bridge 执行插件方法，支持任意插件的任意 JavaScript API
  Future<void> _handleCallPluginMethod(Map<String, dynamic> data) async {
    final pluginId = data['pluginId'] as String?;
    final methodName = data['methodName'] as String?;
    final params = data['params'] as Map<String, dynamic>?;
    final callId = data['callId'] as String?; // 调用ID，用于关联结果

    debugPrint('[ShortcutsHandler] 调用插件方法: $pluginId.$methodName');
    debugPrint('[ShortcutsHandler] 调用ID: $callId');
    debugPrint('[ShortcutsHandler] 参数: $params');

    // 验证必填参数
    if (pluginId == null || pluginId.isEmpty) {
      debugPrint('[ShortcutsHandler] 错误: pluginId 为空');
      await _writeShortcutResult(
        callId: callId ?? 'unknown',
        success: false,
        error: 'pluginId 为空',
      );
      return;
    }

    if (methodName == null || methodName.isEmpty) {
      debugPrint('[ShortcutsHandler] 错误: methodName 为空');
      await _writeShortcutResult(
        callId: callId ?? 'unknown',
        success: false,
        error: 'methodName 为空',
      );
      return;
    }

    // 检查 JS Bridge 是否已初始化
    if (!JSBridgeManager.instance.isSupported) {
      debugPrint('[ShortcutsHandler] 错误: JS Bridge 未初始化');
      await _writeShortcutResult(
        callId: callId ?? 'unknown',
        success: false,
        error: 'JS Bridge 未初始化',
      );
      return;
    }

    try {
      // 构建 JavaScript 代码
      final jsCode = _buildJSCode(pluginId, methodName, params ?? {});
      debugPrint('[ShortcutsHandler] 生成的 JS 代码:\n$jsCode');

      // 通过 JS Bridge 执行
      final result = await JSBridgeManager.instance.evaluateWhenReady(
        jsCode,
        description: 'Shortcuts: $pluginId.$methodName',
      );

      debugPrint('[ShortcutsHandler] 执行结果: ${result.result}');
      debugPrint('[ShortcutsHandler] 执行状态: ${result.success ? "成功" : "失败"}');

      // 写入共享文件供 Swift 读取
      if (result.success) {
        // 解析 JSON 结果
        try {
          final parsedResult = jsonDecode(result.result ?? '{}');
          Map<String, dynamic> resultData;

          if (parsedResult is Map) {
            resultData = _deepDecodeJson(Map<String, dynamic>.from(parsedResult));
          } else {
            resultData = {'success': true, 'data': parsedResult};
          }

          await _writeShortcutResult(
            callId: callId ?? 'unknown',
            success: resultData['success'] as bool? ?? true,
            data: resultData['data'],
            error: resultData['error'] as String?,
          );
        } catch (e) {
          // JSON 解析失败，直接返回字符串
          await _writeShortcutResult(
            callId: callId ?? 'unknown',
            success: true,
            data: result.result,
          );
        }
      } else {
        await _writeShortcutResult(
          callId: callId ?? 'unknown',
          success: false,
          error: result.error ?? '执行失败',
        );
      }
    } catch (e, stackTrace) {
      debugPrint('[ShortcutsHandler] 调用插件方法失败: $e');
      debugPrint('[ShortcutsHandler] 堆栈: $stackTrace');
      await _writeShortcutResult(
        callId: callId ?? 'unknown',
        success: false,
        error: e.toString(),
      );
    }
  }

  /// 写入 Shortcut 执行结果到共享文件
  Future<void> _writeShortcutResult({
    required String callId,
    required bool success,
    dynamic data,
    String? error,
  }) async {
    try {
      final resultData = {
        'status': 'completed',
        'success': success,
        'timestamp': DateTime.now().millisecondsSinceEpoch / 1000,
        if (data != null) 'data': data,
        if (error != null) 'error': error,
      };

      await _shortcutChannel.invokeMethod('writeShortcutResult', {
        'callId': callId,
        'result': resultData,
      });

      debugPrint('[ShortcutsHandler] 已写入结果到共享文件: $callId');
    } catch (e) {
      debugPrint('[ShortcutsHandler] 写入共享文件失败: $e');
    }
  }

  /// 构建 JavaScript 调用代码
  ///
  /// 将 Dart 的插件ID、方法名和参数转换为 JavaScript 函数调用
  String _buildJSCode(
    String pluginId,
    String methodName,
    Map<String, dynamic> params,
  ) {
    // 转换参数为 JavaScript 对象字面量
    final paramsStr = _convertParamsToJS(params);

    // 生成 JavaScript 代码
    // 使用 return await IIFE 确保外层包装器等待异步完成
    return '''
return await (async function() {
  try {
    // 调用插件方法
    const result = await Memento.plugins.$pluginId.$methodName($paramsStr);

    // 返回结果
    return JSON.stringify({
      success: true,
      data: result
    });
  } catch (error) {
    // 捕获并返回错误
    return JSON.stringify({
      success: false,
      error: error.message || String(error)
    });
  }
})();
''';
  }

  /// 深度解析 JSON 字符串（递归处理嵌套的 JSON 字符串）
  ///
  /// 某些插件 API 返回的数据可能包含嵌套的 JSON 字符串，
  /// 例如：{success: true, data: "[{...}]"}
  /// 需要递归解析才能得到正确的数据结构
  Map<String, dynamic> _deepDecodeJson(Map<String, dynamic> map) {
    final result = <String, dynamic>{};

    for (final entry in map.entries) {
      final key = entry.key;
      final value = entry.value;

      // 递归处理不同类型的值
      if (value is String) {
        // 尝试解析字符串为 JSON
        try {
          final decoded = jsonDecode(value);
          if (decoded is Map) {
            result[key] = _deepDecodeJson(Map<String, dynamic>.from(decoded));
          } else if (decoded is List) {
            result[key] = _deepDecodeList(decoded);
          } else {
            result[key] = decoded;
          }
        } catch (_) {
          // 不是 JSON 字符串，直接使用原值
          result[key] = value;
        }
      } else if (value is Map) {
        result[key] = _deepDecodeJson(Map<String, dynamic>.from(value));
      } else if (value is List) {
        result[key] = _deepDecodeList(value);
      } else {
        result[key] = value;
      }
    }

    return result;
  }

  /// 深度解析 JSON 列表
  List<dynamic> _deepDecodeList(List<dynamic> list) {
    return list.map((item) {
      if (item is String) {
        try {
          final decoded = jsonDecode(item);
          if (decoded is Map) {
            return _deepDecodeJson(Map<String, dynamic>.from(decoded));
          } else if (decoded is List) {
            return _deepDecodeList(decoded);
          } else {
            return decoded;
          }
        } catch (_) {
          return item;
        }
      } else if (item is Map) {
        return _deepDecodeJson(Map<String, dynamic>.from(item));
      } else if (item is List) {
        return _deepDecodeList(item);
      } else {
        return item;
      }
    }).toList();
  }

  /// 将 Dart Map 转换为 JavaScript 对象字面量
  ///
  /// 支持嵌套对象、数组、基本类型
  String _convertParamsToJS(Map<String, dynamic> params) {
    if (params.isEmpty) {
      return '{}';
    }

    // 使用 jsonEncode 进行安全的序列化
    // 这样可以正确处理字符串转义、特殊字符等
    try {
      return jsonEncode(params);
    } catch (e) {
      debugPrint('[ShortcutsHandler] 参数序列化失败: $e');
      return '{}';
    }
  }

  /// 销毁监听器
  void dispose() {
    _subscription?.cancel();
    debugPrint('[ShortcutsHandler] 监听器已销毁');
  }
}
