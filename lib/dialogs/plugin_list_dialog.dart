import 'package:flutter/material.dart';
import '../core/plugin_manager.dart';

class PluginListDialog extends StatelessWidget {
  const PluginListDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '插件列表',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: PluginManager.instance.allPlugins.map((plugin) {
                    return ListTile(
                      title: Text(plugin.name),
                      subtitle: Text(plugin.description),
                      onTap: () {
                        // 关闭对话框
                        Navigator.of(context).pop();
                        // 打开插件界面
                        PluginManager.instance.openPlugin(context, plugin);
                      },
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('关闭'),
            ),
          ],
        ),
      ),
    );
  }
}

/// 显示插件列表对话框
void showPluginListDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => const PluginListDialog(),
  );
}