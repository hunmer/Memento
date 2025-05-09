import 'package:Memento/core/event/event_manager.dart';
import 'package:flutter/material.dart';
import './controllers/settings_screen_controller.dart';
import './widgets/webdav_settings_dialog.dart';
import './controllers/webdav_controller.dart';
import '../../core/floating_ball/settings_screen.dart';
import '../../core/floating_ball/floating_ball_manager.dart';
import '../../widgets/backup_time_picker.dart';

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
    _controller = SettingsScreenController(context);
    _webdavController = WebDAVController(context);
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
    // 在这里初始化主题，这是安全的，因为此时 BuildContext 已经准备好了
    _controller.initTheme();
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

  Future<void> _showBackupScheduleDialog() async {
    await showDialog(
      context: context,
      builder: (context) => BackupTimePicker(
        initialSchedule: _controller.backupSchedule, // 传入当前备份计划
        onScheduleSelected: (schedule) {
          // 保存备份计划
          _controller.setBackupSchedule(schedule);
          // 检查是否需要立即备份
          _checkAndTriggerBackup();
        },
      ),
    );
  }

  Future<void> _checkAndTriggerBackup() async {
    final shouldBackup = await _controller.shouldPerformBackup();
    if (shouldBackup && mounted) {
      _showBackupOptionsDialog();
    }
  }

  Future<void> _showBackupOptionsDialog() async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('备份选项'),
        content: const Text('请选择备份方式'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'export'),
            child: const Text('导出应用数据'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'full'),
            child: const Text('完整备份'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'webdav'),
            child: const Text('WebDAV同步'),
          ),
        ],
      ),
    );

    if (result != null && mounted) {
      switch (result) {
        case 'export':
          _controller.exportData();
          break;
        case 'full':
          _controller.exportAllData();
          break;
        case 'webdav':
          _showWebDAVSettings();
          break;
      }
      // 重置备份检测日期
      _controller.resetBackupCheckDate();
    }
  }

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
            onTap: _controller.exportData,
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
            onTap: _showWebDAVSettings,
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
            onTap: _showBackupScheduleDialog,
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
        ],
      ),
    );
  }
}
