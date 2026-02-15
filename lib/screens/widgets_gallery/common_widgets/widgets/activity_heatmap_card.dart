import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';

/// 活动热力图小组件
///
/// 展示今日24小时的活动热力图，支持不同时间粒度（5/10/15/30/60分钟）
/// 颜色深浅表示活动密集程度，根据标签显示不同颜色
class ActivityHeatmapCardWidget extends StatefulWidget {
  /// 时间粒度（分钟）：5, 10, 15, 30, 60
  final int timeGranularity;

  /// 热力图数据列表
  final List<TimeSlotData> timeSlots;

  /// 总时长（分钟）
  final int totalMinutes;

  /// 活跃小时数
  final int activeHours;

  /// 小组件尺寸
  final HomeWidgetSize size;

  const ActivityHeatmapCardWidget({
    super.key,
    required this.timeGranularity,
    required this.timeSlots,
    required this.totalMinutes,
    required this.activeHours,
    this.size = const LargeSize()3,
  });

  /// 从 props 创建实例（用于公共小组件系统）
  factory ActivityHeatmapCardWidget.fromProps(
    Map<String, dynamic> props,
    HomeWidgetSize size,
  ) {
    final timeGranularity = props['timeGranularity'] as int? ?? 60;

    // 解析时间槽数据
    final timeSlotsList = (props['timeSlots'] as List<dynamic>?)
            ?.map((e) => TimeSlotData.fromMap(e as Map<String, dynamic>))
            .toList() ??
        [];

    return ActivityHeatmapCardWidget(
      timeGranularity: timeGranularity,
      timeSlots: timeSlotsList,
      totalMinutes: props['totalMinutes'] as int? ?? 0,
      activeHours: props['activeHours'] as int? ?? 0,
      size: size,
    );
  }

  @override
  State<ActivityHeatmapCardWidget> createState() =>
      _ActivityHeatmapCardWidgetState();
}

