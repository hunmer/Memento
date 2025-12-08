import 'package:flutter/material.dart';
import 'package:Memento/core/plugin_base.dart';
import 'widgets/plugin_overlay_widget.dart';
import 'widgets/minimized_plugin_icon.dart';
import 'widgets/plugin_overlay_selector.dart';

/// 插件覆盖层管理器
/// 负责管理插件小窗口的显示、最小化和恢复状态
class PluginOverlayManager {
  static final PluginOverlayManager _instance = PluginOverlayManager._internal();
  factory PluginOverlayManager() => _instance;
  PluginOverlayManager._internal();

  /// 当前所有最小化的插件信息（按插件ID索引）
  final Map<String, MinimizedPluginInfo> _minimizedPlugins = {};

  /// 是否已有最小化的插件
  bool get hasMinimizedPlugin => _minimizedPlugins.isNotEmpty;

  /// 获取所有最小化的插件信息
  List<MinimizedPluginInfo> get minimizedPlugins => _minimizedPlugins.values.toList();

  /// 获取指定插件的最小化信息
  MinimizedPluginInfo? getMinimizedPlugin(String pluginId) => _minimizedPlugins[pluginId];

  /// 获取当前活跃的最小化插件（最后添加的）
  MinimizedPluginInfo? get lastMinimizedPlugin =>
      _minimizedPlugins.isEmpty ? null : _minimizedPlugins.values.last;

  /// 插件位置缓存（用于保存每个插件的最后一次位置）
  final Map<String, Offset> _pluginPositions = {};

  /// 最小化插件的覆盖层条目（按插件ID索引）
  final Map<String, OverlayEntry> _minimizedOverlayEntries = {};

  /// 显示插件覆盖层对话框
  void showPluginOverlay(BuildContext context, PluginBase plugin) {
    // 如果当前插件已经最小化，则恢复它
    if (_minimizedPlugins.containsKey(plugin.id)) {
      _restoreMinimizedPlugin(context, plugin.id);
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PluginOverlayWidget(
        plugin: plugin,
        onClose: () => _handleClose(context, plugin),
        onMinimize: () => _handleMinimize(context, plugin),
      ),
    );
  }

  /// 从选择对话框显示插件覆盖层
  void showPluginOverlayFromSelection(BuildContext context) {
    showPluginOverlayDialog(context);
  }

  /// 处理关闭
  void _handleClose(BuildContext context, PluginBase plugin) {
    try {
      // 只移除当前插件的最小化状态（如果存在）
      _removeMinimizedPlugin(plugin.id);
      Navigator.of(context).pop();
    } catch (e) {
      debugPrint('Error in _handleClose: $e');
    }
  }

