import 'package:flutter/foundation.dart';
import 'home_item.dart';
import 'home_widget_size.dart';

/// 主页小组件实例
///
/// 表示一个放置在主页上的小组件实例
/// 引用注册表中的小组件定义，并包含该实例的配置
class HomeWidgetItem extends HomeItem {
  /// 小组件ID（引用 HomeWidget.id）
  final String widgetId;

  /// 当前尺寸
  final HomeWidgetSize size;

  /// 小组件特定配置（由小组件自定义使用）
  final Map<String, dynamic> config;

  HomeWidgetItem({
    required super.id,
    required this.widgetId,
    required this.size,
    this.config = const {},
  }) : super(type: HomeItemType.widget);

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'widgetId': widgetId,
    'size': size.toJson(),
    'config': config,
  };

  /// 从 JSON 加载
  factory HomeWidgetItem.fromJson(Map<String, dynamic> json) {
    // 调试：打印原始 JSON 中的 config
    final widgetId = json['widgetId'] as String;

    // 更安全的 config 处理
    Map<String, dynamic> configMap = {};
    if (json['config'] != null) {
      try {
        // 尝试直接转换
        if (json['config'] is Map) {
          configMap = Map<String, dynamic>.from(json['config'] as Map);
        }
      } catch (e) {
        debugPrint(
          '[HomeWidgetItem] fromJson - widgetId: $widgetId, config 转换失败: $e',
        );
      }
    }

    final item = HomeWidgetItem(
      id: json['id'] as String,
      widgetId: widgetId,
      size: HomeWidgetSize.fromJson(json['size'] as Map<String, dynamic>),
      config: configMap,
    );

    return item;
  }

  /// 创建副本，允许修改部分字段
  HomeWidgetItem copyWith({
    String? id,
    String? widgetId,
    HomeWidgetSize? size,
    Map<String, dynamic>? config,
  }) {
    return HomeWidgetItem(
      id: id ?? this.id,
      widgetId: widgetId ?? this.widgetId,
      size: size ?? this.size,
      config: config ?? this.config,
    );
  }
}
