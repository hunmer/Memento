import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 悬浮球手势动作类型
enum FloatingBallGesture {
  tap,      // 单击
  swipeUp,  // 上滑
  swipeDown,// 下滑
  swipeLeft,// 左滑
  swipeRight,// 右滑
}

/// 动作信息类，包含动作标题和回调函数
class ActionInfo {
  final String title;
  final Function callback;
  
  ActionInfo(this.title, this.callback);
}

/// 悬浮球管理器
class FloatingBallManager {
  static final FloatingBallManager _instance = FloatingBallManager._internal();
  factory FloatingBallManager() => _instance;
  FloatingBallManager._internal();

  final Map<FloatingBallGesture, ActionInfo> _actions = {};
  final _prefs = SharedPreferences.getInstance();

  // 默认位置
  Offset _position = const Offset(20, 100);
  
  // 获取保存的位置
  Future<Offset> getPosition() async {
    final prefs = await _prefs;
    final double x = prefs.getDouble('floating_ball_x') ?? 20;
    final double y = prefs.getDouble('floating_ball_y') ?? 100;
    _position = Offset(x, y);
    return _position;
  }

  // 保存位置
  Future<void> savePosition(Offset position) async {
    _position = position;
    final prefs = await _prefs;
    await prefs.setDouble('floating_ball_x', position.dx);
    await prefs.setDouble('floating_ball_y', position.dy);
  }

  // 注册动作
  void registerAction(FloatingBallGesture gesture, String title, Function callback) {
    _actions[gesture] = ActionInfo(title, callback);
  }

  // 获取动作
  Function? getAction(FloatingBallGesture gesture) {
    return _actions[gesture]?.callback;
  }
  
  // 获取动作标题
  String? getActionTitle(FloatingBallGesture gesture) {
    return _actions[gesture]?.title;
  }

  // 获取所有动作
  Map<FloatingBallGesture, ActionInfo> getAllActions() {
    return Map.from(_actions);
  }

  // 清除动作
  void clearAction(FloatingBallGesture gesture) {
    _actions.remove(gesture);
  }

  // 初始化默认动作
  void initDefaultActions(BuildContext context) {
    registerAction(FloatingBallGesture.swipeUp, '显示上滑提示', () {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('上滑')),
      );
    });
    registerAction(FloatingBallGesture.swipeDown, '显示下滑提示', () {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('下滑')),
      );
    });
    registerAction(FloatingBallGesture.swipeLeft, '显示左滑提示', () {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('左滑')),
      );
    });
    registerAction(FloatingBallGesture.swipeRight, '显示右滑提示', () {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('右滑')),
      );
    });
    registerAction(FloatingBallGesture.tap, '显示单击提示', () {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('单击')),
      );
    });
    // 移除双击默认动作
  }
}