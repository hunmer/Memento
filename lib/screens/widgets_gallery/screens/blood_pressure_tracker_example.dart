import 'package:flutter/material.dart';

/// 血压追踪器组件示例
///
/// 展示血压数值和一周趋势的卡片组件
class BloodPressureTrackerExample extends StatefulWidget {
  const BloodPressureTrackerExample({super.key});

  @override
  State<BloodPressureTrackerExample> createState() =>
      _BloodPressureTrackerExampleState();
}

class _BloodPressureTrackerExampleState
    extends State<BloodPressureTrackerExample>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;

  // 血压数据模型
  final BloodPressureData _bloodPressureData = BloodPressureData(
    systolic: 128,
    diastolic: 80,
    status: 'Stable Range',
    unit: 'mmHg',
    weekDays: [
      WeekDayData(label: 'M', normalPercent: 0.60, elevatedPercent: 0.20),
      WeekDayData(label: 'T', normalPercent: 0.70, elevatedPercent: 0.30),
      WeekDayData(label: 'W', normalPercent: 0.50, elevatedPercent: 0.20),
      WeekDayData(label: 'T', normalPercent: 0.85, elevatedPercent: 0.25),
      WeekDayData(label: 'F', normalPercent: 0.90, elevatedPercent: 0.25),
      WeekDayData(label: 'S', normalPercent: 0.80, elevatedPercent: 0.20),
      WeekDayData(label: 'S', normalPercent: 0.65, elevatedPercent: 0.20),
    ],
  );

  @override
  void initState() {
    super.initState();
    _initAnimation();
  }

  void _initAnimation() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
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
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('血压追踪器'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
      ),
      body: Center(
        child: FadeTransition(
          opacity: _fadeInAnimation,
          child: BloodPressureTrackerCard(
            data: _bloodPressureData,
            animationController: _animationController,
          ),
        ),
      ),
    );
  }
}

/// 血压追踪器卡片组件
class BloodPressureTrackerCard extends StatelessWidget {
  final BloodPressureData data;
  final AnimationController animationController;

  const BloodPressureTrackerCard({
    super.key,
    required this.data,
    required this.animationController,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: 350,
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
          _buildHeader(context),
          const SizedBox(height: 32),
          // 血压数值和趋势图
          _buildContent(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.water_drop,
                color: colorScheme.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Blood Pressure',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
        TextButton.icon(
          onPressed: () {},
          icon: Icon(
            Icons.chevron_right,
            color: colorScheme.onSurface.withOpacity(0.5),
            size: 20,
          ),
          label: Text(
            'Today',
            style: TextStyle(
              color: colorScheme.onSurface.withOpacity(0.5),
              fontSize: 14,
            ),
          ),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          ),
        ),
      ],
    );
  }

  Widget _buildContent(BuildContext context) {
    return Column(
      children: [
        // 血压数值
        _buildBloodPressureValue(context),
        const SizedBox(height: 16),
        // 周趋势图
        _buildWeekTrendChart(context),
      ],
    );
  }

  Widget _buildBloodPressureValue(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            AnimatedCountText(
              count: data.systolic,
              duration: const Duration(milliseconds: 1000),
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 40,
                  ),
            ),
            Text(
              '/',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 40,
                  ),
            ),
            AnimatedCountText(
              count: data.diastolic,
              duration: const Duration(milliseconds: 1000),
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 40,
                  ),
            ),
            const SizedBox(width: 4),
            Text(
              data.unit,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.6),
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          data.status,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.6),
              ),
        ),
      ],
    );
  }

  Widget _buildWeekTrendChart(BuildContext context) {
    return SizedBox(
      height: 80,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: data.weekDays.map((dayData) {
          return WeekDayBar(
            label: dayData.label,
            normalPercent: dayData.normalPercent,
            elevatedPercent: dayData.elevatedPercent,
            animationController: animationController,
          );
        }).toList(),
      ),
    );
  }
}

/// 周日柱状图组件
class WeekDayBar extends StatelessWidget {
  final String label;
  final double normalPercent;
  final double elevatedPercent;
  final AnimationController animationController;

  const WeekDayBar({
    super.key,
    required this.label,
    required this.normalPercent,
    required this.elevatedPercent,
    required this.animationController,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // 柱状图
        SizedBox(
          height: 48,
          width: 8,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              // 背景条
              Container(
                width: 8,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              // 正常范围条（浅色）
              AnimatedBuilder(
                animation: animationController,
                builder: (context, child) {
                  return FractionallySizedBox(
                    heightFactor: normalPercent * animationController.value,
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  );
                },
              ),
              // 升高范围条（深色）
              Positioned(
                bottom: (normalPercent - elevatedPercent) * 48,
                child: AnimatedBuilder(
                  animation: animationController,
                  builder: (context, child) {
                    return SizedBox(
                      height: elevatedPercent * 48 * animationController.value,
                      width: 8,
                      child: Container(
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // 标签
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.5),
                fontWeight: FontWeight.w500,
                fontSize: 10,
              ),
        ),
      ],
    );
  }
}

/// 数字计数动画组件
class AnimatedCountText extends StatefulWidget {
  final int count;
  final Duration duration;
  final TextStyle? style;

  const AnimatedCountText({
    super.key,
    required this.count,
    required this.duration,
    this.style,
  });

  @override
  State<AnimatedCountText> createState() => _AnimatedCountTextState();
}

class _AnimatedCountTextState extends State<AnimatedCountText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<int> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _animation = IntTween(begin: 0, end: widget.count).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Text(
          _animation.value.toString(),
          style: widget.style,
        );
      },
    );
  }
}

/// 血压数据模型
class BloodPressureData {
  final int systolic; // 收缩压
  final int diastolic; // 舒张压
  final String status; // 状态描述
  final String unit; // 单位
  final List<WeekDayData> weekDays; // 周数据

  BloodPressureData({
    required this.systolic,
    required this.diastolic,
    required this.status,
    required this.unit,
    required this.weekDays,
  });
}

/// 周日数据模型
class WeekDayData {
  final String label; // 标签 (M, T, W, T, F, S, S)
  final double normalPercent; // 正常范围百分比
  final double elevatedPercent; // 升高范围百分比

  WeekDayData({
    required this.label,
    required this.normalPercent,
    required this.elevatedPercent,
  });
}
