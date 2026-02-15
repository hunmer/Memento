import 'package:flutter/material.dart';
import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/widgets_gallery/common_widgets/models/vertical_circular_progress_card_data.dart';

/// 上下布局圆环进度卡片公共小组件
///
/// 用于展示每日数值和周进度追踪的卡片组件，支持动画效果和主题适配。
/// 适用于健康追踪、进度管理等场景。
///
/// 支持序列化的数据模型，可从 JSON 字符串配置。
///
/// 使用示例：
/// ```dart
/// VerticalCircularProgressCard(
///   data: VerticalCircularProgressCardData(
///     mainValue: 7.5,
///     statusLabel: 'Good Sleep',
///     weeklyProgress: [
///       CircularProgressItemData(day: 'M', achieved: true, progress: 1.0),
///       // ... 其他6天
///     ],
///   ),
///   size: const LargeSize(),
/// )
/// ```
class VerticalCircularProgressCard extends StatefulWidget {
  /// 数据模型
  final VerticalCircularProgressCardData data;

  /// 小组件尺寸
  final HomeWidgetSize size;

  /// 卡片图标，默认为 Icons.bedtime_rounded
  final IconData? icon;

  /// 卡片宽度，默认根据尺寸自适应
  final double? width;

  /// 卡片高度，默认根据尺寸自适应
  final double? height;

  /// 卡片内边距，默认24
  final EdgeInsetsGeometry? padding;

  /// 圆角半径，默认28
  final double? borderRadius;

  /// 是否显示阴影，默认true（浅色模式）
  final bool? showShadow;

  /// 动画时长，默认1200ms
  final Duration? animationDuration;

  /// 点击右侧操作的回调
  final VoidCallback? onActionTap;

  /// 是否为内联模式（内联模式使用 double.maxFinite，非内联模式使用固定尺寸）
  final bool inline;

  const VerticalCircularProgressCard({
    super.key,
    required this.data,
    required this.size,
    this.icon,
    this.width,
    this.height,
    this.padding,
    this.borderRadius,
    this.showShadow,
    this.animationDuration,
    this.onActionTap,
    this.inline = false,
  });

  /// 从属性映射创建组件（用于动态渲染）
  static VerticalCircularProgressCard fromProps(
    Map<String, dynamic> props,
    HomeWidgetSize size,
  ) {
    // 尝试从 props 中解析 data
    VerticalCircularProgressCardData? data;

    if (props.containsKey('data')) {
      // 如果有 data 字段，从 data 中解析（向后兼容）
      final dataValue = props['data'];
      if (dataValue is String) {
        try {
          data = VerticalCircularProgressCardData.fromJsonString(dataValue);
        } catch (e) {
          debugPrint('Failed to parse VerticalCircularProgressCardData: $e');
        }
      } else if (dataValue is Map<String, dynamic>) {
        data = VerticalCircularProgressCardData.fromJson(dataValue);
      }
    } else {
      // 如果没有 data 字段，直接从 props 根级别解析（与其他组件保持一致）
      try {
        data = VerticalCircularProgressCardData.fromJson(props);
      } catch (e) {
        debugPrint(
          'Failed to parse VerticalCircularProgressCardData from props: $e',
        );
      }
    }

    // 如果解析失败，使用默认值
    data ??= VerticalCircularProgressCardData.createDefault();

    // 处理 icon：支持 int (codePoint) 或 IconData
    IconData? icon;
    final iconValue = props['icon'];
    if (iconValue is IconData) {
      icon = iconValue;
    } else if (iconValue is int) {
      icon = IconData(iconValue, fontFamily: 'MaterialIcons');
    }

    return VerticalCircularProgressCard(
      data: data,
      size: size,
      icon: icon,
      width: props['width'] as double?,
      height: props['height'] as double?,
      padding: props['padding'] as EdgeInsetsGeometry?,
      borderRadius: props['borderRadius'] as double?,
      showShadow: props['showShadow'] as bool?,
      animationDuration:
          props['animationDuration'] != null
              ? Duration(
                milliseconds: props['animationDuration'] as int? ?? 1200,
              )
              : null,
      onActionTap: props['onActionTap'] as VoidCallback?,
      inline: props['inline'] as bool? ?? false,
    );
  }