  /// 处理最小化
  void _handleMinimize(BuildContext context, PluginBase plugin) {
    // 如果插件已经最小化，则不重复处理
    if (_minimizedPlugins.containsKey(plugin.id)) {
      Navigator.of(context).pop();
      return;
    }

    // 获取保存的插件位置，如果没有则使用合理的默认位置
    Offset savedPosition;
    try {
      final cachedPosition = _pluginPositions[plugin.id];
      if (cachedPosition != null && !cachedPosition.dx.isNaN && !cachedPosition.dy.isNaN) {
        savedPosition = cachedPosition;
      } else {
        savedPosition = _getSafeDefaultPosition(context, pluginId: plugin.id);
      }
    } catch (e) {
      debugPrint('Error getting saved position: $e');
      savedPosition = _getSafeDefaultPosition(context, pluginId: plugin.id);
    }

    // 保存最小化的插件信息
    _minimizedPlugins[plugin.id] = MinimizedPluginInfo(
      plugin: plugin,
      position: savedPosition,
    );

    // 先获取一个有效的 Navigator，然后再关闭对话框
    final navigator = Navigator.of(context);

    // 延迟到下一帧执行，确保当前对话框完全关闭
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        // 关闭当前对话框
        if (navigator.canPop()) {
          navigator.pop();
        }

        // 显示最小化的图标
        _showMinimizedIcon(context, plugin);
      } catch (e) {
        debugPrint('Error in minimize callback: $e');
      }
    });
  }

  /// 获取安全的默认位置（避免使用 Offset.zero 并防止重叠）
  Offset _getSafeDefaultPosition(BuildContext context, {String? pluginId}) {
    try {
      final screenSize = MediaQuery.of(context).size;
      const iconSize = 60.0;
      const margin = 20.0;

      // 如果没有指定插件ID，使用默认位置
      if (pluginId == null) {
        return Offset(
          screenSize.width - iconSize - margin,
          screenSize.height - iconSize - margin,
        );
      }

      // 计算当前已最小化的插件数量
      final currentIndex = _minimizedPlugins.keys.toList().indexOf(pluginId);

      // 计算位置，从右下角开始向左排列
      final iconsPerRow = (screenSize.width / (iconSize + margin)).floor();
      final row = currentIndex ~/ iconsPerRow;
      final col = currentIndex % iconsPerRow;

      final baseX = screenSize.width - iconSize - margin;
      final baseY = screenSize.height - iconSize - margin;

      final x = baseX - col * (iconSize + margin);
      final y = baseY - row * (iconSize + margin);

      return Offset(
        x.clamp(margin, screenSize.width - iconSize - margin),
        y.clamp(margin, screenSize.height - iconSize - margin),
      );
    } catch (e) {
      // 如果获取屏幕尺寸失败，返回一个保守的默认位置
      return const Offset(100, 100);
    }
  }

  /// 显示最小化的图标
  void _showMinimizedIcon(BuildContext context, PluginBase plugin) {
    final minimizedInfo = _minimizedPlugins[plugin.id];
    if (minimizedInfo == null) {
      debugPrint('No minimized info found for plugin ${plugin.id}');
      return;
    }

    // 检查 context 是否有效
    if (!context.mounted) {
      debugPrint('Context is not mounted in _showMinimizedIcon');
      return;
    }

    final position = minimizedInfo.position;

    // 确保位置值有效
    final initialX = position.dx.isNaN ? 100.0 : position.dx;
    final initialY = position.dy.isNaN ? 100.0 : position.dy;

    OverlayEntry? overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (context) => MinimizedPluginIcon(
        plugin: plugin,
        initialX: initialX,
        initialY: initialY,
        onRestore: () {
          overlayEntry?.remove();
          _handleRestore(context, plugin);
        },
        onPositionChanged: (Offset newPosition) {
          // 保存插件的新位置
          _pluginPositions[plugin.id] = newPosition;

          // 同时更新最小化插件信息中的位置
          final currentInfo = _minimizedPlugins[plugin.id];
          if (currentInfo != null) {
            _minimizedPlugins[plugin.id] = MinimizedPluginInfo(
              plugin: currentInfo.plugin,
              position: newPosition,
            );
          }
        },
      ),
    );

    // 保存覆盖层条目引用
    _minimizedOverlayEntries[plugin.id] = overlayEntry;

    try {
      Overlay.of(context).insert(overlayEntry);
    } catch (e) {
      debugPrint('Error inserting overlay: $e');
      overlayEntry.remove();
      _minimizedOverlayEntries.remove(plugin.id);
    }
  }

  /// 处理恢复
  void _handleRestore(BuildContext context, PluginBase plugin) {
    // 移除最小化状态
    _removeMinimizedPlugin(plugin.id);

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
        onClose: () => _handleClose(context, plugin),
        onMinimize: () => _handleMinimize(context, plugin),
      ),
    );
  }

  /// 移除指定插件的最小化状态
  void _removeMinimizedPlugin(String pluginId) {
    // 移除最小化插件信息
    _minimizedPlugins.remove(pluginId);

    // 移除并清理覆盖层条目
    final overlayEntry = _minimizedOverlayEntries.remove(pluginId);
    if (overlayEntry != null) {
      try {
        overlayEntry.remove();
      } catch (e) {
        debugPrint('Error removing overlay entry: $e');
      }
    }
  }

  /// 恢复指定插件的最小化状态
  void _restoreMinimizedPlugin(BuildContext context, String pluginId) {
    final minimizedInfo = _minimizedPlugins[pluginId];
    if (minimizedInfo == null) return;

    final plugin = minimizedInfo.plugin;

    // 先移除最小化图标
    _removeMinimizedPlugin(pluginId);

    // 显示插件覆盖层
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PluginOverlayWidget(
        plugin: plugin,
        onClose: () => _handleClose(context, plugin),
        onMinimize: () => _handleMinimize(context, plugin),
      ),
    );
  }

  /// 清理所有最小化的插件信息
  void _clearMinimizedPlugin() {
    _minimizedPlugins.clear();

    // 清理所有覆盖层条目
    for (final entry in _minimizedOverlayEntries.values) {
      try {
        entry.remove();
      } catch (e) {
        debugPrint('Error removing overlay entry: $e');
      }
    }
    _minimizedOverlayEntries.clear();
  }

  /// 获取调试信息
  String getDebugInfo() {
    final buffer = StringBuffer();
    buffer.writeln('=== PluginOverlayManager Debug Info ===');
    buffer.writeln('Minimized plugins count: ${_minimizedPlugins.length}');
    for (final entry in _minimizedPlugins.entries) {
      buffer.writeln('  - ${entry.key}: ${entry.value.position}');
    }
    buffer.writeln('Overlay entries count: ${_minimizedOverlayEntries.length}');
    buffer.writeln('Position cache count: ${_pluginPositions.length}');
    return buffer.toString();
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