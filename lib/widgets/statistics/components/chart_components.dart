import 'dart:math';
import 'package:Memento/widgets/l10n/widget_localizations.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';
import 'package:Memento/widgets/statistics/models/statistics_models.dart';

/// 通用卡片构建器
Widget buildStatisticsCard({
  required BuildContext context,
  required String title,
  String? subtitle,
  required Widget child,
  EdgeInsets padding = const EdgeInsets.all(16),
}) {
  return Card(
    elevation: 0,
    color: Theme.of(context).cardColor,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    child: Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          ],
          const SizedBox(height: 16),
          child,
        ],
      ),
    ),
  );
}

/// 分布饼图组件
class DistributionPieChart extends StatelessWidget {
  final List<DistributionData> data;
  final List<Color> colorPalette;
  final String? centerText;
  final String? centerSubtext;
  final double? totalValue;
  final int maxSegments;
  final Function(int)? onSectionSelected;

  const DistributionPieChart({
    super.key,
    required this.data,
    required this.colorPalette,
    this.centerText,
    this.centerSubtext,
    this.totalValue,
    this.maxSegments = 5,
    this.onSectionSelected,
  });

  Color _getColorForIndex(int index, DistributionData item) {
    if (item.color != null) return item.color!;
    return colorPalette[index % colorPalette.length];
  }

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return Center(
        child: Text('widget_noDataAvailable'.tr),
      );
    }

    // 如果数据项过多，合并小的分段
    final List<DistributionData> chartData;
    if (data.length > maxSegments) {
      final topEntries = data.take(maxSegments - 1).toList();
      final otherMinutes = data
          .skip(maxSegments - 1)
          .fold(0.0, (sum, entry) => sum + entry.value);
      topEntries.add(
        DistributionData(
          label: 'Others',
          value: otherMinutes,
          color: Colors.grey,
        ),
      );
      chartData = topEntries;
    } else {
      chartData = data;
    }

    final total = data.fold(0.0, (sum, entry) => sum + entry.value);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Pie Chart
        Expanded(
          flex: 1,
          child: SizedBox(
            height: 160,
            child: Stack(
              children: [
                PieChart(
                  PieChartData(
                    sectionsSpace: 0,
                    centerSpaceRadius: 60,
                    sections: List.generate(chartData.length, (index) {
                      final entry = chartData[index];
                      final color = _getColorForIndex(index, entry);
                      return PieChartSectionData(
                        color: color,
                        value: entry.value,
                        title: '',
                        radius: 10,
                      );
                    }),
                  ),
                ),
                if (centerText != null)
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (centerText != null)
                          Text(
                            centerText!,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        if (centerSubtext != null)
                          Text(
                            centerSubtext!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).textTheme.bodySmall?.color,
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 24),
        // Legend
        Expanded(
          flex: 1,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: chartData.take(maxSegments - 1).map((entry) {
              final percentage = (entry.value / total * 100).toStringAsFixed(1);
              final color = _getColorForIndex(chartData.indexOf(entry), entry);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              entry.label,
                              style: const TextStyle(fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '$percentage%',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

/// 排行榜组件
class RankingList extends StatelessWidget {
  final List<RankingData> data;
  final List<Color> colorPalette;
  final Function(RankingData)? onItemTap;
  final String? valueLabel;
  final Widget? emptyWidget;

  const RankingList({
    super.key,
    required this.data,
    required this.colorPalette,
    this.onItemTap,
    this.valueLabel,
    this.emptyWidget,
  });

  Color _getColorForIndex(int index, RankingData item) {
    if (item.color != null) return item.color!;
    return colorPalette[index % colorPalette.length];
  }

  String _formatValue(double value) {
    if (valueLabel != null) {
      return '$value ${valueLabel!.toLowerCase()}';
    }
    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return emptyWidget ??
          Center(child: Text(WidgetLocalizations.of(context)!.noDataAvailable));
    }

    final maxValue = data.first.value;

    return Column(
      children: data.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        final color = _getColorForIndex(index, item);
        final progress = maxValue > 0 ? item.value / maxValue : 0.0;

        return InkWell(
          onTap: onItemTap != null ? () => onItemTap!(item) : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: item.icon != null
                      ? Icon(
                          IconData(int.parse(item.icon!), fontFamily: 'MaterialIcons'),
                          size: 16,
                          color: color,
                        )
                      : Text(
                          '${index + 1}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              item.label,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            _formatValue(item.value),
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).textTheme.bodySmall?.color,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                          color: color,
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// 时间序列趋势图组件
class TimeSeriesChart extends StatelessWidget {
  final List<TimeSeriesData> series;
  final double height;
  final bool showDots;
  final bool showLines;
  final List<Color> colorPalette;

  const TimeSeriesChart({
    super.key,
    required this.series,
    this.height = 200,
    this.showDots = true,
    this.showLines = true,
    required this.colorPalette,
  });

  @override
  Widget build(BuildContext context) {
    if (series.isEmpty) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text(WidgetLocalizations.of(context)!.noDataAvailable),
        ),
      );
    }

    // 收集所有数据点
    final allSpots = <FlSpot>[];

    for (final serie in series) {
      for (final point in serie.points) {
        final x = point.date.millisecondsSinceEpoch.toDouble();
        allSpots.add(FlSpot(x, point.value));
      }
    }

    if (allSpots.isEmpty) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text(WidgetLocalizations.of(context)!.noDataPoints),
        ),
      );
    }

    final minX = allSpots.first.x;
    final maxX = allSpots.last.x;
    final maxY = allSpots.map((spot) => spot.y).reduce(max);

    return SizedBox(
      height: height,
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          minX: minX,
          maxX: maxX,
          maxY: maxY * 1.1,
          lineTouchData: LineTouchData(
            enabled: true,
            touchTooltipData: LineTouchTooltipData(
              tooltipBgColor: Colors.blueGrey,
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((LineBarSpot touchedSpot) {
                  final date = DateFormat('MM-dd').format(
                    DateTime.fromMillisecondsSinceEpoch(touchedSpot.x.toInt()),
                  );
                  return LineTooltipItem(
                    '$date\n${touchedSpot.y.toStringAsFixed(0)}',
                    const TextStyle(color: Colors.white),
                  );
                }).toList();
              },
            ),
          ),
          lineBarsData: series.asMap().entries.map((entry) {
            final index = entry.key;
            final serie = entry.value;
            final color = serie.color ?? colorPalette[index % colorPalette.length];

            final spots = serie.points.map((point) {
              return FlSpot(point.date.millisecondsSinceEpoch.toDouble(), point.value);
            }).toList();

            return LineChartBarData(
              spots: spots,
              color: color,
              barWidth: 2,
              dotData: FlDotData(
                show: showDots,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: color,
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  );
                },
              ),
              isCurved: false,
              isStrokeCapRound: true,
              belowBarData: BarAreaData(
                show: false,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

/// 24小时分布条形图组件
class HourlyDistributionBar extends StatelessWidget {
  final List<TimeSeriesPoint> hourlyData;
  final List<Color> colorPalette;
  final double height;

  const HourlyDistributionBar({
    super.key,
    required this.hourlyData,
    required this.colorPalette,
    this.height = 32,
  });

  @override
  Widget build(BuildContext context) {
    if (hourlyData.isEmpty) {
      return Center(
        child: Text(WidgetLocalizations.of(context)!.noDataAvailable),
      );
    }

    // 转换为 24 小时的分布
    final Map<int, double> hourlyMap = {};
    for (int i = 0; i < 24; i++) {
      hourlyMap[i] = 0.0;
    }

    for (final point in hourlyData) {
      final hour = point.date.hour;
      hourlyMap[hour] = (hourlyMap[hour] ?? 0.0) + point.value;
    }

    final maxValue = hourlyMap.values.reduce(max);

    return Column(
      children: [
        SizedBox(
          height: height,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Row(
              children: List.generate(24, (index) {
                final value = hourlyMap[index] ?? 0.0;
                final flex = maxValue > 0 ? (value / maxValue * 100).round() : 0;
                final color = colorPalette[index % colorPalette.length];

                return Expanded(
                  flex: max(flex, 1), // 最小宽度
                  child: Container(
                    height: double.infinity,
                    color: value > 0 ? color : Theme.of(context).scaffoldBackgroundColor,
                    alignment: Alignment.center,
                    child: value > 0 && flex > 10
                        ? Text(
                              index.toString().padLeft(2, '0'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                          )
                        : null,
                  ),
                );
              }),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              WidgetLocalizations.of(context)!.time0000,
              style: TextStyle(fontSize: 10, color: Colors.grey),
            ),
            Text(
              WidgetLocalizations.of(context)!.time0600,
              style: TextStyle(fontSize: 10, color: Colors.grey),
            ),
            Text(
              WidgetLocalizations.of(context)!.time1200,
              style: TextStyle(fontSize: 10, color: Colors.grey),
            ),
            Text(
              WidgetLocalizations.of(context)!.time1800,
              style: TextStyle(fontSize: 10, color: Colors.grey),
            ),
            Text(
              WidgetLocalizations.of(context)!.time2400,
              style: TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
      ],
    );
  }
}
