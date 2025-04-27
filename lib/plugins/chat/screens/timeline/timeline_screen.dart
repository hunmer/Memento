import 'package:Memento/core/plugin_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../../l10n/chat_localizations.dart';
import '../../chat_plugin.dart';
import '../../utils/message_operations.dart';
import 'controllers/timeline_controller.dart';
import 'widgets/timeline_message_card.dart';
import 'widgets/timeline_search_bar.dart';

/// Timeline 主屏幕，显示所有频道的消息时间线
class TimelineScreen extends StatefulWidget {
  final ChatPlugin chatPlugin;

  const TimelineScreen({super.key, required this.chatPlugin});

  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen> {
  late TimelineController _controller;
  bool _isGridView = false; // 控制视图模式：false为默认卡片视图，true为瀑布流视图

  late MessageOperations _messageOperations;

  @override
  void initState() {
    super.initState();
    // 创建消息操作处理器
    _messageOperations = MessageOperations(context);

    // 创建时间线控制器，使用消息操作处理器处理消息操作
    _controller = TimelineController(
      widget.chatPlugin,
      onMessageEdit: (message) async {
        // 导航到消息所在的频道并开始编辑
        final channel = _controller.getMessageChannel(message);
        if (channel != null) {
          final result = await Navigator.pushNamed(
            context,
            '/channel/${channel.id}',
            arguments: {
              'channel': channel,
              'initialMessage': message,
              'startEditing': true, // 指示应该开始编辑这条消息
            },
          );

          // 如果消息被编辑，刷新时间线
          if (result == true) {
            await _controller.refreshTimeline();
          }
        }
      },
      onMessageDelete: (message) async {
        await _messageOperations.deleteMessage(message);
        // 删除消息后直接从控制器的消息列表中移除
        _controller.removeMessage(message);
      },
      onMessageCopy: (message) {
        _messageOperations.copyMessage(message);
      },
      onSetFixedSymbol: (message, symbol) async {
        await _messageOperations.setFixedSymbol(message, symbol);
        // 更新单个消息的状态
        _controller.updateMessage(message);
      },
      onSetBubbleColor: (message, color) async {
        await _messageOperations.setBubbleColor(message, color);
        // 更新单个消息的状态
        _controller.updateMessage(message);
      },
    );

    // 确保在构建完成后添加滚动监听器
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.ensureScrollListenerActive();
    });
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
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => PluginManager.toHomeScreen(context),
        ),
        title: Text(l10n.timelineTab),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        actions: [
          // 添加视图切换按钮
          IconButton(
            icon: Icon(_isGridView ? Icons.view_agenda : Icons.grid_view),
            tooltip: _isGridView ? '切换到卡片视图' : '切换到瀑布流视图',
            onPressed: () {
              setState(() {
                _isGridView = !_isGridView;
              });
            },
          ),
        ],
      ),
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
                  return const Center(child: CircularProgressIndicator());
                }

                if (_controller.messages.isEmpty) {
                  if (_controller.searchQuery.isNotEmpty) {
                    return Center(
                      child: Text(
                        'No messages found for "${_controller.searchQuery}"',
                      ),
                    );
                  }
                  return const Center(child: Text('No messages yet'));
                }

                return RefreshIndicator(
                  onRefresh: _controller.refreshTimeline,
                  child: _isGridView ? _buildGridView() : _buildListView(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // 构建列表视图（默认卡片视图）
  Widget _buildListView() {
    return ListView.builder(
      controller: _controller.scrollController,
      padding: const EdgeInsets.all(8),
      itemCount:
          _controller.messages.length + (_controller.hasMoreMessages ? 1 : 0),
      itemBuilder: (context, index) {
        // 显示加载更多指示器
        if (_controller.hasMoreMessages &&
            index == _controller.messages.length) {
          // 触发加载更多
          _controller.ensureScrollListenerActive();

          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final message = _controller.messages[index];
        final channel = _controller.getMessageChannel(message);

        if (channel == null) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: TimelineMessageCard(
            message: message,
            channel: channel,
            controller: _controller,
            settingsService: widget.chatPlugin.settingsService,
          ),
        );
      },
    );
  }

  // 构建网格视图（瀑布流视图）
  Widget _buildGridView() {
    final padding = 8.0;
    final spacing = 8.0;

    return CustomScrollView(
      controller: _controller.scrollController,
      slivers: [
        SliverPadding(
          padding: EdgeInsets.all(padding),
          sliver: SliverMasonryGrid(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                // 显示加载更多指示器
                if (index >= _controller.messages.length) {
                  if (_controller.hasMoreMessages) {
                    // 触发加载更多
                    _controller.ensureScrollListenerActive();
                    return Container(
                      height: 80,
                      alignment: Alignment.center,
                      child: const CircularProgressIndicator(),
                    );
                  }
                  // 返回空容器而不是null
                  return const SizedBox.shrink();
                }

                // 构建自适应高度的卡片
                return _buildGridCard(index);
              },
              childCount:
                  _controller.messages.length +
                  (_controller.hasMoreMessages ? 1 : 0),
            ),
            gridDelegate: SliverSimpleGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
            ),
            mainAxisSpacing: spacing,
            crossAxisSpacing: spacing,
          ),
        ),
      ],
    );
  }

  // 构建网格卡片
  Widget _buildGridCard(int index) {
    // 检查是否是加载更多指示器
    if (index >= _controller.messages.length) {
      return const Card(child: Center(child: CircularProgressIndicator()));
    }

    final message = _controller.messages[index];
    final channel = _controller.getMessageChannel(message);

    if (channel == null) return const SizedBox.shrink();

    return TimelineMessageCard(
      message: message,
      channel: channel,
      controller: _controller,
      isGridView: true,
      settingsService: widget.chatPlugin.settingsService,
    );
  }
}
