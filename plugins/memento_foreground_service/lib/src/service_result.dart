/// 服务操作结果
class ServiceResult {
  /// 是否成功
  final bool success;

  /// 错误信息
  final String? error;

  const ServiceResult({
    required this.success,
    this.error,
  });

  /// 成功结果
  factory ServiceResult.success() => const ServiceResult(success: true);

  /// 失败结果
  factory ServiceResult.failure(String error) => ServiceResult(
        success: false,
        error: error,
      );

  @override
  String toString() => 'ServiceResult(success: $success, error: $error)';
}
