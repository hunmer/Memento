import 'package:Memento/plugins/calendar_album/controllers/calendar_controller.dart';
import 'package:get/get.dart';
import 'package:Memento/plugins/calendar_album/controllers/tag_controller.dart';
import 'package:Memento/plugins/calendar_album/screens/calendar_screen.dart';
import 'package:Memento/plugins/calendar_album/screens/tag_screen.dart';
import 'package:Memento/plugins/calendar_album/screens/album_screen.dart';
import 'package:Memento/plugins/calendar_album/screens/entry_editor_screen.dart';
import 'package:Memento/plugins/calendar_album/calendar_album_plugin.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:Memento/core/widgets/custom_bottom_bar.dart';

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
  final GlobalKey _bottomBarKey = GlobalKey();
  final GlobalKey _fabKey = GlobalKey();

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
    _calendarController = widget.plugin.calendarController!;
    _tagController = widget.plugin.tagController!;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// 构建 FAB
  Widget _buildFab() {
    return Builder(
      builder: (context) {
        return FloatingActionButton(
          key: _fabKey,
          backgroundColor: widget.plugin.color,
          elevation: 4,
          shape: const CircleBorder(),
          onPressed: () {
            NavigationHelper.openContainerWithHero(
              context,
              (context) {
                if (_currentPage == 0) {
                  // Tab0: 新建日记
                  return MultiProvider(
                    providers: [
                      ChangeNotifierProvider.value(value: _calendarController),
                      ChangeNotifierProvider.value(value: _tagController),
                    ],
                    child: EntryEditorScreen(
                      initialDate: _calendarController.selectedDate,
                      isEditing: false,
                    ),
                  );
                } else if (_currentPage == 1) {
                  // Tab1: 标签管理
                  return Scaffold(
                    appBar: AppBar(
                      title: Text('calendar_album_tag_management'.tr),
                    ),
                    body: Center(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.label),
                        label: Text('calendar_album_manage_tags'.tr),
                        onPressed: () async {
                          await _tagController.showTagManagerDialog(context);
                        },
                      ),
                    ),
                  );
                } else {
                  // Tab2: 相册统计
                  final allImages = _calendarController.getAllImages();
                  return Scaffold(
                    appBar: AppBar(
                      title: Text('calendar_album_album_statistics'.tr),
                    ),
                    body: AlertDialog(
                      title: Text('calendar_album_album_statistics'.tr),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${'calendar_album_total_photo_count'.tr}: ${allImages.length}'),
                          const SizedBox(height: 16),
                          if (allImages.isNotEmpty) ...[
                            Text(
                              'calendar_album_recent_photos'.tr,
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
                          child: Text('calendar_album_close'.tr),
                        ),
                      ],
                    ),
                  );
                }
              },
              sourceKey: _fabKey,
              heroTag: 'calendar_album_fab_$_currentPage',
              closedShape: const CircleBorder(),
            );
          },
          child: Icon(
            _currentPage == 0
                ? Icons.create
                : _currentPage == 1
                    ? Icons.settings
                    : Icons.photo_size_select_actual,
            color: Colors.white,
            size: 32,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return CustomBottomBar(
      colors: _colors,
      currentIndex: _currentPage,
      tabController: _tabController,
      bottomBarKey: _bottomBarKey,
      body: (context, controller) => TabBarView(
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
      fab: _buildFab(),
      children: [
        Tab(
          icon: const Icon(Icons.calendar_today),
          text: 'calendar_album_calendar'.tr,
        ),
        Tab(
          icon: const Icon(Icons.tag),
          text: 'calendar_album_tags'.tr,
        ),
        Tab(
          icon: const Icon(Icons.photo_library),
          text: 'calendar_album_album'.tr,
        ),
      ],
    );
  }
}
