import 'package:Memento/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import '../controllers/webdav_controller.dart';
import '../../../core/storage/storage_manager.dart';

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
      _statusMessage = '正在连接...';
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
        _statusMessage = success ? '连接成功!' : '连接失败，请检查设置';
      });
    } catch (e) {
      setState(() {
        _isConnecting = false;
        _isConnected = false;
        _statusMessage = '连接错误: $e';
      });
    }
  }

  // 断开连接
  Future<void> _disconnect() async {
    setState(() {
      _isConnecting = true;
      _statusMessage = '正在断开连接...';
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
      _statusMessage = '已断开连接';
    });
  }

  // 将本地数据同步到WebDAV
  Future<void> _syncLocalToWebDAV() async {
    setState(() {
      _statusMessage = '正在上传数据到WebDAV...';
      _isConnecting = true;
    });

    final success = await widget.controller.syncLocalToWebDAV(context);

    setState(() {
      _isConnecting = false;
      _statusMessage = success ? '上传成功!' : '上传失败，请检查连接';
    });
  }

  // 将WebDAV数据同步到本地
  Future<void> _syncWebDAVToLocal() async {
    setState(() {
      _statusMessage = '正在从WebDAV下载数据...';
      _isConnecting = true;
    });

    final success = await widget.controller.syncWebDAVToLocal(context);

    setState(() {
      _isConnecting = false;
      _statusMessage = success ? '下载成功!' : '下载失败，请检查连接';
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('WebDAV 设置'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _urlController,
                decoration: const InputDecoration(
                  labelText: 'WebDAV 服务器地址',
                  hintText: 'https://example.com/webdav',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入WebDAV服务器地址';
                  }
                  if (!value.startsWith('http://') &&
                      !value.startsWith('https://')) {
                    return '地址必须以http://或https://开头';
                  }
                  return null;
                },
                enabled: !_isConnected,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(labelText: '用户名'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入用户名';
                  }
                  return null;
                },
                enabled: !_isConnected,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: '密码'),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入密码';
                  }
                  return null;
                },
                enabled: !_isConnected,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _dataPathController,
                decoration: const InputDecoration(
                  labelText: '数据目录路径',
                  hintText: '/app_data',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入数据目录路径';
                  }
                  if (!value.startsWith('/')) {
                    return '路径必须以/开头';
                  }
                  return null;
                },
                enabled: !_isConnected,
              ),
              const SizedBox(height: 16),
              if (_isConnected)
                SwitchListTile(
                  title: const Text('自动同步'),
                  subtitle: const Text('监控本地文件变化并自动同步到WebDAV (不包含配置文件)'),
                  value: _autoSync,
                  onChanged: (bool value) {
                    setState(() {
                      _autoSync = value;
                      _statusMessage =
                          value ? '自动同步已开启，点击完成后生效' : '自动同步已关闭，点击完成后生效';
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
            child: const Text('测试连接'),
          )
        else ...[
          TextButton(
            onPressed: _isConnecting ? null : _disconnect,
            child: const Text('断开连接'),
          ),
          TextButton(
            onPressed: _isConnecting ? null : _syncWebDAVToLocal,
            child: const Text('下载'),
          ),
          TextButton(
            onPressed: _isConnecting ? null : _syncLocalToWebDAV,
            child: const Text('上传'),
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
                const SnackBar(
                  content: Text('设置已保存'),
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
