import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:flutter/material.dart';

/// 每周步数进度卡片示例
class WeeklyStepsProgressCardExample extends StatelessWidget {
  const WeeklyStepsProgressCardExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('每周步数进度卡片')),
      body: Container(
        color: isDark ? const Color(0xFF1F2937) : const Color(0xFFE5E5E5),
        child: const Center(
          child: WeeklyStepsProgressCardWidget(
            totalSteps: 16254,
            dateRange: '17-23 Jun 2024',
            averageSteps: 6028,
            dailyData: [
              DailyStepData(
                day: 'Mon',
                steps: 4500,
                date: '17 Jun 2024',
              ),
              DailyStepData(
                day: 'Tue',
                steps: 6200,
                date: '18 Jun 2024',
              ),
              DailyStepData(
                day: 'Wed',
                steps: 3800,
                date: '19 Jun 2024',
              ),
              DailyStepData(
                day: 'Thu',
                steps: 7800,
                date: '20 Jun 2024',
              ),
              DailyStepData(
                day: 'Fri',
                steps: 12800,
                date: '21 Jun 2024',
                percentage: '+2,4%',
                isSelected: true,
              ),
              DailyStepData(
                day: 'Sat',
                steps: 9600,
                date: '22 Jun 2024',
              ),
              DailyStepData(
                day: 'Sun',
                steps: 7200,
                date: '23 Jun 2024',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 每日步数数据
class DailyStepData {
  final String day;
  final int steps;
  final String date;
  final String? percentage;
  final bool isSelected;

  const DailyStepData({
    required this.day,
    required this.steps,
    required this.date,
    this.percentage,
    this.isSelected = false,
  });
}

/// 每周步数进度卡片组件
class WeeklyStepsProgressCardWidget extends StatefulWidget {
  final int totalSteps;
  final String dateRange;
  final int averageSteps;
  final List<DailyStepData> dailyData;

  const WeeklyStepsProgressCardWidget({
    super.key,
    required this.totalSteps,
    required this.dateRange,
    required this.averageSteps,
    required this.dailyData,
  });

  @override
  State<WeeklyStepsProgressCardWidget> createState() =>
      _WeeklyStepsProgressCardWidgetState();
}

class _WeeklyStepsProgressCardWidgetState
    extends State<WeeklyStepsProgressCardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _counterAnimation;

  int? _selectedIndex;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );

    _counterAnimation = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
    );

    // 默认选中最高的步数日期
    if (widget.dailyData.any((d) => d.isSelected)) {
      _selectedIndex = widget.dailyData.indexWhere((d) => d.isSelected);
    } else {
      final maxSteps =
          widget.dailyData.map((d) => d.steps).reduce((a, b) => a > b ? a : b);
      _selectedIndex = widget.dailyData.indexWhere((d) => d.steps == maxSteps);
    }

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _selectDay(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - _fadeAnimation.value)),
            child: Container(
              width: 380,
              height: 600,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF111827) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 标题栏
                    _buildHeader(context, isDark, primaryColor),
                    const SizedBox(height: 24),
                    // 总步数和时间切换
                    _buildTotalSection(context, isDark, primaryColor),
                    const SizedBox(height: 24),
                    // 柱状图
                    _buildChartSection(context, isDark, primaryColor),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// 构建标题栏
  Widget _buildHeader(BuildContext context, bool isDark, Color primaryColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: primaryColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.directions_walk,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Steps',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFFF3F4F6) : const Color(0xFF111827),
              ),
            ),
          ],
        ),
        IconButton(
          icon: Icon(
            Icons.more_horiz,
            color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
          ),
          onPressed: () {},
        ),
      ],
    );
  }

  /// 构建总数和时间切换区域
  Widget _buildTotalSection(
    BuildContext context,
    bool isDark,
    Color primaryColor,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  SizedBox(
                    width: 160,
                    child: AnimatedFlipCounter(
                      value: widget.totalSteps.toDouble() * _counterAnimation.value,
                      fractionDigits: 0,
                      textStyle: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? const Color(0xFFF3F4F6)
                            : const Color(0xFF111827),
                        letterSpacing: -0.5,
                        height: 1.0,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'steps',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? const Color(0xFF9CA3AF)
                          : const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                widget.dateRange,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? const Color(0xFF9CA3AF)
                      : const Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
        // 时间切换按钮
        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1F2937) : const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(4),
          child: Row(
            children: [
              _buildTimeButton('Week', true, isDark),
              _buildTimeButton('Month', false, isDark),
              _buildTimeButton('Year', false, isDark),
            ],
          ),
        ),
      ],
    );
  }

  /// 构建时间切换按钮
  Widget _buildTimeButton(String label, bool isSelected, bool isDark) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 2),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? isDark
                    ? const Color(0xFF374151)
                    : Colors.white
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected
                  ? isDark
                      ? Colors.white
                      : const Color(0xFF111827)
                  : isDark
                      ? const Color(0xFF6B7280)
                      : const Color(0xFF9CA3AF),
            ),
          ),
        ),
      ),
    );
  }

  /// 构建柱状图区域
  Widget _buildChartSection(
    BuildContext context,
    bool isDark,
    Color primaryColor,
  ) {
    return SizedBox(
      height: 260,
      child: Stack(
        children: [
          // 平均值参考线
          Positioned(
            top: 0.65 * 260,
            left: 0,
            right: 0,
            child: _buildAverageLine(context, isDark, primaryColor),
          ),
          // 悬浮提示框
          if (_selectedIndex != null)
            Positioned(
              top: 0.25 * 260,
              left: 0.38,
              right: 0,
              child: _buildTooltip(context, isDark, primaryColor),
            ),
          // 柱状图
          Positioned.fill(
            top: 64,
            bottom: 24,
            child: _StepsBars(
              dailyData: widget.dailyData,
              animation: _fadeAnimation,
              selectedIndex: _selectedIndex ?? 0,
              maxSteps: widget.dailyData.map((d) => d.steps).reduce((a, b) => a > b ? a : b),
              averageSteps: widget.averageSteps,
              onTap: _selectDay,
              isDark: isDark,
              primaryColor: primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建平均值参考线
  Widget _buildAverageLine(BuildContext context, bool isDark, Color primaryColor) {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Average',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                AnimatedFlipCounter(
                  value: widget.averageSteps.toDouble() * _counterAnimation.value,
                  fractionDigits: 0,
                  textStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? const Color(0xFFF3F4F6)
                        : const Color(0xFF111827),
                  ),
                ),
                const SizedBox(width: 2),
                Text(
                  'steps',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w400,
                    color: isDark
                        ? const Color(0xFF9CA3AF)
                        : const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 2,
            decoration: BoxDecoration(
              border: Border.all(
                color: primaryColor.withOpacity(0.4),
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 构建悬浮提示框
  Widget _buildTooltip(BuildContext context, bool isDark, Color primaryColor) {
    if (_selectedIndex == null) return const SizedBox.shrink();

    final data = widget.dailyData[_selectedIndex!];

    return Align(
      alignment: const Alignment(-0.24, 0),
      child: AnimatedOpacity(
        opacity: _fadeAnimation.value,
        duration: const Duration(milliseconds: 200),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF374151) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? const Color(0xFF4B5563) : const Color(0xFFF3F4F6),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 6,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: primaryColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    data.date,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? const Color(0xFFD1D5DB)
                          : const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AnimatedFlipCounter(
                    value: data.steps.toDouble() * _counterAnimation.value,
                    fractionDigits: 0,
                    textStyle: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color:
                          isDark ? Colors.white : const Color(0xFF111827),
                    ),
                  ),
                  if (data.percentage != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        data.percentage!,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF10B981),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 柱状图组件
class _StepsBars extends StatelessWidget {
  final List<DailyStepData> dailyData;
  final Animation<double> animation;
  final int selectedIndex;
  final int maxSteps;
  final int averageSteps;
  final Function(int) onTap;
  final bool isDark;
  final Color primaryColor;

  const _StepsBars({
    required this.dailyData,
    required this.animation,
    required this.selectedIndex,
    required this.maxSteps,
    required this.averageSteps,
    required this.onTap,
    required this.isDark,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    final maxHeight = 180.0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(dailyData.length, (index) {
        final data = dailyData[index];
        final barHeight = (data.steps / maxSteps) * maxHeight;
        final isSelected = index == selectedIndex;

        // 错开动画
        final step = 0.08;
        final barAnimation = CurvedAnimation(
          parent: animation,
          curve: Interval(
            index * step,
            0.5 + index * step,
            curve: Curves.easeOutCubic,
          ),
        );

        return Expanded(
          child: GestureDetector(
            onTap: () => onTap(index),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                AnimatedBuilder(
                  animation: barAnimation,
                  builder: (context, child) {
                    return Container(
                      height: barHeight * barAnimation.value,
                      width: 40,
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? null
                            : LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: isDark
                                    ? [
                                        const Color(0xFFFFD89E),
                                        const Color(0xFFA66C1E),
                                      ]
                                    : [
                                        const Color(0xFFFFD89E),
                                        const Color(0xFFFFF0D9),
                                      ],
                              ),
                        color: isSelected ? primaryColor : null,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: primaryColor.withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : null,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                Text(
                  data.day,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected
                        ? isDark
                            ? const Color(0xFFF3F4F6)
                            : const Color(0xFF111827)
                        : isDark
                            ? const Color(0xFF9CA3AF)
                            : const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}
