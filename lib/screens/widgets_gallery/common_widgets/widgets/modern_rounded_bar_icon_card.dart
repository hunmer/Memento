import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';

/// 柱状图标数据模型
class BarIconEntry {
  final String dayLabel;
  final double positiveValue;
  final double negativeValue;
  final BarIconType moodType;
  final bool isToday;

  const BarIconEntry({
    required this.dayLabel,
    required this.positiveValue,
    required this.negativeValue,
    required this.moodType,
    this.isToday = false,
  });

  /// 从 JSON 创建
  factory BarIconEntry.fromJson(Map<String, dynamic> json) {
    return BarIconEntry(
      dayLabel: json['dayLabel'] as String? ?? '',
      positiveValue: (json['positiveValue'] as num?)?.toDouble() ?? 0.0,
      negativeValue: (json['negativeValue'] as num?)?.toDouble() ?? 0.0,
      moodType: BarIconTypeExtension.fromJson(json['moodType'] as String? ?? 'positive'),
      isToday: json['isToday'] as bool? ?? false,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'dayLabel': dayLabel,
      'positiveValue': positiveValue,
      'negativeValue': negativeValue,
      'moodType': moodType.toJson(),
      'isToday': isToday,
    };
  }
}

/// 心情类型枚举
enum BarIconType {
  positive,
  negative,
}

/// 心情类型扩展
extension BarIconTypeExtension on BarIconType {
  String toJson() => name;

  static BarIconType fromJson(String value) {
    return BarIconType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => BarIconType.positive,
    );
  }
}

/// 心情图标类型
enum MoodIconType {
  happy,
  neutralHappy,
  neutral,
  neutralSad,
  neutralFlat,
}

/// 现代化圆角心情追踪小组件
class ModernRoundedBarIconCard extends StatelessWidget {
  final List<BarIconEntry> weekMoods;

  const ModernRoundedBarIconCard({
    super.key,
    required this.weekMoods,
  });

