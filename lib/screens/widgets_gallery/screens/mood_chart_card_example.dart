import 'package:flutter/material.dart';

/// 心情图表卡片示例
class MoodChartCardExample extends StatelessWidget {
  const MoodChartCardExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('心情图表卡片')),
      body: Container(
        color: isDark ? Colors.black : const Color(0xFFF2F2F7),
        child: const Center(
          child: MoodChartCardWidget(
            dailyValues: [
              DailyMoodData(value: 0.15, isPositive: true),
              DailyMoodData(value: 0.25, isPositive: true),
              DailyMoodData(value: 0.40, isPositive: true),
              DailyMoodData(value: 0.65, isPositive: true),
              DailyMoodData(value: 0.85, isPositive: true),
              DailyMoodData(value: 0.65, isPositive: true),
              DailyMoodData(value: 0.15, isPositive: false),
              DailyMoodData(value: 0.55, isPositive: false),
              DailyMoodData(value: 0.30, isPositive: false),
              DailyMoodData(value: 0.45, isPositive: true),
              DailyMoodData(value: 0.25, isPositive: true),
              DailyMoodData(value: 0.15, isPositive: true),
            ],
            weeklyMoods: [
              MoodEmoji.happy,
              MoodEmoji.good,
              MoodEmoji.sad,
              MoodEmoji.happy,
              MoodEmoji.bad,
              MoodEmoji.neutral,
              MoodEmoji.happy,
            ],
          ),
        ),
      ),
    );
  }
}

/// 每日情绪数据模型
class DailyMoodData {
  final double value;
  final bool isPositive;

  const DailyMoodData({required this.value, required this.isPositive});
}

/// 心情表情枚举
enum MoodEmoji { happy, good, neutral, sad, bad }

/// 心情图表卡片小组件
class MoodChartCardWidget extends StatefulWidget {
  final List<DailyMoodData> dailyValues;
  final List<MoodEmoji> weeklyMoods;

  const MoodChartCardWidget({
    super.key,
    required this.dailyValues,
    required this.weeklyMoods,
  });

  @override
  State<MoodChartCardWidget> createState() => _MoodChartCardWidgetState();
}

