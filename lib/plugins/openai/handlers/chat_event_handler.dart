import 'dart:async';
import 'dart:developer' as developer;
import '../../../core/event/event.dart';
import '../controllers/agent_controller.dart';
import '../services/request_service.dart';
import '../../chat/models/message.dart';
import '../../chat/models/user.dart';
import '../../../utils/image_utils.dart';

class ChatEventHandler {
  final AgentController _agentController = AgentController();
  final eventManager = EventManager.instance;

  // 存储每个消息ID对应的controller，用于更新消息内容
  final Map<String, StreamController<String>> _messageControllers = {};
  final Map<String, StringBuffer> _messageBuffers = {};

  // 清理特定消息的资源
  void _cleanupMessageResources(String messageId) {
    final controller = _messageControllers[messageId];
    if (controller != null && !controller.isClosed) {
      controller.close();
    }
    _messageControllers.remove(messageId);
    _messageBuffers.remove(messageId);
  }

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

    // 处理文件路径，如果存在的话
    String? absoluteFilePath;
    bool hasImage = false;
    if (metadata.containsKey('file') && metadata['file'] != null) {
      final fileMetadata = metadata['file'] as Map<String, dynamic>;
      if (fileMetadata.containsKey('path')) {
        absoluteFilePath = await PathUtils.toAbsolutePath(fileMetadata['path']);
        // 检查是否为图片文件
        final extension = absoluteFilePath.toLowerCase();
        hasImage =
            extension.endsWith('.jpg') ||
            extension.endsWith('.jpeg') ||
            extension.endsWith('.png') ||
            extension.endsWith('.gif') ||
            extension.endsWith('.webp');
      }
    }

    final List<Map<String, dynamic>> agents = List<Map<String, dynamic>>.from(
      metadata['agents'],
    );
    if (agents.isEmpty) return;

    // eventManager.broadcast('onMessageUpdated', Value<Message>(message));

