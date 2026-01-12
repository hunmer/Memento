import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';

/// 心情数据模型
class MoodEntry {
  final String emoji;
  final String label;
  final int value;

  const MoodEntry({
    required this.emoji,
    required this.label,
    required this.value,
  });

  /// 从 JSON 创建
  factory MoodEntry.fromJson(Map<String, dynamic> json) {
    return MoodEntry(
      emoji: json['emoji'] as String? ?? '',
      label: json['label'] as String? ?? '',
      value: json['value'] as int? ?? 0,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'emoji': emoji,
      'label': label,
      'value': value,
    };
  }
}

/// 心情类型枚举
enum MoodType {
  emoji,
  color,
}

/// 心情类型扩展
extension MoodTypeExtension on MoodType {
  String toJson() {
    switch (this) {
      case MoodType.emoji:
        return 'emoji';
      case MoodType.color:
        return 'color';
    }
  }

  static MoodType fromJson(String value) {
    switch (value) {
      case 'emoji':
        return MoodType.emoji;
      case 'color':
        return MoodType.color;
      default:
        return MoodType.emoji;
    }
  }
}

/// 心情图表卡片小组件
class MoodChartCardWidget extends StatefulWidget {
  /// 标题
  final String title;

  /// 副标题
  final String subtitle;

  /// 心情数据列表
  final List<MoodEntry> moods;

  /// 显示类型（emoji 或 color）
  final MoodType displayType;

  /// 主题颜色
  final Color primaryColor;

  const MoodChartCardWidget({
    super.key,
    required this.title,
    required this.subtitle,
    required this.moods,
    this.displayType = MoodType.emoji,
    this.primaryColor = const Color(0xFF6366F1),
  });

  /// 从 props 创建实例（用于公共小组件系统）
  factory MoodChartCardWidget.fromProps(
    Map<String, dynamic> props,
    HomeWidgetSize size,
  ) {
    final moodsList = (props['moods'] as List<dynamic>?)
            ?.map((e) => MoodEntry.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [];

    return MoodChartCardWidget(
      title: props['title'] as String? ?? '',
      subtitle: props['subtitle'] as String? ?? '',
      moods: moodsList,
      displayType: props['displayType'] != null
          ? MoodTypeExtension.fromJson(props['displayType'] as String)
          : MoodType.emoji,
      primaryColor: props.containsKey('primaryColor')
          ? Color(props['primaryColor'] as int)
          : const Color(0xFF6366F1),
    );
  }

  @override
  State<MoodChartCardWidget> createState() => _MoodChartCardWidgetState();
}

class _MoodChartCardWidgetState extends State<MoodChartCardWidget>
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
            child: Container(
              width: 320,
              constraints: const BoxConstraints(minWidth: 280),
              decoration: BoxDecoration(
                color: isDark ? Colors.black : Colors.white,
                borderRadius: BorderRadius.circular(24),
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
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 标题和副标题
                  _buildHeader(isDark),
                  const SizedBox(height: 24),
                  // 心情图表
                  _buildMoodChart(isDark),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// 构建标题区域
  Widget _buildHeader(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.title,
          style: TextStyle(
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
            fontSize: 14,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          widget.subtitle,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.grey.shade900,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  /// 构建心情图表
  Widget _buildMoodChart(bool isDark) {
    // 计算最大值用于缩放
    int maxValue = 0;
    for (var mood in widget.moods) {
      if (mood.value > maxValue) maxValue = mood.value;
    }

    return Column(
      children: [
        // Y轴刻度
        Row(
          children: [
            ...List.generate(5, (index) {
              final value = maxValue * (4 - index) ~/ 4;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    value.toString(),
                    style: TextStyle(
                      color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                      fontSize: 10,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              );
            }),
            const SizedBox(width: 8),
          ],
        ),
        // 柱状图
        SizedBox(
          height: 150,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(widget.moods.length, (index) {
              final mood = widget.moods[index];
              final barAnimation = CurvedAnimation(
                parent: _animation,
                curve: Interval(
                  index * 0.1,
                  0.5 + index * 0.1,
                  curve: Curves.easeOutCubic,
                ),
              );

              return _MoodBar(
                mood: mood,
                maxValue: maxValue,
                animation: barAnimation,
                displayType: widget.displayType,
                primaryColor: widget.primaryColor,
                isDark: isDark,
              );
            }),
          ),
        ),
        // X轴标签
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: widget.moods.map((mood) {
            return Expanded(
              child: Text(
                mood.label,
                style: TextStyle(
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  fontSize: 11,
                ),
                textAlign: TextAlign.center,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

/// 单个心情柱
class _MoodBar extends StatelessWidget {
  final MoodEntry mood;
  final int maxValue;
  final Animation<double> animation;
  final MoodType displayType;
  final Color primaryColor;
  final bool isDark;

  const _MoodBar({
    required this.mood,
    required this.maxValue,
    required this.animation,
    required this.displayType,
    required this.primaryColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final barHeight = maxValue > 0 ? (mood.value / maxValue) * 130 : 0.0;

    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          AnimatedBuilder(
            animation: animation,
            builder: (context, child) {
              return Container(
                height: barHeight * animation.value,
                decoration: BoxDecoration(
                  color: displayType == MoodType.color
                      ? primaryColor.withOpacity(0.7)
                      : isDark
                          ? Colors.grey.shade700
                          : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: displayType == MoodType.emoji
                    ? Center(
                        child: Text(
                          mood.emoji,
                          style: const TextStyle(fontSize: 20),
                        ),
                      )
                    : null,
              );
            },
          ),
        ],
      ),
    );
  }
}
