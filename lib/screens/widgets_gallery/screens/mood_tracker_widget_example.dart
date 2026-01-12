import 'package:flutter/material.dart';
import 'package:Memento/widgets/common/emotion_tracker_card.dart';

/// 心情追踪组件示例页面
class MoodTrackerWidgetExample extends StatefulWidget {
  const MoodTrackerWidgetExample({super.key});

  @override
  State<MoodTrackerWidgetExample> createState() =>
      _MoodTrackerWidgetExampleState();
}

class _MoodTrackerWidgetExampleState extends State<MoodTrackerWidgetExample> {
  final List<DailyEmotion> _weekEmotions = [
    DailyEmotion(
      day: 'M',
      icon: Icons.sentiment_dissatisfied,
      emotionType: EmotionType.bad,
      isLogged: false,
    ),
    DailyEmotion(
      day: 'T',
      icon: Icons.sentiment_satisfied,
      emotionType: EmotionType.good,
      isLogged: false,
    ),
    DailyEmotion(
      day: 'W',
      icon: Icons.sentiment_neutral,
      emotionType: EmotionType.neutral,
      isLogged: true,
    ),
    DailyEmotion(
      day: 'T',
      icon: Icons.sentiment_dissatisfied,
      emotionType: EmotionType.bad,
      isLogged: false,
    ),
    DailyEmotion(
      day: 'F',
      icon: Icons.sentiment_very_dissatisfied,
      emotionType: EmotionType.terrible,
      isLogged: false,
    ),
    DailyEmotion(
      day: 'S',
      icon: Icons.sentiment_neutral,
      emotionType: EmotionType.neutral,
      isLogged: false,
    ),
    DailyEmotion(
      day: 'S',
      icon: Icons.sentiment_satisfied,
      emotionType: EmotionType.good,
      isLogged: false,
    ),
  ];

  String _currentEmotionText = 'Happy';
  int _loggedCount = 2;
  final int _totalCount = 5;

  void _onDayTapped(int index) {
    setState(() {
      // 切换选中状态
      for (int i = 0; i < _weekEmotions.length; i++) {
        _weekEmotions[i] = _weekEmotions[i].copyWith(isLogged: i == index);
      }

      // 更新当前情绪文本
      final tappedDay = _weekEmotions[index];
      _currentEmotionText = _getEmotionText(tappedDay.emotionType);
      _loggedCount = _weekEmotions.where((e) => e.isLogged).length;
    });
  }

  String _getEmotionText(EmotionType emotion) {
    switch (emotion) {
      case EmotionType.good:
        return 'Happy';
      case EmotionType.neutral:
        return 'Neutral';
      case EmotionType.bad:
        return 'Sad';
      case EmotionType.terrible:
        return 'Stressed';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('情绪追踪组件'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
      ),
      body: Container(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.black
            : const Color(0xFFF2F2F7),
        child: Center(
          child: EmotionTrackerCard(
            currentEmotionText: _currentEmotionText,
            loggedCount: _loggedCount,
            totalCount: _totalCount,
            weekEmotions: _weekEmotions,
            onDayTapped: _onDayTapped,
            onHistoryTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('查看历史情绪记录')),
              );
            },
          ),
        ),
      ),
    );
  }
}
