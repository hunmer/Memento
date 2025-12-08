import 'dart:core';
import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:Memento/core/floating_ball/l10n/floating_ball_localizations.dart';
import 'package:Memento/core/storage/storage_manager.dart';
import 'package:flutter/material.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
import 'package:Memento/core/services/toast_service.dart';
import 'floating_ball_service.dart';
import 'package:Memento/dialogs/plugin_list_dialog.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/core/route/route_history_manager.dart';
import 'package:Memento/widgets/route_history_dialog/route_history_dialog.dart';
import 'package:Memento/plugins/agent_chat/agent_chat_plugin.dart';
import 'package:Memento/plugins/agent_chat/screens/tool_template_screen/tool_template_screen.dart';
import 'package:Memento/plugins/agent_chat/screens/tool_management_screen/tool_management_screen.dart';
import 'models/floating_ball_gesture.dart';

/// 动作信息类，包含动作标题和回调函数
class ActionInfo {
  final String title;
  final Function callback;

  ActionInfo(this.title, this.callback);
}

/// 悬浮球大小变化回调
typedef SizeChangeCallback = void Function(double newSize);

/// 悬浮球管理器
class FloatingBallManager {
  static final FloatingBallManager _instance = FloatingBallManager._internal();
  factory FloatingBallManager() => _instance;
  FloatingBallManager._internal() {
    _loadActions().then((_) => _initCompleter.complete());
  }

  final Map<FloatingBallGesture, ActionInfo> _actions = {};
  // 默认位置
  Offset _position = const Offset(20, 100);
  // 默认大小比例 (100%)
  // 默认启用状态
  // 存储文件路径
  File? _storageFile;

  // 初始化完成器，确保数据加载完成
  final Completer<void> _initCompleter = Completer<void>();

  // 写入锁，防止并发写入导致数据覆盖
  bool _isWriting = false;

