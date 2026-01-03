/// AI 消息生成状态枚举
enum AIMessageStatus {
  /// 待生成 - 消息已创建但尚未开始生成
  pending,

  /// 准备中 - 正在初始化生成过程
  preparing,

  /// 生成中 - 正在流式生成内容
  generating,

  /// 工具调用中 - 正在执行工具调用
  toolCalling,

  /// 已完成 - 生成成功完成
  completed,

  /// 已取消 - 生成被用户取消
  cancelled,

  /// 失败 - 生成过程中出现错误
  failed,
}

/// AI 消息状态数据
class AIMessageStatusData {
  /// 消息 ID
  final String messageId;

  /// 会话 ID
  final String conversationId;

  /// 当前状态
  final AIMessageStatus status;

  /// 状态更新时间
  final DateTime updatedAt;

  /// 生成此消息的 Agent ID（如果有）
  final String? generatedByAgentId;

  /// 链式执行 ID（如果是链式调用的一部分）
  final String? chainExecutionId;

  /// 链式调用中的步骤索引（从 0 开始）
  final int? chainStepIndex;

  /// 当前生成的内容片段（用于流式更新）
  final String? currentContent;

  /// 已生成的 token 数量
  final int tokenCount;

  /// 错误信息（如果状态为 failed）
  final String? error;

  /// 工具调用步骤数据（如果有）
  final List<ToolCallStepInfo>? toolCallSteps;

  /// 是否为最终总结消息
  final bool isFinalSummary;

  /// 额外的元数据
  final Map<String, dynamic>? metadata;

  AIMessageStatusData({
    required this.messageId,
    required this.conversationId,
    required this.status,
    required this.updatedAt,
    this.generatedByAgentId,
    this.chainExecutionId,
    this.chainStepIndex,
    this.currentContent,
    this.tokenCount = 0,
    this.error,
    this.toolCallSteps,
    this.isFinalSummary = false,
    this.metadata,
  });

  /// 复制并修改部分字段
  AIMessageStatusData copyWith({
    String? messageId,
    String? conversationId,
    AIMessageStatus? status,
    DateTime? updatedAt,
    String? generatedByAgentId,
    String? chainExecutionId,
    int? chainStepIndex,
    String? currentContent,
    int? tokenCount,
    String? error,
    List<ToolCallStepInfo>? toolCallSteps,
    bool? isFinalSummary,
    Map<String, dynamic>? metadata,
  }) {
    return AIMessageStatusData(
      messageId: messageId ?? this.messageId,
      conversationId: conversationId ?? this.conversationId,
      status: status ?? this.status,
      updatedAt: updatedAt ?? this.updatedAt,
      generatedByAgentId: generatedByAgentId ?? this.generatedByAgentId,
      chainExecutionId: chainExecutionId ?? this.chainExecutionId,
      chainStepIndex: chainStepIndex ?? this.chainStepIndex,
      currentContent: currentContent ?? this.currentContent,
      tokenCount: tokenCount ?? this.tokenCount,
      error: error ?? this.error,
      toolCallSteps: toolCallSteps ?? this.toolCallSteps,
      isFinalSummary: isFinalSummary ?? this.isFinalSummary,
      metadata: metadata ?? this.metadata,
    );
  }

  /// 是否为终止状态（completed、cancelled、failed）
  bool get isTerminal {
    return status == AIMessageStatus.completed ||
        status == AIMessageStatus.cancelled ||
        status == AIMessageStatus.failed;
  }

  /// 是否正在执行中（preparing、generating、toolCalling）
  bool get isActive {
    return status == AIMessageStatus.preparing ||
        status == AIMessageStatus.generating ||
        status == AIMessageStatus.toolCalling;
  }

  Map<String, dynamic> toJson() {
    return {
      'messageId': messageId,
      'conversationId': conversationId,
      'status': status.name,
      'updatedAt': updatedAt.toIso8601String(),
      'generatedByAgentId': generatedByAgentId,
      'chainExecutionId': chainExecutionId,
      'chainStepIndex': chainStepIndex,
      'currentContent': currentContent,
      'tokenCount': tokenCount,
      'error': error,
      'toolCallSteps': toolCallSteps?.map((e) => e.toJson()).toList(),
      'isFinalSummary': isFinalSummary,
      'metadata': metadata,
    };
  }

  factory AIMessageStatusData.fromJson(Map<String, dynamic> json) {
    return AIMessageStatusData(
      messageId: json['messageId'] as String,
      conversationId: json['conversationId'] as String,
      status: AIMessageStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => AIMessageStatus.pending,
      ),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      generatedByAgentId: json['generatedByAgentId'] as String?,
      chainExecutionId: json['chainExecutionId'] as String?,
      chainStepIndex: json['chainStepIndex'] as int?,
      currentContent: json['currentContent'] as String?,
      tokenCount: json['tokenCount'] as int? ?? 0,
      error: json['error'] as String?,
      toolCallSteps: (json['toolCallSteps'] as List?)
          ?.map((e) => ToolCallStepInfo.fromJson(e as Map<String, dynamic>))
          .toList(),
      isFinalSummary: json['isFinalSummary'] as bool? ?? false,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }
}

/// 工具调用步骤信息
class ToolCallStepInfo {
  /// 步骤索引
  final int index;

  /// 步骤方法名称
  final String method;

  /// 步骤标题
  final String title;

  /// 步骤描述
  final String desc;

  /// 执行状态
  final ToolCallExecutionStatus status;

  /// 执行数据
  final String data;

  /// 执行结果（成功后）
  final String? result;

  /// 错误信息（失败时）
  final String? error;

  /// 开始时间
  final DateTime? startedAt;

  /// 完成时间
  final DateTime? completedAt;

  ToolCallStepInfo({
    required this.index,
    required this.method,
    required this.title,
    required this.desc,
    required this.status,
    required this.data,
    this.result,
    this.error,
    this.startedAt,
    this.completedAt,
  });

  /// 执行耗时（毫秒）
  int? get duration {
    if (startedAt != null && completedAt != null) {
      return completedAt!.difference(startedAt!).inMilliseconds;
    }
    return null;
  }

  ToolCallStepInfo copyWith({
    int? index,
    String? method,
    String? title,
    String? desc,
    ToolCallExecutionStatus? status,
    String? data,
    String? result,
    String? error,
    DateTime? startedAt,
    DateTime? completedAt,
  }) {
    return ToolCallStepInfo(
      index: index ?? this.index,
      method: method ?? this.method,
      title: title ?? this.title,
      desc: desc ?? this.desc,
      status: status ?? this.status,
      data: data ?? this.data,
      result: result ?? this.result,
      error: error ?? this.error,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'index': index,
      'method': method,
      'title': title,
      'desc': desc,
      'status': status.name,
      'data': data,
      'result': result,
      'error': error,
      'startedAt': startedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  factory ToolCallStepInfo.fromJson(Map<String, dynamic> json) {
    return ToolCallStepInfo(
      index: json['index'] as int,
      method: json['method'] as String,
      title: json['title'] as String,
      desc: json['desc'] as String,
      status: ToolCallExecutionStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => ToolCallExecutionStatus.pending,
      ),
      data: json['data'] as String,
      result: json['result'] as String?,
      error: json['error'] as String?,
      startedAt: json['startedAt'] != null
          ? DateTime.parse(json['startedAt'] as String)
          : null,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
    );
  }
}

/// 工具调用执行状态
enum ToolCallExecutionStatus {
  /// 等待执行
  pending,

  /// 执行中
  running,

  /// 执行成功
  success,

  /// 执行失败
  failed,
}
