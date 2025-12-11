/// 参数验证工具类 - 客户端和服务端共享
///
/// 此文件提供统一的参数验证逻辑，确保两端规则一致

/// 验证结果
class ValidationResult {
  final bool isValid;
  final String? errorMessage;
  final String? errorField;

  const ValidationResult.success()
      : isValid = true,
        errorMessage = null,
        errorField = null;

  const ValidationResult.failure(this.errorMessage, [this.errorField])
      : isValid = false;

  Map<String, dynamic> toJson() => {
        'isValid': isValid,
        if (errorMessage != null) 'error': errorMessage,
        if (errorField != null) 'field': errorField,
      };
}

/// 验证规则定义
class ValidationRule<T> {
  final String fieldName;
  final bool isRequired;
  final bool Function(T?)? validator;
  final String? customErrorMessage;

  const ValidationRule({
    required this.fieldName,
    this.isRequired = false,
    this.validator,
    this.customErrorMessage,
  });
}

/// 参数验证器
class ParamValidator {
  /// 验证必需的字符串参数
  static ValidationResult requireString(
    Map<String, dynamic> params,
    String fieldName, {
    bool allowEmpty = false,
    int? minLength,
    int? maxLength,
  }) {
    final value = params[fieldName];

    if (value == null) {
      return ValidationResult.failure('缺少必需参数: $fieldName', fieldName);
    }

    if (value is! String) {
      return ValidationResult.failure('参数类型错误: $fieldName 必须是字符串', fieldName);
    }

    if (!allowEmpty && value.isEmpty) {
      return ValidationResult.failure('参数不能为空: $fieldName', fieldName);
    }

    if (minLength != null && value.length < minLength) {
      return ValidationResult.failure(
        '$fieldName 长度不能少于 $minLength 个字符',
        fieldName,
      );
    }

    if (maxLength != null && value.length > maxLength) {
      return ValidationResult.failure(
        '$fieldName 长度不能超过 $maxLength 个字符',
        fieldName,
      );
    }

    return const ValidationResult.success();
  }

  /// 验证可选的字符串参数
  static String? optionalString(Map<String, dynamic> params, String fieldName) {
    final value = params[fieldName];
    if (value == null) return null;
    if (value is String) return value.isEmpty ? null : value;
    return value.toString();
  }

  /// 验证必需的整数参数
  static ValidationResult requireInt(
    Map<String, dynamic> params,
    String fieldName, {
    int? min,
    int? max,
  }) {
    final value = params[fieldName];

    if (value == null) {
      return ValidationResult.failure('缺少必需参数: $fieldName', fieldName);
    }

    int? intValue;
    if (value is int) {
      intValue = value;
    } else if (value is String) {
      intValue = int.tryParse(value);
    }

    if (intValue == null) {
      return ValidationResult.failure('参数类型错误: $fieldName 必须是整数', fieldName);
    }

    if (min != null && intValue < min) {
      return ValidationResult.failure('$fieldName 不能小于 $min', fieldName);
    }

    if (max != null && intValue > max) {
      return ValidationResult.failure('$fieldName 不能大于 $max', fieldName);
    }

    return const ValidationResult.success();
  }

  /// 获取可选的整数参数
  static int? optionalInt(Map<String, dynamic> params, String fieldName) {
    final value = params[fieldName];
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  /// 验证必需的布尔参数
  static ValidationResult requireBool(
    Map<String, dynamic> params,
    String fieldName,
  ) {
    final value = params[fieldName];

    if (value == null) {
      return ValidationResult.failure('缺少必需参数: $fieldName', fieldName);
    }

    if (value is! bool) {
      return ValidationResult.failure('参数类型错误: $fieldName 必须是布尔值', fieldName);
    }

    return const ValidationResult.success();
  }

  /// 获取可选的布尔参数
  static bool optionalBool(
    Map<String, dynamic> params,
    String fieldName, {
    bool defaultValue = false,
  }) {
    final value = params[fieldName];
    if (value == null) return defaultValue;
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true';
    return defaultValue;
  }

  /// 批量验证多个字段
  static ValidationResult validateAll(
    Map<String, dynamic> params,
    List<ValidationRule> rules,
  ) {
    for (final rule in rules) {
      if (rule.isRequired) {
        final value = params[rule.fieldName];
        if (value == null) {
          return ValidationResult.failure(
            rule.customErrorMessage ?? '缺少必需参数: ${rule.fieldName}',
            rule.fieldName,
          );
        }

        if (rule.validator != null && !rule.validator!(value)) {
          return ValidationResult.failure(
            rule.customErrorMessage ?? '参数验证失败: ${rule.fieldName}',
            rule.fieldName,
          );
        }
      }
    }
    return const ValidationResult.success();
  }
}

/// 常用验证器扩展
extension ValidationExtensions on Map<String, dynamic> {
  /// 获取必需的字符串或返回验证错误
  (String?, ValidationResult) getRequiredString(String fieldName) {
    final result = ParamValidator.requireString(this, fieldName);
    if (!result.isValid) return (null, result);
    return (this[fieldName] as String, result);
  }

  /// 获取可选字符串
  String? getOptionalString(String fieldName) {
    return ParamValidator.optionalString(this, fieldName);
  }

  /// 获取可选整数
  int? getOptionalInt(String fieldName) {
    return ParamValidator.optionalInt(this, fieldName);
  }

  /// 获取可选布尔值
  bool getOptionalBool(String fieldName, {bool defaultValue = false}) {
    return ParamValidator.optionalBool(this, fieldName, defaultValue: defaultValue);
  }
}
