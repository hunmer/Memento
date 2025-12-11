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
/// - 当文件发生变化时自动触发同步
/// - 节流处理，避免频繁同步
class FileWatchSyncService {
  static final FileWatchSyncService _instance = FileWatchSyncService._internal();
  factory FileWatchSyncService() => _instance;
  FileWatchSyncService._internal();

  // 文件监听器列表
  final Map<String, StreamSubscription<FileSystemEvent>> _watchers = {};

  // 节流定时器
  Timer? _throttleTimer;

  // 待同步的文件路径
  final Set<String> _pendingSyncPaths = {};

  // 同步服务
  SyncClientService? _syncService;

  // 配置
  ServerSyncConfig? _config;

  // 是否已初始化
  bool _isInitialized = false;

  // 是否正在同步
  bool _isSyncing = false;

  // 节流时间窗口（毫秒）- 在此时间内最多触发一次同步
  static const int _throttleWindowMs = 5000;

  // 最小同步间隔（毫秒）- 两次同步之间的最小间隔
  static const int _minSyncIntervalMs = 3000;

  // 上次同步时间
  DateTime? _lastSyncTime;

  /// 初始化服务
  Future<void> initialize() async {
    if (_isInitialized) return;
    if (kIsWeb) return; // Web 平台不支持文件监听

    try {
      _config = await ServerSyncConfig.load();
      if (_config == null || !_config!.isLoggedIn) {
        debugPrint('FileWatchSyncService: 未登录，跳过初始化');
        return;
      }

      // 检查是否启用了文件修改时同步
      if (!_config!.syncOnChange) {
        debugPrint('FileWatchSyncService: 文件修改时同步未启用，跳过初始化');
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

      // 开始监听
      await _startWatching();

      _isInitialized = true;
      debugPrint('FileWatchSyncService: 初始化完成');
    } catch (e) {
      debugPrint('FileWatchSyncService: 初始化失败 - $e');
    }
  }

  /// 重新加载配置并更新监听状态
  Future<void> reload() async {
    await dispose();
    _isInitialized = false;
    await initialize();
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

    for (final dirName in _config!.syncDirs) {
      final dirPath = path.join(basePath, dirName);
      final directory = Directory(dirPath);

      if (await directory.exists()) {
        try {
          final watcher = directory.watch(
            events: FileSystemEvent.create |
                FileSystemEvent.modify |
                FileSystemEvent.delete,
            recursive: true,
          );

          _watchers[dirName] = watcher.listen(
            _onFileChanged,
            onError: (e) => debugPrint('FileWatchSyncService: 监听错误 - $e'),
          );

          debugPrint('FileWatchSyncService: 开始监听 $dirPath');
        } catch (e) {
          debugPrint('FileWatchSyncService: 无法监听 $dirName - $e');
        }
      } else {
        debugPrint('FileWatchSyncService: 目录不存在，跳过 $dirPath');
      }
    }
  }

  /// 停止监听文件变化
  void _stopWatching() {
    for (final watcher in _watchers.values) {
      watcher.cancel();
    }
    _watchers.clear();
    debugPrint('FileWatchSyncService: 已停止所有监听');
  }

  /// 文件变化处理
  void _onFileChanged(FileSystemEvent event) {
    // 只处理 JSON 文件
    if (!event.path.endsWith('.json')) return;

    // 忽略同步快照文件
    if (event.path.contains('.sync_snapshots')) return;

    debugPrint('FileWatchSyncService: 检测到文件变化 - ${event.path} (${event.type})');

    // 添加到待同步列表
    _pendingSyncPaths.add(event.path);

    // 节流处理：如果没有定时器运行，立即启动
    _scheduleSync();
  }

  /// 调度同步（节流机制）
  void _scheduleSync() {
    // 如果已经有定时器在运行，不重复创建
    if (_throttleTimer != null && _throttleTimer!.isActive) {
      return;
    }

    // 计算需要等待的时间
    int delayMs = _throttleWindowMs;

    if (_lastSyncTime != null) {
      final elapsed = DateTime.now().difference(_lastSyncTime!).inMilliseconds;
      if (elapsed < _minSyncIntervalMs) {
        // 如果距离上次同步时间太短，延迟更长时间
        delayMs = _minSyncIntervalMs - elapsed + 1000;
      }
    }

    _throttleTimer = Timer(
      Duration(milliseconds: delayMs),
      _performPendingSync,
    );

    debugPrint('FileWatchSyncService: 已调度同步，${delayMs}ms 后执行');
  }

  /// 执行待同步的文件
  Future<void> _performPendingSync() async {
    // 防止并发同步
    if (_isSyncing) {
      debugPrint('FileWatchSyncService: 正在同步中，跳过');
      // 如果还有待同步的文件，重新调度
      if (_pendingSyncPaths.isNotEmpty) {
        _throttleTimer = null;
        _scheduleSync();
      }
      return;
    }

    if (_syncService == null || !_syncService!.isLoggedIn) {
      debugPrint('FileWatchSyncService: 同步服务未就绪');
      _pendingSyncPaths.clear();
      return;
    }

    if (_pendingSyncPaths.isEmpty) return;

    _isSyncing = true;
    final pathsToSync = Set<String>.from(_pendingSyncPaths);
    _pendingSyncPaths.clear();

    debugPrint('FileWatchSyncService: 开始同步 ${pathsToSync.length} 个文件');

    try {
      final basePath = await _getDataBasePath();

      int successCount = 0;
      int errorCount = 0;

      for (final fullPath in pathsToSync) {
        // 计算相对路径（相对于 app_data 目录）
        final relativePath = fullPath
            .substring(basePath.length)
            .replaceAll('\\', '/')
            .replaceFirst(RegExp(r'^/'), '');

        debugPrint('FileWatchSyncService: 同步文件 $relativePath');

        final file = File(fullPath);
        if (await file.exists()) {
          // 文件存在，推送到服务器
          final result = await _syncService!.syncFile(relativePath);
          if (result.isSuccess) {
            successCount++;
          } else {
            errorCount++;
          }
          debugPrint('FileWatchSyncService: 同步结果 - ${result.type}');
        } else {
          // 文件被删除，可能需要在服务器上标记删除
          debugPrint('FileWatchSyncService: 文件已删除，跳过 $relativePath');
        }
      }

      _lastSyncTime = DateTime.now();
      debugPrint('FileWatchSyncService: 同步完成 - 成功: $successCount, 失败: $errorCount');
    } catch (e) {
      debugPrint('FileWatchSyncService: 同步失败 - $e');
    } finally {
      _isSyncing = false;
      _throttleTimer = null;

      // 如果在同步期间有新的文件变化，重新调度
      if (_pendingSyncPaths.isNotEmpty) {
        _scheduleSync();
      }
    }
  }

  /// 手动触发全量同步
  Future<List<SyncResult>> performFullSync() async {
    if (_syncService == null || !_syncService!.isLoggedIn) {
      return [SyncResult.error('同步服务未就绪')];
    }

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
    _throttleTimer?.cancel();
    _throttleTimer = null;
    _stopWatching();
    _pendingSyncPaths.clear();
    _syncService = null;
    _config = null;
    _isInitialized = false;
    _isSyncing = false;
    _lastSyncTime = null;
    debugPrint('FileWatchSyncService: 已释放资源');
  }

  /// 是否已初始化
  bool get isInitialized => _isInitialized;

  /// 是否正在监听
  bool get isWatching => _watchers.isNotEmpty;

  /// 当前监听的目录数
  int get watchingDirsCount => _watchers.length;

  /// 是否正在同步
  bool get isSyncing => _isSyncing;

  /// 待同步文件数
  int get pendingSyncCount => _pendingSyncPaths.length;
}

/// 文件监听同步服务的全局实例
final fileWatchSyncService = FileWatchSyncService();
