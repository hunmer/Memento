import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import '../../../core/storage/storage_manager.dart';
import '../models/diary_entry.dart';

class DiaryUtils {
  static const String _pluginDir = 'diary';
  static const String _entriesFile = 'entries.json';

  static String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  static DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  static Future<Map<DateTime, DiaryEntry>> loadDiaryEntries(
    StorageManager storage,
  ) async {
    try {
      final entriesPath = path.join(_pluginDir, _entriesFile);
      final exists = await storage.fileExists(entriesPath);

      if (!exists) {
        return {};
      }

      final jsonString = await storage.readFile(entriesPath);
      final Map<String, dynamic> jsonMap = json.decode(jsonString);

      final Map<DateTime, DiaryEntry> entries = {};
      jsonMap.forEach((key, value) {
        try {
          final entry = DiaryEntry.fromJson(value);
          final normalizedDate = _normalizeDate(entry.date);
          entries[normalizedDate] = entry;
          debugPrint(
            'Loaded entry for ${_formatDate(normalizedDate)}: ${entry.content.length} chars',
          );
        } catch (e) {
          debugPrint('Error parsing entry $key: $e');
        }
      });

      return entries;
    } catch (e) {
      debugPrint('Error loading diary entries: $e');
      return {};
    }
  }

  static Future<void> saveDiaryEntry(
    StorageManager storage,
    DateTime date,
    String content, {
    String? mood,
  }) async {
    try {
      final normalizedDate = _normalizeDate(date);
      final entries = await loadDiaryEntries(storage);
      final now = DateTime.now();
      final existingEntry = entries[normalizedDate];

      final newEntry =
          existingEntry?.copyWith(
            content: content,
            mood: mood,
            updatedAt: now,
          ) ??
          DiaryEntry(
            date: normalizedDate,
            content: content,
            mood: mood,
            createdAt: now,
            updatedAt: now,
          );

      entries[normalizedDate] = newEntry;

      final entriesPath = path.join(_pluginDir, _entriesFile);
      final jsonEntries = entries.map(
        (date, entry) => MapEntry(_formatDate(date), entry.toJson()),
      );

      await storage.writeFile(entriesPath, json.encode(jsonEntries));
    } catch (e) {
      debugPrint('Error saving diary entry: $e');
    }
  }
}
