import 'package:flutter/material.dart';

/// 现代化圆角心情追踪小组件示例
///
/// 特性:
/// - 周视图柱状图显示每日心情值
/// - 不同颜色区分积极(绿色)和消极(橙色)情绪
/// - 7天心情历史带表情图标
/// - 当前日期高亮显示
/// - Material Design 3 风格
class ModernRoundedMoodWidgetExample extends StatelessWidget {
  const ModernRoundedMoodWidgetExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('现代化心情追踪小组件'),
        backgroundColor: isDark ? const Color(0xFF111827) : const Color(0xFFDBE6D1),
      ),
      body: Container(
        color: isDark ? const Color(0xFF111827) : const Color(0xFFDBE6D1),
        child: const Center(
          child: ModernRoundedMoodWidget(),
        ),
      ),
    );
  }
}

/// 心情数据模型
class MoodEntry {
  final String dayLabel;  // M, T, W, T, F, S, S
  final double positiveValue;  // 0.0 - 1.0
  final double negativeValue;  // 0.0 - 1.0
  final MoodType moodType;
  final bool isToday;

  const MoodEntry({
    required this.dayLabel,
    required this.positiveValue,
    required this.negativeValue,
    required this.moodType,
    this.isToday = false,
  });
}

/// 心情类型
enum MoodType {
  positive,
  negative,
}

/// 现代化圆角心情追踪小组件
class ModernRoundedMoodWidget extends StatelessWidget {
  /// 模拟的周心情数据
  static const List<MoodEntry> _weekMoods = [
    MoodEntry(
      dayLabel: 'M',
      positiveValue: 0.15,
      negativeValue: 0.0,
      moodType: MoodType.positive,
    ),
    MoodEntry(
      dayLabel: 'T',
      positiveValue: 0.25,
      negativeValue: 0.0,
      moodType: MoodType.positive,
    ),
    MoodEntry(
      dayLabel: 'W',
      positiveValue: 0.40,
      negativeValue: 0.0,
      moodType: MoodType.positive,
    ),
    MoodEntry(
      dayLabel: 'T',
      positiveValue: 0.65,
      negativeValue: 0.0,
      moodType: MoodType.positive,
    ),
    MoodEntry(
      dayLabel: 'F',
      positiveValue: 0.85,
      negativeValue: 0.0,
      moodType: MoodType.positive,
      isToday: true,
    ),
    MoodEntry(
      dayLabel: 'S',
      positiveValue: 0.0,
      negativeValue: 0.15,
      moodType: MoodType.negative,
    ),
    MoodEntry(
      dayLabel: 'S',
      positiveValue: 0.0,
      negativeValue: 0.55,
      moodType: MoodType.negative,
    ),
  ];

  const ModernRoundedMoodWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 380,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 顶部标签和时间选择
          _buildHeader(context, isDark),
          const SizedBox(height: 32),

          // 周视图柱状图
          _buildWeeklyChart(context, isDark),
          const SizedBox(height: 8),

          // 星期标签
          _buildDayLabels(context, isDark),
          const SizedBox(height: 24),

          // 分隔线
          Container(
            height: 1,
            color: isDark ? const Color(0xFF374151) : const Color(0xFFF3F4F6),
          ),
          const SizedBox(height: 24),

