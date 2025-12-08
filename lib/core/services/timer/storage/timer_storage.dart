/// 统一计时器存储管理
///
/// 负责管理计时器状态的持久化，包括：
/// - 活动计时器状态保存
/// - 应用启动时状态恢复
/// - 历史计时记录存储
/// - 版本兼容与迁移
library;

import 'dart:convert';

import 'package:Memento/core/app_initializer.dart';
import 'package:flutter/material.dart';

import 'package:Memento/core/services/timer/models/timer_state.dart';

/// 统一计时器存储管理器
class TimerStorage {
  static const String _activeTimersPath = 'core/timers/active_timers.json';
  static const String _timerHistoryPath = 'core/timers/timer_history.json';
  static const String _timerStatsPath = 'core/timers/timer_stats.json';

  /// 存储版本号（用于数据迁移）
  static const int _storageVersion = 1;

  /// 保存活动计时器状态
  ///
  /// [timers] 正在运行的计时器列表
  static Future<void> saveActiveTimers(List<TimerState> timers) async {
    try {
      final data = {
        'version': _storageVersion,
        'timestamp': DateTime.now().toIso8601String(),
        'timers': timers.map((timer) => timer.toJson()).toList(),
      };

      await globalStorage.write(_activeTimersPath, data);
    } catch (e) {
      print('Error saving active timers: $e');
      rethrow;
    }
  }

  /// 加载活动计时器状态
  ///
  /// 返回 [Map<String, TimerState>] 其中 key 是计时器ID
  static Future<Map<String, TimerState>> loadActiveTimers() async {
    try {
      final data = await globalStorage.read(_activeTimersPath);

      if (data == null || data['timers'] == null) {
        return {};
      }

      final version = data['version'] as int? ?? 0;

      // 数据迁移检查
      if (version != _storageVersion) {
        print(
          'Timer storage version mismatch. Current: $_storageVersion, Saved: $version',
        );
        await _migrateStorage(version);
        return loadActiveTimers(); // 递归调用重新加载
      }

      final timersJson = data['timers'] as List;
      final Map<String, TimerState> timers = {};

      for (final timerJson in timersJson) {
        try {
          final timer = TimerState.fromJson(timerJson);
          timers[timer.id] = timer;
        } catch (e) {
          print('Error parsing timer: $e');
          // 跳过错误的计时器数据
        }
      }

      return timers;
    } catch (e) {
      print('Error loading active timers: $e');
      return {};
    }
  }

  /// 加载单个活动计时器
  static Future<TimerState?> loadTimer(String timerId) async {
    final timers = await loadActiveTimers();
    return timers[timerId];
  }

  /// 删除活动计时器
  static Future<void> removeActiveTimer(String timerId) async {
    try {
      final timers = await loadActiveTimers();
      timers.remove(timerId);

      // 如果没有活动计时器，删除整个文件
      if (timers.isEmpty) {
        await globalStorage.delete(_activeTimersPath);
      } else {
        await saveActiveTimers(timers.values.toList());
      }
    } catch (e) {
      print('Error removing active timer: $e');
      rethrow;
    }
  }

  /// 清空所有活动计时器
  static Future<void> clearActiveTimers() async {
    try {
      await globalStorage.delete(_activeTimersPath);
    } catch (e) {
      print('Error clearing active timers: $e');
      rethrow;
    }
  }

  /// 保存计时器历史记录
  ///
  /// [timerId] 计时器ID
  /// [duration] 运行时长
  /// [completed] 是否完成
  static Future<void> saveTimerHistory({
    required String timerId,
    required String timerName,
    required String pluginId,
    required Duration duration,
    required bool completed,
    Color? color,
    IconData? icon,
  }) async {
    try {
      final data = await globalStorage.read(_timerHistoryPath);
      final List<dynamic> history = data?['history'] ?? [];

      history.insert(0, {
        'timerId': timerId,
        'timerName': timerName,
        'pluginId': pluginId,
        'duration': duration.inMilliseconds,
        'completed': completed,
        'color': color?.value,
        'icon': icon?.codePoint,
        'timestamp': DateTime.now().toIso8601String(),
      });

      // 保留最近1000条记录
      if (history.length > 1000) {
        history.removeRange(1000, history.length);
      }

      await globalStorage.write(_timerHistoryPath, {
        'version': _storageVersion,
        'history': history,
      });
    } catch (e) {
      print('Error saving timer history: $e');
      rethrow;
    }
  }

  /// 加载计时器历史记录
  static Future<List<Map<String, dynamic>>> loadTimerHistory({
    int? limit,
  }) async {
    try {
      final data = await globalStorage.read(_timerHistoryPath);

      if (data == null || data['history'] == null) {
        return [];
      }

      final List<dynamic> history = data['history'];
      final int actualLimit = limit ?? history.length;

      return history
          .take(actualLimit)
          .map((item) => item as Map<String, dynamic>)
          .toList();
    } catch (e) {
      print('Error loading timer history: $e');
      return [];
    }
  }

  /// 加载指定计时器的历史记录
  static Future<List<Map<String, dynamic>>> loadTimerHistoryById(
    String timerId, {
    int? limit,
  }) async {
    final allHistory = await loadTimerHistory();
    return allHistory
        .where((item) => item['timerId'] == timerId)
        .take(limit ?? 50)
        .toList();
  }

