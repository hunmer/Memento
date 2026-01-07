import 'dart:async';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:Memento/plugins/checkin/models/checkin_item.dart';
import 'package:Memento/plugins/checkin/screens/checkin_form_screen.dart';
import 'package:intl/intl.dart';
import 'package:Memento/plugins/checkin/checkin_plugin.dart';
import 'package:Memento/plugins/checkin/services/group_sort_service.dart';
import 'package:Memento/plugins/checkin/widgets/group_sort_dialog.dart';
import 'package:Memento/core/event/event_manager.dart';
import 'package:Memento/core/event/item_event_args.dart';
import 'package:Memento/core/services/toast_service.dart';
import 'package:Memento/widgets/smooth_bottom_sheet.dart';

/// 本地 TagGroup 类（用于分组管理对话框）
class TagGroup {
  final String name;
  final List<String> tags;
  final List<String>? tagIds;

  TagGroup({required this.name, required this.tags, this.tagIds});

  TagGroup copyWith({String? name, List<String>? tags, List<String>? tagIds}) {
    return TagGroup(
      name: name ?? this.name,
      tags: tags ?? List.from(this.tags),
      tagIds: tagIds ?? (this.tagIds != null ? List.from(this.tagIds!) : null),
    );
  }
}

class CheckinListController {
  final BuildContext context;
  final Function() onStateChanged;

  GroupSortType currentSortType = GroupSortType.upcoming;
  bool isReversed = false;

  String selectedGroup = '全部'; // 当前选中的分组

  // ========== 搜索相关状态 ==========
  String searchQuery = ''; // 搜索文本
  bool get isSearching => searchQuery.isNotEmpty;

  // 动态获取最新的 checkinItems
  List<CheckinItem> get checkinItems => CheckinPlugin.instance.checkinItems;

  CheckinListController({
    required this.context,
    required this.onStateChanged,
    // required this.expandedGroups, // Remove this parameter
  });

  // 获取所有分组 (用于过滤栏)
  List<String> get groups {
    final g = checkinItems.map((item) => item.group).toSet().toList()..sort();
    return ['全部', ...g];
  }

  // 选择分组
  void selectGroup(String group) {
    selectedGroup = group;
    onStateChanged();
  }

  // ========== 搜索功能 ==========

  /// 处理搜索文本变化
  void onSearchChanged(String query) {
    searchQuery = query;
    onStateChanged();
  }

  /// 清除搜索
  void clearSearch() {
    searchQuery = '';
    onStateChanged();
  }

  /// 获取搜索结果（按名称和分组搜索）
  List<CheckinItem> getSearchResults() {
    if (searchQuery.isEmpty) return [];

    final query = searchQuery.toLowerCase();
    return checkinItems.where((item) {
      // 搜索名称和分组
      final nameMatch = item.name.toLowerCase().contains(query);
      final groupMatch = item.group.toLowerCase().contains(query);
      return nameMatch || groupMatch;
    }).toList();
  }

  // ========== 原有过滤逻辑 ==========

  /// 获取过滤后的打卡项目（普通视图）
  List<CheckinItem> get filteredItems {
    List<CheckinItem> items;
    if (selectedGroup == '全部') {
      items = List.from(checkinItems);
    } else {
      items =
          checkinItems.where((item) => item.group == selectedGroup).toList();
    }

    // 这里可以应用排序，如果需要的话。目前保持默认顺序或添加简单的排序。
    // 暂时保持添加顺序，或者可以复用 GroupSortService 对 flat list 进行排序 (需要修改 Service 支持 List<CheckinItem>)
    // 简单起见，这里先不进行复杂排序，或者复用之前的排序逻辑但应用在 List<CheckinItem> 上

    return items;
  }

  // 更新卡片风格
  Future<void> updateCardStyle(CheckinItem item, CheckinCardStyle style) async {
    item.cardStyle = style;
    // 通过 UseCase 保存变更
    await CheckinPlugin.instance.checkinUseCase.updateItem({
      'id': item.id,
      'cardStyle': style.index,
    });
    await CheckinPlugin.shared.triggerSave();
    onStateChanged();
  }

