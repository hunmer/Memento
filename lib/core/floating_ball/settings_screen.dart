import 'package:flutter/material.dart';
import 'floating_ball_manager.dart';

class FloatingBallSettingsScreen extends StatefulWidget {
  const FloatingBallSettingsScreen({super.key});

  @override
  State<FloatingBallSettingsScreen> createState() => _FloatingBallSettingsScreenState();
}

class _FloatingBallSettingsScreenState extends State<FloatingBallSettingsScreen> {
  final FloatingBallManager _manager = FloatingBallManager();
  late Map<FloatingBallGesture, ActionInfo> _actions;
  double _sizeScale = 1.0;
  
  @override
  void initState() {
    super.initState();
    _actions = _manager.getAllActions();
    _loadSizeScale();
  }

  Future<void> _loadSizeScale() async {
    final scale = await _manager.getSizeScale();
    if (mounted) {
      setState(() {
        _sizeScale = scale;
      });
    }
  }
  
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
  
  String _getActionDescription(ActionInfo? actionInfo) {
    if (actionInfo == null) {
      return '未设置';
    }
    return actionInfo.title;
  }
  
  // 预定义的动作列表
  final List<({String title, Function(BuildContext) creator})> _predefinedActions = [
    (
      title: '显示提示消息',
      creator: (context) => (String message) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    ),
    (
      title: '返回上一页',
      creator: (context) => () {
        Navigator.of(context).pop();
      }
    ),
    (
      title: '返回首页',
      creator: (context) => () {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    ),
    (
      title: '刷新页面',
      creator: (context) => () {
        // 通知页面刷新，具体实现可能需要根据实际情况调整
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('页面已刷新')),
        );
      }
    ),
  ];
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('悬浮球设置'),
      ),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
            child: Text(
              '悬浮球大小',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                const Text('50%'),
                Expanded(
                  child: Slider(
                    value: _sizeScale,
                    min: 0.5,
                    max: 1.5,
                    divisions: 13,
                    label: '${(_sizeScale * 100).round()}%',
                    onChanged: (value) {
                      setState(() {
                        _sizeScale = value;
                      });
                      _manager.saveSizeScale(value);
                    },
                  ),
                ),
                const Text('150%'),
              ],
            ),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              '手势动作设置',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          ...FloatingBallGesture.values.map((gesture) {
            return ListTile(
              title: Text(_getGestureName(gesture)),
              subtitle: Text(_getActionDescription(_actions[gesture])),
              trailing: const Icon(Icons.edit),
              onTap: () {
                _showActionSelectionDialog(gesture);
              },
            );
          }).toList(),
        ],
      ),
    );
  }
  
  Future<void> _showActionSelectionDialog(FloatingBallGesture gesture) async {
    final result = await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('设置${_getGestureName(gesture)}动作'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ..._predefinedActions.map((action) {
                  return ListTile(
                    title: Text(action.title),
                    onTap: () async {
                      Navigator.of(dialogContext).pop(action);
                    },
                  );
                }).toList(),
                ListTile(
                  title: const Text('清除动作'),
                  onTap: () {
                    Navigator.of(dialogContext).pop('clear');
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('取消'),
            ),
          ],
        );
      },
    );
    
    // 处理对话框结果
    if (result != null) {
      if (result == 'clear') {
        await _manager.clearAction(gesture);
      } else if (result is ({String title, Function(BuildContext) creator})) {
        final gestureName = _getGestureName(gesture);
        final action = result;
        
        if (action.title == '显示提示消息') {
          await _manager.registerAction(
            gesture,
            '显示${gestureName}提示',
            () => action.creator(context)('${gestureName}手势'),
          );
        } else {
          await _manager.registerAction(
            gesture,
            action.title,
            action.creator(context),
          );
        }
      }
      
      if (mounted) {
        setState(() {
          _actions = _manager.getAllActions();
        });
      }
    }
  }
}