class _MoodChartCardWidgetState extends State<MoodChartCardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeInAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // 使用主题颜色系统
    final primaryColor =
        isDark
            ? const Color(0xFF9DB36D) // 深色模式使用原型颜色
            : const Color(0xFF9DB36D); // Olive Green
    final secondaryColor = const Color(0xFFE88D3E); // Muted Orange
    final cardBackgroundColor = isDark ? const Color(0xFF1F2937) : Colors.white;
    final trackColor =
        isDark ? const Color(0xFF374151) : const Color(0xFFF2F4EF);
    final textColor = isDark ? Colors.white : const Color(0xFF4A3B32);
    final subtitleColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;

    return AnimatedBuilder(
      animation: _fadeInAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - _fadeInAnimation.value)),
          child: Opacity(
            opacity: _fadeInAnimation.value,
            child: Container(
              width: 400,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: cardBackgroundColor,
                borderRadius: BorderRadius.circular(40),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                    blurRadius: 40,
                    offset: const Offset(0, 20),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 顶部图例和筛选按钮
                  _buildHeader(
                    context,
                    primaryColor: primaryColor,
                    secondaryColor: secondaryColor,
                    textColor: textColor,
                  ),
                  const SizedBox(height: 32),

                  // 周期柱状图
                  _buildBarChart(
                    context,
                    trackColor: trackColor,
                    primaryColor: primaryColor,
                    secondaryColor: secondaryColor,
                  ),
                  const SizedBox(height: 12),

                  // 星期标签
                  _buildWeekdayLabels(subtitleColor),
                  const SizedBox(height: 24),

                  // 分隔线
                  Container(
                    height: 1,
                    color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                  ),
                  const SizedBox(height: 24),

                  // 心情历史记录
                  _buildMoodHistory(
                    context,
                    textColor: textColor,
                    subtitleColor: subtitleColor,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(
    BuildContext context, {
    required Color primaryColor,
    required Color secondaryColor,
    required Color textColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            _buildLegend(
              color: primaryColor,
              label: '积极',
              textColor: textColor,
            ),
            const SizedBox(width: 16),
            _buildLegend(
              color: secondaryColor,
              label: '消极',
              textColor: textColor,
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F6F4),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 8),
              Text(
                '本月',
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.expand_more, size: 16, color: Colors.grey.shade600),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLegend({
    required Color color,
    required String label,
    required Color textColor,
  }) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildBarChart(
    BuildContext context, {
    required Color trackColor,
    required Color primaryColor,
    required Color secondaryColor,
  }) {
    return SizedBox(
      height: 160,
      child: AnimatedBuilder(
        animation: _fadeInAnimation,
        builder: (context, child) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(widget.dailyValues.length, (index) {
              final data = widget.dailyValues[index];
              final barAnimation = CurvedAnimation(
                parent: _animationController,
                curve: Interval(
                  index * 0.04,
                  (0.5 + index * 0.04).clamp(0.0, 1.0),
                  curve: Curves.easeOutCubic,
                ),
              );

              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: index < widget.dailyValues.length - 1 ? 6 : 0,
                  ),
                  child: _MoodBar(
                    value: data.value,
                    color: data.isPositive ? primaryColor : secondaryColor,
                    trackColor: trackColor,
                    animation: barAnimation,
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }

  Widget _buildWeekdayLabels(Color color) {
    const weekdays = ['一', '二', '三', '四', '五', '六', '日'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(
        7,
        (index) => Expanded(
          child: Center(
            child: Text(
              weekdays[index],
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMoodHistory(
    BuildContext context, {
    required Color textColor,
    required Color subtitleColor,
  }) {
    final weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 标题行
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '心情历史',
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            Icon(Icons.more_horiz, color: Colors.grey.shade400),
          ],
        ),
        const SizedBox(height: 16),

        // 心情表情行
        AnimatedBuilder(
          animation: _fadeInAnimation,
          builder: (context, child) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(widget.weeklyMoods.length, (index) {
                final mood = widget.weeklyMoods[index];
                final isSelected = index == 4; // 周五高亮
                final itemAnimation = CurvedAnimation(
                  parent: _animationController,
                  curve: Interval(
                    0.3 + index * 0.08,
                    (0.3 + (index + 1) * 0.08).clamp(0.0, 1.0),
                    curve: Curves.easeOutCubic,
                  ),
                );

                return _MoodEmojiItem(
                  mood: mood,
                  label: weekdays[index],
                  isSelected: isSelected,
                  animation: itemAnimation,
                  textColor: textColor,
                  subtitleColor: subtitleColor,
                );
              }),
            );
          },
        ),
      ],
    );
  }
}

/// 单个情绪柱状条
class _MoodBar extends StatelessWidget {
  final double value;
  final Color color;
  final Color trackColor;
  final Animation<double> animation;

  const _MoodBar({
    required this.value,
    required this.color,
    required this.trackColor,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Container(
          height: 160,
          decoration: BoxDecoration(
            color: trackColor,
            borderRadius: BorderRadius.circular(8),
          ),
          clipBehavior: Clip.antiAlias,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: 160 * value * animation.value,
              color: color,
            ),
          ),
        );
      },
    );
  }
}

/// 单个心情表情项
class _MoodEmojiItem extends StatelessWidget {
  final MoodEmoji mood;
  final String label;
  final bool isSelected;
  final Animation<double> animation;
  final Color textColor;
  final Color subtitleColor;

  const _MoodEmojiItem({
    required this.mood,
    required this.label,
    required this.isSelected,
    required this.animation,
    required this.textColor,
    required this.subtitleColor,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Transform.scale(
          scale: 0.8 + 0.2 * animation.value,
          child: Opacity(
            opacity: animation.value,
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.all(isSelected ? 6 : 0),
                  decoration:
                      isSelected
                          ? BoxDecoration(
                            color: Colors.grey.shade100,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.grey.shade300,
                              width: 1,
                            ),
                          )
                          : null,
                  child: _buildMoodIcon(),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 16,
                  child: Text(
                    label,
                    style: TextStyle(
                      color: isSelected ? textColor : subtitleColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      height: 1.0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMoodIcon() {
    switch (mood) {
      case MoodEmoji.happy:
        return const _HappyFaceIcon();
      case MoodEmoji.good:
        return const _GoodFaceIcon();
      case MoodEmoji.neutral:
        return const _NeutralFaceIcon();
      case MoodEmoji.sad:
        return const _SadFaceIcon();
      case MoodEmoji.bad:
        return const _BadFaceIcon();
    }
  }
}

/// 开心表情图标
class _HappyFaceIcon extends StatelessWidget {
  const _HappyFaceIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: const BoxDecoration(
        color: Color(0xFFFBBF24),
        shape: BoxShape.circle,
      ),
      child: Stack(
        children: [
          // 左眼
          Positioned(
            top: 12,
            left: 10,
            child: Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: Color(0xFF4A3B32),
                shape: BoxShape.circle,
              ),
            ),
          ),
          // 右眼
          Positioned(
            top: 12,
            right: 10,
            child: Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: Color(0xFF4A3B32),
                shape: BoxShape.circle,
              ),
            ),
          ),
          // 嘴巴
          Positioned(
            top: 24,
            left: 12,
            child: CustomPaint(
              size: const Size(16, 8),
              painter: _SmilePainter(),
            ),
          ),
        ],
      ),
    );
  }
}

/// 微笑表情图标
class _GoodFaceIcon extends StatelessWidget {
  const _GoodFaceIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: const BoxDecoration(
        color: Color(0xFF84A95E),
        shape: BoxShape.circle,
      ),
      child: Stack(
        children: [
          // 左眼
          Positioned(
            top: 12,
            left: 10,
            child: Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: Color(0xFF2D3748),
                shape: BoxShape.circle,
              ),
            ),
          ),
          // 右眼
          Positioned(
            top: 12,
            right: 10,
            child: Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: Color(0xFF2D3748),
                shape: BoxShape.circle,
              ),
            ),
          ),
          // 嘴巴
          Positioned(
            top: 24,
            left: 12,
            child: CustomPaint(
              size: const Size(16, 8),
              painter: _SmilePainter(),
            ),
          ),
        ],
      ),
    );
  }
}

