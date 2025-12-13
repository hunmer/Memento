import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../webview_plugin.dart';
import 'proxy_settings_screen.dart';

/// WebView 设置界面
class WebViewSettingsScreen extends StatefulWidget {
  const WebViewSettingsScreen({super.key});

  @override
  State<WebViewSettingsScreen> createState() => _WebViewSettingsScreenState();
}

class _WebViewSettingsScreenState extends State<WebViewSettingsScreen> {
  late bool _enableJavaScript;
  late bool _enableJSBridge;
  late bool _blockPopups;
  late bool _enableZoom;
  late bool _saveHistory;
  late bool _restoreTabsOnStartup;
  late bool _blockDeepLinks;
  late int _maxTabs;
  late String _userAgent;
  late String _defaultSearchEngine;
  late String _homePage;

  @override
  void initState() {
    super.initState();
    final settings = WebViewPlugin.instance.webviewSettings;
    _enableJavaScript = settings.enableJavaScript;
    _enableJSBridge = settings.enableJSBridge;
    _blockPopups = settings.blockPopups;
    _enableZoom = settings.enableZoom;
    _saveHistory = settings.saveHistory;
    _restoreTabsOnStartup = settings.restoreTabsOnStartup;
    _blockDeepLinks = settings.blockDeepLinks;
    _maxTabs = settings.maxTabs;
    _userAgent = settings.userAgent;
    _defaultSearchEngine = settings.defaultSearchEngine;
    _homePage = settings.homePage;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('webview_settings_title'.tr),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveSettings,
            tooltip: MaterialLocalizations.of(context).saveButtonLabel,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 基础设置
          Text(
            'webview_settings_basic'.tr,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),

          // JavaScript 开关
          SwitchListTile(
            title: Text('webview_settings_enable_js'.tr),
            subtitle: Text('webview_settings_enable_js_desc'.tr),
            value: _enableJavaScript,
            onChanged: (value) {
              setState(() {
                _enableJavaScript = value;
              });
            },
          ),

          // JS Bridge 开关
          SwitchListTile(
            title: Text('webview_settings_enable_jsbridge'.tr),
            subtitle: Text('webview_settings_enable_jsbridge_desc'.tr),
            value: _enableJSBridge,
            onChanged: (value) {
              setState(() {
                _enableJSBridge = value;
              });
            },
          ),

          // 缩放开关
          SwitchListTile(
            title: Text('webview_settings_enable_zoom'.tr),
            subtitle: Text('webview_settings_enable_zoom_desc'.tr),
            value: _enableZoom,
            onChanged: (value) {
              setState(() {
                _enableZoom = value;
              });
            },
          ),

          const Divider(height: 32),

          // 隐私与安全
          Text(
            'webview_settings_privacy'.tr,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),

          // 阻止弹窗
          SwitchListTile(
            title: Text('webview_settings_block_popups'.tr),
            subtitle: Text('webview_settings_block_popups_desc'.tr),
            value: _blockPopups,
            onChanged: (value) {
              setState(() {
                _blockPopups = value;
              });
            },
          ),

          // 阻止深度链接
          SwitchListTile(
            title: Text('webview_settings_block_deeplinks'.tr),
            subtitle: Text('webview_settings_block_deeplinks_desc'.tr),
            value: _blockDeepLinks,
            onChanged: (value) {
              setState(() {
                _blockDeepLinks = value;
              });
            },
          ),

          // 保存历史记录
          SwitchListTile(
            title: Text('webview_settings_save_history'.tr),
            subtitle: Text('webview_settings_save_history_desc'.tr),
            value: _saveHistory,
            onChanged: (value) {
              setState(() {
                _saveHistory = value;
              });
            },
          ),

          const Divider(height: 32),

          // 标签页管理
          Text(
            'webview_settings_tabs'.tr,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),

          // 恢复上次打开的标签页
          SwitchListTile(
            title: Text('webview_settings_restore_tabs'.tr),
            subtitle: Text('webview_settings_restore_tabs_desc'.tr),
            value: _restoreTabsOnStartup,
            onChanged: (value) {
              setState(() {
                _restoreTabsOnStartup = value;
              });
            },
          ),

          // 最大标签页数量
          ListTile(
            title: Text('webview_settings_max_tabs'.tr),
            subtitle: Text('webview_settings_max_tabs_desc'.tr),
            trailing: SizedBox(
              width: 100,
              child: TextField(
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                ),
                controller: TextEditingController(text: _maxTabs.toString())
                  ..selection = TextSelection.fromPosition(
                    TextPosition(offset: _maxTabs.toString().length),
                  ),
                onChanged: (value) {
                  final parsed = int.tryParse(value);
                  if (parsed != null && parsed > 0 && parsed <= 50) {
                    setState(() {
                      _maxTabs = parsed;
                    });
                  }
                },
              ),
            ),
          ),

