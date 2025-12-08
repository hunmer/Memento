import 'package:Memento/plugins/checkin/l10n/checkin_localizations.dart';

import 'package:Memento/plugins/checkin/models/checkin_item.dart';

enum GroupSortType {
  upcoming, // 按即将发生排序
  frequency, // 按打卡频率排序
  dateAdded, // 按添加日期排序
}

class GroupSortService {
  // 获取排序方式的显示名称
  static String getSortTypeName(GroupSortType type, context) {
    switch (type) {
      case GroupSortType.upcoming:
        return CheckinLocalizations.of(context).upcoming;

      case GroupSortType.frequency:
        return CheckinLocalizations.of(context).frequency;
      case GroupSortType.dateAdded:
        return CheckinLocalizations.of(context).dateAdded;
    }
  }

  // 对分组进行排序，并对每个分组内的项目进行排序
  static List<Map<String, dynamic>> sortGroups(
    List<Map<String, dynamic>> groups,
    GroupSortType sortType,
    bool isReversed,
  ) {
    // 先对分组进行排序
    List<Map<String, dynamic>> sortedGroups;
    switch (sortType) {
      case GroupSortType.upcoming:
        sortedGroups = _sortByUpcoming(groups, isReversed);
        break;
      case GroupSortType.frequency:
        sortedGroups = _sortByFrequency(groups, isReversed);
        break;
      case GroupSortType.dateAdded:
        sortedGroups = _sortByDateAdded(groups, isReversed);
        break;
    }

    // 然后对每个分组内的项目进行排序
    for (var group in sortedGroups) {
      List<CheckinItem> items = group['items'] as List<CheckinItem>;
      group['items'] = sortItems(items, sortType, isReversed);
    }

    return sortedGroups;
  }

  // 对单个分组内的打卡项目进行排序
  static List<CheckinItem> sortItems(
    List<CheckinItem> items,
    GroupSortType sortType,
    bool isReversed,
  ) {
    List<CheckinItem> sortedItems = List<CheckinItem>.from(items);

    switch (sortType) {
      case GroupSortType.upcoming:
        // 按紧急程度排序（未打卡的排前面）
        sortedItems.sort((a, b) {
          bool aChecked = a.isCheckedToday();
          bool bChecked = b.isCheckedToday();

          // 如果打卡状态不同，未打卡的排前面
          if (aChecked != bChecked) {
            return isReversed ? (aChecked ? -1 : 1) : (aChecked ? 1 : -1);
          }

          // 如果打卡状态相同，比较最后打卡时间
          DateTime? lastA = a.lastCheckinDate;
          DateTime? lastB = b.lastCheckinDate;

          if (lastA == null && lastB == null) return 0;
          if (lastA == null) return isReversed ? -1 : 1;
          if (lastB == null) return isReversed ? 1 : -1;

          return isReversed ? lastA.compareTo(lastB) : lastB.compareTo(lastA);
        });
        break;

      case GroupSortType.frequency:
        // 按打卡频率排序
        sortedItems.sort((a, b) {
          int freqA = a.frequency.where((day) => day).length;
          int freqB = b.frequency.where((day) => day).length;

          if (freqA == freqB) {
            // 频率相同时，按名称排序
            return a.name.compareTo(b.name);
          }

          return isReversed ? freqB.compareTo(freqA) : freqA.compareTo(freqB);
        });
        break;

      case GroupSortType.dateAdded:
        // 按添加日期排序（使用ID，因为ID是基于时间戳创建的）
        sortedItems.sort((a, b) {
          return isReversed ? b.id.compareTo(a.id) : a.id.compareTo(b.id);
        });
        break;
    }

    return sortedItems;
  }

