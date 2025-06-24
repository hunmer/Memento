import 'dart:async';
import 'dart:io';
import 'package:Memento/core/storage/storage_manager.dart';
import 'package:flutter/material.dart';
import 'package:webdav_client/webdav_client.dart' as webdav;
import 'package:path/path.dart' as path;
import '../widgets/backup_progress_dialog.dart';
import '../models/webdav_config.dart';

class WebDAVSyncController {
  final BuildContext _originalContext;
  bool _mounted = true;
  final _progressController = StreamController<BackupProgress>.broadcast();
  Stream<BackupProgress> get progressStream => _progressController.stream;

  // WebDAV客户端
  webdav.Client? _webdavClient;
  bool _isConnected = false;
  bool get isConnected => _isConnected;

  // 重试配置
  static const int maxRetries = 10; // 最大重试次数
  static const Duration retryDelay = Duration(seconds: 2); // 重试间隔

  // 当前进度
  BackupProgress _currentProgress = BackupProgress.initial();

  // 最大显示的最近文件数
  static const int _maxRecentFiles = 10;

  WebDAVSyncController(this._originalContext) {
    _initWebDAV();
  }

  // 获取当前有效的 context，如果 _mounted 为 false，则返回 null
  BuildContext? get _safeContext => _mounted ? _originalContext : null;

  void dispose() {
    _mounted = false;
    _progressController.close();
  }

  // 初始化WebDAV客户端
  Future<void> _initWebDAV() async {
    try {
      // 从应用设置中获取WebDAV配置
      final webdavUrl = await _getWebDAVUrl();
      final username = await _getWebDAVUsername();
      final password = await _getWebDAVPassword();

      if (webdavUrl.isEmpty || username.isEmpty || password.isEmpty) {
        _isConnected = false;
        return;
      }

      _webdavClient = webdav.newClient(
        webdavUrl,
        user: username,
        password: password,
        debug: false,
      );

      // 测试连接
      await _webdavClient!.ping();
      _isConnected = true;

      // 确保远程目录存在
      await _ensureRemoteDirectoryExists();
    } catch (e) {
      debugPrint('WebDAV初始化失败: $e');
      _isConnected = false;
      _webdavClient = null;
    }
  }

  // 确保远程目录存在
  Future<void> _ensureRemoteDirectoryExists() async {
    if (_webdavClient == null) return;

    try {
      const remotePath = '/app_backup';
      try {
        await _webdavClient!.mkdir(remotePath);
      } catch (e) {
        // 目录可能已存在，忽略错误
        debugPrint('目录可能已存在: $e');
      }
    } catch (e) {
      debugPrint('创建远程目录失败: $e');
    }
  }

  // 从设置中获取WebDAV配置
  Future<WebDAVConfig> _getWebDAVConfig() async {
    return await WebDAVConfig.load();
  }

  // 从设置中获取WebDAV URL
  Future<String> _getWebDAVUrl() async {
    final config = await _getWebDAVConfig();
    return config.server;
  }

  // 从设置中获取WebDAV用户名
  Future<String> _getWebDAVUsername() async {
    final config = await _getWebDAVConfig();
    return config.username;
  }

  // 从设置中获取WebDAV密码
  Future<String> _getWebDAVPassword() async {
    final config = await _getWebDAVConfig();
    return config.password;
  }

  // 更新进度
  void _updateProgress({
    double? totalProgress,
    String? currentOperation,
    String? recentFile,
  }) {
    if (!_mounted) return;

    List<String> updatedRecentFiles = List.from(_currentProgress.recentFiles);
    if (recentFile != null) {
      // 添加新文件到列表开头
      updatedRecentFiles = [recentFile, ...updatedRecentFiles];
      // 限制列表大小
      if (updatedRecentFiles.length > _maxRecentFiles) {
        updatedRecentFiles = updatedRecentFiles.sublist(0, _maxRecentFiles);
      }
    }

    _currentProgress = _currentProgress.copyWith(
      totalProgress: totalProgress ?? _currentProgress.totalProgress,
      currentOperation: currentOperation ?? _currentProgress.currentOperation,
      recentFiles: updatedRecentFiles,
    );

    _progressController.add(_currentProgress);
  }

  // 关闭进度对话框
  void _closeDialog() {
    if (!_mounted) return;

    final context = _safeContext;
    if (context == null) return;

    Navigator.of(context, rootNavigator: true).pop();
  }

