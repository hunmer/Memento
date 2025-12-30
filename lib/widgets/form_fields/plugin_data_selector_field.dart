import 'package:flutter/material.dart';
import 'package:Memento/core/services/plugin_data_selector/plugin_data_selector_service.dart';
import 'package:Memento/core/services/plugin_data_selector/models/selector_config.dart';
import 'package:Memento/core/services/plugin_data_selector/models/selectable_item.dart';
import 'package:Memento/widgets/form_fields/form_field_wrapper.dart';

/// 插件数据选择器字段
///
/// 功能特性：
/// - 使用 PluginDataSelectorService 选择插件数据
/// - 显示当前选中的数据
/// - 支持自定义配置
/// - 支持字段映射（通过 extra['fieldMapping']）
class PluginDataSelectorField extends FormFieldWrapper {
  /// 插件数据类型（如 'openai.agent'）
  final String pluginDataType;

  /// 对话框标题
  final String? dialogTitle;

  /// 前缀图标
  final IconData? prefixIcon;

  /// 值变化回调
  final ValueChanged<dynamic>? onChanged;

  /// 额外配置（包含 fieldMapping 等）
  final Map<String, dynamic>? extra;

  const PluginDataSelectorField({
    super.key,
    required super.name,
    required this.pluginDataType,
    this.dialogTitle,
    super.initialValue,
    this.prefixIcon,
    this.onChanged,
    this.extra,
    super.enabled = true,
  });

  @override
  State<PluginDataSelectorField> createState() =>
      _PluginDataSelectorFieldState();
}

class _PluginDataSelectorFieldState extends FormFieldWrapperState<PluginDataSelectorField> {
  String? _selectedId;
  String? _selectedTitle;
  Map<String, dynamic>? _selectedData;

  @override
  void initState() {
    super.initState();
    // 处理 initialValue 可能是 String 或 Map 的情况
    if (widget.initialValue is Map) {
      _selectedData = widget.initialValue as Map<String, dynamic>;
      _selectedId = _selectedData!['id'] as String?;
      _selectedTitle = _selectedData!['title'] as String?;
    } else {
      _selectedId = widget.initialValue as String?;
    }
    _loadSelectedData();
  }

  Future<void> _loadSelectedData() async {
    if (_selectedId == null) return;
    // TODO: 可以根据 _selectedId 加载数据获取标题
    // 目前简化处理，只显示 ID
  }

  /// 根据路径从 Map 中提取值（支持嵌套路径，如 "data.title"）
  dynamic _extractByPath(Map<String, dynamic> data, String path) {
    final keys = path.split('.');
    dynamic current = data;
    for (final key in keys) {
      if (current is Map && current.containsKey(key)) {
        current = current[key];
      } else {
        return null;
      }
    }
    return current;
  }

  /// 应用字段映射配置
  Map<String, dynamic> _applyFieldMapping(Map<String, dynamic> sourceData) {
    final fieldMapping = widget.extra?['fieldMapping'] as Map<String, dynamic>?;

    // 如果没有配置字段映射，返回原始数据
    if (fieldMapping == null || fieldMapping.isEmpty) {
      return sourceData;
    }

    final result = <String, dynamic>{};
    fieldMapping.forEach((targetKey, sourcePath) {
      if (sourcePath is String) {
        final value = _extractByPath(sourceData, sourcePath);
        if (value != null) {
          result[targetKey] = value;
        }
      }
    });

    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: widget.prefixIcon != null
            ? Icon(widget.prefixIcon, color: Colors.deepPurple)
            : const Icon(Icons.smart_toy, color: Colors.deepPurple),
        title: Text(_selectedTitle ?? _selectedId ?? '未选择'),
        subtitle: _selectedId != null ? null : const Text('点击选择数据'),
        trailing: const Icon(Icons.chevron_right),
        onTap: widget.enabled ? _showSelector : null,
      ),
    );
  }

  Future<void> _showSelector() async {
    final result = await PluginDataSelectorService.instance.showSelector(
      context,
      widget.pluginDataType,
      config: SelectorConfig(title: widget.dialogTitle ?? '选择数据'),
    );

    if (result != null && !result.cancelled && result.data.isNotEmpty) {
      final item = result.data.first;

      // 将对象转换为 Map 格式
      Map<String, dynamic> itemMap;
      if (item is Map) {
        itemMap = item as Map<String, dynamic>;
      } else {
        // 调用对象的 toJson 方法
        itemMap = item.toJson();
      }

      // 应用字段映射
      final mappedData = _applyFieldMapping(itemMap);

      setState(() {
        _selectedData = mappedData;
        // 用于显示的标题，优先使用映射后的 title 或 name
        _selectedTitle =
            mappedData['title']?.toString() ??
            mappedData['name']?.toString() ??
            itemMap['title']?.toString() ??
            itemMap['name']?.toString() ??
            mappedData['id']?.toString();
      });
      widget.onChanged?.call(mappedData);
    }
  }

  @override
  dynamic getValue() => _selectedData ?? _selectedId;
}
