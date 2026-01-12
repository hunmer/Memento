/// 日记提示卡片数据模型
/// 用于日记、反思、提示等展示场景
class JournalPromptCardData {
  /// 星期几
  final String weekday;

  /// 提示问题
  final String prompt;

  const JournalPromptCardData({
    required this.weekday,
    required this.prompt,
  });

  /// 从 JSON 创建
  factory JournalPromptCardData.fromJson(Map<String, dynamic> json) {
    return JournalPromptCardData(
      weekday: json['weekday'] as String? ?? '',
      prompt: json['prompt'] as String? ?? '',
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'weekday': weekday,
      'prompt': prompt,
    };
  }

  /// 创建示例数据
  static JournalPromptCardData sample() {
    return const JournalPromptCardData(
      weekday: 'Monday',
      prompt: 'How will you make tomorrow meaningful?',
    );
  }
}