  /// 保存计时器统计数据
  static Future<void> saveTimerStats({
    required String timerId,
    required String timerName,
    required String pluginId,
    required Duration totalDuration,
    required int startCount,
    required int completeCount,
  }) async {
    try {
      final data = await globalStorage.read(_timerStatsPath);
      final Map<String, dynamic> stats = data?['stats'] ?? {};

      final existing =
          stats[timerId] as Map<String, dynamic>? ??
          {
            'timerName': timerName,
            'pluginId': pluginId,
            'totalDuration': 0,
            'startCount': 0,
            'completeCount': 0,
          };

      // 累加统计数据
      existing['timerName'] = timerName;
      existing['pluginId'] = pluginId;
      existing['totalDuration'] =
          (existing['totalDuration'] as int) + totalDuration.inMilliseconds;
      existing['startCount'] = (existing['startCount'] as int) + startCount;
      existing['completeCount'] =
          (existing['completeCount'] as int) + completeCount;

      stats[timerId] = existing;

      await globalStorage.write(_timerStatsPath, {
        'version': _storageVersion,
        'stats': stats,
      });
    } catch (e) {
      print('Error saving timer stats: $e');
      rethrow;
    }
  }

  /// 加载计时器统计数据
  static Future<Map<String, Map<String, dynamic>>> loadTimerStats() async {
    try {
      final data = await globalStorage.read(_timerStatsPath);

      if (data == null || data['stats'] == null) {
        return {};
      }

      return Map<String, Map<String, dynamic>>.from(data['stats']);
    } catch (e) {
      print('Error loading timer stats: $e');
      return {};
    }
  }

  /// 获取指定计时器的统计数据
  static Future<Map<String, dynamic>?> getTimerStats(String timerId) async {
    final stats = await loadTimerStats();
    return stats[timerId];
  }

  /// 清除所有存储数据
  static Future<void> clearAll() async {
    try {
      await globalStorage.delete(_activeTimersPath);
      await globalStorage.delete(_timerHistoryPath);
      await globalStorage.delete(_timerStatsPath);
    } catch (e) {
      print('Error clearing timer storage: $e');
      rethrow;
    }
  }

  /// 获取存储使用情况
  static Future<Map<String, dynamic>> getStorageInfo() async {
    try {
      final activeTimers = await loadActiveTimers();
      final history = await loadTimerHistory();
      final stats = await loadTimerStats();

      return {
        'activeTimers': activeTimers.length,
        'historyRecords': history.length,
        'statsEntries': stats.length,
        'storageVersion': _storageVersion,
      };
    } catch (e) {
      print('Error getting storage info: $e');
      return {
        'activeTimers': 0,
        'historyRecords': 0,
        'statsEntries': 0,
        'storageVersion': _storageVersion,
      };
    }
  }

  /// 数据迁移
  static Future<void> _migrateStorage(int fromVersion) async {
    print(
      'Migrating timer storage from version $fromVersion to $_storageVersion',
    );

    // 这里可以添加不同版本之间的迁移逻辑
    // 当前版本是1，暂时不需要迁移
    if (fromVersion < _storageVersion) {
      // 执行迁移操作
      await _performMigration(fromVersion);
    }
  }

  /// 执行数据迁移
  static Future<void> _performMigration(int fromVersion) async {
    // 目前版本是1，无需实际迁移
    // 保留接口以便将来扩展

    print('Migration completed');
  }

  /// 导出数据为 JSON 字符串
  static Future<String> exportData() async {
    try {
      final activeTimers = await loadActiveTimers();
      final history = await loadTimerHistory();
      final stats = await loadTimerStats();

      final exportData = {
        'version': _storageVersion,
        'exportTime': DateTime.now().toIso8601String(),
        'activeTimers': activeTimers.values.map((t) => t.toJson()).toList(),
        'history': history,
        'stats': stats,
      };

      return jsonEncode(exportData);
    } catch (e) {
      print('Error exporting timer data: $e');
      rethrow;
    }
  }

  /// 导入数据从 JSON 字符串
  static Future<void> importData(String jsonData) async {
    try {
      final data = jsonDecode(jsonData) as Map<String, dynamic>;

      final version = data['version'] as int? ?? 0;
      if (version > _storageVersion) {
        throw Exception('Cannot import data from newer version ($version)');
      }

      // 导入活动计时器
      if (data['activeTimers'] != null) {
        final activeTimersJson = data['activeTimers'] as List;
        final List<TimerState> activeTimers = [];

        for (final timerJson in activeTimersJson) {
          try {
            final timer = TimerState.fromJson(timerJson);
            activeTimers.add(timer);
          } catch (e) {
            print('Skipping invalid timer during import: $e');
          }
        }

        await saveActiveTimers(activeTimers);
      }

      // 导入历史记录
      if (data['history'] != null) {
        await globalStorage.write(_timerHistoryPath, {
          'version': _storageVersion,
          'history': data['history'],
        });
      }

      // 导入统计数据
      if (data['stats'] != null) {
        await globalStorage.write(_timerStatsPath, {
          'version': _storageVersion,
          'stats': data['stats'],
        });
      }

      print('Timer data imported successfully');
    } catch (e) {
      print('Error importing timer data: $e');
      rethrow;
    }
  }
}
