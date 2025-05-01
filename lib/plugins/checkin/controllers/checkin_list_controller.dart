import 'package:Memento/widgets/tag_manager_dialog.dart';
import 'package:flutter/material.dart';
import '../models/checkin_item.dart';
import '../widgets/checkin_form_dialog.dart';
import 'package:intl/intl.dart';
import '../../../widgets/circle_icon_picker.dart';
import '../checkin_plugin.dart';

class CheckinListController {
  final BuildContext context;
  final List<CheckinItem> checkinItems;
  final Function() onStateChanged;
  final Map<String, bool> expandedGroups;
  bool isEditMode = false;

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
    return items;
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

  // 切换编辑模式
  void toggleEditMode() {
    isEditMode = !isEditMode;
    onStateChanged();
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
    showDialog<CheckinItem>(
      context: context,
      builder: (context) => CheckinFormDialog(initialItem: item),
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
                child: const Text('取消'),
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
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  checkinItems.remove(item);
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
                child: const Text('确定'),
              ),
            ],
          ),
    );
  }

  // 显示分组管理对话框
  void showGroupManagementDialog() {
    // 将现有的分组转换为 TagGroup 格式
    List<TagGroup> tagGroups = groups.map((group) {
      final items = groupedItems[group] ?? [];
      return TagGroup(
        name: group,
        tags: items.map((item) => item.name).toList(),
      );
    }).toList();

    // 获取当前选中的标签（打卡项目）
    List<String> selectedTags = checkinItems
        .where((item) => item.isCheckedToday())
        .map((item) => item.name)
        .toList();

    showDialog(
      context: context,
      builder: (context) => TagManagerDialog(
        groups: tagGroups,
        selectedTags: selectedTags,
        onGroupsChanged: (List<TagGroup> updatedGroups) async {
          // 处理分组变更
          for (var tagGroup in updatedGroups) {
            final existingItems = groupedItems[tagGroup.name] ?? [];
            final existingItemNames = existingItems.map((e) => e.name).toSet();
            
            // 确保新分组是展开的
            expandedGroups[tagGroup.name] = true;

            // 更新现有项目的分组
            for (var tag in tagGroup.tags) {
              // 如果标签不在现有项目中，创建新项目
              if (!existingItemNames.contains(tag)) {
                final newItem = CheckinItem(
                  name: tag,
                  icon: Icons.check_box_outline_blank,
                  group: tagGroup.name,
                );
                checkinItems.add(newItem);
              } else {
                // 更新现有项目的分组
                for (var item in checkinItems) {
                  if (item.name == tag && item.group != tagGroup.name) {
                    item.group = tagGroup.name;
                  }
                }
              }
            }

            // 处理被移除的项目
            for (var item in List.from(checkinItems)) {
              if (item.group == tagGroup.name && !tagGroup.tags.contains(item.name)) {
                checkinItems.remove(item);
              }
            }
          }

          // 删除不在更新后分组列表中的项目
          final updatedGroupNames = updatedGroups.map((g) => g.name).toSet();
          checkinItems.removeWhere((item) => !updatedGroupNames.contains(item.group));

          // 保存更改
          await CheckinPlugin.shared.triggerSave();
          onStateChanged();
        },
        onTagsSelected: (List<String> tags) {
          // 处理标签选择变更（如果需要）
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

  // 显示添加打卡项目对话框
  void showAddCheckinItemDialog() {
    showDialog<CheckinItem>(
      context: context,
      builder: (context) => const CheckinFormDialog(),
    ).then((checkinItem) async {
      if (checkinItem != null) {
        checkinItems.add(checkinItem);
        // 确保新添加的项目所在的分组是展开的
        expandedGroups[checkinItem.group] = true;
        await CheckinPlugin.shared.triggerSave();
        onStateChanged();
      }
    });
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
