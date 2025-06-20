import 'package:Memento/core/services/backup_service.dart';
import 'package:Memento/screens/settings_screen/log_settings_screen.dart';
import 'package:Memento/test/test_foreground_task_screen.dart';
import 'package:flutter/material.dart';
import './controllers/settings_screen_controller.dart';
import './widgets/webdav_settings_dialog.dart';
import './controllers/webdav_controller.dart';
import '../../core/floating_ball/settings_screen.dart';
import '../../core/floating_ball/floating_ball_manager.dart';
import 'package:Memento/screens/settings_screen/screens/data_management_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late SettingsScreenController _controller;
  late WebDAVController _webdavController;
  bool _isWebDAVConnected = false;

  @override
  void initState() {
    super.initState();
    _controller = SettingsScreenController();
    _webdavController = WebDAVController();

    _controller.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });

    // 检查WebDAV配置
    _checkWebDAVConfig();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 在这里初始化控制器和主题，这是安全的，因为此时 BuildContext 已经准备好了
    _controller.initializeControllers(context);
    _controller.initTheme(context);
    _backupService = BackupService(_controller, context);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // 检查WebDAV配置
  Future<void> _checkWebDAVConfig() async {
    final config = await _webdavController.getWebDAVConfig();
    if (mounted) {
      setState(() {
        _isWebDAVConnected = config?['isConnected'] == true;
      });
    }
  }

  late BackupService _backupService;

  // 显示WebDAV设置对话框
  Future<void> _showWebDAVSettings() async {
    final config = await _webdavController.getWebDAVConfig();
    if (!mounted) return;

    final result = await showDialog<bool>(
      context: context,
      builder:
          (context) => WebDAVSettingsDialog(
            controller: _webdavController,
            initialConfig: config,
          ),
    );

    if (result == true) {
      // 重新检查WebDAV状态
      await _checkWebDAVConfig();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_controller.isInitialized() || _backupService == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(
              _controller.isChineseLocale ? '语言 (中文)' : 'Language (English)',
            ),
            subtitle: Text(
              _controller.isChineseLocale
                  ? '点击切换到英文'
                  : 'Tap to switch to Chinese',
            ),
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
            title: const Text('导出应用数据'),
            subtitle: const Text('将插件数据导出到文件'),
            onTap: () {
              if (mounted) {
                _controller.exportData(context);
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.storage),
            title: const Text('数据文件管理'),
            subtitle: const Text('管理应用数据目录中的文件'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => DataManagementScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.download),
            title: const Text('导入应用数据'),
            subtitle: const Text('从文件导入插件数据'),
            onTap: _controller.importData,
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.backup),
            title: const Text('完整备份'),
            subtitle: const Text('备份整个应用数据目录'),
            onTap: _controller.exportAllData,
          ),
          ListTile(
            leading: const Icon(Icons.restore),
            title: const Text('完整恢复'),
            subtitle: const Text('从备份恢复整个应用数据（覆盖现有数据）'),
            onTap: _controller.importAllData,
            trailing: const Icon(Icons.warning, color: Colors.orange),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.cloud),
            title: const Text('WebDAV 同步'),
            subtitle: Text(_isWebDAVConnected ? '已连接' : '未连接'),
            trailing:
                _isWebDAVConnected
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : null,
            onTap: () {
              if (mounted) {
                _showWebDAVSettings();
              }
            },
          ),
          const Divider(),
          FutureBuilder<bool>(
            future: FloatingBallManager().isEnabled(),
            builder: (context, snapshot) {
              final bool isEnabled = snapshot.data ?? true;
              return ListTile(
                leading: const Icon(Icons.touch_app),
                title: const Text('悬浮球设置'),
                subtitle: Text(isEnabled ? '已启用' : '已禁用'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const FloatingBallSettingsScreen(),
                    ),
                  );
                },
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.schedule),
            title: const Text('自动备份设置'),
            subtitle: const Text('设置自动备份计划'),
            onTap: _backupService.showBackupScheduleDialog,
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.play_circle),
            title: const Text('自动打开上次使用的插件'),
            subtitle: const Text('启动时自动打开最后使用的插件'),
            trailing: Switch(
              value: _controller.autoOpenLastPlugin,
              onChanged:
                  (value) => setState(() {
                    _controller.autoOpenLastPlugin = value;
                  }),
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.system_update),
            title: const Text('自动检查更新'),
            subtitle: const Text('定期检查应用新版本'),
            trailing: Switch(
              value: _controller.autoCheckUpdate,
              onChanged:
                  (value) => setState(() {
                    _controller.autoCheckUpdate = value;
                  }),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.update),
            title: const Text('检查更新'),
            subtitle: const Text('立即检查应用新版本'),
            onTap: _controller.checkForUpdates,
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.assignment),
            title: const Text('日志设置'),
            subtitle: const Text('配置日志记录选项'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const LogSettingsScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.update),
            title: const Text('测试前台服务'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TestForegroundTaskScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