          const Divider(height: 32),

          // 高级设置
          Text(
            'webview_settings_advanced'.tr,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),

          // 用户代理
          ListTile(
            title: Text('webview_settings_user_agent'.tr),
            subtitle: Text(_userAgent.isEmpty ? 'webview_settings_user_agent_default'.tr : _userAgent),
            trailing: const Icon(Icons.edit),
            onTap: () {
              _showEditDialog(
                title: 'webview_settings_user_agent'.tr,
                initialValue: _userAgent,
                onSave: (value) {
                  setState(() {
                    _userAgent = value;
                  });
                },
              );
            },
          ),

          // 默认搜索引擎
          ListTile(
            title: Text('webview_settings_search_engine'.tr),
            subtitle: Text(_defaultSearchEngine),
            trailing: const Icon(Icons.edit),
            onTap: () {
              _showEditDialog(
                title: 'webview_settings_search_engine'.tr,
                initialValue: _defaultSearchEngine,
                onSave: (value) {
                  setState(() {
                    _defaultSearchEngine = value;
                  });
                },
              );
            },
          ),

          // 主页
          ListTile(
            title: Text('webview_settings_homepage'.tr),
            subtitle: Text(_homePage),
            trailing: const Icon(Icons.edit),
            onTap: () {
              _showEditDialog(
                title: 'webview_settings_homepage'.tr,
                initialValue: _homePage,
                onSave: (value) {
                  setState(() {
                    _homePage = value;
                  });
                },
              );
            },
          ),

          const Divider(height: 32),

          // 代理设置
          ListTile(
            title: Text('webview_proxy_settings'.tr),
            subtitle: Text('webview_proxy_settings_desc'.tr),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProxySettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showEditDialog({
    required String title,
    required String initialValue,
    required Function(String) onSave,
  }) {
    final controller = TextEditingController(text: initialValue);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
          ),
          maxLines: 1,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          ),
          ElevatedButton(
            onPressed: () {
              onSave(controller.text.trim());
              Navigator.pop(context);
            },
            child: Text(MaterialLocalizations.of(context).saveButtonLabel),
          ),
        ],
      ),
    );
  }

  Future<void> _saveSettings() async {
    final plugin = WebViewPlugin.instance;
    plugin.webviewSettings = plugin.webviewSettings.copyWith(
      enableJavaScript: _enableJavaScript,
      enableJSBridge: _enableJSBridge,
      blockPopups: _blockPopups,
      enableZoom: _enableZoom,
      saveHistory: _saveHistory,
      restoreTabsOnStartup: _restoreTabsOnStartup,
      blockDeepLinks: _blockDeepLinks,
      maxTabs: _maxTabs,
      userAgent: _userAgent,
      defaultSearchEngine: _defaultSearchEngine,
      homePage: _homePage,
    );

    await plugin.saveWebviewSettings();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('webview_settings_saved'.tr)),
      );
      Navigator.pop(context);
    }
  }
}
