import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:Memento/core/storage/storage_manager.dart';

/// 日志级别
enum LogLevel {
  debug,
  info,
  warning,
  error,
}

/// 日志条目
class LogEntry {
  final DateTime timestamp;
  final LogLevel level;
  final String message;
  final String? stackTrace;
  /// 重复次数（>=1），1 表示首次出现，>1 表示重复次数
  final int count;

  LogEntry({
    required this.timestamp,
    required this.level,
    required this.message,
    this.stackTrace,
    this.count = 1,
  });

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'level': level.name,
      'message': message,
      'stackTrace': stackTrace,
      'count': count,
    };
  }

  factory LogEntry.fromJson(Map<String, dynamic> json) {
    return LogEntry(
      timestamp: DateTime.parse(json['timestamp'] as String),
      level: LogLevel.values.firstWhere(
        (e) => e.name == json['level'],
        orElse: () => LogLevel.info,
      ),
      message: json['message'] as String,
      stackTrace: json['stackTrace'] as String?,
      count: json['count'] as int? ?? 1,
    );
  }

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.write('[${timestamp.toIso8601String()}] ');
    buffer.write('[${level.name.toUpperCase()}] ');
    if (count > 1) {
      buffer.write('[$count] ');
    }
    buffer.write(message);
    if (stackTrace != null) {
      buffer.write('\n$stackTrace');
    }
    return buffer.toString();
  }
}

/// 日志服务
class LogService {
  // 单例模式
  LogService._internal();
  static final LogService _instance = LogService._internal();
  static LogService get instance => _instance;

  // 配置
  static const String _logEnabledKey = 'log_enabled';
  static const String _logDirKey = 'logs';
  static const int _maxLogFiles = 10;

  // 状态
  bool _isEnabled = false;
  bool _isInitialized = false;
  String? _currentLogFilePath;
  final List<LogEntry> _currentSessionLogs = [];
  final StreamController<LogEntry> _logController = StreamController<LogEntry>.broadcast();

  // 存储管理器引用
  StorageManager? _storage;

  // Getters
  bool get isEnabled => _isEnabled;
  bool get isInitialized => _isInitialized;
  List<LogEntry> get currentSessionLogs => List.unmodifiable(_currentSessionLogs);
  Stream<LogEntry> get logStream => _logController.stream;

  /// 初始化日志服务
  Future<void> initialize(StorageManager storage) async {
    if (_isInitialized) return;

    _storage = storage;

    // 读取配置
    _isEnabled = await storage.read(_logEnabledKey, false) as bool;

    if (!_isEnabled) {
      _isInitialized = true;
      return;
    }

    try {
      // 创建日志目录
      final logDir = await _getLogDirectory();
      if (logDir == null) {
        print('[LogService] 无法获取日志目录');
        _isInitialized = true;
        return;
      }

      if (!await logDir.exists()) {
        await logDir.create(recursive: true);
      }

      // 清理旧日志文件
      await _cleanOldLogs(logDir);

      // 创建新的日志文件
      await _createNewLogFile(logDir);

      _isInitialized = true;
      info('日志服务已启动');
    } catch (e, stack) {
      print('[LogService] 初始化失败: $e\n$stack');
      _isInitialized = true;
    }
  }

  /// 启用或禁用日志
  Future<void> setEnabled(bool enabled) async {
    if (_storage == null) {
      throw StateError('日志服务未初始化');
    }

    await _storage!.write(_logEnabledKey, enabled);

    // 如果正在启用，重新初始化
    if (enabled && !_isEnabled) {
      _isEnabled = true;
      await _restart();
    } else if (!enabled && _isEnabled) {
      _isEnabled = false;
      _currentLogFilePath = null;
      _currentSessionLogs.clear();
    }
  }

  /// 记录调试日志
  void debug(String message) {
    _log(LogLevel.debug, message);
  }

  /// 记录信息日志
  void info(String message) {
    _log(LogLevel.info, message);
  }

  /// 记录警告日志
  void warning(String message) {
    _log(LogLevel.warning, message);
  }

  /// 记录错误日志
  void error(String message, {Object? error, StackTrace? stackTrace}) {
    final buffer = StringBuffer(message);
    if (error != null) {
      buffer.write('\n错误: $error');
    }
    if (stackTrace != null) {
      buffer.write('\n堆栈: $stackTrace');
    }
    _log(LogLevel.error, buffer.toString(), stackTrace: stackTrace?.toString());
  }

