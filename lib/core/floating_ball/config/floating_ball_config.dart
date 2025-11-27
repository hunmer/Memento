import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/floating_ball_gesture.dart';

/// 悬浮球配置数据模型
///
/// 支持环境特定配置和配置迁移
class FloatingBallConfig {
  final bool isInOverlay;
  final Map<FloatingBallGesture, String> actionMappings;
  final double sizeScale;
  final Offset position;
  final bool enabled;
  final Color color;
  final String iconPath;

  // Overlay窗口特有配置
  final bool autoStart;
  final bool showNotification;
  final String windowAlignment;
  final bool enableDrag;
  final bool isExpanded;

  // 双悬浮球模式配置
  final bool enableOverlayWindow; // 是否启用overlay窗口悬浮球
  final bool coexistMode;         // 是否允许两个悬浮球同时存在

  const FloatingBallConfig({
    this.isInOverlay = false,
    this.actionMappings = const {},
    this.sizeScale = 1.0,
    this.position = Offset.zero,
    this.enabled = true,
    this.color = Colors.blue,
    this.iconPath = 'assets/icon/icon.png',
    this.autoStart = false,
    this.showNotification = false,
    this.windowAlignment = 'topRight',
    this.enableDrag = true,
    this.isExpanded = false,
    this.enableOverlayWindow = false,
    this.coexistMode = false,
  });

  /// 从JSON创建配置
  factory FloatingBallConfig.fromJson(Map<String, dynamic> json) {
    try {
      // 兼容旧配置格式
      final isInOverlay = json['isInOverlay'] as bool? ?? false;

      // 解析动作映射
      final actionsJson = json['actions'] as Map<String, dynamic>? ?? {};
      final actionMappings = <FloatingBallGesture, String>{};

      for (final entry in actionsJson.entries) {
        final gesture = _parseGesture(entry.key);
        if (gesture != null) {
          actionMappings[gesture] = entry.value as String;
        }
      }

      // 解析位置
      final positionJson = json['position'] as Map<String, dynamic>? ?? {};
      final position = Offset(
        (positionJson['x'] as num?)?.toDouble() ?? 0.0,
        (positionJson['y'] as num?)?.toDouble() ?? 0.0,
      );

      // 解析颜色
      Color color = Colors.blue;
      if (json['color'] != null) {
        if (json['color'] is String) {
          color = Color(int.parse(json['color'] as String));
        } else if (json['color'] is int) {
          color = Color(json['color'] as int);
        }
      }

      return FloatingBallConfig(
        isInOverlay: isInOverlay,
        actionMappings: actionMappings,
        sizeScale: (json['size_scale'] as num?)?.toDouble() ?? 1.0,
        position: position,
        enabled: json['enabled'] as bool? ?? true,
        color: color,
        iconPath: json['icon_path'] as String? ?? 'assets/icon/icon.png',
        autoStart: json['auto_start'] as bool? ?? false,
        showNotification: json['show_notification'] as bool? ?? false,
        windowAlignment: json['window_alignment'] as String? ?? 'topRight',
        enableDrag: json['enable_drag'] as bool? ?? true,
        isExpanded: json['is_expanded'] as bool? ?? false,
        enableOverlayWindow: json['enable_overlay_window'] as bool? ?? false,
        coexistMode: json['coexist_mode'] as bool? ?? false,
      );
    } catch (e) {
      debugPrint('Error parsing FloatingBallConfig: $e');
      // 返回默认配置
      return FloatingBallConfig();
    }
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    final actionsJson = <String, String>{};
    for (final entry in actionMappings.entries) {
      actionsJson[_gestureToString(entry.key)] = entry.value;
    }

    return {
      'isInOverlay': isInOverlay,
      'actions': actionsJson,
      'size_scale': sizeScale,
      'position': {
        'x': position.dx,
        'y': position.dy,
      },
      'enabled': enabled,
      'color': color.value.toString(),
      'icon_path': iconPath,
      'auto_start': autoStart,
      'show_notification': showNotification,
      'window_alignment': windowAlignment,
      'enable_drag': enableDrag,
      'is_expanded': isExpanded,
      'enable_overlay_window': enableOverlayWindow,
      'coexist_mode': coexistMode,
    };
  }

