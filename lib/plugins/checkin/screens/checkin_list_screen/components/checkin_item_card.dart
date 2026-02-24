import 'package:flutter/material.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
import 'package:Memento/plugins/checkin/controllers/checkin_list_controller.dart';
import 'package:Memento/plugins/checkin/models/checkin_item.dart';
import 'package:Memento/plugins/checkin/screens/checkin_record_screen.dart';
import 'package:Memento/plugins/checkin/widgets/checkin_record_dialog.dart';
import 'package:Memento/widgets/common/checkin_item_card.dart';

/// 打卡项目卡片组件（插件包装器）
///
/// 作为公共组件的包装器，处理插件特有的业务逻辑（导航、对话框等）。
class CheckinItemCard extends StatelessWidget {
  final CheckinItem item;
  final int index;
  final int itemIndex;
  final CheckinListController controller;
  final VoidCallback onStateChanged;

  const CheckinItemCard({
    super.key,
    required this.item,
    required this.index,
    required this.itemIndex,
    required this.controller,
    required this.onStateChanged,
  });

  @override
  Widget build(BuildContext context) {
    // 使用公共组件构建卡片，通过回调传递业务逻辑
    return CheckinItemCardWidget(
      item: item,
      index: index,
      itemIndex: itemIndex,
      onStateChanged: () => _showCheckinDialog(context, DateTime.now()),
      onTap: () {
        // 导航到打卡历史页面
        NavigationHelper.openContainer<bool>(
          context,
          (context) => CheckinRecordScreen(
            checkinItem: item,
            controller: controller,
          ),
        ).then((result) {
          onStateChanged();
        });
      },
      onLongPress: () {
        // 长按显示选项菜单
        controller.showItemOptionsDialog(item);
      },
      onDateSelected: (selectedDate) {
        // 点击日期圈或日历日期时，显示打卡对话框
        _showCheckinDialog(context, selectedDate);
      },
    );
  }

  // 显示打卡对话框
  void _showCheckinDialog(BuildContext context, DateTime date) {
    showDialog(
      context: context,
      builder: (dialogContext) => CheckinRecordDialog(
        item: item,
        controller: controller,
        onCheckinCompleted: onStateChanged,
        selectedDate: date,
      ),
    );
  }
}
