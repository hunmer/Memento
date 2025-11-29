import 'package:flutter/material.dart';
import 'package:floating_ball_plugin/floating_ball_plugin.dart';
import 'package:permission_handler/permission_handler.dart';

class FloatingBallScreen extends StatefulWidget {
  const FloatingBallScreen({super.key});

  @override
  State<FloatingBallScreen> createState() => _FloatingBallScreenState();
}

class _FloatingBallScreenState extends State<FloatingBallScreen> {
  bool _isRunning = false;
  bool _hasPermission = false;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    final hasPermission = await Permission.systemAlertWindow.isGranted;
    final isRunning = await FloatingBallPlugin.isRunning();
    setState(() {
      _hasPermission = hasPermission;
      _isRunning = isRunning;
    });
  }

  Future<void> _requestPermission() async {
    final status = await Permission.systemAlertWindow.request();
    if (status.isGranted) {
      setState(() => _hasPermission = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('权限已授予')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('权限被拒绝')),
      );
    }
  }

  Future<void> _toggleFloatingBall() async {
    if (!_hasPermission) {
      await _requestPermission();
      return;
    }

    if (_isRunning) {
      final result = await FloatingBallPlugin.stopFloatingBall();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result ?? '已停止悬浮球')),
        );
      }
    } else {
      final result = await FloatingBallPlugin.startFloatingBall();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result ?? '已启动悬浮球')),
        );
      }
    }

    await _checkStatus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('悬浮球设置'),
      ),
      body: ListView(
        children: [
          Card(
            child: ListTile(
              leading: Icon(
                _isRunning ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                color: _isRunning ? Colors.green : Colors.grey,
              ),
              title: const Text('悬浮球状态'),
              subtitle: Text(_isRunning ? '运行中' : '已停止'),
            ),
          ),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(
                    _hasPermission ? Icons.check_circle : Icons.error,
                    color: _hasPermission ? Colors.green : Colors.red,
                  ),
                  title: const Text('悬浮窗权限'),
                  subtitle: Text(_hasPermission ? '已授予' : '未授予'),
                ),
                if (!_hasPermission)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ElevatedButton.icon(
                      onPressed: _requestPermission,
                      icon: const Icon(Icons.security),
                      label: const Text('申请权限'),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: _toggleFloatingBall,
              icon: Icon(_isRunning ? Icons.stop : Icons.play_arrow),
              label: Text(_isRunning ? '停止悬浮球' : '启动悬浮球'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isRunning ? Colors.red : Colors.green,
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              '功能说明：\n'
              '• 悬浮球可在任何应用上显示\n'
              '• 拖动悬浮球会自动吸附到屏幕边缘\n'
              '• 点击悬浮球可展开3个快速按钮\n'
              '• 建议在使用时保持应用后台运行',
            ),
          ),
        ],
      ),
    );
  }
}
