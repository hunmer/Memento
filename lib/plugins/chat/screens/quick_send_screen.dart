import 'package:flutter/material.dart';
import 'package:Memento/plugins/chat/chat_plugin.dart';
import 'package:Memento/plugins/chat/models/channel.dart';
import 'package:Memento/plugins/chat/screens/chat_screen/chat_screen.dart';

/// 频道快速发送界面
///
/// 从桌面小组件跳转时使用，自动打开指定频道的聊天界面并聚焦输入框
class QuickSendScreen extends StatefulWidget {
  final String? channelId;

  const QuickSendScreen({
    super.key,
    this.channelId,
  });

  @override
  State<QuickSendScreen> createState() => _QuickSendScreenState();
}

class _QuickSendScreenState extends State<QuickSendScreen> {
  Channel? _targetChannel;
  bool _loading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadChannel();
  }

  Future<void> _loadChannel() async {
    try {
      final plugin = ChatPlugin.instance;

      if (widget.channelId == null || widget.channelId!.isEmpty) {
        // 如果没有指定频道ID，使用默认频道或显示频道列表
        setState(() {
          _loading = false;
        });
        return;
      }

      // 查找指定的频道
      final channel = plugin.channelService.channels
          .firstWhere((c) => c.id == widget.channelId);

      setState(() {
        _targetChannel = channel;
        _loading = false;
      });

      // 自动跳转到聊天界面
      if (mounted) {
        _navigateToChat();
      }
    } catch (e) {
      setState(() {
        _errorMessage = '频道不存在或已被删除';
        _loading = false;
      });
    }
  }

  void _navigateToChat() {
    if (_targetChannel == null) return;

    // 跳转到聊天界面
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          channel: _targetChannel!,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('正在加载...'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('错误'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back),
                label: const Text('返回'),
              ),
            ],
          ),
        ),
      );
    }

    // 如果没有指定频道，显示频道选择界面
    return Scaffold(
      appBar: AppBar(
        title: const Text('选择频道'),
      ),
      body: _buildChannelList(),
    );
  }

  Widget _buildChannelList() {
    final plugin = ChatPlugin.instance;
    final channels = plugin.channelService.channels;

    if (channels.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: Theme.of(context).colorScheme.secondary,
            ),
            const SizedBox(height: 16),
            Text(
              '暂无频道',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              '请先创建频道',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: channels.length,
      itemBuilder: (context, index) {
        final channel = channels[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: channel.backgroundColor,
            child: Icon(
              channel.icon,
              color: Colors.white,
            ),
          ),
          title: Text(channel.title),
          subtitle: channel.messages.isNotEmpty
              ? Text(
                  channel.messages.last.content,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                )
              : null,
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () {
            setState(() {
              _targetChannel = channel;
            });
            _navigateToChat();
          },
        );
      },
    );
  }
}
