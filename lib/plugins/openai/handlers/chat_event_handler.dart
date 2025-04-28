import 'dart:async';
import 'dart:developer' as developer;
import '../../../core/event/event.dart';
import '../controllers/agent_controller.dart';
import '../services/ai_service.dart';
import '../../chat/models/message.dart';
import '../../chat/models/user.dart';

class ChatEventHandler {
  final AgentController _agentController = AgentController();
  final AIService _aiService = AIService();
  final eventManager = EventManager.instance;
  
  // 存储每个消息ID对应的controller，用于更新消息内容
  final Map<String, StreamController<String>> _messageControllers = {};
  final Map<String, StringBuffer> _messageBuffers = {};

  void initialize() {
    // 订阅聊天消息事件
    eventManager.subscribe('onMessageSent', _handleChatMessage);
  }

  Future<void> _handleChatMessage(EventArgs args) async {
    if (args is! Value<Message>) return;
    
    final message = args.value;
    final metadata = message.metadata;
    
    developer.log('收到新消息: ${message.content}', name: 'ChatEventHandler');
    
    // 检查消息是否包含agent信息
    if (metadata == null || !metadata.containsKey('agents')) return;
    
    final List<Map<String, dynamic>> agents = List<Map<String, dynamic>>.from(metadata['agents']);
    if (agents.isEmpty) return;

    // 为每个被@的AI agent创建回复
    for (final agentData in agents) {
      // 预先定义变量，以便在catch块中访问
      late User aiUser;
      Message? typingMessage;
      try {
        // 创建AI用户
        aiUser = User(
          id: agentData['id'] ?? 'ai',
          username: agentData['name'] ?? 'AI',
        );

        // 创建"正在输入"的临时消息
        typingMessage = await Message.create(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          content: '正在思考...',
          user: aiUser,
          type: MessageType.received,
          metadata: {'isAI': true},
        );

        // 广播临时消息
        eventManager.broadcast(
          'onMessageReceived',
          Value<Message>(typingMessage),
        );

        // 获取agent配置
        final agent = await _agentController.getAgent(agentData['id']);
        if (agent == null) {
          _updateTypingMessage(typingMessage?.id ?? '', '抱歉，找不到指定的AI助手配置', aiUser);
          continue;
        }

        // 创建消息流控制器和内容缓冲区
        final streamController = StreamController<String>();
        final contentBuffer = StringBuffer();
        final messageId = typingMessage?.id ?? '';
        _messageControllers[messageId] = streamController;
        _messageBuffers[messageId] = contentBuffer;
        int tokenCount = 0;

        developer.log(
          '开始处理来自用户的消息: ${message.content}',
          name: 'ChatEventHandler'
        );
        
        // 启动流式响应
        _aiService.streamResponse(
          agent: agent,
          prompt: message.content,
          onToken: (token) async {
            if (!streamController.isClosed) {
              streamController.add(token);
              contentBuffer.write(token);
              tokenCount++;
              
              // 更新消息内容
              final updatedMessage = await Message.create(
                id: typingMessage?.id ?? '',
                content: contentBuffer.toString(),
                user: aiUser,
                type: MessageType.received,
                date: typingMessage?.date,
                metadata: {'isAI': true},
              );

              if (tokenCount % 5 == 0) {
                developer.log(
                  '更新消息内容: 已接收 $tokenCount 个token，当前长度: ${contentBuffer.length}',
                  name: 'ChatEventHandler'
                );
              }

              eventManager.broadcast(
                'onMessageUpdated',
                Value<Message>(updatedMessage),
              );
            }
          },
          onError: (error) {
            developer.log(
              '生成回复时出现错误: $error',
              name: 'ChatEventHandler',
              error: error
            );
            _updateTypingMessage(typingMessage!.id, '抱歉，生成回复时出现错误：$error', aiUser);
            
            // 清理资源
            final messageId = typingMessage?.id ?? '';
            streamController.close();
            _messageControllers.remove(messageId);
            _messageBuffers.remove(messageId);
          },
          onComplete: () async {
            developer.log(
              '完成消息生成，最终长度: ${contentBuffer.length}，Token数: $tokenCount',
              name: 'ChatEventHandler'
            );
            
            try {
              // 创建最终消息
              final finalMessage = await Message.create(
                id: typingMessage?.id ?? '',
                content: contentBuffer.toString(),
                user: aiUser,
                type: MessageType.received,
                date: typingMessage?.date,
                metadata: {'isAI': true},
              );

              // 先广播一个消息更新事件
              eventManager.broadcast(
                'onMessageUpdated',
                Value<Message>(finalMessage),
              );

              // 再广播一个新消息接收事件，确保界面能收到新消息
              eventManager.broadcast(
                'onMessageReceived',
                Value<Message>(finalMessage),
              );

              developer.log(
                '已发送最终消息：${finalMessage.content}',
                name: 'ChatEventHandler'
              );
            } catch (e) {
              developer.log(
                '发送最终消息时出错：$e',
                name: 'ChatEventHandler',
                error: e,
              );
            }

            // 清理资源
            streamController.close();
            _messageControllers.remove(typingMessage?.id);
            _messageBuffers.remove(typingMessage?.id);
          },
        );
      } catch (e) {
        developer.log(
          '处理AI回复时出错',
          name: 'ChatEventHandler',
          error: e,
        );
        if (typingMessage != null) {
          _updateTypingMessage(
            typingMessage.id,
            '处理AI回复时出错：$e',
            aiUser,
          );
        } else {
          // 如果typingMessage未创建，则创建一个新的错误消息
          final errorMessageId = DateTime.now().millisecondsSinceEpoch.toString();
          _updateTypingMessage(
            errorMessageId,
            '处理AI回复时出错：$e',
            aiUser,
          );
        }
        continue;
      }
    }
  }

  void _updateTypingMessage(String messageId, String content, User user) async {
    final updatedMessage = await Message.create(
      id: messageId,
      content: content,
      user: user,
      type: MessageType.received,
      metadata: {'isAI': true, 'isError': true},
    );

    eventManager.broadcast(
      'onMessageUpdated',
      Value<Message>(updatedMessage),
    );
  }

  void dispose() {
    // 清理所有活跃的消息流
    for (final controller in _messageControllers.values) {
      if (!controller.isClosed) {
        controller.close();
      }
    }
    _messageControllers.clear();
  }
}