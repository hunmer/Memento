import 'dart:async';
import 'package:floating_ball_plugin/floating_ball_plugin.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:Memento/core/floating_ball/floating_widget_controller.dart';
import 'package:Memento/core/floating_ball/screens/floating_button_manager_screen.dart';

class FloatingBallScreen extends StatefulWidget {
  const FloatingBallScreen({super.key});

  @override
  State<FloatingBallScreen> createState() => _FloatingBallScreenState();
}

class _FloatingBallScreenState extends State<FloatingBallScreen> {
  late final FloatingWidgetController _controller;
  StreamSubscription<bool>? _runningSubscription;
  StreamSubscription<bool>? _permissionSubscription;
  StreamSubscription<FloatingBallPosition>? _positionSubscription;
  StreamSubscription<FloatingBallButtonEvent>? _buttonSubscription;

  // 图片选择器
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _controller = FloatingWidgetController();
    _initialize();
  }

  Future<void> _initialize() async {
    await _controller.initialize();
    _setupListeners();
  }

  void _setupListeners() {
    _runningSubscription = _controller.runningChanges.listen((isRunning) {
      if (mounted) {
        setState(() {});
        _showMessage(isRunning ? '悬浮球已启动' : '悬浮球已停止');
      }
    });

    _permissionSubscription = _controller.permissionChanges.listen((
      hasPermission,
    ) {
      if (mounted) {
        setState(() {});
        _showMessage(hasPermission ? '权限已授予' : '权限被拒绝');
      }
    });

    _positionSubscription = _controller.positionChanges.listen((position) {
      if (mounted) {
        setState(() {});
      }
    });

    _buttonSubscription = _controller.buttonEvents.listen((event) {
      print('收到按钮事件: ${event.title}, data: ${event.data}');
      if (mounted) {
        _showMessage('点击了: ${event.title}');
        _handleButtonEvent(event);
      }
    });
  }

  void _handleButtonEvent(FloatingBallButtonEvent event) {
    if (event.data != null) {
      final action = event.data!['action'];
      if (action != null) {
        switch (action) {
          case 'home':
            // 返回首页
            break;
          case 'settings':
            // 打开设置
            break;
          case 'search':
            // 打开搜索
            break;
        }
      }
    }
  }

  @override
  void dispose() {
    _runningSubscription?.cancel();
    _permissionSubscription?.cancel();
    _positionSubscription?.cancel();
    _buttonSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('悬浮球设置')),
      body: ListView(
        children: [
          Card(
            child: ListTile(
              leading: Icon(
                _controller.isRunning
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: _controller.isRunning ? Colors.green : Colors.grey,
              ),
              title: const Text('悬浮球状态'),
              subtitle: Text(_controller.isRunning ? '运行中' : '已停止'),
            ),
          ),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(
                    _controller.hasPermission
                        ? Icons.check_circle
                        : Icons.error,
                    color:
                        _controller.hasPermission ? Colors.green : Colors.red,
                  ),
                  title: const Text('悬浮窗权限'),
                  subtitle: Text(_controller.hasPermission ? '已授予' : '未授予'),
                ),
                if (!_controller.hasPermission)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await _controller.requestPermission();
                      },
                      icon: const Icon(Icons.security),
                      label: const Text('申请权限'),
                    ),
                  ),
              ],
            ),
          ),
          // 配置参数卡片
          Card(
            child: Column(
              children: [
                const ListTile(
                  leading: Icon(Icons.tune),
                  title: Text('悬浮球配置'),
                  subtitle: Text('自定义悬浮球的外观和行为'),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton.icon(
                    onPressed: _pickAndSetImage,
                    icon: const Icon(Icons.image),
                    label: const Text('选择图片作为悬浮球'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      const Text('大小: '),
                      Expanded(
                        child: Slider(
                          value: _controller.ballSize,
                          min: 50,
                          max: 150,
                          divisions: 10,
                          label: '${_controller.ballSize.round()}dp',
                          onChanged: (value) {
                            _controller.setBallSize(value);
                            setState(() {});
                          },
                          onChangeEnd: (value) async {
                            await _controller.updateConfig();
                          },
                        ),
                      ),
                      Text('${_controller.ballSize.round()}dp'),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      const Text('吸附阈值: '),
                      Expanded(
                        child: Slider(
                          value: _controller.snapThreshold.toDouble(),
                          min: 20,
                          max: 100,
                          divisions: 8,
                          label: '${_controller.snapThreshold}px',
                          onChanged: (value) {
                            _controller.setSnapThreshold(value.toInt());
                            setState(() {});
                          },
                          onChangeEnd: (value) async {
                            await _controller.updateConfig();
                          },
                        ),
                      ),
                      Text('${_controller.snapThreshold}px'),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      const Expanded(child: Text('自动恢复悬浮球状态')),
                      Switch(
                        value: _controller.autoRestore,
                        onChanged: (value) {
                          _controller.setAutoRestore(value);
                          setState(() {});
                        },
                      ),
                    ],
                  ),
                ),
                // 按钮管理
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text('按钮数量: '),
                          Text('${_controller.buttonData.length} 个'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const FloatingButtonManagerScreen(),
                            ),
                          ).then((_) => setState(() {}));
                        },
                        icon: const Icon(Icons.touch_app),
                        label: const Text('管理悬浮按钮'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // 位置信息
          if (_controller.lastPosition != null)
            Card(
              child: ListTile(
                leading: const Icon(Icons.location_on),
                title: const Text('当前位置'),
                subtitle: Text(
                  'X: ${_controller.lastPosition!.x}, Y: ${_controller.lastPosition!.y}',
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                    _controller.clearPosition();
                    setState(() {});
                  },
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: () async {
                await _controller.toggleFloatingBall();
              },
              icon: Icon(_controller.isRunning ? Icons.stop : Icons.play_arrow),
              label: Text(_controller.isRunning ? '停止悬浮球' : '启动悬浮球'),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    _controller.isRunning ? Colors.red : Colors.green,
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              '功能说明：\n'
              '• 悬浮球可在任何应用上显示\n'
              '• 支持自定义图片作为悬浮球外观\n'
              '• 拖动悬浮球会自动吸附到屏幕边缘（靠近时）\n'
              '• 点击悬浮球可展开圆形子按钮，点击后通过EventChannel回传事件\n'
              '• 子按钮根据位置动态布局（全圆或半圆）\n'
              '• 调节大小、吸附阈值和按钮数据无需重启\n'
              '• 位置会自动保存，下次启动时恢复\n'
              '• 建议在使用时保持应用后台运行',
            ),
          ),
        ],
      ),
    );
  }

  /// 选择并设置图片
  Future<void> _pickAndSetImage() async {
    final result = await _controller.pickAndSetImage(_picker);
    if (result != null && mounted) {
      _showMessage(result);
    }
  }

  /// 显示消息
  void _showMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
      );
    }
  }
}
