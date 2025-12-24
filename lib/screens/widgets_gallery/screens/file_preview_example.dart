import 'package:flutter/material.dart';

/// 文件预览示例
class FilePreviewExample extends StatelessWidget {
  const FilePreviewExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('文件预览'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'FilePreviewScreen',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            const Text('这是一个文件预览组件，支持多种文件类型。'),
            const SizedBox(height: 8),
            const Text('需要提供文件路径、文件名、MIME 类型和文件大小。'),
            const SizedBox(height: 32),
            _buildPreviewButton(
              context,
              title: '查看使用说明',
              icon: Icons.info,
              onPressed: () => _showUsageInfo(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewButton(
    BuildContext context, {
    required String title,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onPressed,
    );
  }

  void _showUsageInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('FilePreviewScreen 使用说明'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('必需参数:', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('• filePath: 文件路径'),
              Text('• fileName: 文件名称'),
              Text('• mimeType: 文件 MIME 类型'),
              Text('• fileSize: 文件大小（字节）'),
              SizedBox(height: 16),
              Text('使用示例:', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('''
FilePreviewScreen(
  filePath: 'app_data/images/photo.jpg',
  fileName: 'photo.jpg',
  mimeType: 'image/jpeg',
  fileSize: 1024000,
)'''),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }
}