  // 按分组获取打卡项目 (用于统计或旧逻辑兼容)
  Map<String, List<CheckinItem>> get groupedItems {
    final grouped = <String, List<CheckinItem>>{};
    for (var item in checkinItems) {
      final group = item.group;
      if (!grouped.containsKey(group)) {
        grouped[group] = [];
      }
      grouped[group]!.add(item);
    }
    return grouped;
  }

  // 获取统计信息
  Map<String, dynamic> getStatistics() {
    final groupStats = <String, Map<String, int>>{};
    // Use actual groups from items, not including 'All'
    final actualGroups =
        checkinItems.map((item) => item.group).toSet().toList()..sort();

    for (var group in actualGroups) {
      final items = groupedItems[group] ?? [];
      final completed = items.where((item) => item.isCheckedToday()).length;
      groupStats[group] = {'total': items.length, 'completed': completed};
    }

    int totalItems = checkinItems.length;
    int completedItems =
        checkinItems.where((item) => item.isCheckedToday()).length;
    double completionRate =
        totalItems > 0 ? completedItems / totalItems * 100 : 0;

    // 计算今日总打卡次数
    int todayCheckins = 0;
    for (var item in checkinItems) {
      todayCheckins += item.getTodayRecords().length;
    }

    return {
      'groupStats': groupStats,
      'totalItems': totalItems,
      'completedItems': completedItems,
      'completionRate': completionRate,
      'todayCheckins': todayCheckins,
    };
  }

  // 获取今日打卡记录总数
  int getTotalRecordsToday() {
    int totalRecords = 0;
    for (var item in checkinItems) {
      totalRecords += item.getTodayRecords().length;
    }
    return totalRecords;
  }

  // 恢复最后一次排序设置
  Future<void> restoreLastSortSetting() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastSortTypeIndex = prefs.getInt('lastSortType');
      final lastIsReversed = prefs.getBool('isReversed');

