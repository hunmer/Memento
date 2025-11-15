/// Memento Prompt 分析数据模式
///
/// 用于控制 Prompt 方法返回的数据详细程度，以优化 token 消耗。
///
/// 三种模式的 token 消耗对比（以 Activity 插件为例）：
/// - summary: ~800 tokens (仅统计摘要)
/// - compact: ~2000 tokens (简化字段的记录列表)
/// - full: ~8000 tokens (完整数据)
library;

/// 分析数据模式枚举
enum AnalysisMode {
  /// 摘要模式 - 仅返回统计数据，无详细记录列表
  ///
  /// 适用场景：
  /// - 快速概览数据趋势
  /// - 生成统计报告
  /// - Token 预算有限时
  ///
  /// 返回格式示例：
  /// ```json
  /// {
  ///   "sum": {
  ///     "total": 100,
  ///     "cnt": 50,
  ///     "dur": 3600
  ///   }
  /// }
  /// ```
  summary,

  /// 紧凑模式 - 返回简化字段的记录列表
  ///
  /// 适用场景：
  /// - 需要查看具体记录但不需要完整内容
  /// - 平衡数据详细度和 token 消耗
  /// - 列表展示和快速筛选
  ///
  /// 返回格式示例：
  /// ```json
  /// {
  ///   "sum": { "total": 10 },
  ///   "recs": [
  ///     {
  ///       "id": "uuid",
  ///       "title": "标题",
  ///       "ts": "2025-01-15T09:00:00",
  ///       "tags": ["标签1"]
  ///     }
  ///   ]
  /// }
  /// ```
  ///
  /// 省略字段：
  /// - description/content (冗长的描述内容)
  /// - metadata (元数据)
  /// - 其他非核心字段
  compact,

  /// 完整模式 - 返回所有字段的完整数据
  ///
  /// 适用场景：
  /// - 需要访问所有数据字段
  /// - 详细分析和数据导出
  /// - 向后兼容旧版实现
  ///
  /// 返回格式：与 jsAPI 返回的原始数据一致
  full,
}

/// 分析模式扩展方法
extension AnalysisModeExtension on AnalysisMode {
  /// 从字符串解析分析模式
  ///
  /// 支持的字符串值（不区分大小写）：
  /// - "summary", "sum", "s" -> AnalysisMode.summary
  /// - "compact", "comp", "c" -> AnalysisMode.compact
  /// - "full", "f", "all" -> AnalysisMode.full
  ///
  /// 默认值：未识别的字符串返回 [AnalysisMode.summary]
  static AnalysisMode fromString(String? mode) {
    if (mode == null || mode.isEmpty) {
      return AnalysisMode.summary;
    }

    final normalizedMode = mode.toLowerCase().trim();
    switch (normalizedMode) {
      case 'summary':
      case 'sum':
      case 's':
        return AnalysisMode.summary;
      case 'compact':
      case 'comp':
      case 'c':
        return AnalysisMode.compact;
      case 'full':
      case 'f':
      case 'all':
        return AnalysisMode.full;
      default:
        // 默认返回 summary 模式以节省 token
        return AnalysisMode.summary;
    }
  }

  /// 转换为字符串
  String toShortString() {
    switch (this) {
      case AnalysisMode.summary:
        return 'summary';
      case AnalysisMode.compact:
        return 'compact';
      case AnalysisMode.full:
        return 'full';
    }
  }

  /// 是否为摘要模式
  bool get isSummary => this == AnalysisMode.summary;

  /// 是否为紧凑模式
  bool get isCompact => this == AnalysisMode.compact;

  /// 是否为完整模式
  bool get isFull => this == AnalysisMode.full;

  /// 是否需要返回记录列表
  bool get needsRecords => this != AnalysisMode.summary;

  /// 是否需要返回完整字段
  bool get needsFullFields => this == AnalysisMode.full;
}

/// 分析模式工具类
class AnalysisModeUtils {
  AnalysisModeUtils._(); // 私有构造函数，禁止实例化

  /// 从参数 Map 中解析分析模式
  ///
  /// 查找顺序：
  /// 1. params['mode']
  /// 2. params['analysisMode']
  /// 3. 默认值 [AnalysisMode.summary]
  static AnalysisMode parseFromParams(Map<String, dynamic>? params) {
    if (params == null) {
      return AnalysisMode.summary;
    }

    final modeStr = params['mode'] ?? params['analysisMode'];
    return AnalysisModeExtension.fromString(modeStr?.toString());
  }

  /// 验证模式是否有效
  static bool isValidMode(String? mode) {
    if (mode == null || mode.isEmpty) {
      return false;
    }

    final normalizedMode = mode.toLowerCase().trim();
    return const ['summary', 'sum', 's', 'compact', 'comp', 'c', 'full', 'f', 'all']
        .contains(normalizedMode);
  }

  /// 获取所有支持的模式字符串
  static List<String> getAllModeStrings() {
    return ['summary', 'compact', 'full'];
  }

  /// 获取模式说明
  static String getModeDescription(AnalysisMode mode) {
    switch (mode) {
      case AnalysisMode.summary:
        return '摘要模式：仅返回统计数据，最节省 token';
      case AnalysisMode.compact:
        return '紧凑模式：返回简化字段的记录列表，平衡详细度和 token 消耗';
      case AnalysisMode.full:
        return '完整模式：返回所有字段的完整数据';
    }
  }
}
