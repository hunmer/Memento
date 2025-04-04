import 'package:flutter/material.dart';
import '../models/checkin_item.dart';
import '../widgets/checkin_form_dialog.dart';
import '../screens/checkin_detail_screen.dart';
import '../../../widgets/circle_icon_picker.dart';
import '../../../widgets/group_management_dialog.dart';
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

    return {
      'groupStats': groupStats,
      'totalItems': totalItems,
      'completedItems': completedItems,
      'completionRate': completionRate,
    };
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
  void showCheckinSuccessDialog(CheckinItem item) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    scaffoldMessenger.clearSnackBars(); // 清除所有现有的 SnackBar
    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Text('${item.name}打卡成功！连续打卡${item.getConsecutiveDays()}天'),
        backgroundColor: item.color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3), // 设置显示时间为3秒
        action: SnackBarAction(
          label: '查看详情',
          textColor: Colors.white,
          onPressed: () {
            scaffoldMessenger.hideCurrentSnackBar(); // 点击时立即隐藏当前 SnackBar
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CheckinDetailScreen(checkinItem: item),
              ),
            );
          },
        ),
      ),
    );
  }

  // 显示分组管理对话框
  void showGroupManagementDialog() {
    showDialog(
      context: context,
      builder:
          (BuildContext dialogContext) => StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return AlertDialog(
                title: const Text('分组管理'),
                content: SizedBox(
                  width: double.maxFinite,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (groups.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(
                            child: Text(
                              '暂无分组',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        )
                      else
                        Flexible(
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: groups.length,
                            itemBuilder: (context, index) {
                              final group = groups[index];
                              final items = groupedItems[group] ?? [];
                              final completedCount =
                                  items
                                      .where((item) => item.isCheckedToday())
                                      .length;

                              return ListTile(
                                leading: const Icon(Icons.folder_outlined),
                                title: Text(group),
                                subtitle: Text(
                                  '${items.length}个项目，$completedCount个已打卡',
                                  style: TextStyle(
                                    color:
                                        completedCount > 0
                                            ? Colors.green
                                            : Colors.grey,
                                  ),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (items.isEmpty)
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline),
                                        tooltip: '删除空分组',
                                        onPressed: () {
                                          // 空分组不需要特别处理，因为分组是根据打卡项目动态生成的
                                          Navigator.pop(context);
                                        },
                                      ),
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined),
                                      tooltip: '编辑分组',
                                      onPressed: () {
                                        _showEditOrCreateGroupDialog(
                                          group: group,
                                          items: items,
                                          parentContext: dialogContext,
                                          onGroupUpdated: () => setState(() {}),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('关闭'),
                  ),
                  TextButton(
                    onPressed: () {
                      _showEditOrCreateGroupDialog(
                        parentContext: dialogContext,
                        onGroupUpdated: () => setState(() {}),
                      );
                    },
                    child: const Text('新建'),
                  ),
                ],
              );
            },
          ),
    ).then((_) {
      // 关闭对话框后刷新界面
      onStateChanged();
    });
  }

  // 显示编辑或创建分组对话框
  void _showEditOrCreateGroupDialog({
    String? group,
    List<CheckinItem>? items,
    required BuildContext parentContext,
    required VoidCallback onGroupUpdated,
  }) {
    final bool isEditing = group != null;
    final TextEditingController groupController = TextEditingController(
      text: group,
    );
    IconData selectedIcon = Icons.folder; // 默认图标
    Color selectedColor = Colors.blue; // 默认颜色

    showDialog(
      context: parentContext,
      builder:
          (BuildContext context) => StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return AlertDialog(
                title: Text(isEditing ? '编辑分组' : '新建分组'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleIconPicker(
                        currentIcon: selectedIcon,
                        backgroundColor: selectedColor,
                        onIconSelected: (icon) {
                          setState(() => selectedIcon = icon);
                        },
                        onColorSelected: (color) {
                          setState(() => selectedColor = color);
                        },
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        controller: groupController,
                        decoration: const InputDecoration(
                          labelText: '分组名称',
                          hintText: '请输入分组名称',
                        ),
                      ),
                      if (isEditing) ...[
                        const SizedBox(height: 16),
                        Text('该分组包含 ${items!.length} 个打卡项目'),
                      ],
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('取消'),
                  ),
                  TextButton(
                    onPressed: () async {
                      final newGroupName = groupController.text.trim();
                      if (newGroupName.isNotEmpty &&
                          (!isEditing || newGroupName != group)) {
                        if (isEditing) {
                          // 更新所有该分组下的打卡项目
                          for (var item in items!) {
                            item.group = newGroupName;
                          }
                          // 确保新分组是展开的
                          expandedGroups.remove(group);
                          expandedGroups[newGroupName] = true;
                        } else {
                          // 创建一个新的打卡项目作为分组标记
                          final groupMarker = CheckinItem(
                            name: newGroupName,
                            icon: selectedIcon,
                            color: selectedColor,
                            group: newGroupName,
                          );
                          checkinItems.add(groupMarker);
                          expandedGroups[newGroupName] = true;
                        }

                        await CheckinPlugin.shared.triggerSave();
                        Navigator.pop(context);
                        onGroupUpdated();
                        onStateChanged();
                        ScaffoldMessenger.of(parentContext).showSnackBar(
                          SnackBar(
                            content: Text(
                              isEditing
                                  ? '已更新分组"$newGroupName"'
                                  : '已创建新分组"$newGroupName"',
                            ),
                          ),
                        );
                      } else {
                        Navigator.pop(context);
                      }
                    },
                    child: const Text('保存'),
                  ),
                ],
              );
            },
          ),
    );
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
