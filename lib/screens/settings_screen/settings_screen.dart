import 'package:flutter/material.dart';
import './controllers/settings_screen_controller.dart';
import './widgets/plugin_selection_dialog.dart';
import './widgets/folder_selection_dialog.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late SettingsScreenController _controller;

  @override
  void initState() {
    super.initState();
    _controller = SettingsScreenController(context);
    _controller.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 在这里初始化主题，这是安全的，因为此时 BuildContext 已经准备好了
    _controller.initTheme();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(_controller.isChineseLocale ? '语言 (中文)' : 'Language (English)'),
            subtitle: Text(_controller.isChineseLocale ? '点击切换到英文' : 'Tap to switch to Chinese'),
            onTap: _controller.toggleLanguage,
          ),
          ListTile(
            leading: const Icon(Icons.brightness_4),
            title: const Text('深色模式'),
            subtitle: const Text('切换应用主题'),
            trailing: Switch(
              value: _controller.isDarkMode,
              onChanged: (value) => _controller.toggleTheme(),
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.upload),
            title: const Text('导出数据'),
            subtitle: const Text('将应用数据导出到文件'),
            onTap: _controller.exportData,
          ),
          ListTile(
            leading: const Icon(Icons.download),
            title: const Text('导入数据'),
            subtitle: const Text('从文件导入应用数据'),
            onTap: _controller.importData,
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('关于'),
            onTap: _controller.showAboutDialog,
          ),
        ],
      ),
    );
  }
}