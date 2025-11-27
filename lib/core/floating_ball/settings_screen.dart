import 'package:Memento/core/floating_ball/l10n/floating_ball_localizations.dart';
import 'package:flutter/material.dart';
import 'floating_ball_manager.dart';
import 'floating_ball_service.dart';
import 'overlay_window_manager.dart';
import 'models/floating_ball_gesture.dart';

class FloatingBallSettingsScreen extends StatefulWidget {
  const FloatingBallSettingsScreen({super.key});

  @override
  State<FloatingBallSettingsScreen> createState() =>
      _FloatingBallSettingsScreenState();
}

class _FloatingBallSettingsScreenState
    extends State<FloatingBallSettingsScreen> {
  final FloatingBallManager _manager = FloatingBallManager();
  double _sizeScale = 1.0;
  bool _isEnabled = true;
  bool _enableOverlayWindow = false;
  bool _coexistMode = false;
  final Map<FloatingBallGesture, String?> _selectedActions = {};

  // 从FloatingBallManager获取预定义动作列表
  List<String> get _availableActions => _manager.getAllPredefinedActionTitles();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    // 加载悬浮球大小
    final scale = await _manager.getSizeScale();

    // 加载悬浮球启用状态
    final enabled = await _manager.isEnabled();

    // 加载overlay窗口设置
    final overlayConfig = await _manager.getOverlayWindowConfig();
    final enableOverlayWindow = overlayConfig['enableOverlayWindow'] as bool;
    final coexistMode = overlayConfig['coexistMode'] as bool;

    // 加载当前设置的动作
    for (var gesture in FloatingBallGesture.values) {
      final actionTitle = _manager.getActionTitle(gesture);
      _selectedActions[gesture] = actionTitle;
    }

    if (mounted) {
      setState(() {
        _sizeScale = scale;
        _isEnabled = enabled;
        _enableOverlayWindow = enableOverlayWindow;
        _coexistMode = coexistMode;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = FloatingBallLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n!.floatingBallSettings)),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // 悬浮球启用开关
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.floatingBallSettings,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(l10n.enableFloatingBall),
                      Switch(
                        value: _isEnabled,
                        onChanged: (value) async {
                          setState(() {
                            _isEnabled = value;
                          });
                          await _manager.setEnabled(value);

                          // 如果启用悬浮球，则显示悬浮球
                          if (value) {
                            FloatingBallService().show(context);
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Overlay窗口悬浮球设置
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Overlay窗口悬浮球',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '在应用外部显示的悬浮球，可以在任何界面使用',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 16),

                  // 启用Overlay窗口开关
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('启用Overlay窗口'),
                      Switch(
                        value: _enableOverlayWindow,
                        onChanged: (value) async {
                          setState(() {
                            _enableOverlayWindow = value;
                            // 如果启用overlay窗口，自动启用共存模式
                            if (value) {
                              _coexistMode = true;
                            }
                          });
                          // TODO: 保存到配置
                          await _saveOverlayWindowConfig(value, _coexistMode);

                          // TODO: 显示或隐藏overlay窗口悬浮球
                          if (value) {
                            // _showOverlayWindowFloatingBall();
                          } else {
                            // _hideOverlayWindowFloatingBall();
                          }
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // 共存模式开关
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('允许双悬浮球共存'),
                      Switch(
                        value: _coexistMode,
                        onChanged: (value) async {
                          setState(() {
                            _coexistMode = value;
                            // 如果启用overlay窗口但禁用共存模式，需要提示用户
                            if (_enableOverlayWindow && !value) {
                              _showCoexistModeWarning();
                            }
                          });
                          // TODO: 保存到配置
                          await _saveOverlayWindowConfig(_enableOverlayWindow, value);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 悬浮球大小设置
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.floatingBallSettings,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Text(l10n.small),
                      Expanded(
                        child: Slider(
                          value: _sizeScale,
                          min: 0.5,
                          max: 1.5,
                          divisions: 10,
                          label: '${(_sizeScale * 100).round()}%',
                          onChanged: (value) {
                            setState(() {
                              _sizeScale = value;
                            });
                            _manager.saveSizeScale(value);
                          },
                        ),
                      ),
                      Text(l10n.large),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 悬浮球动作设置
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.floatingBallSettings,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  // 为每种手势创建下拉选择框
                  ..._buildGestureActionSelectors(),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 重置位置按钮
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.resetPosition,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      _manager.resetPosition();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.positionReset)),
                      );
                    },
                    child: Text(l10n.resetPosition),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 构建所有手势动作选择器
  List<Widget> _buildGestureActionSelectors() {
    final l10n = FloatingBallLocalizations.of(context);
    final List<Widget> selectors = [];

    for (var gesture in FloatingBallGesture.values) {
      selectors.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Row(
            children: [
              SizedBox(width: 100, child: Text(_getGestureName(gesture))),
              Expanded(
                child: DropdownButton<String?>(
                  isExpanded: true,
                  value: _selectedActions[gesture],
                  hint: Text(l10n!.notSet),
                  items: [
                    DropdownMenuItem<String?>(
                      value: null,
                      child: Text(l10n.noAction),
                    ),
                    ..._availableActions.map((action) {
                      return DropdownMenuItem<String?>(
                        value: action,
                        child: Text(action),
                      );
                    }),
                  ],
                  onChanged: (value) async {
                    setState(() {
                      _selectedActions[gesture] = value;
                    });

                    if (value != null) {
                      // 注册新动作
                      await _manager.setAction(
                        gesture,
                        value,
                        () {}, // 空回调，实际回调将在setActionContext中设置
                      );

                      // 立即更新上下文以应用新动作
                      _manager.setActionContext(context);
                    } else {
                      // 清除动作
                      await _manager.clearAction(gesture);
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      );
    }

    return selectors;
  }

  // 获取手势名称
  String _getGestureName(FloatingBallGesture gesture) {
    final l10n = FloatingBallLocalizations.of(context);
    switch (gesture) {
      case FloatingBallGesture.tap:
        return l10n!.tapGesture;
      case FloatingBallGesture.swipeUp:
        return l10n!.swipeUpGesture;
      case FloatingBallGesture.swipeDown:
        return l10n!.swipeDownGesture;
      case FloatingBallGesture.swipeLeft:
        return l10n!.swipeLeftGesture;
      case FloatingBallGesture.swipeRight:
        return l10n!.swipeRightGesture;
    }
  }

  // 保存overlay窗口配置
  Future<void> _saveOverlayWindowConfig(bool enableOverlayWindow, bool coexistMode) async {
    await _manager.saveOverlayWindowConfig(
      enableOverlayWindow: enableOverlayWindow,
      coexistMode: coexistMode,
    );

    // 如果启用overlay窗口，立即显示它
    if (enableOverlayWindow) {
      await _showOverlayWindowFloatingBall();
    } else {
      await _hideOverlayWindowFloatingBall();
    }
  }

  // 显示overlay窗口悬浮球
  Future<void> _showOverlayWindowFloatingBall() async {
    try {
      final manager = OverlayWindowManager();
      await manager.showFloatingBall(context);
    } catch (e) {
      debugPrint('Failed to show overlay window floating ball: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('显示全局悬浮球失败: $e')),
      );
    }
  }

  // 隐藏overlay窗口悬浮球
  Future<void> _hideOverlayWindowFloatingBall() async {
    try {
      final manager = OverlayWindowManager();
      await manager.hideFloatingBall();
    } catch (e) {
      debugPrint('Failed to hide overlay window floating ball: $e');
    }
  }

  // 显示共存模式警告
  void _showCoexistModeWarning() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('提示'),
          content: Text('您启用了Overlay窗口悬浮球，禁用共存模式将隐藏应用内悬浮球。\n\n确定要继续吗？'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // 恢复开关状态
                setState(() {
                  _coexistMode = true;
                });
              },
              child: Text('取消'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // 确认禁用overlay窗口
                setState(() {
                  _enableOverlayWindow = false;
                  _coexistMode = false;
                });
                _saveOverlayWindowConfig(false, false);
              },
              child: Text('确认'),
            ),
          ],
        );
      },
    );
  }
}
