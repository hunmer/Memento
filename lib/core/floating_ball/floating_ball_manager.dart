import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'floating_ball_service.dart';
import '../../dialogs/plugin_list_dialog.dart';
import '../plugin_manager.dart';

/// 悬浮球手势动作类型
enum FloatingBallGesture {
  tap, // 单击
  swipeUp, // 上滑
  swipeDown, // 下滑
  swipeLeft, // 左滑
  swipeRight, // 右滑
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
  // 默认启用状态
  bool _isEnabled = true;

  // 预定义的动作映射表
  static final Map<String, Function(BuildContext)> _predefinedActionCreators = {
    '打开上次插件':
        (context) => () {
          if (context.mounted) {
            // 获取当前打开的插件ID
            // 使用 Navigator.of(context).context 获取最上层路由的 context
            final navigatorContext = Navigator.of(context).context;
            String? currentPluginId =
                PluginManager.instance.getCurrentPluginId();
            if (currentPluginId == null) return;

            // 调用getLastOpenedPlugin时传递当前插件ID作为排除项
            final lastPlugin = PluginManager.instance.getLastOpenedPlugin(
              excludePluginId: currentPluginId,
            );
            if (lastPlugin != null) {
              PluginManager.instance.openPlugin(context, lastPlugin);
            } else {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('没有找到最近打开的插件')));
            }
          }
        },
    '选择打开插件':
        (context) => () {
          if (context.mounted) {
            showPluginListDialog(context);
          }
        },
    '显示提示消息':
        (context) => (String message) {
          if (context.mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(message)));
          }
        },
    '返回上一页':
        (context) => () {
          if (context.mounted) {
            Navigator.of(context).maybePop();
          }
        },
    '返回首页':
        (context) => () {
          if (context.mounted) {
            Navigator.of(context).popUntil((route) => route.isFirst);
          }
        },
    '刷新页面':
        (context) => () {
          if (context.mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('页面已刷新')));
          }
        },
  };

  // 加载保存的动作
  Future<void> _loadActions() async {
    final prefs = await _prefs;
    for (var gesture in FloatingBallGesture.values) {
      final key = 'floating_ball_action_${gesture.name}';
      final actionTitle = prefs.getString(key);
      if (actionTitle != null) {
        // 暂时不设置回调函数，等到需要时再设置
        _actions[gesture] = ActionInfo(actionTitle, () {});
      }
    }
    debugPrint('Loaded ${_actions.length} saved actions');
  }

  // 保存动作
  Future<void> _saveAction(
    FloatingBallGesture gesture,
    String? actionTitle,
  ) async {
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
    FloatingBallService().notifySizeChange(scale);
  }

  // 获取悬浮球启用状态
  Future<bool> isEnabled() async {
    final prefs = await _prefs;
    return prefs.getBool('floating_ball_enabled') ?? true;
  }

  // 保存悬浮球启用状态
  Future<void> setEnabled(bool enabled) async {
    _isEnabled = enabled;
    final prefs = await _prefs;
    await prefs.setBool('floating_ball_enabled', enabled);

    // 如果禁用，直接隐藏悬浮球
    if (!enabled) {
      FloatingBallService().hide();
    }
    // 注意：不在这里调用show()，而是让上层调用者决定是否显示
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
  Future<void> registerAction(
    FloatingBallGesture gesture,
    String title,
    Function callback,
  ) async {
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

  // 获取所有预定义动作标题
  List<String> getAllPredefinedActionTitles() {
    final List<String> titles = _predefinedActionCreators.keys.toList();
    // 添加自定义动作标题
    for (var action in _actions.values) {
      if (!titles.contains(action.title)) {
        titles.add(action.title);
      }
    }
    return titles;
  }

  // 清除动作
  Future<void> clearAction(FloatingBallGesture gesture) async {
    _actions.remove(gesture);
    await _saveAction(gesture, null);
  }

  // 设置动作的上下文
  void setActionContext(BuildContext context) {
    debugPrint('Setting action context with ${_actions.length} actions');

    // 更新所有已保存动作的回调函数
    for (var gesture in FloatingBallGesture.values) {
      final actionInfo = _actions[gesture];
      if (actionInfo != null) {
        if (_predefinedActionCreators.containsKey(actionInfo.title)) {
          final creator = _predefinedActionCreators[actionInfo.title]!;
          if (actionInfo.title == '显示提示消息') {
            final gestureName = _getGestureName(gesture);
            _actions[gesture] = ActionInfo(
              actionInfo.title,
              () => creator(context)('$gestureName手势'),
            );
          } else {
            _actions[gesture] = ActionInfo(actionInfo.title, creator(context));
          }
        } else {
          // 如果动作不在预定义列表中，设置一个默认的提示动作
          final gestureName = _getGestureName(gesture);
          _actions[gesture] = ActionInfo(actionInfo.title, () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('$gestureName手势 - ${actionInfo.title}')),
            );
          });
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

  // 初始化默认动作 - 只有在没有保存的动作时才设置默认动作
  Future<void> initDefaultActions(BuildContext context) async {
    // 等待加载保存的动作完成
    await _prefs;

    // 检查每个手势是否已有保存的动作，如果没有才设置默认动作
    for (var gesture in FloatingBallGesture.values) {
      if (!_actions.containsKey(gesture)) {
        switch (gesture) {
          case FloatingBallGesture.swipeUp:
            registerAction(gesture, '显示上滑提示', () {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('上滑')));
            });
            break;
          case FloatingBallGesture.swipeDown:
            registerAction(gesture, '显示下滑提示', () {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('下滑')));
            });
            break;
          case FloatingBallGesture.swipeLeft:
            registerAction(gesture, '显示左滑提示', () {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('左滑')));
            });
            break;
          case FloatingBallGesture.swipeRight:
            registerAction(gesture, '显示右滑提示', () {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('右滑')));
            });
            break;
          case FloatingBallGesture.tap:
            registerAction(gesture, '显示单击提示', () {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('单击')));
            });
            break;
        }
      }
    }

    debugPrint(
      'Initialized default actions for gestures without saved actions',
    );
  }
}
