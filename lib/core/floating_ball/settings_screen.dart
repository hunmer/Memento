import 'package:Memento/core/floating_ball/l10n/floating_ball_localizations.dart';
import 'package:flutter/material.dart';
import 'package:Memento/core/services/toast_service.dart';
import '../action/action_manager.dart';
import '../action/widgets/action_selector_dialog.dart';
import 'floating_ball_manager.dart';
import 'floating_ball_service.dart';
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
  final ActionManager _actionManager = ActionManager();
  double _sizeScale = 1.0;
  bool _isEnabled = true;
  final Map<FloatingBallGesture, GestureActionConfig?> _selectedActions = {};

  @override
  void initState() {
    super.initState();
    // 初始化 ActionManager（如果尚未初始化）
    if (!_actionManager.isInitialized) {
      _actionManager.initialize().then((_) {
        if (mounted) {
          _loadSettings();
        }
      });
    } else {
      _loadSettings();
    }
  }

  Future<void> _loadSettings() async {
    // 加载悬浮球大小
    final scale = await _manager.getSizeScale();

    // 加载悬浮球启用状态
    final enabled = await _manager.isEnabled();

    // 从 ActionManager 加载手势动作配置
    for (var gesture in FloatingBallGesture.values) {
      final config = _actionManager.getGestureAction(gesture);
      _selectedActions[gesture] = config;
    }

    if (mounted) {
      setState(() {
        _sizeScale = scale;
        _isEnabled = enabled;
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
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {
                      _manager.resetPosition();
                      Toast.success(l10n.positionReset);
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
      if (gesture != FloatingBallGesture.longPress) {
        final config = _selectedActions[gesture];
        final displayText = _getGestureActionDisplayText(config);

        selectors.add(
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: Icon(_getGestureIcon(gesture), color: Colors.white),
              ),
              title: Text(_getGestureName(gesture)),
              subtitle: Text(
                displayText,
                style: TextStyle(
                  color: displayText == l10n!.notSet ? Colors.grey[600] : null,
                ),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                final result = await showDialog<ActionSelectorResult>(
                  context: context,
                  builder:
                      (context) => ActionSelectorDialog(
                        gesture: gesture,
                        initialValue:
                            config != null
                                ? ActionSelectorResult(
                                  singleAction: config.singleAction,
                                  actionGroup: config.group,
                                )
                                : null,
                      ),
                );

                if (result != null && mounted) {
                  setState(() {
                    if (result.isGroup && result.actionGroup != null) {
                      _selectedActions[gesture] = GestureActionConfig(
                        gesture: gesture,
                        group: result.actionGroup,
                      );
                    } else if (result.isSingleAction &&
                        result.singleAction != null) {
                      _selectedActions[gesture] = GestureActionConfig(
                        gesture: gesture,
                        singleAction: result.singleAction,
                      );
                    } else {
                      _selectedActions[gesture] = null;
                    }
                  });

                  // 保存到 ActionManager
                  final actionConfig = _selectedActions[gesture];
                  if (actionConfig != null) {
                    await _actionManager.setGestureAction(
                      gesture,
                      actionConfig,
                    );
                  } else {
                    await _actionManager.clearGestureAction(gesture);
                  }
                }
              },
            ),
          ),
        );
      }
    }

    return selectors;
  }

  /// 获取手势动作的显示文本
  String _getGestureActionDisplayText(GestureActionConfig? config) {
    if (config == null || config.isEmpty) {
      return '未设置';
    }

    if (config.singleAction != null) {
      return config.singleAction!.displayTitle;
    }

    if (config.group != null) {
      return '${config.group!.title} (${config.group!.actionCount}个动作)';
    }

    return '未设置';
  }

  /// 获取手势图标
  IconData _getGestureIcon(FloatingBallGesture gesture) {
    switch (gesture) {
      case FloatingBallGesture.tap:
        return Icons.touch_app;
      case FloatingBallGesture.doubleTap:
        return Icons.gesture;
      case FloatingBallGesture.longPress:
        return Icons.timer;
      case FloatingBallGesture.swipeUp:
        return Icons.keyboard_arrow_up;
      case FloatingBallGesture.swipeDown:
        return Icons.keyboard_arrow_down;
      case FloatingBallGesture.swipeLeft:
        return Icons.keyboard_arrow_left;
      case FloatingBallGesture.swipeRight:
        return Icons.keyboard_arrow_right;
    }
  }

  // 获取手势名称
  String _getGestureName(FloatingBallGesture gesture) {
    final l10n = FloatingBallLocalizations.of(context);
    switch (gesture) {
      case FloatingBallGesture.tap:
        return l10n!.tapGesture;
      case FloatingBallGesture.doubleTap:
        return l10n!.doubleTapGesture;
      case FloatingBallGesture.longPress:
        return l10n!.longPressGesture;
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
}
