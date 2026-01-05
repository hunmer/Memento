import 'home_item.dart';
import 'home_widget_item.dart';
import 'home_widget_size.dart';

/// 小组件折叠方向
enum HomeStackDirection {
  horizontal,
  vertical,
}

/// 小组件折叠项，承载多个 HomeWidgetItem
class HomeStackItem extends HomeItem {
  final List<HomeWidgetItem> children;
  final HomeWidgetSize size;
  final HomeStackDirection direction;
  final int activeIndex;

  HomeStackItem({
    required super.id,
    required this.children,
    required this.size,
    this.direction = HomeStackDirection.horizontal,
    this.activeIndex = 0,
  }) : super(type: HomeItemType.stack);

  HomeWidgetItem? get currentItem {
    if (children.isEmpty) {
      return null;
    }
    if (activeIndex < 0 || activeIndex >= children.length) {
      return children.first;
    }
    return children[activeIndex];
  }

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'size': size.toJson(),
        'direction': direction.name,
        'activeIndex': activeIndex,
        'children': children.map((item) => item.toJson()).toList(),
      };

  factory HomeStackItem.fromJson(Map<String, dynamic> json) {
    final direction = HomeStackDirection.values.firstWhere(
      (value) => value.name == (json['direction'] as String? ?? 'horizontal'),
      orElse: () => HomeStackDirection.horizontal,
    );
    final children = (json['children'] as List? ?? [])
        .map((item) => HomeWidgetItem.fromJson(item as Map<String, dynamic>))
        .toList();
    final size = HomeWidgetSize.fromJson(json['size'] as Map<String, dynamic>);

    return HomeStackItem(
      id: json['id'] as String,
      children: children,
      size: size,
      direction: direction,
      activeIndex: json['activeIndex'] as int? ?? 0,
    );
  }

  HomeStackItem copyWith({
    String? id,
    List<HomeWidgetItem>? children,
    HomeWidgetSize? size,
    HomeStackDirection? direction,
    int? activeIndex,
  }) {
    return HomeStackItem(
      id: id ?? this.id,
      children: children ?? this.children,
      size: size ?? this.size,
      direction: direction ?? this.direction,
      activeIndex: activeIndex ?? this.activeIndex,
    );
  }
}