  // 显示错误提示
  void _showErrorSnackBar(String message) {
    if (!_mounted) return;

    final context = _safeContext;
    if (context == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  // 显示成功提示
  void _showSuccessSnackBar(String message) {
    if (!_mounted) return;

    final context = _safeContext;
    if (context == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  // 递归获取所有文件
  Future<List<File>> _getAllFiles(Directory directory) async {
    List<File> files = [];

    try {
      final entities = directory.listSync();
      for (final entity in entities) {
        if (entity is File) {
          files.add(entity);
        } else if (entity is Directory) {
          files.addAll(await _getAllFiles(entity));
        }
      }
    } catch (e) {
      debugPrint('获取文件列表失败: $e');
    }

    return files;
  }

  // 递归创建远程目录（带重试）
  Future<void> _ensureRemoteDirectoryExistsRecursively(
    String remotePath,
  ) async {
    if (remotePath == '/' || remotePath.isEmpty) return;

    int retryCount = 0;
    Exception? lastError;

    while (retryCount < maxRetries) {
      try {
        try {
          await _webdavClient!.readDir(remotePath);
          return; // 目录存在，直接返回
        } catch (e) {
          // 确保父目录存在
          final parentDir = path.dirname(remotePath);
          await _ensureRemoteDirectoryExistsRecursively(parentDir);

          // 创建当前目录
          await _webdavClient!.mkdir(remotePath);
          return; // 创建成功，返回
        }
      } catch (e) {
        lastError = e as Exception;
        retryCount++;
        if (retryCount < maxRetries) {
          debugPrint('创建目录失败，正在重试 ($retryCount/$maxRetries): $e');
          await Future.delayed(retryDelay);
        }
      }
    }

    debugPrint('创建远程目录失败，已重试 $maxRetries 次: $lastError');
    throw lastError ?? Exception('创建远程目录失败');
  }

  // 递归获取所有远程文件（带重试）
  Future<List<String>> _listAllRemoteFiles(String remotePath) async {
    List<String> files = [];
    int retryCount = 0;
    Exception? lastError;

    while (retryCount < maxRetries) {
      try {
        final items = await _webdavClient!.readDir(remotePath);

        for (final item in items) {
          final itemPath = item.path;
          if (itemPath == null) continue;

          if (item.isDir == false) {
            // 这是一个文件
            files.add(itemPath);
          } else {
            // 这是一个目录，递归获取
            files.addAll(await _listAllRemoteFiles(itemPath));
          }
        }
        return files; // 成功获取文件列表，返回结果
      } catch (e) {
        lastError = e as Exception;
        retryCount++;
        if (retryCount < maxRetries) {
          debugPrint('获取远程文件列表失败，正在重试 ($retryCount/$maxRetries): $e');
          _updateProgress(
            currentOperation: '获取文件列表失败，正在重试 ($retryCount/$maxRetries)...',
          );
          await Future.delayed(retryDelay);
        }
      }
    }

    debugPrint('获取远程文件列表失败，已重试 $maxRetries 次: $lastError');
    throw lastError ?? Exception('获取远程文件列表失败');
  }

  // 上传所有文件到WebDAV
  Future<bool> uploadAllToWebDAV() async {
    if (!_mounted) return false;

    // 保存当前 context 的引用
    final context = _safeContext;
    if (context == null) return false;

    // 检查WebDAV连接
    if (_webdavClient == null || !_isConnected) {
      await _initWebDAV();
      if (_webdavClient == null || !_isConnected) {
        _showErrorSnackBar('WebDAV连接失败，请检查设置');
        return false;
      }
    }

    // 重置进度
    _currentProgress = BackupProgress.initial();
    _updateProgress(totalProgress: 0.0, currentOperation: '准备上传...');

    // 显示进度对话框
    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (dialogContext) => BackupProgressDialog(
              progressStream: progressStream,
              title: '上传到WebDAV',
              onCancel: () {
                // 处理取消操作
                Navigator.of(dialogContext).pop();
                _showErrorSnackBar('上传已取消');
              },
            ),
      );
    }

    try {
      // 获取应用文档目录
      final appDir = await StorageManager.getApplicationDocumentsDirectory();

      // 获取所有文件
      final files = await _getAllFiles(appDir);
      int totalFiles = files.length;
      int processedFiles = 0;

      // 上传文件
      for (final file in files) {
        if (!_mounted) {
          _closeDialog();
          return false;
        }

        final relativePath = file.path.substring(appDir.path.length);
        final remotePath = '/app_backup$relativePath';

        // 更新进度
        processedFiles++;
        final progress =
            totalFiles > 0 ? (processedFiles / totalFiles).toDouble() : 0.0;
        _updateProgress(
          totalProgress: progress,
          currentOperation: '上传文件 ($processedFiles/$totalFiles)',
          recentFile: relativePath,
        );

        // 确保远程目录存在
        final remoteDir = path.dirname(remotePath);
        await _ensureRemoteDirectoryExistsRecursively(remoteDir);

        // 上传文件（带重试）
        bool uploadSuccess = false;
        int retryCount = 0;
        Exception? lastError;

        while (!uploadSuccess && retryCount < maxRetries) {
          try {
            await _webdavClient!.writeFromFile(file.path, remotePath);
            uploadSuccess = true;
          } catch (e) {
            lastError = e as Exception;
            retryCount++;
            if (retryCount < maxRetries) {
              _updateProgress(
                currentOperation: '上传失败，正在重试 ($retryCount/$maxRetries)...',
                recentFile: relativePath,
              );
              await Future.delayed(retryDelay);
            }
          }
        }

        if (!uploadSuccess) {
          throw lastError ?? Exception('上传失败，已重试 $maxRetries 次');
        }

        // 让出CPU时间片
        await Future.delayed(Duration.zero);
      }

      // 上传完成
      _updateProgress(totalProgress: 1.0, currentOperation: '上传完成');

      // 关闭进度对话框
      _closeDialog();

      // 显示成功消息
      _showSuccessSnackBar('上传完成，共上传 $totalFiles 个文件');
      return true;
    } catch (e) {
      debugPrint('上传失败: $e');
      _closeDialog();
      _showErrorSnackBar('上传失败: $e');
      return false;
    }
  }

  // 从WebDAV下载所有文件
  Future<bool> downloadAllFromWebDAV() async {
    if (!_mounted) return false;

    // 保存当前 context 的引用
    final context = _safeContext;
    if (context == null) return false;

    // 检查WebDAV连接
    if (_webdavClient == null || !_isConnected) {
      await _initWebDAV();
      if (_webdavClient == null || !_isConnected) {
        _showErrorSnackBar('WebDAV连接失败，请检查设置');
        return false;
      }
    }

    // 重置进度
    _currentProgress = BackupProgress.initial();
    _updateProgress(totalProgress: 0.0, currentOperation: '准备下载...');

    // 显示进度对话框
    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (dialogContext) => BackupProgressDialog(
              progressStream: progressStream,
              title: '从WebDAV下载',
              onCancel: () {
                // 处理取消操作
                Navigator.of(dialogContext).pop();
                _showErrorSnackBar('下载已取消');
              },
            ),
      );
    }

    try {
      // 获取应用文档目录
      final appDir = await StorageManager.getApplicationDocumentsDirectory();

      // 获取远程文件列表
      _updateProgress(currentOperation: '获取远程文件列表...');

      const remotePath = '/app_backup';
      final remoteFiles = await _listAllRemoteFiles(remotePath);
      int totalFiles = remoteFiles.length;
      int processedFiles = 0;

      // 下载文件
      for (final remoteFile in remoteFiles) {
        if (!_mounted) {
          _closeDialog();
          return false;
        }

        final localPath = path.join(
          appDir.path,
          remoteFile.substring(remotePath.length),
        );

        // 更新进度
        processedFiles++;
        final progress =
            totalFiles > 0 ? (processedFiles / totalFiles).toDouble() : 0.0;
        _updateProgress(
          totalProgress: progress,
          currentOperation: '下载文件 ($processedFiles/$totalFiles)',
          recentFile: remoteFile.substring(remotePath.length),
        );

        // 确保本地目录存在
        final localDir = path.dirname(localPath);
        final dirFile = Directory(localDir);
        if (!await dirFile.exists()) {
          await dirFile.create(recursive: true);
        }

        // 下载文件（带重试）
        bool downloadSuccess = false;
        int retryCount = 0;
        Exception? lastError;

        while (!downloadSuccess && retryCount < maxRetries) {
          try {
            await _webdavClient!.read2File(remoteFile, localPath);
            downloadSuccess = true;
          } catch (e) {
            lastError = e as Exception;
            retryCount++;
            if (retryCount < maxRetries) {
              _updateProgress(
                currentOperation: '下载失败，正在重试 ($retryCount/$maxRetries)...',
                recentFile: remoteFile.substring(remotePath.length),
              );
              await Future.delayed(retryDelay);
            }
          }
        }

        if (!downloadSuccess) {
          throw lastError ?? Exception('下载失败，已重试 $maxRetries 次');
        }

        // 让出CPU时间片
        await Future.delayed(Duration.zero);
      }

      // 下载完成
      _updateProgress(totalProgress: 1.0, currentOperation: '下载完成');

      // 关闭进度对话框
      _closeDialog();

      // 显示成功消息
      _showSuccessSnackBar('下载完成，共下载 $totalFiles 个文件');
      return true;
    } catch (e) {
      debugPrint('下载失败: $e');
      _closeDialog();
      _showErrorSnackBar('下载失败: $e');
      return false;
    }
  }
}
