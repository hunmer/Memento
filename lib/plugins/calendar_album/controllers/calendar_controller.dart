import 'package:Memento/core/plugin_manager.dart';
import 'package:flutter/material.dart';
import 'package:Memento/plugins/calendar_album/models/calendar_entry.dart';
import 'package:Memento/plugins/calendar_album/sample_data.dart';
import 'dart:convert';
import 'package:Memento/core/storage/storage_manager.dart';
import 'package:Memento/core/services/plugin_widget_sync_helper.dart';
import 'package:Memento/core/event/event_manager.dart';
import 'package:Memento/core/event/item_event_args.dart';

class CalendarController extends ChangeNotifier {
  // 发送事件通知
  void _notifyEvent(String action, CalendarEntry entry) {
    final eventArgs = ItemEventArgs(
      eventName: 'calendar_entry_$action',
      itemId: entry.id,
      title: entry.title,
      action: action,
    );
    EventManager.instance.broadcast('calendar_entry_$action', eventArgs);
  }
  final Map<DateTime, List<CalendarEntry>> _entries = {};
  DateTime _selectedDate = DateTime.now();
  DateTime _currentMonth = DateTime.now();
  DateTime _rangeStart = DateTime.now();
  DateTime _rangeEnd = DateTime.now();
  final List<DateTime> _displayMonths = [];
  final String _storageKey = 'calendar_album/calendar_entries';

  CalendarController() {
    _loadEntries();
    _updateDisplayMonths(); // 初始化时设置默认月份范围
  }

  StorageManager get _storage {
    final storage = PluginManager.instance.storageManager;
    if (storage == null) {
      throw Exception('StorageManager is not initialized in PluginManager');
    }
    return storage;
  }

  DateTime get selectedDate => _selectedDate;
  DateTime get currentMonth => _currentMonth;
  DateTime get rangeStart => _rangeStart;
  DateTime get rangeEnd => _rangeEnd;

  set currentMonth(DateTime month) {
    _currentMonth = DateTime(month.year, month.month);
    _rangeStart = DateTime(
      _currentMonth.year,
      _currentMonth.month - 1,
    ); // 默认显示前后1个月
    _rangeEnd = DateTime(_currentMonth.year, _currentMonth.month + 1);
    _updateDisplayMonths();
    notifyListeners();
  }

  bool get isExpanded => _rangeStart.month != _rangeEnd.month;

  void expandRange() {
    _rangeStart = DateTime(_currentMonth.year, _currentMonth.month - 3);
    _rangeEnd = DateTime(_currentMonth.year, _currentMonth.month + 3);
    _updateDisplayMonths();
    notifyListeners();
  }

  void collapseRange() {
    _rangeStart = DateTime(_currentMonth.year, _currentMonth.month);
    _rangeEnd = DateTime(_currentMonth.year, _currentMonth.month);
    _updateDisplayMonths();
    notifyListeners();
  }

  void toggleExpanded() {
    if (isExpanded) {
      collapseRange();
    } else {
      expandRange();
    }
  }

  void _updateDisplayMonths() {
    _displayMonths.clear();
    var current = DateTime(_rangeStart.year, _rangeStart.month);
    final end = DateTime(_rangeEnd.year, _rangeEnd.month);

    while (current.isBefore(end) || current.isAtSameMomentAs(end)) {
      _displayMonths.add(current);
      current = DateTime(current.year, current.month + 1);
    }
  }

  Map<DateTime, List<CalendarEntry>> get entries => _entries;

  bool loadMoreMonths(bool isBefore) {
    if (_displayMonths.isEmpty) return false;

    final newMonths = <DateTime>[];

    if (isBefore) {
      final firstMonth = _displayMonths.first;
      for (int i = 1; i <= 3; i++) {
        newMonths.add(DateTime(firstMonth.year, firstMonth.month - i));
      }
      _displayMonths.insertAll(0, newMonths);
      _rangeStart = _displayMonths.first;
    } else {
      final lastMonth = _displayMonths.last;
      for (int i = 1; i <= 3; i++) {
        newMonths.add(DateTime(lastMonth.year, lastMonth.month + i));
      }
      _displayMonths.addAll(newMonths);
      _rangeEnd = _displayMonths.last;
    }
    notifyListeners();
    return true;
  }

  List<DateTime> get displayMonths => _displayMonths;

  void selectDate(DateTime date) {
    _selectedDate = DateTime(date.year, date.month, date.day);
    notifyListeners();
  }

  List<CalendarEntry> getEntriesForDate(DateTime date) {
    final key = DateTime(date.year, date.month, date.day);
    return _entries[key] ?? [];
  }

  Future<void> _loadEntries() async {
    final data = await _storage.readSafeJson(_storageKey);

    // 检查是否有数据，如果没有则加载示例数据
    if (data.isEmpty) {
      await _loadSampleData();
      return;
    }

    // 加载现有数据
    data.forEach((key, value) {
      final date = DateTime.parse(key);
      final entries =
          (value as List)
              .map(
                (e) =>
                    CalendarEntry.fromJson(Map<String, dynamic>.from(e as Map)),
              )
              .toList();
      _entries[date] = entries;
      notifyListeners();
    });
  }

