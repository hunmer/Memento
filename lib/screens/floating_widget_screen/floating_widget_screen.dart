import 'dart:async';
import 'package:floating_ball_plugin/floating_ball_plugin.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
          // 悬浮窗权限
          ListTile(
            leading: Icon(
              _controller.hasPermission ? Icons.check_circle : Icons.error,
              color: _controller.hasPermission ? Colors.green : Colors.red,
            ),
            title: Text('screens_floatingWindowPermission'.tr),
            trailing:
                _controller.hasPermission
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
          // 其他选项只在悬浮球开启时显示
          if (_controller.isRunning) ...[
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
            // 选择图片
            ListTile(
              leading: const Icon(Icons.image),
              title: Text('screens_selectImageAsFloatingBall'.tr),
              trailing: const Icon(Icons.chevron_right),
              onTap: _pickAndSetImage,
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
            // 展开/合上动画
            ListTile(
              leading: const Icon(Icons.animation),
              title: Text('screens_expandAnimation'.tr),
              subtitle: Text('screens_expandAnimationDescription'.tr),
              trailing: AdaptiveSwitch(
                value: _controller.expandAnimationEnabled,
                onChanged: (value) async {
                  _controller.setExpandAnimationEnabled(value);
                  await _controller.updateConfig();
                  setState(() {});
                },
              ),
            ),
            const Divider(height: 1),
            // 大小设置
            ListTile(
              leading: const Icon(Icons.straighten),
              title: Text('screens_sizeColon'.tr),
              trailing: Text(
                'screens_ballSizeDp'.trParams({
                  'size': _controller.ballSize.round().toString(),
                }),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 72.0, right: 16.0),
              child: Slider(
                value: _controller.ballSize,
                min: 50,
                max: 150,
                divisions: 10,
                onChanged: (value) {
                  _controller.setBallSize(value);
                  setState(() {});
                },
                onChangeEnd: (value) async {
                  await _controller.updateConfig();
                },
              ),
            ),
            const Divider(height: 1),
            // 吸附阈值
            ListTile(
              leading: const Icon(Icons.vertical_align_center),
              title: Text('screens_snapThresholdColon'.tr),
              trailing: Text(
                'screens_snapThresholdPx'.trParams({
                  'threshold': _controller.snapThreshold.toString(),
                }),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 72.0, right: 16.0),
              child: Slider(
                value: _controller.snapThreshold.toDouble(),
                min: 20,
                max: 100,
                divisions: 8,
                onChanged: (value) {
                  _controller.setSnapThreshold(value.toInt());
                  setState(() {});
                },
                onChangeEnd: (value) async {
                  await _controller.updateConfig();
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
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.location_on),
                title: Text('screens_currentPosition'.tr),
                subtitle: Text(
                  'screens_xPositionYPosition'.trParams({
                    'x': _controller.lastPosition!.x.toDouble().toStringAsFixed(
                      0,
                    ),
                    'y': _controller.lastPosition!.y.toDouble().toStringAsFixed(
                      0,
                    ),
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
        ],
      ),
    );
  }

  /// 选择并设置图片（先显示预设对话框）
  Future<void> _pickAndSetImage() async {
    if (!mounted) return;

    // 先显示预设对话框
    final selectedStyle = await _showPresetStyleDialog();
    if (selectedStyle == null) return; // 用户取消

    try {
      Uint8List? bytes;

      if (selectedStyle == 'pick_from_gallery') {
        // 从相册选择
        final XFile? image = await _picker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 80,
        );
        if (image == null) return;
        bytes = await image.readAsBytes();
      } else if (selectedStyle.startsWith('preset_')) {
        // 使用预设图片
        final presetPath =
            'assets/floating_ball_icons/${selectedStyle.replaceFirst('preset_', '')}.png';
        final byteData = await rootBundle.load(presetPath);
        bytes = byteData.buffer.asUint8List();
      }

      if (bytes == null || !mounted) return;

      // 设置悬浮球图片
      final result = await _controller.setCustomImage(bytes);
      if (result != null && mounted) {
        _showMessage(result);
      } else if (mounted) {
        _showMessage('screens_floatingBallImageSet'.tr);
        setState(() {}); // 刷新UI
      }
    } catch (e) {
      if (mounted) {
        _showMessage('选择图片失败: $e');
      }
    }
  }

  /// 显示预设样式选择对话框
  Future<String?> _showPresetStyleDialog() async {
    return showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('screens_selectPresetStyle'.tr),
            content: SizedBox(
              width: 300,
              child: GridView.count(
                shrinkWrap: true,
                crossAxisCount: 3,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                children: [
                  // 预设图片
                  _buildPresetItem(
                    'preset_1',
                    '预设1',
                    'assets/floating_ball_icons/1.png',
                  ),
                  // 最后一个：从相册选择
                  _buildPresetItem(
                    'pick_from_gallery',
                    'screens_fromGallery'.tr,
                    null,
                    isGallery: true,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('screens_cancel'.tr),
              ),
            ],
          ),
    );
  }

  /// 构建预设样式选项
  Widget _buildPresetItem(
    String id,
    String label,
    String? assetPath, {
    bool isGallery = false,
  }) {
    return GestureDetector(
      onTap: () => Navigator.pop(context, id),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color:
                  isGallery
                      ? Theme.of(context).colorScheme.primaryContainer
                      : null,
              border: Border.all(
                color: Theme.of(context).colorScheme.outline,
                width: 1,
              ),
            ),
            child:
                assetPath != null
                    ? ClipOval(
                      child: Image.asset(
                        assetPath,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (context, error, stackTrace) => Icon(
                              Icons.image_not_supported,
                              size: 30,
                              color: Theme.of(context).colorScheme.outline,
                            ),
                      ),
                    )
                    : Icon(
                      isGallery ? Icons.photo_library : Icons.image,
                      size: 30,
                      color:
                          isGallery
                              ? Theme.of(context).colorScheme.onPrimaryContainer
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// 显示消息
  void _showMessage(String message) {
    if (mounted) {
      Toast.info(message, duration: const Duration(seconds: 2));
    }
  }
}
