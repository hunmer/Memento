import 'package:flutter/material.dart';
import '../models/checkin_item.dart';
import '../controllers/checkin_list_controller.dart';
import 'package:intl/intl.dart';

class CheckinRecordScreen extends StatefulWidget {
  final CheckinItem checkinItem;
  final CheckinListController controller;

  const CheckinRecordScreen({
    super.key, 
    required this.checkinItem,
    required this.controller,
  });

  @override
  State<CheckinRecordScreen> createState() => _CheckinRecordScreenState();
}

class _CheckinRecordScreenState extends State<CheckinRecordScreen> {
  final _dateFormat = DateFormat('yyyy-MM-dd');
  final _timeFormat = DateFormat('HH:mm');

  @override
  Widget build(BuildContext context) {
    // 按日期分组打卡记录
    final recordsByDate = <DateTime, List<MapEntry<DateTime, CheckinRecord>>>{};

    for (var entry in widget.checkinItem.checkInRecords.entries) {
      final date = DateTime(entry.key.year, entry.key.month, entry.key.day);
      recordsByDate.putIfAbsent(date, () => []).add(entry);
    }

    // 对日期进行排序（降序）
    final sortedDates =
        recordsByDate.keys.toList()..sort((a, b) => b.compareTo(a));

    return Scaffold(
      appBar: AppBar(title: Text('${widget.checkinItem.name}的打卡记录')),
      body:
          sortedDates.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                itemCount: sortedDates.length,
                itemBuilder: (context, index) {
                  final date = sortedDates[index];
                  final records = recordsByDate[date]!;
                  records.sort((a, b) => b.key.compareTo(a.key)); // 按时间降序排序

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 日期标题
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest
                                .withOpacity(0.5),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(12),
                            ),
                          ),
                          child: Row(
                            children: [
                              Text(
                                _dateFormat.format(date),
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${records.length}次打卡',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                        // 打卡记录列表
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: records.length,
                          itemBuilder: (context, recordIndex) {
                            final record = records[recordIndex].value;
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: widget.checkinItem.color,
                                child: Text(
                                  '${recordIndex + 1}',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              title: Row(
                                children: [
                                  Text(
                                    '${_timeFormat.format(record.startTime)} - ${_timeFormat.format(record.endTime)}',
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '打卡时间：${_timeFormat.format(record.checkinTime)}',
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                              subtitle:
                                  record.note != null
                                      ? Text(
                                        record.note!,
                                        style:
                                            Theme.of(
                                              context,
                                            ).textTheme.bodySmall,
                                      )
                                      : null,
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed:
                                    () => _showDeleteConfirmDialog(
                                      records[recordIndex].key,
                                    ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_busy,
            size: 64,
            color: Theme.of(context).disabledColor,
          ),
          const SizedBox(height: 16),
          Text('暂无打卡记录', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            '点击打卡按钮开始记录',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).hintColor,
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmDialog(DateTime recordTime) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('删除打卡记录'),
            content: const Text('确定要删除这条打卡记录吗？此操作不可恢复。'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await widget.checkinItem.cancelCheckinRecord(recordTime);
                  if (mounted) {
                    setState(() {});
                  }
                },
                child: const Text('删除', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );
  }
}
