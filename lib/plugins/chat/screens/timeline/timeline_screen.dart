import 'package:flutter/material.dart';
import '../../l10n/chat_localizations.dart';
import '../../chat_plugin.dart';
import 'controllers/timeline_controller.dart';
import 'widgets/timeline_message_card.dart';
import 'widgets/timeline_search_bar.dart';

/// Timeline 主屏幕，显示所有频道的消息时间线
class TimelineScreen extends StatefulWidget {
  final ChatPlugin chatPlugin;

  const TimelineScreen({
    super.key,
    required this.chatPlugin,
  });

  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen> {
  late TimelineController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TimelineController(widget.chatPlugin);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = ChatLocalizations.of(context)!;
    
    return Scaffold(
      body: Column(
        children: [
          // 搜索栏
          TimelineSearchBar(
            controller: _controller,
            chatPlugin: widget.chatPlugin,
          ),
          
          // 消息列表
          Expanded(
            child: ListenableBuilder(
              listenable: _controller,
              builder: (context, _) {
                if (_controller.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (_controller.messages.isEmpty) {
                  if (_controller.searchQuery.isNotEmpty) {
                    return Center(
                      child: Text('No messages found for "${_controller.searchQuery}"'),
                    );
                  }
                  return const Center(
                    child: Text('No messages yet'),
                  );
                }

                return RefreshIndicator(
                  onRefresh: _controller.refreshTimeline,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: _controller.messages.length,
                    itemBuilder: (context, index) {
                      final message = _controller.messages[index];
                      final channel = _controller.getMessageChannel(message);
                      
                      if (channel == null) return const SizedBox.shrink();
                      
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: TimelineMessageCard(
                          message: message,
                          channel: channel,
                          controller: _controller,
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}