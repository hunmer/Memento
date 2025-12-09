import 'dart:async';
import 'package:floating_ball_plugin/floating_ball_plugin.dart';
import 'package:flutter/material.dart';
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
        setState(() {});        _showMessage(isRunning ? 'screens_floatingBallStarted'.tr : 'screens_floatingBallStopped'.tr);
      }
    });

    _permissionSubscription = _controller.permissionChanges.listen((
      hasPermission,
    ) {
      if (mounted) {
        setState(() {});        _showMessage(hasPermission ? 'screens_permissionGranted'.tr : 'screens_permissionDenied'.tr);
      }
    });

    _positionSubscription = _controller.positionChanges.listen((position) {
      if (mounted) {
        setState(() {});
      }
    });

    _buttonSubscription = _controller.buttonEvents.listen((event) {
      print('收到按钮事件: ${event.title}, data: ${event.data}');
      if (mounted) {        _showMessage('screens_clickedButton'.trParams({'buttonName': event.title}));
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
  Widget build(BuildContext context) {    return Scaffold(
      appBar: AppBar(title: Text('screens_floatingBallSettings'.tr)),
      body: ListView(
        children: [
          // 第一行：悬浮球状态、悬浮窗权限、开启/禁用悬浮球
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                // 悬浮球状态卡片
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _controller.isRunning
                                ? Icons.radio_button_checked
                                : Icons.radio_button_unchecked,
                            color: _controller.isRunning ? Colors.green : Colors.grey,
                            size: 32,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'screens_floatingBallStatus'.tr,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _controller.isRunning ? 'screens_running'.tr : 'screens_stopped'.tr,
                            style: TextStyle(
                              fontSize: 12,
                              color: _controller.isRunning
                                  ? Colors.green
                                  : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // 悬浮窗权限卡片
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _controller.hasPermission
                                ? Icons.check_circle
                                : Icons.error,
                            color: _controller.hasPermission
                                ? Colors.green
                                : Colors.red,
                            size: 32,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'screens_floatingWindowPermission'.tr,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _controller.hasPermission ? 'screens_granted'.tr : 'screens_notGranted'.tr,
                            style: TextStyle(
                              fontSize: 12,
                              color: _controller.hasPermission
                                  ? Colors.green
                                  : Colors.red,
                            ),
                          ),
                          if (!_controller.hasPermission) ...[
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              onPressed: () async {
                                await _controller.requestPermission();
                              },
                              icon: const Icon(Icons.security, size: 16),
                              label: Text('screens_requestPermission'.tr, style: TextStyle(fontSize: 12)),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // 开启/禁用悬浮球卡片
                Expanded(
                  child: Card(
                    color: _controller.isRunning
                        ? Colors.red.shade50
                        : Colors.green.shade50,
                    child: InkWell(
                      onTap: () async {
                        await _controller.toggleFloatingBall();
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _controller.isRunning ? Icons.stop : Icons.play_arrow,
                              color: _controller.isRunning
                                  ? Colors.red
                                  : Colors.green,
                              size: 32,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'screens_floatingBallSwitch'.tr,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _controller.isRunning ? 'screens_clickToStop'.tr : 'screens_clickToStart'.tr,
                              style: TextStyle(
                                fontSize: 12,
                                color: _controller.isRunning
                                    ? Colors.red
                                    : Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // 应用内自动隐藏overlay悬浮球选项
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'screens_autoHideInApp'.tr,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'screens_autoHideInAppDescription'.tr,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _controller.autoHideInApp,
                      onChanged: (value) {
                        _controller.setAutoHideInApp(value);
                        setState(() {});
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // 配置参数卡片
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.tune),
                  title: Text('screens_floatingBallConfig'.tr),
                  subtitle: Text('screens_customizeFloatingBallAppearanceBehavior'.tr),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton.icon(
                    onPressed: _pickAndSetImage,
                    icon: const Icon(Icons.image),
                    label: Text('screens_selectImageAsFloatingBall'.tr),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      Text('screens_sizeColon'.tr),
                      Expanded(
                        child: Slider(
                          value: _controller.ballSize,
                          min: 50,
                          max: 150,
                          divisions: 10,
                          label: 'screens_ballSizeDp'.trParams({'size': _controller.ballSize.round(.toString()}),
                          onChanged: (value) {
                            _controller.setBallSize(value);
                            setState(() {});
                          },
                          onChangeEnd: (value) async {
                            await _controller.updateConfig();
                          }
                        ),
                      ),
                      Text('screens_ballSizeDp'.trParams({'size': _controller.ballSize.round(.toString()}))
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      Text('screens_snapThresholdColon'.tr),
                      Expanded(
                        child: Slider(
                          value: _controller.snapThreshold.toDouble(),
                          min: 20,
                          max: 100,
                          divisions: 8,
                          label: 'screens_snapThresholdPx'.trParams({'threshold': _controller.snapThreshold.toString()}),
                          onChanged: (value) {
                            _controller.setSnapThreshold(value.toInt());
                            setState(() {});
                          },
                          onChangeEnd: (value) async {
                            await _controller.updateConfig();
                          },
                        ),
                      ),
                      Text('screens_snapThresholdPx'.trParams({'threshold': _controller.snapThreshold.toString()})),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      Expanded(child: Text('screens_autoRestoreFloatingBallState'.tr)),
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
                          Text('screens_buttonCountColon'.tr),
                          Text('screens_buttonCount'.trParams({'count': _controller.buttonData.length.toString()})),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: () {
                          NavigationHelper.push(context, const FloatingButtonManagerScreen(),
                          ).then((_) => setState(() {}));
                        },
                        icon: const Icon(Icons.touch_app),
                        label: Text('screens_manageFloatingButtons'.tr),
                      ),
                    ],
                  ),
                ),
              ],
            )
          ),
          // 位置信息
          if (_controller.lastPosition != null)
            Card(
              child: ListTile(
                leading: const Icon(Icons.location_on),
                title: Text('screens_currentPosition'.tr),
                subtitle: Text(
                  'screens_xPositionYPosition'.trParams({'x': _controller.lastPosition!.x.toDouble().toStringAsFixed(0), 'y': _controller.lastPosition!.y.toDouble(.toStringAsFixed(0))})
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
