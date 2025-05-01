import 'package:flutter/material.dart';
import '../../../controllers/checkin_list_controller.dart';
import '../../../models/checkin_item.dart';
import 'checkin_item_list.dart';

class GroupCard extends StatelessWidget {
  final String group;
  final List<CheckinItem> items;
  final int completedCount;
  final int total;
  final bool isExpanded;
  final int groupIndex;
  final CheckinListController controller;
  final VoidCallback onStateChanged;

  const GroupCard({
    super.key,
    required this.group,
    required this.items,
    required this.completedCount,
    required this.total,
    required this.isExpanded,
    required this.groupIndex,
    required this.controller,
    required this.onStateChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: 0,
        vertical: 0,
      ),
      elevation: 2,
      child: Column(
        children: [
          // 分组标题
          ListTile(
            title: Text(
              group,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              '$completedCount/$total 已完成',
              style: TextStyle(
                color: completedCount == total
                    ? Colors.green
                    : Theme.of(context).hintColor,
              ),
            ),
            leading: const Icon(Icons.folder),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (controller.isEditMode) ...[
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () {
                      controller.showGroupManagementDialog();
                    },
                  ),
                  // 分组拖拽手柄
                  ReorderableDragStartListener(
                    index: groupIndex,
                    child: const Icon(Icons.drag_handle),
                  ),
                ],
                IconButton(
                  icon: Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                  ),
                  onPressed: () {
                    controller.expandedGroups[group] = !isExpanded;
                    onStateChanged();
                  },
                ),
              ],
            ),
          ),

          // 分组内的打卡项目
          if (isExpanded)
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              margin: const EdgeInsets.symmetric(
                horizontal: 8,
              ),
              child: CheckinItemList(
                items: items,
                group: group,
                groupIndex: groupIndex,
                controller: controller,
                onStateChanged: onStateChanged,
              ),
            ),
        ],
      ),
    );
  }
}