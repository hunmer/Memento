import 'package:flutter/material.dart';
import '../../controllers/conversation_controller.dart';
import '../../models/conversation.dart';

/// 会话列表屏幕
class ConversationListScreen extends StatefulWidget {
  final ConversationController controller;

  const ConversationListScreen({
    super.key,
    required this.controller,
  });

  @override
  State<ConversationListScreen> createState() =>
      _ConversationListScreenState();
}

class _ConversationListScreenState extends State<ConversationListScreen> {
  @override
  void initState() {
    super.initState();
    // 监听控制器变化
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agent Chat'),
        actions: [
          // 搜索按钮
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: 实现搜索功能
            },
          ),
          // 设置按钮
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // TODO: 打开设置页面
            },
          ),
        ],
      ),
      body: widget.controller.isLoading
          ? const Center(child: CircularProgressIndicator())
          : widget.controller.conversations.isEmpty
              ? _buildEmptyState()
              : _buildConversationList(),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateConversationDialog,
        child: const Icon(Icons.add),
        tooltip: '新建会话',
      ),
    );
  }

  /// 空状态视图
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            '还没有任何会话',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '点击右下角的 + 按钮创建新会话',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  /// 会话列表
  Widget _buildConversationList() {
    final conversations = widget.controller.conversations;

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: conversations.length,
      itemBuilder: (context, index) {
        final conversation = conversations[index];
        return _buildConversationCard(conversation);
      },
    );
  }

  /// 会话卡片
  Widget _buildConversationCard(Conversation conversation) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue[100],
          child: Icon(
            conversation.isPinned ? Icons.push_pin : Icons.chat,
            color: Colors.blue[700],
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                conversation.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (conversation.unreadCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${conversation.unreadCount}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (conversation.lastMessagePreview != null) ...[
              const SizedBox(height: 4),
              Text(
                conversation.lastMessagePreview!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
            const SizedBox(height: 4),
            Text(
              _formatDateTime(conversation.lastMessageAt),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _onConversationMenuSelected(
            value,
            conversation,
          ),
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'pin',
              child: Row(
                children: [
                  Icon(
                    conversation.isPinned ? Icons.push_pin_outlined : Icons.push_pin,
                  ),
                  const SizedBox(width: 8),
                  Text(conversation.isPinned ? '取消置顶' : '置顶'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit),
                  SizedBox(width: 8),
                  Text('编辑'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('删除', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
        onTap: () => _openConversation(conversation),
      ),
    );
  }

  /// 格式化时间
  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return '刚刚';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}分钟前';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}小时前';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}天前';
    } else {
      return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
    }
  }

  /// 打开会话
  Future<void> _openConversation(Conversation conversation) async {
    await widget.controller.selectConversation(conversation.id);

    if (mounted) {
      // TODO: 导航到聊天页面
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('打开会话: ${conversation.title}'),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  /// 会话菜单选择
  Future<void> _onConversationMenuSelected(
    String value,
    Conversation conversation,
  ) async {
    switch (value) {
      case 'pin':
        await widget.controller.togglePin(conversation.id);
        break;

      case 'edit':
        _showEditConversationDialog(conversation);
        break;

      case 'delete':
        _showDeleteConfirmDialog(conversation);
        break;
    }
  }

  /// 显示创建会话对话框
  Future<void> _showCreateConversationDialog() async {
    final titleController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('新建会话'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: '会话标题',
                hintText: '输入会话标题',
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            const Text(
              '注意：请先在OpenAI插件中创建Agent',
              style: TextStyle(fontSize: 12, color: Colors.orange),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('创建'),
          ),
        ],
      ),
    );

    if (result == true && titleController.text.isNotEmpty) {
      try {
        // TODO: 实现Agent选择
        // 暂时使用占位符
        await widget.controller.createConversation(
          title: titleController.text,
          agentId: 'placeholder_agent_id',
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('会话创建成功')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('创建失败: $e')),
          );
        }
      }
    }

    titleController.dispose();
  }

  /// 显示编辑会话对话框
  Future<void> _showEditConversationDialog(Conversation conversation) async {
    final titleController = TextEditingController(text: conversation.title);

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('编辑会话'),
        content: TextField(
          controller: titleController,
          decoration: const InputDecoration(
            labelText: '会话标题',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('保存'),
          ),
        ],
      ),
    );

    if (result == true && titleController.text.isNotEmpty) {
      final updated = conversation.copyWith(title: titleController.text);
      await widget.controller.updateConversation(updated);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('会话已更新')),
        );
      }
    }

    titleController.dispose();
  }

  /// 显示删除确认对话框
  Future<void> _showDeleteConfirmDialog(Conversation conversation) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除会话 "${conversation.title}" 吗？\n\n此操作将同时删除所有消息记录，且不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (result == true) {
      await widget.controller.deleteConversation(conversation.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('会话已删除')),
        );
      }
    }
  }
}
