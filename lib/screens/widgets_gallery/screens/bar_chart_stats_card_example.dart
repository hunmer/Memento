import 'package:flutter/material.dart';

/// 柱状图统计卡片示例
class BarChartStatsCardExample extends StatelessWidget {
  const BarChartStatsCardExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('柱状图统计卡片')),
      body: Container(
        color: isDark ? Colors.grey.shade900 : const Color(0xFFF3F5F9),
        child: const Center(
          child: BarChartStatsCardWidget(
            title: 'Sleep Time',
            dateRange: '12 - 19 January 2025',
            averageValue: 6.5,
            unit: 'hours',
            icon: Icons.bedtime,
            iconColor: Color(0xFF00C968),
            data: [
              3.2,
              5.2,
              9.5,
              5.8,
              3.2,
              9.2,
              7.2,
            ],
            labels: [
              '12/01',
              '13/01',
              '14/01',
              '15/01',
              '16/01',
              '17/01',
              '18/01',
            ],
            maxValue: 10,
          ),
        ),
      ),
    );
  }
}

/// 柱状图统计小组件
class BarChartStatsCardWidget extends StatefulWidget {
  final String title;
  final String dateRange;
  final double averageValue;
  final String unit;
  final IconData icon;
  final Color iconColor;
  final List<double> data;
  final List<String> labels;
  final double maxValue;

  const BarChartStatsCardWidget({
    super.key,
    required this.title,
    required this.dateRange,
    required this.averageValue,
    required this.unit,
    required this.icon,
    required this.iconColor,
    required this.data,
    required this.labels,
    required this.maxValue,
  });

  @override
  State<BarChartStatsCardWidget> createState() => _BarChartStatsCardWidgetState();
}

class _BarChartStatsCardWidgetState extends State<BarChartStatsCardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  static const double _baseEnd = 0.6;

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
    final backgroundColor = isDark ? const Color(0xFF1F2937) : Colors.white;
    final gridColor = isDark ? Colors.grey.shade700 : Colors.grey.shade200;
    final textColor = isDark ? Colors.grey.shade400 : Colors.grey.shade500;

    final elementCount = widget.data.length + 2;
    final maxStep = (1.0 - _baseEnd) / (elementCount - 1);
    final step = maxStep * 0.9;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - _animation.value)),
            child: Container(
              width: 320,
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildHeader(isDark, textColor, 0, step),
                  const SizedBox(height: 32),
                  _buildAverageSection(isDark, 1, step),
                  const SizedBox(height: 32),
                  _buildChart(gridColor, textColor, step),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(bool isDark, Color textColor, int index, double step) {
    final itemAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Interval(
        index * step,
        _baseEnd + index * step,
        curve: Curves.easeOutCubic,
      ),
    );

    return Opacity(
      opacity: itemAnimation.value,
      child: Transform.translate(
        offset: Offset(0, 10 * (1 - itemAnimation.value)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.grey.shade900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.dateRange,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
                ),
              ],
            ),
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: widget.iconColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: widget.iconColor.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                widget.icon,
                color: Colors.white,
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAverageSection(bool isDark, int index, double step) {
    final itemAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Interval(
        index * step,
        _baseEnd + index * step,
        curve: Curves.easeOutCubic,
      ),
    );

    return Opacity(
      opacity: itemAnimation.value,
      child: Transform.translate(
        offset: Offset(0, 10 * (1 - itemAnimation.value)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  widget.averageValue.toStringAsFixed(1),
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.grey.shade900,
                    letterSpacing: -2,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  widget.unit,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.grey.shade900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Daily average',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChart(Color gridColor, Color textColor, double step) {
    return Column(
      children: [
        SizedBox(
          height: 192,
          child: Row(
            children: [
              _buildYAxis(textColor, gridColor, step),
              const SizedBox(width: 8),
              Expanded(child: _buildBars(gridColor, step)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _buildXLabels(textColor, step),
      ],
    );
  }

  Widget _buildYAxis(Color textColor, Color gridColor, double step) {
    return SizedBox(
      width: 24,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(6, (index) {
          final value = (widget.maxValue / 5) * (5 - index);
          final itemAnimation = CurvedAnimation(
            parent: _animationController,
            curve: Interval(
              2 * step,
              1.0,
              curve: Curves.easeOutCubic,
            ),
          );
          return Opacity(
            opacity: itemAnimation.value,
            child: Text(
              value.toInt().toString(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
              textAlign: TextAlign.right,
            ),
          );
        }),
      ),
    );
  }

  Widget _buildBars(Color gridColor, double step) {
    return Stack(
      children: [
        _buildGridLines(gridColor),
        _buildDataBars(step),
      ],
    );
  }

  Widget _buildGridLines(Color gridColor) {
    return Positioned.fill(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(
          6,
          (index) => Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: index < 5
                        ? gridColor.withOpacity(0.5)
                        : gridColor,
                    width: index < 5 ? 1 : 1,
                    style: BorderStyle.solid,
                  ),
                ),
              ),
              margin: EdgeInsets.only(bottom: index < 5 ? 0 : 0),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDataBars(double step) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(widget.data.length, (index) {
        final barAnimation = CurvedAnimation(
          parent: _animationController,
          curve: Interval(
            (2 + index) * step,
            _baseEnd + (2 + index) * step,
            curve: Curves.easeOutCubic,
          ),
        );

        final height = (widget.data[index] / widget.maxValue);

        return Expanded(
          child: Container(
            height: 192,
            alignment: Alignment.bottomCenter,
            child: Container(
              width: 12,
              height: 192 * height * barAnimation.value,
              decoration: BoxDecoration(
                color: widget.iconColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildXLabels(Color textColor, double step) {
    final labelsAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Interval(
        0.5,
        1.0,
        curve: Curves.easeOutCubic,
      ),
    );

    return Opacity(
      opacity: labelsAnimation.value,
      child: Padding(
        padding: const EdgeInsets.only(left: 32),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            widget.labels.length,
            (index) => Expanded(
              child: Center(
                child: Text(
                  widget.labels[index],
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
