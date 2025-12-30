import 'package:flutter/material.dart';
import 'package:Memento/core/services/plugin_data_selector/plugin_data_selector_service.dart';
import 'package:Memento/core/services/plugin_data_selector/models/selector_config.dart';
import 'package:Memento/widgets/form_fields/form_field_wrapper.dart';

/// 插件数据选择器字段
///
/// 功能特性：
/// - 使用 PluginDataSelectorService 选择插件数据
/// - 显示当前选中的数据
/// - 支持自定义配置
class PluginDataSelectorField extends FormFieldWrapper {
  /// 插件数据类型（如 'openai.agent'）
  final String pluginDataType;

  /// 对话框标题
  final String? dialogTitle;

  /// 前缀图标
  final IconData? prefixIcon;

  /// 值变化回调
  final ValueChanged<dynamic>? onChanged;

  const PluginDataSelectorField({
    super.key,
    required super.name,
    required this.pluginDataType,
    this.dialogTitle,
    super.initialValue,
    this.prefixIcon,
    this.onChanged,
    super.enabled = true,
  });

  @override
  State<PluginDataSelectorField> createState() =>
      _PluginDataSelectorFieldState();
}

class _PluginDataSelectorFieldState extends FormFieldWrapperState<PluginDataSelectorField> {
  String? _selectedId;
  String? _selectedTitle;

  @override
  void initState() {
    super.initState();
    _selectedId = widget.initialValue;
    _loadSelectedData();
  }

  Future<void> _loadSelectedData() async {
    if (_selectedId == null) return;
    // TODO: 可以根据 _selectedId 加载数据获取标题
    // 目前简化处理，只显示 ID
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
      final data = result.data.first;
      setState(() {
        _selectedId = data['id'] as String?;
        _selectedTitle = data['title'] as String?;
      });
      widget.onChanged?.call(_selectedId);
    }
  }

  @override
  dynamic getValue() => _selectedId;
}
