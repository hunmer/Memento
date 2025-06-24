import 'package:flutter/material.dart';
import '../../../controllers/checkin_list_controller.dart';
import '../../../models/checkin_item.dart';
import '../../../screens/checkin_record_screen.dart';
import '../../../widgets/checkin_record_dialog.dart';
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
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => CheckinRecordScreen(
                    checkinItem: item,
                    controller: controller,
                  ),
            ),
          ).then((_) => onStateChanged());
        },
        onLongPress: () {
          controller.showItemOptionsDialog(item);
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // 项目名称、图标和描述
                  Expanded(
                    child: Row(
                      children: [
                        // 项目图标
                        Icon(item.icon, color: item.color, size: 24),
                        const SizedBox(width: 8),

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
                      ],
                    ),
                  ),
                ],
              ),

              // 打卡记录信息
              Padding(
                padding: const EdgeInsets.only(left: 8.0, top: 4.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
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
                    // 今日打卡记录
                    ..._buildTodayRecords(context),
                  ],
                ),
              ),

              // 周打卡圆圈
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: WeeklyCheckinCircles(
                  item: item,
                  onDateSelected: (selectedDate) {
                    showDialog(
                      context: context,
                      builder:
                          (context) => CheckinRecordDialog(
                            item: item,
                            controller: controller,
                            onCheckinCompleted: onStateChanged,
                            selectedDate: selectedDate,
                          ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildTodayRecords(BuildContext context) {
    final todayRecords = item.getTodayRecords();
    if (todayRecords.isEmpty) {
      return [];
    }

    return [
      const SizedBox(height: 8),
      Text(
        '今日打卡记录:',
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
      ),
      ...todayRecords.map((record) {
        final timeStr =
            '${record.startTime.hour.toString().padLeft(2, '0')}:${record.startTime.minute.toString().padLeft(2, '0')} - '
            '${record.endTime.hour.toString().padLeft(2, '0')}:${record.endTime.minute.toString().padLeft(2, '0')}';
        return Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  timeStr + (record.note != null ? ' (${record.note})' : ''),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 16),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder:
                        (context) => AlertDialog(
                          title: const Text('删除打卡记录'),
                          content: const Text('确定要删除这条打卡记录吗？'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('取消'),
                            ),
                            TextButton(
                              onPressed: () async {
                                await item.cancelCheckinRecord(
                                  record.checkinTime,
                                );
                                onStateChanged();
                                if (context.mounted) {
                                  Navigator.of(context).pop();
                                }
                              },
                              child: const Text('删除'),
                            ),
                          ],
                        ),
                  );
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        );
      }),
    ];
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
