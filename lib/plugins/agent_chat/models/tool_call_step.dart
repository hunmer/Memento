/// 工具调用步骤模型
///
/// 用于表示 AI 返回的工具调用 JSON 中的单个步骤
class ToolCallStep {
    /// 执行方法类型
    /// - 'run_js': 执行 JavaScript 代码
    /// - 其他类型预留扩展
    final String method;

    /// 步骤标题（显示在 UI 上）
    final String title;

    /// 步骤描述（说明这一步在做什么）
    final String desc;

    /// 执行数据
    /// - 当 method='run_js' 时，为 JavaScript 代码字符串
    final String data;

    /// 执行状态
    ToolCallStatus status;

    /// 执行结果（成功时的返回值）
    String? result;

    /// 错误信息（失败时的错误描述）
    String? error;

    ToolCallStep({
        required this.method,
        required this.title,
        required this.desc,
        required this.data,
        this.status = ToolCallStatus.pending,
        this.result,
        this.error,
    });

    /// 从 JSON 创建
    factory ToolCallStep.fromJson(Map<String, dynamic> json) {
        return ToolCallStep(
            method: json['method'] as String? ?? 'run_js',
            title: json['title'] as String? ?? '执行步骤',
            desc: json['desc'] as String? ?? '',
            data: json['data'] as String? ?? '',
        );
    }

    /// 转换为 JSON
    Map<String, dynamic> toJson() {
        return {
            'method': method,
            'title': title,
            'desc': desc,
            'data': data,
            'status': status.toString(),
            'result': result,
            'error': error,
        };
    }

    /// 复制并修改
    ToolCallStep copyWith({
        String? method,
        String? title,
        String? desc,
        String? data,
        ToolCallStatus? status,
        String? result,
        String? error,
    }) {
        return ToolCallStep(
            method: method ?? this.method,
            title: title ?? this.title,
            desc: desc ?? this.desc,
            data: data ?? this.data,
            status: status ?? this.status,
            result: result ?? this.result,
            error: error ?? this.error,
        );
    }
}

/// 工具调用执行状态
enum ToolCallStatus {
    /// 等待执行
    pending,

    /// 执行中
    running,

    /// 执行成功
    success,

    /// 执行失败
    failed,
}

/// 工具调用响应（包含多个步骤）
class ToolCallResponse {
    /// 工具调用步骤列表
    final List<ToolCallStep> steps;

    ToolCallResponse({
        required this.steps,
    });

    /// 从 JSON 创建
    factory ToolCallResponse.fromJson(Map<String, dynamic> json) {
        final stepsJson = json['steps'] as List<dynamic>? ?? [];
        final steps = stepsJson
            .map((stepJson) => ToolCallStep.fromJson(stepJson as Map<String, dynamic>))
            .toList();

        return ToolCallResponse(steps: steps);
    }

    /// 转换为 JSON
    Map<String, dynamic> toJson() {
        return {
            'steps': steps.map((step) => step.toJson()).toList(),
        };
    }

    /// 是否所有步骤都成功
    bool get allSuccess {
        return steps.every((step) => step.status == ToolCallStatus.success);
    }

    /// 是否有步骤失败
    bool get hasFailure {
        return steps.any((step) => step.status == ToolCallStatus.failed);
    }

    /// 获取所有成功步骤的结果
    List<String> get successResults {
        return steps
            .where((step) => step.status == ToolCallStatus.success && step.result != null)
            .map((step) => step.result!)
            .toList();
    }
}
