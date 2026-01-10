import 'package:flutter/material.dart';

/// 睡眠阶段图表示例
class SleepStageChartExample extends StatelessWidget {
  const SleepStageChartExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('睡眠阶段图表')),
      body: Container(
        color: isDark ? const Color(0xFFEBB305) : const Color(0xFFFDFDFD),
        child: const Center(
          child: SleepStageChartWidget(
            sleepStages: [
              SleepStageData(
                type: SleepStageType.core,
                left: 0,
                topPercent: 20,
                widthPercent: 55,
                height: 48,
              ),
              SleepStageData(
                type: SleepStageType.postREM,
                left: 30,
                topPercent: 65,
                widthPercent: 10,
                height: 40,
              ),
              SleepStageData(
                type: SleepStageType.rem,
                left: 45,
                topPercent: 45,
                widthPercent: 38,
                height: 48,
              ),
              SleepStageData(
                type: SleepStageType.deep,
                left: 80,
                topPercent: 70,
                widthPercent: 15,
                height: 48,
              ),
            ],
            selectedTab: 1,
          ),
        ),
      ),
    );
  }
}

/// 睡眠阶段类型
enum SleepStageType { core, rem, postREM, deep }

/// 睡眠阶段数据模型
class SleepStageData {
  final SleepStageType type;
  final double left; // 0-100
  final double topPercent; // 0-100
  final double widthPercent; // 0-100
  final double height;

  const SleepStageData({
    required this.type,
    required this.left,
    required this.topPercent,
    required this.widthPercent,
    required this.height,
  });
}

/// 睡眠阶段图表小组件
class SleepStageChartWidget extends StatefulWidget {
  final List<SleepStageData> sleepStages;
  final int selectedTab;
  final bool showTooltip;

  const SleepStageChartWidget({
    super.key,
    required this.sleepStages,
    this.selectedTab = 1,
    this.showTooltip = true,
  });

  @override
  State<SleepStageChartWidget> createState() => _SleepStageChartWidgetState();
}

class _SleepStageChartWidgetState extends State<SleepStageChartWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  int _selectedTab = 1;

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.selectedTab;
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

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - _animation.value)),
            child: Container(
              width: 360,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(48),
                border: Border.all(
                  color: isDark ? const Color(0xFF404040) : Colors.white,
                  width: 4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 40,
                    offset: const Offset(0, -10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 时间范围选择器
                  _buildTabSelector(context),
                  const SizedBox(height: 32),
                  // 睡眠阶段图表
                  _buildChart(context),
                  const SizedBox(height: 32),
                  // 图例
                  _buildLegend(context),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTabSelector(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tabs = ['1 Day', '1 Week', '1 Month', '1 Year', 'All Time'];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color:
            isDark
                ? const Color(0xFF3A3A3C).withOpacity(0.5)
                : const Color(0xFFF8F5F2),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final isSelected = _selectedTab == index;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = index),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color:
                      isSelected
                          ? (isDark ? const Color(0xFF3A3A3C) : Colors.white)
                          : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow:
                      isSelected
                          ? [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                            ),
                          ]
                          : null,
                ),
                child: Text(
                  tabs[index],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color:
                        isSelected
                            ? (isDark
                                ? const Color(0xFF5D4037)
                                : const Color(0xFF5D4037))
                            : (isDark
                                ? Colors.grey.shade600
                                : const Color(0xFF5D4037).withOpacity(0.6)),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildChart(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chartWidth = 296.0;
    final chartHeight = 256.0;

    return SizedBox(
      height: chartHeight,
      width: chartWidth,
      child: Stack(
        children: [
          // 网格线
          ...List.generate(5, (index) {
            final x = (chartWidth / 4) * index;
            return Positioned(
              left: x,
              top: 0,
              bottom: 24,
              child: Container(
                width: 1,
                color:
                    isDark ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
              ),
            );
          }),
          // 时间标签
          Positioned(
            left: 8,
            right: 8,
            bottom: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children:
                  ['11:00', '12:00', '13:00', '14:00', '15:00']
                      .map(
                        (time) => Text(
                          time,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color:
                                isDark
                                    ? const Color(0xFF6B7280)
                                    : const Color(0xFF9CA3AF),
                          ),
                        ),
                      )
                      .toList(),
            ),
          ),
          // 睡眠阶段气泡
          ...widget.sleepStages.asMap().entries.map((entry) {
            final index = entry.key;
            final stage = entry.value;
            final step = 0.08;
            final start = (index * step).clamp(0.0, 0.92);
            final end = (0.5 + index * step).clamp(0.0, 1.0);

            final itemAnimation = CurvedAnimation(
              parent: _animationController,
              curve: Interval(start, end, curve: Curves.easeOutCubic),
            );

            return _SleepStageBubble(
              stage: stage,
              chartWidth: chartWidth,
              chartHeight: chartHeight - 32,
              animation: itemAnimation,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildLegend(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _LegendItem(
          color: const Color(0xFF9CB573),
          label: 'Core',
          isDark: isDark,
        ),
        _LegendItem(
          color: const Color(0xFF8D6E63),
          label: 'REM',
          isDark: isDark,
        ),
        _LegendItem(
          color: const Color(0xFFF4CD26),
          label: 'Post-REM',
          isDark: isDark,
        ),
      ],
    );
  }
}

/// 睡眠阶段气泡组件
class _SleepStageBubble extends StatelessWidget {
  final SleepStageData stage;
  final double chartWidth;
  final double chartHeight;
  final Animation<double> animation;

  const _SleepStageBubble({
    required this.stage,
    required this.chartWidth,
    required this.chartHeight,
    required this.animation,
  });

  Color _getColor() {
    switch (stage.type) {
      case SleepStageType.core:
        return const Color(0xFF9CB573);
      case SleepStageType.rem:
        return const Color(0xFFE99547);
      case SleepStageType.postREM:
        return const Color(0xFFF4CD26);
      case SleepStageType.deep:
        return const Color(0xFFC8B6F9);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColor();

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final width = (chartWidth * stage.widthPercent / 100) * animation.value;
        final height = stage.height * animation.value;

        return Positioned(
          left: (chartWidth * stage.left / 100),
          top: (chartHeight * stage.topPercent / 100),
          child: Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(width / 2),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// 工具提示箭尾绘制器
class _TooltipTailPainter extends CustomPainter {
  final Color color;

  _TooltipTailPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path();
    path.moveTo(size.width / 2 - 8, 0);
    path.lineTo(size.width / 2 + 8, 0);
    path.lineTo(size.width / 2, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _TooltipTailPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

/// 图例项组件
class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final bool isDark;

  const _LegendItem({
    required this.color,
    required this.label,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.grey.shade200 : const Color(0xFF5D4037),
          ),
        ),
      ],
    );
  }
}
