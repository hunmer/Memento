import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import '../../../core/storage/storage_manager.dart';
import '../models/diary_entry.dart';

class DiaryUtils {
  static const String _pluginDir = 'diary';

  static String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  static DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  static String _getEntryPath(DateTime date) {
    return path.join(_pluginDir, '${_formatDate(date)}.json');
  }

  static Future<Map<DateTime, DiaryEntry>> loadDiaryEntries(
    StorageManager storage,
  ) async {
    try {
      final Map<DateTime, DiaryEntry> entries = {};

      // 使用索引文件来管理日记条目
      final indexPath = path.join(_pluginDir, 'diary_index.json');

      // 如果索引文件不存在，创建一个空的索引
      if (!await storage.fileExists(indexPath)) {
        await storage.writeJson(indexPath, {});
        return entries;
      }

      // 读取索引文件
      final Map<String, dynamic> index = await storage.readJson(indexPath);

      // 遍历索引中的条目
      for (final dateStr in index.keys) {
        if (dateStr == 'diary_index.json') continue;

        final filePath = path.join(_pluginDir, '$dateStr.json');
        if (await storage.fileExists(filePath)) {
          try {
            final jsonMap = await storage.readJson(filePath);
            final entry = DiaryEntry.fromJson(jsonMap);
            final normalizedDate = _normalizeDate(entry.date);
            entries[normalizedDate] = entry;
            debugPrint(
              'Loaded entry for ${_formatDate(normalizedDate)}: ${entry.content.length} chars',
            );
          } catch (e) {
            debugPrint('Error loading entry $dateStr: $e');
          }
        }
      }

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
      final dateStr = _formatDate(normalizedDate);
      final now = DateTime.now();
      final entryPath = _getEntryPath(normalizedDate);

      DiaryEntry newEntry;

      // 检查是否存在现有条目
      if (await storage.fileExists(entryPath)) {
        // 更新现有条目
        final existingData = await storage.readJson(entryPath);
        final existingEntry = DiaryEntry.fromJson(existingData);

        newEntry = existingEntry.copyWith(
          content: content,
          mood: mood,
          updatedAt: now,
        );
      } else {
        // 创建新条目
        newEntry = DiaryEntry(
          date: normalizedDate,
          content: content,
          mood: mood,
          createdAt: now,
          updatedAt: now,
        );
      }

      // 确保目录存在
      await storage.createDirectory(_pluginDir);

      // 保存日记条目
      await storage.writeJson(entryPath, newEntry.toJson());

      // 更新索引文件
      await _updateDiaryIndex(storage, dateStr);

      debugPrint('Saved diary entry for $dateStr');
    } catch (e) {
      debugPrint('Error saving diary entry: $e');
      throw Exception('Failed to save diary entry: $e');
    }
  }

  /// 更新日记索引文件
  static Future<void> _updateDiaryIndex(
    StorageManager storage,
    String dateStr,
  ) async {
    final indexPath = path.join(_pluginDir, 'diary_index.json');

    try {
      // 读取现有索引或创建新索引
      Map<String, dynamic> index = {};
      if (await storage.fileExists(indexPath)) {
        index = await storage.readJson(indexPath);
      }

      // 更新索引
      index[dateStr] = {'lastUpdated': DateTime.now().toIso8601String()};

      // 保存索引
      await storage.writeJson(indexPath, index);
    } catch (e) {
      debugPrint('Error updating diary index: $e');
      // 索引更新失败不应影响主要操作
    }
  }

  /// 加载特定日期的日记条目
  static Future<DiaryEntry?> loadDiaryEntry(
    StorageManager storage,
    DateTime date,
  ) async {
    try {
      final normalizedDate = _normalizeDate(date);
      final entryPath = _getEntryPath(normalizedDate);

      if (!await storage.fileExists(entryPath)) {
        return null; // 该日期没有日记条目
      }

      final jsonData = await storage.readJson(entryPath);
      return DiaryEntry.fromJson(jsonData);
    } catch (e) {
      debugPrint('Error loading diary entry: $e');
      return null;
    }
  }

