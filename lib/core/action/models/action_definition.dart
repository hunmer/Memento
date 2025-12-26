/// 动作定义模型
/// 定义动作的基本信息、执行器和配置
library;

import 'package:flutter/material.dart';
import 'package:Memento/core/action/action_executor.dart';
import 'action_form.dart';

/// 动作分类枚举
enum ActionCategory {
  navigation,    // 导航类
  plugin,       // 插件类
  system,       // 系统类
  custom,       // 自定义类
}

/// 动作定义类
/// 包含动作的元数据、表单配置、执行器等信息
class ActionDefinition {
  /// 动作唯一标识符
  final String id;

  /// 动作标题（用于UI显示）
  final String title;

  /// 动作描述
  final String? description;

  /// 动作图标
  final IconData? icon;

  /// 动作分类
  final ActionCategory category;

  /// 表单配置（用于用户输入参数）
  final ActionForm? form;

  /// 动作执行器
  final ActionExecutor executor;

  /// 内置动作标识（区分内置和自定义）
  final bool isBuiltIn;

  /// 是否需要确认执行
  final bool requiresConfirmation;

  /// 确认提示文字
  final String? confirmationMessage;

  /// 动作快捷键组合（可选）
  final String? shortcutKey;

  /// 验证器列表
  final List<Validator>? validators;

  /// 创建动作定义
  const ActionDefinition({
    required this.id,
    required this.title,
    required this.executor,
    this.description,
    this.icon,
    this.category = ActionCategory.custom,
    this.form,
    this.isBuiltIn = false,
    this.requiresConfirmation = false,
    this.confirmationMessage,
    this.shortcutKey,
    this.validators,
  });

