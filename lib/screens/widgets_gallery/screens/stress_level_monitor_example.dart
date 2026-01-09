import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:flutter/material.dart';

/// 压力水平监测示例
class StressLevelMonitorExample extends StatelessWidget {
  const StressLevelMonitorExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('压力水平监测')),
      body: Container(
        color: isDark ? const Color(0xFF18181B) : const Color(0xFFF3F4F6),
        child: const Center(
          child: StressLevelMonitorWidget(
            currentScore: 4.2,
            status: 'Stressed Out',
            weeklyData: [
              WeeklyStressData(day: 'Mon', value: 0.45, isSelected: false),
              WeeklyStressData(day: 'Tue', value: 0.25, isSelected: false),
              WeeklyStressData(day: 'Wed', value: 0.60, isSelected: false),
              WeeklyStressData(day: 'Thu', value: 0.85, isSelected: true),
              WeeklyStressData(day: 'Fri', value: 0.35, isSelected: false),
              WeeklyStressData(day: 'Sat', value: 0.15, isSelected: false),
              WeeklyStressData(day: 'Sun', value: 0.40, isSelected: false),
            ],
          ),
        ),
      ),
    );
  }
}

/// 每周压力数据模型
class WeeklyStressData {
  /// 星期几
  final String day;

  /// 压力值 (0.0 - 1.0)
  final double value;

  /// 是否被选中
  final bool isSelected;

  const WeeklyStressData({
    required this.day,
    required this.value,
    required this.isSelected,
  });
}

/// 压力水平监测小组件
class StressLevelMonitorWidget extends StatefulWidget {
  /// 当前压力分数
  final double currentScore;

  /// 状态描述
  final String status;

  /// 一周数据
  final List<WeeklyStressData> weeklyData;

  const StressLevelMonitorWidget({
    super.key,
    required this.currentScore,
    required this.status,
    required this.weeklyData,
  });

  @override
  State<StressLevelMonitorWidget> createState() =>
      _StressLevelMonitorWidgetState();
}

class _StressLevelMonitorWidgetState extends State<StressLevelMonitorWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scoreAnimation;
  late List<Animation<double>> _barAnimations;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );

    _scoreAnimation = Tween<double>(begin: 0.0, end: widget.currentScore).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    // 为每个进度条创建动画
    _barAnimations = List.generate(
      widget.weeklyData.length,
      (index) => Tween<double>(begin: 0.0, end: widget.weeklyData[index].value)
          .animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Interval(
            0.2 + (index * 0.1),
            0.8 + (index * 0.03),
            curve: Curves.easeOut,
          ),
        ),
      ),
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

    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - _fadeAnimation.value)),
            child: _buildContent(isDark),
          ),
        );
      },
    );
  }

  Widget _buildContent(bool isDark) {
    final backgroundColor = isDark ? const Color(0xFF27272A) : Colors.white;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final surfaceColor = isDark
        ? primaryColor.withOpacity(0.15)
        : primaryColor.withOpacity(0.1);

    return Container(
      width: 380,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题栏
          _buildHeader(isDark, primaryColor, surfaceColor),
          const SizedBox(height: 32),

          // 分数和进度条在同一行
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // 当前分数和状态
              _buildScoreSection(isDark, primaryColor),
              // 每周进度条靠右
              _buildWeeklyBars(isDark, primaryColor),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark, Color primaryColor, Color surfaceColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: surfaceColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                color: primaryColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Stress Level',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.grey.shade900,
              ),
            ),
          ],
        ),
        InkWell(
          onTap: () {
            // 可以添加点击事件，导航到详细页面
          },
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                Text(
                  'Today',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScoreSection(bool isDark, Color primaryColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                AnimatedBuilder(
                  animation: _scoreAnimation,
                  builder: (context, child) {
                    return AnimatedFlipCounter(
                      value: _scoreAnimation.value,
                      fractionDigits: 1,
                      textStyle: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.grey.shade900,
                      ),
                    );
                  },
                ),
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    'pts',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white : Colors.grey.shade900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              widget.status,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w400,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWeeklyBars(bool isDark, Color primaryColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(widget.weeklyData.length, (index) {
        final data = widget.weeklyData[index];
        return _WeeklyBar(
          day: data.day.substring(0, 1), // 取首字母
          value: data.value,
          animation: _barAnimations[index],
          isSelected: data.isSelected,
          primaryColor: primaryColor,
          isDark: isDark,
        );
      }),
    );
  }
}

/// 每周进度条单项
class _WeeklyBar extends StatelessWidget {
  final String day;
  final double value;
  final Animation<double> animation;
  final bool isSelected;
  final Color primaryColor;
  final bool isDark;

  const _WeeklyBar({
    required this.day,
    required this.value,
    required this.animation,
    required this.isSelected,
    required this.primaryColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isDark
        ? const Color(0xFF374151)
        : const Color(0xFFE5E7EB);

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: InkWell(
            onTap: () {
              // 可以添加点击事件，显示该日的详细信息
            },
            borderRadius: BorderRadius.circular(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 14,
                  height: 64,
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      width: double.infinity,
                      height: 64 * animation.value,
                      decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  day,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected
                        ? (isDark ? Colors.white : Colors.grey.shade900)
                        : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
