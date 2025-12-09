import 'selectable_item.dart';

/// 选择路径项
///
/// 记录多级选择中每一步的选择
class SelectionPathItem {
  /// 步骤 ID
  final String stepId;

  /// 步骤标题
  final String stepTitle;

  /// 选中的项目
  final SelectableItem selectedItem;

  const SelectionPathItem({
    required this.stepId,
    required this.stepTitle,
    required this.selectedItem,
  });

  /// 转换为 Map
  Map<String, dynamic> toMap() => {
        'stepId': stepId,
        'stepTitle': stepTitle,
        'selectedItemId': selectedItem.id,
        'selectedItemTitle': selectedItem.title,
      };
}

/// 选择器返回结果
class SelectorResult {
  /// 来源插件 ID
  final String pluginId;

  /// 选择器 ID
  final String selectorId;

  /// 选择路径（记录多级选择的每一步）
  final List<SelectionPathItem> path;

  /// 最终选择的数据（单选时为单个对象，多选时为列表）
  final dynamic data;

  /// 是否取消
  final bool cancelled;

  const SelectorResult({
    required this.pluginId,
    required this.selectorId,
    required this.path,
    this.data,
    this.cancelled = false,
  });

  /// 快捷构造 - 取消选择
  factory SelectorResult.cancelled() => const SelectorResult(
        pluginId: '',
        selectorId: '',
        path: [],
        cancelled: true,
      );

  /// 转换为 Map
  Map<String, dynamic> toMap() => {
        'plugin': pluginId,
        'selector': selectorId,
        'path': path.map((p) => p.toMap()).toList(),
        'data': _serializeData(data),
      };

  /// 序列化数据
  dynamic _serializeData(dynamic data) {
    if (data == null) return null;
    if (data is List) {
      return data.map((item) {
        if (item is SelectableItem) {
          return item.toMap();
        }
        return item;
      }).toList();
    }
    if (data is SelectableItem) {
      return data.toMap();
    }
    return data;
  }

  /// 是否有有效数据
  bool get hasData => !cancelled && data != null;

  /// 获取选择路径中的指定步骤数据
  SelectableItem? getPathItem(String stepId) {
    try {
      return path.firstWhere((p) => p.stepId == stepId).selectedItem;
    } catch (_) {
      return null;
    }
  }

  /// 获取选择路径中的指定步骤原始数据
  T? getPathRawData<T>(String stepId) {
    final item = getPathItem(stepId);
    if (item?.rawData is T) {
      return item!.rawData as T;
    }
    return null;
  }

  @override
  String toString() {
    if (cancelled) return 'SelectorResult(cancelled)';
    return 'SelectorResult(plugin: $pluginId, selector: $selectorId, '
        'path: ${path.map((p) => p.stepTitle).join(' > ')}, '
        'data: $data)';
  }
}

/// 多选结果
class MultiSelectorResult extends SelectorResult {
  /// 选中的项目列表
  final List<SelectableItem> selectedItems;

  const MultiSelectorResult({
    required super.pluginId,
    required super.selectorId,
    required super.path,
    required this.selectedItems,
    super.cancelled = false,
  }) : super(data: null);

  @override
  dynamic get data => selectedItems.map((item) => item.rawData).toList();

  /// 是否有选中项
  bool get hasSelection => selectedItems.isNotEmpty;

  /// 选中数量
  int get selectionCount => selectedItems.length;
}
