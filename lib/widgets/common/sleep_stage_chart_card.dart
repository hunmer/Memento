import 'package:flutter/material.dart';

/// 睡眠阶段类型
///
/// 表示睡眠的不同阶段：核心睡眠、快速眼动(REM)、后快速眼动和深度睡眠
enum SleepStageType {
  /// 核心睡眠
  core,

  /// 快速眼动睡眠
  rem,

  /// 后快速眼动睡眠
  postREM,

  /// 深度睡眠
  deep,
}

/// 睡眠阶段数据模型
///
/// 描述单个睡眠阶段的位置、大小和类型信息
class SleepStageData {
  /// 睡眠阶段类型
  final SleepStageType type;

  /// 左边距位置（百分比，0-100）
  final double left;

  /// 顶部位置（百分比，0-100）
  final double topPercent;

  /// 宽度（百分比，0-100）
  final double widthPercent;

  /// 高度（像素）
  final double height;

  const SleepStageData({
    required this.type,
    required this.left,
    required this.topPercent,
    required this.widthPercent,
    required this.height,
  });

  /// 从 JSON 创建
  ///
  /// 用于从 JSON 数据反序列化睡眠阶段数据
  factory SleepStageData.fromJson(Map<String, dynamic> json) {
    return SleepStageData(
      type: SleepStageType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => SleepStageType.core,
      ),
      left: (json['left'] as num).toDouble(),
      topPercent: (json['topPercent'] as num).toDouble(),
      widthPercent: (json['widthPercent'] as num).toDouble(),
      height: (json['height'] as num).toDouble(),
    );
  }

  /// 转换为 JSON
  ///
  /// 用于序列化睡眠阶段数据到 JSON
  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'left': left,
      'topPercent': topPercent,
      'widthPercent': widthPercent,
      'height': height,
    };
  }

  /// 复制并修改部分属性
  SleepStageData copyWith({
    SleepStageType? type,
    double? left,
    double? topPercent,
    double? widthPercent,
    double? height,
  }) {
    return SleepStageData(
      type: type ?? this.type,
      left: left ?? this.left,
      topPercent: topPercent ?? this.topPercent,
      widthPercent: widthPercent ?? this.widthPercent,
      height: height ?? this.height,
    );
  }
}

/// 睡眠阶段图表卡片组件
///
/// 展示睡眠阶段的可视化图表，支持动画效果和时间范围选择
class SleepStageChartCard extends StatefulWidget {
  /// 睡眠阶段数据列表
  final List<SleepStageData> sleepStages;

  /// 初始选中的标签索引
  final int selectedTab;

  /// 是否显示工具提示
  final bool showTooltip;

  /// 时间标签列表
  final List<String> timeLabels;

  const SleepStageChartCard({
    super.key,
    required this.sleepStages,
    this.selectedTab = 1,
    this.showTooltip = true,
    this.timeLabels = const ['11:00', '12:00', '13:00', '14:00', '15:00'],
  });

  @override
  State<SleepStageChartCard> createState() => _SleepStageChartCardState();
}

class _SleepStageChartCardState extends State<SleepStageChartCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  late int _selectedTab;

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
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? const Color(0xFF404040) : Colors.white,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 时间范围选择器
                  _buildTabSelector(context),
                  const SizedBox(height: 24),
                  // 睡眠阶段图表
                  _buildChart(context),
                  const SizedBox(height: 24),
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

  /// 构建时间范围选择器
  Widget _buildTabSelector(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tabs = ['1 Day', '1 Week', '1 Month', '1 Year', 'All Time'];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF3A3A3C).withOpacity(0.5)
            : const Color(0xFFF8F5F2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final isSelected = _selectedTab == index;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = index),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isDark ? const Color(0xFF3A3A3C) : Colors.white)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: isSelected
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
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isSelected
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

  /// 构建睡眠阶段图表
  Widget _buildChart(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chartWidth = 280.0;
    final chartHeight = 200.0;

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
                color: isDark
                    ? const Color(0xFF404040)
                    : const Color(0xFFE5E7EB),
              ),
            );
          }),
          // 时间标签
          Positioned(
            left: 4,
            right: 4,
            bottom: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: widget.timeLabels.map((time) {
                return Text(
                  time,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? const Color(0xFF6B7280)
                        : const Color(0xFF9CA3AF),
                  ),
                );
              }).toList(),
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

  /// 构建图例
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
        _LegendItem(
          color: const Color(0xFFC8B6F9),
          label: 'Deep',
          isDark: isDark,
        ),
      ],
    );
  }
}

/// 睡眠阶段气泡组件
///
/// 显示单个睡眠阶段的可视化气泡，带有动画效果
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

  /// 获取当前阶段类型的颜色
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

/// 图例项组件
///
/// 显示单个图例项，包含颜色点和标签
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
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.grey.shade200 : const Color(0xFF5D4037),
          ),
        ),
      ],
    );
  }
}
