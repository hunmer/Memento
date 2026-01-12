import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';

/// 周柱状图卡片小组件
///
/// 显示一周7天的数据柱状图，支持渐变效果和动画
class WeeklyBarsCardWidget extends StatefulWidget {
  /// 卡片标题
  final String title;

  /// 标题图标
  final IconData icon;

  /// 当前数值
  final double currentValue;

  /// 数值单位
  final String unit;

  /// 状态文本
  final String status;

  /// 7天的数值（0.0 - 1.0）
  final List<double> dailyValues;

  /// 主色调
  final Color? primaryColor;

  const WeeklyBarsCardWidget({
    super.key,
    required this.title,
    required this.icon,
    required this.currentValue,
    required this.unit,
    required this.status,
    required this.dailyValues,
    this.primaryColor,
  });

  /// 从 props 创建实例
  factory WeeklyBarsCardWidget.fromProps(
    Map<String, dynamic> props,
    HomeWidgetSize size,
  ) {
    final dailyValuesList = props['dailyValues'] as List?;
    final dailyValues = dailyValuesList?.map((item) {
      return (item as num).toDouble();
    }).toList() ?? <double>[];

    return WeeklyBarsCardWidget(
      title: props['title'] as String? ?? '',
      icon: _parseIcon(props['icon']),
      currentValue: (props['currentValue'] as num?)?.toDouble() ?? 0.0,
      unit: props['unit'] as String? ?? '',
      status: props['status'] as String? ?? '',
      dailyValues: dailyValues,
      primaryColor: props['primaryColor'] != null
          ? Color(props['primaryColor'] as int)
          : null,
    );
  }

  /// 解析图标
  static IconData _parseIcon(dynamic iconData) {
    if (iconData is int) {
      return IconData(iconData, fontFamily: 'MaterialIcons');
    }
    if (iconData is String) {
      // 根据字符串返回常见图标
      switch (iconData) {
        case 'water_drop':
          return Icons.water_drop;
        case 'fitness':
          return Icons.fitness_center;
        case 'local_fire_department':
          return Icons.local_fire_department;
        case 'directions_run':
          return Icons.directions_run;
        default:
          return Icons.circle;
      }
    }
    return Icons.circle;
  }

  @override
  State<WeeklyBarsCardWidget> createState() => _WeeklyBarsCardWidgetState();
}

class _WeeklyBarsCardWidgetState extends State<WeeklyBarsCardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
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
    final backgroundColor = isDark ? const Color(0xFF18181B) : Colors.white;
    final primaryColor =
        widget.primaryColor ?? Theme.of(context).colorScheme.primary;
    final textColor = isDark ? Colors.white : Colors.grey.shade900;
    final subtextColor = isDark ? Colors.grey.shade400 : Colors.grey.shade500;
    final barBgColor =
        isDark ? const Color(0xFF27272A) : const Color(0xFFEFF6FF);

    final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - _animation.value)),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color:
                      isDark
                          ? const Color(0xFF27272A)
                          : Colors.white.withOpacity(0.5),
                  width: 1,
                ),
                boxShadow:
                    isDark
                        ? null
                        : [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 20,
                              offset: const Offset(0, 4),
                            ),
                          ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 标题栏
                  _buildHeader(context, primaryColor, textColor, subtextColor),
                  const SizedBox(height: 16),

                  // 数值显示 + 周柱状图
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // 左侧：当前数值
                      Expanded(
                        child: _buildValueSection(
                          context,
                          textColor,
                          subtextColor,
                        ),
                      ),

                      // 右侧：周柱状图
                      _buildWeeklyBars(
                        context,
                        days,
                        primaryColor,
                        barBgColor,
                        subtextColor,
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

  /// 标题栏
  Widget _buildHeader(
    BuildContext context,
    Color primaryColor,
    Color textColor,
    Color subtextColor,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 18,
              height: 18,
              alignment: Alignment.center,
              child: Icon(widget.icon, color: primaryColor, size: 18),
            ),
            const SizedBox(width: 8),
            Text(
              widget.title,
              style: TextStyle(
                color: textColor,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        Text(
          'Today',
          style: TextStyle(
            color: subtextColor,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  /// 数值显示区域
  Widget _buildValueSection(
    BuildContext context,
    Color textColor,
    Color subtextColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 36,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 70,
                height: 36,
                child: AnimatedFlipCounter(
                  value: widget.currentValue * _animation.value,
                  fractionDigits: 0,
                  textStyle: TextStyle(
                    color: textColor,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    height: 1.0,
                    letterSpacing: -1,
                  ),
                ),
              ),
              const SizedBox(width: 2),
              SizedBox(
                height: 16,
                child: Text(
                  widget.unit,
                  style: TextStyle(
                    color: subtextColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          widget.status,
          style: TextStyle(
            color: subtextColor,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  /// 周柱状图
  Widget _buildWeeklyBars(
    BuildContext context,
    List<String> days,
    Color primaryColor,
    Color barBgColor,
    Color labelColor,
  ) {
    return SizedBox(
      height: 80,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(7, (index) {
          final value = index < widget.dailyValues.length
              ? widget.dailyValues[index]
              : 0.0;
          final step = 0.05;
          final itemAnimation = CurvedAnimation(
            parent: _animationController,
            curve: Interval(
              index * step,
              0.6 + index * step,
              curve: Curves.easeOutCubic,
            ),
          );

          return Padding(
            padding: EdgeInsets.only(left: index == 0 ? 0 : 4),
            child: _DayBar(
              label: days[index],
              value: value,
              animation: itemAnimation,
              primaryColor: primaryColor,
              backgroundColor: barBgColor,
              labelColor: labelColor,
            ),
          );
        }),
      ),
    );
  }
}

/// 单日柱状图
class _DayBar extends StatelessWidget {
  final String label;
  final double value;
  final Animation<double> animation;
  final Color primaryColor;
  final Color backgroundColor;
  final Color labelColor;

  const _DayBar({
    required this.label,
    required this.value,
    required this.animation,
    required this.primaryColor,
    required this.backgroundColor,
    required this.labelColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 54,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(5),
          ),
          alignment: Alignment.bottomCenter,
          clipBehavior: Clip.antiAlias,
          child: AnimatedBuilder(
            animation: animation,
            builder: (context, child) {
              return FractionallySizedBox(
                heightFactor: value * animation.value,
                alignment: Alignment.bottomCenter,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        primaryColor.withOpacity(0.95),
                        primaryColor.withOpacity(0.7),
                        primaryColor.withOpacity(0.4),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            color: labelColor,
            fontSize: 9,
            fontWeight: FontWeight.w500,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}
