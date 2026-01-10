import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:flutter/material.dart';

/// 周柱状图卡片示例
class WeeklyBarsCardExample extends StatelessWidget {
  const WeeklyBarsCardExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('周柱状图卡片')),
      body: Container(
        color: isDark ? Colors.black : const Color(0xFFF3F4F6),
        child: const Center(
          child: WeeklyBarsCardWidget(
            title: 'Hydration',
            icon: Icons.water_drop,
            currentValue: 1285,
            unit: 'ml',
            status: 'On Track',
            dailyValues: [0.60, 0.45, 0.30, 0.55, 0.80, 0.90, 0.40],
            primaryColor: Color(0xFF3B82F6),
          ),
        ),
      ),
    );
  }
}

/// 周数据点
class DayData {
  final String label;
  final double value;

  const DayData({required this.label, required this.value});
}

/// 周柱状图统计小组件
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
              width: 300,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(32),
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
                  const SizedBox(height: 32),

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
              width: 20,
              height: 20,
              alignment: Alignment.center,
              child: Icon(widget.icon, color: primaryColor, size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              widget.title,
              style: TextStyle(
                color: textColor,
                fontSize: 18,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        Row(
          children: [
            Text(
              'Today',
              style: TextStyle(
                color: subtextColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right, color: subtextColor, size: 12),
          ],
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
          height: 48,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 80,
                height: 48,
                child: AnimatedFlipCounter(
                  value: widget.currentValue * _animation.value,
                  fractionDigits: 0,
                  textStyle: TextStyle(
                    color: textColor,
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                    height: 1.0,
                    letterSpacing: -1,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              SizedBox(
                height: 20,
                child: Text(
                  widget.unit,
                  style: TextStyle(
                    color: subtextColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          widget.status,
          style: TextStyle(
            color: subtextColor,
            fontSize: 14,
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
      height: 96,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(7, (index) {
          final value = widget.dailyValues[index];
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
            padding: EdgeInsets.only(left: index == 0 ? 0 : 6),
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
          width: 12,
          height: 64,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(6),
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
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: labelColor,
            fontSize: 10,
            fontWeight: FontWeight.w500,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}
