import 'package:flutter/material.dart';

/// 心情追踪组件示例页面
class MoodTrackerWidgetExample extends StatefulWidget {
  const MoodTrackerWidgetExample({super.key});

  @override
  State<MoodTrackerWidgetExample> createState() =>
      _MoodTrackerWidgetExampleState();
}

class _MoodTrackerWidgetExampleState extends State<MoodTrackerWidgetExample> {
  final List<DailyMood> _weekMoods = [
    DailyMood(
      day: 'M',
      icon: Icons.sentiment_dissatisfied,
      moodType: MoodType.bad,
      isLogged: false,
    ),
    DailyMood(
      day: 'T',
      icon: Icons.sentiment_satisfied,
      moodType: MoodType.good,
      isLogged: false,
    ),
    DailyMood(
      day: 'W',
      icon: Icons.sentiment_neutral,
      moodType: MoodType.neutral,
      isLogged: true,
    ),
    DailyMood(
      day: 'T',
      icon: Icons.sentiment_dissatisfied,
      moodType: MoodType.bad,
      isLogged: false,
    ),
    DailyMood(
      day: 'F',
      icon: Icons.sentiment_very_dissatisfied,
      moodType: MoodType.terrible,
      isLogged: false,
    ),
    DailyMood(
      day: 'S',
      icon: Icons.sentiment_neutral,
      moodType: MoodType.neutral,
      isLogged: false,
    ),
    DailyMood(
      day: 'S',
      icon: Icons.sentiment_satisfied,
      moodType: MoodType.good,
      isLogged: false,
    ),
  ];

  String _currentMoodText = 'Happy';
  int _loggedCount = 2;
  int _totalCount = 5;

  void _onDayTapped(int index) {
    setState(() {
      // 切换选中状态
      for (int i = 0; i < _weekMoods.length; i++) {
        _weekMoods[i] = _weekMoods[i].copyWith(isLogged: i == index);
      }

      // 更新当前心情文本
      final tappedDay = _weekMoods[index];
      _currentMoodText = _getMoodText(tappedDay.moodType);
      _loggedCount = _weekMoods.where((m) => m.isLogged).length;
    });
  }

  String _getMoodText(MoodType mood) {
    switch (mood) {
      case MoodType.good:
        return 'Happy';
      case MoodType.neutral:
        return 'Neutral';
      case MoodType.bad:
        return 'Sad';
      case MoodType.terrible:
        return 'Stressed';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('心情追踪组件'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
      ),
      body: Container(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.black
            : const Color(0xFFF2F2F7),
        child: Center(
          child: MoodTrackerWidget(
            currentMoodText: _currentMoodText,
            loggedCount: _loggedCount,
            totalCount: _totalCount,
            weekMoods: _weekMoods,
            onDayTapped: _onDayTapped,
          ),
        ),
      ),
    );
  }
}

/// 心情追踪卡片组件
class MoodTrackerWidget extends StatefulWidget {
  final String currentMoodText;
  final int loggedCount;
  final int totalCount;
  final List<DailyMood> weekMoods;
  final void Function(int index) onDayTapped;

  const MoodTrackerWidget({
    super.key,
    required this.currentMoodText,
    required this.loggedCount,
    required this.totalCount,
    required this.weekMoods,
    required this.onDayTapped,
  });

  @override
  State<MoodTrackerWidget> createState() => _MoodTrackerWidgetState();
}

class _MoodTrackerWidgetState extends State<MoodTrackerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );

    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF1F2937)
                  : Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 标题行
                _buildHeader(context),
                const SizedBox(height: 32),

                // 主要内容区
                _buildMainContent(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.sentiment_satisfied,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Mood',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ],
        ),
        InkWell(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('查看历史心情记录')),
            );
          },
          borderRadius: BorderRadius.circular(8),
          child: Row(
            children: [
              Text(
                'Today',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      fontWeight: FontWeight.w300,
                    ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right,
                color:
                    Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                size: 24,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMainContent(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedMoodText(moodText: widget.currentMoodText),
            const SizedBox(height: 4),
            Text(
              'Logged ${widget.loggedCount}/${widget.totalCount}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color:
                        Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    fontWeight: FontWeight.w300,
                  ),
            ),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int i = 0; i < widget.weekMoods.length; i += 1) ...[
              if (i > 0) const SizedBox(width: 8),
              _buildDayButton(context, i),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildDayButton(BuildContext context, int index) {
    final day = widget.weekMoods[index];
    final isSelected = day.isLogged;

    return InkWell(
      onTap: () => widget.onDayTapped(index),
      borderRadius: BorderRadius.circular(16),
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : (Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF374151)
                      : const Color(0xFFE5E7EB)),
              shape: BoxShape.circle,
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              day.icon,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(height: 8),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: isSelected
                      ? Theme.of(context).colorScheme.onSurface
                      : Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.6),
                ) ??
                TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isSelected
                      ? Theme.of(context).colorScheme.onSurface
                      : Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.6),
                ),
            child: Text(day.day),
          ),
        ],
      ),
    );
  }
}

/// 心情文本动画组件
class AnimatedMoodText extends StatefulWidget {
  final String moodText;

  const AnimatedMoodText({super.key, required this.moodText});

  @override
  State<AnimatedMoodText> createState() => _AnimatedMoodTextState();
}

class _AnimatedMoodTextState extends State<AnimatedMoodText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void didUpdateWidget(AnimatedMoodText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.moodText != widget.moodText) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Text(
        widget.moodText,
        style: Theme.of(context).textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
      ),
    );
  }
}

/// 每日心情数据模型
class DailyMood {
  final String day;
  final IconData icon;
  final MoodType moodType;
  final bool isLogged;

  DailyMood({
    required this.day,
    required this.icon,
    required this.moodType,
    required this.isLogged,
  });

  DailyMood copyWith({
    String? day,
    IconData? icon,
    MoodType? moodType,
    bool? isLogged,
  }) {
    return DailyMood(
      day: day ?? this.day,
      icon: icon ?? this.icon,
      moodType: moodType ?? this.moodType,
      isLogged: isLogged ?? this.isLogged,
    );
  }
}

/// 心情类型枚举
enum MoodType {
  good,
  neutral,
  bad,
  terrible,
}
