import 'package:flutter/material.dart';
import '../../controllers/chat_controller.dart';
import '../../models/conversation.dart';
import '../../services/message_service.dart';
import '../../services/conversation_service.dart';
import '../../../../core/storage/storage_manager.dart';
import 'components/message_bubble.dart';
import 'components/message_input.dart';

/// 聊天界面
class ChatScreen extends StatefulWidget {
  final Conversation conversation;
  final StorageManager storage;

  const ChatScreen({
    super.key,
    required this.conversation,
    required this.storage,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late final ChatController _controller;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  Future<void> _initializeController() async {
    _controller = ChatController(
      conversation: widget.conversation,
      messageService: MessageService(storage: widget.storage),
      conversationService: ConversationService(storage: widget.storage),
    );

    await _controller.initialize();
    _controller.addListener(_onControllerChanged);

    // 监听MessageService以实现流式响应实时更新
    _controller.messageService.addListener(_onControllerChanged);

    // 初始化完成后滚动到底部
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  void _onControllerChanged() {
    if (mounted) {
      setState(() {});

      // 有新消息时自动滚动到底部
      if (_controller.messages.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });
      }
    }
  }

  void _scrollToBottom({bool animate = false}) {
    if (_scrollController.hasClients) {
      if (animate) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      } else {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.messageService.removeListener(_onControllerChanged);
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.conversation.title,
              style: const TextStyle(fontSize: 16),
            ),
            if (_controller.currentAgent != null)
              Text(
                _controller.currentAgent!.name,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.normal,
                ),
              ),
          ],
        ),
        actions: [
          // Token统计按钮
          IconButton(
            icon: const Icon(Icons.analytics_outlined),
            onPressed: _showTokenStats,
            tooltip: 'Token统计',
          ),
          // 设置按钮
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showSettings,
            tooltip: '会话设置',
          ),
        ],
      ),
      body: _controller.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // 消息列表
                Expanded(
                  child: _controller.messages.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount: _controller.messages.length,
                          itemBuilder: (context, index) {
                            final message = _controller.messages[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: MessageBubble(
                                message: message,
                                onEdit: (messageId, newContent) async {
                                  await _controller.editMessage(
                                      messageId, newContent);
                                },
                                onDelete: (messageId) async {
                                  await _showDeleteConfirmation(messageId);
                                },
                                onRegenerate: (messageId) async {
                                  await _controller.regenerateResponse(messageId);
                                },
                              ),
                            );
                          },
                        ),
                ),

                // 输入框
                MessageInput(controller: _controller),
              ],
            ),
    );
  }

  /// 构建空状态
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            '开始新的对话',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          if (_controller.currentAgent != null)
            Text(
              '当前Agent: ${_controller.currentAgent!.name}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
        ],
      ),
    );
  }

  /// 显示Token统计
  void _showTokenStats() {
    final totalTokens = _controller.getTotalTokens();
    final contextTokens = _controller.getContextTokens();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Token统计'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatRow('总Token数', totalTokens.toString()),
            const SizedBox(height: 8),
            _buildStatRow('上下文Token数', contextTokens.toString()),
            const SizedBox(height: 8),
            _buildStatRow(
              '上下文消息数',
              '${_controller.contextMessageCount} 条',
            ),
            const SizedBox(height: 16),
            Text(
              '注：Token数为估算值，实际消耗以API返回为准',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 14)),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  /// 显示设置对话框
  void _showSettings() {
    int? customContextCount = widget.conversation.contextMessageCount;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('会话设置'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '上下文消息数量',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<int?>(
                      title: const Text('使用全局设置'),
                      value: null,
                      groupValue: customContextCount,
                      onChanged: (value) {
                        setDialogState(() {
                          customContextCount = value;
                        });
                      },
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<int?>(
                      title: const Text('自定义'),
                      value: -1, // 用-1表示自定义模式
                      groupValue:
                          customContextCount == null ? null : -1,
                      onChanged: (value) {
                        setDialogState(() {
                          customContextCount = 10; // 默认值
                        });
                      },
                    ),
                  ),
                ],
              ),
              if (customContextCount != null)
                Padding(
                  padding: const EdgeInsets.only(left: 16, top: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Slider(
                          value: customContextCount!.toDouble(),
                          min: 1,
                          max: 50,
                          divisions: 49,
                          label: customContextCount.toString(),
                          onChanged: (value) {
                            setDialogState(() {
                              customContextCount = value.toInt();
                            });
                          },
                        ),
                      ),
                      SizedBox(
                        width: 40,
                        child: Text(
                          '$customContextCount',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () async {
                // 保存设置
                final updatedConversation = widget.conversation.copyWith(
                  contextMessageCount: customContextCount,
                );
                await _controller.conversationService
                    .updateConversation(updatedConversation);
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('设置已保存')),
                  );
                }
              },
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
  }

  /// 显示删除确认对话框
  Future<void> _showDeleteConfirmation(String messageId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除这条消息吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _controller.deleteMessage(messageId);
    }
  }
}
