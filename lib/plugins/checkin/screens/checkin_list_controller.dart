import 'package:flutter/material.dart';
import '../models/checkin_item.dart';
import '../widgets/checkin_form_dialog.dart';
import 'checkin_detail_screen.dart';

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

  // 获取统计信息
  Map<String, dynamic> getStatistics() {
    // 获取分组统计信息
    final groupStats = <String, Map<String, int>>{};
    for (var group in groups) {
      final items = groupedItems[group] ?? [];
      final completed = items.where((item) => item.isCheckedToday()).length;
      groupStats[group] = {
        'total': items.length,
        'completed': completed,
      };
    }
    
    // 计算总体完成率
    int totalItems = checkinItems.length;
    int completedItems = checkinItems.where((item) => item.isCheckedToday()).length;
    double completionRate = totalItems > 0 ? completedItems / totalItems * 100 : 0;

    return {
      'groupStats': groupStats,
      'totalItems': totalItems,
      'completedItems': completedItems,
      'completionRate': completionRate,
    };
  }

  // 切换编辑模式
  void toggleEditMode() {
    isEditMode = !isEditMode;
    onStateChanged();
  }

  // 获取所有分组
  List<String> get groups => checkinItems
      .map((item) => item.group ?? '未分组')
      .toSet()
      .toList()
    ..sort();

  // 按分组获取打卡项目
  Map<String, List<CheckinItem>> get groupedItems {
    final grouped = <String, List<CheckinItem>>{};
    for (var item in checkinItems) {
      final group = item.group ?? '未分组';
      if (!grouped.containsKey(group)) {
        grouped[group] = [];
      }
      grouped[group]!.add(item);
    }
    return grouped;
  }

  // 显示打卡项目操作菜单
  void showItemOptionsDialog(CheckinItem item) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
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
    ).then((editedItem) {
      if (editedItem != null) {
        final index = checkinItems.indexOf(item);
        if (index != -1) {
          checkinItems[index] = editedItem;
          // 如果分组改变了，确保新分组是展开的
          expandedGroups[editedItem.group ?? '未分组'] = true;
          onStateChanged();
        }
      }
    });
  }

  // 显示重置确认对话框
  void _showResetConfirmDialog(CheckinItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('重置打卡记录'),
        content: Text('确定要重置"${item.name}"的所有打卡记录吗？\n此操作不可恢复！'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () {
              final index = checkinItems.indexOf(item);
              if (index != -1) {
                checkinItems[index] = CheckinItem(
                  id: item.id,
                  name: item.name,
                  icon: item.icon,
                  color: item.color,
                  group: item.group,
                  checkInRecords: {}, // 清空打卡记录
                );
                onStateChanged();
              }
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('已重置"${item.name}"的打卡记录'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('重置'),
          ),
        ],
      ),
    );
  }

  // 显示删除确认对话框
  void _showDeleteConfirmDialog(CheckinItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除打卡项目'),
        content: Text('确定要删除"${item.name}"吗？\n此操作不可恢复！'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () {
              checkinItems.remove(item);
              onStateChanged();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('已删除"${item.name}"'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  // 显示打卡成功对话框
  void showCheckinSuccessDialog(CheckinItem item) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${item.name}打卡成功！连续打卡${item.getConsecutiveDays()}天'),
        backgroundColor: item.color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        action: SnackBarAction(
          label: '查看详情',
          textColor: Colors.white,
          onPressed: () {
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
    final TextEditingController newGroupController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('分组管理'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 添加新分组
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: newGroupController,
                      decoration: const InputDecoration(
                        labelText: '新分组名称',
                        hintText: '请输入新分组名称',
                        prefixIcon: Icon(Icons.folder_outlined),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () {
                      final newGroup = newGroupController.text.trim();
                      if (newGroup.isNotEmpty) {
                        newGroupController.clear();
                        Navigator.pop(context);
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // 现有分组列表
              const Text(
                '现有分组:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
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
                      final completedCount = items.where((item) => item.isCheckedToday()).length;
                      
                      return ListTile(
                        leading: const Icon(Icons.folder_outlined),
                        title: Text(group),
                        subtitle: Text(
                          '${items.length}个项目，$completedCount个已打卡',
                          style: TextStyle(
                            color: completedCount > 0 ? Colors.green : Colors.grey,
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
                                  Navigator.pop(context);
                                },
                              ),
                            IconButton(
                              icon: const Icon(Icons.edit_outlined),
                              tooltip: '编辑分组',
                              onPressed: () {
                                _showEditGroupDialog(group, items);
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
        ],
      ),
    ).then((_) {
      onStateChanged();
    });
  }

  // 显示编辑分组对话框
  void _showEditGroupDialog(String currentGroup, List<CheckinItem> items) {
    final TextEditingController groupController = TextEditingController(text: currentGroup);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('编辑分组'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: groupController,
              decoration: const InputDecoration(
                labelText: '分组名称',
                hintText: '请输入新的分组名称',
                prefixIcon: Icon(Icons.folder_outlined),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '该分组包含 ${items.length} 个打卡项目',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              final newGroupName = groupController.text.trim();
              if (newGroupName.isNotEmpty && newGroupName != currentGroup) {
                // 更新所有属于该分组的打卡项目
                for (var item in items) {
                  final index = checkinItems.indexOf(item);
                  if (index != -1) {
                    checkinItems[index] = CheckinItem(
                      id: item.id,
                      name: item.name,
                      icon: item.icon,
                      color: item.color,
                      group: newGroupName.isNotEmpty ? newGroupName : '默认分组',
                      checkInRecords: item.checkInRecords,
                    );
                  }
                }
                onStateChanged();
              }
              Navigator.pop(context); // 关闭编辑对话框
              Navigator.pop(context); // 关闭分组管理对话框
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  // 获取分组的统计信息
  Map<String, int> getGroupStats(String group) {
    final items = groupedItems[group] ?? [];
    final completedCount = items.where((item) => item.isCheckedToday()).length;
    return {
      'total': items.length,
      'completed': completedCount,
    };
  }

  // 获取分组的完成数量
  int getGroupCompletedCount(String group) {
    final items = groupedItems[group] ?? [];
    return items.where((item) => item.isCheckedToday()).length;
  }

  // 构建分组列表项
  List<Map<String, dynamic>> buildGroupListItems() {
    return groups.map((group) {
      final items = groupedItems[group] ?? [];
      final completedCount = getGroupCompletedCount(group);
      
      return {
        'group': group,
        'items': items,
        'completedCount': completedCount,
        'total': items.length,
      };
    }).toList();
  }

  // 显示添加打卡项目对话框
  void showAddCheckinItemDialog() {
    showDialog<CheckinItem>(
      context: context,
      builder: (context) => const CheckinFormDialog(),
    ).then((checkinItem) {
      if (checkinItem != null) {
        checkinItems.add(checkinItem);
        // 确保新添加的项目所在的分组是展开的
        expandedGroups[checkinItem.group ?? '未分组'] = true;
        onStateChanged();
      }
    });
  }
}