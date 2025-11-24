import 'package:flutter/material.dart';
import '../plugin_base.dart';
import 'widgets/plugin_overlay_widget.dart';
import 'widgets/minimized_plugin_icon.dart';
import 'widgets/plugin_overlay_selector.dart';

/// 插件覆盖层管理器
/// 负责管理插件小窗口的显示、最小化和恢复状态
class PluginOverlayManager {
  static final PluginOverlayManager _instance = PluginOverlayManager._internal();
  factory PluginOverlayManager() => _instance;
  PluginOverlayManager._internal();

  /// 当前最小化的插件信息
  MinimizedPluginInfo? _minimizedPlugin;

  /// 是否已有最小化的插件
  bool get hasMinimizedPlugin => _minimizedPlugin != null;

  /// 获取最小化的插件信息
  MinimizedPluginInfo? get minimizedPlugin => _minimizedPlugin;

  /// 插件位置缓存（用于保存每个插件的最后一次位置）
  final Map<String, Offset> _pluginPositions = {};

  /// 显示插件覆盖层对话框
  void showPluginOverlay(BuildContext context, PluginBase plugin) {
    // 如果已有最小化的插件，先清理
    if (_minimizedPlugin != null) {
      _clearMinimizedPlugin();
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PluginOverlayWidget(
        plugin: plugin,
        onClose: () => _handleClose(context),
        onMinimize: () => _handleMinimize(context, plugin),
      ),
    );
  }

  /// 从选择对话框显示插件覆盖层
  void showPluginOverlayFromSelection(BuildContext context) {
    showPluginOverlayDialog(context);
  }

  /// 处理关闭
  void _handleClose(BuildContext context) {
    _clearMinimizedPlugin();
    Navigator.of(context).pop();
  }

  /// 处理最小化
  void _handleMinimize(BuildContext context, PluginBase plugin) {
    // 获取保存的插件位置，如果没有则使用默认位置
    final savedPosition = _pluginPositions[plugin.id] ?? Offset.zero;

    // 保存最小化的插件信息
    _minimizedPlugin = MinimizedPluginInfo(
      plugin: plugin,
      position: savedPosition,
    );

    // 关闭当前对话框
    Navigator.of(context).pop();

    // 显示最小化的图标
    _showMinimizedIcon(context);
  }

  /// 显示最小化的图标
  void _showMinimizedIcon(BuildContext context) {
    if (_minimizedPlugin == null) return;

    OverlayEntry? overlayEntry;
    final plugin = _minimizedPlugin!.plugin;

    overlayEntry = OverlayEntry(
      builder: (context) => MinimizedPluginIcon(
        plugin: plugin,
        initialX: _minimizedPlugin!.position.dx,
        initialY: _minimizedPlugin!.position.dy,
        onRestore: () {
          overlayEntry?.remove();
          _handleRestore(context);
        },
        onPositionChanged: (Offset newPosition) {
          // 保存插件的新位置
          _pluginPositions[plugin.id] = newPosition;

          // 同时更新当前最小化插件信息中的位置
          if (_minimizedPlugin != null && _minimizedPlugin!.plugin.id == plugin.id) {
            _minimizedPlugin = MinimizedPluginInfo(
              plugin: _minimizedPlugin!.plugin,
              position: newPosition,
            );
          }
        },
      ),
    );

    Overlay.of(context).insert(overlayEntry);
  }

  /// 处理恢复
  void _handleRestore(BuildContext context) {
    if (_minimizedPlugin == null) return;

    final plugin = _minimizedPlugin!.plugin;

    // 在清理之前，确保当前位置已经被保存
    // 注意：当前位置已经在 onPositionChanged 回调中保存了

    // 清理最小化状态
    _clearMinimizedPlugin();

    // 安全地关闭最小化图标对话框
    try {
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      // 忽略无法弹出时的错误
      debugPrint('Navigator.pop error in _handleRestore: $e');
    }

    // 显示恢复的覆盖层
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PluginOverlayWidget(
        plugin: plugin,
        onClose: () => _handleClose(context),
        onMinimize: () => _handleMinimize(context, plugin),
      ),
    );
  }

  /// 清理最小化的插件信息
  void _clearMinimizedPlugin() {
    _minimizedPlugin = null;
  }

  /// 强制清理所有状态（用于应用退出等场景）
  void dispose() {
    _clearMinimizedPlugin();
  }
}

/// 最小化插件信息
class MinimizedPluginInfo {
  final PluginBase plugin;
  final Offset position;

  MinimizedPluginInfo({
    required this.plugin,
    required this.position,
  });
}