  /// 删除特定日期的日记条目
  static Future<bool> deleteDiaryEntry(
    StorageManager storage,
    DateTime date,
  ) async {
    try {
      final normalizedDate = _normalizeDate(date);
      final dateStr = _formatDate(normalizedDate);
      final entryPath = _getEntryPath(normalizedDate);

      if (!await storage.fileExists(entryPath)) {
        return false; // 文件不存在，无需删除
      }

      // 获取条目内容长度
      final entryContent = await storage.readJson(entryPath);
      final contentLength = (entryContent['content'] as String).length;

      // 删除日记文件
      await storage.deleteFile(entryPath);

      // 从索引中移除并更新总字数
      await _removeFromDiaryIndex(storage, dateStr, contentLength);

      debugPrint('Deleted diary entry for $dateStr');
      return true;
    } catch (e) {
      debugPrint('Error deleting diary entry: $e');
      return false;
    }
  }

  /// 从索引中移除日记条目并更新总字数
  static Future<void> _removeFromDiaryIndex(
    StorageManager storage,
    String dateStr,
    int contentLength,
  ) async {
    final indexPath = path.join(_pluginDir, 'diary_index.json');

    try {
      // 读取现有索引
      if (await storage.fileExists(indexPath)) {
        Map<String, dynamic> index = await storage.readJson(indexPath);

        // 从索引中移除条目
        index.remove(dateStr);

        // 更新总字数
        int totalCharCount = index['totalCharCount'] as int? ?? 0;
        totalCharCount -= contentLength;
        index['totalCharCount'] = totalCharCount > 0 ? totalCharCount : 0;

        // 保存更新后的索引
        await storage.writeJson(indexPath, index);
      }
    } catch (e) {
      debugPrint('Error removing from diary index: $e');
      // 索引更新失败不应影响主要操作
    }
  }

  /// 检查特定日期是否有日记条目
  static Future<bool> hasEntryForDate(
    StorageManager storage,
    DateTime date,
  ) async {
    final normalizedDate = _normalizeDate(date);
    final entryPath = _getEntryPath(normalizedDate);
    return await storage.fileExists(entryPath);
  }

  /// 获取所有日记的总字数
  static Future<int> getTotalCharCount(StorageManager storage) async {
    final indexPath = path.join(_pluginDir, 'diary_index.json');

    try {
      if (!await storage.fileExists(indexPath)) {
        return 0;
      }

      final index = await storage.readJson(indexPath);
      return index['totalCharCount'] as int? ?? 0;
    } catch (e) {
      debugPrint('Error getting total char count: $e');
      return 0;
    }
  }

  /// 获取特定日期日记的字数
  static Future<int> getEntryCharCount(
    StorageManager storage,
    DateTime date,
  ) async {
    final dateStr = _formatDate(_normalizeDate(date));
    final indexPath = path.join(_pluginDir, 'diary_index.json');

    try {
      if (!await storage.fileExists(indexPath)) {
        return 0;
      }

      final index = await storage.readJson(indexPath);
      final entry = index[dateStr] as Map<String, dynamic>?;
      return entry?['contentLength'] as int? ?? 0;
    } catch (e) {
      debugPrint('Error getting entry char count: $e');
      return 0;
    }
  }

  /// 获取日记统计信息
  static Future<Map<String, dynamic>> getDiaryStats(
    StorageManager storage,
  ) async {
    final indexPath = path.join(_pluginDir, 'diary_index.json');

    try {
      if (!await storage.fileExists(indexPath)) {
        return {'totalCharCount': 0, 'entryCount': 0, 'averageCharCount': 0};
      }

      final index = await storage.readJson(indexPath);
      final entryCount =
          index.keys.where((key) => key != 'totalCharCount').length;
      final totalCharCount = index['totalCharCount'] as int? ?? 0;

      return {
        'totalCharCount': totalCharCount,
        'entryCount': entryCount,
        'averageCharCount':
            entryCount > 0 ? (totalCharCount / entryCount).round() : 0,
      };
    } catch (e) {
      debugPrint('Error getting diary stats: $e');
      return {'totalCharCount': 0, 'entryCount': 0, 'averageCharCount': 0};
    }
  }
}
