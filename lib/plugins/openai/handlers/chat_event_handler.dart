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

/// 用于传递多个值的事件参数
class ValuesEventArgs<T1, T2> implements EventArgs {
  final T1 value1;
  final T2 value2;
  @override
  final String eventName;
  @override
  final DateTime whenOccurred;

  ValuesEventArgs(
    this.value1,
    this.value2, {
    this.eventName = '',
    DateTime? whenOccurred,
  }) : whenOccurred = whenOccurred ?? DateTime.now();
}

class ChatEventHandler {
  late final _agentController = OpenAIPlugin.instance.controller;
  final eventManager = EventManager.instance;
  ChatPlugin get _plugin =>
      PluginManager.instance.getPlugin('chat')! as ChatPlugin;

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

    // 检查消息是否包含agent信息
    if (metadata == null || !metadata.containsKey('agents')) return;

    // 处理文件路径，如果存在的话
    String? absoluteFilePath;
    bool hasImage = false;
    if (metadata.containsKey('file') && metadata['file'] != null) {
      final fileMetadata = metadata['file'] as Map<String, dynamic>;
      if (fileMetadata.containsKey('path')) {
        absoluteFilePath = await ImageUtils.getAbsolutePath(
          fileMetadata['path'],
        );
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
        iconPath: await ImageUtils.getAbsolutePath(agent.avatarUrl),
      );

      // 创建AI回复消息，使用agent的ID确保唯一性
      final messageId =
          'ai_${originalMessage.id}_${agentData['id']}_${DateTime.now().millisecondsSinceEpoch}';
      typingMessage = await Message.create(
        id: messageId,
        content: '正在思考...',
        channelId: originalMessage.channelId,
        user: aiUser,
        replyToId: originalMessage.id, // 标记为对原消息的回复
        type: MessageType.received,
        metadata: {'agentId': agentData['id'], 'isAI': true},
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

      // 添加AI消息到频道
      final channelId = originalMessage.channelId as String;
      await _plugin.channelService.addMessage(channelId, typingMessage);
      // 添加短暂延迟，确保消息已被存储到频道中
      await Future.delayed(const Duration(milliseconds: 300));
      _plugin.notifyListeners();

      developer.log('已创建AI回复消息: ${typingMessage.id}', name: 'ChatEventHandler');

      // 准备消息列表，首先添加system消息
      List<ChatCompletionMessage> contextMessages = [
        ChatCompletionMessage.system(content: agent.systemPrompt),
      ];

      // 获取历史上下文消息
      if (originalMessage.metadata?.containsKey('contextCount') == true) {
        final contextCount = originalMessage.metadata!['contextCount'] as int;
        if (contextCount > 0) {
          // 实现重试机制，最多重试5次，每次延迟500ms
          int retryCount = 0;
          const maxRetries = 5;
          const retryDelay = Duration(milliseconds: 500);
          List<Message> previousMessages = [];

          while (retryCount < maxRetries) {
            previousMessages = ChatPlugin.instance.channelService
                .getMessagesBefore(
                  originalMessage.id,
                  contextCount,
                  channelId: channelId,
                );

            // 如果获取到了消息，就跳出循环
            if (previousMessages.isNotEmpty) {
              break;
            }

            // 如果没有获取到消息，等待500ms后重试
            await Future.delayed(retryDelay);
            retryCount++;
          }

          // 过滤掉typing消息和当前消息
          final filteredMessages =
              previousMessages.where((msg) {
                // 排除当前消息
                if (msg.id == originalMessage.id) return false;
                if (msg.content.contains('抱歉，生成回复时出现错误')) return false;
                return true;
              }).toList();

          // 将历史消息转换为AI消息格式，按时间顺序添加
          for (final msg in filteredMessages) {
            if (msg.metadata?.containsKey('isAI') == true) {
              contextMessages.add(
                ChatCompletionMessage.assistant(content: msg.content),
              );
            } else {
              contextMessages.add(
                ChatCompletionMessage.user(
                  content: ChatCompletionUserMessageContent.string(msg.content),
                ),
              );
            }
          }
        }
      }

      // 最后添加当前用户的消息
      contextMessages.add(
        ChatCompletionMessage.user(
          content: ChatCompletionUserMessageContent.string(
            originalMessage.content,
          ),
        ),
      );

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
            String processedContent = RequestService.processThinkingContent(
              currentContent,
            );

            // 立即更新 typingMessage 的内容并广播
            if (typingMessage != null) {
              typingMessage.content = processedContent;
              typingMessage.metadata?.addAll({
                'agentId': agentData['id'],
                'lastUpdate': DateTime.now().millisecondsSinceEpoch,
              });

              // 获取频道ID并立即广播更新

              // 直接更新消息，不使用microtask以避免时序问题
              if (!streamController.isClosed) {
                // 确保消息保存并触发UI更新
                await _plugin.channelService.saveMessage(typingMessage);

                // 添加额外的通知以确保UI更新
                _plugin.notifyListeners();

                // 通过事件系统广播消息更新事件
                eventManager.broadcast(
                  'onMessageUpdated',
                  ValuesEventArgs(typingMessage, typingMessage.id),
                );
              }
            }

            // 添加短暂延迟，避免过于频繁的更新
            await Future.delayed(const Duration(milliseconds: 10));
          }
        },
        onError: (error) async {
          if (typingMessage != null) {
            typingMessage.content = '抱歉，生成回复时出现错误：$error';
            typingMessage.metadata?.addAll({
              'isError': true,
              'isCompleted': true,
              'completedAt': DateTime.now().millisecondsSinceEpoch,
            });

            // 保存错误消息
            await _plugin.channelService.saveMessage(typingMessage);

            // 确保UI更新
            _plugin.notifyListeners();

            // 通过事件系统广播消息更新事件
            eventManager.broadcast(
              'onMessageUpdated',
              ValuesEventArgs(typingMessage, typingMessage.id),
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
            String finalContent = RequestService.processThinkingContent(
              contentBuffer.toString(),
            );
            typingMessage.content = finalContent;

            // 更新元数据
            typingMessage.metadata = {
              'isAI': true,
              'agentId': agentData['id'],
              'isCompleted': true,
              'completedAt': DateTime.now().millisecondsSinceEpoch,
            };

            // 立即广播最终的消息更新事件

            // 直接保存消息，不使用microtask以避免时序问题
            await _plugin.channelService.saveMessage(typingMessage);

            // 立即通知UI更新
            _plugin.notifyListeners();

            // 通过事件系统广播消息更新事件
            eventManager.broadcast(
              'onMessageUpdated',
              ValuesEventArgs(typingMessage, typingMessage.id),
            );

            // 确保UI更新，使用短暂延迟后再次保存以确保消息完全更新
            await Future.delayed(const Duration(milliseconds: 100));
            await _plugin.channelService.saveMessage(typingMessage);

            // 最后再次通知UI更新
            _plugin.notifyListeners();
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
        },
      );
    } catch (e) {
      return;
    }
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
