import 'package:Memento/plugins/chat/l10n/chat_localizations.dart';
import 'package:Memento/plugins/chat/screens/channel_list/channel_list_screen.dart';
import 'package:Memento/plugins/chat/screens/timeline/timeline_screen.dart';
import 'package:Memento/plugins/chat/screens/create_channel/create_channel_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:smooth_sheets/smooth_sheets.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:Memento/plugins/chat/chat_plugin.dart';

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
  double _bottomBarHeight = 60; // 默认底部栏高度
  final GlobalKey _bottomBarKey = GlobalKey();

  // 使用插件主题色和辅助色
  final List<Color> _colors = [
    Colors.indigoAccent, // Tab0 - 频道列表 (插件主色)
    Colors.blue.shade400, // Tab1 - 时间线
  ];

  @override
  void initState() {
    super.initState();
    _currentPage = 0;
    _tabController = TabController(length: 2, vsync: this);
    _tabController.animation?.addListener(() {
      final value = _tabController.animation!.value.round();
      if (value != _currentPage && mounted) {
        setState(() {
          _currentPage = value;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// 调度底部栏高度测量
  void _scheduleBottomBarHeightMeasurement() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _bottomBarKey.currentContext != null) {
        final RenderBox renderBox = _bottomBarKey.currentContext!.findRenderObject() as RenderBox;
        final newHeight = renderBox.size.height;
        if (_bottomBarHeight != newHeight) {
          setState(() {
            _bottomBarHeight = newHeight;
          });
        }
      }
    });
  }

  /// 新建聊天（时间线 Tab 的 FAB 操作）
  Future<void> _createNewChat() async {
    // 切换到频道列表 Tab
    if (_currentPage != 0) {
      _tabController.animateTo(0);
    }
  }

  /// 显示创建频道的 Sheet
  void _showCreateChannelSheet() {
    Navigator.of(context).push(
      ModalSheetRoute(
        swipeDismissible: true,
        builder: (context) => Sheet(
          decoration: MaterialSheetDecoration(
            size: SheetSize.fit,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(20),
            ),
            clipBehavior: Clip.antiAlias,
          ),
          child: CreateChannelSheet(plugin: widget.plugin),
        ),
      ),
    );
  }

  /// 构建创建频道的 FAB
  Widget _buildCreateChannelFAB() {
    return FloatingActionButton(
      backgroundColor: widget.plugin.color,
      elevation: 4,
      shape: const CircleBorder(),
      onPressed: _showCreateChannelSheet,
      child: const Icon(
        Icons.add_comment,
        color: Colors.white,
        size: 32,
      ),
    );
  }

  /// 构建新建聊天的 FAB（时间线 Tab）
  Widget _buildNewChatFAB() {
    return FloatingActionButton(
      backgroundColor: widget.plugin.color,
      elevation: 4,
      shape: const CircleBorder(),
      onPressed: _createNewChat,
      child: const Icon(
        Icons.chat,
        color: Colors.white,
        size: 32,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _scheduleBottomBarHeightMeasurement();
    final Color unselectedColor =
        _colors[_currentPage].computeLuminance() < 0.5
            ? Colors.black.withOpacity(0.6)
            : Colors.white.withOpacity(0.6);
    final Color bottomAreaColor = Theme.of(context).scaffoldBackgroundColor;

    return BottomBar(
      fit: StackFit.expand,
      icon:
          (width, height) => Center(
            child: IconButton(
              padding: EdgeInsets.zero,
              onPressed: () {
                // 滚动到顶部功能
                if (_tabController.indexIsChanging) return;

                // 切换到第一个tab
                if (_currentPage != 0) {
                  _tabController.animateTo(0);
                }
              },
              icon: Icon(
                Icons.keyboard_arrow_up,
                color: _colors[_currentPage],
                size: width,
              ),
            ),
          ),
      borderRadius: BorderRadius.circular(25),
      duration: const Duration(milliseconds: 300),
      curve: Curves.decelerate,
      showIcon: true,
      width: MediaQuery.of(context).size.width * 0.85,
      barColor:
          _colors[_currentPage].computeLuminance() > 0.5
              ? Colors.black
              : Colors.white,
      start: 2,
      end: 0,
      offset: 12,
      barAlignment: Alignment.bottomCenter,
      iconHeight: 35,
      iconWidth: 35,
      reverse: false,
      barDecoration: BoxDecoration(
        color: _colors[_currentPage].withOpacity(0.1),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: _colors[_currentPage].withOpacity(0.3),
          width: 1,
        ),
      ),
      iconDecoration: BoxDecoration(
        color: _colors[_currentPage].withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _colors[_currentPage].withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      hideOnScroll:
          !kIsWeb &&
          defaultTargetPlatform != TargetPlatform.macOS &&
          defaultTargetPlatform != TargetPlatform.windows &&
          defaultTargetPlatform != TargetPlatform.linux,
      scrollOpposite: false,
      onBottomBarHidden: () {},
      onBottomBarShown: () {},
      body:
          (context, controller) => Stack(
            children: [
              Positioned.fill(
                child: Padding(
                  padding: EdgeInsets.only(bottom: _bottomBarHeight),
                  child: TabBarView(
                    controller: _tabController,
                    dragStartBehavior: DragStartBehavior.start,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      // Tab0: 频道列表
                      ChannelListScreen(
                        channels: widget.plugin.channelService.channels,
                        chatPlugin: widget.plugin,
                      ),
                      // Tab1: 时间线
                      TimelineScreen(chatPlugin: widget.plugin),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  height: _bottomBarHeight,
                  color: bottomAreaColor,
                ),
              ),
            ],
          ),
      child: Stack(
        key: _bottomBarKey,
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          TabBar(
            controller: _tabController,
            dividerColor: Colors.transparent,
            overlayColor: WidgetStateProperty.all(Colors.transparent),
            indicatorPadding: const EdgeInsets.fromLTRB(6, 0, 6, 0),
            indicator: UnderlineTabIndicator(
              borderSide: BorderSide(
                color:
                    _currentPage < 2 ? _colors[_currentPage] : unselectedColor,
                width: 4,
              ),
              insets: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            ),
            labelColor:
                _currentPage < 2 ? _colors[_currentPage] : unselectedColor,
            unselectedLabelColor: unselectedColor,
            tabs: [
              Tab(
                icon: const Icon(Icons.chat_bubble_outline),
                text: ChatLocalizations.of(context).channelsTab,
              ),
              Tab(
                icon: const Icon(Icons.timeline),
                text: ChatLocalizations.of(context).timelineTab,
              ),
            ],
          ),
          Positioned(
            top: -25,
            child: _currentPage == 0
                ? _buildCreateChannelFAB()
                : _buildNewChatFAB(),
          ),
        ],
      ),
    );
  }
}
