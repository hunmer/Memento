import 'package:flutter/material.dart';
import 'package:Memento/widgets/file_preview/file_preview_screen.dart';

/// 文件预览示例
class FilePreviewExample extends StatelessWidget {
  const FilePreviewExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('文件预览'),
      ),
      body: Container(
        color: isDark ? Colors.black : const Color(0xFFF2F2F7),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('文件预览组件'),
                const SizedBox(height: 8),
                const Text('点击下方按钮查看不同类型的文件预览效果'),
                const SizedBox(height: 24),
                _buildPreviewButton(
                  context,
                  title: '图片预览',
                  subtitle: '支持缩放和拖动',
                  icon: Icons.image,
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const FilePreviewScreen(
                        filePath: 'app_data/images/sample.jpg',
                        fileName: 'sample.jpg',
                        mimeType: 'image/jpeg',
                        fileSize: 1024000,
                      ),
                    ),
                  ),
                ),
                const Divider(height: 24),
                _buildPreviewButton(
                  context,
                  title: '视频预览',
                  subtitle: '支持视频播放',
                  icon: Icons.videocam,
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const FilePreviewScreen(
                        filePath: 'app_data/videos/sample.mp4',
                        fileName: 'sample.mp4',
                        mimeType: 'video/mp4',
                        fileSize: 5120000,
                        isVideo: true,
                      ),
                    ),
                  ),
                ),
                const Divider(height: 24),
                _buildPreviewButton(
                  context,
                  title: '普通文件预览',
                  subtitle: '显示文件信息',
                  icon: Icons.insert_drive_file,
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const FilePreviewScreen(
                        filePath: 'app_data/documents/report.pdf',
                        fileName: 'report.pdf',
                        mimeType: 'application/pdf',
                        fileSize: 2048000,
                      ),
                    ),
                  ),
                ),
              ],
            ),
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

  Widget _buildPreviewButton(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).primaryColor),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onPressed,
      ),
    );
  }
}
