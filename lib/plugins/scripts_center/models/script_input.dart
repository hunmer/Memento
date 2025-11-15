/// 脚本输入参数模型
///
/// 用于定义 module 类型脚本的输入参数
class ScriptInput {
  /// 参数显示名称
  final String label;

  /// 参数变量名（在JS中使用）
  final String key;

  /// 数据类型：string, number, boolean, select
  final String type;

  /// 是否必填
  final bool required;

  /// 默认值
  final dynamic defaultValue;

  /// 选项列表（仅用于 select 类型）
  final List<String>? options;

  /// 参数描述（可选）
  final String? description;

  /// 提示文本（可选）
  final String? placeholder;

  ScriptInput({
    required this.label,
    required this.key,
    required this.type,
    this.required = false,
    this.defaultValue,
    this.options,
    this.description,
    this.placeholder,
  });

  /// 从JSON创建输入参数对象
  factory ScriptInput.fromJson(Map<String, dynamic> json) {
    return ScriptInput(
      label: json['label'] as String? ?? '',
      key: json['key'] as String? ?? '',
      type: json['type'] as String? ?? 'string',
      required: json['required'] as bool? ?? false,
      defaultValue: json['defaultValue'],
      options: (json['options'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      description: json['description'] as String?,
      placeholder: json['placeholder'] as String?,
    );
  }

  /// 转换为JSON（用于保存metadata.json）
  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'key': key,
      'type': type,
      'required': required,
      if (defaultValue != null) 'defaultValue': defaultValue,
      if (options != null && options!.isNotEmpty) 'options': options,
      if (description != null) 'description': description,
      if (placeholder != null) 'placeholder': placeholder,
    };
  }

  /// 创建副本，可选择性修改部分字段
  ScriptInput copyWith({
    String? label,
    String? key,
    String? type,
    bool? required,
    dynamic defaultValue,
    List<String>? options,
    String? description,
    String? placeholder,
  }) {
    return ScriptInput(
      label: label ?? this.label,
      key: key ?? this.key,
      type: type ?? this.type,
      required: required ?? this.required,
      defaultValue: defaultValue ?? this.defaultValue,
      options: options ?? this.options,
      description: description ?? this.description,
      placeholder: placeholder ?? this.placeholder,
    );
  }

  /// 是否是选择类型
  bool get isSelect => type == 'select';

  /// 是否是数字类型
  bool get isNumber => type == 'number';

  /// 是否是布尔类型
  bool get isBoolean => type == 'boolean';

  /// 验证输入值
  String? validate(dynamic value) {
    // 必填验证
    if (required && (value == null || value.toString().trim().isEmpty)) {
      return '$label 是必填项';
    }

    // 类型验证
    if (value != null && value.toString().isNotEmpty) {
      switch (type) {
        case 'number':
          if (double.tryParse(value.toString()) == null) {
            return '$label 必须是数字';
          }
          break;
        case 'select':
          if (options != null &&
              !options!.contains(value.toString())) {
            return '$label 的值不在可选项中';
          }
          break;
      }
    }

    return null;
  }

  /// 获取格式化后的值（根据类型转换）
  dynamic getFormattedValue(dynamic value) {
    if (value == null) return defaultValue;

    switch (type) {
      case 'number':
        return double.tryParse(value.toString()) ?? defaultValue;
      case 'boolean':
        if (value is bool) return value;
        return value.toString().toLowerCase() == 'true';
      default:
        return value.toString();
    }
  }

  @override
  String toString() {
    return 'ScriptInput{label: $label, key: $key, type: $type, required: $required}';
  }
}
