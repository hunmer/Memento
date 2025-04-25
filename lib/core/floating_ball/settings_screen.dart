import 'package:flutter/material.dart';
import 'floating_ball_manager.dart';

class FloatingBallSettingsScreen extends StatefulWidget {
  const FloatingBallSettingsScreen({Key? key}) : super(key: key);

  @override
  State<FloatingBallSettingsScreen> createState() => _FloatingBallSettingsScreenState();
}

class _FloatingBallSettingsScreenState extends State<FloatingBallSettingsScreen> {
  final FloatingBallManager _manager = FloatingBallManager();
  double _sizeScale = 1.0;
  final Map<FloatingBallGesture, String?> _selectedActions = {};
  
  // 从FloatingBallManager获取预定义动作列表
  List<String> get _availableActions => 
      _manager.getAllPredefinedActionTitles();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    // 加载悬浮球大小
    final scale = await _manager.getSizeScale();
    
    // 获取可用的动作列表
    final availableActions = _availableActions;
    
    // 加载当前设置的动作
    for (var gesture in FloatingBallGesture.values) {
      final actionTitle = _manager.getActionTitle(gesture);
      // 只设置存在于可用动作列表中的动作
      _selectedActions[gesture] = availableActions.contains(actionTitle) ? actionTitle : null;
    }
    
    if (mounted) {
      setState(() {
        _sizeScale = scale;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('悬浮球设置'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // 悬浮球大小设置
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '悬浮球大小',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text('小'),
                      Expanded(
                        child: Slider(
                          value: _sizeScale,
                          min: 0.5,
                          max: 1.5,
                          divisions: 10,
                          label: (_sizeScale * 100).round().toString() + '%',
                          onChanged: (value) {
                            setState(() {
                              _sizeScale = value;
                            });
                            _manager.saveSizeScale(value);
                          },
                        ),
                      ),
                      const Text('大'),
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
                  const Text(
                    '悬浮球手势动作',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  
                  // 为每种手势创建下拉选择框
                  ..._buildGestureActionSelectors(),
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
    final List<Widget> selectors = [];
    
    for (var gesture in FloatingBallGesture.values) {
      selectors.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Row(
            children: [
              SizedBox(
                width: 100,
                child: Text(_getGestureName(gesture)),
              ),
              Expanded(
                child: DropdownButton<String?>(
                  isExpanded: true,
                  value: _selectedActions[gesture],
                  hint: const Text('未设置'),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('无动作'),
                    ),
                    ..._availableActions.map((action) {
                      return DropdownMenuItem<String?>(
                        value: action,
                        child: Text(action),
                      );
                    }).toList(),
                  ],
                  onChanged: (value) async {
                    setState(() {
                      _selectedActions[gesture] = value;
                    });
                    
                    if (value != null) {
                      // 注册新动作
                      await _manager.registerAction(
                        gesture, 
                        value, 
                        () {}, // 空回调，实际回调将在setActionContext中设置
                      );
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
    switch (gesture) {
      case FloatingBallGesture.tap:
        return '单击';
      case FloatingBallGesture.swipeUp:
        return '上滑';
      case FloatingBallGesture.swipeDown:
        return '下滑';
      case FloatingBallGesture.swipeLeft:
        return '左滑';
      case FloatingBallGesture.swipeRight:
        return '右滑';
    }
  }
}