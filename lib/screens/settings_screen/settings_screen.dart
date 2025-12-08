import 'package:Memento/core/services/backup_service.dart';
import 'package:Memento/core/theme_controller.dart';
import 'package:Memento/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
import 'package:Memento/widgets/super_cupertino_navigation_wrapper.dart';
import './controllers/settings_screen_controller.dart';
import './widgets/webdav_settings_dialog.dart';
import './controllers/webdav_controller.dart';
import 'package:Memento/core/floating_ball/settings_screen.dart';
import 'package:Memento/core/floating_ball/floating_ball_manager.dart';
import 'package:Memento/screens/settings_screen/screens/data_management_screen.dart';
import 'package:Memento/screens/about_screen/about_screen.dart';
import './l10n/settings_screen_localizations.dart';

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
    _controller.initializeControllers(context);
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

    return SuperCupertinoNavigationWrapper(
      title: Text(
        SettingsScreenLocalizations.of(context).settingsTitle,
        style: TextStyle(color: Theme.of(context).textTheme.titleLarge?.color),
      ),
      largeTitle: '设置',
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // 界面设置
          Text(
            '界面设置',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(SettingsScreenLocalizations.of(context).languageTitle),
            subtitle: Text(
              SettingsScreenLocalizations.of(context).languageSubtitle,
            ),
            onTap: () => _controller.toggleLanguage(context),
          ),
          ListTile(
            leading: const Icon(Icons.brightness_4),
            title: Text(SettingsScreenLocalizations.of(context).darkModeTitle),
            subtitle: Text(
              SettingsScreenLocalizations.of(context).darkModeSubtitle,
            ),
            trailing: Switch(
              value: ThemeController.isDarkTheme(context),
              onChanged: (value) => _controller.toggleTheme(context),
            ),
          ),
          const Divider(),

          // 数据管理
          Text(
            '数据管理',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.upload),
            title: Text(
              SettingsScreenLocalizations.of(context).exportDataTitle,
            ),
            subtitle: Text(
              SettingsScreenLocalizations.of(context).exportDataSubtitle,
            ),
            onTap: () {
              if (mounted) {
                _controller.exportData(context);
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.storage),
            title: Text(
              SettingsScreenLocalizations.of(context).dataManagementTitle,
            ),
            subtitle: Text(
              SettingsScreenLocalizations.of(context).dataManagementSubtitle,
            ),
            onTap: () {
              NavigationHelper.push(context, DataManagementScreen());
            },
          ),
          ListTile(
            leading: const Icon(Icons.download),
            title: Text(
              SettingsScreenLocalizations.of(context).importDataTitle,
            ),
            subtitle: Text(
              SettingsScreenLocalizations.of(context).importDataSubtitle,
            ),
            onTap: _controller.importData,
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.backup),
            title: Text(
              SettingsScreenLocalizations.of(context).fullBackupTitle,
            ),
            subtitle: Text(
              SettingsScreenLocalizations.of(context).fullBackupSubtitle,
            ),
            onTap: _controller.exportAllData,
          ),
          ListTile(
            leading: const Icon(Icons.restore),
            title: Text(
              SettingsScreenLocalizations.of(context).fullRestoreTitle,
            ),
            subtitle: Text(
              SettingsScreenLocalizations.of(context).fullRestoreSubtitle,
            ),
            onTap: _controller.importAllData,
            trailing: const Icon(Icons.warning, color: Colors.orange),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.cloud),
            title: Text(SettingsScreenLocalizations.of(context).webDAVTitle),
            subtitle: Text(
              _isWebDAVConnected
                  ? SettingsScreenLocalizations.of(context).webDAVConnected
                  : SettingsScreenLocalizations.of(context).webDAVDisconnected,
            ),
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

          // 应用设置
          Text(
            '应用设置',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          FutureBuilder<bool>(
            future: FloatingBallManager().isEnabled(),
            builder: (context, snapshot) {
              final bool isEnabled = snapshot.data ?? true;
              return ListTile(
                leading: const Icon(Icons.touch_app),
                title: Text(
                  SettingsScreenLocalizations.of(context).floatingBallTitle,
                ),
                subtitle: Text(
                  isEnabled
                      ? SettingsScreenLocalizations.of(
                        context,
                      ).floatingBallEnabled
                      : SettingsScreenLocalizations.of(
                        context,
                      ).floatingBallDisabled,
                ),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  NavigationHelper.push(
                    context,
                    const FloatingBallSettingsScreen(),
                  );
                },
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.schedule),
            title: Text(
              SettingsScreenLocalizations.of(context).autoBackupTitle,
            ),
            subtitle: Text(
              SettingsScreenLocalizations.of(context).autoBackupSubtitle,
            ),
            onTap: _backupService.showBackupScheduleDialog,
          ),
          ListTile(
            leading: const Icon(Icons.play_circle),
            title: Text(
              SettingsScreenLocalizations.of(context).autoOpenLastPluginTitle,
            ),
            subtitle: Text(
              SettingsScreenLocalizations.of(
                context,
              ).autoOpenLastPluginSubtitle,
            ),
            trailing: Switch(
              value: _controller.autoOpenLastPlugin,
              onChanged:
                  (value) => setState(() {
                    _controller.autoOpenLastPlugin = value;
                  }),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.system_update),
            title: Text(
              SettingsScreenLocalizations.of(context).autoCheckUpdateTitle,
            ),
            subtitle: Text(
              SettingsScreenLocalizations.of(context).autoCheckUpdateSubtitle,
            ),
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
            title: Text(
              SettingsScreenLocalizations.of(context).checkUpdateTitle,
            ),
            subtitle: Text(
              SettingsScreenLocalizations.of(context).checkUpdateSubtitle,
            ),
            onTap: _controller.checkForUpdates,
          ),
          const Divider(),

          // 开发者测试
          Text(
            '开发者测试',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.code),
            title: const Text('JS Console'),
            subtitle: const Text('测试 JavaScript API 功能'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.pushNamed(context, '/js_console');
            },
          ),
          ListTile(
            leading: const Icon(Icons.widgets),
            title: const Text('JSON Dynamic Widget 测试'),
            subtitle: const Text('测试和预览动态 UI 组件'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.pushNamed(context, '/json_dynamic_test');
            },
          ),
          ListTile(
            leading: const Icon(Icons.navigation),
            title: const Text('Super Cupertino Navigation 测试'),
            subtitle: const Text('测试 iOS 风格导航栏组件'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.pushNamed(context, '/super_cupertino_test');
            },
          ),
          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('通知测试'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.pushNamed(context, '/notification_test');
            },
          ),
          ListTile(
            leading: const Icon(Icons.touch_app),
            title: const Text('悬浮球设置'),
            subtitle: const Text('管理系统级悬浮球功能'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.pushNamed(context, '/floating_ball');
            },
          ),
          ListTile(
            leading: const Icon(Icons.link),
            title: const Text('Intent 测试'),
            subtitle: const Text('测试动态 Intent 注册和深度链接'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.pushNamed(context, '/intent_test');
            },
          ),
          const Divider(),

          // 关于
          Text(
            '关于',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.info),
            title: Text(AppLocalizations.of(context)!.aboutTitle),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              NavigationHelper.push(context, const AboutScreen());
            },
          ),
        ],
      ),
    );
  }
}