  /// 将组件配置转换为属性映射（用于保存配置）
  static Map<String, dynamic> toProps(
    VerticalCircularProgressCardData data, {
    HomeWidgetSize? size,
  }) {
    final props = {'data': data.toJsonString()};
    if (size != null) {
      // 将 size 转换为 JSON 字符串存储
      props['size'] = size.toJson().toString();
    }
    return props;
  }

  @override
  State<VerticalCircularProgressCard> createState() =>
      _VerticalCircularProgressCardState();
}

class _VerticalCircularProgressCardState
    extends State<VerticalCircularProgressCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: widget.animationDuration ?? const Duration(milliseconds: 1200),
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
    final primaryColor = _getPrimaryColor(isDark);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - _animation.value)),
            child: Container(
              height: widget.inline ? double.maxFinite : (widget.height ?? 200),
              width: widget.inline ? double.maxFinite : (widget.width ?? 450),
              padding: widget.padding ?? widget.size.getPadding(),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow:
                    (widget.showShadow ?? (!isDark))
                        ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ]
                        : null,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 标题栏
                  _buildHeader(context, isDark, primaryColor),
                  SizedBox(height: widget.size.getTitleSpacing()),
                  // 主内容区
                  _buildContent(context, isDark, primaryColor),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getPrimaryColor(bool isDark) {
    if (widget.data.primaryColor != null) {
      try {
        return Color(int.parse(widget.data.primaryColor!, radix: 16));
      } catch (e) {
        debugPrint('Failed to parse primaryColor: ${widget.data.primaryColor}');
      }
    }
    return isDark
        ? const Color(0xFFF36E24)
        : Theme.of(context).colorScheme.primary;
  }

  Widget _buildHeader(BuildContext context, bool isDark, Color primaryColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              Container(
                padding: widget.size.getPadding(),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  widget.icon ?? Icons.bedtime_rounded,
                  color: primaryColor,
                  size: widget.size.getIconSize(),
                ),
              ),
              SizedBox(width: widget.size.getItemSpacing()),
              Flexible(
                child: Text(
                  widget.data.title,
                  style: TextStyle(
                    fontSize: widget.size.getTitleFontSize(),
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF111827),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        InkWell(
          onTap: widget.onActionTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: widget.size.getPadding(),
            child: Row(
              children: [
                Text(
                  widget.data.actionLabel,
                  style: TextStyle(
                    fontSize: widget.size.getSubtitleFontSize(),
                    fontWeight: FontWeight.w500,
                    color:
                        isDark
                            ? const Color(0xFF9CA3AF)
                            : const Color(0xFF6B7280),
                  ),
                ),
                SizedBox(width: widget.size.getSmallSpacing()),
                Icon(
                  Icons.chevron_right_rounded,
                  size: widget.size.getIconSize(),
                  color:
                      isDark
                          ? const Color(0xFF9CA3AF)
                          : const Color(0xFF6B7280),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContent(BuildContext context, bool isDark, Color primaryColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // 左侧：睡眠时长
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 48,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    height: widget.size.getLargeFontSize(),
                    child: AnimatedFlipCounter(
                      value: widget.data.mainValue * _animation.value,
                      fractionDigits: 0,
                      textStyle: TextStyle(
                        fontSize: widget.size.getLargeFontSize(),
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF111827),
                        height: 1.0,
                      ),
                    ),
                  ),
                  SizedBox(width: widget.size.getSmallSpacing()),
                  SizedBox(
                    height: widget.size.getLargeFontSize(),
                    child: Text(
                      widget.data.unit,
                      style: TextStyle(
                        fontSize: widget.size.getSubtitleFontSize(),
                        fontWeight: FontWeight.w500,
                        color:
                            isDark
                                ? const Color(0xFF9CA3AF)
                                : const Color(0xFF6B7280),
                        height: 1.0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: widget.size.getSmallSpacing()),
            Text(
              widget.data.statusLabel,
              style: TextStyle(
                fontSize: widget.size.getSubtitleFontSize(),
                fontWeight: FontWeight.w500,
                color:
                    isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
        // 右侧：周日程进度
        Flexible(child: _buildWeeklyProgress(isDark, primaryColor)),
      ],
    );
  }

  /// 构建周日程进度，支持横向滚动
  Widget _buildWeeklyProgress(bool isDark, Color primaryColor) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;

        // 预计算所需宽度：n 个指示器宽度 + (n-1) 个间距
        final indicatorWidth = widget.size.getLegendIndicatorWidth();
        final itemCount = widget.data.weeklyProgress.length;
        final spacing = widget.size.getItemSpacing();
        final estimatedWidth =
            (indicatorWidth * itemCount) + (spacing * (itemCount - 1));

        // 构建内容 Row
        final contentRow = Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children:
              widget.data.weeklyProgress.asMap().entries.map((entry) {
                final index = entry.key;
                final data = entry.value;

                // 计算动画延迟
                final itemAnimation = CurvedAnimation(
                  parent: _animationController,
                  curve: Interval(
                    index * 0.08,
                    0.5 + index * 0.08,
                    curve: Curves.easeOutCubic,
                  ),
                );

                return Padding(
                  padding: EdgeInsets.only(left: index == 0 ? 0 : spacing),
                  child: _DaySleepIndicator(
                    dayData: data,
                    primaryColor: primaryColor,
                    isDark: isDark,
                    animation: itemAnimation,
                    size: widget.size,
                  ),
                );
              }).toList(),
        );

        // 如果估计宽度不超过最大宽度，居中显示
        if (estimatedWidth <= maxWidth) {
          return Center(child: contentRow);
        }

        // 需要滚动，使用 SingleChildScrollView
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: contentRow,
        );
      },
    );
  }
}