      if (lastSortTypeIndex != null) {
        currentSortType = GroupSortType.values[lastSortTypeIndex];
      }
      if (lastIsReversed != null) {
        isReversed = lastIsReversed;
      }
    } catch (e) {
      print('恢复排序设置失败: $e');
      // 使用默认排序设置
      currentSortType = GroupSortType.upcoming;
      isReversed = false;
    }
  }

  // 显示分组排序对话框 (可能需要调整为列表排序)
  Future<void> showGroupSortDialog() async {
    // Temporary: keep as is, or disable if sorting isn't prioritized in this refactor
    await showDialog(
      context: context,
      builder:
          (context) => GroupSortDialog(
            currentSortType: currentSortType,
            isReversed: isReversed,
            onSortChanged: (sortType, reversed) async {
              currentSortType = sortType;
              isReversed = reversed;
              // 保存排序设置
              final prefs = await SharedPreferences.getInstance();
              await prefs.setInt('lastSortType', sortType.index);
              await prefs.setBool('isReversed', reversed);
              onStateChanged();
            },
          ),
    );
  }

  // 切换编辑模式
  // 检查日期是否为今天
  bool isToday(DateTime? date) {
    if (date == null) return false;
    final today = DateTime.now();
    return date.year == today.year &&
        date.month == today.month &&
        date.day == today.day;
  }

  // 检查打卡项是否已完成
  bool isCompleted(CheckinItem item) {
    return item.isCheckedToday();
  }

  // 切换打卡状态
  // 发送事件通知
  void notifyEvent(String action, CheckinItem item) {
    final eventArgs = ItemEventArgs(
      eventName: 'checkin_$action',
      itemId: item.id,
      title: item.name,
      action: action,
    );
    EventManager.instance.broadcast('checkin_$action', eventArgs);
  }

  // 显示编辑打卡项页面
  void showEditItemDialog(CheckinItem item) {
    NavigationHelper.push<CheckinItem>(
      context,
      CheckinFormScreen(initialItem: item),
    ).then((updatedItem) async {
      if (updatedItem != null) {
        // 通过 UseCase 更新数据到存储
        final result = await CheckinPlugin.instance.checkinUseCase.updateItem(updatedItem.toJson());
        if (result.isSuccess) {
          // 保存成功后，重新加载数据
          await CheckinPlugin.shared.triggerSave();
          onStateChanged();
        } else {
          // 显示错误信息
          final error = result.errorOrNull;
          ToastService.instance.showToast(
            error?.message ?? '保存失败',
          );
        }
      }
    });
  }

  // 删除打卡项
  void deleteItem(CheckinItem item) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              'checkin_deleteCheckinItemTitle'.tr,
            ),
            content: Text(
              '${'checkin_deleteConfirmMessage'.tr}"${item.name}"?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('app_cancel'.tr),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  // 发送删除事件
                  notifyEvent('deleted', item);
                  // 使用正确的删除方法
                  await CheckinPlugin.instance.removeCheckinItem(item);
                  onStateChanged();
                },
                child: Text(
                  'app_delete'.tr,
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }

  // 显示打卡项目操作菜单
  void showItemOptionsDialog(CheckinItem item) {
    SmoothBottomSheet.show(
      context: context,
      builder:
          (context) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.style),
                  title: Text('checkin_modifyCardDisplayStyle'.tr),
                  onTap: () {
                    Navigator.pop(context);
                    _showCardStyleDialog(item);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.edit),
                  title: Text('checkin_editCheckinItem'.tr),
                  onTap: () {
                    Navigator.pop(context);
                    _editCheckinItem(item);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.refresh),
                  title: Text(
                    'checkin_resetCheckinRecords'.tr,
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _showResetConfirmDialog(item);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: Text(
                    'app_delete'.tr,
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _showDeleteConfirmDialog(item);
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
    );
  }

  void _showCardStyleDialog(CheckinItem item) {
    showDialog(
      context: context,
      builder:
          (context) => SimpleDialog(
            title: Text('checkin_selectCardStyle'.tr),
            children: [
              SimpleDialogOption(
                onPressed: () {
                  Navigator.pop(context);
                  updateCardStyle(item, CheckinCardStyle.weekly);
                },
                child: Text('checkin_sevenDayDisplay'.tr),
              ),
              SimpleDialogOption(
                onPressed: () {
                  Navigator.pop(context);
                  updateCardStyle(item, CheckinCardStyle.small);
                },
                child: Text('checkin_smallCardStyle'.tr),
              ),
              SimpleDialogOption(
                onPressed: () {
                  Navigator.pop(context);
                  updateCardStyle(item, CheckinCardStyle.calendar);
                },
                child: Text('checkin_calendarStyle'.tr),
              ),
            ],
          ),
    );
  }

  // 编辑打卡项目
  void _editCheckinItem(CheckinItem item) {
    NavigationHelper.push<CheckinItem>(
      context,
      CheckinFormScreen(initialItem: item),
    ).then((editedItem) async {
      if (editedItem != null) {
        // 通过 UseCase 更新数据到存储
        final result = await CheckinPlugin.instance.checkinUseCase.updateItem(editedItem.toJson());
        if (result.isSuccess) {
          // 保存成功后，重新加载数据
          await CheckinPlugin.shared.triggerSave();
          onStateChanged();
        } else {
          // 显示错误信息
          final error = result.errorOrNull;
          ToastService.instance.showToast(
            error?.message ?? '保存失败',
          );
        }
      }
    });
  }

  // 显示重置确认对话框
  void _showResetConfirmDialog(CheckinItem item) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              'checkin_resetCheckinRecordsTitle'.tr,
            ),
            content: Text(
              '${'checkin_resetCheckinRecordsMessage'.tr}"${item.name}"',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('app_cancel'.tr),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await item.resetRecords();
                  onStateChanged();
                  ToastService.instance.showToast(
                    'checkin_resetSuccessMessage'.trParams({'name': item.name}),
                  );
                },
                child: Text(
                  'checkin_confirmReset'.tr,
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }

  // 显示删除确认对话框
  void _showDeleteConfirmDialog(CheckinItem item) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              'checkin_deleteCheckinItemTitle'.tr,
            ),
            content: Text(
              '${'checkin_deleteConfirmMessage'.tr}"${item.name}"?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('app_cancel'.tr),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  // 发送删除事件
                  notifyEvent('deleted', item);
                  // 使用正确的删除方法
                  await CheckinPlugin.instance.removeCheckinItem(item);
                  onStateChanged();
                  ToastService.instance.showToast(
                    'checkin_deleteSuccessMessage'.trParams({'name': item.name}),
                  );
                },
                child: Text(
                  'checkin_confirmDelete'.tr,
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }

  // 显示打卡成功对话框
  void showCheckinSuccessDialog(CheckinItem item, CheckinRecord record) {
    final streak = item.getConsecutiveDays();
    final timeFormat = DateFormat('HH:mm');

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green),
                const SizedBox(width: 8),
                Text('checkin_checkinSuccessTitle'.tr),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${'checkin_checkinSuccessTitle'.tr} ${item.name}',
                ),
                const SizedBox(height: 8),
                Text(
                  '${'checkin_timeRangeLabel'.tr}: ${timeFormat.format(record.startTime)} - ${timeFormat.format(record.endTime)}',
                  style: const TextStyle(fontSize: 14),
                ),
                if (record.note != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${'checkin_noteLabel'.tr}: ${record.note}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
                const SizedBox(height: 8),
                if (streak > 1)
                  Text(
                    '${'checkin_consecutiveDaysLabel'.tr}: $streak',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('app_ok'.tr),
              ),
            ],
          ),
    );
  }

  // 显示分组管理对话框
  void showGroupManagementDialog() {
    // 获取当前的标签组
    List<TagGroup> getCurrentTagGroups() {
      // Re-calculate groups as selectedGroup shouldn't affect management
      final groups =
          checkinItems.map((item) => item.group).toSet().toList()..sort();
      return groups.map((group) {
        final items = groupedItems[group] ?? [];
        return TagGroup(
          name: group,
          tags: items.map((item) => item.name).toList(),
          tagIds: items.map((item) => item.id).toList(),
        );
      }).toList();
    }

    // 获取当前选中的标签（打卡项目）
    List<String> getSelectedTags() {
      return checkinItems
          .where((item) => item.isCheckedToday())
          .map((item) => item.name)
          .toList();
    }

    showDialog(
      context: context,
      builder:
          (dialogContext) => TagManagerDialog(
            groups: getCurrentTagGroups(),
            selectedTags: getSelectedTags(),
            onAddTag: (String group, {String? tag}) async {
              // 获取最新的标签组数据
              final currentGroups = getCurrentTagGroups();
              // 获取标签对应的id（如果存在）
              String? itemId;
              if (tag != null) {
                for (var tagGroup in currentGroups) {
                  if (tagGroup.name == group) {
                    final tagIndex = tagGroup.tags.indexOf(tag);
                    if (tagIndex != -1 &&
                        tagGroup.tagIds != null &&
                        tagGroup.tagIds!.length > tagIndex) {
                      itemId = tagGroup.tagIds![tagIndex];
                      break;
                    }
                  }
                }
              }

              // 直接使用checkin的对话框，不关闭TagManager
              final newTagName = await showAddCheckinItemDialog(
                group: group,
                copyFromTag: tag,
                id: itemId, // 传递id参数用于编辑
              );

              if (newTagName != null) {
                return newTagName;
              }
              return null;
            },
            onGroupsChanged: (List<TagGroup> updatedGroups) async {
              // 处理分组变更
              for (var tagGroup in updatedGroups) {
                final existingItems = groupedItems[tagGroup.name] ?? [];
                final existingItemNames =
                    existingItems.map((e) => e.name).toSet();

                // 更新现有项目的分组
                for (var tag in tagGroup.tags) {
                  // 如果标签不在现有项目中，创建新项目
                  if (!existingItemNames.contains(tag)) {
                    // 这里不需要显示对话框，因为已经通过onAddTag回调处理了
                  }
                }

                // 处理被移除的项目
                for (var item in List.from(checkinItems)) {
                  if (item.group == tagGroup.name &&
                      !tagGroup.tags.contains(item.name)) {
                    checkinItems.remove(item);
                  }
                }
              }

              // 删除不在更新后分组列表中的项目
              final updatedGroupNames =
                  updatedGroups.map((g) => g.name).toSet();
              checkinItems.removeWhere(
                (item) => !updatedGroupNames.contains(item.group),
              );

              // 保存更改
              await CheckinPlugin.shared.triggerSave();
              onStateChanged();
            },
            onRefreshData: () async {
              return getCurrentTagGroups();
            },
            config: TagManagerConfig(
              title: 'checkin_manageGroupsTitle'.tr,
              addGroupHint: 'checkin_addGroupHint'.tr,
              addTagHint: 'checkin_addTagHint'.tr,
              editGroupHint: 'checkin_editGroupHint'.tr,
              allTagsLabel: 'checkin_allTagsLabel'.tr,
              newGroupLabel: 'checkin_newGroupLabel'.tr,
            ),
          ),
    ).then((_) {
      // 关闭对话框后刷新界面
      onStateChanged();
    });
  }

  // 显示添加或编辑打卡项目对话框
  Future<String?> showAddCheckinItemDialog({
    String? group,
    String? copyFromTag,
    String? id,
  }) async {
    final completer = Completer<String?>();

    // 如果提供了id，尝试找到现有项目进行编辑
    CheckinItem? existingItem;
    if (id != null) {
      try {
        existingItem = checkinItems.firstWhere((item) => item.id == id);
      } catch (e) {
        // 如果找不到匹配的项目，existingItem 保持为 null
        existingItem = null;
      }
    }

    // 如果提供了copyFromTag且不是编辑模式，尝试找到该标签对应的CheckinItem作为模板
    CheckinItem? templateItem;
    if (copyFromTag != null && id == null) {
      templateItem = checkinItems.firstWhere(
        (item) => item.name == copyFromTag,
        orElse:
            () => CheckinItem(
              name: '',
              group: group ?? '',
              icon: Icons.check_circle,
              color: Colors.blue,
            ),
      );

      // 创建一个新的CheckinItem，复制模板的属性但使用新的名称
      templateItem = CheckinItem(
        name: '', // 名称留空，由用户填写
        group: group ?? templateItem.group,
        icon: templateItem.icon,
        color: templateItem.color,
        // 复制其他需要的属性，但不复制记录
      );
    }

    NavigationHelper.push<CheckinItem>(
      context,
      CheckinFormScreen(
        initialItem: existingItem ??
            templateItem ??
            (group != null
                ? CheckinItem(
                    name: '',
                    group: group,
                    icon: Icons.check_circle,
                    color: Colors.blue,
                  )
                : null),
      ),
    ).then((checkinItem) async {
      if (checkinItem != null) {
        if (existingItem != null) {
          // 更新现有项目
          final index = checkinItems.indexWhere(
            (item) => item.id == existingItem!.id,
          );
          if (index != -1) {
            checkinItems[index] = checkinItem;
          }
        } else {
          // 添加新项目
          checkinItems.add(checkinItem);
        }
        await CheckinPlugin.shared.triggerSave();
        onStateChanged();
        completer.complete(checkinItem.name);
      } else {
        completer.complete(null);
      }
    });

    return completer.future;
  }

  // 更新指定分组中项目的顺序
  Future<void> updateItemsOrder(
    String group,
    List<CheckinItem> newOrder,
  ) async {
    // 找到当前分组在 checkinItems 中的起始和结束索引
    int startIndex = -1;
    int endIndex = -1;

    for (int i = 0; i < checkinItems.length; i++) {
      if (checkinItems[i].group == group) {
        if (startIndex == -1) startIndex = i;
        endIndex = i;
      } else if (startIndex != -1) {
        // 已经找到了分组的所有项目，可以跳出循环
        break;
      }
    }

    if (startIndex != -1 && endIndex != -1) {
      // 替换原有的项目顺序
      checkinItems.removeRange(startIndex, endIndex + 1);
      checkinItems.insertAll(startIndex, newOrder);
      await CheckinPlugin.shared.triggerSave();
      onStateChanged();
    }
  }

  // 释放资源
  void dispose() {
    // 清理资源
  }
}

