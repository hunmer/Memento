/// 字段过滤选项模型
///
/// 用于配置数据过滤行为，支持多种过滤策略。
library;

/// 数据过滤模式
enum FilterMode {
  /// 完整模式 - 返回所有字段
  full,

  /// 紧凑模式 - 移除冗长字段（description、content等）
  compact,

  /// 摘要模式 - 仅返回统计数据，不返回详细记录
  summary,
}

/// 字段过滤选项
class FilterOptions {
  /// 过滤模式
  final FilterMode mode;

  /// 字段白名单（只保留这些字段，优先级最高）
  final List<String>? fields;

  /// 字段黑名单（移除这些字段）
  final List<String>? excludeFields;

  /// 文本字段长度限制（字段名 -> 最大长度）
  final Map<String, int>? textLengthLimits;

  /// 是否生成统计摘要（用于 summary 模式）
  final bool generateSummary;

  /// 是否缩短字段名（使用 FieldUtils.fieldAbbreviations）
  final bool abbreviateFieldNames;

  const FilterOptions({
    this.mode = FilterMode.full,
    this.fields,
    this.excludeFields,
    this.textLengthLimits,
    this.generateSummary = true,
    this.abbreviateFieldNames = false,
  });

  /// 从参数 Map 创建过滤选项
  factory FilterOptions.fromParams(Map<String, dynamic>? params) {
    if (params == null) {
      return const FilterOptions();
    }

    // 解析 mode
    FilterMode mode = FilterMode.full;
    final modeStr = params['mode']?.toString().toLowerCase();
    if (modeStr != null) {
      switch (modeStr) {
        case 'summary':
        case 'sum':
        case 's':
          mode = FilterMode.summary;
          break;
        case 'compact':
        case 'comp':
        case 'c':
          mode = FilterMode.compact;
          break;
        case 'full':
        case 'f':
        case 'all':
          mode = FilterMode.full;
          break;
      }
    }

    // 解析 fields
    List<String>? fields;
    if (params['fields'] is List) {
      fields = (params['fields'] as List).map((e) => e.toString()).toList();
    }

    // 解析 excludeFields
    List<String>? excludeFields;
    if (params['excludeFields'] is List) {
      excludeFields =
          (params['excludeFields'] as List).map((e) => e.toString()).toList();
    }

    // 解析 textLengthLimits
    Map<String, int>? textLengthLimits;
    if (params['textLengthLimits'] is Map) {
      textLengthLimits = Map<String, int>.from(params['textLengthLimits']);
    }

    return FilterOptions(
      mode: mode,
      fields: fields,
      excludeFields: excludeFields,
      textLengthLimits: textLengthLimits,
      generateSummary: params['generateSummary'] ?? true,
      abbreviateFieldNames: params['abbreviateFieldNames'] ?? false,
    );
  }

  /// 是否需要过滤
  bool get needsFiltering {
    return mode != FilterMode.full ||
        fields != null ||
        excludeFields != null ||
        textLengthLimits != null ||
        abbreviateFieldNames;
  }

  /// 是否只返回摘要
  bool get isSummaryOnly => mode == FilterMode.summary;

  /// 是否需要返回记录列表
  bool get needsRecords => mode != FilterMode.summary;

  /// 复制并修改选项
  FilterOptions copyWith({
    FilterMode? mode,
    List<String>? fields,
    List<String>? excludeFields,
    Map<String, int>? textLengthLimits,
    bool? generateSummary,
    bool? abbreviateFieldNames,
  }) {
    return FilterOptions(
      mode: mode ?? this.mode,
      fields: fields ?? this.fields,
      excludeFields: excludeFields ?? this.excludeFields,
      textLengthLimits: textLengthLimits ?? this.textLengthLimits,
      generateSummary: generateSummary ?? this.generateSummary,
      abbreviateFieldNames: abbreviateFieldNames ?? this.abbreviateFieldNames,
    );
  }

  @override
  String toString() {
    return 'FilterOptions(mode: $mode, fields: $fields, excludeFields: $excludeFields)';
  }
}