  /// 从 props 创建实例（用于公共小组件系统）
  factory ModernRoundedBarIconCard.fromProps(
    Map<String, dynamic> props,
    HomeWidgetSize size,
  ) {
    final moodsList = (props['weekMoods'] as List<dynamic>?)
            ?.map((e) => BarIconEntry.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [
          BarIconEntry(
            dayLabel: 'M',
            positiveValue: 0.15,
            negativeValue: 0.0,
            moodType: BarIconType.positive,
          ),
          BarIconEntry(
            dayLabel: 'T',
            positiveValue: 0.25,
            negativeValue: 0.0,
            moodType: BarIconType.positive,
          ),
          BarIconEntry(
            dayLabel: 'W',
            positiveValue: 0.40,
            negativeValue: 0.0,
            moodType: BarIconType.positive,
          ),
          BarIconEntry(
            dayLabel: 'T',
            positiveValue: 0.65,
            negativeValue: 0.0,
            moodType: BarIconType.positive,
          ),
          BarIconEntry(
            dayLabel: 'F',
            positiveValue: 0.85,
            negativeValue: 0.0,
            moodType: BarIconType.positive,
            isToday: true,
          ),
          BarIconEntry(
            dayLabel: 'S',
            positiveValue: 0.0,
            negativeValue: 0.15,
            moodType: BarIconType.negative,
          ),
          BarIconEntry(
            dayLabel: 'S',
            positiveValue: 0.0,
            negativeValue: 0.55,
            moodType: BarIconType.negative,
          ),
        ];

    return ModernRoundedBarIconCard(weekMoods: moodsList);
  }

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
          _buildHeader(context, isDark),
          const SizedBox(height: 32),
          _buildWeeklyChart(context, isDark),
          const SizedBox(height: 8),
          _buildDayLabels(context, isDark),
          const SizedBox(height: 24),
          Container(
            height: 1,
            color: isDark ? const Color(0xFF374151) : const Color(0xFFF3F4F6),
          ),
          const SizedBox(height: 24),
          _buildMoodHistory(context, isDark),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            _buildLegend(context, color: const Color(0xFF9DB36D), label: 'Positive', isDark: isDark),
            const SizedBox(width: 16),
            _buildLegend(context, color: const Color(0xFFE88D3E), label: 'Negative', isDark: isDark),
          ],
        ),
        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF374151) : const Color(0xFFF8F6F4),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            children: [
              Icon(Icons.calendar_today, size: 16, color: isDark ? const Color(0xFFD1D5DB) : const Color(0xFF6B7280)),
              const SizedBox(width: 8),
              Text('Monthly', style: TextStyle(color: isDark ? const Color(0xFFD1D5DB) : const Color(0xFF4A3B32), fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(width: 4),
              Icon(Icons.expand_more, size: 16, color: isDark ? const Color(0xFFD1D5DB) : const Color(0xFF6B7280)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLegend(BuildContext context, {required Color color, required String label, required bool isDark}) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(color: isDark ? const Color(0xFFD1D5DB) : const Color(0xFF4A3B32), fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }

  Widget _buildWeeklyChart(BuildContext context, bool isDark) {
    return SizedBox(
      height: 160,
      child: Row(
        children: weekMoods.map((mood) {
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

  Widget _buildMoodBar(BuildContext context, BarIconEntry mood, bool isDark) {
    final primaryColor = const Color(0xFF9DB36D);
    final secondaryColor = const Color(0xFFE88D3E);
    final trackColor = isDark ? const Color(0xFF374151) : const Color(0xFFF2F4EF);

    return Container(
      height: 160,
      decoration: BoxDecoration(color: trackColor, borderRadius: BorderRadius.circular(9999)),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          if (mood.positiveValue > 0)
            Positioned(bottom: 0, left: 0, right: 0, height: 160 * mood.positiveValue, child: Container(decoration: BoxDecoration(color: primaryColor, borderRadius: BorderRadius.circular(9999)))),
          if (mood.negativeValue > 0)
            Positioned(bottom: 0, left: 0, right: 0, height: 160 * mood.negativeValue, child: Container(decoration: BoxDecoration(color: secondaryColor, borderRadius: BorderRadius.circular(9999)))),
        ],
      ),
    );
  }

  Widget _buildDayLabels(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Row(
        children: weekMoods.map((mood) {
          return Expanded(
            child: Center(
              child: Text(mood.dayLabel, style: TextStyle(color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280), fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMoodHistory(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Mood History', style: TextStyle(color: isDark ? Colors.white : const Color(0xFF4A3B32), fontWeight: FontWeight.bold, fontSize: 20)),
            Icon(Icons.more_horiz, color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF9CA3AF)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildMoodIcon(context, dayLabel: 'Mon', moodType: MoodIconType.happy, isToday: false, isDark: isDark),
            _buildMoodIcon(context, dayLabel: 'Tue', moodType: MoodIconType.neutralHappy, isToday: false, isDark: isDark),
            _buildMoodIcon(context, dayLabel: 'Wed', moodType: MoodIconType.neutral, isToday: false, isDark: isDark),
            _buildMoodIcon(context, dayLabel: 'Thu', moodType: MoodIconType.happy, isToday: false, isDark: isDark),
            _buildMoodIcon(context, dayLabel: 'Fri', moodType: MoodIconType.neutralSad, isToday: true, isDark: isDark),
            _buildMoodIcon(context, dayLabel: 'Sat', moodType: MoodIconType.neutralFlat, isToday: false, isDark: isDark),
            _buildMoodIcon(context, dayLabel: 'Sun', moodType: MoodIconType.happy, isToday: false, isDark: isDark),
          ],
        ),
      ],
    );
  }

  Widget _buildMoodIcon(BuildContext context, {required String dayLabel, required MoodIconType moodType, required bool isToday, required bool isDark}) {
    final colors = _getMoodIconColors(moodType);

    return Column(
      children: [
        Container(
          padding: isToday ? const EdgeInsets.symmetric(horizontal: 6, vertical: 6) : EdgeInsets.zero,
          decoration: isToday
              ? BoxDecoration(
                  color: isDark ? const Color(0xFF374151).withOpacity(0.5) : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(9999),
                  border: Border.all(color: isDark ? const Color(0xFF4B5563) : const Color(0xFFE5E7EB), width: 1),
                )
              : null,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              CustomPaint(
                size: const Size(40, 40),
                painter: _MoodIconPainter(faceColor: colors.faceColor, eyeColor: colors.eyeColor, mouthType: moodType),
              ),
              if (isToday)
                Positioned(
                  bottom: -4,
                  right: -10,
                  child: Container(
                    decoration: BoxDecoration(color: isDark ? Colors.white : const Color(0xFF1F2937), shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4, offset: const Offset(0, 2))]),
                    padding: const EdgeInsets.all(4),
                    child: Icon(Icons.thumb_up, size: 12, color: isDark ? const Color(0xFF1F2937) : Colors.white),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(dayLabel, style: TextStyle(color: isToday ? (isDark ? const Color(0xFFD1D5DB) : const Color(0xFF374151)) : (isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280)), fontWeight: isToday ? FontWeight.bold : FontWeight.normal, fontSize: 12)),
      ],
    );
  }

  _MoodIconColors _getMoodIconColors(MoodIconType type) {
    switch (type) {
      case MoodIconType.happy:
        return _MoodIconColors(faceColor: const Color(0xFFFBBF24), eyeColor: const Color(0xFF4A3B32));
      case MoodIconType.neutralHappy:
        return _MoodIconColors(faceColor: const Color(0xFF84A95E), eyeColor: const Color(0xFF2D3748));
      case MoodIconType.neutral:
        return _MoodIconColors(faceColor: const Color(0xFF9B80F3), eyeColor: const Color(0xFF2D3748));
      case MoodIconType.neutralSad:
        return _MoodIconColors(faceColor: const Color(0xFFE88D3E), eyeColor: const Color(0xFF4A3B32));
      case MoodIconType.neutralFlat:
        return _MoodIconColors(faceColor: const Color(0xFFBCABA3), eyeColor: const Color(0xFF2D3748));
    }
  }
}

class _MoodIconColors {
  final Color faceColor;
  final Color eyeColor;

  const _MoodIconColors({required this.faceColor, required this.eyeColor});
}

class _MoodIconPainter extends CustomPainter {
  final Color faceColor;
  final Color eyeColor;
  final MoodIconType mouthType;

  _MoodIconPainter({required this.faceColor, required this.eyeColor, required this.mouthType});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final facePaint = Paint()..color = faceColor;
    canvas.drawCircle(center, radius, facePaint);

    final eyePaint = Paint()..color = eyeColor..style = PaintingStyle.fill;

    final leftEye = Offset(center.dx - radius * 0.3, center.dy - radius * 0.15);
    final rightEye = Offset(center.dx + radius * 0.3, center.dy - radius * 0.15);
    final eyeRadius = radius * 0.12;

    if (mouthType == MoodIconType.neutral) {
      _drawCrossEyes(canvas, leftEye, rightEye, eyeRadius, eyePaint);
    } else {
      canvas.drawCircle(leftEye, eyeRadius, eyePaint);
      canvas.drawCircle(rightEye, eyeRadius, eyePaint);
    }

    final mouthPaint = Paint()..color = eyeColor..style = PaintingStyle.stroke..strokeWidth = 2..strokeCap = StrokeCap.round;
    _drawMouth(canvas, center, radius, mouthPaint);
  }

  void _drawCrossEyes(Canvas canvas, Offset left, Offset right, double radius, Paint paint) {
    final strokePaint = Paint()..color = paint.color..style = PaintingStyle.stroke..strokeWidth = 1.5..strokeCap = StrokeCap.round;
    final offset = radius * 0.6;

    canvas.drawLine(Offset(left.dx - offset, left.dy - offset), Offset(left.dx + offset, left.dy + offset), strokePaint);
    canvas.drawLine(Offset(left.dx + offset, left.dy - offset), Offset(left.dx - offset, left.dy + offset), strokePaint);
    canvas.drawLine(Offset(right.dx - offset, right.dy - offset), Offset(right.dx + offset, right.dy + offset), strokePaint);
    canvas.drawLine(Offset(right.dx + offset, right.dy - offset), Offset(right.dx - offset, right.dy + offset), strokePaint);
  }

  void _drawMouth(Canvas canvas, Offset center, double radius, Paint paint) {
    final mouthY = center.dy + radius * 0.25;
    final mouthWidth = radius * 0.5;

    switch (mouthType) {
      case MoodIconType.happy:
        final path = Path();
        path.moveTo(center.dx - mouthWidth, mouthY - radius * 0.1);
        path.quadraticBezierTo(center.dx, mouthY + radius * 0.2, center.dx + mouthWidth, mouthY - radius * 0.1);
        canvas.drawPath(path, paint);
        break;
      case MoodIconType.neutralHappy:
        final path = Path();
        path.moveTo(center.dx - mouthWidth, mouthY);
        path.quadraticBezierTo(center.dx, mouthY + radius * 0.1, center.dx + mouthWidth, mouthY);
        canvas.drawPath(path, paint);
        break;
      case MoodIconType.neutral:
        final path = Path();
        path.moveTo(center.dx - mouthWidth * 0.8, mouthY + radius * 0.1);
        path.quadraticBezierTo(center.dx, mouthY - radius * 0.1, center.dx + mouthWidth * 0.8, mouthY + radius * 0.1);
        canvas.drawPath(path, paint);
        break;
      case MoodIconType.neutralSad:
        final path = Path();
        path.moveTo(center.dx - mouthWidth, mouthY + radius * 0.1);
        path.quadraticBezierTo(center.dx, mouthY - radius * 0.05, center.dx + mouthWidth, mouthY + radius * 0.1);
        canvas.drawPath(path, paint);
        break;
      case MoodIconType.neutralFlat:
        canvas.drawLine(Offset(center.dx - mouthWidth, mouthY), Offset(center.dx + mouthWidth, mouthY), paint);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _MoodIconPainter oldDelegate) {
    return oldDelegate.faceColor != faceColor || oldDelegate.eyeColor != eyeColor || oldDelegate.mouthType != mouthType;
  }
}