  /// 加载示例数据
  Future<void> _loadSampleData() async {
    final sampleEntries = CalendarAlbumSampleData.getSampleCalendarEntriesGrouped();

    // 将示例数据加载到内存中
    sampleEntries.forEach((date, entries) {
      _entries[date] = entries;
    });

    // 保存示例数据到存储
    await _saveEntries();

    notifyListeners();
  }

  Future<void> _saveEntries() async {
    final Map<String, dynamic> data = {};
    _entries.forEach((key, value) {
      data[key.toIso8601String()] = value.map((e) => e.toJson()).toList();
    });
    await _storage.setString(_storageKey, json.encode(data));
  }

  Future<void> addEntry(CalendarEntry entry) async {
    final date = DateTime(
      entry.createdAt.year,
      entry.createdAt.month,
      entry.createdAt.day,
    );
    if (!_entries.containsKey(date)) {
      _entries[date] = [];
    }
    _entries[date]!.add(entry);
    await _saveEntries();
    notifyListeners();

    // 广播添加事件
    _notifyEvent('added', entry);

    // 同步小组件数据
    await PluginWidgetSyncHelper.instance.syncCalendarAlbum();
  }

  Future<void> updateEntry(CalendarEntry entry) async {
    final date = DateTime(
      entry.createdAt.year,
      entry.createdAt.month,
      entry.createdAt.day,
    );
    if (_entries.containsKey(date)) {
      final index = _entries[date]!.indexWhere((e) => e.id == entry.id);
      if (index != -1) {
        _entries[date]![index] = entry;
        await _saveEntries();
        notifyListeners();

        // 广播更新事件
        _notifyEvent('updated', entry);

        // 同步小组件数据
        await PluginWidgetSyncHelper.instance.syncCalendarAlbum();
      }
    }
  }

  Future<void> deleteEntry(CalendarEntry entry) async {
    final date = DateTime(
      entry.createdAt.year,
      entry.createdAt.month,
      entry.createdAt.day,
    );
    if (_entries.containsKey(date)) {
      _entries[date]!.removeWhere((e) => e.id == entry.id);
      if (_entries[date]!.isEmpty) {
        _entries.remove(date);
      }
      await _saveEntries();
      notifyListeners();

      // 广播删除事件
      _notifyEvent('deleted', entry);

      // 同步小组件数据
      await PluginWidgetSyncHelper.instance.syncCalendarAlbum();
    }
  }

  List<String> getAllTags() {
    final Set<String> tags = {};
    for (var entries in _entries.values) {
      for (var entry in entries) {
        tags.addAll(entry.tags);
      }
    }
    return tags.toList()..sort();
  }

  List<CalendarEntry> getEntriesByTag(String tag) {
    final List<CalendarEntry> taggedEntries = [];
    for (var entries in _entries.values) {
      taggedEntries.addAll(entries.where((entry) => entry.tags.contains(tag)));
    }
    return taggedEntries..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  List<CalendarEntry> getEntriesByTags(List<String> tags) {
    if (tags.isEmpty) return [];

    final List<CalendarEntry> taggedEntries = [];
    for (var entries in _entries.values) {
      taggedEntries.addAll(
        entries.where((entry) => tags.every((tag) => entry.tags.contains(tag))),
      );
    }
    return taggedEntries..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  List<String> getAllImages() {
    final Set<String> images = {};
    for (var entries in _entries.values) {
      for (var entry in entries) {
        images.addAll(entry.imageUrls);
        images.addAll(entry.extractImagesFromMarkdown());
      }
    }
    return images.toList();
  }

  CalendarEntry? getEntryById(String id) {
    for (final entries in _entries.values) {
      for (final entry in entries) {
        if (entry.id == id) {
          return entry;
        }
      }
    }
    return null;
  }

  CalendarEntry? getDiaryEntryForImage(String imageUrl) {
    for (final entries in _entries.values) {
      for (final entry in entries) {
        if (entry.imageUrls.contains(imageUrl) ||
            entry.extractImagesFromMarkdown().contains(imageUrl)) {
          return entry;
        }
      }
    }
    return null;
  }

  int getAllEntriesCount() {
    return _entries.values.fold(0, (sum, entries) => sum + entries.length);
  }

  int getTodayEntriesCount() {
    final today = DateTime.now();
    final key = DateTime(today.year, today.month, today.day);
    return _entries[key]?.length ?? 0;
  }

  int getLast7DaysEntriesCount() {
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));
    int count = 0;

    var current = DateTime(
      sevenDaysAgo.year,
      sevenDaysAgo.month,
      sevenDaysAgo.day,
    );
    final end = DateTime(now.year, now.month, now.day);

    while (current.isBefore(end) || current.isAtSameMomentAs(end)) {
      count += _entries[current]?.length ?? 0;
      current = current.add(const Duration(days: 1));
    }

    return count;
  }
}
