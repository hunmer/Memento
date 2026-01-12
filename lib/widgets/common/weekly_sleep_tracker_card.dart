import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';

/// 每日睡眠数据模型
class DaySleepData {
  /// 是否完成目标
  final bool isCompleted;

  /// 完成进度 (0.0 - 1.0)
  final double progress;

  /// 星期标签 (如 'M', 'T', 'W' 等)
  final String day;

  const DaySleepData({
    required this.isCompleted,
    required this.progress,
    required this.day,
  });

  /// 从 JSON 创建
  factory DaySleepData.fromJson(Map<String, dynamic> json) {
    return DaySleepData(
      isCompleted: json['isCompleted'] as bool? ?? false,
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      day: json['day'] as String? ?? '',
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'isCompleted': isCompleted,
      'progress': progress,
      'day': day,
    };
  }

  /// 复制并修改部分属性
  DaySleepData copyWith({
    bool? isCompleted,
    double? progress,
    String? day,
  }) {
    return DaySleepData(
      isCompleted: isCompleted ?? this.isCompleted,
      progress: progress ?? this.progress,
      day: day ?? this.day,
    );
  }
}

/// 睡眠追踪卡片小组件
///
/// 显示总睡眠时长、状态标签和每周7天的进度环。
/// 适用于主屏幕小组件和睡眠统计界面。
///
/// 功能特性：
/// - 动画显示睡眠时长（使用 AnimatedFlipCounter）
/// - 每日睡眠进度环显示
/// - 完成状态标记（勾选/关闭图标）
/// - 支持深色/浅色主题自动适配
/// - 入场动画效果
///
/// 使用示例：
/// ```dart
/// WeeklySleepTrackerCard(
///   totalHours: 7.5,
///   statusLabel: 'Good',
///   weeklyData: [
///     DaySleepData(isCompleted: true, progress: 1.0, day: 'M'),
///     DaySleepData(isCompleted: false, progress: 0.8, day: 'T'),
///     // ... 其他天数
///   ],
///   primaryColor: Colors.blue,
/// )
/// ```
class WeeklySleepTrackerCard extends StatefulWidget {
  /// 总睡眠时长（小时）
  final double totalHours;

  /// 状态标签（如 "Insomniac", "Good" 等）
  final String statusLabel;

  /// 每周数据（7天）
  final List<DaySleepData> weeklyData;

  /// 主色调，默认为橙色
  final Color? primaryColor;

  const WeeklySleepTrackerCard({
    super.key,
    required this.totalHours,
    required this.statusLabel,
    required this.weeklyData,
    this.primaryColor,
  });

  /// 从 props 创建实例（用于 HomeWidget）
  factory WeeklySleepTrackerCard.fromProps(
    Map<String, dynamic> props,
    HomeWidgetSize size,
  ) {
    final weeklyDataList = props['weeklyData'] as List?;
    final weeklyData = weeklyDataList?.map((item) {
      return DaySleepData.fromJson(item as Map<String, dynamic>);
    }).toList() ?? <DaySleepData>[];

    return WeeklySleepTrackerCard(
      totalHours: (props['totalHours'] as num?)?.toDouble() ?? 0.0,
      statusLabel: props['statusLabel'] as String? ?? '',
      weeklyData: weeklyData,
      primaryColor: props['primaryColor'] != null
          ? Color(props['primaryColor'] as int)
          : null,
    );
  }

  @override
  State<WeeklySleepTrackerCard> createState() =>
      _WeeklySleepTrackerCardState();
}

