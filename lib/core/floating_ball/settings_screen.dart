import 'package:Memento/core/floating_ball/l10n/floating_ball_localizations.dart';
import 'package:flutter/material.dart';
import 'floating_ball_manager.dart';
import 'floating_ball_service.dart';

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

    // 加载当前设置的动作
    for (var gesture in FloatingBallGesture.values) {
      final actionTitle = _manager.getActionTitle(gesture);
      _selectedActions[gesture] = actionTitle;
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
                    l10n!.floatingBallSettings,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(l10n!.enableFloatingBall),
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
                    l10n!.floatingBallSettings,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Text(l10n!.small),
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
                      Text(l10n!.large),
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
                    l10n!.floatingBallSettings,
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
                    l10n!.resetPosition,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      _manager.resetPosition();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n!.positionReset)),
                      );
                    },
                    child: Text(l10n!.resetPosition),
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
                      child: Text(l10n!.noAction),
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
}
