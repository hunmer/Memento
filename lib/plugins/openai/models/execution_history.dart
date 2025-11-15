import 'package:uuid/uuid.dart';

/// 执行历史记录数据模型
///
/// 用于保存预设的每次执行记录，包括输入、输出、图片等信息
class ExecutionHistory {
  /// 唯一标识符
  final String id;

  /// 关联的预设ID
  final String presetId;

  /// 使用的智能体ID
  final String? agentId;

  /// 输入的提示词
  final String prompt;

  /// 选择的图片路径列表
  final List<String> imagePaths;

  /// AI响应输出
  final String response;

  /// 执行状态（success, error, running）
  final String status;

  /// 错误信息（如果有）
  final String? errorMessage;

  /// 创建时间
  final DateTime createdAt;

  /// 执行耗时（毫秒）
  final int? durationMs;

  ExecutionHistory({
    String? id,
    required this.presetId,
    this.agentId,
    required this.prompt,
    List<String>? imagePaths,
    this.response = '',
    this.status = 'running',
    this.errorMessage,
    DateTime? createdAt,
    this.durationMs,
  })  : id = id ?? const Uuid().v4(),
        imagePaths = imagePaths ?? [],
        createdAt = createdAt ?? DateTime.now();

  /// 从JSON创建对象
  factory ExecutionHistory.fromJson(Map<String, dynamic> json) {
    return ExecutionHistory(
      id: json['id'] as String,
      presetId: json['presetId'] as String,
      agentId: json['agentId'] as String?,
      prompt: json['prompt'] as String,
      imagePaths: (json['imagePaths'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      response: json['response'] as String? ?? '',
      status: json['status'] as String? ?? 'running',
      errorMessage: json['errorMessage'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      durationMs: json['durationMs'] as int?,
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'presetId': presetId,
      'agentId': agentId,
      'prompt': prompt,
      'imagePaths': imagePaths,
      'response': response,
      'status': status,
      'errorMessage': errorMessage,
      'createdAt': createdAt.toIso8601String(),
      'durationMs': durationMs,
    };
  }

  /// 创建副本
  ExecutionHistory copyWith({
    String? response,
    String? status,
    String? errorMessage,
    int? durationMs,
  }) {
    return ExecutionHistory(
      id: id,
      presetId: presetId,
      agentId: agentId,
      prompt: prompt,
      imagePaths: imagePaths,
      response: response ?? this.response,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      createdAt: createdAt,
      durationMs: durationMs ?? this.durationMs,
    );
  }

  @override
  String toString() {
    return 'ExecutionHistory(id: $id, presetId: $presetId, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ExecutionHistory && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
