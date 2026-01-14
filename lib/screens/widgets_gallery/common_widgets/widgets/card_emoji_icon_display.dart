import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/widgets/common/emotion_tracker_card.dart';

/// 卡片表情图标展示小组件
///
/// 用于 widgets_gallery 的包装器组件，支持 fromProps 工厂方法。
class CardEmojiIconDisplay extends StatelessWidget {
  /// 当前情绪文本
  final String currentEmotionText;

  /// 已记录天数
  final int loggedCount;

  /// 总天数
  final int totalCount;

  /// 周情绪数据列表
  final List<DailyEmotion> weekEmotions;

  /// 日期按钮点击回调
  final void Function(int index)? onDayTapped;

  /// 历史记录点击回调
  final VoidCallback? onHistoryTap;

  const CardEmojiIconDisplay({
    super.key,
    required this.currentEmotionText,
    required this.loggedCount,
    required this.totalCount,
    required this.weekEmotions,
    this.onDayTapped,
    this.onHistoryTap,
  });

  /// 从 props 创建实例
  factory CardEmojiIconDisplay.fromProps(
    Map<String, dynamic> props,
    HomeWidgetSize size,
  ) {
    // 解析周情绪数据列表
    final weekEmotionsList = props['weekEmotions'] as List<dynamic>?;
    final List<DailyEmotion> weekEmotions = weekEmotionsList?.map((emotionJson) {
          final emotionMap = emotionJson as Map<String, dynamic>;
          return DailyEmotion(
            day: emotionMap['day'] as String,
            icon: IconData(
              emotionMap['iconCodePoint'] as int,
              fontFamily: 'MaterialIcons',
            ),
            emotionType: EmotionType.values.firstWhere(
              (e) => e.name == emotionMap['emotionType'],
              orElse: () => EmotionType.neutral,
            ),
            isLogged: emotionMap['isLogged'] as bool,
          );
        }).toList() ??
        [];

    return CardEmojiIconDisplay(
      currentEmotionText: props['currentEmotionText'] as String? ?? 'Happy',
      loggedCount: props['loggedCount'] as int? ?? 0,
      totalCount: props['totalCount'] as int? ?? 7,
      weekEmotions: weekEmotions,
      onDayTapped: null, // 由外部传入
      onHistoryTap: null, // 由外部传入
    );
  }

  @override
  Widget build(BuildContext context) {
    return EmotionTrackerCard(
      currentEmotionText: currentEmotionText,
      loggedCount: loggedCount,
      totalCount: totalCount,
      weekEmotions: weekEmotions,
      onDayTapped: onDayTapped ?? (index) {},
      onHistoryTap: onHistoryTap,
    );
  }
}
