import 'package:Memento/plugins/calendar_album/controllers/calendar_controller.dart';
import 'package:Memento/plugins/calendar_album/controllers/tag_controller.dart';
import 'package:Memento/plugins/calendar_album/screens/calendar_screen.dart';
import 'package:Memento/plugins/calendar_album/screens/tag_screen.dart';
import 'package:Memento/plugins/calendar_album/screens/album_screen.dart';
import 'package:Memento/plugins/calendar_album/screens/entry_editor_screen.dart';
import 'package:Memento/plugins/calendar_album/widgets/tag_manager_dialog.dart';
import 'package:Memento/plugins/calendar_album/l10n/calendar_album_localizations.dart';
import 'package:Memento/plugins/calendar_album/calendar_album_plugin.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
import 'package:provider/provider.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';

/// CalendarAlbum 插件的底部栏组件
/// 提供日历视图、标签视图和相册视图三个 Tab 的切换功能
class CalendarAlbumBottomBar extends StatefulWidget {
  final CalendarAlbumPlugin plugin;

  const CalendarAlbumBottomBar({super.key, required this.plugin});

  @override
  State<CalendarAlbumBottomBar> createState() => _CalendarAlbumBottomBarState();
}

class _CalendarAlbumBottomBarState extends State<CalendarAlbumBottomBar>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late int _currentPage;
  double _bottomBarHeight = 60; // 默认底部栏高度
  final GlobalKey _bottomBarKey = GlobalKey();

  // 使用插件主题色和辅助色
  final List<Color> _colors = [
    const Color.fromARGB(255, 245, 210, 52), // Tab0 - 日历视图 (插件主色)
    Colors.green.shade600, // Tab1 - 标签视图
    Colors.purple.shade600, // Tab2 - 相册视图
  ];

  late final CalendarController _calendarController;
  late final TagController _tagController;

  @override
  void initState() {
    super.initState();
    _currentPage = 0;
    _tabController = TabController(length: 3, vsync: this);
    _tabController.animation?.addListener(() {
      final value = _tabController.animation!.value.round();
      if (value != _currentPage && mounted) {
        setState(() {
          _currentPage = value;
        });
      }
    });

    // 获取控制器
    _calendarController = widget.plugin.calendarController;
    _tagController = widget.plugin.tagController;
  }

  /// 测量底部栏高度
  void _scheduleBottomBarHeightMeasurement() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _bottomBarKey.currentContext != null) {
        final RenderBox renderBox =
            _bottomBarKey.currentContext!.findRenderObject() as RenderBox;
        final newHeight = renderBox.size.height;
        if (_bottomBarHeight != newHeight) {
          setState(() {
            _bottomBarHeight = newHeight;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// 新建日记
  Future<void> _createNewDiary() async {
    await NavigationHelper.push(context, MultiProvider(
              providers: [
                ChangeNotifierProvider.value(value: _calendarController),
                ChangeNotifierProvider.value(value: _tagController),
              ],
              child: EntryEditorScreen(
                initialDate: _calendarController.selectedDate,
                isEditing: false,),
      ),
    );
  }

  /// 标签管理
  Future<void> _manageTags() async {
    await showDialog(
      context: context,
      builder:
          (context) => TagManagerDialog(
            groups: _tagController.tagGroups,
            selectedTags: _tagController.selectedTags,
            onGroupsChanged: (newGroups) {
              _tagController.tagGroups = newGroups;
              // ignore: invalid_use_of_visible_for_testing_member
              _tagController.notifyListeners();
            },
          ),
    );
  }

  /// 相册管理（显示图片统计信息）
  void _showAlbumStats() {
    final allImages = _calendarController.getAllImages();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('相册统计'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('总图片数量: ${allImages.length}'),
                const SizedBox(height: 16),
                if (allImages.isNotEmpty) ...[
                  Text(
                    '最近的照片：',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: allImages.length.clamp(0, 10),
                      itemBuilder: (context, index) {
                        final imageUrl = allImages[index];
                        return Container(
                          width: 80,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(7),
                            child: Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey.shade200,
                                  child: const Icon(Icons.broken_image),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('关闭'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _scheduleBottomBarHeightMeasurement();
    final Color unselectedColor = Colors.black.withOpacity(0.6);
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
      barColor: Colors.white,
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
                      // Tab0: 日历视图
                      MultiProvider(
                        providers: [
                          ChangeNotifierProvider.value(
                            value: _calendarController,
                          ),
                          ChangeNotifierProvider.value(value: _tagController),
                        ],
                        child: CalendarScreen(
                          key: const PageStorageKey('calendar'),
                        ),
                      ),
                      // Tab1: 标签视图
                      MultiProvider(
                        providers: [
                          ChangeNotifierProvider.value(
                            value: _calendarController,
                          ),
                          ChangeNotifierProvider.value(value: _tagController),
                        ],
                        child: TagScreen(key: const PageStorageKey('tags')),
                      ),
                      // Tab2: 相册视图
                      MultiProvider(
                        providers: [
                          ChangeNotifierProvider.value(
                            value: _calendarController,
                          ),
                          ChangeNotifierProvider.value(value: _tagController),
                        ],
                        child: AlbumScreen(key: const PageStorageKey('album')),
                      ),
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
                    _currentPage < 3 ? _colors[_currentPage] : unselectedColor,
                width: 4,
              ),
              insets: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            ),
            labelColor:
                _currentPage < 3 ? _colors[_currentPage] : unselectedColor,
            unselectedLabelColor: unselectedColor,
            tabs: [
              Tab(
                icon: const Icon(Icons.calendar_today),
                text: CalendarAlbumLocalizations.of(context).calendar ?? '日历',
              ),
              Tab(
                icon: const Icon(Icons.tag),
                text: CalendarAlbumLocalizations.of(context).tags ?? '标签',
              ),
              Tab(
                icon: const Icon(Icons.photo_library),
                text: CalendarAlbumLocalizations.of(context).album ?? '相册',
              ),
            ],
          ),
          Positioned(
            top: -25,
            right:
                MediaQuery.of(context).size.width *
                0.15 *
                0.25, // 向右偏移底部栏宽度的1/4
            child: FloatingActionButton(
              backgroundColor: widget.plugin.color, // 使用插件主题色
              elevation: 4,
              shape: const CircleBorder(),
              child: Icon(
                _currentPage == 0
                    ? Icons.create
                    : _currentPage == 1
                    ? Icons.settings
                    : Icons.photo_size_select_actual,
                color: Colors.white,
                size: 32,
              ),
              onPressed: () {
                if (_currentPage == 0) {
                  // Tab0: 新建日记
                  _createNewDiary();
                } else if (_currentPage == 1) {
                  // Tab1: 标签管理
                  _manageTags();
                } else {
                  // Tab2: 相册管理
                  _showAlbumStats();
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