/// 本地 TagManagerDialog 配置类
class TagManagerConfig {
  final String title;
  final String addGroupHint;
  final String addTagHint;
  final String editGroupHint;
  final String allTagsLabel;
  final String newGroupLabel;

  const TagManagerConfig({
    this.title = '标签管理',
    this.addGroupHint = '添加分组',
    this.addTagHint = '添加标签',
    this.editGroupHint = '编辑分组',
    this.allTagsLabel = '全部',
    this.newGroupLabel = '新建分组',
  });
}

/// 本地 TagManagerDialog 组件
class TagManagerDialog extends StatefulWidget {
  final List<TagGroup> groups;
  final List<String> selectedTags;
  final Function(List<TagGroup>)? onGroupsChanged;
  final Function(List<String>)? onTagsSelected;
  final Future<String?> Function(String group, {String? tag})? onAddTag;
  final Future<List<TagGroup>> Function()? onRefreshData;
  final TagManagerConfig? config;

  const TagManagerDialog({
    super.key,
    required this.groups,
    required this.selectedTags,
    this.onGroupsChanged,
    this.onTagsSelected,
    this.onAddTag,
    this.onRefreshData,
    this.config,
  });

  @override
  State<TagManagerDialog> createState() => _TagManagerDialogState();
}

class _TagManagerDialogState extends State<TagManagerDialog> {
  late List<TagGroup> _groups;
  late List<String> _selectedTags;
  late String _selectedGroup;

