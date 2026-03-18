import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;

import 'package:Memento/core/storage/storage_manager.dart';
import 'package:Memento/core/services/sync_client_service.dart';
import 'package:Memento/core/services/sync_record_service.dart';
import 'package:Memento/core/services/sync_websocket_service.dart';
import 'package:Memento/core/services/encryption_service.dart';
import 'package:Memento/core/route/route_refresh_manager.dart';
import 'package:Memento/screens/settings_screen/models/server_sync_config.dart';

/// 文件监听同步服务
///
/// 负责：
/// - 监听指定目录的文件变化
/// - 当文件发生变化时立即加入同步队列
/// - 按顺序处理同步队列
/// - 记录文件修改时间以检测变化
class FileWatchSyncService {
  static final FileWatchSyncService _instance = FileWatchSyncService._internal();
  factory FileWatchSyncService() => _instance;
  FileWatchSyncService._internal();

  // 调试日志标签
  static const String _tag = 'FileWatchSync';

  // 文件监听器列表
  final Map<String, StreamSubscription<FileSystemEvent>> _watchers = {};

  // 同步队列（有序列表）
  final List<SyncTask> _syncQueue = [];

  // 当前正在处理的同步任务
  SyncTask? _currentTask;

  // 同步服务
  SyncClientService? _syncService;

  // 同步记录服务
  SyncRecordService? _recordService;

  // WebSocket 服务
  SyncWebSocketService? _wsService;

  // 配置
  ServerSyncConfig? _config;

  // 是否已初始化
  bool _isInitialized = false;

  // 是否正在同步
  bool _isSyncing = false;

  // 文件修改时间记录（用于检测真正的修改）
  final Map<String, DateTime> _fileModifyTimes = {};

  // 文件内容 MD5 缓存（用于检测内容是否真正变化）
  final Map<String, String> _fileMd5Cache = {};

  // 同步防抖间隔（毫秒）- 同一文件在短时间内多次修改，只同步最后一次
  static const int _debounceMs = 500;

  // 防抖定时器映射
  final Map<String, Timer> _debounceTimers = {};

  /// 初始化服务
  Future<void> initialize() async {
    if (_isInitialized) return;
    if (kIsWeb) return; // Web 平台不支持文件监听

    try {
      _config = await ServerSyncConfig.load();
      if (_config == null || !_config!.isLoggedIn) return;

      // 检查是否启用了文件修改时同步
      if (!_config!.syncOnChange) return;

      // 初始化同步服务
      final storage = StorageManager();
      final encryption = EncryptionService();
      await encryption.initializeFromPassword(
        _config!.password,
        _config!.salt!,
      );

      _syncService = SyncClientService(
        serverUrl: _config!.server,
        storage: storage,
        encryption: encryption,
      );
      _syncService!.initialize(
        token: _config!.token!,
        userId: _config!.userId!,
        deviceId: _config!.deviceId,
      );

      // 初始化记录服务
      _recordService = SyncRecordService();
      await _recordService!.initialize(storage);

      // 初始化 WebSocket 服务
      _initWebSocket();

      // 开始监听
      await _startWatching();

      _isInitialized = true;

      // 启动时后台同步（不阻塞主线程）
      if (_config!.syncOnStart) {
        _performStartupSync();
      }
    } catch (e, stack) {
      debugPrint('$_tag: 初始化失败 - $e');
      debugPrint('$_tag: $stack');
    }
  }

  /// 重新加载配置并更新监听状态
  Future<void> reload() async {
    await dispose();
    _isInitialized = false;
    await initialize();
  }

  /// 初始化 WebSocket 连接
  void _initWebSocket() {
    if (_config == null || !_config!.isLoggedIn) return;
    if (_syncService == null || _recordService == null) return;

    _wsService = SyncWebSocketService();
    _wsService!.configure(
      syncClientService: _syncService!,
      recordService: _recordService!,
      routeRefreshManager: RouteRefreshManager(),
    );

    _wsService!.connect(
      serverUrl: _config!.server,
      token: _config!.token!,
      deviceId: _config!.deviceId,
    );

    _log('WebSocket 连接已初始化');
  }

