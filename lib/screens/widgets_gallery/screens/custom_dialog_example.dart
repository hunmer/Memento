import 'package:flutter/material.dart';

/// 自定义对话框示例
class CustomDialogExample extends StatelessWidget {
  const CustomDialogExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('自定义对话框示例'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'CustomDialog',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            const Text('Flutter 的 AlertDialog 和 SimpleDialogDialog 组件。'),
            const SizedBox(height: 32),
            _buildDialogButton(
              context,
              title: '基础对话框',
              onPressed: () => _showBasicDialog(context),
            ),
            const SizedBox(height: 16),
            _buildDialogButton(
              context,
              title: '确认对话框',
              onPressed: () => _showConfirmDialog(context),
            ),
            const SizedBox(height: 16),
            _buildDialogButton(
              context,
              title: '输入对话框',
              onPressed: () => _showInputDialog(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogButton(
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

  void _showBasicDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('基础对话框'),
        content: const Text('这是一个基础的对话框示例。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  void _showConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认操作'),
        content: const Text('您确定要执行此操作吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showInputDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('输入内容'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: '请输入内容',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('输入内容: ${controller.text}')),
              );
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}