/// 日睡眠进度指示器
class _DaySleepIndicator extends StatelessWidget {
  final CircularProgressItemData dayData;
  final Color primaryColor;
  final bool isDark;
  final Animation<double> animation;
  final HomeWidgetSize size;

  const _DaySleepIndicator({
    required this.dayData,
    required this.primaryColor,
    required this.isDark,
    required this.animation,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final animatedProgress = dayData.progress * animation.value;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              dayData.achieved ? Icons.check_rounded : Icons.close_rounded,
              size: size.getIconSize(),
              color:
                  dayData.achieved
                      ? (isDark ? Colors.white : const Color(0xFF111827))
                      : (isDark
                          ? const Color(0xFF4B5563)
                          : const Color(0xFFD1D5DB)),
            ),
            SizedBox(height: size.getSmallSpacing()),
            SizedBox(
              width: size.getLegendIndicatorWidth(),
              height: size.getLegendIndicatorHeight(),
              child: CustomPaint(
                painter: _CircleProgressPainter(
                  progress: animatedProgress,
                  primaryColor: primaryColor,
                  backgroundColor:
                      isDark
                          ? const Color(0xFF4B5563)
                          : const Color(0xFFE5E7EB),
                  strokeWidth: size.getStrokeWidth() * size.progressStrokeScale,
                ),
              ),
            ),
            SizedBox(height: size.getSmallSpacing()),
            Text(
              dayData.day,
              style: TextStyle(
                fontSize: size.getLegendFontSize(),
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
                color:
                    isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// 圆形进度绘制器
class _CircleProgressPainter extends CustomPainter {
  final double progress;
  final Color primaryColor;
  final Color backgroundColor;
  final double strokeWidth;

  _CircleProgressPainter({
    required this.progress,
    required this.primaryColor,
    required this.backgroundColor,
    this.strokeWidth = 2.5,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - strokeWidth / 2;

    // 绘制背景圆环
    final backgroundPaint =
        Paint()
          ..color = backgroundColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    // 绘制进度圆弧
    if (progress > 0) {
      final progressPaint =
          Paint()
            ..color = primaryColor
            ..style = PaintingStyle.stroke
            ..strokeWidth = strokeWidth
            ..strokeCap = StrokeCap.round;

      const startAngle = -3.141592653589793238 / 2; // 从顶部开始
      final sweepAngle = 2 * 3.141592653589793238 * progress;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CircleProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
