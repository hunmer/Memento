import 'package:flutter/material.dart';
import 'package:Memento/widgets/import_dialog.dart';

/// 导入对话框示例
class ImportDialogExample extends StatelessWidget {
  const ImportDialogExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('导入对话框'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ImportDialog',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            const Text('这是一个数据导入对话框组件，支持选择插件数据导入。'),
            const SizedBox(height: 8),
            const Text('需要插件管理器和插件数据映射。'),
            const SizedBox(height: 32),
            Center(
              child: ElevatedButton.icon(
                onPressed: () => _showImportDialog(context),
                icon: const Icon(Icons.upload_file),
                label: const Text('打开导入对话框'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showImportDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) => ImportDialog(
        isMergeMode: true,
        pluginDataMap: const {},
      ),
    );
  }
}