  /// 输出日志
  void _log(String message) {
    debugPrint('$_tag: $message');
  }

  /// 启动时后台同步（异步执行，不阻塞主线程）
  void _performStartupSync() {
    Future.delayed(const Duration(seconds: 2), () async {
      if (_syncService == null || !_syncService!.isLoggedIn) return;

      try {
        final results = await _syncService!.fullSync();

        int pushCount = 0;
        int pullCount = 0;
        int errorCount = 0;

        for (final result in results) {
          switch (result.type) {
            case SyncResultType.success:
              pushCount++;
              break;
            case SyncResultType.conflictResolved:
              pullCount++;
              break;
            case SyncResultType.error:
              errorCount++;
              break;
            default:
              break;
          }
        }

        if (pushCount > 0 || pullCount > 0 || errorCount > 0) {
          _log('启动同步完成 - 推送: $pushCount, 拉取: $pullCount, 错误: $errorCount');
        }
      } catch (e) {
        debugPrint('$_tag: 启动同步失败 - $e');
      }
    });
  }

  /// 获取数据存储的基础路径
  Future<String> _getDataBasePath() async {
    final appDir = await StorageManager.getApplicationDocumentsDirectory();
    return path.join(appDir.path, 'app_data');
  }

  /// 开始监听文件变化
  Future<void> _startWatching() async {
    if (_config == null) return;

    final basePath = await _getDataBasePath();

    for (final dirName in _config!.syncDirs) {
      final dirPath = path.join(basePath, dirName);
      final directory = Directory(dirPath);

      if (await directory.exists()) {
        try {
          final watcher = directory.watch(
            events: FileSystemEvent.create |
                FileSystemEvent.modify |
                FileSystemEvent.delete |
                FileSystemEvent.move,
            recursive: true,
          );

          _watchers[dirName] = watcher.listen(
            _onFileChanged,
            onError: (e) => debugPrint('$_tag: 监听错误 [$dirName]: $e'),
          );
        } catch (e) {
          debugPrint('$_tag: 无法监听目录 $dirName: $e');
        }
      }
    }
  }

  /// 停止监听文件变化
  void _stopWatching() {
    for (final watcher in _watchers.values) {
      watcher.cancel();
    }
    _watchers.clear();
  }

  /// 需要忽略的文件名列表（避免同步循环）
  static const _ignoredFiles = {'sync_records.json'};

  /// 文件变化处理
  void _onFileChanged(FileSystemEvent event) {
    // 忽略临时文件
    if (event.path.endsWith('.tmp') ||
        event.path.endsWith('.temp') ||
        event.path.endsWith('.bak')) {
      return;
    }

    // 忽略隐藏文件（以.开头）
    final fileName = path.basename(event.path);
    if (fileName.startsWith('.')) return;

    // 忽略同步记录文件（避免无限循环）
    if (_ignoredFiles.contains(fileName)) return;

    // 对于修改事件，检查文件修改时间是否真的变化
    if (event.type == FileSystemEvent.modify) {
      _handleModifyEvent(event.path);
    } else if (event.type == FileSystemEvent.create) {
      _addToSyncQueue(event.path, 'create');
    } else if (event.type == FileSystemEvent.delete) {
      _addToSyncQueue(event.path, 'delete');
    } else if (event.type == FileSystemEvent.move) {
      _addToSyncQueue(event.path, 'move');
    }
  }

  /// 处理修改事件（带防抖）
  void _handleModifyEvent(String filePath) {
    // 取消之前的防抖定时器
    _debounceTimers[filePath]?.cancel();

    // 设置新的防抖定时器
    _debounceTimers[filePath] = Timer(
      Duration(milliseconds: _debounceMs),
      () {
        _debounceTimers.remove(filePath);
        _checkAndAddToQueue(filePath);
      },
    );
  }

