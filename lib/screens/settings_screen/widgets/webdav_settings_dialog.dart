import 'package:flutter/material.dart';
import '../controllers/webdav_controller.dart';

class WebDAVSettingsDialog extends StatefulWidget {
  final WebDAVController controller;
  final Map<String, dynamic>? initialConfig;

  const WebDAVSettingsDialog({
    Key? key,
    required this.controller,
    this.initialConfig,
  }) : super(key: key);

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
  String _statusMessage = '';

  @override
  void initState() {
    super.initState();
    
    // 初始化控制器
    _urlController = TextEditingController(
      text: widget.initialConfig?['url'] ?? 'https://',
    );
    _usernameController = TextEditingController(
      text: widget.initialConfig?['username'] ?? '',
    );
    _passwordController = TextEditingController(
      text: widget.initialConfig?['password'] ?? '',
    );
    _dataPathController = TextEditingController(
      text: widget.initialConfig?['dataPath'] ?? '/app_data',
    );
    
    _isConnected = widget.initialConfig?['isConnected'] == true;
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

    await widget.controller.disconnect();

    setState(() {
      _isConnecting = false;
      _isConnected = false;
      _statusMessage = '已断开连接';
    });
  }

  // 显示数据同步选项对话框
  void _showSyncOptionsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('数据同步选项'),
        content: const Text(
          '请选择同步方式：\n'
          '- 将本地数据上传到WebDAV\n'
          '- 将WebDAV数据下载到本地\n'
          '- 跳过数据同步'
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _syncLocalToWebDAV();
            },
            child: const Text('上传到WebDAV'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _syncWebDAVToLocal();
            },
            child: const Text('下载到本地'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(true); // 关闭设置对话框并返回成功
            },
            child: const Text('跳过同步'),
          ),
        ],
      ),
    );
  }

  // 将本地数据同步到WebDAV
  Future<void> _syncLocalToWebDAV() async {
    setState(() {
      _statusMessage = '正在上传数据到WebDAV...';
      _isConnecting = true;
    });

    final success = await widget.controller.syncLocalToWebDAV();

    setState(() {
      _isConnecting = false;
      _statusMessage = success ? '上传成功!' : '上传失败，请检查连接';
    });

    if (success) {
      if (!mounted) return;
      Navigator.of(context).pop(true); // 关闭对话框并返回成功
    }
  }

  // 将WebDAV数据同步到本地
  Future<void> _syncWebDAVToLocal() async {
    setState(() {
      _statusMessage = '正在从WebDAV下载数据...';
      _isConnecting = true;
    });

    final success = await widget.controller.syncWebDAVToLocal();

    setState(() {
      _isConnecting = false;
      _statusMessage = success ? '下载成功!' : '下载失败，请检查连接';
    });

    if (success) {
      if (!mounted) return;
      Navigator.of(context).pop(true); // 关闭对话框并返回成功
    }
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
                decoration: const InputDecoration(
                  labelText: '用户名',
                ),
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
                decoration: const InputDecoration(
                  labelText: '密码',
                ),
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
                const Center(
                  child: CircularProgressIndicator(),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(false);
          },
          child: const Text('取消'),
        ),
        if (!_isConnected)
          TextButton(
            onPressed: _isConnecting ? null : _testConnection,
            child: const Text('测试连接'),
          )
        else
          TextButton(
            onPressed: _isConnecting ? null : _disconnect,
            child: const Text('断开连接'),
          ),
        if (_isConnected)
          TextButton(
            onPressed: _isConnecting ? null : _showSyncOptionsDialog,
            child: const Text('确定'),
          ),
      ],
    );
  }
}