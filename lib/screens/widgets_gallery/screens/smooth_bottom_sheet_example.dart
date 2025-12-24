import 'package:flutter/material.dart';

/// 平滑底部弹窗示例
class SmoothBottomSheetExample extends StatelessWidget {
  const SmoothBottomSheetExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('平滑底部弹窗'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SmoothBottomSheet',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            const Text('这是一个平滑的底部弹窗组件。'),
            const SizedBox(height: 24),
            Text(
              '功能特性',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text('• 平滑动画'),
            const Text('• 自定义内容'),
            const Text('• 手势关闭'),
            const SizedBox(height: 32),
            _buildSheetButton(
              context,
              title: '基础弹窗',
              onPressed: () => _showBasicSheet(context),
            ),
            const SizedBox(height: 16),
            _buildSheetButton(
              context,
              title: '列表弹窗',
              onPressed: () => _showListSheet(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSheetButton(
    BuildContext context, {
    required String title,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        child: Text(title),
      ),
    );
  }

  void _showBasicSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => const Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, size: 64, color: Colors.green),
            SizedBox(height: 16),
            Text('操作成功', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('这是一个基础的底部弹窗示例'),
          ],
        ),
      ),
    );
  }

  void _showListSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('从相册选择'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text('拍照'),
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}
