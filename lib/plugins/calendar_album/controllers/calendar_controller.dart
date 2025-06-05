import 'package:flutter/material.dart';
import '../models/calendar_entry.dart';
import 'dart:convert';
import '../../../core/storage/storage_manager.dart';

class CalendarController extends ChangeNotifier {
  final StorageManager _storage;
  final Map<DateTime, List<CalendarEntry>> _entries = {};
  bool _isExpanded = false;
  DateTime _selectedDate = DateTime.now();
  final String _storageKey = 'calendar_entries';

  CalendarController(this._storage) {
    _loadEntries();
  }

  bool get isExpanded => _isExpanded;
  DateTime get selectedDate => _selectedDate;
  Map<DateTime, List<CalendarEntry>> get entries => _entries;

  void toggleExpanded() {
    _isExpanded = !_isExpanded;
    notifyListeners();
  }

  void selectDate(DateTime date) {
    _selectedDate = DateTime(date.year, date.month, date.day);
    if (_isExpanded) {
      _isExpanded = false;
    }
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
        final entries = (value as List)
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
}