  @override
  void initState() {
    super.initState();
    _groups = List.from(widget.groups);
    _selectedTags = List.from(widget.selectedTags);
    _selectedGroup = _groups.isNotEmpty ? _groups[0].name : '';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 600,
        height: 500,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 标题栏
            Row(
              children: [
                Text(
                  widget.config?.title ?? '标签管理',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(),

            // 分组选择
            if (_groups.isNotEmpty)
              Container(
                height: 50,
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _groups.length,
                  itemBuilder: (context, index) {
                    final group = _groups[index];
                    final isSelected = _selectedGroup == group.name;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(group.name),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedGroup = group.name;
                            });
                          }
                        },
                      ),
                    );
                  },
                ),
              ),

            const Divider(),

            // 标签列表
            Expanded(
              child: _buildTagsList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTagsList() {
    if (_groups.isEmpty) {
      return const Center(child: Text('暂无分组'));
    }

    final currentGroup = _groups.firstWhere(
      (g) => g.name == _selectedGroup,
      orElse: () => _groups[0],
    );

    if (currentGroup.tags.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('分组「${currentGroup.name}」暂无标签'),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('添加标签'),
              onPressed: () => _handleAddTag(currentGroup.name),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: currentGroup.tags.length,
      itemBuilder: (context, index) {
        final tag = currentGroup.tags[index];
        final isSelected = _selectedTags.contains(tag);
        return CheckboxListTile(
          title: Text(tag),
          value: isSelected,
          onChanged: (value) {
            setState(() {
              if (value == true) {
                _selectedTags.add(tag);
              } else {
                _selectedTags.remove(tag);
              }
              widget.onTagsSelected?.call(_selectedTags);
            });
          },
        );
      },
    );
  }

  Future<void> _handleAddTag(String group) async {
    final result = await widget.onAddTag?.call(group);
    if (result != null) {
      // 刷新数据
      final updated = await widget.onRefreshData?.call();
      if (updated != null) {
        setState(() {
          _groups = updated;
        });
        widget.onGroupsChanged?.call(_groups);
      }
    }
  }
}
