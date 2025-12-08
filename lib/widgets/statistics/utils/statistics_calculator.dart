import 'package:flutter/material.dart';
import 'package:Memento/widgets/statistics/models/statistics_models.dart';

/// 通用的统计计算工具类
class StatisticsCalculator {
  /// 根据标签计算活动分布数据
  static List<DistributionData> calculateDistributionByTag(
    List<Map<String, dynamic>> records, {
    required String tagField,
    required String valueField,
    int? totalMinutes,
  }) {
    final Map<String, double> tagMinutes = {};

    for (var record in records) {
      final value = (record[valueField] ?? 0.0).toDouble();
      final tag = record[tagField]?.toString() ?? '';

      tagMinutes[tag] = (tagMinutes[tag] ?? 0.0) + value;
    }

    final sortedEntries =
        tagMinutes.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return sortedEntries
        .map(
          (entry) => DistributionData(
            label: entry.key.isEmpty ? 'Unnamed' : entry.key,
            value: entry.value,
          ),
        )
        .toList();
  }

  /// 计算排行榜数据
  static List<RankingData> calculateRanking(
    List<Map<String, dynamic>> records, {
    required String labelField,
    required String valueField,
    String? iconField,
    Map<String, dynamic>? extraDataField,
  }) {
    final data = <RankingData>[];

    for (var record in records) {
      final value = (record[valueField] ?? 0.0).toDouble();
      final label = record[labelField]?.toString() ?? '';
      final icon = iconField != null ? record[iconField]?.toString() : null;
      final extraData = extraDataField != null ? record[extraDataField] : null;

      data.add(
        RankingData(
          label: label.isEmpty ? 'Unnamed' : label,
          value: value,
          icon: icon,
          extraData: extraData,
        ),
      );
    }

    data.sort((a, b) => b.value.compareTo(a.value));

    return data;
  }

  /// 计算时间序列数据
  static List<TimeSeriesData> calculateTimeSeries(
    List<Map<String, dynamic>> records, {
    required String dateField,
    required String valueField,
    String? groupField,
    String? labelField,
  }) {
    final Map<String, Map<DateTime, double>> groupedData = {};

    for (var record in records) {
      final dateStr = record[dateField]?.toString() ?? '';
      final date = DateTime.tryParse(dateStr);
      if (date == null) continue;

      final value = (record[valueField] ?? 0.0).toDouble();
      final group =
          groupField != null ? record[groupField]?.toString() ?? '' : 'default';

      if (!groupedData.containsKey(group)) {
        groupedData[group] = {};
      }

      final normalizedDate = DateTime(date.year, date.month, date.day);
      groupedData[group]![normalizedDate] =
          (groupedData[group]![normalizedDate] ?? 0.0) + value;
    }

    return groupedData.entries.map((entry) {
      final points =
          entry.value.entries
              .map((e) => TimeSeriesPoint(date: e.key, value: e.value))
              .toList()
            ..sort((a, b) => a.date.compareTo(b.date));

      return TimeSeriesData(label: entry.key, points: points);
    }).toList();
  }

  /// 计算24小时分布数据
  static List<TimeSeriesPoint> calculateHourlyDistribution(
    List<Map<String, dynamic>> records, {
    required String dateField,
    required String valueField,
  }) {
    final Map<int, double> hourlyMap = {};

    for (int i = 0; i < 24; i++) {
      hourlyMap[i] = 0.0;
    }

    for (var record in records) {
      final dateStr = record[dateField]?.toString() ?? '';
      final date = DateTime.tryParse(dateStr);
      if (date == null) continue;

      final value = (record[valueField] ?? 0.0).toDouble();
      final hour = date.hour;

      hourlyMap[hour] = (hourlyMap[hour] ?? 0.0) + value;
    }

    return hourlyMap.entries
        .map(
          (entry) => TimeSeriesPoint(
            date: DateTime(2020, 1, 1, entry.key),
            value: entry.value,
          ),
        )
        .toList();
  }

  /// 根据颜色获取哈希颜色
  static Color getColorForLabel(String label, List<Color> colorPalette) {
    if (label.isEmpty) return Colors.grey;
    final int hash = label.hashCode;
    return colorPalette[hash.abs() % colorPalette.length];
  }

  /// 为分布数据分配颜色
  static List<DistributionData> assignColorsToDistribution(
    List<DistributionData> data,
    List<Color> colorPalette,
  ) {
    return data.asMap().entries.map((entry) {
      final item = entry.value;

      if (item.color != null) return item;

      return DistributionData(
        label: item.label,
        value: item.value,
        color: getColorForLabel(item.label, colorPalette),
        icon: item.icon,
      );
    }).toList();
  }

