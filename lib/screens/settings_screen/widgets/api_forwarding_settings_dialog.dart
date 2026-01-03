import 'dart:async';
import 'package:flutter/material.dart';
import 'package:Memento/core/api_forwarding/api_forwarding_config.dart';
import 'package:Memento/core/api_forwarding/api_forwarding_service.dart';

/// API 转发服务设置对话框
class ApiForwardingSettingsDialog extends StatefulWidget {
  final ApiForwardingConfig initialConfig;

  const ApiForwardingSettingsDialog({
    super.key,
    required this.initialConfig,
  });

  @override
  State<ApiForwardingSettingsDialog> createState() =>
      _ApiForwardingSettingsDialogState();
}

class _ApiForwardingSettingsDialogState
    extends State<ApiForwardingSettingsDialog> {
  late TextEditingController _serverUrlController;
  late TextEditingController _pairingKeyController;
  late TextEditingController _deviceNameController;
  bool _isConnected = false;
  bool _isWaitingForPeer = false;  // 新增：等待对端
  bool _isConnecting = false;
  bool _autoConnect = false;

  StreamSubscription? _eventSubscription;

  @override
  void initState() {
    super.initState();

    final config = widget.initialConfig;
    _serverUrlController = TextEditingController(text: config.serverUrl);
    _pairingKeyController = TextEditingController(text: config.pairingKey);
    _deviceNameController = TextEditingController(text: config.deviceName);
    _autoConnect = config.autoConnect;

    // 监听连接状态
    _eventSubscription =
        ApiForwardingService.instance.eventStream.listen((event) {
      if (mounted) {
        final type = event['type'] as String?;
        debugPrint('[对话框] 收到事件: $type');
        setState(() {
          switch (type) {
            case 'connected':
              _isConnected = true;
              _isWaitingForPeer = false;
              _isConnecting = false;
              debugPrint('[对话框] 状态更新: 已连接到前端');
              // 连接成功后延迟关闭对话框，让用户看到状态更新
              Future.delayed(const Duration(milliseconds: 500), () {
                if (mounted) {
                  Navigator.of(context).pop(true);
                }
              });
              break;
            case 'waiting':
              _isConnected = true;
              _isWaitingForPeer = true;
              _isConnecting = false;
              debugPrint('[对话框] 状态更新: 等待前端连接');
              break;
            case 'disconnected':
            case 'stopped':
              _isConnected = false;
              _isWaitingForPeer = false;
              _isConnecting = false;
              debugPrint('[对话框] 状态更新: 未连接');
              break;
            case 'error':
              _isConnecting = false;
              _showErrorSnackBar(event['message']?.toString() ?? '未知错误');
              break;
          }
        });
      }
    });

    // 检查当前连接状态（在事件监听器设置之前）
    _isConnected = ApiForwardingService.instance.isConnected;
    _isWaitingForPeer = ApiForwardingService.instance.isWaitingForPeer;
  }

  @override
  void dispose() {
    _eventSubscription?.cancel();
    _serverUrlController.dispose();
    _pairingKeyController.dispose();
    _deviceNameController.dispose();
    super.dispose();
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('错误: $message')),
    );
  }

  Future<void> _generateNewKey() async {
    final newKey = ApiForwardingConfig.generatePairingKey();
    _pairingKeyController.text = newKey;
  }

  Future<void> _saveAndConnect() async {
    if (_serverUrlController.text.isEmpty ||
        _pairingKeyController.text.isEmpty) {
      _showErrorSnackBar('请填写服务器地址和配对密钥');
      return;
    }

    setState(() {
      _isConnecting = true;
    });

    try {
      final config = ApiForwardingConfig(
        enabled: true,
        autoConnect: _autoConnect,
        serverUrl: _serverUrlController.text.trim(),
        pairingKey: _pairingKeyController.text.trim(),
        deviceName: _deviceNameController.text.trim(),
      );

      await config.save();
      await ApiForwardingService.instance.start(config);

      // 连接成功后会通过事件监听器自动关闭对话框
    } catch (e) {
      setState(() {
        _isConnecting = false;
      });
      if (mounted) {
        _showErrorSnackBar('连接失败: $e');
      }
    }
  }

  // 状态辅助方法
  Color _getStatusColor() {
    debugPrint('[对话框] _getStatusColor: _isWaitingForPeer=$_isWaitingForPeer, _isConnected=$_isConnected');
    if (_isWaitingForPeer) {
      return Colors.blue; // 等待对端 - 蓝色
    } else if (_isConnected) {
      return Colors.green; // 已连接 - 绿色
    } else {
      return Colors.orange; // 未连接 - 橙色
    }
  }

  IconData _getStatusIcon() {
    if (_isWaitingForPeer) {
      return Icons.hourglass_empty; // 等待对端
    } else if (_isConnected) {
      return Icons.check_circle; // 已连接
    } else {
      return Icons.warning; // 未连接
    }
  }

  String _getStatusText() {
    debugPrint('[对话框] _getStatusText: _isWaitingForPeer=$_isWaitingForPeer, _isConnected=$_isConnected');
    if (_isWaitingForPeer) {
      return '等待前端连接...'; // 等待对端
    } else if (_isConnected) {
      return '已连接到前端'; // 已连接
    } else {
      return '未连接'; // 未连接
    }
  }

  Future<void> _disconnect() async {
    await ApiForwardingService.instance.stop();

    final config = widget.initialConfig;
    final newConfig = ApiForwardingConfig(
      enabled: false,
      serverUrl: config.serverUrl,
      pairingKey: config.pairingKey,
      deviceName: config.deviceName,
    );
    await newConfig.save();

    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('转发数据服务设置'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 状态指示
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getStatusColor().withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _getStatusColor(),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _getStatusIcon(),
                    color: _getStatusColor(),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _getStatusText(),
                      style: TextStyle(
                        color: _getStatusColor(),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 服务器地址
            TextField(
              controller: _serverUrlController,
              decoration: InputDecoration(
                labelText: '服务器地址',
                hintText: 'ws://localhost:8654',
                prefixIcon: const Icon(Icons.cloud),
                border: const OutlineInputBorder(),
                helperText: _serverUrlController.text.isEmpty
                    ? '支持格式: ws://host:port 或 wss://host:port'
                    : '格式正确',
                helperStyle: TextStyle(
                  color: _serverUrlController.text.isEmpty
                      ? Colors.grey
                      : Colors.green,
                ),
              ),
              enabled: !_isConnected,
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 12),

            // 配对密钥
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _pairingKeyController,
                    decoration: const InputDecoration(
                      labelText: '配对密钥',
                      hintText: 'XXXX-XXXX-XXXX-XXXX',
                      prefixIcon: Icon(Icons.key),
                      border: OutlineInputBorder(),
                    ),
                    enabled: !_isConnected,
                  ),
                ),
                const SizedBox(width: 8),
                if (!_isConnected)
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _generateNewKey,
                    tooltip: '生成新密钥',
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // 设备名称
            TextField(
              controller: _deviceNameController,
              decoration: const InputDecoration(
                labelText: '设备名称',
                hintText: 'Memento Client',
                prefixIcon: Icon(Icons.devices),
                border: OutlineInputBorder(),
              ),
              enabled: !_isConnected,
            ),
            const SizedBox(height: 12),

            // 启动时自动连接开关
            SwitchListTile(
              title: const Text('启动时自动连接'),
              subtitle: const Text('应用启动时自动连接到转发服务器'),
              value: _autoConnect,
              onChanged: !_isConnected ? (value) {
                setState(() {
                  _autoConnect = value;
                });
              } : null,
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 8),

            // 说明文字
            Text(
              '使用说明：',
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            const Text(
              '1. 在前端项目中配置相同的服务器地址和配对密钥\n'
              '2. 确保客户端和前端都能访问转发服务器\n'
              '3. 配对密钥用于匹配前端和客户端连接',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            // 如果正在连接，不允许取消
            if (_isConnecting) {
              _showErrorSnackBar('正在连接中，请稍候...');
              return;
            }
            Navigator.of(context).pop();
          },
          child: const Text('取消'),
        ),
        if (_isConnected)
          ElevatedButton(
            onPressed: _isConnecting ? null : _disconnect,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('断开连接'),
          )
        else
          ElevatedButton(
            onPressed: _isConnecting ? null : _saveAndConnect,
            child: _isConnecting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('连接'),
          ),
      ],
    );
  }
}