class _ActivityHeatmapCardWidgetState extends State<ActivityHeatmapCardWidget> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: widget.size.getPadding(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '今日活动热力图',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.pink,
                    ),
              ),
              Icon(
                Icons.chevron_right,
                size: 18,
                color: Colors.pink.withOpacity(0.6),
              ),
            ],
          ),
          SizedBox(height: widget.size.getTitleSpacing()),

          // 24小时热力图网格
          Expanded(child: _buildHeatmap()),

          SizedBox(height: widget.size.getItemSpacing()),

          // 图例
          _buildLegend(),

          SizedBox(height: widget.size.getSmallSpacing()),

          // 统计信息
          _buildStats(),
        ],
      ),
    );
  }

  Widget _buildHeatmap() {
    final granularity = widget.timeGranularity;

    switch (granularity) {
      case 5:
        return _buildGranularHeatmap(5);
      case 10:
        return _buildGranularHeatmap(10);
      case 15:
        return _buildGranularHeatmap(15);
      case 30:
        return _buildGranularHeatmap(30);
      case 60:
      default:
        return _build60MinHeatmap();
    }
  }

  // 通用的细粒度热力图构建方法（5/10/15/30分钟）
  Widget _buildGranularHeatmap(int granularity) {
    final columns = 12;
    final rows = (widget.timeSlots.length / columns).ceil();

    // 确保至少有1行
    final actualRows = rows > 0 ? rows : 1;

    return Column(
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: List.generate(actualRows, (row) {
        return Expanded(
          flex: 1,
          child: Row(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: List.generate(columns, (col) {
              final index = row * columns + col;
              if (index >= widget.timeSlots.length) {
                return const Expanded(child: SizedBox());
              }
              final data = widget.timeSlots[index];
              return Expanded(
                flex: 1,
                child: _buildHeatmapCell(
                  hour: data.hour,
                  durationMinutes: data.durationMinutes,
                  label: '',
                  showLabel: false,
                  tagDurations: data.tagDurations,
                ),
              );
            }),
          ),
        );
      }),
    );
  }

  // 60分钟粒度（24小时，4行6列）- 显示文本
  Widget _build60MinHeatmap() {
    return Column(
      children: List.generate(4, (row) {
        return Expanded(
          child: Row(
            children: List.generate(6, (col) {
              final index = row * 6 + col;
              final data = index < widget.timeSlots.length
                  ? widget.timeSlots[index]
                  : TimeSlotData(hour: col + row * 6, minute: 0, durationMinutes: 0);
              return Expanded(
                child: _buildHeatmapCell(
                  hour: data.hour,
                  durationMinutes: data.durationMinutes,
                  label: '${data.hour}',
                  showLabel: true,
                  tagDurations: data.tagDurations,
                ),
              );
            }),
          ),
        );
      }),
    );
  }

  Widget _buildHeatmapCell({
    required int hour,
    required int durationMinutes,
    required String label,
    bool showLabel = true,
    Map<String, int> tagDurations = const {},
  }) {
    final color = _getSlotColor(durationMinutes, widget.timeGranularity, tagDurations);
    final isActive = durationMinutes > 0;

    return Container(
      margin: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
        border: Border.all(
          color: Colors.grey.withOpacity(0.2),
          width: 0.5,
        ),
      ),
      child: showLabel
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (label.isNotEmpty)
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: widget.size.getLegendFontSize(),
                      fontWeight: FontWeight.w500,
                      color: _getTextColor(color),
                    ),
                  ),
                if (isActive) ...[
                  SizedBox(height: widget.size.getSmallSpacing()),
                  Text(
                    _formatMinutes(durationMinutes),
                    style: TextStyle(
                      fontSize: widget.size.getLegendFontSize() - 2,
                      color: _getTextColor(color),
                    ),
                  ),
                ],
              ],
            )
          : const SizedBox.shrink(),
    );
  }

  Color _getSlotColor(
    int minutes,
    int granularity,
    Map<String, int> tagDurations,
  ) {
    if (minutes == 0) {
      return Colors.grey.withOpacity(0.1);
    }

    // 如果有标签，使用主要标签的颜色
    if (tagDurations.isNotEmpty) {
      final primaryTag = tagDurations.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;
      final tagColor = _getColorFromTag(primaryTag);

      // 根据占时间槽的比例来调整颜色的透明度
      final ratio = minutes / granularity;
      final alpha = _getAlphaFromRatio(ratio);

      return tagColor.withOpacity(alpha);
    }

    // 没有标签时，使用默认粉色
    final ratio = minutes / granularity;
    final alpha = _getAlphaFromRatio(ratio);
    return Colors.pink.withOpacity(alpha);
  }

  double _getAlphaFromRatio(double ratio) {
    if (ratio < 0.25) {
      return 0.3;
    } else if (ratio < 0.5) {
      return 0.5;
    } else if (ratio < 0.75) {
      return 0.7;
    } else {
      return 1.0;
    }
  }

  Color _getTextColor(Color background) {
    if (background == Colors.grey.withOpacity(0.1)) {
      return Colors.grey.withOpacity(0.7);
    }
    return background.computeLuminance() > 0.5 ? Colors.black87 : Colors.white;
  }

  String _formatMinutes(int minutes) {
    if (minutes < 60) {
      return '${minutes}m';
    } else {
      final hours = minutes ~/ 60;
      final mins = minutes % 60;
      return mins > 0 ? '${hours}h${mins}m' : '${hours}h';
    }
  }

  Widget _buildLegend() {
    // 收集所有标签
    final allTags = <String>{};
    for (final slot in widget.timeSlots) {
      allTags.addAll(slot.tagDurations.keys);
    }

    // 统计标签使用情况
    final tagStats = <String, int>{};
    for (final slot in widget.timeSlots) {
      for (final entry in slot.tagDurations.entries) {
        tagStats[entry.key] = (tagStats[entry.key] ?? 0) + entry.value;
      }
    }

    // 取前3个标签
    final topTags = tagStats.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final displayTags = topTags.take(3).toList();

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: displayTags.map((entry) {
        final color = _getColorFromTag(entry.key);
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 4),
            Text(entry.key, style: TextStyle(fontSize: widget.size.getLegendFontSize())),
          ],
        );
      }).toList(),
    );
  }

  Color _getColorFromTag(String tag) {
    final baseHue = (tag.hashCode % 360).abs().toDouble();
    return HSLColor.fromAHSL(1.0, baseHue, 0.6, 0.5).toColor();
  }

  Widget _buildStats() {
    if (widget.timeSlots.isEmpty) {
      return Text(
        '今日暂无活动',
        style: TextStyle(
          fontSize: widget.size.getLegendFontSize(),
          color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6),
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '总时长: ${_formatMinutes(widget.totalMinutes)}',
          style: TextStyle(
            fontSize: widget.size.getLegendFontSize(),
            color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
          ),
        ),
        Text(
          '活跃: ${widget.activeHours}小时',
          style: TextStyle(
            fontSize: widget.size.getLegendFontSize(),
            color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
          ),
        ),
      ],
    );
  }
}

/// 时间槽数据
class TimeSlotData {
  final int hour;
  final int minute;
  final int durationMinutes;

  /// 标签到时长的映射（用于确定主要标签颜色）
  final Map<String, int> tagDurations;

  TimeSlotData({
    required this.hour,
    required this.minute,
    required this.durationMinutes,
    this.tagDurations = const {},
  });

  /// 从 Map 创建实例
  factory TimeSlotData.fromMap(Map<String, dynamic> map) {
    return TimeSlotData(
      hour: map['hour'] as int? ?? 0,
      minute: map['minute'] as int? ?? 0,
      durationMinutes: map['durationMinutes'] as int? ?? 0,
      tagDurations: (map['tagDurations'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, v as int)) ??
          const {},
    );
  }

  /// 转换为 Map
  Map<String, dynamic> toMap() {
    return {
      'hour': hour,
      'minute': minute,
      'durationMinutes': durationMinutes,
      'tagDurations': tagDurations,
    };
  }

  /// 获取持续时间最长的标签
  String? get primaryTag {
    if (tagDurations.isEmpty) return null;
    return tagDurations.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }
}
