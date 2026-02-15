import 'package:flutter/material.dart';
import 'package:Memento/widgets/backup_time_picker.dart';

/// 备份时间选择器示例
class BackupTimePickerExample extends StatelessWidget {
  const BackupTimePickerExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width - 32;

    return Scaffold(
      appBar: AppBar(
        title: const Text('备份时间选择器'),
      ),
      body: Container(
        color: isDark ? Colors.black : const Color(0xFFF2F2F7),
        child: SingleChildScrollView(
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

              // 小尺寸
              _buildSectionTitle('小尺寸'),
              const SizedBox(height: 8),
              Center(
                child: SizedBox(
                  width: 180,
                  height: 120,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.access_time,
                            color: Theme.of(context).primaryColor,
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            '备份时间',
                            style: TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: () => _showBackupTimePicker(context),
                            icon: const Icon(Icons.add, size: 14),
                            label: const Text('设置', style: TextStyle(fontSize: 12)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 中尺寸
              _buildSectionTitle('中尺寸'),
              const SizedBox(height: 8),
              Center(
                child: SizedBox(
                  width: 280,
                  height: 180,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.access_time,
                              color: Theme.of(context).primaryColor,
                              size: 40,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            '设置自动备份时间',
                            style: TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            '选择备份频率和时间',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => _showBackupTimePicker(context),
                            icon: const Icon(Icons.access_time),
                            label: const Text('设置备份时间'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 中宽尺寸
              _buildSectionTitle('中宽尺寸'),
              const SizedBox(height: 8),
              SizedBox(
                width: screenWidth,
                height: 160,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.access_time,
                            color: Theme.of(context).primaryColor,
                            size: 36,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '自动备份',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                '设置定时备份计划',
                                style: TextStyle(color: Colors.grey),
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () => _showBackupTimePicker(context),
                                  icon: const Icon(Icons.access_time, size: 18),
                                  label: const Text('设置时间'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 大宽尺寸
              _buildSectionTitle('大宽尺寸'),
              const SizedBox(height: 8),
              SizedBox(
                width: screenWidth,
                height: 200,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(
                                Icons.access_time,
                                color: Theme.of(context).primaryColor,
                                size: 48,
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '备份时间设置',
                                    style: Theme.of(context).textTheme.titleLarge,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '支持指定日期、每天、每周、每月等多种备份频率',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          color: Colors.grey,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => _showBackupTimePicker(context),
                            icon: const Icon(Icons.access_time),
                            label: const Text('配置备份计划'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.grey,
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
