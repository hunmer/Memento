/// 每日反思卡片数据模型
/// 用于引导用户每日思考和记录
class DailyReflectionCardData {
  /// 星期几标签
  final String dayOfWeek;

  /// 引导性问题
  final String question;

  /// 卡片背景色（深色模式）
  final int? darkBackgroundColor;

  /// 主色调（按钮颜色）
  final int? primaryColor;

  const DailyReflectionCardData({
    required this.dayOfWeek,
    required this.question,
    this.darkBackgroundColor,
    this.primaryColor,
  });

  /// 从 JSON 创建
  factory DailyReflectionCardData.fromJson(Map<String, dynamic> json) {
    return DailyReflectionCardData(
      dayOfWeek: json['dayOfWeek'] as String? ?? '',
      question: json['question'] as String? ?? '',
      darkBackgroundColor: json['darkBackgroundColor'] as int?,
      primaryColor: json['primaryColor'] as int?,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'dayOfWeek': dayOfWeek,
      'question': question,
      'darkBackgroundColor': darkBackgroundColor,
      'primaryColor': primaryColor,
    };
  }

  /// 创建默认数据
  static DailyReflectionCardData get defaultData => const DailyReflectionCardData(
    dayOfWeek: 'Monday',
    question: 'How will you make tomorrow meaningful?',
    darkBackgroundColor: 0xFF2A2D45,
    primaryColor: 0xFF626D9E,
  );
}
