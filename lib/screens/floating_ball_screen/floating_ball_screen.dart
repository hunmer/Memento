import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:floating_ball_plugin/floating_ball_plugin.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FloatingBallScreen extends StatefulWidget {
  const FloatingBallScreen({super.key});

  @override
  State<FloatingBallScreen> createState() => _FloatingBallScreenState();
}

class _FloatingBallScreenState extends State<FloatingBallScreen> {
  bool _isRunning = false;
  bool _hasPermission = false;
  FloatingBallPosition? _lastPosition;
  StreamSubscription<FloatingBallPosition>? _positionSubscription;

  // 配置参数
  double _ballSize = 80.0;
  int _snapThreshold = 50;
  int _subButtonCount = 3; // 默认3个子按钮
  String _iconName = ''; // 空字符串表示使用默认图标

  // 图片选择
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _checkStatus();
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _ballSize = prefs.getDouble('floating_ball_size') ?? 80.0;
      _snapThreshold = prefs.getInt('floating_ball_snap_threshold') ?? 50;
      _subButtonCount = prefs.getInt('floating_ball_sub_button_count') ?? 3;
      _iconName = prefs.getString('floating_ball_icon') ?? '';
      _lastPosition = FloatingBallPosition(
        prefs.getInt('floating_ball_x') ?? 0,
        prefs.getInt('floating_ball_y') ?? 0,
      );
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('floating_ball_size', _ballSize);
    await prefs.setInt('floating_ball_snap_threshold', _snapThreshold);
    await prefs.setInt('floating_ball_sub_button_count', _subButtonCount);
    await prefs.setString('floating_ball_icon', _iconName);
    if (_lastPosition != null) {
      await prefs.setInt('floating_ball_x', _lastPosition!.x);
      await prefs.setInt('floating_ball_y', _lastPosition!.y);
    }
  }

  Future<void> _checkStatus() async {
    final hasPermission = await Permission.systemAlertWindow.isGranted;
    final isRunning = await FloatingBallPlugin.isRunning();
    setState(() {
      _hasPermission = hasPermission;
      _isRunning = isRunning;
    });

    if (isRunning) {
      _startListeningPosition();
    }
  }

  void _startListeningPosition() {
    _positionSubscription?.cancel();
    _positionSubscription = FloatingBallPlugin.listenPositionChanges().listen(
      (position) {
        setState(() {
          _lastPosition = position;
        });
        // 保存位置
        SharedPreferences.getInstance().then((prefs) {
          prefs.setInt('floating_ball_x', position.x);
          prefs.setInt('floating_ball_y', position.y);
        });
      },
    );
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
      _positionSubscription?.cancel();
    } else {
      // 创建配置
      final config = FloatingBallConfig(
        iconName: _iconName.isEmpty ? null : _iconName,
        size: _ballSize,
        startX: _lastPosition?.x,
        startY: _lastPosition?.y,
        snapThreshold: _snapThreshold,
        subButtonCount: _subButtonCount,
      );

      final result = await FloatingBallPlugin.startFloatingBall(config: config);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result ?? '已启动悬浮球')),
        );
      }
      _startListeningPosition();
    }

    await _checkStatus();
  }

  /// 实时更新悬浮球配置
  Future<void> _updateFloatingBallConfig() async {
    if (!_isRunning) {
      return;
    }

    final config = FloatingBallConfig(
      iconName: _iconName.isEmpty ? null : _iconName,
      size: _ballSize,
      snapThreshold: _snapThreshold,
      subButtonCount: _subButtonCount,
    );

    await FloatingBallPlugin.updateConfig(config);
    await _saveSettings();
  }

  /// 选择并设置悬浮球图片
  Future<void> _pickAndSetImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80, // 压缩图片质量
      );

      if (image != null) {
        final Uint8List bytes = await image.readAsBytes();

        if (_isRunning) {
          final result = await FloatingBallPlugin.setFloatingBallImage(bytes);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(result ?? '图片设置成功')),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('请先启动悬浮球')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('选择图片失败: $e')),
        );
      }
    }
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
                          value: _ballSize,
                          min: 50,
                          max: 150,
                          divisions: 10,
                          label: '${_ballSize.round()}dp',
                          onChanged: (value) {
                            setState(() => _ballSize = value);
                          },
                          onChangeEnd: (value) async {
                            await _saveSettings();
                            await _updateFloatingBallConfig();
                          },
                        ),
                      ),
                      Text('${_ballSize.round()}dp'),
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
                          value: _snapThreshold.toDouble(),
                          min: 20,
                          max: 100,
                          divisions: 8,
                          label: '${_snapThreshold}px',
                          onChanged: (value) {
                            setState(() => _snapThreshold = value.toInt());
                          },
                          onChangeEnd: (value) async {
                            await _saveSettings();
                            await _updateFloatingBallConfig();
                          },
                        ),
                      ),
                      Text('${_snapThreshold}px'),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      const Text('子按钮数量: '),
                      Expanded(
                        child: Slider(
                          value: _subButtonCount.toDouble(),
                          min: 1,
                          max: 10,
                          divisions: 9,
                          label: '$_subButtonCount 个',
                          onChanged: (value) {
                            setState(() => _subButtonCount = value.toInt());
                          },
                          onChangeEnd: (value) async {
                            await _saveSettings();
                            await _updateFloatingBallConfig();
                          },
                        ),
                      ),
                      Text('$_subButtonCount'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // 位置信息
          if (_lastPosition != null)
            Card(
              child: ListTile(
                leading: const Icon(Icons.location_on),
                title: const Text('当前位置'),
                subtitle: Text('X: ${_lastPosition!.x}, Y: ${_lastPosition!.y}'),
                trailing: IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                    setState(() {
                      _lastPosition = null;
                    });
                    SharedPreferences.getInstance().then((prefs) {
                      prefs.remove('floating_ball_x');
                      prefs.remove('floating_ball_y');
                    });
                  },
                ),
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
              '• 支持自定义图片作为悬浮球外观\n'
              '• 拖动悬浮球会自动吸附到屏幕边缘（靠近时）\n'
              '• 点击悬浮球可展开圆形子按钮（最多10个）\n'
              '• 子按钮根据位置动态布局（全圆或半圆）\n'
              '• 调节大小、吸附阈值和子按钮数量无需重启\n'
              '• 位置会自动保存，下次启动时恢复\n'
              '• 建议在使用时保持应用后台运行',
            ),
          ),
        ],
      ),
    );
  }
}
