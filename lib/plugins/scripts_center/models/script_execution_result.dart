/// 脚本执行结果模型
///
/// 封装脚本执行的结果信息，包括成功状态、返回值、错误信息等
class ScriptExecutionResult {
  /// 是否执行成功
  final bool success;

  /// 返回值（任意类型）
  final dynamic result;

  /// 错误信息（仅在失败时有值）
  final String? error;

  /// 执行耗时
  final Duration duration;

  /// 执行时间戳
  final DateTime timestamp;

  /// 脚本ID（可选，用于日志追踪）
  final String? scriptId;

  const ScriptExecutionResult({
    required this.success,
    this.result,
    this.error,
    required this.duration,
    required this.timestamp,
    this.scriptId,
  });

  /// 创建成功的执行结果
  factory ScriptExecutionResult.success({
    required dynamic result,
    required Duration duration,
    DateTime? timestamp,
    String? scriptId,
  }) {
    return ScriptExecutionResult(
      success: true,
      result: result,
      error: null,
      duration: duration,
      timestamp: timestamp ?? DateTime.now(),
      scriptId: scriptId,
    );
  }

  /// 创建失败的执行结果
  factory ScriptExecutionResult.failure({
    required String error,
    required Duration duration,
    DateTime? timestamp,
    String? scriptId,
  }) {
    return ScriptExecutionResult(
      success: false,
      result: null,
      error: error,
      duration: duration,
      timestamp: timestamp ?? DateTime.now(),
      scriptId: scriptId,
    );
  }

  /// 转换为JSON（用于日志记录）
  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'result': result?.toString(),
      'error': error,
      'duration_ms': duration.inMilliseconds,
      'timestamp': timestamp.toIso8601String(),
      if (scriptId != null) 'script_id': scriptId,
    };
  }

  @override
  String toString() {
    if (success) {
      return 'Success: $result (${duration.inMilliseconds}ms)';
    } else {
      return 'Failure: $error (${duration.inMilliseconds}ms)';
    }
  }
}