          // 心情历史
          _buildMoodHistory(context, isDark),
        ],
      ),
    );
  }

  /// 构建顶部标签和时间选择
  Widget _buildHeader(BuildContext context, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            // Positive 标签
            _buildLegend(
              context,
              color: const Color(0xFF9DB36D),
              label: 'Positive',
              isDark: isDark,
            ),
            const SizedBox(width: 16),
            // Negative 标签
            _buildLegend(
              context,
              color: const Color(0xFFE88D3E),
              label: 'Negative',
              isDark: isDark,
            ),
          ],
        ),
        // 时间选择按钮
        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF374151) : const Color(0xFFF8F6F4),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            children: [
              Icon(
                Icons.calendar_today,
                size: 16,
                color: isDark ? const Color(0xFFD1D5DB) : const Color(0xFF6B7280),
              ),
              const SizedBox(width: 8),
              Text(
                'Monthly',
                style: TextStyle(
                  color: isDark ? const Color(0xFFD1D5DB) : const Color(0xFF4A3B32),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.expand_more,
                size: 16,
                color: isDark ? const Color(0xFFD1D5DB) : const Color(0xFF6B7280),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 构建图例标签
  Widget _buildLegend(
    BuildContext context, {
    required Color color,
    required String label,
    required bool isDark,
  }) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: isDark ? const Color(0xFFD1D5DB) : const Color(0xFF4A3B32),
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  /// 构建周视图柱状图
  Widget _buildWeeklyChart(BuildContext context, bool isDark) {
    return SizedBox(
      height: 160,
      child: Row(
        children: _weekMoods.map((mood) {
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: _buildMoodBar(context, mood, isDark),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// 构建单个心情柱
  Widget _buildMoodBar(BuildContext context, MoodEntry mood, bool isDark) {
    final primaryColor = const Color(0xFF9DB36D);
    final secondaryColor = const Color(0xFFE88D3E);
    final trackColor = isDark ? const Color(0xFF374151) : const Color(0xFFF2F4EF);

    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: trackColor,
        borderRadius: BorderRadius.circular(9999),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // 积极情绪柱
          if (mood.positiveValue > 0)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 160 * mood.positiveValue,
              child: Container(
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(9999),
                ),
              ),
            ),
          // 消极情绪柱
          if (mood.negativeValue > 0)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 160 * mood.negativeValue,
              child: Container(
                decoration: BoxDecoration(
                  color: secondaryColor,
                  borderRadius: BorderRadius.circular(9999),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 构建星期标签
  Widget _buildDayLabels(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Row(
        children: _weekMoods.map((mood) {
          return Expanded(
            child: Center(
              child: Text(
                mood.dayLabel,
                style: TextStyle(
                  color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// 构建心情历史
  Widget _buildMoodHistory(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 标题行
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Mood History',
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF4A3B32),
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            Icon(
              Icons.more_horiz,
              color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF9CA3AF),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // 7天心情图标
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildMoodIcon(
              context,
              dayLabel: 'Mon',
              moodType: MoodIconType.happy,
              isToday: false,
              isDark: isDark,
            ),
            _buildMoodIcon(
              context,
              dayLabel: 'Tue',
              moodType: MoodIconType.neutralHappy,
              isToday: false,
              isDark: isDark,
            ),
            _buildMoodIcon(
              context,
              dayLabel: 'Wed',
              moodType: MoodIconType.neutral,
              isToday: false,
              isDark: isDark,
            ),
            _buildMoodIcon(
              context,
              dayLabel: 'Thu',
              moodType: MoodIconType.happy,
              isToday: false,
              isDark: isDark,
            ),
            _buildMoodIcon(
              context,
              dayLabel: 'Fri',
              moodType: MoodIconType.neutralSad,
              isToday: true,
              isDark: isDark,
            ),
            _buildMoodIcon(
              context,
              dayLabel: 'Sat',
              moodType: MoodIconType.neutralFlat,
              isToday: false,
              isDark: isDark,
            ),
            _buildMoodIcon(
              context,
              dayLabel: 'Sun',
              moodType: MoodIconType.happy,
              isToday: false,
              isDark: isDark,
            ),
          ],
        ),
      ],
    );
  }

  /// 构建单个心情图标
  Widget _buildMoodIcon(
    BuildContext context, {
    required String dayLabel,
    required MoodIconType moodType,
    required bool isToday,
    required bool isDark,
  }) {
    final colors = _getMoodIconColors(moodType);

    return Column(
      children: [
        // 图标容器(如果是今天,显示高亮背景)
        Container(
          padding: isToday
              ? const EdgeInsets.symmetric(horizontal: 6, vertical: 6)
              : EdgeInsets.zero,
          decoration: isToday
              ? BoxDecoration(
                  color: isDark
                      ? const Color(0xFF374151).withOpacity(0.5)
                      : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(9999),
                  border: Border.all(
                    color: isDark ? const Color(0xFF4B5563) : const Color(0xFFE5E7EB),
                    width: 1,
                  ),
                )
              : null,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // 心情图标
              CustomPaint(
                size: const Size(40, 40),
                painter: _MoodIconPainter(
                  faceColor: colors.faceColor,
                  eyeColor: colors.eyeColor,
                  mouthType: moodType,
                ),
              ),
              // 今天指示器(点赞图标)
              if (isToday)
                Positioned(
                  bottom: -4,
                  right: -10,
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white : const Color(0xFF1F2937),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.thumb_up,
                      size: 12,
                      color: isDark ? const Color(0xFF1F2937) : Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // 星期标签
        Text(
          dayLabel,
          style: TextStyle(
            color: isToday
                ? (isDark ? const Color(0xFFD1D5DB) : const Color(0xFF374151))
                : (isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280)),
            fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  /// 获取心情图标颜色
  _MoodIconColors _getMoodIconColors(MoodIconType type) {
    switch (type) {
      case MoodIconType.happy:
        return _MoodIconColors(
          faceColor: const Color(0xFFFBBF24),
          eyeColor: const Color(0xFF4A3B32),
        );
      case MoodIconType.neutralHappy:
        return _MoodIconColors(
          faceColor: const Color(0xFF84A95E),
          eyeColor: const Color(0xFF2D3748),
        );
      case MoodIconType.neutral:
        return _MoodIconColors(
          faceColor: const Color(0xFF9B80F3),
          eyeColor: const Color(0xFF2D3748),
        );
      case MoodIconType.neutralSad:
        return _MoodIconColors(
          faceColor: const Color(0xFFE88D3E),
          eyeColor: const Color(0xFF4A3B32),
        );
      case MoodIconType.neutralFlat:
        return _MoodIconColors(
          faceColor: const Color(0xFFBCABA3),
          eyeColor: const Color(0xFF2D3748),
        );
    }
  }
}

/// 心情图标类型
enum MoodIconType {
  happy,          // 笑脸
  neutralHappy,   // 中性偏开心
  neutral,        // 中性(叉眼)
  neutralSad,     // 中性偏难过
  neutralFlat,    // 平淡(直线嘴)
}

/// 心情图标颜色配置
class _MoodIconColors {
  final Color faceColor;
  final Color eyeColor;

  const _MoodIconColors({
    required this.faceColor,
    required this.eyeColor,
  });
}

/// 自定义心情图标绘制器
class _MoodIconPainter extends CustomPainter {
  final Color faceColor;
  final Color eyeColor;
  final MoodIconType mouthType;

  _MoodIconPainter({
    required this.faceColor,
    required this.eyeColor,
    required this.mouthType,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // 绘制脸部圆形
    final facePaint = Paint()..color = faceColor;
    canvas.drawCircle(center, radius, facePaint);

    // 绘制眼睛
    final eyePaint = Paint()
      ..color = eyeColor
      ..style = PaintingStyle.fill;

    final leftEye = Offset(center.dx - radius * 0.3, center.dy - radius * 0.15);
    final rightEye = Offset(center.dx + radius * 0.3, center.dy - radius * 0.15);
    final eyeRadius = radius * 0.12;

    if (mouthType == MoodIconType.neutral) {
      // 叉眼 (X X)
      _drawCrossEyes(canvas, leftEye, rightEye, eyeRadius, eyePaint);
    } else {
      // 普通圆眼 (o o)
      canvas.drawCircle(leftEye, eyeRadius, eyePaint);
      canvas.drawCircle(rightEye, eyeRadius, eyePaint);
    }

    // 绘制嘴巴
    final mouthPaint = Paint()
      ..color = eyeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    _drawMouth(canvas, center, radius, mouthPaint);
  }

  /// 绘制叉眼
  void _drawCrossEyes(Canvas canvas, Offset left, Offset right, double radius, Paint paint) {
    final strokePaint = Paint()
      ..color = paint.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    final offset = radius * 0.6;

    // 左眼叉
    canvas.drawLine(Offset(left.dx - offset, left.dy - offset), Offset(left.dx + offset, left.dy + offset), strokePaint);
    canvas.drawLine(Offset(left.dx + offset, left.dy - offset), Offset(left.dx - offset, left.dy + offset), strokePaint);

    // 右眼叉
    canvas.drawLine(Offset(right.dx - offset, right.dy - offset), Offset(right.dx + offset, right.dy + offset), strokePaint);
    canvas.drawLine(Offset(right.dx + offset, right.dy - offset), Offset(right.dx - offset, right.dy + offset), strokePaint);
  }

  /// 绘制嘴巴
  void _drawMouth(Canvas canvas, Offset center, double radius, Paint paint) {
    final mouthY = center.dy + radius * 0.25;
    final mouthWidth = radius * 0.5;

    switch (mouthType) {
      case MoodIconType.happy:
        // 笑嘴 (U形)
        final path = Path();
        path.moveTo(center.dx - mouthWidth, mouthY - radius * 0.1);
        path.quadraticBezierTo(center.dx, mouthY + radius * 0.2, center.dx + mouthWidth, mouthY - radius * 0.1);
        canvas.drawPath(path, paint);
        break;
      case MoodIconType.neutralHappy:
        // 微笑嘴
        final path = Path();
        path.moveTo(center.dx - mouthWidth, mouthY);
        path.quadraticBezierTo(center.dx, mouthY + radius * 0.1, center.dx + mouthWidth, mouthY);
        canvas.drawPath(path, paint);
        break;
      case MoodIconType.neutral:
        // 弯曲嘴 (难过)
        final path = Path();
        path.moveTo(center.dx - mouthWidth * 0.8, mouthY + radius * 0.1);
        path.quadraticBezierTo(center.dx, mouthY - radius * 0.1, center.dx + mouthWidth * 0.8, mouthY + radius * 0.1);
        canvas.drawPath(path, paint);
        break;
      case MoodIconType.neutralSad:
        // 微难过嘴
        final path = Path();
        path.moveTo(center.dx - mouthWidth, mouthY + radius * 0.1);
        path.quadraticBezierTo(center.dx, mouthY - radius * 0.05, center.dx + mouthWidth, mouthY + radius * 0.1);
        canvas.drawPath(path, paint);
        break;
      case MoodIconType.neutralFlat:
        // 直线嘴
        canvas.drawLine(
          Offset(center.dx - mouthWidth, mouthY),
          Offset(center.dx + mouthWidth, mouthY),
          paint,
        );
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _MoodIconPainter oldDelegate) {
    return oldDelegate.faceColor != faceColor ||
        oldDelegate.eyeColor != eyeColor ||
        oldDelegate.mouthType != mouthType;
  }
}
