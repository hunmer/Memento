import 'package:flutter/material.dart';

/// Super Cupertino 导航包装示例
class SuperCupertinoNavigationExample extends StatelessWidget {
  const SuperCupertinoNavigationExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Super Cupertino 导航包装'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SuperCupertinoNavigationWrapper',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            const Text('这是一个超级 Cupertino 导航包装组件，提供类似 iOS 的导航体验。'),
            const SizedBox(height: 24),
            Text(
              '功能特性',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text('• iOS 风格导航'),
            const Text('• 平滑过渡动画'),
            const Text('• 手势支持'),
          ],
        ),
      ),
    );
  }
}