  /// 从JSON字符串创建配置
  factory FloatingBallConfig.fromJsonString(String jsonString) {
    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return FloatingBallConfig.fromJson(json);
    } catch (e) {
      debugPrint('Error parsing FloatingBallConfig from string: $e');
      return FloatingBallConfig();
    }
  }

  /// 转换为JSON字符串
  String toJsonString() {
    return jsonEncode(toJson());
  }

  /// 创建副本并修改指定属性
  FloatingBallConfig copyWith({
    bool? isInOverlay,
    Map<FloatingBallGesture, String>? actionMappings,
    double? sizeScale,
    Offset? position,
    bool? enabled,
    Color? color,
    String? iconPath,
    bool? autoStart,
    bool? showNotification,
    String? windowAlignment,
    bool? enableDrag,
    bool? isExpanded,
    bool? enableOverlayWindow,
    bool? coexistMode,
  }) {
    return FloatingBallConfig(
      isInOverlay: isInOverlay ?? this.isInOverlay,
      actionMappings: actionMappings ?? this.actionMappings,
      sizeScale: sizeScale ?? this.sizeScale,
      position: position ?? this.position,
      enabled: enabled ?? this.enabled,
      color: color ?? this.color,
      iconPath: iconPath ?? this.iconPath,
      autoStart: autoStart ?? this.autoStart,
      showNotification: showNotification ?? this.showNotification,
      windowAlignment: windowAlignment ?? this.windowAlignment,
      enableDrag: enableDrag ?? this.enableDrag,
      isExpanded: isExpanded ?? this.isExpanded,
      enableOverlayWindow: enableOverlayWindow ?? this.enableOverlayWindow,
      coexistMode: coexistMode ?? this.coexistMode,
    );
  }

  /// 获取默认配置
  static FloatingBallConfig get defaultConfig => FloatingBallConfig(
    isInOverlay: false,
    sizeScale: 1.0,
    position: const Offset(21, 99),
    enabled: true,
    color: Color(0xFF2196F3), // 与全局保持一致的Material Blue
    iconPath: 'assets/icon/icon.png',
    actionMappings: {
      FloatingBallGesture.tap: '打开上次插件',
      FloatingBallGesture.swipeUp: '返回上一页',
      FloatingBallGesture.swipeDown: '选择打开插件',
      FloatingBallGesture.swipeLeft: '选择打开插件小窗口',
      FloatingBallGesture.swipeRight: '刷新页面',
    },
  );

  /// 获取OverlayWindow环境的默认配置
  static FloatingBallConfig get overlayWindowDefaultConfig => FloatingBallConfig(
    isInOverlay: true,
    sizeScale: 1.0,
    position: const Offset(100, 100), // 默认位置
    enabled: true,
    color: Color(0xFF2196F3), // 与应用内保持一致的Material Blue
    iconPath: 'home', // 使用内置图标而不是assets图片
    autoStart: false,
    showNotification: false,
    windowAlignment: 'topRight',
    enableDrag: true,
    isExpanded: false,
    enableOverlayWindow: true,
    coexistMode: true,
    actionMappings: {
      FloatingBallGesture.tap: '展开选项',
      FloatingBallGesture.swipeUp: '打开聊天',
      FloatingBallGesture.swipeDown: '打开日记',
      FloatingBallGesture.swipeLeft: '打开日历',
      FloatingBallGesture.swipeRight: '打开设置',
    },
  );

  /// 获取双悬浮球共存模式的默认配置
  static FloatingBallConfig get coexistenceDefaultConfig => FloatingBallConfig(
    isInOverlay: false, // 应用内悬浮球
    sizeScale: 0.6,
    position: const Offset(21, 99),
    enabled: true,
    color: Colors.blue,
    iconPath: 'assets/icon/icon.png',
    autoStart: false,
    showNotification: false,
    windowAlignment: 'topRight',
    enableDrag: true,
    isExpanded: false,
    enableOverlayWindow: true, // 同时启用overlay窗口悬浮球
    coexistMode: true, // 允许两个悬浮球共存
    actionMappings: {
      FloatingBallGesture.tap: '打开上次插件',
      FloatingBallGesture.swipeUp: '返回上一页',
      FloatingBallGesture.swipeDown: '选择打开插件',
      FloatingBallGesture.swipeLeft: '选择打开插件小窗口',
      FloatingBallGesture.swipeRight: '刷新页面',
    },
  );

  /// 配置迁移：从旧版本升级
  static FloatingBallConfig migrateFromOldConfig(Map<String, dynamic> oldConfig) {
    try {
      // 检查是否为新版本配置
      if (oldConfig.containsKey('isInOverlay')) {
        return FloatingBallConfig.fromJson(oldConfig);
      }

      // 旧版本配置迁移
      final migrated = FloatingBallConfig.fromJson(oldConfig);
      return migrated.copyWith(
        autoStart: false,
        showNotification: false,
        windowAlignment: 'topRight',
        enableDrag: oldConfig['enable_drag'] as bool? ?? true,
        isExpanded: false,
      );
    } catch (e) {
      debugPrint('Error migrating config: $e');
      return FloatingBallConfig.defaultConfig;
    }
  }

  /// 获取手势的字符串表示
  static String _gestureToString(FloatingBallGesture gesture) {
    switch (gesture) {
      case FloatingBallGesture.tap:
        return 'tap';
      case FloatingBallGesture.swipeUp:
        return 'swipeUp';
      case FloatingBallGesture.swipeDown:
        return 'swipeDown';
      case FloatingBallGesture.swipeLeft:
        return 'swipeLeft';
      case FloatingBallGesture.swipeRight:
        return 'swipeRight';
    }
  }

  /// 从字符串解析手势
  static FloatingBallGesture? _parseGesture(String gestureString) {
    switch (gestureString) {
      case 'tap':
        return FloatingBallGesture.tap;
      case 'swipeUp':
        return FloatingBallGesture.swipeUp;
      case 'swipeDown':
        return FloatingBallGesture.swipeDown;
      case 'swipeLeft':
        return FloatingBallGesture.swipeLeft;
      case 'swipeRight':
        return FloatingBallGesture.swipeRight;
      default:
        return null;
    }
  }

  /// 获取特定手势的动作
  String? getAction(FloatingBallGesture gesture) {
    return actionMappings[gesture];
  }

  /// 设置特定手势的动作
  FloatingBallConfig setAction(FloatingBallGesture gesture, String action) {
    final newMappings = Map<FloatingBallGesture, String>.from(actionMappings);
    newMappings[gesture] = action;
    return copyWith(actionMappings: newMappings);
  }

  /// 清除特定手势的动作
  FloatingBallConfig clearAction(FloatingBallGesture gesture) {
    final newMappings = Map<FloatingBallGesture, String>.from(actionMappings);
    newMappings.remove(gesture);
    return copyWith(actionMappings: newMappings);
  }

  /// 获取配置的哈希值（用于比较配置是否发生变化）
  @override
  int get hashCode => toJsonString().hashCode;

  /// 检查配置是否相等
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FloatingBallConfig &&
           other.isInOverlay == isInOverlay &&
           other.sizeScale == sizeScale &&
           other.position == position &&
           other.enabled == enabled &&
           other.color == color &&
           other.iconPath == iconPath &&
           other.autoStart == autoStart &&
           other.showNotification == showNotification &&
           other.windowAlignment == windowAlignment &&
           other.enableDrag == enableDrag &&
           other.isExpanded == isExpanded &&
           other.enableOverlayWindow == enableOverlayWindow &&
           other.coexistMode == coexistMode;
  }

  @override
  String toString() {
    return 'FloatingBallConfig('
        'isInOverlay: $isInOverlay, '
        'sizeScale: $sizeScale, '
        'position: $position, '
        'enabled: $enabled, '
        'actionMappings: $actionMappings'
        ')';
  }
}

/// 悬浮球配置管理器
class FloatingBallConfigManager {

  /// 读取配置
  static Future<FloatingBallConfig> loadConfig({bool isInOverlay = false}) async {
    // TODO: 实现存储读取逻辑
    // 暂时返回默认配置
    if (isInOverlay) {
      return FloatingBallConfig.overlayWindowDefaultConfig;
    } else {
      return FloatingBallConfig.defaultConfig;
    }
  }

  /// 保存配置
  static Future<void> saveConfig(FloatingBallConfig config) async {
    // TODO: 实现存储保存逻辑
    debugPrint('Saving FloatingBallConfig: ${config.toString()}');
  }

  /// 重置为默认配置
  static Future<void> resetToDefault({bool isInOverlay = false}) async {
    final defaultConfig = isInOverlay
        ? FloatingBallConfig.overlayWindowDefaultConfig
        : FloatingBallConfig.defaultConfig;
    await saveConfig(defaultConfig);
  }
}
