import 'dart:async';
import 'dart:developer' as developer;
import '../../../core/event/event.dart';
import '../../../core/plugin_manager.dart';
import 'package:openai_dart/openai_dart.dart';
import '../../chat/chat_plugin.dart';
import '../openai_plugin.dart';
import '../services/request_service.dart';
import '../../chat/models/message.dart';
import '../../chat/models/user.dart';
import '../../../utils/image_utils.dart';
import '../../chat/services/channel_service.dart';

class ChatEventHandler {
  late final _agentController = OpenAIPlugin.instance.controller;
  final eventManager = EventManager.instance;
  ChatPlugin get _plugin => PluginManager.instance.getPlugin('chat')! as ChatPlugin;

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
    developer.log('ChatEventHandler已初始化', name: 'ChatEventHandler');
  }

  Future<void> _handleChatMessage(EventArgs args) async {
    if (args is! Value<Message>) return;

    final message = args.value;
    final metadata = message.metadata;

    // 保存用户消息
    final channelId = message.channelId ?? 'default';
    await _plugin.channelService.saveMessage(message);
    _plugin.notifyListeners();
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
        iconPath:await ImageUtils.getAbsolutePath(agent.avatarUrl),
      );

      // 创建AI回复消息，使用agent的ID确保唯一性
      final messageId =
          'ai_${originalMessage.id}_${agentData['id']}_${DateTime.now().millisecondsSinceEpoch}';
      typingMessage = await Message.create(
        id: messageId,
        content: '正在思考...',
        channelId: originalMessage.channelId,
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
      
      // 添加AI消息到频道
      final channelId = originalMessage.channelId as String;
      await _plugin.channelService.addMessage(channelId, typingMessage);
      _plugin.notifyListeners();
      
      // 添加短暂延迟，确保消息已被存储到频道中
      await Future.delayed(const Duration(milliseconds: 300));
      
      developer.log(
        '已创建AI回复消息: ${typingMessage.id}',
        name: 'ChatEventHandler',
      );

      // 准备消息列表，首先添加system消息
      List<ChatCompletionMessage> contextMessages = [
        ChatCompletionMessage.system(
          content: agent.systemPrompt ?? 'You are a helpful assistant.',
        ),
      ];

      // 获取历史上下文消息
      if (originalMessage.metadata?.containsKey('contextCount') == true) {
        final contextCount = originalMessage.metadata!['contextCount'] as int;
        if (contextCount > 0) {
          // 添加延迟以确保消息已被存储
          await Future.delayed(const Duration(milliseconds: 500));
          
          final previousMessages = ChatPlugin.instance.channelService.getMessagesBefore(
            originalMessage.id,
            contextCount,
            channelId: channelId,
          );
          
          // 过滤掉typing消息和当前消息
          final filteredMessages = previousMessages.where((msg) {
            // 排除当前消息
            if (msg.id == originalMessage.id) return false;
            if(msg.content.contains('抱歉，生成回复时出现错误')) return false;
            // 排除typing消息
            // if (msg.metadata?.containsKey('isStreaming') == true) return false; // isStreaming 暂时不生效
            return true;
          }).toList();
          
          // 将历史消息转换为AI消息格式，按时间顺序添加
          for (final msg in filteredMessages) {
            if (msg.metadata?.containsKey('isAI') == true) {
              contextMessages.add(ChatCompletionMessage.assistant(
                content: msg.content,
              ));
            } else {
              contextMessages.add(ChatCompletionMessage.user(
                content: ChatCompletionUserMessageContent.string(msg.content),
              ));
            }
          }
        }
      }

      // 最后添加当前用户的消息
      contextMessages.add(ChatCompletionMessage.user(
        content: ChatCompletionUserMessageContent.string(originalMessage.content),
      ));

      await RequestService.streamResponse(
        agent: agent,
        prompt: null, // 不再需要单独的prompt参数，因为已经添加到contextMessages中
        vision: hasImage,
        filePath: absoluteFilePath,
        contextMessages: contextMessages,
        onToken: (token) async {
          if (!streamController.isClosed) {
            if (tokenCount == 0) {
              contentBuffer.clear();
            }
            // 处理token并添加到缓冲区
            contentBuffer.write(token);
            tokenCount++;

            // 立即处理并更新消息内容
            String currentContent = contentBuffer.toString();
            String processedContent = RequestService.processThinkingContent(currentContent);

            // 立即更新 typingMessage 的内容并广播
            if (typingMessage != null) {
              typingMessage.content = processedContent;
              typingMessage.metadata?.addAll({
                'agentId': agentData['id'],
                'isStreaming': true,
                'lastUpdate': DateTime.now().millisecondsSinceEpoch,
              });
              
              // 获取频道ID并立即广播更新
              final channelId = originalMessage.channelId ?? 'default';
              
              // 直接更新消息，不使用microtask以避免时序问题
              if (!streamController.isClosed) {
                await _plugin.channelService.saveMessage(typingMessage!);
                // 不需要额外调用notifyListeners，saveMessage内部已包含
              }
            }
            
            // 添加短暂延迟，避免过于频繁的更新
            await Future.delayed(const Duration(milliseconds: 10));
          }
        },
        onError: (error) async {
          if (typingMessage != null) {
            typingMessage.content = '抱歉，生成回复时出现错误：$error';
            typingMessage.metadata?.addAll({'isError': true});
            final channelId = originalMessage.channelId ?? 'default';
            await _plugin.channelService.saveMessage(typingMessage);
            _plugin.notifyListeners();
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
            String finalContent = RequestService.processThinkingContent(
              contentBuffer.toString(),
            );
            typingMessage.content = finalContent;
            
            // 更新元数据，移除 isStreaming 标记
            typingMessage.metadata = {
              'isAI': true,
              'agentId': agentData['id'],
              'isCompleted': true,
              'completedAt': DateTime.now().millisecondsSinceEpoch,
            };

            // 立即广播最终的消息更新事件
            final channelId = originalMessage.channelId ?? 'default';
            
            // 直接保存消息，不使用microtask以避免时序问题
            await _plugin.channelService.saveMessage(typingMessage!);
            
            // 确保UI更新，使用短暂延迟后再次保存以确保消息完全更新
            await Future.delayed(const Duration(milliseconds: 50));
            await _plugin.channelService.saveMessage(typingMessage!);
          }

          // 延迟一下再清理资源，确保最后的更新被处理
          await Future.delayed(const Duration(milliseconds: 200));
          
          // 清理资源
          if (!streamController.isClosed) {
            streamController.close();
          }
          
          if (typingMessage != null) {
            _cleanupMessageResources(typingMessage.id);
          }
        }
      );
    } catch (e) {
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
        final channelId = originalMessage.metadata?['channelId'] as String? ?? 'default';
        await _plugin.channelService.saveMessage(typingMessage);
        _plugin.notifyListeners();
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

    // 添加消息到频道
    final channelId = message.metadata?['channelId'] as String? ?? 'default';
    await _plugin.channelService.addMessage(channelId, message);
    _plugin.notifyListeners();
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