class _WeeklySleepTrackerCardState extends State<WeeklySleepTrackerCard>
    with SingleTickerProviderStateMixin {
  /// 动画控制器
  late AnimationController _animationController;

  /// 入场动画
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _animation = CurvedAnimation(
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
    final backgroundColor = isDark ? const Color(0xFF2C2C2E) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF111827);
    final secondaryTextColor =
        isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
    final primaryColor =
        widget.primaryColor ?? const Color(0xFFF36E24);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - _animation.value)),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(28),
                boxShadow:
                    isDark
                        ? null
                        : [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 标题栏
                  _buildHeader(
                    context,
                    primaryColor,
                    textColor,
                    secondaryTextColor,
                  ),
                  const SizedBox(height: 24),

                  // 睡眠时长和状态
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // 左侧：睡眠时长和状态
                      _buildSleepInfo(context, textColor, secondaryTextColor),

                      // 右侧：7天进度环
                      _buildWeeklyProgressRings(
                        context,
                        primaryColor,
                        isDark,
                        secondaryTextColor,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// 构建标题栏
  ///
  /// 包含睡眠图标、标题和"Today"导航按钮
  Widget _buildHeader(
    BuildContext context,
    Color primaryColor,
    Color textColor,
    Color secondaryTextColor,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.bedtime_rounded,
                color: primaryColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Sleep',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ],
        ),
        GestureDetector(
          onTap: () {
            // TODO: 导航到详情页
          },
          child: Row(
            children: [
              Text(
                'Today',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: secondaryTextColor,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right_rounded,
                color: secondaryTextColor,
                size: 20,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 构建睡眠时长和状态信息
  ///
  /// 显示总睡眠小时数和状态标签
  Widget _buildSleepInfo(
    BuildContext context,
    Color textColor,
    Color secondaryTextColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 54,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 100,
                height: 48,
                child: AnimatedFlipCounter(
                  value: widget.totalHours * _animation.value,
                  fractionDigits:
                      widget.totalHours % 1 != 0 ? 2 : 0,
                  textStyle: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                    height: 1.0,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              SizedBox(
                height: 20,
                child: Text(
                  'hr',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: secondaryTextColor,
                    height: 1.0,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          widget.statusLabel,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: secondaryTextColor,
          ),
        ),
      ],
    );
  }

  /// 构建每周进度环
  ///
  /// 显示7天的睡眠进度环，每个环带有动画效果
  Widget _buildWeeklyProgressRings(
    BuildContext context,
    Color primaryColor,
    bool isDark,
    Color secondaryTextColor,
  ) {
    return Row(
      children: List.generate(widget.weeklyData.length, (index) {
        final dayData = widget.weeklyData[index];
        // 为每一天创建独立的动画
        final itemAnimation = CurvedAnimation(
          parent: _animationController,
          curve: Interval(
            index * 0.12,
            0.6 + index * 0.12,
            curve: Curves.easeOutCubic,
          ),
        );
        return Padding(
          padding: EdgeInsets.only(left: index == 0 ? 0 : 8),
          child: _DayProgressRing(
            data: dayData,
            primaryColor: primaryColor,
            isDark: isDark,
            animation: itemAnimation,
          ),
        );
      }),
    );
  }
}

/// 单日进度环组件
///
/// 显示完成状态图标、进度环和星期标签
class _DayProgressRing extends StatelessWidget {
  /// 当天的睡眠数据
  final DaySleepData data;

  /// 主色调
  final Color primaryColor;

  /// 是否为深色主题
  final bool isDark;

  /// 进度动画
  final Animation<double> animation;

  const _DayProgressRing({
    required this.data,
    required this.primaryColor,
    required this.isDark,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    // 根据完成状态决定图标颜色
    final iconColor =
        data.isCompleted
            ? (isDark ? Colors.white : const Color(0xFF111827))
            : (isDark ? const Color(0xFF6B7280) : const Color(0xFFD1D5DB));

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 完成状态图标
        Icon(
          data.isCompleted ? Icons.check_rounded : Icons.close_rounded,
          size: 14,
          color: iconColor,
        ),
        const SizedBox(height: 4),

        // 进度环
        SizedBox(
          width: 24,
          height: 24,
          child: AnimatedBuilder(
            animation: animation,
            builder: (context, child) {
              return CustomPaint(
                painter: _CircleProgressPainter(
                  progress: data.progress * animation.value,
                  primaryColor: primaryColor,
                  backgroundColor:
                      isDark
                          ? const Color(0xFF4B5563)
                          : const Color(0xFFE5E7EB),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 2),

        // 星期标签
        Text(
          data.day,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

/// 圆形进度条绘制器
///
/// 使用 CustomPainter 绘制背景圆环和进度圆弧
class _CircleProgressPainter extends CustomPainter {
  /// 进度值 (0.0 - 1.0)
  final double progress;

  /// 进度条颜色
  final Color primaryColor;

  /// 背景圆环颜色
  final Color backgroundColor;

  _CircleProgressPainter({
    required this.progress,
    required this.primaryColor,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 5) / 2; // 减去strokeWidth

    // 绘制背景圆环
    final backgroundPaint =
        Paint()
          ..color = backgroundColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    // 绘制进度圆弧
    final progressPaint =
        Paint()
          ..color = primaryColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * 3.14159 * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -3.14159 / 2, // 从顶部开始（12点钟方向）
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CircleProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}