  /// 为排行榜数据分配颜色
  static List<RankingData> assignColorsToRanking(
    List<RankingData> data,
    List<Color> colorPalette,
  ) {
    return data.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;

      if (item.color != null) return item;

      return RankingData(
        label: item.label,
        value: item.value,
        color: getColorForLabel(item.label, colorPalette),
        icon: item.icon,
        order: index + 1,
        extraData: item.extraData,
      );
    }).toList();
  }

  /// 过滤指定日期范围内的记录
  static List<Map<String, dynamic>> filterByDateRange(
    List<Map<String, dynamic>> records,
    DateTime startDate,
    DateTime endDate, {
    required String dateField,
  }) {
    return records.where((record) {
      final dateStr = record[dateField]?.toString() ?? '';
      final date = DateTime.tryParse(dateStr);
      if (date == null) return false;

      final normalizedDate = DateTime(date.year, date.month, date.day);
      return normalizedDate.isAfter(
            startDate.subtract(const Duration(days: 1)),
          ) &&
          normalizedDate.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();
  }

  /// 计算总计值
  static double? calculateTotalValue(
    List<DistributionData>? distributionData,
    List<RankingData>? rankingData,
    List<TimeSeriesData>? timeSeriesData,
  ) {
    if (distributionData != null && distributionData.isNotEmpty) {
      return distributionData.fold(0.0, (sum, item) => sum! + item.value);
    }

    if (rankingData != null && rankingData.isNotEmpty) {
      return rankingData.fold(0.0, (sum, item) => sum! + item.value);
    }

    if (timeSeriesData != null && timeSeriesData.isNotEmpty) {
      double total = 0.0;
      for (var series in timeSeriesData) {
        for (var point in series.points) {
          total += point.value;
        }
      }
      return total;
    }

    return null;
  }

  /// 计算平均值
  static double calculateAverage(List<double> values) {
    if (values.isEmpty) return 0.0;
    return values.reduce((a, b) => a + b) / values.length;
  }

  /// 计算百分比
  static double calculatePercentage(double value, double total) {
    if (total == 0) return 0.0;
    return (value / total) * 100;
  }

  /// 格式化数值显示
  static String formatValue(double value, {String? unit}) {
    if (unit != null) {
      return '${value.toStringAsFixed(1)}$unit';
    }
    return value.toStringAsFixed(1);
  }

  /// 格式化百分比显示
  static String formatPercentage(double percentage) {
    return '${percentage.toStringAsFixed(1)}%';
  }

  /// 查找最大最小值
  static ({double min, double max}) findMinMax(List<double> values) {
    if (values.isEmpty) return (min: 0.0, max: 0.0);

    double min = values.first;
    double max = values.first;

    for (var value in values) {
      if (value < min) min = value;
      if (value > max) max = value;
    }

    return (min: min, max: max);
  }

  /// 分组统计
  static Map<String, List<Map<String, dynamic>>> groupBy(
    List<Map<String, dynamic>> records,
    String field,
  ) {
    final groups = <String, List<Map<String, dynamic>>>{};

    for (var record in records) {
      final key = record[field]?.toString() ?? '';
      if (!groups.containsKey(key)) {
        groups[key] = [];
      }
      groups[key]!.add(record);
    }

    return groups;
  }

  /// 排序数据
  static List<Map<String, dynamic>> sortRecords(
    List<Map<String, dynamic>> records,
    String field, {
    bool ascending = false,
  }) {
    final sorted = List<Map<String, dynamic>>.from(records);
    sorted.sort((a, b) {
      final aVal = a[field] ?? 0;
      final bVal = b[field] ?? 0;

      if (ascending) {
        return (aVal as Comparable).compareTo(bVal as Comparable);
      } else {
        return (bVal as Comparable).compareTo(aVal as Comparable);
      }
    });

    return sorted;
  }

  /// 分页数据
  static List<Map<String, dynamic>> paginate(
    List<Map<String, dynamic>> records, {
    required int page,
    required int pageSize,
  }) {
    final startIndex = page * pageSize;
    final endIndex = startIndex + pageSize;

    if (startIndex >= records.length) {
      return [];
    }

    if (endIndex >= records.length) {
      return records.sublist(startIndex);
    }

    return records.sublist(startIndex, endIndex);
  }
}
