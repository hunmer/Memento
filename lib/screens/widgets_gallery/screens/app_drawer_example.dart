import 'package:flutter/material.dart';
import 'package:Memento/widgets/app_drawer.dart';

/// 应用抽屉示例
class AppDrawerExample extends StatelessWidget {
  const AppDrawerExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('应用抽屉'),
      ),
      drawer: const AppDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'AppDrawer',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            const Text('这是一个应用抽屉组件，点击左上角菜单图标打开。'),
            const SizedBox(height: 32),
            const Center(
              child: Icon(Icons.menu_open, size: 64, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            const Center(
              child: Text('点击左上角菜单图标查看抽屉效果'),
            ),
          ],
        ),
      ),
    );
  }
}
