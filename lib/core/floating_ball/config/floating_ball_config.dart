import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/floating_ball_gesture.dart';

/// 悬浮球配置数据模型
class FloatingBallConfig {
  final Map<FloatingBallGesture, String> actionMappings;
  final double sizeScale;
  final Offset position;
  final bool enabled;
  final Color color;
  final String iconPath;

  const FloatingBallConfig({
    this.actionMappings = const {},
    this.sizeScale = 1.0,
    this.position = Offset.zero,
    this.enabled = true,
    this.color = Colors.blue,
    this.iconPath = 'assets/icon/icon.png',
  });

  /// 从JSON创建配置
  factory FloatingBallConfig.fromJson(Map<String, dynamic> json) {
    try {
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
        actionMappings: actionMappings,
        sizeScale: (json['size_scale'] as num?)?.toDouble() ?? 1.0,
        position: position,
        enabled: json['enabled'] as bool? ?? true,
        color: color,
        iconPath: json['icon_path'] as String? ?? 'assets/icon/icon.png',
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
      'actions': actionsJson,
      'size_scale': sizeScale,
      'position': {
        'x': position.dx,
        'y': position.dy,
      },
      'enabled': enabled,
      'color': color.value.toString(),
      'icon_path': iconPath,
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
    Map<FloatingBallGesture, String>? actionMappings,
    double? sizeScale,
    Offset? position,
    bool? enabled,
    Color? color,
    String? iconPath,
  }) {
    return FloatingBallConfig(
      actionMappings: actionMappings ?? this.actionMappings,
      sizeScale: sizeScale ?? this.sizeScale,
      position: position ?? this.position,
      enabled: enabled ?? this.enabled,
      color: color ?? this.color,
      iconPath: iconPath ?? this.iconPath,
    );
  }

  /// 获取默认配置
  static FloatingBallConfig get defaultConfig => FloatingBallConfig(
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

  
  /// 配置迁移：从旧版本升级
  static FloatingBallConfig migrateFromOldConfig(Map<String, dynamic> oldConfig) {
    try {
      // 直接返回从JSON解析的配置
      return FloatingBallConfig.fromJson(oldConfig);
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
      case FloatingBallGesture.doubleTap:
        return 'doubleTap';
      case FloatingBallGesture.longPress:
        return 'longPress';
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
      case 'doubleTap':
        return FloatingBallGesture.doubleTap;
      case 'longPress':
        return FloatingBallGesture.longPress;
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
           other.sizeScale == sizeScale &&
           other.position == position &&
           other.enabled == enabled &&
           other.color == color &&
           other.iconPath == iconPath;
  }

  @override
  String toString() {
    return 'FloatingBallConfig('
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
  static Future<FloatingBallConfig> loadConfig() async {
    // TODO: 实现存储读取逻辑
    // 暂时返回默认配置
    return FloatingBallConfig.defaultConfig;
  }

  /// 保存配置
  static Future<void> saveConfig(FloatingBallConfig config) async {
    // TODO: 实现存储保存逻辑
    debugPrint('Saving FloatingBallConfig: ${config.toString()}');
  }

  /// 重置为默认配置
  static Future<void> resetToDefault() async {
    await saveConfig(FloatingBallConfig.defaultConfig);
  }
}
