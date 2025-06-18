import 'package:Memento/widgets/group_management_dialog.dart';
import 'package:flutter/material.dart';
import '../models/timer_task.dart';

class TimerGroupManager {
  final List<TimerTask> tasks;
  Map<String, bool> expandedGroups;

  TimerGroupManager(this.tasks, this.expandedGroups);

  // 获取分组列表
  List<String> get groups =>
      tasks.map((task) => task.group).toSet().toList()..sort();

  // 切换分组展开状态
  void toggleGroupExpansion(String group) {
    expandedGroups[group] = !(expandedGroups[group] ?? true);
  }

  // 显示分组管理对话框
  void showGroupManagementDialog(
    BuildContext context, {
    VoidCallback? onDataChanged,
  }) {
    final groupDataList =
        groups.map((group) {
          final groupTasks =
              tasks.where((task) => task.group == group).toList();
          final completedCount =
              groupTasks.where((task) => task.isRunning).length;
          return GroupData(
            name: group,
            itemCount: groupTasks.length,
            completedCount: completedCount,
            items: groupTasks,
          );
        }).toList();

    GroupManagementDialog.show(
      context: context,
      groups: groupDataList,
      expandedGroups: expandedGroups,
      onGroupRenamed: (oldGroup, newGroup) {
        // 更新所有该分组下的任务
        for (var task in tasks) {
          if (task.group == oldGroup) {
            task.group = newGroup;
          }
        }
        // 更新分组展开状态
        expandedGroups.remove(oldGroup);
        expandedGroups[newGroup] = true;
        // 通知父组件数据变更
        if (onDataChanged != null) {
          onDataChanged();
        }
        if (context.mounted) {
          Navigator.pop(context);
        }
      },
      onGroupCreated: (groupName, icon, color) {
        // 创建一个新的任务作为分组标记
        final newTask = TimerTask.create(
          name: groupName,
          color: color,
          icon: icon,
          group: groupName,
          timerItems: [],
        );
        tasks.add(newTask);
        expandedGroups[groupName] = true;
        // 通知UI刷新
        if (context.mounted) {
          Navigator.pop(context);
          showGroupManagementDialog(context);
        }
      },
      customItemBuilder: (context, group) {
        return ListTile(
          leading: const Icon(Icons.folder_outlined),
          title: Text(group.name),
          subtitle: Text(
            '${group.itemCount}个任务，${group.completedCount}个运行中',
            style: TextStyle(
              color: group.completedCount > 0 ? Colors.green : Colors.grey,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (group.itemCount == 0)
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
                  // 通知父组件可能需要刷新
                  if (onDataChanged != null) {
                    onDataChanged();
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
