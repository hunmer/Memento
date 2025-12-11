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
/// - 防抖处理，避免频繁同步
class FileWatchSyncService {
  static final FileWatchSyncService _instance = FileWatchSyncService._internal();
  factory FileWatchSyncService() => _instance;
  FileWatchSyncService._internal();

  // 文件监听器列表
  final Map<String, StreamSubscription<FileSystemEvent>> _watchers = {};

  // 防抖定时器
  Timer? _debounceTimer;

  // 待同步的文件路径
  final Set<String> _pendingSyncPaths = {};

  // 同步服务
  SyncClientService? _syncService;

  // 配置
  ServerSyncConfig? _config;

  // 是否已初始化
  bool _isInitialized = false;

  // 防抖延迟时间（毫秒）
  static const int _debounceDelayMs = 2000;

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

      // 如果启用了文件修改时同步，开始监听
      if (_config!.syncOnChange) {
        await _startWatching();
      }

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

  /// 开始监听文件变化
  Future<void> _startWatching() async {
    if (_config == null) return;

    final appDir = await StorageManager.getApplicationDocumentsDirectory();

    for (final dirName in _config!.syncDirs) {
      final dirPath = path.join(appDir.path, dirName);
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

          debugPrint('FileWatchSyncService: 开始监听 $dirName');
        } catch (e) {
          debugPrint('FileWatchSyncService: 无法监听 $dirName - $e');
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
    debugPrint('FileWatchSyncService: 已停止所有监听');
  }

  /// 文件变化处理
  void _onFileChanged(FileSystemEvent event) {
    // 只处理 JSON 文件
    if (!event.path.endsWith('.json')) return;

    debugPrint('FileWatchSyncService: 检测到文件变化 - ${event.path} (${event.type})');

    // 计算相对路径
    _pendingSyncPaths.add(event.path);

    // 防抖处理
    _debounceTimer?.cancel();
    _debounceTimer = Timer(
      const Duration(milliseconds: _debounceDelayMs),
      _performPendingSync,
    );
  }

  /// 执行待同步的文件
  Future<void> _performPendingSync() async {
    if (_syncService == null || !_syncService!.isLoggedIn) {
      debugPrint('FileWatchSyncService: 同步服务未就绪');
      _pendingSyncPaths.clear();
      return;
    }

    if (_pendingSyncPaths.isEmpty) return;

    debugPrint('FileWatchSyncService: 开始同步 ${_pendingSyncPaths.length} 个文件');

    try {
      final appDir = await StorageManager.getApplicationDocumentsDirectory();

      for (final fullPath in _pendingSyncPaths.toList()) {
        // 计算相对路径
        final relativePath = fullPath
            .substring(appDir.path.length)
            .replaceAll('\\', '/')
            .replaceFirst(RegExp(r'^/'), '');

        debugPrint('FileWatchSyncService: 同步文件 $relativePath');

        final file = File(fullPath);
        if (await file.exists()) {
          // 文件存在，推送到服务器
          final result = await _syncService!.syncFile(relativePath);
          debugPrint('FileWatchSyncService: 同步结果 - ${result.type}');
        } else {
          // 文件被删除，可能需要在服务器上标记删除
          // 注意：当前实现不支持同步删除操作
          debugPrint('FileWatchSyncService: 文件已删除，跳过 $relativePath');
        }
      }
    } catch (e) {
      debugPrint('FileWatchSyncService: 同步失败 - $e');
    } finally {
      _pendingSyncPaths.clear();
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
    _debounceTimer?.cancel();
    _stopWatching();
    _pendingSyncPaths.clear();
    _syncService = null;
    _config = null;
    _isInitialized = false;
    debugPrint('FileWatchSyncService: 已释放资源');
  }

  /// 是否已初始化
  bool get isInitialized => _isInitialized;

  /// 是否正在监听
  bool get isWatching => _watchers.isNotEmpty;

  /// 当前监听的目录数
  int get watchingDirsCount => _watchers.length;
}

/// 文件监听同步服务的全局实例
final fileWatchSyncService = FileWatchSyncService();
