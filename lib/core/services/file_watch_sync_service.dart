import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;

import 'package:Memento/core/storage/storage_manager.dart';
import 'package:Memento/core/services/sync_client_service.dart';
import 'package:Memento/core/services/encryption_service.dart';
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

  // 配置
  ServerSyncConfig? _config;

  // 是否已初始化
  bool _isInitialized = false;

  // 是否正在同步
  bool _isSyncing = false;

  // 文件修改时间记录（用于检测真正的修改）
  final Map<String, DateTime> _fileModifyTimes = {};

  // 同步防抖间隔（毫秒）- 同一文件在短时间内多次修改，只同步最后一次
  static const int _debounceMs = 500;

  // 防抖定时器映射
  final Map<String, Timer> _debounceTimers = {};

  /// 初始化服务
  Future<void> initialize() async {
    if (_isInitialized) return;
    if (kIsWeb) return; // Web 平台不支持文件监听

    _log('开始初始化...');

    try {
      _config = await ServerSyncConfig.load();
      if (_config == null || !_config!.isLoggedIn) {
        _log('未登录，跳过初始化');
        return;
      }

      // 检查是否启用了文件修改时同步
      if (!_config!.syncOnChange) {
        _log('文件修改时同步未启用，跳过初始化');
        return;
      }

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

      _log('同步服务初始化完成 - 服务器: ${_config!.server}');

      // 开始监听
      await _startWatching();

      _isInitialized = true;
      _log('初始化完成，监听目录: ${_config!.syncDirs}');

      // 启动时后台同步（不阻塞主线程）
      if (_config!.syncOnStart) {
        _performStartupSync();
      }
    } catch (e, stack) {
      _log('初始化失败 - $e');
      debugPrint('$_tag: $stack');
    }
  }

  /// 重新加载配置并更新监听状态
  Future<void> reload() async {
    _log('重新加载配置...');
    await dispose();
    _isInitialized = false;
    await initialize();
  }

  /// 输出调试日志
  void _log(String message) {
    final timestamp = DateTime.now().toIso8601String();
    debugPrint('$_tag [$timestamp]: $message');
  }

  /// 启动时后台同步（异步执行，不阻塞主线程）
  void _performStartupSync() {
    _log('计划启动时同步（2秒后执行）...');
    // 使用 Future.delayed 确保 UI 先加载完成
    Future.delayed(const Duration(seconds: 2), () async {
      if (_syncService == null || !_syncService!.isLoggedIn) {
        _log('启动同步跳过 - 同步服务未就绪');
        return;
      }

      _log('开始启动时全量同步...');

      try {
        final results = await _syncService!.fullSync();

        int pullCount = 0;
        int pushCount = 0;
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
              _log('同步错误: ${result.filePath} - ${result.message}');
              break;
            default:
              break;
          }
        }

        _log('启动同步完成 - 推送: $pushCount, 拉取: $pullCount, 错误: $errorCount');
      } catch (e) {
        _log('启动同步失败 - $e');
      }
    });
  }

  /// 获取数据存储的基础路径
  Future<String> _getDataBasePath() async {
    final appDir = await StorageManager.getApplicationDocumentsDirectory();
    // 与 mobile_storage.dart 保持一致，数据存储在 app_data 子目录
    return path.join(appDir.path, 'app_data');
  }

  /// 开始监听文件变化
  Future<void> _startWatching() async {
    if (_config == null) return;

    final basePath = await _getDataBasePath();
    _log('基础路径: $basePath');

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
            onError: (e) => _log('监听错误 [$dirName]: $e'),
          );

          _log('开始监听目录: $dirPath');
        } catch (e) {
          _log('无法监听目录 $dirName: $e');
        }
      } else {
        _log('目录不存在，跳过: $dirPath');
      }
    }
  }

  /// 停止监听文件变化
  void _stopWatching() {
    for (final watcher in _watchers.values) {
      watcher.cancel();
    }
    _watchers.clear();
    _log('已停止所有监听');
  }

  /// 文件变化处理
  void _onFileChanged(FileSystemEvent event) {
    // 忽略同步快照文件
    if (event.path.contains('.sync_snapshots')) return;

    // 忽略临时文件
    if (event.path.endsWith('.tmp') ||
        event.path.endsWith('.temp') ||
        event.path.endsWith('.bak')) {
      return;
    }

    // 忽略隐藏文件（以.开头）
    final fileName = path.basename(event.path);
    if (fileName.startsWith('.')) return;

    final eventType = _getEventTypeString(event.type);
    _log('检测到文件变化: ${event.path} (类型: $eventType)');

    // 对于修改事件，检查文件修改时间是否真的变化
    if (event.type == FileSystemEvent.modify) {
      _handleModifyEvent(event.path);
    } else if (event.type == FileSystemEvent.create) {
      // 创建事件，立即加入队列
      _addToSyncQueue(event.path, 'create');
    } else if (event.type == FileSystemEvent.delete) {
      // 删除事件，立即加入队列
      _addToSyncQueue(event.path, 'delete');
    } else if (event.type == FileSystemEvent.move) {
      // 移动事件，立即加入队列
      _addToSyncQueue(event.path, 'move');
    }
  }

  /// 获取事件类型字符串
  String _getEventTypeString(int eventType) {
    final types = <String>[];
    if (eventType & FileSystemEvent.create != 0) types.add('create');
    if (eventType & FileSystemEvent.modify != 0) types.add('modify');
    if (eventType & FileSystemEvent.delete != 0) types.add('delete');
    if (eventType & FileSystemEvent.move != 0) types.add('move');
    return types.join('|');
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

    _log('设置防抖定时器: $filePath (${_debounceMs}ms)');
  }

  /// 检查文件修改时间并加入队列
  Future<void> _checkAndAddToQueue(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        _log('文件不存在，跳过: $filePath');
        return;
      }

      final stat = await file.stat();
      final modifiedTime = stat.modified;

      // 检查是否有记录的修改时间
      final lastModified = _fileModifyTimes[filePath];

      if (lastModified != null && !modifiedTime.isAfter(lastModified)) {
        _log('文件修改时间未变化，跳过: $filePath');
        return;
      }

      // 更新修改时间记录
      _fileModifyTimes[filePath] = modifiedTime;

      _log('文件修改时间: ${modifiedTime.toIso8601String()}');

      // 加入同步队列
      _addToSyncQueue(filePath, 'modify');
    } catch (e) {
      _log('检查文件修改时间失败: $filePath - $e');
    }
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
      _log('更新队列中的任务: $filePath (触发: $trigger)');
    } else {
      // 添加新任务
      _syncQueue.add(task);
      _log('添加到同步队列: $filePath (触发: $trigger, 队列长度: ${_syncQueue.length})');
    }

    // 如果当前没有在同步，立即开始处理队列
    if (!_isSyncing) {
      _processQueue();
    } else {
      _log('正在同步中，任务已加入队列等待处理');
    }
  }

  /// 处理同步队列
  Future<void> _processQueue() async {
    if (_isSyncing) {
      _log('已在处理队列中，跳过');
      return;
    }

    if (_syncQueue.isEmpty) {
      _log('同步队列为空');
      return;
    }

    if (_syncService == null || !_syncService!.isLoggedIn) {
      _log('同步服务未就绪，清空队列');
      _syncQueue.clear();
      return;
    }

    _isSyncing = true;
    _log('开始处理同步队列，待处理任务数: ${_syncQueue.length}');

    int successCount = 0;
    int errorCount = 0;
    int skipCount = 0;

    try {
      final basePath = await _getDataBasePath();

      while (_syncQueue.isNotEmpty) {
        // 从队列头部取出任务
        final task = _syncQueue.removeAt(0);
        _currentTask = task;

        _log('处理任务 [${successCount + errorCount + skipCount + 1}/${successCount + errorCount + skipCount + _syncQueue.length + 1}]: ${task.filePath}');

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

          if (result.isSuccess) {
            successCount++;
            _log('同步成功: $relativePath (${result.type})');
          } else {
            errorCount++;
            _log('同步失败: $relativePath - ${result.message}');
          }
        } else {
          // 文件被删除
          skipCount++;
          _log('文件已删除，跳过: $relativePath');
          // 可以在这里添加删除服务器文件的逻辑
        }

        _currentTask = null;
      }

      _log('队列处理完成 - 成功: $successCount, 失败: $errorCount, 跳过: $skipCount');
    } catch (e, stack) {
      _log('处理队列异常: $e');
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

    _log('设置文件修改时同步: $enabled');

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

    _log('更新同步目录列表: $dirs');

    // 重新启动监听
    _stopWatching();
    if (_config!.syncOnChange) {
      await _startWatching();
    }
  }

  /// 释放资源
  Future<void> dispose() async {
    _log('开始释放资源...');

    // 取消所有防抖定时器
    for (final timer in _debounceTimers.values) {
      timer.cancel();
    }
    _debounceTimers.clear();

    _stopWatching();
    _syncQueue.clear();
    _fileModifyTimes.clear();
    _syncService = null;
    _config = null;
    _isInitialized = false;
    _isSyncing = false;
    _currentTask = null;

    _log('资源释放完成');
  }

  /// 是否已初始化
  bool get isInitialized => _isInitialized;

  /// 是否正在监听
  bool get isWatching => _watchers.isNotEmpty;

  /// 当前监听的目录数
  int get watchingDirsCount => _watchers.length;

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
