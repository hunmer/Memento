import 'package:flutter/foundation.dart';
import '../../../core/storage/storage_manager.dart';

/// 消息详细信息服务
///
/// 管理工具调用消息的详细数据（用户输入、思考过程、工具调用、最终回复）
// ignore: unintended_html_in_doc_comment
/// 数据以独立JSON文件存储，路径：agent_chat/message_details/<messageId>.json
class MessageDetailService {
  final StorageManager storage;

  /// 内存缓存，避免频繁读取文件
  final Map<String, MessageDetail> _cache = {};

  MessageDetailService({required this.storage});

  /// 保存消息详细数据
  Future<void> saveDetail({
    required String messageId,
    required String conversationId,
    required String userPrompt,
    required String fullAIInput,
    required String thinkingProcess,
    required Map<String, dynamic>? toolCallData,
    required String finalReply,
  }) async {
    try {
      final detail = MessageDetail(
        messageId: messageId,
        conversationId: conversationId,
        userPrompt: userPrompt,
        fullAIInput: fullAIInput,
        thinkingProcess: thinkingProcess,
        toolCallData: toolCallData,
        finalReply: finalReply,
        timestamp: DateTime.now(),
      );

      final path = 'agent_chat/message_details/$messageId';
      await storage.write(path, detail.toJson());

      // 更新缓存
      _cache[messageId] = detail;

      debugPrint('✅ 消息详细数据已保存: $messageId');
    } catch (e) {
      debugPrint('❌ 保存消息详细数据失败: $e');
    }
  }

  /// 加载消息详细数据
  Future<MessageDetail?> loadDetail(String messageId) async {
    // 先检查缓存
    if (_cache.containsKey(messageId)) {
      return _cache[messageId];
    }

    try {
      final path = 'agent_chat/message_details/$messageId';
      final data = await storage.read(path);

      if (data == null) {
        debugPrint('⚠️ 消息详细数据不存在: $messageId');
        return null;
      }

      final detail = MessageDetail.fromJson(data as Map<String, dynamic>);

      // 缓存
      _cache[messageId] = detail;

      return detail;
    } catch (e) {
      debugPrint('❌ 加载消息详细数据失败: $e');
      return null;
    }
  }

  /// 删除消息详细数据
  Future<void> deleteDetail(String messageId) async {
    try {
      final path = 'agent_chat/message_details/$messageId';
      await storage.delete(path);

      // 清除缓存
      _cache.remove(messageId);

      debugPrint('✅ 消息详细数据已删除: $messageId');
    } catch (e) {
      debugPrint('❌ 删除消息详细数据失败: $e');
    }
  }

  /// 删除会话下所有消息的详细数据
  Future<void> deleteConversationDetails(String conversationId, List<String> messageIds) async {
    for (final messageId in messageIds) {
      await deleteDetail(messageId);
    }
  }

  /// 清除缓存
  void clearCache() {
    _cache.clear();
  }
}

/// 消息详细数据模型
class MessageDetail {
  /// 消息ID
  final String messageId;

  /// 会话ID
  final String conversationId;

  /// 用户原始输入
  final String userPrompt;

  /// AI接收到的完整输入（包括系统提示词、上下文消息等）
  final String fullAIInput;

  /// AI思考过程
  final String thinkingProcess;

  /// 工具调用数据（JSON格式）
  final Map<String, dynamic>? toolCallData;

  /// AI最终回复
  final String finalReply;

  /// 保存时间
  final DateTime timestamp;

  MessageDetail({
    required this.messageId,
    required this.conversationId,
    required this.userPrompt,
    required this.fullAIInput,
    required this.thinkingProcess,
    this.toolCallData,
    required this.finalReply,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'messageId': messageId,
      'conversationId': conversationId,
      'userPrompt': userPrompt,
      'fullAIInput': fullAIInput,
      'thinkingProcess': thinkingProcess,
      'toolCallData': toolCallData,
      'finalReply': finalReply,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory MessageDetail.fromJson(Map<String, dynamic> json) {
    return MessageDetail(
      messageId: json['messageId'] as String,
      conversationId: json['conversationId'] as String,
      userPrompt: json['userPrompt'] as String,
      fullAIInput: json['fullAIInput'] as String? ?? json['userPrompt'] as String, // 向后兼容
      thinkingProcess: json['thinkingProcess'] as String,
      toolCallData: json['toolCallData'] as Map<String, dynamic>?,
      finalReply: json['finalReply'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}
