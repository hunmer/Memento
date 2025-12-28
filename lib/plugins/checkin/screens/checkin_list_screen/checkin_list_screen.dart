import 'package:get/get.dart';
import 'package:Memento/plugins/checkin/models/checkin_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:Memento/widgets/super_cupertino_navigation_wrapper.dart';
import 'package:Memento/plugins/checkin/controllers/checkin_list_controller.dart';
import 'package:Memento/plugins/checkin/widgets/checkin_record_dialog.dart';
import 'package:Memento/core/route/route_history_manager.dart';
import 'components/empty_state.dart';
import 'components/checkin_item_card.dart';

class CheckinListScreen extends StatefulWidget {
  final CheckinListController controller;

  /// 可选的打卡项目ID，用于从小组件跳转时自动打开打卡记录对话框
  final String? initialItemId;

  /// 可选的目标日期（格式：YYYY-MM-DD），用于打开指定日期的打卡记录
  final String? targetDate;

  const CheckinListScreen({
    super.key,
    required this.controller,
    this.initialItemId,
    this.targetDate,
  });

  @override
  State<CheckinListScreen> createState() => _CheckinListScreenState();
}

class _CheckinListScreenState extends State<CheckinListScreen> {
  late CheckinListController controller;

  @override
  void initState() {
    super.initState();
    controller = widget.controller;
    // 恢复最后一次排序设置
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await controller.restoreLastSortSetting();
      if (mounted) setState(() {});

      // 初始化时设置路由上下文
      _updateRouteContext();

      // 如果指定了 initialItemId，则自动打开对应的打卡记录对话框
      if (widget.initialItemId != null && mounted) {
        _showCheckinDialogForItem(widget.initialItemId!, widget.targetDate);
      }
    });
  }

  void _handleStateChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  /// 更新路由上下文，使"询问当前上下文"功能能获取到当前选中的分组
  void _updateRouteContext() {
    final group = controller.selectedGroup;
    RouteHistoryManager.updateCurrentContext(
      pageId: "/checkin_list",
      title: '打卡列表 - $group',
      params: {'group': group},
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredItems = controller.filteredItems;
    final searchResults = controller.getSearchResults();

    return SuperCupertinoNavigationWrapper(
      title: Text('checkin_name'.tr),
      largeTitle: 'checkin_checkinListTitle'.tr,
      body: Column(
        children: [
          // 打卡项目列表（不包含过滤栏）
          Expanded(
            child:
                filteredItems.isEmpty
                    ? const EmptyState()
                    : SingleChildScrollView(
                      padding: const EdgeInsets.only(bottom: 80),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: StaggeredGrid.count(
                          crossAxisCount: 2,
                          mainAxisSpacing: 0,
                          crossAxisSpacing: 0,
                          children:
                              filteredItems.asMap().entries.map((entry) {
                                final index = entry.key;
                                final item = entry.value;
                                return StaggeredGridTile.fit(
                                  crossAxisCellCount:
                                      item.cardStyle == CheckinCardStyle.small
                                          ? 1
                                          : 2,
                                  child: CheckinItemCard(
                                    item: item,
                                    index: index,
                                    itemIndex: index,
                                    controller: controller,
                                    onStateChanged: _handleStateChanged,
                                  ),
                                );
                              }).toList(),
                        ),
                      ),
                    ),
          ),
        ],
      ),
      // ========== 搜索相关配置 ==========
      enableSearchBar: true,
      searchPlaceholder: 'checkin_searchPlaceholder'.tr,
      onSearchChanged: (query) => controller.onSearchChanged(query),
      onSearchSubmitted: (query) => controller.onSearchChanged(query),
      searchBody: _buildSearchResults(searchResults),
      // ========== 过滤栏配置 ==========
      enableFilterBar: true,
      filterBarChild: _buildFilterBar(),
      actions: [
        // 排序按钮
        IconButton(
          icon: const Icon(Icons.sort),
          onPressed: () async {
            await controller.showGroupSortDialog();
            if (mounted) setState(() {});
          },
        ),
        IconButton(
          icon: const Icon(Icons.folder),
          onPressed: controller.showGroupManagementDialog,
        ),
      ],
      enableLargeTitle: false,
    );
  }

  /// 构建搜索结果视图
  Widget _buildSearchResults(List<CheckinItem> searchResults) {
    if (controller.isSearching && searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              '未找到相关打卡项目',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              '尝试使用其他关键词搜索',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    if (controller.isSearching && searchResults.isNotEmpty) {
      return SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 80),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: StaggeredGrid.count(
            crossAxisCount: 2,
            crossAxisSpacing: 0,
            mainAxisSpacing: 0,
            children:
                searchResults.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  return StaggeredGridTile.fit(
                    crossAxisCellCount:
                        item.cardStyle == CheckinCardStyle.small ? 1 : 2,
                    child: CheckinItemCard(
                      item: item,
                      index: index,
                      itemIndex: index,
                      controller: controller,
                      onStateChanged: _handleStateChanged,
                    ),
                  );
                }).toList(),
          ),
        ),
      );
    }

    // 默认状态（不显示搜索结果）
    return const SizedBox.shrink();
  }

  Widget _buildFilterBar() {
    final groups = controller.groups;
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: groups.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final group = groups[index];
          final isSelected = group == controller.selectedGroup;
          return ChoiceChip(
            label: Text(group),
            selected: isSelected,
            onSelected: (selected) {
              if (selected) {
                controller.selectGroup(group);
                // 更新路由上下文
                _updateRouteContext();
              }
            },
            showCheckmark: false,
            labelStyle: TextStyle(
              color:
                  isSelected
                      ? Theme.of(context).colorScheme.onPrimary
                      : Theme.of(context).textTheme.bodyMedium?.color,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
            selectedColor: Theme.of(context).primaryColor,
          );
        },
      ),
    );
  }

  /// 根据 itemId 显示打卡记录对话框
  void _showCheckinDialogForItem(String itemId, [String? targetDate]) {
    // 查找对应的打卡项目
    final item = controller.checkinItems.firstWhere(
      (item) => item.id == itemId,
      orElse: () => throw Exception('未找到ID为 $itemId 的打卡项目'),
    );

    // 解析目标日期，如果未提供则使用当前日期
    DateTime? selectedDate;
    if (targetDate != null && targetDate.isNotEmpty) {
      try {
        final parts = targetDate.split('-');
        if (parts.length == 3) {
          selectedDate = DateTime(
            int.parse(parts[0]),
            int.parse(parts[1]),
            int.parse(parts[2]),
          );
        }
      } catch (e) {
        debugPrint('解析日期失败: $targetDate, 错误: $e');
      }
    }
    // 如果没有指定日期，使用当前日期
    selectedDate ??= DateTime.now();

    // 延迟一帧以确保界面完全加载
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;

      showDialog(
        context: context,
        builder:
            (context) => CheckinRecordDialog(
              item: item,
              controller: controller,
              onCheckinCompleted: _handleStateChanged,
              selectedDate: selectedDate,
            ),
      );
    });
  }
}