  // 大小变化回调列表
  final List<SizeChangeCallback> _sizeChangeCallbacks = [];

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
              Toast.info(FloatingBallLocalizations.of(context)!.noRecentPlugin);
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
            Toast.success(FloatingBallLocalizations.of(context)!.pageRefreshed);
          }
        },
    '路由历史记录':
        (context) => () {
          if (context.mounted) {
            showDialog(
              context: context,
              builder: (context) => const RouteHistoryDialog(),
            );
          }
        },
    '打开上个路由':
        (context) => () async {
          if (context.mounted) {
            final lastPage = RouteHistoryManager.getLastVisitedPage();
            if (lastPage != null) {
              await _reopenPage(context, lastPage);
            } else {
              Toast.info('没有历史记录');
            }
          }
        },
  };

  /// 根据页面记录重新打开页面
  static Future<void> _reopenPage(
    BuildContext context,
    dynamic lastPage,
  ) async {
    if (!context.mounted) return;

    // 记录访问历史
    RouteHistoryManager.recordPageVisit(
      pageId: lastPage.pageId,
      title: lastPage.title,
      icon: lastPage.icon,
    );

    switch (lastPage.pageId) {
      case 'tool_template':
        await NavigationHelper.push(context, ToolTemplateScreen(
                  templateService: AgentChatPlugin.instance.templateService,),
        );
        break;
      case 'tool_management':
        await NavigationHelper.push(context, const ToolManagementScreen(),
        );
        break;
      default:
        if (context.mounted) {
          Toast.error('未知页面类型: ${lastPage.pageId}');
        }
    }
  }

  static get noRecentPlugin => null;

  // 获取存储文件
  Future<File> _getStorageFile() async {
    if (_storageFile != null) return _storageFile!;
    final directory = await StorageManager.getApplicationDocumentsDirectory();
    _storageFile = File('${directory.path}/floating_ball_config.json');
    if (!await _storageFile!.exists()) {
      // 写入完整的默认配置而不是空对象
      await _storageFile!.writeAsString(json.encode(_getDefaultConfig()));
    }
    return _storageFile!;
  }

  // 确保初始化完成
  Future<void> _ensureInitialized() async {
    if (!_initCompleter.isCompleted) {
      await _initCompleter.future;
    }
  }

  // 获取默认配置
  Map<String, dynamic> _getDefaultConfig() {
    return {
      'actions': {},
      'size_scale': 0.6,
      'position': {'x': 21.0, 'y': 99.0},
      'enabled': true,
    };
  }

  // 验证配置完整性
  bool _isConfigValid(Map<String, dynamic> config) {
    return config.containsKey('actions') &&
        config.containsKey('size_scale') &&
        config.containsKey('position') &&
        config.containsKey('enabled');
  }

  // 合并配置与默认值
  Map<String, dynamic> _mergeWithDefaults(Map<String, dynamic> config) {
    final defaults = _getDefaultConfig();
    return {
      'actions': config['actions'] ?? defaults['actions'],
      'size_scale': config['size_scale'] ?? defaults['size_scale'],
      'position': config['position'] ?? defaults['position'],
      'enabled': config['enabled'] ?? defaults['enabled'],
    };
  }

  // 安全写入数据，带锁机制防止竞态条件
  Future<void> _writeDataSafe(Map<String, dynamic> data) async {
    // 等待其他写入操作完成
    while (_isWriting) {
      await Future.delayed(const Duration(milliseconds: 10));
    }

    _isWriting = true;
    try {
      final file = await _getStorageFile();
      await file.writeAsString(json.encode(data));
    } finally {
      _isWriting = false;
    }
  }

  // 读取数据
  Future<Map<String, dynamic>> _readData() async {
    try {
      final file = await _getStorageFile();
      if (!await file.exists()) {
        return _getDefaultConfig();
      }

      final content = await file.readAsString();
      if (content.trim().isEmpty) {
        return _getDefaultConfig();
      }

      final decoded = json.decode(content) as Map<String, dynamic>;

      // 验证配置完整性
      if (!_isConfigValid(decoded)) {
        debugPrint('Invalid config detected, merging with defaults');
        return _mergeWithDefaults(decoded);
      }

      return decoded;
    } catch (e) {
      debugPrint('Error reading floating ball data: $e');

      // 尝试备份损坏的文件
      try {
        final file = await _getStorageFile();
        if (await file.exists()) {
          final backupPath =
              '${file.path}.backup_${DateTime.now().millisecondsSinceEpoch}';
          await file.copy(backupPath);
          debugPrint('Corrupted config backed up to: $backupPath');
        }
      } catch (backupError) {
        debugPrint('Failed to backup corrupted config: $backupError');
      }

      // 返回默认配置
      return _getDefaultConfig();
    }
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

    // 为tap手势设置默认动作（如果没有配置的话）
    if (!_actions.containsKey(FloatingBallGesture.tap)) {
      _actions[FloatingBallGesture.tap] = ActionInfo('选择打开插件', () {
        // 这个回调会在setActionContext中被正确设置
      });
    }
  }

  // 保存动作
  Future<void> _saveAction(
    FloatingBallGesture gesture,
    String? actionTitle,
  ) async {
    await _ensureInitialized();
    final data = await _readData();
    var actions = data['actions'] as Map<String, dynamic>? ?? {};
    if (actionTitle != null) {
      actions[gesture.name] = actionTitle;
    } else {
      actions.remove(gesture.name);
    }
    data['actions'] = actions;
    await _writeDataSafe(data);
  }

  // 获取悬浮球大小比例
  Future<double> getSizeScale() async {
    await _ensureInitialized();
    final data = await _readData();
    return (data['size_scale'] as num?)?.toDouble() ?? 1.0;
  }

  // 保存悬浮球大小比例
  Future<void> saveSizeScale(double scale) async {
    await _ensureInitialized();
    final data = await _readData();
    data['size_scale'] = scale;
    await _writeDataSafe(data);

    // 通知悬浮球大小变化
    FloatingBallService().notifySizeChange(scale);

    // 通知所有注册的回调
    _notifySizeChange(scale);
  }

  // 获取悬浮球启用状态
  Future<bool> isEnabled() async {
    await _ensureInitialized();
    final data = await _readData();
    return (data['enabled'] as bool?) ?? true;
  }

  // 保存悬浮球启用状态
  Future<void> setEnabled(bool enabled) async {
    await _ensureInitialized();
    final data = await _readData();
    data['enabled'] = enabled;
    await _writeDataSafe(data);

    // 如果禁用，直接隐藏悬浮球
    if (!enabled) {
      FloatingBallService().hide();
    }
  }

  // 获取保存的位置
  Future<Offset> getPosition() async {
    await _ensureInitialized();
    final data = await _readData();
    final position = data['position'] as Map<String, dynamic>? ?? {};
    final double x = (position['x'] as num?)?.toDouble() ?? 20;
    final double y = (position['y'] as num?)?.toDouble() ?? 100;
    _position = Offset(x, y);
    return _position;
  }

  // 保存位置
  Future<void> savePosition(Offset position) async {
    await _ensureInitialized();
    _position = position;
    final data = await _readData();
    data['position'] = {'x': position.dx, 'y': position.dy};
    await _writeDataSafe(data);
  }

  // 设置动作
  Future<void> setAction(
    FloatingBallGesture gesture,
    String title,
    final Function() callback,
  ) async {
    await _ensureInitialized();
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
    await _ensureInitialized();
    _actions.remove(gesture);
    await _saveAction(gesture, null);
  }

  // 设置动作的上下文
  void setActionContext(BuildContext context) {
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
    await _ensureInitialized();
    const defaultPosition = Offset(20, 100);
    _position = defaultPosition;
    final data = await _readData();
    data['position'] = {'x': defaultPosition.dx, 'y': defaultPosition.dy};
    await _writeDataSafe(data);

    // 通知悬浮球服务更新位置
    FloatingBallService().updatePosition(defaultPosition);
  }

  // 添加大小变化回调
  void addSizeChangeCallback(SizeChangeCallback callback) {
    _sizeChangeCallbacks.add(callback);
  }

  // 移除大小变化回调
  void removeSizeChangeCallback(SizeChangeCallback callback) {
    _sizeChangeCallbacks.remove(callback);
  }

  // 通知所有大小变化回调
  void _notifySizeChange(double newScale) {
    for (var callback in _sizeChangeCallbacks) {
      try {
        callback(newScale);
      } catch (e) {
        debugPrint('Error in size change callback: $e');
      }
    }
  }
}
