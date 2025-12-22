import 'package:flutter/foundation.dart';
import '../../../services/conversation_service.dart';
import '../../../services/message_service.dart';
import '../../../services/message_detail_service.dart';
import '../../../services/tool_template_service.dart';
import '../../../models/chat_message.dart';

/// 管理器共享上下文
///
/// 提供所有管理器需要的共享依赖和工具方法
/// 遵循 DRY 原则,避免重复代码
class ManagerContext {
  final String conversationId;
  final MessageService messageService;
  final ConversationService conversationService;
  final MessageDetailService messageDetailService;
  final ToolTemplateService? templateService;

  /// 获取插件设置的回调
  final Map<String, dynamic> Function()? getSettings;

  /// 状态通知回调 - 用于触发 UI 更新
  final VoidCallback? notifyListeners;

  ManagerContext({
    required this.conversationId,
    required this.messageService,
    required this.conversationService,
    required this.messageDetailService,
    this.templateService,
    this.getSettings,
    this.notifyListeners,
  });

  /// 保存消息详情到本地存储
  ///
  /// 用于调试和审计,保存完整的请求/响应上下文
  Future<void> saveMessageDetail({
    required String messageId,
    required String userPrompt,
    required String fullAIInput,
    required String thinkingProcess,
    Map<String, dynamic>? toolCallData,
    required String finalReply,
  }) async {
    try {
      await messageDetailService.saveDetail(
        conversationId: conversationId,
        messageId: messageId,
        userPrompt: userPrompt,
        fullAIInput: fullAIInput,
        thinkingProcess: thinkingProcess,
        toolCallData: toolCallData,
        finalReply: finalReply,
      );
    } catch (e) {
      debugPrint('保存消息详情失败: $e');
    }
  }

  /// 格式化上下文消息为可读字符串
  ///
  /// 用于日志和调试显示
  String formatContextMessages(List<ChatMessage> messages) {
    return messages
        .map((msg) => '${msg.isUser ? "用户" : "AI"}: ${msg.content.substring(0, msg.content.length > 50 ? 50 : msg.content.length)}...')
        .join('\n');
  }

  /// 获取设置值
  T? getSetting<T>(String key, [T? defaultValue]) {
    try {
      final settings = getSettings?.call();
      return settings?[key] as T? ?? defaultValue;
    } catch (e) {
      return defaultValue;
    }
  }

  /// 触发 UI 更新
  void notify() {
    notifyListeners?.call();
  }
}
