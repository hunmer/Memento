import 'package:flutter/material.dart';
import '../models/checkin_item.dart';
import '../../../utils/audio_service.dart';

class CheckinDetailScreen extends StatelessWidget {
  final CheckinItem checkinItem;

  const CheckinDetailScreen({super.key, required this.checkinItem});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(checkinItem.name),
        backgroundColor: checkinItem.color,
      ),
      body: Column(
        children: [
          // 打卡状态卡片
          _buildStatusCard(),

          // 打卡历史列表
          Expanded(child: _buildHistoryList()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          if (!checkinItem.isCheckedToday()) {
            await AudioService().playCheckInSound();

            // 创建一个默认的打卡记录
            final now = DateTime.now();
            final record = CheckinRecord(
              startTime: now,
              endTime: now,
              checkinTime: now,
              note: '快速打卡',
            );

            await checkinItem.addCheckinRecord(record);
          } else {
            // 获取今天的所有打卡记录并取消第一个
            final todayRecords = checkinItem.getTodayRecords();
            if (todayRecords.isNotEmpty) {
              // 找到对应的记录键
              DateTime? recordKey;
              checkinItem.checkInRecords.forEach((key, value) {
                if (value == todayRecords.first) {
                  recordKey = key;
                }
              });

              if (recordKey != null) {
                await checkinItem.cancelCheckinRecord(recordKey!);
              }
            }
          }

          // 刷新页面
          if (context.mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder:
                    (context) => CheckinDetailScreen(checkinItem: checkinItem),
              ),
            );
          }
        },
        backgroundColor: checkinItem.color,
        child: Icon(checkinItem.isCheckedToday() ? Icons.close : Icons.check),
      ),
    );
  }

  Widget _buildStatusCard() {
    final consecutiveDays = checkinItem.getConsecutiveDays();
    final now = DateTime.now();
    final monthlyRecords = checkinItem.getMonthlyRecords(now.year, now.month);
    final monthlyCount = monthlyRecords.length;

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatusItem(
              '今日状态',
              checkinItem.isCheckedToday() ? '已打卡' : '未打卡',
              checkinItem.isCheckedToday() ? Icons.check_circle : Icons.cancel,
            ),
            _buildStatusItem(
              '连续打卡',
              '$consecutiveDays天',
              Icons.local_fire_department,
            ),
            _buildStatusItem('本月完成', '$monthlyCount天', Icons.calendar_month),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: checkinItem.color, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: checkinItem.color,
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildHistoryList() {
    // 获取最近30天的打卡记录
    final List<DateTime> dates = List.generate(
      30,
      (index) => DateTime.now().subtract(Duration(days: index)),
    );

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: dates.length,
      itemBuilder: (context, index) {
        final date = dates[index];
        // 检查该日期是否有打卡记录
        final hasRecord = checkinItem.checkInRecords.keys.any(
          (key) =>
              key.year == date.year &&
              key.month == date.month &&
              key.day == date.day,
        );

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color:
                    hasRecord
                        ? checkinItem.color.withAlpha(
                          25,
                        ) // 使用withAlpha代替withOpacity
                        : Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                hasRecord ? Icons.check_circle : Icons.circle_outlined,
                color: hasRecord ? checkinItem.color : Colors.grey,
              ),
            ),
            title: Text(
              '${date.year}年${date.month}月${date.day}日',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            trailing: Text(
              hasRecord ? '已打卡' : '未打卡',
              style: TextStyle(
                color: hasRecord ? checkinItem.color : Colors.grey,
              ),
            ),
          ),
        );
      },
    );
  }
}
