import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';

/// 每日情绪数据模型
class DailyEmotion {
  /// 日期标签（如 'M', 'T', 'W' 等）
  final String day;

  /// 情绪图标
  final IconData icon;

  /// 情绪类型
  final EmotionType emotionType;

  /// 是否已记录
  final bool isLogged;

  const DailyEmotion({
    required this.day,
    required this.icon,
    required this.emotionType,
    required this.isLogged,
  });

  /// 创建副本
  DailyEmotion copyWith({
    String? day,
    IconData? icon,
    EmotionType? emotionType,
    bool? isLogged,
  }) {
    return DailyEmotion(
      day: day ?? this.day,
      icon: icon ?? this.icon,
      emotionType: emotionType ?? this.emotionType,
      isLogged: isLogged ?? this.isLogged,
    );
  }

  /// 从 JSON 创建
  factory DailyEmotion.fromJson(Map<String, dynamic> json) {
    return DailyEmotion(
      day: json['day'] as String,
      icon: IconData(
        json['iconCodePoint'] as int,
        fontFamily: 'MaterialIcons',
      ),
      emotionType: EmotionType.values.firstWhere(
        (e) => e.name == json['emotionType'],
        orElse: () => EmotionType.neutral,
      ),
      isLogged: json['isLogged'] as bool,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'day': day,
      'iconCodePoint': icon.codePoint,
      'emotionType': emotionType.name,
      'isLogged': isLogged,
    };
  }
}

/// 情绪类型枚举
enum EmotionType {
  /// 好情绪
  good,

  /// 中性情绪
  neutral,

  /// 坏情绪
  bad,

  /// 糟糕情绪
  terrible,
}

/// 情绪追踪卡片组件
///
/// 用于展示一周情绪记录的卡片组件，支持动画效果和主题适配。
/// 显示当前情绪文本、记录统计和周情绪按钮。
///
/// 使用示例：
/// ```dart
/// EmotionTrackerCard(
///   currentEmotionText: 'Happy',
///   loggedCount: 2,
///   totalCount: 5,
///   weekEmotions: [
///     DailyEmotion(
///       day: 'M',
///       icon: Icons.sentiment_satisfied,
///       emotionType: EmotionType.good,
///       isLogged: true,
///     ),
///     // ... 更多数据
///   ],
///   onDayTapped: (index) => print('Day $index tapped'),
///   onHistoryTap: () => print('History tapped'),
///   size: const MediumSize(),
/// )
/// ```
class EmotionTrackerCard extends StatefulWidget {
  /// 当前情绪文本
  final String currentEmotionText;

  /// 已记录天数
  final int loggedCount;

  /// 总天数
  final int totalCount;

  /// 周情绪数据列表
  final List<DailyEmotion> weekEmotions;

  /// 日期按钮点击回调
  final void Function(int index) onDayTapped;

  /// 历史记录点击回调
  final VoidCallback? onHistoryTap;

  /// 是否为内联模式（内联模式使用 double.maxFinite，非内联模式使用固定尺寸）
  final bool inline;

  /// 小组件尺寸
  final HomeWidgetSize size;

  const EmotionTrackerCard({
    super.key,
    required this.currentEmotionText,
    required this.loggedCount,
    required this.totalCount,
    required this.weekEmotions,
    required this.onDayTapped,
    this.onHistoryTap,
    this.inline = false,
    this.size = const MediumSize(),
  });

  @override
  State<EmotionTrackerCard> createState() => _EmotionTrackerCardState();
}

class _EmotionTrackerCardState extends State<EmotionTrackerCard>
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
    final size = widget.size;
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: size.getPadding().horizontal / 2),
        constraints: BoxConstraints(maxWidth: widget.inline ? double.maxFinite : 400),
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
            padding: size.getPadding(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 标题行
                _buildHeader(context),
                SizedBox(height: size.getTitleSpacing()),

                // 主要内容区
                _buildMainContent(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 构建标题行
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
              'Emotion',
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
                  const SnackBar(content: Text('查看历史情绪记录')),
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
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                size: 24,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 构建主要内容区
  Widget _buildMainContent(BuildContext context) {
    final size = widget.size;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedEmotionText(emotionText: widget.currentEmotionText),
            SizedBox(height: size.getItemSpacing() / 2),
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
            for (int i = 0; i < widget.weekEmotions.length; i += 1) ...[
              if (i > 0) SizedBox(width: size.getItemSpacing()),
              _buildDayButton(context, i),
            ],
          ],
        ),
      ],
    );
  }

  /// 构建日期按钮
  Widget _buildDayButton(BuildContext context, int index) {
    final day = widget.weekEmotions[index];
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

/// 情绪文本动画组件
class AnimatedEmotionText extends StatefulWidget {
  /// 情绪文本
  final String emotionText;

  const AnimatedEmotionText({super.key, required this.emotionText});

  @override
  State<AnimatedEmotionText> createState() => _AnimatedEmotionTextState();
}

class _AnimatedEmotionTextState extends State<AnimatedEmotionText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void didUpdateWidget(AnimatedEmotionText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.emotionText != widget.emotionText) {
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
        widget.emotionText,
        style: Theme.of(context).textTheme.titleMedium
      ),
    );
  }
}
