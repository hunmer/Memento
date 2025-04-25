import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'floating_ball_service.dart';
import '../../dialogs/plugin_list_dialog.dart';

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
  FloatingBallManager._internal() {
    _loadActions();
  }

  final Map<FloatingBallGesture, ActionInfo> _actions = {};
  final _prefs = SharedPreferences.getInstance();

  // 默认位置
  Offset _position = const Offset(20, 100);
  // 默认大小比例 (100%)
  double _sizeScale = 1.0;

  // 预定义的动作映射表
  static final Map<String, Function(BuildContext)> _predefinedActionCreators = {
    '选择打开插件': (context) => () {
      if (context.mounted) {
        showPluginListDialog(context);
      }
    },
    '显示提示消息': (context) => (String message) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    },
    '返回上一页': (context) => () {
      if (context.mounted) {
        Navigator.of(context).maybePop();
      }
    },
    '返回首页': (context) => () {
      if (context.mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    },
    '刷新页面': (context) => () {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('页面已刷新')),
        );
      }
    },
  };

  // 加载保存的动作
  Future<void> _loadActions() async {
    final prefs = await _prefs;
    for (var gesture in FloatingBallGesture.values) {
      final key = 'floating_ball_action_${gesture.name}';
      final actionTitle = prefs.getString(key);
      if (actionTitle != null && _predefinedActionCreators.containsKey(actionTitle)) {
        // 暂时不设置回调函数，等到需要时再设置
        _actions[gesture] = ActionInfo(actionTitle, () {});
      }
    }
  }

  // 保存动作
  Future<void> _saveAction(FloatingBallGesture gesture, String? actionTitle) async {
    final prefs = await _prefs;
    final key = 'floating_ball_action_${gesture.name}';
    if (actionTitle != null) {
      await prefs.setString(key, actionTitle);
    } else {
      await prefs.remove(key);
    }
  }
  
  // 获取悬浮球大小比例
  Future<double> getSizeScale() async {
    final prefs = await _prefs;
    return prefs.getDouble('floating_ball_size_scale') ?? 1.0;
  }

  // 保存悬浮球大小比例
  Future<void> saveSizeScale(double scale) async {
    _sizeScale = scale;
    final prefs = await _prefs;
    await prefs.setDouble('floating_ball_size_scale', scale);
    
    // 通知悬浮球大小变化
    FloatingBallService()?.notifySizeChange(scale);
  }

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
  Future<void> registerAction(FloatingBallGesture gesture, String title, Function callback) async {
    _actions[gesture] = ActionInfo(title, callback);
    await _saveAction(gesture, title);
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
  Future<void> clearAction(FloatingBallGesture gesture) async {
    _actions.remove(gesture);
    await _saveAction(gesture, null);
  }

  // 设置动作的上下文
  void setActionContext(BuildContext context) {
    // 更新所有已保存动作的回调函数
    for (var gesture in FloatingBallGesture.values) {
      final actionInfo = _actions[gesture];
      if (actionInfo != null && _predefinedActionCreators.containsKey(actionInfo.title)) {
        final creator = _predefinedActionCreators[actionInfo.title]!;
        if (actionInfo.title == '显示提示消息') {
          final gestureName = _getGestureName(gesture);
          _actions[gesture] = ActionInfo(
            actionInfo.title,
            () => creator(context)('${gestureName}手势'),
          );
        } else {
          _actions[gesture] = ActionInfo(
            actionInfo.title,
            creator(context),
          );
        }
      }
    }
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