/// 参数类型枚举
enum ParameterType {
  string, // 普通文本
  date, // 日期 YYYY-MM-DD
  mode, // 数据模式选择（summary/compact/full）
  number, // 数字
  array, // 数组（JSON格式字符串）
}

/// 参数定义类
class ParameterDefinition {
  final String name; // 参数名称（JSON key）
  final ParameterType type; // 参数类型
  final dynamic defaultValue; // 默认值
  final String? label; // 显示标签
  final String? hint; // 提示文本
  final List<String>? options; // 下拉选项（用于 mode 等）
  final bool required; // 是否必填

  const ParameterDefinition({
    required this.name,
    required this.type,
    this.defaultValue,
    this.label,
    this.hint,
    this.options,
    this.required = false,
  });

  /// 获取显示标签（优先使用 label，否则使用 name）
  String getDisplayLabel() => label ?? name;

  /// 获取提示文本
  String? getHint() => hint;
}
