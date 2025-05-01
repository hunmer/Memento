import 'package:flutter/material.dart';
import '../../../controllers/checkin_list_controller.dart';
import '../../../models/checkin_item.dart';
import '../../../screens/checkin_record_screen.dart';
import '../../../widgets/checkin_record_dialog.dart';
import '../../../models/checkin_item.dart';
import 'package:intl/intl.dart';
import 'weekly_checkin_circles.dart';

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
    final isToday = item.lastCheckinDate != null ? controller.isToday(item.lastCheckinDate) : false;
    final isCompleted = controller.isCompleted(item);

    return Card(
      margin: const EdgeInsets.symmetric(
        vertical: 4,
        horizontal: 8,
      ),
      child: InkWell(
        onTap: controller.isEditMode
            ? null
            : () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CheckinRecordScreen(
                      checkinItem: item,
                      controller: controller,
                    ),
                  ),
                ).then((_) => onStateChanged());
              },
        onLongPress: controller.isEditMode
            ? null
            : () {
                controller.showItemOptionsDialog(item);
              },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (controller.isEditMode) ...[
                    // 编辑模式下的拖拽手柄
                    ReorderableDragStartListener(
                      index: index,
                      child: const Icon(Icons.drag_handle),
                    ),
                    const SizedBox(width: 8),
                  ],

                  // 打卡按钮
                  if (!controller.isEditMode)
                    IconButton(
                      icon: Icon(
                        isCompleted
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        color: isCompleted ? Colors.green : Colors.grey,
                      ),
                      onPressed: () {
                          // 如果今天未打卡，则打卡
                          showDialog(
                            context: context,
                            builder: (context) => CheckinRecordDialog(
                              item: item,
                              controller: controller,
                              onCheckinCompleted: onStateChanged,
                            ),
                          );
                      },
                    ),

                  // 项目名称和描述
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (item.description.isNotEmpty)
                          Text(
                            item.description,
                            style: Theme.of(context).textTheme.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),

                  // 编辑模式下的操作按钮
                  if (controller.isEditMode) ...[
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () {
                        controller.showEditItemDialog(item);
                        onStateChanged();
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () {
                        controller.deleteItem(item);
                        onStateChanged();
                      },
                    ),
                  ],
                ],
              ),

              // 打卡记录信息
              Padding(
                padding: const EdgeInsets.only(left: 8.0, top: 4.0),
                child: Row(
                  children: [
                    // 上次打卡时间
                    if (item.lastCheckinDate != null)
                      Expanded(
                        child: Text(
                          '上次打卡: ${DateFormat('yyyy-MM-dd').format(item.lastCheckinDate!)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),

                    // 打卡频率
                    Text(
                      '频率: ${_getFrequencyText(item)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),

              // 周打卡圆圈
              if (!controller.isEditMode)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: WeeklyCheckinCircles(item: item),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _getFrequencyText(CheckinItem item) {
    if (item.frequency.every((day) => day)) {
      return '每天';
    } else {
      final days = <String>[];
      final weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
      for (var i = 0; i < item.frequency.length; i++) {
        if (item.frequency[i]) {
          days.add(weekdays[i]);
        }
      }
      return days.join(', ');
    }
  }
}