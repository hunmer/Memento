import 'package:flutter/foundation.dart';
import 'package:intelligence/intelligence.dart';
import 'package:intelligence/model/representable.dart';
import 'package:Memento/plugins/agent_chat/services/conversation_service.dart';
import 'package:universal_platform/universal_platform.dart';

/// 同步频道列表到 iOS Intelligence 插件
class ConversationSyncService {
  static final ConversationSyncService instance = ConversationSyncService._();
  ConversationSyncService._();

  /// 同步所有非临时会话到 iOS
  Future<void> syncConversationsToIOS(ConversationService service) async {
    if (!kIsWeb && UniversalPlatform.isIOS) {
      try {
        final conversations = service.getNonTemporaryConversations();

        final representables = conversations.map((conv) {
          return Representable(
            id: conv.id,
            representation: conv.title,
          );
        }).toList();

        await Intelligence().populate(representables);

        debugPrint('[ConversationSync] 已同步 ${representables.length} 个频道到 iOS');
      } catch (e) {
        debugPrint('[ConversationSync] 同步失败: $e');
      }
    }
  }
}
