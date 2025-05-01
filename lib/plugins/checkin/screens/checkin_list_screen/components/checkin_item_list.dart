import 'package:flutter/material.dart';
import '../../../controllers/checkin_list_controller.dart';
import '../../../models/checkin_item.dart';
import 'checkin_item_card.dart';

class CheckinItemList extends StatelessWidget {
  final List<CheckinItem> items;
  final String group;
  final int groupIndex;
  final CheckinListController controller;
  final VoidCallback onStateChanged;

  const CheckinItemList({
    super.key,
    required this.items,
    required this.group,
    required this.groupIndex,
    required this.controller,
    required this.onStateChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ReorderableListView.builder(
      buildDefaultDragHandles: false, // 禁用默认拖拽手柄
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      onReorder: (oldIndex, newIndex) {
        if (controller.isEditMode) {
          if (oldIndex < newIndex) {
            newIndex -= 1;
          }

          // 获取当前分组的所有项目
          final groupItems = List<CheckinItem>.from(items);

          // 重新排序项目
          final movedItem = groupItems.removeAt(oldIndex);
          groupItems.insert(newIndex, movedItem);

          // 更新 checkinItems
          final allItems = controller.checkinItems;
          final firstGroupItemIndex = allItems.indexWhere(
            (item) => item.group == group,
          );

          // 移除旧的分组项目
          allItems.removeWhere((item) => item.group == group);

          // 在正确位置插入新的分组项目
          allItems.insertAll(firstGroupItemIndex, groupItems);

          onStateChanged();
        }
      },
      itemBuilder: (context, index) {
        final item = items[index];
        final itemIndex = controller.checkinItems.indexOf(item);

        return CheckinItemCard(
          key: ValueKey('item_${item.id}_$index'),
          item: item,
          index: index,
          itemIndex: itemIndex,
          controller: controller,
          onStateChanged: onStateChanged,
        );
      },
    );
  }
}