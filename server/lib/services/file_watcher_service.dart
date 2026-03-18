import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;

import 'file_storage_service.dart';
import 'websocket_manager.dart';

/// 文件状态缓存
class _FileState {
  final String md5;
  final DateTime modifiedAt;

  _FileState({required this.md5, required this.modifiedAt});
}

/// 文件监听服务
///
/// 监听 data/users 目录下的文件变化，当修改时间和 MD5 都变动时通知 WebSocket 客户端
class FileWatcherService {
  final FileStorageService _storageService;
  final WebSocketManager _webSocketManager;
  final String _dataDir;

  /// 文件状态缓存: userId -> filePath -> _FileState
  final Map<String, Map<String, _FileState>> _fileStates = {};

  /// 轮询定时器
  Timer? _pollTimer;

  /// 轮询间隔（毫秒）
  final int _pollIntervalMs;

  /// 是否启用日志
  bool _enableLog = true;

  /// 是否正在运行
  bool _isRunning = false;

  FileWatcherService(
    this._storageService,
    this._webSocketManager,
    this._dataDir, {
    int pollIntervalMs = 2000,
  }) : _pollIntervalMs = pollIntervalMs;

  /// 启动文件监听
  Future<void> start() async {
    if (_isRunning) {
      _log('文件监听服务已在运行中');
      return;
    }

    _isRunning = true;

    // 初始化文件状态缓存
    await _initializeFileStates();

    // 启动轮询
    _pollTimer = Timer.periodic(
      Duration(milliseconds: _pollIntervalMs),
      (_) => _pollFileChanges(),
    );

    _log('文件监听服务已启动，轮询间隔: ${_pollIntervalMs}ms');
  }

  /// 停止文件监听
  Future<void> stop() async {
    _pollTimer?.cancel();
    _pollTimer = null;
    _isRunning = false;
    _fileStates.clear();
    _log('文件监听服务已停止');
  }

  /// 初始化文件状态缓存
  Future<void> _initializeFileStates() async {
    final usersDir = Directory(path.join(_dataDir, 'users'));
    if (!await usersDir.exists()) {
      _log('用户目录不存在，跳过初始化');
      return;
    }

    int totalFiles = 0;

    await for (final userEntity in usersDir.list()) {
      if (userEntity is Directory) {
        final userId = path.basename(userEntity.path);
        _fileStates[userId] = {};

        await for (final entity in userEntity.list(recursive: true)) {
          if (entity is File) {
            final fileName = path.basename(entity.path);

            // 排除索引文件和临时文件
            if (fileName.startsWith('.') ||
                fileName.endsWith('.tmp') ||
                fileName.endsWith('.bak')) {
              continue;
            }

            try {
              final relativePath = path.relative(entity.path, from: userEntity.path);
              final normalizedPath = relativePath.replaceAll('\\', '/');

              final state = await _readFileState(entity);
              if (state != null) {
                _fileStates[userId]![normalizedPath] = state;
                totalFiles++;
              }
            } catch (e) {
              // 忽略读取错误
            }
          }
        }
      }
    }

    _log('已初始化 $totalFiles 个文件的状态缓存');
  }

  /// 读取文件状态
  Future<_FileState?> _readFileState(File file) async {
    try {
      final content = await file.readAsString();
      final data = jsonDecode(content) as Map<String, dynamic>;

      final md5 = data['md5'] as String?;
      final updatedAtStr = data['updated_at'] as String?;

      if (md5 == null || updatedAtStr == null) {
        return null;
      }

      return _FileState(
        md5: md5,
        modifiedAt: DateTime.parse(updatedAtStr),
      );
    } catch (e) {
      return null;
    }
  }

  /// 轮询文件变化
  Future<void> _pollFileChanges() async {
    final usersDir = Directory(path.join(_dataDir, 'users'));
    if (!await usersDir.exists()) {
      return;
    }

    await for (final userEntity in usersDir.list()) {
      if (userEntity is Directory) {
        final userId = path.basename(userEntity.path);
        await _checkUserFiles(userId, userEntity);
      }
    }
  }

  /// 检查用户文件变化
  Future<void> _checkUserFiles(String userId, Directory userDir) async {
    // 确保用户有状态缓存
    if (!_fileStates.containsKey(userId)) {
      _fileStates[userId] = {};
    }

    final currentState = _fileStates[userId]!;
    final foundFiles = <String>{};

    await for (final entity in userDir.list(recursive: true)) {
      if (entity is File) {
        final fileName = path.basename(entity.path);

        // 排除索引文件和临时文件
        if (fileName.startsWith('.') ||
            fileName.endsWith('.tmp') ||
            fileName.endsWith('.bak')) {
          continue;
        }

        try {
          final relativePath = path.relative(entity.path, from: userDir.path);
          final normalizedPath = relativePath.replaceAll('\\', '/');
          foundFiles.add(normalizedPath);

          final newState = await _readFileState(entity);
          if (newState == null) continue;

          final oldState = currentState[normalizedPath];

          // 检查是否是新增文件或修改时间和 MD5 都变动
          if (oldState == null) {
            // 新增文件
            currentState[normalizedPath] = newState;
            _log('检测到新文件: userId=$userId, path=$normalizedPath');
            // 新增文件也广播通知
            _broadcastUpdate(userId, normalizedPath, newState);
          } else if (oldState.md5 != newState.md5 &&
                     oldState.modifiedAt != newState.modifiedAt) {
            // 修改时间和 MD5 都变动才通知
            currentState[normalizedPath] = newState;
            _log('检测到文件变化: userId=$userId, path=$normalizedPath, oldMd5=${oldState.md5}, newMd5=${newState.md5}');
            _broadcastUpdate(userId, normalizedPath, newState);
          } else if (oldState.md5 != newState.md5) {
            // 只有 MD5 变化，更新缓存但不广播
            currentState[normalizedPath] = newState;
            _log('文件 MD5 变化但时间未变，仅更新缓存: $normalizedPath');
          }
        } catch (e) {
          // 忽略读取错误
        }
      }
    }

    // 移除已删除的文件缓存
    final deletedPaths = currentState.keys.where((p) => !foundFiles.contains(p)).toList();
    for (final deletedPath in deletedPaths) {
      currentState.remove(deletedPath);
      _log('文件已删除，移除缓存: $deletedPath');
    }
  }

  /// 广播文件更新
  void _broadcastUpdate(String userId, String filePath, _FileState state) {
    // 检查用户是否有在线连接
    if (!_webSocketManager.isUserOnline(userId)) {
      return;
    }

    // 广播给用户所有设备（不排除源设备，因为这是文件系统监听）
    // 客户端会根据 md5 判断是否需要拉取
    _webSocketManager.broadcastFileUpdate(
      userId,
      filePath,
      state.md5,
      state.modifiedAt,
      '', // 空的 sourceDeviceId 表示是服务端检测到的变化
    );
  }

  /// 输出日志
  void _log(String message) {
    if (_enableLog) {
      print('[FileWatcher] $message');
    }
  }

  /// 设置日志开关
  void setLogEnabled(bool enabled) {
    _enableLog = enabled;
  }

  /// 获取缓存的文件数量
  int get cachedFileCount {
    int count = 0;
    for (final userStates in _fileStates.values) {
      count += userStates.length;
    }
    return count;
  }

  /// 获取缓存的用户数量
  int get cachedUserCount => _fileStates.length;
}
