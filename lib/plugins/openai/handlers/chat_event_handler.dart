import 'dart:async';
import 'dart:developer' as developer;
import '../../../core/event/event.dart';
import '../openai_plugin.dart';
import '../services/request_service.dart';
import '../../chat/models/message.dart';
import '../../chat/models/user.dart';
import '../../../utils/image_utils.dart';

class ChatEventHandler {
  late final _agentController = OpenAIPlugin.instance.controller;
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

    // 立即广播用户消息
    eventManager.broadcast(
      'onMessageUpdated',
      Value<Message>(message),
    );
    developer.log('收到新消息: ${message.content}', name: 'ChatEventHandler');

    // 检查消息是否包含agent信息
    if (metadata == null || !metadata.containsKey('agents')) return;

    // 处理文件路径，如果存在的话
    String? absoluteFilePath;
    bool hasImage = false;
    if (metadata.containsKey('file') && metadata['file'] != null) {
      final fileMetadata = metadata['file'] as Map<String, dynamic>;
      if (fileMetadata.containsKey('path')) {
        absoluteFilePath = await ImageUtils.getAbsolutePath(fileMetadata['path']);
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
      // 获取完整的agent对象
      final agent = await _agentController.getAgent(agentData['id']);
      if (agent == null) {
        throw Exception('找不到指定的AI助手配置');
      }
      
      // 使用完整的agent信息创建AI用户
      aiUser = User(
        id: agent.id,
        username: agent.name,
        iconPath: agent.avatarUrl != null ? await ImageUtils.getAbsolutePath(agent.avatarUrl) : '',
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

      // 发布AI回复消息创建事件
      typingMessage.metadata?.addAll({
        'agentId': agentData['id'],
        'replyTo': originalMessage.id,
        'isAI': true,
        'isStreaming': true,
      });
      
      // 立即广播AI消息创建事件
      eventManager.broadcast('onMessageCreate', Value<Message>(typingMessage));

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
            String processedContent =  RequestService.processThinkingContent(currentContent);

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
        onError: (error) async {
          if (typingMessage != null) {
            typingMessage.content = '抱歉，生成回复时出现错误：$error';
            typingMessage.metadata?.addAll({'isError': true});
            eventManager.broadcast(
              'onMessageUpdated',
              Value<Message>(typingMessage),
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
            String finalContent =  RequestService.processThinkingContent(
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
      
      // 创建一个默认的AI用户，用于显示错误消息
      if (!_isAiUserInitialized(aiUser)) {
        aiUser = User(
          id: agentData['id'] ?? 'ai',
          username: agentData['name'] ?? 'AI',
        );
      }
      
      if (typingMessage != null) {
        typingMessage.content = '处理AI回复时出错：$e';
        typingMessage.metadata?.addAll({'isError': true});
        eventManager.broadcast(
          'onMessageUpdated',
          Value<Message>(typingMessage),
        );
      } else {
        // 如果typingMessage未创建，则创建一个新的错误消息
        final errorMessageId = DateTime.now().millisecondsSinceEpoch.toString();
        await _handleErrorMessage(errorMessageId, '处理AI回复时出错：$e', aiUser);
      }
      return; // 使用return替代continue，因为我们现在在一个独立的异步方法中
    }
  }

  // 使用与更新正常消息相同的方法处理错误消息
  Future<void> _handleErrorMessage(String messageId, String content, User user) async {
    // 首先创建消息
    final message = await Message.create(
      id: messageId,
      content: content,
      user: user,
      type: MessageType.received,
      metadata: {'isAI': true, 'isError': true, 'agentId': user.id},
    );

    // 广播消息创建事件
    eventManager.broadcast('onMessageCreate', Value<Message>(message));
  }

  // 检查AI用户是否已初始化
  bool _isAiUserInitialized(User? user) {
    return user != null && user.id.isNotEmpty;
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
