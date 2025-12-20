import 'package:Memento/core/services/backup_service.dart';
import 'package:Memento/core/theme_controller.dart';

import 'package:flutter/material.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
import 'package:Memento/widgets/super_cupertino_navigation_wrapper.dart';
import './controllers/settings_screen_controller.dart';
import './widgets/webdav_settings_dialog.dart';
import './widgets/server_sync_settings_section.dart';
import './controllers/webdav_controller.dart';
import 'package:Memento/core/floating_ball/settings_screen.dart';
import 'package:Memento/core/floating_ball/floating_ball_manager.dart';
import 'package:Memento/screens/settings_screen/screens/data_management_screen.dart';
import 'package:Memento/screens/about_screen/about_screen.dart';
import 'package:Memento/screens/settings_screen/models/server_sync_config.dart';
import 'package:Memento/screens/settings_screen/controllers/permission_controller.dart';
import 'package:Memento/screens/settings_screen/widgets/permission_request_dialog.dart';
import 'package:get/get.dart';
import 'package:universal_platform/universal_platform.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late SettingsScreenController _controller;
  late WebDAVController _webdavController;
  bool _isWebDAVConnected = false;
  bool _isServerSyncLoggedIn = false;

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
    // 检查服务器同步配置
    _checkServerSyncConfig();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 异步初始化控制器
    _initializeAsync();
  }

  Future<void> _initializeAsync() async {
    await _controller.initializeControllers(context);
    _backupService = BackupService(_controller, context);
    if (mounted) {
      setState(() {});
    }
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

  // 检查服务器同步配置
  Future<void> _checkServerSyncConfig() async {
    final config = await ServerSyncConfig.load();
    if (mounted) {
      setState(() {
        _isServerSyncLoggedIn = config.isLoggedIn;
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

  // 显示服务器同步设置对话框
  Future<void> _showServerSyncSettings() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.9,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            expand: false,
            builder:
                (context, scrollController) => SingleChildScrollView(
                  controller: scrollController,
                  child: Padding(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewInsets.bottom,
                    ),
                    child: const ServerSyncSettingsSection(),
                  ),
                ),
          ),
    );

    // 重新检查服务器同步状态
    await _checkServerSyncConfig();
  }

  // 显示定位 API Key 设置对话框
  Future<void> _showLocationApiKeyDialog() async {
    final TextEditingController apiKeyController = TextEditingController(
      text: _controller.locationApiKey,
    );

    final result = await showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('screens_setLocationApiKey'.tr),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'screens_locationApiKeyHint'.tr,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: apiKeyController,
                  decoration: InputDecoration(
                    labelText: 'screens_apiKeyLabel'.tr,
                    hintText: 'screens_apiKeyInputHint'.tr,
                    border: const OutlineInputBorder(),
                  ),
                  maxLines: 1,
                ),
                const SizedBox(height: 12),
                Text(
                  'screens_locationApiKeyGuide'.tr,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('screens_cancel'.tr),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(apiKeyController.text);
                },
                child: Text('app_save'.tr),
              ),
            ],
          ),
    );

    if (result != null && result.isNotEmpty) {
      await _controller.setLocationApiKey(result);
      if (mounted) {
        setState(() {});
      }
    }

    apiKeyController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool showPermissionEntry =
        UniversalPlatform.isAndroid || UniversalPlatform.isIOS;
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
              onChanged: (value) => _controller.setTheme(context, value),
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
          ListTile(
            leading: const Icon(Icons.sync),
            title: Text('settings_screen_serverSyncTitle'.tr),
            subtitle: Text(
              _isServerSyncLoggedIn
                  ? 'settings_screen_serverSyncConnected'.tr
                  : 'settings_screen_serverSyncDisconnected'.tr,
            ),
            trailing:
                _isServerSyncLoggedIn
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : null,
            onTap: () {
              if (mounted) {
                _showServerSyncSettings();
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
            leading: const Icon(Icons.location_on),
            title: Text('screens_locationApiKey'.tr),
            subtitle: Text(
              _controller.locationApiKey.isEmpty
                ? 'screens_locationApiKeyNotSet'.tr
                : 'screens_locationApiKeyPartial'.trParams({'key': _controller.locationApiKey.substring(0, 8)}),
            ),
            trailing: const Icon(Icons.edit),
            onTap: () => _showLocationApiKeyDialog(),
          ),
          if (showPermissionEntry)
            ListTile(
              leading: const Icon(Icons.privacy_tip),
              title: Text('app_permissionsTitle'.tr),
              subtitle: Text('app_permissionsManageDescription'.tr),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () async {
                await showPermissionRequestDialog(
                  context: context,
                  controller: PermissionController(),
                  barrierDismissible: true,
                  showSkipButton: false,
                );
              },
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
            leading: const Icon(Icons.account_tree),
            title: const Text('数据选择器测试'),
            subtitle: const Text('测试插件数据选择器系统'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.pushNamed(context, '/data_selector_test');
            },
          ),
          ListTile(
            leading: const Icon(Icons.widgets),
            title: Text('screens_jsonDynamicWidgetTest'.tr),
            subtitle: Text('screens_testAndPreviewDynamicUI'.tr),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.pushNamed(context, '/json_dynamic_test');
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
            title: Text('app_aboutTitle'.tr),
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