  /// 检查文件修改时间并加入队列
  Future<void> _checkAndAddToQueue(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return;

      final stat = await file.stat();
      final modifiedTime = stat.modified;

      // 检查是否有记录的修改时间
      final lastModified = _fileModifyTimes[filePath];
      if (lastModified != null && !modifiedTime.isAfter(lastModified)) return;

      // 计算文件内容的 MD5，检测内容是否真正变化
      final currentMd5 = await _computeFileMd5(filePath);
      if (currentMd5 == null) return;

      final cachedMd5 = _fileMd5Cache[filePath];
      if (cachedMd5 != null && cachedMd5 == currentMd5) {
        // 内容未变化，只更新修改时间记录
        _fileModifyTimes[filePath] = modifiedTime;
        return;
      }

      // 更新记录
      _fileModifyTimes[filePath] = modifiedTime;
      _fileMd5Cache[filePath] = currentMd5;

      // 加入同步队列
      _addToSyncQueue(filePath, 'modify');
    } catch (e) {
      debugPrint('$_tag: 检查文件失败: $filePath - $e');
    }
  }

  /// 计算文件的 MD5 值
  Future<String?> _computeFileMd5(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return null;

      // 判断是否为二进制文件
      final isBinary = _isBinaryFile(filePath);

      if (isBinary) {
        // 二进制文件：直接计算字节流的 MD5
        final bytes = await file.readAsBytes();
        return md5.convert(bytes).toString();
      } else {
        // 文本文件
        final content = await file.readAsString();

        // JSON 文件：规范化后计算 MD5（与 SyncClientService 保持一致）
        if (filePath.toLowerCase().endsWith('.json')) {
          try {
            final json = jsonDecode(content) as Map<String, dynamic>;
            return _computeNormalizedJsonMd5(json);
          } catch (e) {
            // JSON 解析失败，按普通文本处理
          }
        }

        // 普通文本文件：直接计算 MD5
        return md5.convert(utf8.encode(content)).toString();
      }
    } catch (e) {
      return null;
    }
  }

  /// 计算规范化 JSON 的 MD5（递归排序所有 key）
  String _computeNormalizedJsonMd5(Map<String, dynamic> data) {
    final normalized = _normalizeJson(data);
    final jsonString = jsonEncode(normalized);
    return md5.convert(utf8.encode(jsonString)).toString();
  }

  /// 规范化 JSON（递归排序所有 key）
  Map<String, dynamic> _normalizeJson(Map<String, dynamic> data) {
    final sortedKeys = data.keys.toList()..sort();
    final result = <String, dynamic>{};

    for (final key in sortedKeys) {
      final value = data[key];
      if (value is Map<String, dynamic>) {
        result[key] = _normalizeJson(value);
      } else if (value is List) {
        result[key] = _normalizeJsonList(value);
      } else {
        result[key] = value;
      }
    }

    return result;
  }

  /// 规范化 JSON 列表
  List<dynamic> _normalizeJsonList(List<dynamic> list) {
    return list.map((item) {
      if (item is Map<String, dynamic>) {
        return _normalizeJson(item);
      } else if (item is List) {
        return _normalizeJsonList(item);
      }
      return item;
    }).toList();
  }

  /// 二进制文件扩展名列表
  static const _binaryExtensions = {
    '.png', '.jpg', '.jpeg', '.gif', '.webp', '.bmp', '.ico',
    '.mp3', '.mp4', '.wav', '.avi', '.mov', '.mkv',
    '.pdf', '.zip', '.tar', '.gz', '.7z', '.rar',
    '.doc', '.docx', '.xls', '.xlsx', '.ppt', '.pptx',
  };

  /// 判断文件是否为二进制文件
  bool _isBinaryFile(String filePath) {
    final lowerPath = filePath.toLowerCase();
    for (final ext in _binaryExtensions) {
      if (lowerPath.endsWith(ext)) return true;
    }
    return false;
  }

  /// 添加到同步队列
  void _addToSyncQueue(String filePath, String trigger) {
    // 创建同步任务
    final task = SyncTask(
      filePath: filePath,
      trigger: trigger,
      timestamp: DateTime.now(),
    );

    // 检查是否已在队列中（同一文件）
    final existingIndex = _syncQueue.indexWhere((t) => t.filePath == filePath);
    if (existingIndex >= 0) {
      // 更新现有任务（移除旧的，添加新的到末尾）
      _syncQueue.removeAt(existingIndex);
      _syncQueue.add(task);
    } else {
      // 添加新任务
      _syncQueue.add(task);
    }

    // 如果当前没有在同步，立即开始处理队列
    if (!_isSyncing) {
      _processQueue();
    }
  }

  /// 处理同步队列
  Future<void> _processQueue() async {
    if (_isSyncing) return;
    if (_syncQueue.isEmpty) return;

    if (_syncService == null || !_syncService!.isLoggedIn) {
      _syncQueue.clear();
      return;
    }

    _isSyncing = true;

    try {
      final basePath = await _getDataBasePath();

      while (_syncQueue.isNotEmpty) {
        // 从队列头部取出任务
        final task = _syncQueue.removeAt(0);
        _currentTask = task;

        // 计算相对路径
        final relativePath = task.filePath
            .substring(basePath.length)
            .replaceAll('\\', '/')
            .replaceFirst(RegExp(r'^/'), '');

        final file = File(task.filePath);

        if (await file.exists()) {
          // 文件存在，推送到服务器
          _log('推送文件: $relativePath');
          final result = await _syncService!.syncFile(relativePath);

          if (!result.isSuccess) {
            _log('同步失败: $relativePath - ${result.message}');
          }
        }

        _currentTask = null;
      }
    } catch (e, stack) {
      debugPrint('$_tag: 处理队列异常: $e');
      debugPrint('$_tag: $stack');
    } finally {
      _isSyncing = false;
      _currentTask = null;
    }
  }

  /// 手动触发全量同步
  Future<List<SyncResult>> performFullSync() async {
    if (_syncService == null || !_syncService!.isLoggedIn) {
      return [SyncResult.error('同步服务未就绪')];
    }

    _log('手动触发全量同步');
    return await _syncService!.fullSync();
  }

  /// 启用/禁用文件修改时同步
  Future<void> setSyncOnChangeEnabled(bool enabled) async {
    if (_config == null) return;

    _config!.syncOnChange = enabled;
    await _config!.save();

    if (enabled) {
      await _startWatching();
    } else {
      _stopWatching();
    }
  }

  /// 更新同步目录列表
  Future<void> updateSyncDirs(List<String> dirs) async {
    if (_config == null) return;

    _config!.syncDirs = dirs;
    await _config!.save();

    // 重新启动监听
    _stopWatching();
    if (_config!.syncOnChange) {
      await _startWatching();
    }
  }

  /// 释放资源
  Future<void> dispose() async {
    // 取消所有防抖定时器
    for (final timer in _debounceTimers.values) {
      timer.cancel();
    }
    _debounceTimers.clear();

    _stopWatching();
    _syncQueue.clear();
    _fileModifyTimes.clear();
    _fileMd5Cache.clear();

    // 断开并清理 WebSocket
    _wsService?.disconnect();
    _wsService = null;
    _recordService = null;

    _syncService = null;
    _config = null;
    _isInitialized = false;
    _isSyncing = false;
    _currentTask = null;
  }

  /// 是否已初始化
  bool get isInitialized => _isInitialized;

  /// 是否正在监听
  bool get isWatching => _watchers.isNotEmpty;

  /// 当前监听的目录数
  int get watchingDirsCount => _watchers.length;

  /// WebSocket 是否已连接
  bool get isWsConnected => _wsService?.isConnected ?? false;

  /// 是否正在同步
  bool get isSyncing => _isSyncing;

  /// 待同步任务数
  int get pendingSyncCount => _syncQueue.length;

  /// 当前正在处理的任务
  SyncTask? get currentTask => _currentTask;
}

/// 同步任务
class SyncTask {
  final String filePath;
  final String trigger; // 'create', 'modify', 'delete', 'move'
  final DateTime timestamp;

  SyncTask({
    required this.filePath,
    required this.trigger,
    required this.timestamp,
  });

  @override
  String toString() => 'SyncTask($filePath, $trigger, $timestamp)';
}

/// 文件监听同步服务的全局实例
final fileWatchSyncService = FileWatchSyncService();