  /// 内部日志记录方法
  void _log(LogLevel level, String message, {String? stackTrace}) {
    if (!_isEnabled || !_isInitialized) return;

    // 检查最后一条日志是否与当前相同（忽略时间戳和堆栈信息）
    final lastEntry = _currentSessionLogs.isNotEmpty ? _currentSessionLogs.last : null;
    final isDuplicate = lastEntry != null &&
        lastEntry.level == level &&
        lastEntry.message == message &&
        lastEntry.stackTrace == stackTrace;

    LogEntry entry;

    if (isDuplicate) {
      // 创建一个新的 LogEntry，计数 +1
      entry = LogEntry(
        timestamp: lastEntry.timestamp, // 保持首次出现的时间
        level: level,
        message: message,
        stackTrace: stackTrace,
        count: lastEntry.count + 1,
      );
      // 替换最后一条日志
      _currentSessionLogs[_currentSessionLogs.length - 1] = entry;
    } else {
      // 创建新日志
      entry = LogEntry(
        timestamp: DateTime.now(),
        level: level,
        message: message,
        stackTrace: stackTrace,
      );
      // 添加到内存
      _currentSessionLogs.add(entry);
    }

    // 发布到流
    _logController.add(entry);

    // 直接输出到控制台（不使用 debugPrint 避免死循环）
    print(entry.toString());

    // 异步写入文件
    _writeToFile(entry);
  }

  /// 获取所有日志文件
  Future<List<File>> getLogFiles() async {
    final logDir = await _getLogDirectory();
    if (logDir == null || !await logDir.exists()) {
      return [];
    }

    final entities = await logDir.list().toList();
    final files = entities.whereType<File>().toList();
    files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
    return files;
  }

  /// 读取指定日志文件内容
  Future<String> readLogFile(File file) async {
    try {
      return await file.readAsString();
    } catch (e) {
      return '读取失败: $e';
    }
  }

  /// 清空当前会话日志
  void clearCurrentSessionLogs() {
    _currentSessionLogs.clear();
  }

  /// 删除所有日志文件
  Future<void> deleteAllLogs() async {
    final logDir = await _getLogDirectory();
    if (logDir == null || !await logDir.exists()) {
      return;
    }

    final entities = await logDir.list().toList();
    for (final entity in entities) {
      if (entity is File) {
        try {
          await entity.delete();
        } catch (e) {
          print('[LogService] 删除日志文件失败: ${entity.path} - $e');
        }
      }
    }

    _currentLogFilePath = null;
    _currentSessionLogs.clear();

    // 如果启用日志，创建新文件
    if (_isEnabled) {
      await _createNewLogFile(logDir);
    }
  }

  /// 释放资源
  Future<void> dispose() async {
    await _logController.close();
  }

  // 私有方法

  Future<Directory?> _getLogDirectory() async {
    if (_storage == null) return null;

    try {
      // 尝试从应用数据目录获取
      final appDir = await _storage!.getApplicationDataDirectory();
      return Directory(p.join(appDir.path, _logDirKey));
    } catch (e) {
      print('[LogService] 获取日志目录失败: $e');
    }

    return null;
  }

  Future<void> _cleanOldLogs(Directory logDir) async {
    try {
      final entities = await logDir.list().toList();
      final files = entities.whereType<File>().toList();

      // 按修改时间排序（最新的在前）
      files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));

      // 删除超出限制的旧文件
      if (files.length > _maxLogFiles) {
        for (final file in files.skip(_maxLogFiles)) {
          try {
            await file.delete();
            print('[LogService] 删除旧日志: ${file.path}');
          } catch (e) {
            print('[LogService] 删除日志文件失败: ${file.path} - $e');
          }
        }
      }
    } catch (e) {
      print('[LogService] 清理旧日志失败: $e');
    }
  }

  Future<void> _createNewLogFile(Directory logDir) async {
    try {
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').replaceAll('.', '-');
      final fileName = 'log_$timestamp.txt';
      final file = File(p.join(logDir.path, fileName));

      if (!await file.exists()) {
        await file.create(recursive: true);
      }

      _currentLogFilePath = file.path;
      _currentSessionLogs.clear();

      // 写入文件头
      final header = 'Memento 日志文件\n开始时间: ${DateTime.now().toIso8601String()}\n${'=' * 50}\n';
      await file.writeAsString(header);

      print('[LogService] 创建新日志文件: ${file.path}');
    } catch (e, stack) {
      print('[LogService] 创建日志文件失败: $e\n$stack');
    }
  }

  Future<void> _writeToFile(LogEntry entry) async {
    if (_currentLogFilePath == null) return;

    try {
      final file = File(_currentLogFilePath!);
      if (await file.exists()) {
        await file.writeAsString('${entry.toString()}\n', mode: FileMode.append, flush: true);
      }
    } catch (e) {
      print('[LogService] 写入日志失败: $e');
    }
  }

  Future<void> _restart() async {
    if (_storage == null) return;

    final logDir = await _getLogDirectory();
    if (logDir == null) return;

    if (!await logDir.exists()) {
      await logDir.create(recursive: true);
    }

    await _cleanOldLogs(logDir);
    await _createNewLogFile(logDir);
  }
}
