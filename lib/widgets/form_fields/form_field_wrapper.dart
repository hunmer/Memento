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

  /// 保存值（由 onSaved 回调使用）
  void save() {
    // 默认实现为空，子类可以覆盖
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
  /// 防止 setValue 中重复调用 save 的标志
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _value, (value) => setValue(value));
  }

  @override
  dynamic getValue() {
    return _value;
  }

  @override
  void setValue(dynamic value) {
    if (widget.enabled) {
      final wasSaving = _isSaving;
      _isSaving = true;
      try {
        setState(() {
          _value = value;
        });
        widget.onChanged?.call(value);
      } finally {
        _isSaving = wasSaving;
      }
    }
  }

  @override
  void save() {
    // 如果不在 setValue 调用的 save 中，则调用 onSaved
    if (!_isSaving) {
      widget.onSaved?.call(_value);
    }
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

  /// 保存回调（带当前值参数）
  final void Function(dynamic value)? onSaved;

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
    this.onSaved,
    this.onReset,
  });

  @override
  State<WrappedFormField> createState() => WrappedFormFieldState();
}
