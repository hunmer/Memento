import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../models/checkin_item.dart';

class DailyCheckinChart extends StatelessWidget {
  final bool isMonthly;
  final List<CheckinItem> checkinItems;

  const DailyCheckinChart({
    super.key,
    required this.isMonthly,
    required this.checkinItems,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final data = _prepareData();

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: theme.textTheme.bodySmall,
                );
              },
            ),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < data.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      isMonthly ? '${index + 1}日' : '${_getWeekday(index)}',
                      style: theme.textTheme.bodySmall,
                    ),
                  );
                }
                return const SizedBox();
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: data.asMap().entries.map((entry) {
              return FlSpot(entry.key.toDouble(), entry.value.toDouble());
            }).toList(),
            isCurved: true,
            color: theme.colorScheme.primary,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: theme.colorScheme.primary.withOpacity(0.2),
            ),
          ),
        ],
      ),
    );
  }

  List<int> _prepareData() {
    final now = DateTime.now();
    final days = isMonthly ? 30 : 7;
    List<int> dailyCount = List.filled(days, 0);

    for (var item in checkinItems) {
      for (var date in item.checkInRecords.keys) {
        final diff = now.difference(date).inDays;
        if (diff < days) {
          dailyCount[days - diff - 1]++;
        }
      }
    }

    return dailyCount;
  }

  String _getWeekday(int index) {
    const weekdays = ['一', '二', '三', '四', '五', '六', '日'];
    final now = DateTime.now();
    final date = now.subtract(Duration(days: 6 - index));
    return weekdays[date.weekday - 1];
  }
}