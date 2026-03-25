import 'dart:async';
import 'package:floating_ball_plugin/floating_ball_plugin.dart';
import 'package:flutter/material.dart';
import 'package:Memento/widgets/adaptive_switch.dart';
import 'package:get/get.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
import 'package:Memento/core/services/toast_service.dart';
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
        _showMessage(
          isRunning
              ? 'screens_floatingBallStarted'.tr
              : 'screens_floatingBallStopped'.tr,
        );
      }
    });

    _permissionSubscription = _controller.permissionChanges.listen((
      hasPermission,
    ) {
      if (mounted) {
        setState(() {});
        _showMessage(
          hasPermission
              ? 'screens_permissionGranted'.tr
              : 'screens_permissionDenied'.tr,
        );
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
        _showMessage(
          'screens_clickedButton'.trParams({'buttonName': event.title}),
        );
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
      appBar: AppBar(title: Text('screens_floatingBallSettings'.tr)),
      body: ListView(
        children: [
          // 悬浮球状态
          ListTile(
            leading: Icon(
              _controller.isRunning
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: _controller.isRunning ? Colors.green : Colors.grey,
            ),
            title: Text('screens_floatingBallStatus'.tr),
            trailing: Text(
              _controller.isRunning ? 'screens_running'.tr : 'screens_stopped'.tr,
              style: TextStyle(
                color: _controller.isRunning ? Colors.green : Colors.grey,
              ),
            ),
          ),
          const Divider(height: 1),
          // 悬浮窗权限
          ListTile(
            leading: Icon(
              _controller.hasPermission ? Icons.check_circle : Icons.error,
              color: _controller.hasPermission ? Colors.green : Colors.red,
            ),
            title: Text('screens_floatingWindowPermission'.tr),
            trailing: _controller.hasPermission
                ? Text(
                    'screens_granted'.tr,
                    style: const TextStyle(color: Colors.green),
                  )
                : TextButton(
                    onPressed: () async {
                      await _controller.requestPermission();
                    },
                    child: Text('screens_requestPermission'.tr),
                  ),
          ),
          const Divider(height: 1),
          // 开启/禁用悬浮球
          ListTile(
            leading: Icon(
              _controller.isRunning ? Icons.stop : Icons.play_arrow,
              color: _controller.isRunning ? Colors.red : Colors.green,
            ),
            title: Text('screens_floatingBallSwitch'.tr),
            trailing: AdaptiveSwitch(
              value: _controller.isRunning,
              onChanged: (_) async {
                await _controller.toggleFloatingBall();
              },
            ),
            onTap: () async {
              await _controller.toggleFloatingBall();
            },
          ),
          const Divider(height: 1),
          // 应用内自动隐藏
          ListTile(
            leading: const Icon(Icons.visibility_off),
            title: Text('screens_autoHideInApp'.tr),
            subtitle: Text('screens_autoHideInAppDescription'.tr),
            trailing: AdaptiveSwitch(
              value: _controller.autoHideInApp,
              onChanged: (value) {
                _controller.setAutoHideInApp(value);
                setState(() {});
              },
            ),
          ),
          const Divider(height: 16, thickness: 8),
          // 选择图片
          ListTile(
            leading: const Icon(Icons.image),
            title: Text('screens_selectImageAsFloatingBall'.tr),
            trailing: const Icon(Icons.chevron_right),
            onTap: _pickAndSetImage,
          ),
          const Divider(height: 1),
          // 大小设置
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                const Icon(Icons.straighten, size: 24),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('screens_sizeColon'.tr),
                      Slider(
                        value: _controller.ballSize,
                        min: 50,
                        max: 150,
                        divisions: 10,
                        label: 'screens_ballSizeDp'.trParams({
                          'size': _controller.ballSize.round().toString(),
                        }),
                        onChanged: (value) {
                          _controller.setBallSize(value);
                          setState(() {});
                        },
                        onChangeEnd: (value) async {
                          await _controller.updateConfig();
                        },
                      ),
                    ],
                  ),
                ),
                Text(
                  'screens_ballSizeDp'.trParams({
                    'size': _controller.ballSize.round().toString(),
                  }),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // 吸附阈值
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                const Icon(Icons.vertical_align_center, size: 24),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('screens_snapThresholdColon'.tr),
                      Slider(
                        value: _controller.snapThreshold.toDouble(),
                        min: 20,
                        max: 100,
                        divisions: 8,
                        label: 'screens_snapThresholdPx'.trParams({
                          'threshold': _controller.snapThreshold.toString(),
                        }),
                        onChanged: (value) {
                          _controller.setSnapThreshold(value.toInt());
                          setState(() {});
                        },
                        onChangeEnd: (value) async {
                          await _controller.updateConfig();
                        },
                      ),
                    ],
                  ),
                ),
                Text(
                  'screens_snapThresholdPx'.trParams({
                    'threshold': _controller.snapThreshold.toString(),
                  }),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // 自动恢复状态
          ListTile(
            leading: const Icon(Icons.restore),
            title: Text('screens_autoRestoreFloatingBallState'.tr),
            trailing: AdaptiveSwitch(
              value: _controller.autoRestore,
              onChanged: (value) {
                _controller.setAutoRestore(value);
                setState(() {});
              },
            ),
          ),
          const Divider(height: 1),
          // 按钮管理
          ListTile(
            leading: const Icon(Icons.touch_app),
            title: Text('screens_manageFloatingButtons'.tr),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'screens_buttonCount'.trParams({
                    'count': _controller.buttonData.length.toString(),
                  }),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right),
              ],
            ),
            onTap: () {
              NavigationHelper.push(
                context,
                const FloatingButtonManagerScreen(),
              ).then((_) => setState(() {}));
            },
          ),
          // 位置信息
          if (_controller.lastPosition != null) ...[
            const Divider(height: 16, thickness: 8),
            ListTile(
              leading: const Icon(Icons.location_on),
              title: Text('screens_currentPosition'.tr),
              subtitle: Text(
                'screens_xPositionYPosition'.trParams({
                  'x': _controller.lastPosition!.x.toDouble().toStringAsFixed(0),
                  'y': _controller.lastPosition!.y.toDouble().toStringAsFixed(0),
                }),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  _controller.clearPosition();
                  setState(() {});
                },
              ),
            ),
          ],
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
      Toast.info(message, duration: const Duration(seconds: 2));
    }
  }
}
