import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../models/proxy_settings.dart';
import '../webview_plugin.dart';

/// Proxy 代理设置界面（Android 专用）
class ProxySettingsScreen extends StatefulWidget {
  const ProxySettingsScreen({super.key});

  @override
  State<ProxySettingsScreen> createState() => _ProxySettingsScreenState();
}

class _ProxySettingsScreenState extends State<ProxySettingsScreen> {
  late ProxySettings _proxySettings;
  late bool _enabled;
  late List<ProxyRule> _proxyRules;
  late List<String> _bypassRules;
  late bool _reverseBypass;

  @override
  void initState() {
    super.initState();
    _proxySettings = WebViewPlugin.instance.webviewSettings.proxySettings;
    _enabled = _proxySettings.enabled;
    _proxyRules = List.from(_proxySettings.proxyRules);
    _bypassRules = List.from(_proxySettings.bypassRules);
    _reverseBypass = _proxySettings.reverseBypassEnabled;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('webview_proxy_settings'.tr),
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
          // 平台提示
          Card(
            color: Colors.amber.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.amber.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'webview_proxy_android_only'.tr,
                      style: TextStyle(color: Colors.amber.shade900),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 启用开关
          SwitchListTile(
            title: Text('webview_proxy_enable'.tr),
            subtitle: Text('webview_proxy_enable_desc'.tr),
            value: _enabled,
            onChanged: (value) {
              setState(() {
                _enabled = value;
              });
            },
          ),

          const Divider(height: 32),

          // Proxy 规则列表
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'webview_proxy_rules'.tr,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: _enabled ? _addProxyRule : null,
                tooltip: 'webview_proxy_add_rule'.tr,
              ),
            ],
          ),

          if (_proxyRules.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'webview_proxy_no_rules'.tr,
                style: TextStyle(color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
            )
          else
            ..._proxyRules.asMap().entries.map((entry) {
              final index = entry.key;
              final rule = entry.value;
              return Card(
                child: ListTile(
                  title: Text(rule.url),
                  subtitle: _buildRuleSubtitle(rule),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed:
                            _enabled ? () => _editProxyRule(index, rule) : null,
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: _enabled
                            ? () => setState(() {
                                  _proxyRules.removeAt(index);
                                })
                            : null,
                      ),
                    ],
                  ),
                ),
              );
            }),

          const SizedBox(height: 16),
          const Divider(height: 32),

          // 绕过规则
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'webview_proxy_bypass_rules'.tr,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: _enabled ? _addBypassRule : null,
                tooltip: 'webview_proxy_add_bypass_rule'.tr,
              ),
            ],
          ),

          if (_bypassRules.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'webview_proxy_no_bypass_rules'.tr,
                style: TextStyle(color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
            )
          else
            ..._bypassRules.asMap().entries.map((entry) {
              final index = entry.key;
              final rule = entry.value;
              return Card(
                child: ListTile(
                  title: Text(rule),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: _enabled
                        ? () => setState(() {
                              _bypassRules.removeAt(index);
                            })
                        : null,
                  ),
                ),
              );
            }),

          const SizedBox(height: 16),

          // 反转绕过规则
          SwitchListTile(
            title: Text('webview_proxy_reverse_bypass'.tr),
            subtitle: Text('webview_proxy_reverse_bypass_desc'.tr),
            value: _reverseBypass,
            onChanged:
                _enabled
                    ? (value) {
                      setState(() {
                        _reverseBypass = value;
                      });
                    }
                    : null,
          ),
        ],
      ),
    );
  }

  Widget? _buildRuleSubtitle(ProxyRule rule) {
    final filters = <String>[];
    if (rule.schemeFilter != null) filters.add('scheme=${rule.schemeFilter}');
    if (rule.hostFilter != null) filters.add('host=${rule.hostFilter}');
    if (rule.portFilter != null) filters.add('port=${rule.portFilter}');
    if (rule.pathFilter != null) filters.add('path=${rule.pathFilter}');

    if (filters.isEmpty) return null;
    return Text(filters.join(', '));
  }

  void _addProxyRule() {
    _showProxyRuleDialog();
  }

  void _editProxyRule(int index, ProxyRule rule) {
    _showProxyRuleDialog(index: index, rule: rule);
  }

  void _showProxyRuleDialog({int? index, ProxyRule? rule}) {
    final urlController = TextEditingController(text: rule?.url ?? '');
    final schemeController = TextEditingController(text: rule?.schemeFilter ?? '');
    final hostController = TextEditingController(text: rule?.hostFilter ?? '');
    final portController = TextEditingController(
      text: rule?.portFilter?.toString() ?? '',
    );
    final pathController = TextEditingController(text: rule?.pathFilter ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title:
            Text(
              index == null
                  ? 'webview_proxy_add_rule'.tr
                  : 'webview_proxy_edit_rule'.tr,
            ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: urlController,
                decoration: InputDecoration(
                  labelText: 'webview_proxy_url'.tr,
                  hintText: 'http://proxy.example.com:8080',
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              ExpansionTile(
                title: Text('webview_proxy_filters'.tr),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'webview_proxy_filters_optional'.tr,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      'webview_proxy_filters_note'.tr,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.orange.shade700,
                            fontStyle: FontStyle.italic,
                          ),
                    ),
                  ],
                ),
                children: [
                  const SizedBox(height: 8),
                  TextField(
                    controller: schemeController,
                    decoration: InputDecoration(
                      labelText: 'webview_proxy_scheme_filter'.tr,
                      hintText: 'http / https',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: hostController,
                    decoration: InputDecoration(
                      labelText: 'webview_proxy_host_filter'.tr,
                      hintText: 'example.com',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: portController,
                    decoration: InputDecoration(
                      labelText: 'webview_proxy_port_filter'.tr,
                      hintText: '8080',
                      border: const OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: pathController,
                    decoration: InputDecoration(
                      labelText: 'webview_proxy_path_filter'.tr,
                      hintText: '/api/*',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          ),
          ElevatedButton(
            onPressed: () {
              if (urlController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('webview_proxy_url_required'.tr)),
                );
                return;
              }

              final newRule = ProxyRule(
                url: urlController.text.trim(),
                schemeFilter:
                    schemeController.text.trim().isNotEmpty
                        ? schemeController.text.trim()
                        : null,
                hostFilter:
                    hostController.text.trim().isNotEmpty
                        ? hostController.text.trim()
                        : null,
                portFilter:
                    portController.text.trim().isNotEmpty
                        ? int.tryParse(portController.text.trim())
                        : null,
                pathFilter:
                    pathController.text.trim().isNotEmpty
                        ? pathController.text.trim()
                        : null,
              );

              setState(() {
                if (index == null) {
                  _proxyRules.add(newRule);
                } else {
                  _proxyRules[index] = newRule;
                }
              });

              Navigator.pop(context);
            },
            child: Text(MaterialLocalizations.of(context).saveButtonLabel),
          ),
        ],
      ),
    );
  }

  void _addBypassRule() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('webview_proxy_add_bypass_rule'.tr),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: 'webview_proxy_bypass_pattern'.tr,
            hintText: 'example.com, *.excluded.com',
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                setState(() {
                  _bypassRules.add(controller.text.trim());
                });
                Navigator.pop(context);
              }
            },
            child: Text(MaterialLocalizations.of(context).saveButtonLabel),
          ),
        ],
      ),
    );
  }

  Future<void> _saveSettings() async {
    final newProxySettings = ProxySettings(
      enabled: _enabled,
      proxyRules: _proxyRules,
      bypassRules: _bypassRules,
      reverseBypassEnabled: _reverseBypass,
    );

    final plugin = WebViewPlugin.instance;
    plugin.webviewSettings = plugin.webviewSettings.copyWith(
      proxySettings: newProxySettings,
    );

    await plugin.saveWebviewSettings();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('webview_proxy_settings_saved'.tr)),
      );
      Navigator.pop(context);
    }
  }
}
