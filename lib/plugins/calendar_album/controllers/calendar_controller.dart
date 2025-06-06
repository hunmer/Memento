import 'package:Memento/core/plugin_manager.dart';
import 'package:flutter/material.dart';
import '../models/calendar_entry.dart';
import 'dart:convert';
import '../../../core/storage/storage_manager.dart';

class CalendarController extends ChangeNotifier {
  final Map<DateTime, List<CalendarEntry>> _entries = {};
  DateTime _selectedDate = DateTime.now();
  DateTime _currentMonth = DateTime.now();
  DateTime _rangeStart = DateTime.now();
  DateTime _rangeEnd = DateTime.now();
  final List<DateTime> _displayMonths = [];
  final String _storageKey = 'calendar_entries';

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
    final String? data = await _storage.getString(_storageKey);
    if (data != null) {
      final Map<String, dynamic> jsonData = json.decode(data);
      jsonData.forEach((key, value) {
        final date = DateTime.parse(key);
        final entries =
            (value as List)
                .map((e) => CalendarEntry.fromJson(e as Map<String, dynamic>))
                .toList();
        _entries[date] = entries;
      });
      notifyListeners();
    }
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
    }
  }

  List<String> getAllTags() {
    final Set<String> tags = {};
    _entries.values.forEach((entries) {
      entries.forEach((entry) {
        tags.addAll(entry.tags);
      });
    });
    return tags.toList()..sort();
  }

  List<CalendarEntry> getEntriesByTag(String tag) {
    final List<CalendarEntry> taggedEntries = [];
    _entries.values.forEach((entries) {
      taggedEntries.addAll(entries.where((entry) => entry.tags.contains(tag)));
    });
    return taggedEntries..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  List<CalendarEntry> getEntriesByTags(List<String> tags) {
    if (tags.isEmpty) return [];

    final List<CalendarEntry> taggedEntries = [];
    _entries.values.forEach((entries) {
      taggedEntries.addAll(
        entries.where((entry) => tags.every((tag) => entry.tags.contains(tag))),
      );
    });
    return taggedEntries..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  List<String> getAllImages() {
    final Set<String> images = {};
    _entries.values.forEach((entries) {
      entries.forEach((entry) {
        images.addAll(entry.imageUrls);
        images.addAll(entry.extractImagesFromMarkdown());
      });
    });
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
}