    // 为每个被@的AI agent创建独立的异步任务处理回复
    final List<Future<void>> agentTasks = [];
    for (final agentData in agents) {
      // 创建独立的异步任务
      final task = _processAgentResponse(
        agentData,
        message,
        absoluteFilePath,
        hasImage,
      );
      agentTasks.add(task);
    }
    // 并行执行所有agent的任务
    await Future.wait(agentTasks);
  }

  // 将单个agent的响应处理逻辑抽取为独立方法
  Future<void> _processAgentResponse(
    Map<String, dynamic> agentData,
    Message originalMessage,
    String? absoluteFilePath,
    bool hasImage,
  ) async {
    // 预先定义变量，以便在catch块中访问
    late User aiUser;
    Message? typingMessage;
    try {
      // 创建AI用户
      aiUser = User(
        id: agentData['id'] ?? 'ai',
        username: agentData['name'] ?? 'AI',
      );

      // 创建AI回复消息，使用agent的ID确保唯一性
      final messageId =
          'ai_${originalMessage.id}_${agentData['id']}_${DateTime.now().millisecondsSinceEpoch}';
      typingMessage = await Message.create(
        id: messageId,
        content: '正在思考...',
        user: aiUser,
        type: MessageType.received,
        metadata: {
          'isAI': true,
          'isStreaming': true,
          'replyTo': originalMessage.id, // 标记为对原消息的回复
        },
      );

      // 创建消息流控制器和内容缓冲区
      final streamController = StreamController<String>();
      final contentBuffer = StringBuffer();
      _messageControllers[messageId] = streamController;
      _messageBuffers[messageId] = contentBuffer;
      int tokenCount = 0;

      developer.log(
        '开始处理来自用户的消息: ${originalMessage.content}',
        name: 'ChatEventHandler',
      );

      // 发布AI回复消息创建事件，添加agent标识
      typingMessage.metadata?['agentId'] = agentData['id'];
      eventManager.broadcast('onMessageCreate', Value<Message>(typingMessage));

      // 获取agent配置
      final agent = await _agentController.getAgent(agentData['id']);
      if (agent == null) {
        _updateTypingMessage(messageId, '抱歉，找不到指定的AI助手配置', aiUser);
        return; // 使用return替代continue，因为我们现在在一个独立的异步方法中
      }

      // 启动流式响应
      await RequestService.streamResponse(
        agent: agent,
        prompt: originalMessage.content,
        vision: hasImage, // 如果有图片，启用vision模式
        filePath: absoluteFilePath, // 传递文件路径
        onToken: (token) async {
          if (!streamController.isClosed) {
            if (tokenCount == 0) {
              contentBuffer.clear();
            }
            // 处理token并添加到缓冲区
            contentBuffer.write(token);
            tokenCount++;

            // 检查并处理思考过程的标记
            String currentContent = contentBuffer.toString();
            String processedContent = _processThinkingContent(currentContent);

            // 更新 typingMessage 的内容
            if (typingMessage != null) {
              typingMessage.content = processedContent;
              // 保持agent标识
              typingMessage.metadata?['agentId'] = agentData['id'];
              eventManager.broadcast(
                'onMessageUpdated',
                Value<Message>(typingMessage),
              );
            }
          }
        },
        onError: (error) {
          developer.log(
            '生成回复时出现错误: $error',
            name: 'ChatEventHandler',
            error: error,
          );
          if (typingMessage != null) {
            _updateTypingMessage(
              typingMessage.id,
              '抱歉，生成回复时出现错误：$error',
              aiUser,
            );
          }

          // 清理资源
          final messageId = typingMessage?.id ?? '';
          streamController.close();
          _cleanupMessageResources(messageId);
        },
        onComplete: () async {
          developer.log(
            '完成消息生成，最终长度: ${contentBuffer.length}，Token数: $tokenCount',
            name: 'ChatEventHandler',
          );

          // 直接更新 typingMessage 的内容和元数据
          if (typingMessage != null) {
            // 在完成时也处理一次思考过程的标记
            String finalContent = _processThinkingContent(
              contentBuffer.toString(),
            );
            typingMessage.content = finalContent;
            // 保持agent标识
            typingMessage.metadata = {
              'isAI': true,
              'agentId': agentData['id'],
            }; // 移除 isStreaming 标记

            // 广播最终的消息更新事件
            eventManager.broadcast(
              'onMessageUpdated',
              Value<Message>(typingMessage),
            );
          }

          // 清理资源
          streamController.close();
          if (typingMessage != null) {
            _cleanupMessageResources(typingMessage.id);
          }
        },
      );
    } catch (e) {
      developer.log('处理AI回复时出错', name: 'ChatEventHandler', error: e);
      if (typingMessage != null) {
        _updateTypingMessage(typingMessage.id, '处理AI回复时出错：$e', aiUser);
      } else {
        // 如果typingMessage未创建，则创建一个新的错误消息
        final errorMessageId = DateTime.now().millisecondsSinceEpoch.toString();
        _updateTypingMessage(errorMessageId, '处理AI回复时出错：$e', aiUser);
      }
      return; // 使用return替代continue，因为我们现在在一个独立的异步方法中
    }
  }

  void _updateTypingMessage(String messageId, String content, User user) async {
    final updatedMessage = await Message.create(
      id: messageId,
      content: content,
      user: user,
      type: MessageType.received,
      metadata: {'isAI': true, 'isError': true, 'agentId': user.id},
    );

    eventManager.broadcast('onMessageUpdated', Value<Message>(updatedMessage));
  }

  String _processThinkingContent(String content) {
    // 检查是否存在完整的思考过程（已结束的思考）
    if (content.contains('<think>') && content.contains('</think>')) {
      // 使用正则表达式匹配所有思考过程
      final pattern = RegExp(r'<think>(.*?)</think>', dotAll: true);
      return content.replaceAllMapped(pattern, (match) {
        // 将思考过程转换为 Markdown blockquote 格式
        String thinkingContent = match.group(1) ?? '';
        // 在每一行前面添加 > 符号，实现 blockquote 效果
        String formattedContent = thinkingContent
            .trim()
            .split('\n')
            .map((line) => '> $line')
            .join('\n');
        return '\n\n**思考过程：**\n$formattedContent\n\n';
      });
    }
    // 处理未结束的思考过程
    else if (content.contains('<think>')) {
      // 将未结束的思考过程转换为 blockquote 格式
      final pattern = RegExp(r'<think>(.*)$', dotAll: true);
      return content.replaceAllMapped(pattern, (match) {
        String thinkingContent = match.group(1) ?? '';
        String formattedContent = thinkingContent
            .trim()
            .split('\n')
            .map((line) => '> $line')
            .join('\n');
        return '\n\n**思考中...**\n$formattedContent';
      });
    }
    return content;
  }

  void dispose() {
    // 获取所有消息ID的副本，因为我们会在循环中修改集合
    final messageIds = _messageControllers.keys.toList();

    // 使用_cleanupMessageResources清理每个消息的资源
    for (final messageId in messageIds) {
      _cleanupMessageResources(messageId);
    }
  }
}
