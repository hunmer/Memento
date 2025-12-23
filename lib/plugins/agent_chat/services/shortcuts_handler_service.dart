import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:intelligence/intelligence.dart';
import 'package:Memento/plugins/agent_chat/agent_chat_plugin.dart';
import 'package:Memento/plugins/agent_chat/models/chat_message.dart';
import 'package:Memento/plugins/agent_chat/models/file_attachment.dart';
import 'package:Memento/plugins/agent_chat/models/conversation.dart';
import 'package:Memento/plugins/agent_chat/screens/chat_screen/chat_screen.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
import 'package:Memento/core/app_initializer.dart';

/// iOS Shortcuts 动作处理服务
class ShortcutsHandlerService {
  static final ShortcutsHandlerService instance = ShortcutsHandlerService._();
  ShortcutsHandlerService._();

  StreamSubscription<String>? _subscription;

  /// 初始化监听器
  void initialize() {
    // 监听来自 iOS AppIntent 的消息
    _subscription = Intelligence().selectionsStream().listen((String jsonString) {
      _handleShortcutAction(jsonString);
    });

    debugPrint('[ShortcutsHandler] iOS Shortcuts 监听器已启动');
  }

  /// 处理 Shortcut 动作
  Future<void> _handleShortcutAction(String jsonString) async {
    try {
      debugPrint('[ShortcutsHandler] 收到 Shortcut 数据: $jsonString');

      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      final action = data['action'] as String?;

      if (action == 'send_to_agent_chat') {
        await _handleSendToAgentChat(data);
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
      final existing = controller.conversations.cast<Conversation?>().firstWhere(
            (c) => c?.id == conversationId,
            orElse: () => null,
          );

      if (existing != null) {
        targetConversation = existing;
        debugPrint('[ShortcutsHandler] 使用已有频道: ${existing.title}');
      } else {
        // 频道不存在，创建临时会话
        targetConversation = await controller.conversationService.createTemporaryConversation(
          title: '快捷指令消息',
          routeName: 'shortcuts',
        );
        debugPrint('[ShortcutsHandler] 频道不存在，创建临时会话');
      }
    } else {
      // 未指定频道，创建临时会话
      targetConversation = await controller.conversationService.createTemporaryConversation(
        title: '快捷指令消息',
        routeName: 'shortcuts',
      );
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
          initialFiles: attachmentFiles.isNotEmpty ? attachmentFiles : null, // 传递图片文件
          autoSend: true, // 自动发送消息
        ),
      );

      debugPrint(
        '[ShortcutsHandler] 已导航到聊天界面，消息将自动发送'
        '${attachmentFiles.isNotEmpty ? "（包含 ${attachmentFiles.length} 张图片）" : ""}',
      );
    } else {
      debugPrint('[ShortcutsHandler] 警告：navigatorKey.currentContext 为 null，无法导航');
    }
  }

  /// 销毁监听器
  void dispose() {
    _subscription?.cancel();
    debugPrint('[ShortcutsHandler] 监听器已销毁');
  }
}
