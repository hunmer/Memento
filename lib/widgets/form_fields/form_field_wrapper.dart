import 'package:flutter/material.dart';

/// 表单字段包装器基类
///
/// 为表单组件提供统一的状态管理接口
abstract class FormFieldWrapper extends StatefulWidget {
  /// 字段名称
  final String name;

  /// 初始值
  final dynamic initialValue;

  /// 值变化回调
  final ValueChanged? onChanged;

  /// 是否启用
  final bool enabled;

  const FormFieldWrapper({
    super.key,
    required this.name,
    this.initialValue,
    this.onChanged,
    this.enabled = true,
  });

  /// 创建对应的 State
  @override
  State<FormFieldWrapper> createState();
}

/// 表单字段状态基类
///
/// 定义了表单字段必须实现的状态管理方法
abstract class FormFieldWrapperState<T extends FormFieldWrapper> extends State<T> {
  /// 当前字段的值
  dynamic _value;

  /// 获取当前值
  dynamic getValue() => _value;

  /// 设置值
  void setValue(dynamic value) {
    if (widget.enabled) {
      setState(() {
        _value = value;
      });
      widget.onChanged?.call(value);
    }
  }

  /// 重置为初始值
  void reset() {
    if (widget.enabled) {
      setState(() {
        _value = widget.initialValue;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _value = widget.initialValue;
  }

  @override
  void didUpdateWidget(T oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue && _value == null) {
      _value = widget.initialValue;
    }
  }
}

/// 表单字段包装器状态（公开类）
class WrappedFormFieldState extends FormFieldWrapperState<WrappedFormField> {
  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _value, (value) => setValue(value));
  }
}

/// 表单字段包装器
///
/// 将现有表单组件包装，提供统一的状态管理接口
class WrappedFormField extends FormFieldWrapper {
  /// 子组件构建器
  final Widget Function(BuildContext context, dynamic value, ValueChanged setValue) builder;

  /// 获取当前值的回调
  final dynamic Function()? getValue;

  /// 重置回调
  final VoidCallback? onReset;

  const WrappedFormField({
    super.key,
    required super.name,
    super.initialValue,
    super.onChanged,
    super.enabled,
    required this.builder,
    this.getValue,
    this.onReset,
  });

  @override
  State<WrappedFormField> createState() => WrappedFormFieldState();
}
