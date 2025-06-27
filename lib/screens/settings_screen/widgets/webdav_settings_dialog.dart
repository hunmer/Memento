import 'package:Memento/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import '../controllers/webdav_controller.dart';
import '../../../core/storage/storage_manager.dart';
import 'l10n/webdav_localizations.dart';

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
      _statusMessage = WebDAVLocalizations.of(context).connectingStatus;
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
                ? WebDAVLocalizations.of(context).connectionSuccessStatus
                : WebDAVLocalizations.of(context).connectionFailedStatus;
      });
    } catch (e) {
      setState(() {
        _isConnecting = false;
        _isConnected = false;
        _statusMessage =
            WebDAVLocalizations.of(context).connectionErrorStatus +
            e.toString();
      });
    }
  }

  // 断开连接
  Future<void> _disconnect() async {
    setState(() {
      _isConnecting = true;
      _statusMessage = WebDAVLocalizations.of(context).disconnectingStatus;
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
      _statusMessage = WebDAVLocalizations.of(context).disconnectedStatus;
    });
  }

  // 将本地数据同步到WebDAV
  Future<void> _syncLocalToWebDAV() async {
    setState(() {
      _statusMessage = WebDAVLocalizations.of(context).uploadingStatus;
      _isConnecting = true;
    });

    final success = await widget.controller.syncLocalToWebDAV(context);

    setState(() {
      _isConnecting = false;
      _statusMessage =
          success
              ? WebDAVLocalizations.of(context).uploadSuccessStatus
              : WebDAVLocalizations.of(context).uploadFailedStatus;
    });
  }

  // 将WebDAV数据同步到本地
  Future<void> _syncWebDAVToLocal() async {
    setState(() {
      _statusMessage = WebDAVLocalizations.of(context).downloadingStatus;
      _isConnecting = true;
    });

    final success = await widget.controller.syncWebDAVToLocal(context);

    setState(() {
      _isConnecting = false;
      _statusMessage =
          success
              ? WebDAVLocalizations.of(context).downloadSuccessStatus
              : WebDAVLocalizations.of(context).downloadFailedStatus;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(WebDAVLocalizations.of(context).title),
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
                  labelText: WebDAVLocalizations.of(context).serverAddress,
                  hintText: WebDAVLocalizations.of(context).serverAddressHint,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return WebDAVLocalizations.of(
                      context,
                    ).serverAddressEmptyError;
                  }
                  if (!value.startsWith('http://') &&
                      !value.startsWith('https://')) {
                    return WebDAVLocalizations.of(
                      context,
                    ).serverAddressInvalidError;
                  }
                  return null;
                },
                enabled: !_isConnected,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: WebDAVLocalizations.of(context).username,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return WebDAVLocalizations.of(context).usernameEmptyError;
                  }
                  return null;
                },
                enabled: !_isConnected,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: WebDAVLocalizations.of(context).password,
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return WebDAVLocalizations.of(context).passwordEmptyError;
                  }
                  return null;
                },
                enabled: !_isConnected,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _dataPathController,
                decoration: InputDecoration(
                  labelText: WebDAVLocalizations.of(context).rootPath,
                  hintText: WebDAVLocalizations.of(context).rootPathHint,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return WebDAVLocalizations.of(context).rootPathEmptyError;
                  }
                  if (!value.startsWith('/')) {
                    return WebDAVLocalizations.of(context).rootPathInvalidError;
                  }
                  return null;
                },
                enabled: !_isConnected,
              ),
              const SizedBox(height: 16),
              if (_isConnected)
                SwitchListTile(
                  title: Text(WebDAVLocalizations.of(context).enableAutoSync),
                  subtitle: Text(
                    WebDAVLocalizations.of(context).syncIntervalHint,
                  ),
                  value: _autoSync,
                  onChanged: (bool value) {
                    setState(() {
                      _autoSync = value;
                      _statusMessage =
                          value
                              ? WebDAVLocalizations.of(
                                context,
                              ).autoSyncEnabledStatus
                              : WebDAVLocalizations.of(
                                context,
                              ).autoSyncDisabledStatus;
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
            child: Text(WebDAVLocalizations.of(context).testConnection),
          )
        else ...[
          TextButton(
            onPressed: _isConnecting ? null : _disconnect,
            child: Text(WebDAVLocalizations.of(context).disconnect),
          ),
          TextButton(
            onPressed: _isConnecting ? null : _syncWebDAVToLocal,
            child: Text(WebDAVLocalizations.of(context).downloadAllData),
          ),
          TextButton(
            onPressed: _isConnecting ? null : _syncLocalToWebDAV,
            child: Text(WebDAVLocalizations.of(context).uploadAllData),
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
              ScaffoldMessenger.of(currentContext).showSnackBar(
                SnackBar(
                  content: Text(
                    WebDAVLocalizations.of(context).settingsSavedMessage,
                  ),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: Text(AppLocalizations.of(context)!.done),
          ),
        ],
      ],
    );
  }
}
