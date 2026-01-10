import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:flutter/material.dart';

/// 分段进度条统计卡片示例
class SegmentedProgressCardExample extends StatelessWidget {
  const SegmentedProgressCardExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('分段进度条统计卡片')),
      body: Container(
        color: isDark ? Colors.black : const Color(0xFFF2F2F7),
        child: const Center(
          child: SegmentedProgressCardWidget(
            title: '今日支出',
            currentValue: 322,
            targetValue: 443,
            segments: [
              SegmentData(label: '餐饮', value: 37, color: Color(0xFFFF3B30)),
              SegmentData(label: '健身', value: 43, color: Color(0xFF007AFF)),
              SegmentData(label: '交通', value: 31, color: Color(0xFFFFCC00)),
              SegmentData(label: '其他', value: 11, color: Color(0xFF8E8E93)),
            ],
            unit: '\$',
          ),
        ),
      ),
    );
  }
}

/// 分段数据模型
class SegmentData {
  final String label;
  final double value;
  final Color color;

  const SegmentData({
    required this.label,
    required this.value,
    required this.color,
  });
}

/// 分段进度条统计小组件
class SegmentedProgressCardWidget extends StatefulWidget {
  /// 卡片标题
  final String title;

  /// 当前值
  final double currentValue;

  /// 目标值
  final double targetValue;

  /// 分段数据
  final List<SegmentData> segments;

  /// 数值单位
  final String unit;

  const SegmentedProgressCardWidget({
    super.key,
    required this.title,
    required this.currentValue,
    required this.targetValue,
    required this.segments,
    this.unit = '',
  });

  @override
  State<SegmentedProgressCardWidget> createState() =>
      _SegmentedProgressCardWidgetState();
}

class _SegmentedProgressCardWidgetState extends State<SegmentedProgressCardWidget>
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

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - _animation.value)),
            child: child,
          ),
        );
      },
      child: Container(
        width: 340,
        decoration: BoxDecoration(
          color: isDark ? Colors.black : Colors.white,
          borderRadius: BorderRadius.circular(40),
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 40,
                offset: const Offset(0, 12),
              ),
          ],
          border: isDark ? Border.all(color: Colors.white.withOpacity(0.1)) : null,
        ),
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题和数值
            _buildHeader(context, isDark),
            const SizedBox(height: 32),
            // 分段进度条
            _buildProgressBar(context, isDark),
            const SizedBox(height: 32),
            // 分段列表
            ..._buildSegmentList(context, isDark),
          ],
        ),
      ),
    );
  }

  /// 构建标题和数值部分
  Widget _buildHeader(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.title,
          style: TextStyle(
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
            fontSize: 15,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 48,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 180,
                height: 40,
                child: AnimatedFlipCounter(
                  value: widget.currentValue * _animation.value,
                  fractionDigits: 0,
                  textStyle: TextStyle(
                    color: isDark ? Colors.white : Colors.grey.shade900,
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    height: 1.0,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 20,
                child: Text(
                  '/ ${widget.targetValue.toInt()}',
                  style: TextStyle(
                    color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    height: 1.0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 构建分段进度条
  Widget _buildProgressBar(BuildContext context, bool isDark) {
    final totalValue = widget.segments.fold<double>(0, (sum, seg) => sum + seg.value);

    return Container(
      height: 10,
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(5),
        child: Row(
          children: widget.segments.map((segment) {
            final percentage = totalValue > 0 ? segment.value / totalValue : 0;
            return Expanded(
              flex: (percentage * 100).toInt(),
              child: Container(
                color: segment.color,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  /// 构建分段列表
  List<Widget> _buildSegmentList(BuildContext context, bool isDark) {
    final List<Widget> items = [];

    for (int i = 0; i < widget.segments.length; i++) {
      final segment = widget.segments[i];

      // 为每个列表项创建延迟动画
      final itemAnimation = CurvedAnimation(
        parent: _animationController,
        curve: Interval(
          i * 0.08,
          0.5 + i * 0.08,
          curve: Curves.easeOutCubic,
        ),
      );

      if (i > 0) {
        items.add(const SizedBox(height: 18));
      }

      items.add(
        AnimatedBuilder(
          animation: itemAnimation,
          builder: (context, child) {
            return Opacity(
              opacity: itemAnimation.value,
              child: Transform.translate(
                offset: Offset(0, 10 * (1 - itemAnimation.value)),
                child: _SegmentItem(
                  segment: segment,
                  isDark: isDark,
                  animation: itemAnimation,
                  unit: widget.unit,
                ),
              ),
            );
          },
        ),
      );
    }

    return items;
  }
}

/// 单个分段项
class _SegmentItem extends StatelessWidget {
  final SegmentData segment;
  final bool isDark;
  final Animation<double> animation;
  final String unit;

  const _SegmentItem({
    required this.segment,
    required this.isDark,
    required this.animation,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // 颜色指示器
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: segment.color,
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              BoxShadow(
                color: segment.color.withOpacity(0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
        const SizedBox(width: 14),
        // 标签
        Text(
          segment.label,
          style: TextStyle(
            color: isDark ? Colors.grey.shade200 : Colors.grey.shade700,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        // 数值
        SizedBox(
          height: 20,
          child: Text(
            unit == '' ? '${segment.value.toInt()}' : '$unit${segment.value.toInt()}',
            style: TextStyle(
              color: isDark ? Colors.white : Colors.grey.shade900,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              height: 1.0,
            ),
          ),
        ),
      ],
    );
  }
}
