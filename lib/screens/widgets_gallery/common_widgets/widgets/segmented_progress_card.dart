import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';

/// 分段数据模型
class SegmentData {
  final String label;
  final double value;
  final Color color;

  /// 格式化显示文本（用于显示小时/分钟等格式）
  final String display;

  const SegmentData({
    required this.label,
    required this.value,
    required this.color,
    this.display = '',
  });

  /// 从 JSON 创建
  factory SegmentData.fromJson(Map<String, dynamic> json) {
    return SegmentData(
      label: json['label'] as String? ?? '',
      value: (json['value'] as num?)?.toDouble() ?? 0.0,
      color: Color(json['color'] as int? ?? 0xFF000000),
      display: json['display'] as String? ?? '',
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'value': value,
      'color': color.value,
      'display': display,
    };
  }
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

  /// 是否为内联模式（内联模式使用 double.maxFinite，非内联模式使用固定尺寸）
  final bool inline;

  /// 组件尺寸
  final HomeWidgetSize size;

  const SegmentedProgressCardWidget({
    super.key,
    required this.title,
    required this.currentValue,
    required this.targetValue,
    required this.segments,
    this.unit = '',
    this.inline = false,
    this.size = HomeWidgetSize.medium,
  });

  /// 从 props 创建实例（用于公共小组件系统）
  factory SegmentedProgressCardWidget.fromProps(
    Map<String, dynamic> props,
    HomeWidgetSize size,
  ) {
    final segmentsList =
        (props['segments'] as List<dynamic>?)
            ?.map((e) => SegmentData.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [];

    return SegmentedProgressCardWidget(
      title: props['title'] as String? ?? '',
      currentValue: (props['currentValue'] as num?)?.toDouble() ?? 0.0,
      targetValue: (props['targetValue'] as num?)?.toDouble() ?? 0.0,
      segments: segmentsList,
      unit: props['unit'] as String? ?? '',
      inline: props['inline'] as bool? ?? false,
      size: size,
    );
  }

  @override
  State<SegmentedProgressCardWidget> createState() =>
      _SegmentedProgressCardWidgetState();
}

class _SegmentedProgressCardWidgetState
    extends State<SegmentedProgressCardWidget>
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
    // 立即启动动画，确保 AnimatedFlipCounter 能接收到从 0 到目标值的变化
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _animationController.forward();
    });
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
        width: widget.inline ? double.maxFinite : 340,
        decoration: BoxDecoration(
          color: isDark ? Colors.black : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 40,
                offset: const Offset(0, 12),
              ),
          ],
          border:
              isDark ? Border.all(color: Colors.white.withOpacity(0.1)) : null,
        ),
        padding: widget.size.getPadding(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题和数值
            _buildHeader(context, isDark),
            SizedBox(height: widget.size.getTitleSpacing()),
            // 分段进度条
            _buildProgressBar(context, isDark),
            SizedBox(height: widget.size.getTitleSpacing()),
            // 分段列表（支持滚动）
            Flexible(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _buildSegmentList(context, isDark),
                ),
              ),
            ),
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
            fontSize: widget.size.getSubtitleFontSize(),
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
          ),
        ),
        SizedBox(height: widget.size.getSmallSpacing() * 2),
        SizedBox(
          height: widget.size.getLargeFontSize() + widget.size.getSmallSpacing(),
          child: AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  AnimatedFlipCounter(
                    value: widget.currentValue * _animation.value,
                    fractionDigits: 0,
                    textStyle: TextStyle(
                      color: isDark ? Colors.white : Colors.grey.shade900,
                      fontSize: widget.size.getLargeFontSize(),
                      fontWeight: FontWeight.bold,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '/ ${widget.targetValue.toInt()}',
                    style: TextStyle(
                      color:
                          isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                      fontSize: widget.size.getLargeFontSize() * 0.5,
                      fontWeight: FontWeight.w500,
                      height: 1.0,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  /// 构建分段进度条
  Widget _buildProgressBar(BuildContext context, bool isDark) {
    final totalValue = widget.segments.fold<double>(
      0,
      (sum, seg) => sum + seg.value,
    );

    return Container(
      height: widget.size.getLegendIndicatorHeight(),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(widget.size.getLegendIndicatorHeight() / 2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.size.getLegendIndicatorHeight() / 2),
        child: Row(
          children:
              widget.segments.map((segment) {
                final percentage =
                    totalValue > 0 ? segment.value / totalValue : 0;
                return Expanded(
                  flex: (percentage * 100).toInt(),
                  child: Container(color: segment.color),
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
      // 确保 Interval 的 end 值不超过 1.0
      final end = (0.5 + i * 0.08).clamp(0.0, 1.0);
      final itemAnimation = CurvedAnimation(
        parent: _animationController,
        curve: Interval(i * 0.08, end, curve: Curves.easeOutCubic),
      );

      if (i > 0) {
        items.add(SizedBox(height: widget.size.getItemSpacing() * 2));
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
                  size: widget.size,
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
  final HomeWidgetSize size;

  const _SegmentItem({
    required this.segment,
    required this.isDark,
    required this.animation,
    required this.unit,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final indicatorSize = size.getLegendIndicatorWidth();

    return Row(
      children: [
        // 颜色指示器
        Container(
          width: indicatorSize,
          height: indicatorSize,
          decoration: BoxDecoration(
            color: segment.color,
            borderRadius: BorderRadius.circular(indicatorSize / 4),
            boxShadow: [
              BoxShadow(
                color: segment.color.withOpacity(0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
        SizedBox(width: size.getItemSpacing()),
        // 标签
        Text(
          segment.label,
          style: TextStyle(
            color: isDark ? Colors.grey.shade200 : Colors.grey.shade700,
            fontSize: size.getSubtitleFontSize(),
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        // 数值 - 优先使用 display 字段
        SizedBox(
          height: size.getSubtitleFontSize(),
          child: Text(
            segment.display.isNotEmpty
                ? segment.display
                : (unit == ''
                    ? '${segment.value.toInt()}'
                    : '$unit${segment.value.toInt()}'),
            style: TextStyle(
              color: isDark ? Colors.white : Colors.grey.shade900,
              fontSize: size.getSubtitleFontSize(),
              fontWeight: FontWeight.w600,
              height: 1.0,
            ),
          ),
        ),
      ],
    );
  }
}
