import 'dart:ui';

/// iOS 小组件尺寸枚举
///
/// 对应 iOS WidgetKit 的系统尺寸：
/// - small: systemSmall (170x170 pt)
/// - wide: systemMedium (364x170 pt)
/// - large: systemLarge (364x382 pt)
enum IOSWidgetSize {
  /// 小组件 - systemSmall
  small('systemSmall', 170, 170),

  /// 宽组件 - systemMedium
  wide('systemMedium', 364, 170),

  /// 大组件 - systemLarge
  large('systemLarge', 364, 382);

  final String family;
  final int pointWidth;
  final int pointHeight;

  const IOSWidgetSize(this.family, this.pointWidth, this.pointHeight);

  /// 从名称获取尺寸
  static IOSWidgetSize fromName(String name) {
    return switch (name) {
      'small' => IOSWidgetSize.small,
      'wide' => IOSWidgetSize.wide,
      'large' => IOSWidgetSize.large,
      _ => IOSWidgetSize.small,
    };
  }

  /// 获取像素尺寸（基于 @3x 像素密度）
  Size getPixelSize({double pixelRatio = 3.0}) {
    return Size(
      pointWidth * pixelRatio,
      pointHeight * pixelRatio,
    );
  }

  /// 获取 iOS Widget Family 名称
  String get iosFamily => family;
}

/// iOS 小组件配置
///
/// 存储单个 iOS 桌面小组件的配置信息，包括：
/// - 对应的 HomeWidget ID
/// - 选择的尺寸
/// - 传递给 builder 的配置
class IOSWidgetConfig {
  /// iOS Widget Kind（唯一标识符）
  final String widgetKind;

  /// 对应的 HomeWidget ID
  final String homeWidgetId;

  /// 所属插件 ID
  final String pluginId;

  /// 选择的 iOS 尺寸
  final IOSWidgetSize size;

  /// 传递给 HomeWidget builder 的配置
  final Map<String, dynamic> config;

  /// 最后更新时间
  final DateTime lastUpdated;

  const IOSWidgetConfig({
    required this.widgetKind,
    required this.homeWidgetId,
    required this.pluginId,
    required this.size,
    required this.config,
    required this.lastUpdated,
  });

  /// 从 JSON 创建配置
  factory IOSWidgetConfig.fromJson(Map<String, dynamic> json) {
    return IOSWidgetConfig(
      widgetKind: json['widgetKind'] as String? ?? '',
      homeWidgetId: json['homeWidgetId'] as String? ?? '',
      pluginId: json['pluginId'] as String? ?? '',
      size: IOSWidgetSize.fromName(json['size'] as String? ?? 'small'),
      config: json['config'] != null
          ? Map<String, dynamic>.from(json['config'] as Map)
          : {},
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.parse(json['lastUpdated'] as String)
          : DateTime.now(),
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'widgetKind': widgetKind,
      'homeWidgetId': homeWidgetId,
      'pluginId': pluginId,
      'size': size.name,
      'config': config,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  /// 创建副本
  IOSWidgetConfig copyWith({
    String? widgetKind,
    String? homeWidgetId,
    String? pluginId,
    IOSWidgetSize? size,
    Map<String, dynamic>? config,
    DateTime? lastUpdated,
  }) {
    return IOSWidgetConfig(
      widgetKind: widgetKind ?? this.widgetKind,
      homeWidgetId: homeWidgetId ?? this.homeWidgetId,
      pluginId: pluginId ?? this.pluginId,
      size: size ?? this.size,
      config: config ?? this.config,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}
