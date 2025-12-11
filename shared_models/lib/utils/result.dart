/// 统一的操作结果类型 - 客户端和服务端共享
///
/// 此文件提供类型安全的操作结果封装
library;

import 'dart:convert';

/// 操作结果 - 成功或失败
sealed class Result<T> {
  const Result();

  /// 创建成功结果
  factory Result.success(T data) = Success<T>;

  /// 创建失败结果
  factory Result.failure(String message, {String? code, dynamic details}) =
      Failure<T>;

  /// 是否成功
  bool get isSuccess => this is Success<T>;

  /// 是否失败
  bool get isFailure => this is Failure<T>;

  /// 获取数据（失败时返回 null）
  T? get dataOrNull => isSuccess ? (this as Success<T>).data : null;

  /// 获取错误（成功时返回 null）
  Failure<T>? get errorOrNull => isFailure ? (this as Failure<T>) : null;

  /// 映射成功值
  Result<R> map<R>(R Function(T) transform) {
    if (this is Success<T>) {
      return Result.success(transform((this as Success<T>).data));
    }
    final failure = this as Failure<T>;
    return Failure<R>(failure.message,
        code: failure.code, details: failure.details);
  }

  /// 链式操作
  Result<R> flatMap<R>(Result<R> Function(T) transform) {
    if (this is Success<T>) {
      return transform((this as Success<T>).data);
    }
    final failure = this as Failure<T>;
    return Failure<R>(failure.message,
        code: failure.code, details: failure.details);
  }

  /// 转换为 JSON 字符串（用于 JSAPI 响应）
  String toJsonString({Object? Function(T)? encoder}) {
    if (this is Success<T>) {
      final data = (this as Success<T>).data;
      if (encoder != null) {
        return jsonEncode(encoder(data));
      }
      return jsonEncode(data);
    }
    final failure = this as Failure<T>;
    return jsonEncode({
      'error': failure.message,
      if (failure.code != null) 'code': failure.code,
      if (failure.details != null) 'details': failure.details,
    });
  }

  /// 转换为 Map（用于 HTTP 响应）
  Map<String, dynamic> toResponseMap({Object? Function(T)? encoder}) {
    if (this is Success<T>) {
      final data = (this as Success<T>).data;
      return {
        'success': true,
        'data': encoder != null ? encoder(data) : data,
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
    final failure = this as Failure<T>;
    return {
      'success': false,
      'error': failure.message,
      if (failure.code != null) 'code': failure.code,
      if (failure.details != null) 'details': failure.details,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
}

/// 成功结果
class Success<T> extends Result<T> {
  final T data;

  const Success(this.data);

  @override
  String toString() => 'Success($data)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Success<T> && data == other.data);

  @override
  int get hashCode => data.hashCode;
}

/// 失败结果
class Failure<T> extends Result<T> {
  final String message;
  final String? code;
  final dynamic details;

  const Failure(this.message, {this.code, this.details});

  @override
  String toString() => 'Failure($message, code: $code)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Failure<T> && message == other.message && code == other.code);

  @override
  int get hashCode => Object.hash(message, code);
}

/// 常见错误码
class ErrorCodes {
  static const String notFound = 'NOT_FOUND';
  static const String invalidParams = 'INVALID_PARAMS';
  static const String unauthorized = 'UNAUTHORIZED';
  static const String forbidden = 'FORBIDDEN';
  static const String serverError = 'SERVER_ERROR';
  static const String conflict = 'CONFLICT';
  static const String validationError = 'VALIDATION_ERROR';
}

/// 快捷方法扩展
extension ResultExtensions<T> on Future<Result<T>> {
  /// 获取数据或抛出异常
  Future<T> getOrThrow() async {
    final result = await this;
    if (result is Success<T>) {
      return result.data;
    }
    throw Exception((result as Failure<T>).message);
  }

  /// 获取数据或返回默认值
  Future<T> getOrDefault(T defaultValue) async {
    final result = await this;
    return result.dataOrNull ?? defaultValue;
  }
}