  /// 序列化到JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category.name,
      'iconCodePoint': icon?.codePoint,
      'iconFontFamily': icon?.fontFamily,
      'form': form?.toJson(),
      'isBuiltIn': isBuiltIn,
      'requiresConfirmation': requiresConfirmation,
      'confirmationMessage': confirmationMessage,
      'shortcutKey': shortcutKey,
      'validators': validators?.map((v) => v.toJson()).toList(),
    };
  }

  /// 从JSON反序列化
  factory ActionDefinition.fromJson(Map<String, dynamic> json) {
    // 从 JSON 中恢复执行器（默认使用 BuiltInActionExecutor）
    final executor = json['executor'] != null
        ? ActionExecutorFactory.fromJson(json['executor'] as Map<String, dynamic>)
        : BuiltInActionExecutor(json['id'] as String);

    return ActionDefinition(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      category: ActionCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => ActionCategory.custom,
      ),
      icon: json['iconCodePoint'] != null
          ? IconData(
              json['iconCodePoint'] as int,
              fontFamily: json['iconFontFamily'] as String?,
            )
          : null,
      form: json['form'] != null
          ? ActionForm.fromJson(json['form'] as Map<String, dynamic>)
          : null,
      executor: executor,
      isBuiltIn: json['isBuiltIn'] as bool? ?? false,
      requiresConfirmation: json['requiresConfirmation'] as bool? ?? false,
      confirmationMessage: json['confirmationMessage'] as String?,
      shortcutKey: json['shortcutKey'] as String?,
      validators: json['validators'] != null
          ? (json['validators'] as List)
              .map((v) => Validator.fromJson(v as Map<String, dynamic>))
              .toList()
          : null,
    );
  }

  /// 验证动作数据
  List<String> validate(Map<String, dynamic> data) {
    final errors = <String>[];

    // 基础验证
    if (validators != null) {
      for (final validator in validators!) {
        final validationResult = validator.validate(data);
        if (validationResult.isNotEmpty) {
          errors.addAll(validationResult);
        }
      }
    }

    // 表单验证
    if (form != null) {
      final formErrors = form!.validate(data);
      errors.addAll(formErrors);
    }

    return errors;
  }

  /// 复制并修改属性
  ActionDefinition copyWith({
    String? id,
    String? title,
    String? description,
    IconData? icon,
    ActionCategory? category,
    ActionForm? form,
    ActionExecutor? executor,
    bool? isBuiltIn,
    bool? requiresConfirmation,
    String? confirmationMessage,
    String? shortcutKey,
    List<Validator>? validators,
  }) {
    return ActionDefinition(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      category: category ?? this.category,
      form: form ?? this.form,
      executor: executor ?? this.executor,
      isBuiltIn: isBuiltIn ?? this.isBuiltIn,
      requiresConfirmation: requiresConfirmation ?? this.requiresConfirmation,
      confirmationMessage: confirmationMessage ?? this.confirmationMessage,
      shortcutKey: shortcutKey ?? this.shortcutKey,
      validators: validators ?? this.validators,
    );
  }

  @override
  String toString() {
    return 'ActionDefinition(id: $id, title: $title, category: $category)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ActionDefinition && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// 验证器类
/// 用于验证动作参数的合法性
class Validator {
  /// 验证器类型
  final String type;

  /// 验证器参数
  final Map<String, dynamic>? params;

  /// 验证消息
  final String? message;

  const Validator({
    required this.type,
    this.params,
    this.message,
  });

  /// 执行验证
  List<String> validate(Map<String, dynamic> data) {
    switch (type) {
      case 'required':
        return _validateRequired(data);
      case 'minLength':
        return _validateMinLength(data);
      case 'maxLength':
        return _validateMaxLength(data);
      case 'pattern':
        return _validatePattern(data);
      case 'custom':
        return _validateCustom(data);
      default:
        return [];
    }
  }

  List<String> _validateRequired(Map<String, dynamic> data) {
    final field = params?['field'] as String?;
    final value = field != null ? data[field] : null;

    if (value == null || value.toString().isEmpty) {
      return [message ?? '${field ?? '字段'}是必填的'];
    }
    return [];
  }

  List<String> _validateMinLength(Map<String, dynamic> data) {
    final field = params?['field'] as String?;
    final minLength = params?['minLength'] as int? ?? 0;
    final value = data[field];

    if (value != null && value.toString().length < minLength) {
      return [message ?? '${field ?? '字段'}长度不能少于$minLength个字符'];
    }
    return [];
  }

  List<String> _validateMaxLength(Map<String, dynamic> data) {
    final field = params?['field'] as String?;
    final maxLength = params?['maxLength'] as int? ?? 0;
    final value = data[field];

    if (value != null && value.toString().length > maxLength) {
      return [message ?? '${field ?? '字段'}长度不能超过$maxLength个字符'];
    }
    return [];
  }

  List<String> _validatePattern(Map<String, dynamic> data) {
    final field = params?['field'] as String?;
    final pattern = params?['pattern'] as String?;
    final value = data[field];

    if (pattern != null && value != null && value is String) {
      final regex = RegExp(pattern);
      if (!regex.hasMatch(value)) {
        return [message ?? '${field ?? '字段'}格式不正确'];
      }
    }
    return [];
  }

  List<String> _validateCustom(Map<String, dynamic> data) {
    // 自定义验证逻辑
    // 可以通过反射或函数引用实现
    return [];
  }

  /// 序列化到JSON
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'params': params,
      'message': message,
    };
  }

  /// 从JSON反序列化
  factory Validator.fromJson(Map<String, dynamic> json) {
    return Validator(
      type: json['type'] as String,
      params: json['params'] as Map<String, dynamic>?,
      message: json['message'] as String?,
    );
  }

  @override
  String toString() {
    return 'Validator(type: $type, message: $message)';
  }
}

/// 内置动作常量
class BuiltInActions {
  // 导航类
  static const String openPlugin = 'openPlugin';
  static const String goBack = 'goBack';
  static const String goHome = 'goHome';
  static const String openSettings = 'openSettings';
  static const String refresh = 'refresh';
  static const String showRouteHistory = 'showRouteHistory';
  static const String reopenLastRoute = 'reopenLastRoute';
  static const String openLastPlugin = 'openLastPlugin';
  static const String selectPlugin = 'selectPlugin';
  static const String routeViewer = 'routeViewer';

  // 插件类
  static const String executePluginAction = 'executePluginAction';

  // 系统类
  static const String exitApp = 'exitApp';
  static const String lockScreen = 'lockScreen';
  static const String showNotifications = 'showNotifications';
  static const String askContext = 'askContext';
  static const String toggleTheme = 'toggleTheme';
}
