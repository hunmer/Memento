import 'package:flutter/material.dart';
import 'package:Memento/widgets/backup_time_picker.dart';

/// 备份时间选择器示例
class BackupTimePickerExample extends StatelessWidget {
  const BackupTimePickerExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('备份时间选择器'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'BackupTimePicker',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            const Text('这是一个备份时间选择器，支持多种备份计划类型。'),
            const SizedBox(height: 8),
            const Text('支持的计划类型:'),
            const SizedBox(height: 8),
            const Text('• 指定日期备份'),
            const Text('• 每天备份'),
            const Text('• 每周指定日备份'),
            const Text('• 每月指定日备份'),
            const SizedBox(height: 32),
            Center(
              child: ElevatedButton.icon(
                onPressed: () => _showBackupTimePicker(context),
                icon: const Icon(Icons.access_time),
                label: const Text('设置备份时间'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBackupTimePicker(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) => const BackupTimePicker(
        onScheduleSelected: _onScheduleSelected,
      ),
    );
  }

  static void _onScheduleSelected(dynamic schedule) {
    debugPrint('已选择备份计划: $schedule');
  }
}