/// 中性表情图标
class _NeutralFaceIcon extends StatelessWidget {
  const _NeutralFaceIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: const BoxDecoration(
        color: Color(0xFFBCABA3),
        shape: BoxShape.circle,
      ),
      child: Stack(
        children: [
          // 左眼
          Positioned(
            top: 12,
            left: 10,
            child: Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: Color(0xFF2D3748),
                shape: BoxShape.circle,
              ),
            ),
          ),
          // 右眼
          Positioned(
            top: 12,
            right: 10,
            child: Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: Color(0xFF2D3748),
                shape: BoxShape.circle,
              ),
            ),
          ),
          // 嘴巴（直线）
          Positioned(
            top: 24,
            left: 10,
            child: Container(
              width: 20,
              height: 2,
              decoration: BoxDecoration(
                color: const Color(0xFF2D3748),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 难过表情图标
class _SadFaceIcon extends StatelessWidget {
  const _SadFaceIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: const BoxDecoration(
        color: Color(0xFF9B80F3),
        shape: BoxShape.circle,
      ),
      child: Stack(
        children: [
          // 左眼（X形）
          Positioned(
            top: 11,
            left: 9,
            child: CustomPaint(size: const Size(8, 8), painter: _XEyePainter()),
          ),
          // 右眼（X形）
          Positioned(
            top: 11,
            right: 9,
            child: CustomPaint(size: const Size(8, 8), painter: _XEyePainter()),
          ),
          // 嘴巴（倒弧线）
          Positioned(
            top: 24,
            left: 12,
            child: CustomPaint(
              size: const Size(16, 8),
              painter: _FrownPainter(),
            ),
          ),
        ],
      ),
    );
  }
}

/// 糟糕表情图标
class _BadFaceIcon extends StatelessWidget {
  const _BadFaceIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: const BoxDecoration(
        color: Color(0xFFE88D3E),
        shape: BoxShape.circle,
      ),
      child: Stack(
        children: [
          // 左眼
          Positioned(
            top: 12,
            left: 10,
            child: Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: Color(0xFF4A3B32),
                shape: BoxShape.circle,
              ),
            ),
          ),
          // 右眼
          Positioned(
            top: 12,
            right: 10,
            child: Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: Color(0xFF4A3B32),
                shape: BoxShape.circle,
              ),
            ),
          ),
          // 嘴巴（倒弧线）
          Positioned(
            top: 24,
            left: 12,
            child: CustomPaint(
              size: const Size(16, 8),
              painter: _FrownPainter(),
            ),
          ),
        ],
      ),
    );
  }
}

/// 微笑绘制器
class _SmilePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = const Color(0xFF4A3B32)
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(0, size.height * 0.3);
    path.quadraticBezierTo(
      size.width / 2,
      size.height * 1.2,
      size.width,
      size.height * 0.3,
    );
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 倒弧线绘制器（难过）
class _FrownPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = const Color(0xFF4A3B32)
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(0, size.height * 0.8);
    path.quadraticBezierTo(
      size.width / 2,
      size.height * -0.2,
      size.width,
      size.height * 0.8,
    );
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// X形眼睛绘制器
class _XEyePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = const Color(0xFF2D3748)
          ..strokeWidth = 1.5
          ..strokeCap = StrokeCap.round;

    // 左上到右下
    canvas.drawLine(const Offset(0, 0), Offset(size.width, size.height), paint);

    // 右上到左下
    canvas.drawLine(Offset(size.width, 0), Offset(0, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
