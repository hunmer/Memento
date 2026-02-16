import 'package:flutter/material.dart';
import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';

/// 双柱状数据模型
class DualBarData {
  final double primary;
  final double secondary;

  const DualBarData({required this.primary, required this.secondary});

  /// 从 JSON 创建
  factory DualBarData.fromJson(Map<String, dynamic> json) {
    return DualBarData(
      primary: (json['primary'] as num?)?.toDouble() ?? 0.0,
      secondary: (json['secondary'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {'primary': primary, 'secondary': secondary};
  }
}

/// 双柱状图统计卡片小组件
class DualBarChartCardWidget extends StatefulWidget {
  /// 标题
  final String title;

  /// 日期
  final String date;

  /// 主数值
  final int primaryValue;

  /// 次数值
  final int secondaryValue;

  /// 主标签
  final String primaryLabel;

  /// 次标签
  final String secondaryLabel;

  /// 警告阶段（可选）
  final String? warningStage;

  /// 图表数据列表
  final List<DualBarData> chartData;

  /// 是否为内联模式（内联模式使用 double.maxFinite，非内联模式使用固定尺寸）
  final bool inline;

  /// 组件尺寸
  final HomeWidgetSize size;

  const DualBarChartCardWidget({
    super.key,
    required this.title,
    required this.date,
    required this.primaryValue,
    required this.secondaryValue,
    required this.primaryLabel,
    required this.secondaryLabel,
    this.warningStage,
    required this.chartData,
    this.inline = false,
    this.size = const MediumSize(),
  });

  /// 从 props 创建实例
  factory DualBarChartCardWidget.fromProps(
    Map<String, dynamic> props,
    HomeWidgetSize size,
  ) {
    // 解析图表数据
    List<DualBarData> parseChartData(dynamic data) {
      if (data == null) return [];
      if (data is List) {
        return data.map((item) {
          if (item is DualBarData) return item;
          if (item is Map<String, dynamic>) {
            return DualBarData.fromJson(item);
          }
          return const DualBarData(primary: 0, secondary: 0);
        }).toList();
      }
      return [];
    }

    return DualBarChartCardWidget(
      title: props['title'] as String? ?? 'Stats',
      date: props['date'] as String? ?? '',
      primaryValue: (props['primaryValue'] as num?)?.toInt() ?? 0,
      secondaryValue: (props['secondaryValue'] as num?)?.toInt() ?? 0,
      primaryLabel: props['primaryLabel'] as String? ?? '',
      secondaryLabel: props['secondaryLabel'] as String? ?? '',
      warningStage: props['warningStage'] as String?,
      chartData: parseChartData(props['chartData']),
      inline: props['inline'] as bool? ?? false,
      size: size,
    );
  }

  @override
  State<DualBarChartCardWidget> createState() => _DualBarChartCardWidgetState();
}

class _DualBarChartCardWidgetState extends State<DualBarChartCardWidget>
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
    final primaryColor = Theme.of(context).colorScheme.primary;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - _animation.value)),
            child: Container(
              width: widget.inline ? double.maxFinite : 320,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1F2937) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: widget.size.getPadding(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 图表区域
                    SizedBox(
                      height: 128,
                      child: _buildChart(context, primaryColor),
                    ),
                    SizedBox(height: widget.size.getTitleSpacing()),
                    // 数值显示区域
                    _buildValues(context, primaryColor),
                    const SizedBox(height: 12),
                    // 底部信息区域
                    _buildFooter(context),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildChart(BuildContext context, Color primaryColor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final step = 0.03;

    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.zero,
      itemCount: widget.chartData.length,
      separatorBuilder:
          (_, __) => SizedBox(width: widget.size.getItemSpacing()),
      itemBuilder: (context, index) {
        final data = widget.chartData[index];
        // 确保 Interval 的 end 值不超过 1.0
        final start = (index * step).clamp(0.0, 0.95);
        final end = (0.5 + index * step).clamp(0.0, 1.0);

        final itemAnimation = CurvedAnimation(
          parent: _animationController,
          curve: Interval(start, end, curve: Curves.easeOutCubic),
        );

        return _DualBarColumn(
          primaryHeight: data.primary,
          secondaryHeight: data.secondary,
          primaryColor: primaryColor,
          secondaryColor:
              isDark
                  ? Colors.grey.shade600.withOpacity(0.3)
                  : Colors.grey.shade400.withOpacity(0.4),
          animation: itemAnimation,
          size: widget.size,
        );
      },
    );
  }

  Widget _buildValues(BuildContext context, Color primaryColor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDark ? const Color(0xFFF9FAFB) : const Color(0xFF1F2937);
    final subTextColor =
        isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Primary value
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: primaryColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 46,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 70,
                    height: 40,
                    child: AnimatedFlipCounter(
                      value: widget.primaryValue * _animation.value,
                      textStyle: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                        height: 1.0,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  SizedBox(
                    height: 18,
                    child: Text(
                      widget.primaryLabel,
                      style: TextStyle(
                        fontSize: 18,
                        color: subTextColor,
                        height: 1.0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(width: widget.size.getTitleSpacing()),
        // Secondary value
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.grey.shade600.withOpacity(0.6),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 46,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 50,
                    height: 40,
                    child: AnimatedFlipCounter(
                      value: widget.secondaryValue * _animation.value,
                      textStyle: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                        height: 1.0,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  SizedBox(
                    height: 18,
                    child: Text(
                      widget.secondaryLabel,
                      style: TextStyle(
                        fontSize: 18,
                        color: subTextColor,
                        height: 1.0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFooter(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDark ? const Color(0xFFF9FAFB) : const Color(0xFF1F2937);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: widget.size.getItemSpacing()),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                widget.date,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey.shade600 : Colors.grey.shade300,
                  shape: BoxShape.circle,
                ),
              ),
              if (widget.warningStage != null) ...[
                const SizedBox(width: 8),
                Row(
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Text(
                          '!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      widget.warningStage!,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
          Container(
            padding: EdgeInsets.all(widget.size.getSmallSpacing()),
            child: Icon(
              Icons.chevron_right,
              size: 28,
              color:
                  isDark
                      ? Colors.grey.shade600.withOpacity(0.4)
                      : Colors.grey.shade400.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }
}

/// 双柱列组件
class _DualBarColumn extends StatelessWidget {
  final double primaryHeight;
  final double secondaryHeight;
  final Color primaryColor;
  final Color secondaryColor;
  final Animation<double> animation;
  final HomeWidgetSize size;

  const _DualBarColumn({
    required this.primaryHeight,
    required this.secondaryHeight,
    required this.primaryColor,
    required this.secondaryColor,
    required this.animation,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return SizedBox(
          width: 8,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Primary bar (top)
              Container(
                width: 8,
                height: primaryHeight * animation.value,
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              SizedBox(height: size.getItemSpacing()),
              // Secondary bar (bottom)
              Container(
                width: 8,
                height: secondaryHeight * animation.value,
                decoration: BoxDecoration(
                  color: secondaryColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
