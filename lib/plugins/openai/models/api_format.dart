/// API 格式枚举
///
/// 定义支持的 LLM API 格式类型
enum ApiFormat {
  openai('openai', 'OpenAI'),
  anthropic('anthropic', 'Anthropic (Claude)'),
  minimax('minimax', 'MiniMax');

  final String value;
  final String label;

  const ApiFormat(this.value, this.label);

  /// 从字符串值获取枚举
  static ApiFormat fromString(String value) =>
      ApiFormat.values.firstWhere((e) => e.value == value, orElse: () => ApiFormat.openai);
}
