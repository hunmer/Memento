import 'package:Memento/plugins/chat/screens/channel_list/channel_list_screen.dart';
import 'package:get/get.dart';
import 'package:Memento/plugins/chat/screens/timeline/timeline_screen.dart';
import 'package:Memento/plugins/chat/screens/tags/tags_screen.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:Memento/core/widgets/custom_bottom_bar.dart';
import 'package:Memento/plugins/chat/chat_plugin.dart';
import 'package:Memento/plugins/chat/screens/channel_list/controllers/channel_list_controller.dart';
import 'package:Memento/plugins/chat/screens/channel_list/widgets/channel_dialogs/channel_dialog.dart';
import 'package:Memento/core/route/route_history_manager.dart';

/// Chat 插件的底部栏组件
/// 提供频道列表和时间线两个 Tab 的切换功能
class ChatBottomBar extends StatefulWidget {
  final ChatPlugin plugin;

  const ChatBottomBar({super.key, required this.plugin});

  @override
  State<ChatBottomBar> createState() => _ChatBottomBarState();
}

class _ChatBottomBarState extends State<ChatBottomBar>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late int _currentPage;
  final GlobalKey _bottomBarKey = GlobalKey();
  late ChannelListController _channelListController;

  // 使用插件主题色和辅助色（动态计算）
  List<Color> _getColors(BuildContext context) {
    final Color pluginColor = widget.plugin.color;
    final Color secondaryColor = Theme.of(context).colorScheme.secondary;
    final Color tertiaryColor = Theme.of(context).colorScheme.tertiary;
    return [
      pluginColor, // Tab0 - 频道列表 (插件主色)
      secondaryColor, // Tab1 - 时间线
      tertiaryColor, // Tab2 - 标签
    ];
  }

  @override
  void initState() {
    super.initState();
    _currentPage = 0;
    _tabController = TabController(length: 3, vsync: this);
    _channelListController = ChannelListController(
      channels: widget.plugin.channelService.channels,
      chatPlugin: widget.plugin,
    );
    _tabController.animation?.addListener(() {
      final value = _tabController.animation!.value.round();
      if (value != _currentPage && mounted) {
        setState(() {
          _currentPage = value;
        });
        // 更新路由上下文
        _updateRouteContext(value);
      }
    });

    // 初始化时设置路由上下文
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateRouteContext(_currentPage);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _channelListController.dispose();
    super.dispose();
  }

  /// 更新路由上下文，使"询问当前上下文"功能能获取到当前tab状态
  void _updateRouteContext(int tabIndex) {
    String pageId;
    String title;

    switch (tabIndex) {
      case 0:
        pageId = '/chat/channels';
        title = 'chat_channelsTab'.tr;
        break;
      case 1:
        pageId = '/chat/timeline';
        title = 'chat_timelineTab'.tr;
        break;
      case 2:
        pageId = '/chat/tags';
        title = 'chat_tagsTab'.tr;
        break;
      default:
        pageId = '/chat';
        title = 'chat_name'.tr;
    }

    RouteHistoryManager.updateCurrentContext(
      pageId: pageId,
      title: title,
      params: {'tabIndex': tabIndex},
    );
  }

  /// 显示创建频道的对话框
  void _showAddChannelDialog() {
    // 获取当前激活的频道分类，排除"全部"和"未分组"
    String? defaultGroup = _channelListController.selectedGroup;
    if (defaultGroup == "all" || defaultGroup == "ungrouped") {
      defaultGroup = null;
    }

    showDialog(
      context: context,
      builder:
          (context) => ChannelDialog(
            onAddChannel: (channel) async {
              await _channelListController.addChannel(channel);
            },
            defaultGroup: defaultGroup,
      ),
    );
  }

  /// 构建 FAB
  Widget _buildFab() {
    return FloatingActionButton(
      backgroundColor: widget.plugin.color,
      elevation: 4,
      shape: const CircleBorder(),
      onPressed: _showAddChannelDialog,
      child: Icon(
        Icons.add_comment,
        color: widget.plugin.color.computeLuminance() < 0.5
            ? Colors.white
            : Colors.black,
        size: 32,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = _getColors(context);

    return CustomBottomBar(
      colors: colors,
      currentIndex: _currentPage,
      tabController: _tabController,
      bottomBarKey: _bottomBarKey,
      body: (context, controller) => TabBarView(
        controller: _tabController,
        dragStartBehavior: DragStartBehavior.start,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          // Tab0: 频道列表
          ChannelListScreen(
            channels: widget.plugin.channelService.channels,
            chatPlugin: widget.plugin,
            controller: _channelListController,
            onAddChannel: _showAddChannelDialog,
          ),
          // Tab1: 时间线
          TimelineScreen(chatPlugin: widget.plugin),
          // Tab2: 标签
          TagsScreen(chatPlugin: widget.plugin),
        ],
      ),
      fab: _buildFab(),
      children: [
        Tab(
          icon: const Icon(Icons.chat_bubble_outline),
          text: 'chat_channelsTab'.tr,
        ),
        Tab(
          icon: const Icon(Icons.timeline),
          text: 'chat_timelineTab'.tr,
        ),
        Tab(
          icon: const Icon(Icons.tag),
          text: 'chat_tagsTab'.tr,
        ),
      ],
    );
  }
}
