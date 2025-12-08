import 'package:flutter/material.dart';
import 'package:Memento/plugins/checkin/controllers/checkin_list_controller.dart';
import 'package:Memento/plugins/checkin/models/checkin_item.dart';
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 分组标题
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              const Icon(Icons.folder_outlined, size: 20, color: Colors.grey),
              const SizedBox(width: 8),
              Text(
                group,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Theme.of(context).textTheme.titleMedium?.color,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: completedCount == total
                      ? Colors.green.withValues(alpha: 0.1)
                      : Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$completedCount/$total',
                  style: TextStyle(
                    fontSize: 12,
                    color: completedCount == total
                        ? Colors.green
                        : Theme.of(context).hintColor,
                  ),
                ),
              ),
            ],
          ),
        ),

        // 分组内的打卡项目(始终显示)
        CheckinItemList(
          items: items,
          group: group,
          groupIndex: groupIndex,
          controller: controller,
          onStateChanged: onStateChanged,
        ),
      ],
    );
  }
}