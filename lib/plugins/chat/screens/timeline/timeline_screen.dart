import 'dart:io';
import 'package:get/get.dart';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:Memento/widgets/super_cupertino_navigation_wrapper.dart';
import 'package:Memento/plugins/chat/chat_plugin.dart';
import 'package:Memento/plugins/chat/utils/message_operations.dart';
import 'controllers/timeline_controller.dart';
import 'models/timeline_filter.dart';
import 'widgets/timeline_message_card.dart';
import 'widgets/filter_dialog.dart';

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

    // 从插件配置中恢复视图模式
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _isGridView = widget.chatPlugin.settingsService.timelineIsGridView;
        });
      }
    });

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
      onToggleFavorite: (message) async {
        await _messageOperations.toggleFavorite(message);
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
    final l10n = ChatLocalizations.of(context);

    return SuperCupertinoNavigationWrapper(
      title: Text(l10n.timelineTab),
      largeTitle: l10n.timelineTab,
      enableSearchBar: true,
      searchPlaceholder: '搜索消息...',
      onSearchChanged: (query) {
        // 搜索防抖处理已在控制器中实现
        _controller.searchController.text = query;
      },
      onSearchSubmitted: (query) {
        _controller.searchController.text = query;
      },
      automaticallyImplyLeading: !(Platform.isAndroid || Platform.isIOS),
      actions: [
        // 过滤器按钮
        IconButton(
          icon: Icon(Icons.filter_list),
          tooltip: '过滤器',
          onPressed: () => _showFilterDialog(context),
        ),
        // 视图切换按钮
        IconButton(
          icon: Icon(_isGridView ? Icons.view_agenda : Icons.grid_view),
          tooltip: _isGridView ? '切换到卡片视图' : '切换到瀑布流视图',
          onPressed: () {
            setState(() {
              _isGridView = !_isGridView;
              // 保存视图模式到插件配置
              widget.chatPlugin.settingsService.setTimelineIsGridView(
                _isGridView,
              );
            });
          },
        ),
      ],
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          if (_controller.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_controller.displayMessages.isEmpty) {
            if (_controller.searchQuery.isNotEmpty ||
                _controller.isFilterActive) {
              return Center(
                child: Text(
                  '${l10n.noMessagesFound} "${_controller.searchQuery}"',
                ),
              );
            }
            return Center(child: Text(l10n.noMessagesYet));
          }

          return RefreshIndicator(
            onRefresh: _controller.refreshTimeline,
            child: _isGridView ? _buildGridView() : _buildListView(),
          );
        },
      ),
    );
  }

  // 构建列表视图（默认卡片视图）
  Widget _buildListView() {
    return ListView.builder(
      controller: _controller.scrollController,
      padding: const EdgeInsets.all(8),
      itemCount:
          _controller.displayMessages.length +
          (_controller.hasMoreMessages ? 1 : 0),
      itemBuilder: (context, index) {
        // 显示加载更多指示器
        if (_controller.hasMoreMessages &&
            index == _controller.displayMessages.length) {
          // 在构建完成后触发加载更多，避免在 build 期间调用 setState
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _controller.loadMoreMessages();
          });

          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final message = _controller.displayMessages[index];
        final channel = _controller.getMessageChannel(message);

        if (channel == null) return const SizedBox.shrink();

        // 限制动画延迟，避免列表过长时延迟过大（最多延迟 500ms）
        final animationDelay = ((index * 50).clamp(0, 500)).ms;

        return Animate(
          key: ValueKey(message.id),
          effects: [
            FadeEffect(
              duration: 300.ms,
              delay: animationDelay,
            ),
            SlideEffect(
              begin: const Offset(0, 0.3),
              end: Offset.zero,
              duration: 400.ms,
              delay: animationDelay,
              curve: Curves.easeOut,
            ),
          ],
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: TimelineMessageCard(
              message: message,
              channel: channel,
              controller: _controller,
              settingsService: widget.chatPlugin.settingsService,
            ),
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
                if (index >= _controller.displayMessages.length) {
                  if (_controller.hasMoreMessages) {
                    // 在构建完成后触发加载更多，避免在 build 期间调用 setState
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _controller.loadMoreMessages();
                    });
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
                  _controller.displayMessages.length +
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
    if (index >= _controller.displayMessages.length) {
      return const Card(child: Center(child: CircularProgressIndicator()));
    }

    final message = _controller.displayMessages[index];
    final channel = _controller.getMessageChannel(message);

    if (channel == null) return const SizedBox.shrink();

    // 限制动画延迟，避免列表过长时延迟过大（最多延迟 500ms）
    final animationDelay = ((index * 50).clamp(0, 500)).ms;

    return Animate(
      key: ValueKey(message.id),
      effects: [
        FadeEffect(
          duration: 300.ms,
          delay: animationDelay,
        ),
        SlideEffect(
          begin: const Offset(0, 0.3),
          end: Offset.zero,
          duration: 400.ms,
          delay: animationDelay,
          curve: Curves.easeOut,
        ),
      ],
      child: TimelineMessageCard(
        message: message,
        channel: channel,
        controller: _controller,
        isGridView: true,
        settingsService: widget.chatPlugin.settingsService,
      ),
    );
  }

  /// 显示高级过滤器对话框
  Future<void> _showFilterDialog(BuildContext context) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder:
          (context) => FilterDialog(
            filter: _controller.filter,
            chatPlugin: widget.chatPlugin,
          ),
    );

    if (result != null) {
      // 从 Map 更新过滤器
      _controller.filter.updateFrom(TimelineFilter.fromJson(result));
      // 应用过滤器
      _controller.applyFilter(_controller.filter);
    }
  }
}
