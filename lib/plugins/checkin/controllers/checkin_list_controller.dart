import 'dart:async';
import 'package:Memento/l10n/app_localizations.dart';
import 'package:Memento/widgets/tag_manager_dialog.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/checkin_item.dart';
import '../screens/checkin_form_screen.dart';
import 'package:intl/intl.dart';
import '../checkin_plugin.dart';
import '../services/group_sort_service.dart';
import '../widgets/group_sort_dialog.dart';
import '../../../core/event/event_manager.dart';
import '../../../core/event/item_event_args.dart';

class CheckinListController {
  final BuildContext context;
  final List<CheckinItem> checkinItems;
  final Function() onStateChanged;
  final Map<String, bool> expandedGroups;
  GroupSortType currentSortType = GroupSortType.upcoming;
  bool isReversed = false;

  CheckinListController({
    required this.context,
    required this.checkinItems,
    required this.onStateChanged,
    required this.expandedGroups,
  });

  // 获取所有分组
  List<String> get groups =>
      checkinItems.map((item) => item.group).toSet().toList()..sort();

  // 构建分组列表项
  List<Map<String, dynamic>> buildGroupListItems() {
    final items = <Map<String, dynamic>>[];
    for (var group in groups) {
      final groupItems = groupedItems[group] ?? [];
      final completedCount =
          groupItems.where((item) => item.isCheckedToday()).length;
      items.add({
        'group': group,
        'items': groupItems,
        'completedCount': completedCount,
        'total': groupItems.length,
      });
    }

    // 应用排序
    return GroupSortService.sortGroups(items, currentSortType, isReversed);
  }

  // 按分组获取打卡项目
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
    for (var group in groups) {
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
      'todayCheckins': todayCheckins, // 添加今日打卡总次数
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

  // 获取特定分组的统计信息
  Map<String, int> getGroupStats(String group) {
    final items = groupedItems[group] ?? [];
    final completed = items.where((item) => item.isCheckedToday()).length;
    return {'total': items.length, 'completed': completed};
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

  // 显示分组排序对话框
  Future<void> showGroupSortDialog() async {
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
    Navigator.push<CheckinItem>(
      context,
      MaterialPageRoute(
        builder: (context) => CheckinFormScreen(initialItem: item),
      ),
    ).then((updatedItem) {
      if (updatedItem != null) {
        final index = checkinItems.indexWhere((i) => i.id == updatedItem.id);
        if (index != -1) {
          checkinItems[index] = updatedItem;
          CheckinPlugin.shared.triggerSave();
          onStateChanged();
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
            title: const Text('删除打卡项'),
            content: Text('确定要删除"${item.name}"吗？此操作不可恢复。'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(AppLocalizations.of(context)!.cancel),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  checkinItems.removeWhere((i) => i.id == item.id);
                  // 发送删除事件
                  notifyEvent('deleted', item);
                  CheckinPlugin.shared.triggerSave();
                  onStateChanged();
                },
                child: const Text('删除', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );
  }

  // 显示打卡项目操作菜单
  void showItemOptionsDialog(CheckinItem item) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.edit),
                  title: const Text('编辑打卡项目'),
                  onTap: () {
                    Navigator.pop(context);
                    _editCheckinItem(item);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.refresh),
                  title: const Text('重置打卡记录'),
                  onTap: () {
                    Navigator.pop(context);
                    _showResetConfirmDialog(item);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('删除', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(context);
                    _showDeleteConfirmDialog(item);
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
    );
  }

  // 编辑打卡项目
  void _editCheckinItem(CheckinItem item) {
    Navigator.push<CheckinItem>(
      context,
      MaterialPageRoute(
        builder: (context) => CheckinFormScreen(initialItem: item),
      ),
    ).then((editedItem) async {
      if (editedItem != null) {
        final index = checkinItems.indexOf(item);
        if (index != -1) {
          checkinItems[index] = editedItem;
          // 如果分组改变了，确保新分组是展开的
          expandedGroups[editedItem.group] = true;
          await CheckinPlugin.shared.triggerSave();
          onStateChanged();
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
            title: const Text('重置打卡记录'),
            content: Text('确定要重置"${item.name}"的所有打卡记录吗？这将清除所有历史打卡数据，且无法恢复。'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(AppLocalizations.of(context)!.cancel),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await item.resetRecords();
                  onStateChanged();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('已重置"${item.name}"的打卡记录')),
                  );
                },
                child: const Text('确定重置', style: TextStyle(color: Colors.red)),
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
            title: const Text('删除打卡项目'),
            content: Text('确定要删除"${item.name}"吗？这将同时删除所有历史打卡记录，且无法恢复。'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(AppLocalizations.of(context)!.cancel),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  checkinItems.remove(item);
                  // 发送删除事件
                  notifyEvent('deleted', item);
                  await CheckinPlugin.shared.triggerSave();
                  onStateChanged();
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('已删除"${item.name}"')));
                },
                child: const Text('确定删除', style: TextStyle(color: Colors.red)),
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
                const Text('打卡成功'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('您已成功完成 ${item.name} 的打卡'),
                const SizedBox(height: 8),
                Text(
                  '时间段: ${timeFormat.format(record.startTime)} - ${timeFormat.format(record.endTime)}',
                  style: const TextStyle(fontSize: 14),
                ),
                if (record.note != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '备注: ${record.note}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
                const SizedBox(height: 8),
                if (streak > 1)
                  Text(
                    '连续打卡天数: $streak',
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
                child: Text(AppLocalizations.of(context)!.ok),
              ),
            ],
          ),
    );
  }

  // 显示分组管理对话框
  void showGroupManagementDialog() {
    // 获取当前的标签组
    List<TagGroup> getCurrentTagGroups() {
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

                // 确保新分组是展开的
                expandedGroups[tagGroup.name] = true;

                // 更新现有项目的分组
                for (var tag in tagGroup.tags) {
                  // 如果标签不在现有项目中，创建新项目
                  if (!existingItemNames.contains(tag)) {
                    // 这里不需要显示对话框，因为已经通过onAddTag回调处理了
                    // 只需确保标签已经被正确添加到项目中
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
            config: const TagManagerConfig(
              title: '管理分组',
              addGroupHint: '请输入分组名称',
              addTagHint: '请输入打卡项目名称',
              editGroupHint: '请输入新的分组名称',
              allTagsLabel: '所有打卡项目',
              newGroupLabel: '新建分组',
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

    Navigator.push<CheckinItem>(
      context,
      MaterialPageRoute(
        builder:
            (context) => CheckinFormScreen(
              initialItem:
                  existingItem ??
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
        // 确保新添加的项目所在的分组是展开的
        expandedGroups[checkinItem.group] = true;
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
    expandedGroups.clear();
  }
}
