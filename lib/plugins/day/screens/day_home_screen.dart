import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';
import 'package:Memento/widgets/super_cupertino_navigation_wrapper.dart';
import 'package:Memento/plugins/day/controllers/day_controller.dart';
import 'package:Memento/plugins/day/widgets/memorial_day_card.dart';
import 'package:Memento/plugins/day/widgets/memorial_day_list_item.dart';
import 'package:Memento/plugins/day/widgets/edit_memorial_day_dialog/edit_memorial_day_page.dart';
import 'package:Memento/plugins/day/models/memorial_day.dart';
import 'package:Memento/core/route/route_history_manager.dart';

class DayHomeScreen extends StatefulWidget {
  const DayHomeScreen({super.key});

  @override
  State<DayHomeScreen> createState() => _DayHomeScreenState();
}

class _DayHomeScreenState extends State<DayHomeScreen> {
  // 搜索查询状态
  String _searchQuery = '';

  Future<void> _showEditDialog(
    BuildContext context, [
    MemorialDay? memorialDay,
  ]) async {
    if (!mounted) return;

    final result = await Navigator.push<DialogResult>(
      context,
      MaterialPageRoute(
        builder: (context) => EditMemorialDayPage(memorialDay: memorialDay),
      ),
    );

    if (result == null) {
      return; // 页面被异常关闭
    }

    if (!mounted) return;

    switch (result.action) {
      case DialogAction.save:
        if (result.memorialDay != null) {
          // 用户保存了更改
          if (memorialDay != null) {
            // 更新现有的纪念日
            await _controller.updateMemorialDay(result.memorialDay!);
          } else {
            // 添加新的纪念日
            await _controller.addMemorialDay(result.memorialDay!);
          }
        }
        break;

      case DialogAction.delete:
        if (memorialDay != null) {
          // 用户请求删除，调用控制器的删除方法
          await _controller.deleteMemorialDay(memorialDay.id);
        }
        break;

      case DialogAction.cancel:
        // 用户取消操作，不做任何处理
        break;
    }
  }

  late DayController _controller;

  @override
  void initState() {
    super.initState();
    _controller = DayController();
    _initializeController();
  }

  Future<void> _initializeController() async {
    await _controller.initialize();
    if (mounted) setState(() {});

    // 初始化时设置路由上下文
    _updateRouteContext();
  }

