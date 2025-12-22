import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/plugins/checkin/models/checkin_item.dart';
import 'package:Memento/plugins/checkin/controllers/checkin_list_controller.dart';
import 'package:intl/intl.dart';
import 'package:Memento/core/route/route_history_manager.dart';

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
  void initState() {
    super.initState();
    // 初始化时设置路由上下文
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateRouteContext();
    });
  }

  /// 更新路由上下文，使"询问当前上下文"功能能获取到当前查看的打卡项目
  void _updateRouteContext() {
    final itemName = widget.checkinItem.name;
    RouteHistoryManager.updateCurrentContext(
      pageId: "/checkin_record",
      title: '打卡记录 - $itemName',
      params: {'itemName': itemName},
    );
  }

  @override
  Widget build(BuildContext context) {
    // 按日期分组打卡记录
    final recordsByDate = <DateTime, List<CheckinRecord>>{};
    for (var entry in widget.checkinItem.checkInRecords.entries) {
      // 解析日期字符串为DateTime
      final dateParts = entry.key.split('-');
      if (dateParts.length == 3) {
        final date = DateTime(
          int.parse(dateParts[0]),
          int.parse(dateParts[1]),
          int.parse(dateParts[2]),
        );
        recordsByDate.putIfAbsent(date, () => []).addAll(entry.value);
      }
    }

    // 对日期进行排序（降序）
    final sortedDates =
        recordsByDate.keys.toList()..sort((a, b) => b.compareTo(a));

    return Scaffold(
      appBar: AppBar(
        title: Text('checkin_checkinRecordsTitle'.tr),
      ),
      body:
          sortedDates.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                itemCount: sortedDates.length,
                itemBuilder: (context, index) {
                  final date = sortedDates[index];
                  final records = recordsByDate[date]!;
                  records.sort(
                    (a, b) => b.checkinTime.compareTo(a.checkinTime),
                  ); // 按打卡时间降序排序

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
                                .withValues(alpha: 0.5),
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
                            final record = records[recordIndex];
                            return ListTile(
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
                                      records[recordIndex].checkinTime,
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
          Text(
            'checkin_noRecords'.tr,
            style: Theme.of(context).textTheme.titleMedium,
          ),
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
            title: Text(
              'checkin_deleteCheckinRecordTitle'.tr,
            ),
            content: Text(
              'checkin_deleteCheckinRecordMessage'.tr,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('app_cancel'.tr),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await widget.checkinItem.cancelCheckinRecord(recordTime);
                  if (mounted) {
                    setState(() {});
                  }
                },
                child: Text(
                  'app_delete'.tr,
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }
}
