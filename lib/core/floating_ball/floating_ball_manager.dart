import 'dart:core';
import 'dart:convert';
import 'dart:io';
import 'package:Memento/core/storage/storage_manager.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
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
  // 默认位置
  Offset _position = const Offset(20, 100);
  // 默认大小比例 (100%)
  // 默认启用状态
  // 存储文件路径
  File? _storageFile;

  // 预定义的动作映射表
  static final Map<String, Function(BuildContext)> _predefinedActionCreators = {
    '打开上次插件':
        (context) => () {
          if (context.mounted) {
            final String? currentPluginId =
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

  // 获取存储文件
  Future<File> _getStorageFile() async {
    if (_storageFile != null) return _storageFile!;
    final directory = await StorageManager.getApplicationDocumentsDirectory();
    _storageFile = File('${directory.path}/floating_ball_config.json');
    if (!await _storageFile!.exists()) {
      await _storageFile!.writeAsString('{}');
    }
    return _storageFile!;
  }

  // 读取数据
  Future<Map<String, dynamic>> _readData() async {
    try {
      final file = await _getStorageFile();
      if (!await file.exists()) {
        return {
          'actions': {},
          'size_scale': 0.6,
          'position': {'x': 21.0, 'y': 99.0},
          'enabled': true,
        };
      }

      final content = await file.readAsString();
      if (content.trim().isEmpty) {
        return {
          'actions': {},
          'size_scale': 0.6,
          'position': {'x': 21.0, 'y': 99.0},
          'enabled': true,
        };
      }

      final decoded = json.decode(content) as Map<String, dynamic>;
      return decoded;
    } catch (e) {
      debugPrint('Error reading floating ball data: $e');
      // 返回默认配置
      return {
        'actions': {},
        'size_scale': 0.6,
        'position': {'x': 21.0, 'y': 99.0},
        'enabled': true,
      };
    }
  }

  // 写入数据
  Future<void> _writeData(Map<String, dynamic> data) async {
    final file = await _getStorageFile();
    await file.writeAsString(json.encode(data));
  }

  // 加载保存的动作
  Future<void> _loadActions() async {
    final data = await _readData();
    final actions = data['actions'] as Map<String, dynamic>? ?? {};
    for (var gesture in FloatingBallGesture.values) {
      final actionTitle = actions[gesture.name];
      if (actionTitle != null) {
        _actions[gesture] = ActionInfo(actionTitle.toString(), () {});
      }
    }
    debugPrint('Loaded ${_actions.length} saved actions');
  }

  // 保存动作
  Future<void> _saveAction(
    FloatingBallGesture gesture,
    String? actionTitle,
  ) async {
    final data = await _readData();
    var actions = data['actions'] as Map<String, dynamic>? ?? {};
    if (actionTitle != null) {
      actions[gesture.name] = actionTitle;
    } else {
      actions.remove(gesture.name);
    }
    data['actions'] = actions;
    await _writeData(data);
  }

  // 获取悬浮球大小比例
  Future<double> getSizeScale() async {
    final data = await _readData();
    return (data['size_scale'] as num?)?.toDouble() ?? 1.0;
  }

  // 保存悬浮球大小比例
  Future<void> saveSizeScale(double scale) async {
    final data = await _readData();
    data['size_scale'] = scale;
    await _writeData(data);

    // 通知悬浮球大小变化
    FloatingBallService().notifySizeChange(scale);
  }

  // 获取悬浮球启用状态
  Future<bool> isEnabled() async {
    final data = await _readData();
    return (data['enabled'] as bool?) ?? true;
  }

  // 保存悬浮球启用状态
  Future<void> setEnabled(bool enabled) async {
    final data = await _readData();
    data['enabled'] = enabled;
    await _writeData(data);

    // 如果禁用，直接隐藏悬浮球
    if (!enabled) {
      FloatingBallService().hide();
    }
  }

  // 获取保存的位置
  Future<Offset> getPosition() async {
    final data = await _readData();
    final position = data['position'] as Map<String, dynamic>? ?? {};
    final double x = (position['x'] as num?)?.toDouble() ?? 20;
    final double y = (position['y'] as num?)?.toDouble() ?? 100;
    _position = Offset(x, y);
    return _position;
  }

  // 保存位置
  Future<void> savePosition(Offset position) async {
    _position = position;
    final data = await _readData();
    data['position'] = {'x': position.dx, 'y': position.dy};
    await _writeData(data);
  }

  // 设置动作
  Future<void> setAction(
    FloatingBallGesture gesture,
    String title,
    final Function() callback,
  ) async {
    _actions[gesture] = ActionInfo(title, callback);
    await _saveAction(gesture, title);
  }

  // 获取动作
  Function()? getAction(FloatingBallGesture gesture) {
    return _actions[gesture]?.callback as Function()?;
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
          _actions[gesture] = ActionInfo(actionInfo.title, creator(context));
        }
      }
    }
  }

  // 重置悬浮球位置到默认值
  Future<void> resetPosition() async {
    const defaultPosition = Offset(20, 100);
    _position = defaultPosition;
    final data = await _readData();
    data['position'] = {'x': defaultPosition.dx, 'y': defaultPosition.dy};
    await _writeData(data);

    // 通知悬浮球服务更新位置
    FloatingBallService().updatePosition(defaultPosition);
  }
}