  /// 更新路由上下文,使"询问当前上下文"功能能获取到当前状态
  void _updateRouteContext() {
    final count = _controller.memorialDays.length;
    RouteHistoryManager.updateCurrentContext(
      pageId: "/day_list",
      title: '纪念日列表（共 $count 个）',
      params: {'count': count.toString()},
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _controller,
      child: Consumer<DayController>(
        builder: (context, controller, child) {
          final theme = Theme.of(context);
          return SuperCupertinoNavigationWrapper(
            title: Text(
              'day_memorialDays'.tr,
              style: TextStyle(color: theme.textTheme.titleLarge?.color),
            ),
            largeTitle: 'day_memorialDaysListTitle'.tr,

            // 启用搜索栏
            enableSearchBar: true,
            searchPlaceholder: 'day_searchPlaceholder'.tr,
            // 搜索回调
            onSearchChanged: (query) {
              setState(() {
                _searchQuery = query;
              });
            },
            onSearchSubmitted: (query) {
              // 搜索提交时的逻辑
            },
            // 搜索结果页面
            searchBody: _buildSearchResults(controller),
            actions: [
              // 排序菜单
              PopupMenuButton<SortMode>(
                icon: Icon(Icons.sort, color: theme.iconTheme.color),
                tooltip: 'day_sortOptions'.tr,
                onSelected: (mode) => controller.setSortMode(mode),
                itemBuilder:
                    (context) => [
                      PopupMenuItem(
                        value: SortMode.upcoming,
                        child: Text('day_upcomingSort'.tr),
                      ),
                      PopupMenuItem(
                        value: SortMode.recent,
                        child: Text('day_recentSort'.tr),
                      ),
                      PopupMenuItem(
                        value: SortMode.manual,
                        child: Text('day_manualSort'.tr),
                      ),
                    ],
              ),
              // 视图切换按钮
              IconButton(
                icon: Icon(
                  controller.isCardView ? Icons.view_list : Icons.view_module,
                  color: theme.iconTheme.color,
                ),
                onPressed: controller.toggleView,
                tooltip:
                    controller.isCardView
                        ? 'day_listView'.tr
                        : 'day_cardView'.tr,
              ),
            ],
            body: Stack(
              children: [
                _buildBody(controller),
                // FAB 覆盖层
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: FloatingActionButton(
                    onPressed: () => _showEditDialog(context),
                    child: const Icon(Icons.add),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody(DayController controller) {
    if (controller.memorialDays.isEmpty) {
      return Center(child: Text('day_noMemorialDays'.tr));
    }

    return controller.isCardView
        ? _buildCardView(controller.memorialDays, controller.isDraggable)
        : _buildListView(controller.memorialDays, controller.isDraggable);
  }

  Widget _buildCardView(List<MemorialDay> days, bool allowReorder) {
    // 如果不允许重排序，使用普通GridView
    if (!allowReorder) {
      return GridView.builder(
        padding: const EdgeInsets.all(8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.85,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: days.length,
        itemBuilder: (context, index) {
          return MemorialDayCard(
            key: ValueKey(days[index].id),
            memorialDay: days[index],
            isDraggable: false,
            onTap: () => _showEditDialog(context, days[index]),
          );
        },
      );
    }

    // 允许重排序时使用ReorderableGridView
    return ReorderableGridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.85,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: days.length,
      itemBuilder: (context, index) {
        return MemorialDayCard(
          key: ValueKey(days[index].id),
          memorialDay: days[index],
          isDraggable: true,
          onTap: () => _showEditDialog(context, days[index]),
        );
      },
      onReorder: (oldIndex, newIndex) async {
        await _controller.reorderMemorialDays(oldIndex, newIndex);
      },
      // 自定义拖拽装饰，移除边框
      dragWidgetBuilder: (index, child) {
        return Material(
          color: Colors.transparent,
          elevation: 0,
          child: Transform.scale(scale: 1.05, child: child),
        );
      },
    );
  }

  Widget _buildListView(List<MemorialDay> days, bool allowReorder) {
    // 如果不允许重排序，使用普通ListView
    if (!allowReorder) {
      return ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: days.length,
        itemBuilder: (context, index) {
          return MemorialDayListItem(
            key: ValueKey(days[index].id),
            memorialDay: days[index],
            isDraggable: false,
            onTap: () => _showEditDialog(context, days[index]),
          );
        },
      );
    }

    // 允许重排序时使用ReorderableListView
    return ReorderableListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: days.length,
      itemBuilder: (context, index) {
        return MemorialDayListItem(
          key: ValueKey(days[index].id),
          memorialDay: days[index],
          isDraggable: true,
          onTap: () => _showEditDialog(context, days[index]),
        );
      },
      onReorder: (oldIndex, newIndex) async {
        await _controller.reorderMemorialDays(oldIndex, newIndex);
      },
      // 自定义拖拽装饰，移除边框
      proxyDecorator: (child, index, animation) {
        return AnimatedBuilder(
          animation: animation,
          builder: (BuildContext context, Widget? child) {
            return Material(
              elevation: 0, // 无阴影
              color: Colors.transparent, // 透明背景
              borderRadius: BorderRadius.zero, // 无圆角
              child: child,
            );
          },
          child: child,
        );
      },
    );
  }

  /// 构建搜索结果列表
  Widget _buildSearchResults(DayController controller) {
    // 如果没有搜索查询，显示提示
    if (_searchQuery.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 64,
              color: Theme.of(context).disabledColor,
            ),
            const SizedBox(height: 16),
            Text(
              '输入关键词搜索纪念日',
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).disabledColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '支持搜索标题和笔记内容',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).disabledColor.withOpacity(0.7),
              ),
            ),
          ],
        ),
      );
    }

    // 过滤纪念日（标题和笔记中包含搜索关键词）
    final filteredDays =
        controller.memorialDays.where((memorialDay) {
          // 检查标题是否匹配
          final titleMatch = memorialDay.title.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          );

          // 检查笔记是否匹配（笔记列表中的任意一个笔记包含关键词）
          final notesMatch = memorialDay.notes.any(
            (note) => note.toLowerCase().contains(_searchQuery.toLowerCase()),
          );

          return titleMatch || notesMatch;
        }).toList();

    // 如果没有搜索结果，显示空状态
    if (filteredDays.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: Theme.of(context).disabledColor,
            ),
            const SizedBox(height: 16),
            Text(
              '未找到匹配的纪念日',
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).disabledColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '尝试使用其他关键词搜索',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).disabledColor.withOpacity(0.7),
              ),
            ),
          ],
        ),
      );
    }

    // 显示搜索结果列表（使用与主界面相同的视图模式）
    return controller.isCardView
        ? _buildSearchCardView(filteredDays)
        : _buildSearchListView(filteredDays);
  }

  /// 构建搜索结果的卡片视图
  Widget _buildSearchCardView(List<MemorialDay> filteredDays) {
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.85,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: filteredDays.length,
      itemBuilder: (context, index) {
        return MemorialDayCard(
          key: ValueKey(filteredDays[index].id),
          memorialDay: filteredDays[index],
          isDraggable: false,
          onTap: () => _showEditDialog(context, filteredDays[index]),
        );
      },
    );
  }

  /// 构建搜索结果的列表视图
  Widget _buildSearchListView(List<MemorialDay> filteredDays) {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: filteredDays.length,
      itemBuilder: (context, index) {
        return MemorialDayListItem(
          key: ValueKey(filteredDays[index].id),
          memorialDay: filteredDays[index],
          isDraggable: false,
          onTap: () => _showEditDialog(context, filteredDays[index]),
        );
      },
    );
  }
}