  // 按即将发生排序（根据最近一次打卡时间和打卡频率）
  static List<Map<String, dynamic>> _sortByUpcoming(
    List<Map<String, dynamic>> groups,
    bool isReversed,
  ) {
    return List<Map<String, dynamic>>.from(groups)..sort((a, b) {
      List<CheckinItem> itemsA = a['items'] as List<CheckinItem>;
      List<CheckinItem> itemsB = b['items'] as List<CheckinItem>;

      // 计算每个分组的紧急程度（未打卡项目的数量）
      int urgencyA = _calculateUrgency(itemsA);
      int urgencyB = _calculateUrgency(itemsB);

      // 如果紧急程度相同，比较最后打卡时间
      if (urgencyA == urgencyB) {
        DateTime? lastA = _findLastCheckinDate(itemsA);
        DateTime? lastB = _findLastCheckinDate(itemsB);

        if (lastA == null && lastB == null) return 0;
        if (lastA == null) return isReversed ? -1 : 1;
        if (lastB == null) return isReversed ? 1 : -1;

        return isReversed ? lastA.compareTo(lastB) : lastB.compareTo(lastA);
      }

      return isReversed
          ? urgencyA.compareTo(urgencyB)
          : urgencyB.compareTo(urgencyA);
    });
  }

  // 按打卡频率排序
  static List<Map<String, dynamic>> _sortByFrequency(
    List<Map<String, dynamic>> groups,
    bool isReversed,
  ) {
    return List<Map<String, dynamic>>.from(groups)..sort((a, b) {
      List<CheckinItem> itemsA = a['items'] as List<CheckinItem>;
      List<CheckinItem> itemsB = b['items'] as List<CheckinItem>;

      // 计算每个分组的平均打卡频率
      double freqA = _calculateAverageFrequency(itemsA);
      double freqB = _calculateAverageFrequency(itemsB);

      return isReversed ? freqB.compareTo(freqA) : freqA.compareTo(freqB);
    });
  }

  // 按添加日期排序（使用ID，因为ID是基于时间戳创建的）
  static List<Map<String, dynamic>> _sortByDateAdded(
    List<Map<String, dynamic>> groups,
    bool isReversed,
  ) {
    return List<Map<String, dynamic>>.from(groups)..sort((a, b) {
      List<CheckinItem> itemsA = a['items'] as List<CheckinItem>;
      List<CheckinItem> itemsB = b['items'] as List<CheckinItem>;

      // 使用最早的ID（基于时间戳）作为创建时间的参考
      String earliestIdA = _findEarliestId(itemsA);
      String earliestIdB = _findEarliestId(itemsB);

      return isReversed
          ? earliestIdB.compareTo(earliestIdA)
          : earliestIdA.compareTo(earliestIdB);
    });
  }

  // 计算分组的紧急程度（未打卡的项目数量）
  static int _calculateUrgency(List<CheckinItem> items) {
    return items.where((item) => !item.isCheckedToday()).length;
  }

  // 查找最后一次打卡日期
  static DateTime? _findLastCheckinDate(List<CheckinItem> items) {
    DateTime? lastDate;
    for (var item in items) {
      DateTime? itemLastDate = item.lastCheckinDate;
      if (itemLastDate != null &&
          (lastDate == null || itemLastDate.isAfter(lastDate))) {
        lastDate = itemLastDate;
      }
    }
    return lastDate;
  }

  // 计算平均打卡频率（每周需要打卡的天数）
  static double _calculateAverageFrequency(List<CheckinItem> items) {
    if (items.isEmpty) return 0;
    double totalFrequency = 0;
    for (var item in items) {
      int daysPerWeek = item.frequency.where((day) => day).length;
      totalFrequency += daysPerWeek / 7; // 转换为每天的频率
    }
    return totalFrequency / items.length;
  }

  // 查找最早的ID（基于时间戳创建）
  static String _findEarliestId(List<CheckinItem> items) {
    if (items.isEmpty) return '';
    return items
        .map((item) => item.id)
        .reduce((a, b) => a.compareTo(b) < 0 ? a : b);
  }
}
