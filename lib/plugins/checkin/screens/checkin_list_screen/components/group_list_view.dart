import 'package:flutter/material.dart';
import '../../../controllers/checkin_list_controller.dart';
import '../../../models/checkin_item.dart';
import 'group_card.dart';

class GroupListView extends StatelessWidget {
  final List<Map<String, dynamic>> groupListItems;
  final CheckinListController controller;
  final VoidCallback onStateChanged;

  const GroupListView({
    super.key,
    required this.groupListItems,
    required this.controller,
    required this.onStateChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ReorderableListView.builder(
      buildDefaultDragHandles: false, // 禁用默认拖拽手柄
      itemCount: groupListItems.length,
      onReorder: (oldIndex, newIndex) {
      },
      itemBuilder: (context, groupIndex) {
        final groupData = groupListItems[groupIndex];
        final group = groupData['group'] as String;
        final items = (groupData['items'] as List<dynamic>).cast<CheckinItem>();
        final completedCount = groupData['completedCount'] as int;
        final total = groupData['total'] as int;
        final isExpanded = controller.expandedGroups[group] ?? true;

        return GroupCard(
          key: ValueKey('group_${group}_$groupIndex'),
          group: group,
          items: items,
          completedCount: completedCount,
          total: total,
          isExpanded: isExpanded,
          groupIndex: groupIndex,
          controller: controller,
          onStateChanged: onStateChanged,
        );
      },
    );
  }
}