// 这里导入具体的实现类
// 为了避免循环依赖，这些类在单独的文件中定义
import 'home_widget_item.dart';
import 'home_folder_item.dart';

/// 主页项目类型
enum HomeItemType {
  /// 小组件
  widget,

  /// 文件夹
  folder,
}

/// 主页项目基类（可以是小组件或文件夹）
abstract class HomeItem {
  /// 唯一标识符
  final String id;

  /// 项目类型
  final HomeItemType type;

  HomeItem({required this.id, required this.type});

  /// 转换为 JSON
  Map<String, dynamic> toJson();

  /// 从 JSON 创建实例
  static HomeItem fromJson(Map<String, dynamic> json) {
    final typeStr = json['type'] as String;
    final type = HomeItemType.values.firstWhere(
      (t) => t.name == typeStr,
      orElse: () => HomeItemType.widget,
    );

    switch (type) {
      case HomeItemType.widget:
        return HomeWidgetItem.fromJson(json);
      case HomeItemType.folder:
        return HomeFolderItem.fromJson(json);
    }
  }
}
