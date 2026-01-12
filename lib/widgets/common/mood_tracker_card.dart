import 'package:flutter/material.dart';

/// 每日心情数据模型
class DailyMood {
  /// 日期标签（如 'M', 'T', 'W' 等）
  final String day;

  /// 心情图标
  final IconData icon;

  /// 心情类型
  final MoodType moodType;

  /// 是否已记录
  final bool isLogged;

  const DailyMood({
    required this.day,
    required this.icon,
    required this.moodType,
    required this.isLogged,
  });

  /// 创建副本
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

  /// 从 JSON 创建
  factory DailyMood.fromJson(Map<String, dynamic> json) {
    return DailyMood(
      day: json['day'] as String,
      icon: IconData(json['iconCodePoint'] as int, fontFamily: 'MaterialIcons'),
      moodType: MoodType.values.firstWhere(
        (e) => e.name == json['moodType'],
        orElse: () => MoodType.neutral,
      ),
      isLogged: json['isLogged'] as bool,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'day': day,
      'iconCodePoint': icon.codePoint,
      'moodType': moodType.name,
      'isLogged': isLogged,
    };
  }
}

/// 心情类型枚举
enum MoodType {
  /// 好心情
  good,

  /// 中性心情
  neutral,

  /// 坏心情
  bad,

  /// 糟糕心情
  terrible,
}

/// 心情追踪卡片组件
///
/// 用于展示一周心情记录的卡片组件，支持动画效果和主题适配。
/// 显示当前心情文本、记录统计和周心情按钮。
///
/// 使用示例：
/// ```dart
/// MoodTrackerCard(
///   currentMoodText: 'Happy',
///   loggedCount: 2,
///   totalCount: 5,
///   weekMoods: [
///     DailyMood(
///       day: 'M',
///       icon: Icons.sentiment_satisfied,
///       moodType: MoodType.good,
///       isLogged: true,
///     ),
///     // ... 更多数据
///   ],
///   onDayTapped: (index) => print('Day $index tapped'),
///   onHistoryTap: () => print('History tapped'),
/// )
/// ```
class MoodTrackerCard extends StatefulWidget {
  /// 当前心情文本
  final String currentMoodText;

  /// 已记录天数
  final int loggedCount;

  /// 总天数
  final int totalCount;

  /// 周心情数据列表
  final List<DailyMood> weekMoods;

  /// 日期按钮点击回调
  final void Function(int index) onDayTapped;

  /// 历史记录点击回调
  final VoidCallback? onHistoryTap;

  const MoodTrackerCard({
    super.key,
    required this.currentMoodText,
    required this.loggedCount,
    required this.totalCount,
    required this.weekMoods,
    required this.onDayTapped,
    this.onHistoryTap,
  });

  @override
  State<MoodTrackerCard> createState() => _MoodTrackerCardState();
}

class _MoodTrackerCardState extends State<MoodTrackerCard>
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
          onTap: widget.onHistoryTap ??
              () {
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
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.6),
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
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.6),
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
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.3),
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
  /// 心情文本
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
