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
import '../l10n/screens_localizations.dart';
import 'package:get/get.dart';

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
        'settings_screen_settingsTitle'.tr,
        style: TextStyle(color: Theme.of(context).textTheme.titleLarge?.color),
      ),
      largeTitle: 'settings_screen_settingsTitle'.tr,
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
            title: Text('settings_screen_languageTitle'.tr),
            subtitle: Text('settings_screen_languageSubtitle'.tr),
            onTap: () => _controller.toggleLanguage(context),
          ),
          ListTile(
            leading: const Icon(Icons.brightness_4),
            title: Text('settings_screen_darkModeTitle'.tr),
            subtitle: Text('settings_screen_darkModeSubtitle'.tr),
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
            title: Text('settings_screen_exportDataTitle'.tr),
            subtitle: Text('settings_screen_exportDataSubtitle'.tr),
            onTap: () {
              if (mounted) {
                _controller.exportData(context);
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.storage),
            title: Text('settings_screen_dataManagementTitle'.tr),
            subtitle: Text('settings_screen_dataManagementSubtitle'.tr),
            onTap: () {
              NavigationHelper.push(context, DataManagementScreen());
            },
          ),
          ListTile(
            leading: const Icon(Icons.download),
            title: Text('settings_screen_importDataTitle'.tr),
            subtitle: Text('settings_screen_importDataSubtitle'.tr),
            onTap: _controller.importData,
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.backup),
            title: Text('settings_screen_fullBackupTitle'.tr),
            subtitle: Text('settings_screen_fullBackupSubtitle'.tr),
            onTap: _controller.exportAllData,
          ),
          ListTile(
            leading: const Icon(Icons.restore),
            title: Text('settings_screen_fullRestoreTitle'.tr),
            subtitle: Text('settings_screen_fullRestoreSubtitle'.tr),
            onTap: _controller.importAllData,
            trailing: const Icon(Icons.warning, color: Colors.orange),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.cloud),
            title: Text('settings_screen_webDAVTitle'.tr),
            subtitle: Text(
              _isWebDAVConnected
                  ? 'settings_screen_webDAVConnected'.tr
                  : 'settings_screen_webDAVDisconnected'.tr,
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
                title: Text('settings_screen_floatingBallTitle'.tr),
                subtitle: Text(
                  isEnabled
                      ? 'settings_screen_floatingBallEnabled'.tr
                      : 'settings_screen_floatingBallDisabled'.tr,
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
            title: Text('settings_screen_autoBackupTitle'.tr),
            subtitle: Text('settings_screen_autoBackupSubtitle'.tr),
            onTap: _backupService.showBackupScheduleDialog,
          ),
          ListTile(
            leading: const Icon(Icons.play_circle),
            title: Text('settings_screen_autoOpenLastPluginTitle'.tr),
            subtitle: Text('settings_screen_autoOpenLastPluginSubtitle'.tr),
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
            title: Text('settings_screen_autoCheckUpdateTitle'.tr),
            subtitle: Text('settings_screen_autoCheckUpdateSubtitle'.tr),
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
            title: Text('settings_screen_checkUpdateTitle'.tr),
            subtitle: Text('settings_screen_checkUpdateSubtitle'.tr),
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
            title: Text('screens_jsConsole'.tr),
            subtitle: Text('screens_testJavaScriptAPI'.tr),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.pushNamed(context, '/js_console');
            },
          ),
          ListTile(
            leading: const Icon(Icons.widgets),
            title: Text('screens_jsonDynamicWidgetTest'.tr),
            subtitle: Text(
              'screens_testAndPreviewDynamicUI'.tr,
            ),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.pushNamed(context, '/json_dynamic_test');
            },
          ),
          ListTile(
            leading: const Icon(Icons.navigation),
            title: Text(
              'screens_superCupertinoNavigationTest'.tr,
            ),
            subtitle: Text(
              'screens_testIOSStyleNavigation'.tr,
            ),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.pushNamed(context, '/super_cupertino_test');
            },
          ),
          ListTile(
            leading: const Icon(Icons.notifications),
            title: Text('screens_notificationTest'.tr),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.pushNamed(context, '/notification_test');
            },
          ),
          ListTile(
            leading: const Icon(Icons.touch_app),
            title: Text('screens_floatingBallSettings'.tr),
            subtitle: Text('screens_manageSystemFloatingBall'.tr),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.pushNamed(context, '/floating_ball');
            },
          ),
          ListTile(
            leading: const Icon(Icons.link),
            title: Text('screens_intentTest'.tr),
            subtitle: Text('screens_testDynamicIntentAndDeepLink'.tr),
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
