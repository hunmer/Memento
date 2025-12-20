import 'package:flutter/material.dart';
import 'package:Memento/widgets/smooth_bottom_sheet.dart';
import 'models/index.dart';
import 'package:Memento/widgets/data_selector_sheet/data_selector_sheet.dart';

/// 插件数据选择器服务
///
/// 单例模式，管理所有插件注册的数据选择器
class PluginDataSelectorService {
  // 单例实例
  static final PluginDataSelectorService _instance =
      PluginDataSelectorService._internal();

  factory PluginDataSelectorService() => _instance;

  static PluginDataSelectorService get instance => _instance;

  PluginDataSelectorService._internal();

  // 选择器注册表: selectorId -> SelectorDefinition
  final Map<String, SelectorDefinition> _selectorRegistry = {};

  // 插件 -> 选择器映射
  final Map<String, List<String>> _pluginSelectors = {};

  /// 注册选择器
  ///
  /// [definition] 选择器定义
  /// 返回注册是否成功
  bool registerSelector(SelectorDefinition definition) {
    if (_selectorRegistry.containsKey(definition.id)) {
      debugPrint('警告: 选择器 ${definition.id} 已存在，将被覆盖');
    }

    _selectorRegistry[definition.id] = definition;

    // 更新插件映射
    _pluginSelectors.putIfAbsent(definition.pluginId, () => []);
    if (!_pluginSelectors[definition.pluginId]!.contains(definition.id)) {
      _pluginSelectors[definition.pluginId]!.add(definition.id);
    }
    return true;
  }

  /// 批量注册选择器
  void registerSelectors(List<SelectorDefinition> definitions) {
    for (final definition in definitions) {
      registerSelector(definition);
    }
  }

  /// 注销选择器
  void unregisterSelector(String selectorId) {
    final definition = _selectorRegistry.remove(selectorId);
    if (definition != null) {
      _pluginSelectors[definition.pluginId]?.remove(selectorId);
      debugPrint('已注销选择器: $selectorId');
    }
  }

  /// 注销插件的所有选择器
  void unregisterPluginSelectors(String pluginId) {
    final selectorIds = _pluginSelectors.remove(pluginId);
    if (selectorIds != null) {
      for (final id in selectorIds) {
        _selectorRegistry.remove(id);
      }
      debugPrint('已注销插件 $pluginId 的 ${selectorIds.length} 个选择器');
    }
  }

  /// 获取选择器定义
  SelectorDefinition? getSelectorDefinition(String selectorId) {
    return _selectorRegistry[selectorId];
  }

  /// 检查选择器是否已注册
  bool hasSelector(String selectorId) {
    return _selectorRegistry.containsKey(selectorId);
  }

  /// 获取插件的所有选择器
  List<SelectorDefinition> getPluginSelectors(String pluginId) {
    final ids = _pluginSelectors[pluginId] ?? [];
    return ids
        .map((id) => _selectorRegistry[id])
        .whereType<SelectorDefinition>()
        .toList();
  }

  /// 获取所有已注册的选择器
  List<SelectorDefinition> getAllSelectors() {
    return _selectorRegistry.values.toList();
  }

  /// 获取所有已注册选择器的 ID
  List<String> getAllSelectorIds() {
    return _selectorRegistry.keys.toList();
  }

  /// 获取所有已注册选择器的插件 ID
  List<String> getRegisteredPluginIds() {
    return _pluginSelectors.keys.toList();
  }

  /// 显示选择器 Sheet
  ///
  /// [context] BuildContext
  /// [selectorId] 选择器 ID
  /// [config] 可选配置
  /// 返回选择结果，如果取消则返回 null
  Future<SelectorResult?> showSelector(
    BuildContext context,
    String selectorId, {
    SelectorConfig? config,
  }) async {
    final definition = _selectorRegistry[selectorId];
    if (definition == null) {
      throw ArgumentError('未找到选择器: $selectorId');
    }

    // 动态导入以避免循环依赖
    final result = await _showDataSelectorSheet(
      context,
      definition,
      config ?? const SelectorConfig(),
    );

    return result;
  }

  /// 显示选择器 Sheet（内部方法）
  Future<SelectorResult?> _showDataSelectorSheet(
    BuildContext context,
    SelectorDefinition definition,
    SelectorConfig config,
  ) async {
    return await SmoothBottomSheet.show<SelectorResult>(
      context: context,
      isScrollControlled: true,
      swipeDismissible: config.swipeDismissible,
      barrierDismissible: config.swipeDismissible,
      builder: (context) => DataSelectorSheet(
        definition: definition,
        config: config,
      ),
    );
  }

  /// 快捷方法：显示插件选择器列表
  ///
  /// 先让用户选择要使用哪个选择器，然后打开对应的选择器
  Future<SelectorResult?> showPluginSelectorPicker(
    BuildContext context, {
    List<String>? allowedPluginIds,
    SelectorConfig? config,
  }) async {
    final availableSelectors = allowedPluginIds != null
        ? getAllSelectors()
            .where((s) => allowedPluginIds.contains(s.pluginId))
            .toList()
        : getAllSelectors();

    if (availableSelectors.isEmpty) {
      return null;
    }

    if (availableSelectors.length == 1) {
      // 只有一个选择器，直接打开
      return showSelector(context, availableSelectors.first.id, config: config);
    }

    // 显示选择器列表供用户选择
    final selectedSelector = await SmoothBottomSheet.show<SelectorDefinition>(
      context: context,
      builder: (context) => _SelectorPickerSheet(
        selectors: availableSelectors,
      ),
    );

    if (selectedSelector == null) {
      return SelectorResult.cancelled();
    }

    return showSelector(context, selectedSelector.id, config: config);
  }

  /// 清空所有注册
  void clearAll() {
    _selectorRegistry.clear();
    _pluginSelectors.clear();
    debugPrint('已清空所有选择器注册');
  }
}

/// 全局访问点
final pluginDataSelectorService = PluginDataSelectorService.instance;

/// 选择器选择 Sheet
class _SelectorPickerSheet extends StatelessWidget {
  final List<SelectorDefinition> selectors;

  const _SelectorPickerSheet({required this.selectors});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            '选择数据类型',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        const Divider(height: 1),
        ListView.builder(
          shrinkWrap: true,
          itemCount: selectors.length,
          itemBuilder: (context, index) {
            final selector = selectors[index];
            return ListTile(
              leading: Icon(
                selector.icon ?? Icons.folder,
                color: selector.color,
              ),
              title: Text(selector.name),
              subtitle: selector.description != null
                  ? Text(selector.description!)
                  : null,
              onTap: () => Navigator.pop(context, selector),
            );
          },
        ),
      ],
    );
  }
}
