
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/screens/settings_screen/controllers/webdav_controller.dart';
import 'package:Memento/core/storage/storage_manager.dart';
import '../../../../core/services/toast_service.dart';

class WebDAVSettingsDialog extends StatefulWidget {
  final WebDAVController controller;
  final Map<String, dynamic>? initialConfig;

  const WebDAVSettingsDialog({
    super.key,
    required this.controller,
    this.initialConfig,
  });

  @override
  State<WebDAVSettingsDialog> createState() => _WebDAVSettingsDialogState();
}

class _WebDAVSettingsDialogState extends State<WebDAVSettingsDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _urlController;
  late TextEditingController _usernameController;
  late TextEditingController _passwordController;
  late TextEditingController _dataPathController;

  bool _isConnecting = false;
  bool _isConnected = false;
  bool _autoSync = false;
  String _statusMessage = '';

  @override
  void initState() {
    super.initState();

    // 初始化控制器，设置默认值
    _urlController = TextEditingController(
      text: widget.initialConfig?['url'] ?? 'http://127.0.0.1:8080',
    );
    _usernameController = TextEditingController(
      text: widget.initialConfig?['username'] ?? 'admin',
    );
    _passwordController = TextEditingController(
      text: widget.initialConfig?['password'] ?? '123456',
    );
    _dataPathController = TextEditingController(
      text: widget.initialConfig?['dataPath'] ?? '/app_data',
    );

    _isConnected = widget.initialConfig?['enabled'] == true;
    _autoSync = widget.initialConfig?['autoSync'] == true;

    // 如果已连接且开启了自动同步，启动文件监控
    if (_isConnected && _autoSync) {
      widget.controller.startFileMonitoring();
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _dataPathController.dispose();
    super.dispose();
  }

  // 测试连接
  Future<void> _testConnection() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isConnecting = true;
      _statusMessage = 'webdav_connectingStatus'.tr;
    });

    try {
      final success = await widget.controller.connect(
        url: _urlController.text,
        username: _usernameController.text,
        password: _passwordController.text,
        dataPath: _dataPathController.text,
      );

      setState(() {
        _isConnecting = false;
        _isConnected = success;
        _statusMessage =
            success
                ? 'webdav_connectionSuccessStatus'.tr
                : 'webdav_connectionFailedStatus'.tr;
      });
    } catch (e) {
      setState(() {
        _isConnecting = false;
        _isConnected = false;
        _statusMessage =
            'webdav_connectionErrorStatus'.tr +
            e.toString();
      });
    }
  }

  // 断开连接
  Future<void> _disconnect() async {
    setState(() {
      _isConnecting = true;
      _statusMessage = 'webdav_disconnectingStatus'.tr;
    });

    // 停止文件监控
    await widget.controller.stopFileMonitoring();
    await widget.controller.disconnect();

    // 更新配置，禁用 WebDAV 和自动同步
    final storageManager = StorageManager();
    await storageManager.initialize();
    await storageManager.saveWebDAVConfig(
      url: _urlController.text,
      username: _usernameController.text,
      password: _passwordController.text,
      dataPath: _dataPathController.text,
      enabled: false,
      autoSync: false,
    );

    setState(() {
      _isConnecting = false;
      _isConnected = false;
      _autoSync = false;
      _statusMessage = 'webdav_disconnectedStatus'.tr;
    });
  }

  // 将本地数据同步到WebDAV
  Future<void> _syncLocalToWebDAV() async {
    setState(() {
      _statusMessage = 'webdav_uploadingStatus'.tr;
      _isConnecting = true;
    });

    final success = await widget.controller.syncLocalToWebDAV(context);

    setState(() {
      _isConnecting = false;
      _statusMessage =
          success
              ? 'webdav_uploadSuccessStatus'.tr
              : 'webdav_uploadFailedStatus'.tr;
    });
  }

  // 将WebDAV数据同步到本地
  Future<void> _syncWebDAVToLocal() async {
    setState(() {
      _statusMessage = 'webdav_downloadingStatus'.tr;
      _isConnecting = true;
    });

    final success = await widget.controller.syncWebDAVToLocal(context);

    setState(() {
      _isConnecting = false;
      _statusMessage =
          success
              ? 'webdav_downloadSuccessStatus'.tr
              : 'webdav_downloadFailedStatus'.tr;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('webdav_title'.tr),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _urlController,
                decoration: InputDecoration(
                  labelText: 'webdav_serverAddress'.tr,
                  hintText: 'webdav_serverAddressHint'.tr,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'webdav_serverAddressEmptyError'.tr;
                  }
                  if (!value.startsWith('http://') &&
                      !value.startsWith('https://')) {
                    return 'webdav_serverAddressInvalidError'.tr;
                  }
                  return null;
                },
                enabled: !_isConnected,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: 'webdav_username'.tr,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'webdav_usernameEmptyError'.tr;
                  }
                  return null;
                },
                enabled: !_isConnected,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'webdav_password'.tr,
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'webdav_passwordEmptyError'.tr;
                  }
                  return null;
                },
                enabled: !_isConnected,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _dataPathController,
                decoration: InputDecoration(
                  labelText: 'webdav_rootPath'.tr,
                  hintText: 'webdav_rootPathHint'.tr,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'webdav_rootPathEmptyError'.tr;
                  }
                  if (!value.startsWith('/')) {
                    return 'webdav_rootPathInvalidError'.tr;
                  }
                  return null;
                },
                enabled: !_isConnected,
              ),
              const SizedBox(height: 16),
              if (_isConnected)
                SwitchListTile(
                  title: Text('webdav_enableAutoSync'.tr),
                  subtitle: Text(
                    'webdav_syncIntervalHint'.tr,
                  ),
                  value: _autoSync,
                  onChanged: (bool value) {
                    setState(() {
                      _autoSync = value;
                      _statusMessage =
                          value
                              ? 'webdav_autoSyncEnabledStatus'.tr
                              : 'webdav_autoSyncDisabledStatus'.tr;
                    });
                  },
                ),
              const SizedBox(height: 8),
              if (_statusMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    _statusMessage,
                    style: TextStyle(
                      color: _isConnected ? Colors.green : Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              if (_isConnecting)
                const Center(child: CircularProgressIndicator()),
            ],
          ),
        ),
      ),
      actions: [
        if (!_isConnected)
          TextButton(
            onPressed: _isConnecting ? null : _testConnection,
            child: Text('webdav_testConnection'.tr),
          )
        else ...[
          TextButton(
            onPressed: _isConnecting ? null : _disconnect,
            child: Text('webdav_disconnect'.tr),
          ),
          TextButton(
            onPressed: _isConnecting ? null : _syncWebDAVToLocal,
            child: Text('webdav_downloadAllData'.tr),
          ),
          TextButton(
            onPressed: _isConnecting ? null : _syncLocalToWebDAV,
            child: Text('webdav_uploadAllData'.tr),
          ),
          TextButton(
            onPressed: () async {
              // 在异步操作前获取context的引用
              final currentContext = context;

              // 保存当前配置，包括自动同步状态
              final storageManager = StorageManager();
              await storageManager.initialize();
              await storageManager.saveWebDAVConfig(
                url: _urlController.text,
                username: _usernameController.text,
                password: _passwordController.text,
                dataPath: _dataPathController.text,
                enabled: _isConnected,
                autoSync: _autoSync,
              );

              // 完成时根据自动同步设置决定是否启动文件监控
              if (_isConnected && _autoSync) {
                await widget.controller.startFileMonitoring();
              } else {
                await widget.controller.stopFileMonitoring();
              }

              // 使用mounted检查和保存的context引用
              if (!mounted) return;
              Navigator.of(currentContext).pop(true);

              // 显示提示
              toastService.showToast('webdav_settingsSavedMessage'.tr);
            },
            child: Text('app_done'.tr),
          ),
        ],
      ],
    );
  }
}
