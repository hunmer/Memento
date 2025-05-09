import 'dart:io';
import 'package:flutter/material.dart';
import 'package:webdav_client/webdav_client.dart' as webdav;
import 'package:path_provider/path_provider.dart';
import '../../../core/storage/storage_manager.dart';
import 'package:mime/mime.dart';
import 'dart:async';
import '../widgets/backup_progress_dialog.dart';

class WebDAVController {
  webdav.Client? _client;
  bool _isConnected = false;
  final _progressController = StreamController<BackupProgress>.broadcast();
  Stream<BackupProgress> get progressStream => _progressController.stream;

  WebDAVController();

  void dispose() {
    _progressController.close();
  }

  bool get isConnected => _isConnected;

  // 连接到WebDAV服务器
  Future<bool> connect({
    required String url,
    required String username,
    required String password,
    required String dataPath,
  }) async {
    try {
      // 确保URL格式正确
      if (!url.startsWith('http://') && !url.startsWith('https://')) {
        throw FormatException('URL必须以 http:// 或 https:// 开头');
      }

      final client = webdav.newClient(
        url,
        user: username,
        password: password,
        debug: false,
      );

      // 测试连接
      await client.ping();

      // 确保远程数据目录存在
      try {
        await client.mkdir(dataPath);
      } catch (e) {
        // 目录可能已经存在，忽略错误
      }

      _client = client;
      _isConnected = true;

      // 保存连接信息
      final StorageManager storageManager = StorageManager();
      // 确保 StorageManager 已初始化
      await storageManager.initialize();

      await storageManager.saveWebDAVConfig(
        url: url,
        username: username,
        password: password,
        dataPath: dataPath,
        enabled: true,
      );

      return true;
    } catch (e) {
      String errorMessage = '';
      if (e.toString().contains('Operation not permitted')) {
        errorMessage =
            '连接被系统限制，请检查：\n'
            '1. 如果是本地服务器，请确保应用有访问本地网络的权限\n'
            '2. 如果使用HTTP，请确保允许非安全连接\n'
            '3. 检查服务器防火墙设置';
      } else if (e.toString().contains('Connection refused')) {
        errorMessage =
            '连接被拒绝，请检查：\n'
            '1. 服务器是否已启动\n'
            '2. 端口号是否正确\n'
            '3. 防火墙是否允许该连接';
      } else if (e.toString().contains('Connection timed out')) {
        errorMessage =
            '连接超时，请检查：\n'
            '1. 网络连接是否正常\n'
            '2. 服务器是否响应过慢\n'
            '3. 检查服务器地址是否正确';
      } else {
        errorMessage = e.toString();
      }

      // 只记录错误日志，不显示SnackBar
      debugPrint('WebDAV连接失败: $errorMessage');
      _isConnected = false;
      return false;
    }
  }

  // 断开WebDAV连接
  Future<void> disconnect() async {
    _client = null;
    _isConnected = false;

    final StorageManager storageManager = StorageManager();
    await storageManager.saveWebDAVConfig(
      url: '',
      username: '',
      password: '',
      dataPath: '',
      enabled: false,
    );
  }

  // 从本地同步到WebDAV
  Future<bool> syncLocalToWebDAV(BuildContext context) async {
    if (!_isConnected || _client == null) {
      debugPrint('WebDAV未连接或客户端为空');
      return false;
    }

    try {
      final StorageManager storageManager = StorageManager();
      final config = await storageManager.readJson('webdav_config.json');
      final remotePath = config['dataPath'] as String;

      // 获取本地应用数据目录
      final directory = await getApplicationDocumentsDirectory();
      final localPath = '${directory.path}/app_data';
      final localDir = Directory(localPath);

      // 检查本地目录是否存在
      if (!await localDir.exists()) {
        debugPrint('本地目录不存在：$localPath');
        await localDir.create(recursive: true);
      }

      // 检查本地目录是否为空
      final entities = await localDir.list().toList();
      if (entities.isEmpty) {
        debugPrint('本地目录为空：$localPath');
        return false;
      }

      debugPrint('开始上传本地文件，源目录：$localPath，目标路径：$remotePath');
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
                  Navigator.of(dialogContext).pop();
                  if (dialogContext.mounted) {
                    ScaffoldMessenger.of(
                      dialogContext,
                    ).showSnackBar(const SnackBar(content: Text('下载已取消')));
                  }
                },
              ),
        );
      }
      // 更新初始进度
      _progressController.add(
        BackupProgress(
          totalProgress: 0,
          currentOperation: '准备上传...',
          recentFiles: [],
        ),
      );

      // 递归上传本地文件到WebDAV
      final result = await _uploadDirectory(localDir, '', remotePath);

      // 关闭进度对话框
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      return result;
    } catch (e) {
      debugPrint('同步本地到WebDAV失败: $e');

      // 只记录错误日志，不显示SnackBar
      if (!context.mounted) return false;
      return false;
    }
  }

  // 递归上传目录
  Future<bool> _uploadDirectory(
    Directory dir,
    String relativePath,
    String remotePath,
  ) async {
    try {
      final entities = await dir.list().toList();
      debugPrint('正在处理目录：${dir.path}，包含 ${entities.length} 个项目');

      // 计算总文件数
      int totalFiles = 0;
      int processedFiles = 0;
      for (var entity in entities) {
        if (entity is File) {
          totalFiles++;
        } else if (entity is Directory) {
          final subFiles =
              await entity.list(recursive: true).where((e) => e is File).length;
          totalFiles += subFiles;
        }
      }

      for (var entity in entities) {
        final name = entity.path.split('/').last;
        final currentRelativePath =
            relativePath.isEmpty ? name : '$relativePath/$name';

        if (entity is File) {
          // 上传文件
          final remoteFilePath = '$remotePath/$currentRelativePath';
          debugPrint('正在上传文件：${entity.path} -> $remoteFilePath');

          // 更新进度
          processedFiles++;
          final progress =
              totalFiles > 0 ? (processedFiles / totalFiles).toDouble() : 0.0;
          _progressController.add(
            BackupProgress(
              totalProgress: progress,
              currentOperation: '正在上传 ($processedFiles/$totalFiles)',
              recentFiles: [currentRelativePath],
            ),
          );

          try {
            // 获取文件的MIME类型
            String? mimeType = lookupMimeType(entity.path);
            mimeType ??= 'application/octet-stream'; // 默认MIME类型

            debugPrint('上传文件MIME类型: $mimeType');

            // 设置请求头
            _client!.setHeaders({'Content-Type': mimeType});

            // 直接使用 writeFromFile 方法上传
            await _client!.writeFromFile(entity.path, remoteFilePath);
            debugPrint('文件上传成功：$remoteFilePath');
          } catch (e) {
            debugPrint('文件上传失败：$remoteFilePath, 错误：$e');
            return false;
          }
        } else if (entity is Directory) {
          // 创建远程目录
          final remoteDirPath = '$remotePath/$currentRelativePath';
          try {
            debugPrint('创建远程目录：$remoteDirPath');
            await _client!.mkdir(remoteDirPath);
          } catch (e) {
            // 目录可能已存在，忽略错误
            debugPrint('目录可能已存在：$remoteDirPath');
          }

          // 递归处理子目录，注意：这里传递正确的远程目录路径
          final subDirResult = await _uploadDirectory(
            entity,
            currentRelativePath,
            remotePath, // 保持根路径不变，相对路径会在递归中构建
          );
          if (!subDirResult) {
            debugPrint('处理子目录失败：${entity.path}');
            return false;
          }
        }
      }
      debugPrint('目录 ${dir.path} 处理完成');
      return true;
    } catch (e) {
      debugPrint('上传目录失败: $e');
      return false;
    }
  }

  // 从WebDAV同步到本地
  Future<bool> syncWebDAVToLocal(BuildContext context) async {
    if (!_isConnected || _client == null) {
      return false;
    }

    try {
      final StorageManager storageManager = StorageManager();
      final config = await storageManager.readJson('webdav_config.json');
      final remotePath = config['dataPath'] as String;

      // 获取本地应用数据目录
      final directory = await getApplicationDocumentsDirectory();
      final localPath = '${directory.path}/app_data';

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
                  Navigator.of(dialogContext).pop();
                  if (dialogContext.mounted) {
                    ScaffoldMessenger.of(
                      dialogContext,
                    ).showSnackBar(const SnackBar(content: Text('下载已取消')));
                  }
                },
              ),
        );
      }

      // 更新初始进度
      _progressController.add(
        BackupProgress(
          totalProgress: 0,
          currentOperation: '准备下载...',
          recentFiles: [],
        ),
      );

      // 递归下载WebDAV文件到本地
      final result = await _downloadDirectory(remotePath, Directory(localPath));

      // 关闭进度对话框
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      return result;
    } catch (e) {
      debugPrint('同步WebDAV到本地失败: $e');

      // 只记录错误日志，不显示SnackBar
      if (!context.mounted) return false;
      return false;
    }
  }

  // 递归下载目录
  Future<bool> _downloadDirectory(String remotePath, Directory localDir) async {
    try {
      // 确保本地目录存在
      if (!await localDir.exists()) {
        await localDir.create(recursive: true);
      }

      // 更新进度
      _progressController.add(
        BackupProgress(
          totalProgress: 0,
          currentOperation: '扫描远程文件...',
          recentFiles: [],
        ),
      );

      // 列出远程目录内容
      await _client!.readDir(remotePath);

      // 计算总文件数（包括子目录中的文件）
      int totalFiles = 0;
      int processedFiles = 0;

      Future<void> countFiles(String path) async {
        final items = await _client!.readDir(path);
        for (var item in items) {
          if (item.name == null) continue;
          if (item.isDir ?? false) {
            await countFiles('$path/${item.name!}');
          } else {
            totalFiles++;
          }
        }
      }

      await countFiles(remotePath);

      // 更新进度
      _progressController.add(
        BackupProgress(
          totalProgress: 0,
          currentOperation: '开始下载 ($totalFiles 个文件)...',
          recentFiles: [],
        ),
      );

      Future<bool> downloadFiles(String path, Directory dir) async {
        final items = await _client!.readDir(path);

        for (var file in items) {
          final name = file.name;
          if (name == null) continue;

          final localFilePath = '${dir.path}/$name';
          final remoteFilePath = '$path/$name';

          if (file.isDir ?? false) {
            // 处理目录
            final newLocalDir = Directory(localFilePath);
            if (!await downloadFiles(remoteFilePath, newLocalDir)) {
              return false;
            }
          } else {
            // 更新进度
            processedFiles++;
            final progress =
                totalFiles > 0 ? (processedFiles / totalFiles).toDouble() : 0.0;
            _progressController.add(
              BackupProgress(
                totalProgress: progress,
                currentOperation: '正在下载 ($processedFiles/$totalFiles)',
                recentFiles: [remoteFilePath.substring(remotePath.length + 1)],
              ),
            );

            // 下载文件到本地
            await _client!.read2File(remoteFilePath, localFilePath);
          }
        }
        return true;
      }

      return await downloadFiles(remotePath, localDir);
    } catch (e) {
      debugPrint('下载目录失败: $e');
      return false;
    }
  }

  // 检查WebDAV连接配置
  Future<Map<String, dynamic>?> getWebDAVConfig() async {
    try {
      final StorageManager storageManager = StorageManager();
      await storageManager.initialize();

      final config = await storageManager.getWebDAVConfig();
      if (config != null && config['isConnected'] == true) {
        // 如果有保存的连接，尝试重新连接
        final connected = await connect(
          url: config['url'],
          username: config['username'],
          password: config['password'],
          dataPath: config['dataPath'],
        );

        if (connected) {
          return config;
        }
      }
      return config;
    } catch (e) {
      debugPrint('获取WebDAV配置失败: $e');
    }
    return null;
  }

  // 监控文件变化并同步到WebDAV
  StreamSubscription<FileSystemEvent>? _fileWatcher;

  // 启动文件监控
  Future<bool> startFileMonitoring() async {
    if (!_isConnected || _client == null) {
      debugPrint('WebDAV未连接，无法启动文件监控');
      return false;
    }

    try {
      // 获取本地应用数据目录
      final directory = await getApplicationDocumentsDirectory();
      final localPath = '${directory.path}/app_data';
      final localDir = Directory(localPath);

      // 确保目录存在
      if (!await localDir.exists()) {
        await localDir.create(recursive: true);
      }

      // 停止现有监控
      await stopFileMonitoring();

      // 清空待处理的文件变更
      _pendingFileChanges.clear();
      _isProcessingChanges = false;
      if (_debounceTimer != null) {
        _debounceTimer!.cancel();
        _debounceTimer = null;
      }

      // 启动新监控
      _fileWatcher = localDir.watch(recursive: true).listen((event) {
        _handleFileChange(event);
      });

      debugPrint('文件监控已启动，监控目录: $localPath');
      return true;
    } catch (e) {
      debugPrint('启动文件监控失败: $e');
      return false;
    }
  }

  // 停止文件监控
  Future<void> stopFileMonitoring() async {
    // 取消文件监控
    if (_fileWatcher != null) {
      await _fileWatcher!.cancel();
      _fileWatcher = null;
      debugPrint('文件监控已停止');
    }

    // 取消防抖定时器
    if (_debounceTimer != null) {
      _debounceTimer!.cancel();
      _debounceTimer = null;
    }

    // 清空待处理的变更
    _pendingFileChanges.clear();
    _isProcessingChanges = false;
  }

  // 文件变化队列和处理锁
  final Map<String, DateTime> _pendingFileChanges = {};
  bool _isProcessingChanges = false;
  Timer? _debounceTimer;

  // 处理文件变化事件
  void _handleFileChange(FileSystemEvent event) {
    final fileName = event.path.split('/').last;

    // 忽略临时文件、隐藏文件和配置文件
    if (event.path.contains('.tmp') ||
        fileName.startsWith('.') ||
        fileName == 'webdav_config.json') {
      return;
    }

    debugPrint('检测到文件变化: ${event.type} - ${event.path}');

    // 将变更添加到队列，使用最新的时间戳
    _pendingFileChanges[event.path] = DateTime.now();

    // 取消现有定时器
    _debounceTimer?.cancel();

    // 设置防抖定时器，等待文件操作完成后再处理
    _debounceTimer = Timer(const Duration(seconds: 2), () {
      _processFileChanges();
    });
  }

  // 处理文件变化队列
  Future<void> _processFileChanges() async {
    if (_isProcessingChanges || _pendingFileChanges.isEmpty) return;

    _isProcessingChanges = true;

    try {
      // 按时间戳排序，先处理早期的变更
      final sortedPaths =
          _pendingFileChanges.keys.toList()..sort(
            (a, b) =>
                _pendingFileChanges[a]!.compareTo(_pendingFileChanges[b]!),
          );

      for (final path in sortedPaths) {
        // 移除已处理的项目
        final timestamp = _pendingFileChanges.remove(path);
        if (timestamp == null) continue; // 这里的检查是必要的，因为timestamp可能为null

        // 检查文件是否存在决定操作类型
        final file = File(path);
        if (await file.exists()) {
          await _syncFileToWebDAV(path);
        } else {
          await _deleteFileFromWebDAV(path);
        }

        // 每个操作之间稍作延迟，避免并发问题
        await Future.delayed(const Duration(milliseconds: 500));
      }
    } finally {
      _isProcessingChanges = false;

      // 如果处理过程中有新的变更，继续处理
      if (_pendingFileChanges.isNotEmpty) {
        // 稍作延迟再处理
        Timer(const Duration(seconds: 1), () {
          _processFileChanges();
        });
      }
    }
  }

  // 同步单个文件到WebDAV
  Future<void> _syncFileToWebDAV(String localFilePath) async {
    if (!_isConnected || _client == null) return;

    // 检查是否是配置文件
    final fileName = localFilePath.split('/').last;
    if (fileName == 'webdav_config.json') {
      debugPrint('跳过同步配置文件: $fileName');
      return;
    }

    // 添加延迟，避免文件仍在写入过程中
    await Future.delayed(const Duration(milliseconds: 500));

    // 最大重试次数
    const maxRetries = 3;
    int retryCount = 0;

    while (retryCount < maxRetries) {
      try {
        final config = await getWebDAVConfig();
        if (config == null || !config['isConnected']) return;

        final remotePath = config['dataPath'];
        final directory = await getApplicationDocumentsDirectory();
        final localBasePath = '${directory.path}/app_data';

        // 计算相对路径
        final relativePath = localFilePath.substring(localBasePath.length + 1);
        final remoteFilePath = '$remotePath/$relativePath';

        // 确保远程目录存在
        final remoteDir = remoteFilePath.substring(
          0,
          remoteFilePath.lastIndexOf('/'),
        );
        try {
          await _client!.mkdir(remoteDir);
        } catch (e) {
          // 目录可能已存在，忽略错误
        }

        // 上传文件
        final file = File(localFilePath);
        if (await file.exists()) {
          // 检查文件是否可以被读取（不被锁定）
          try {
            final randomAccessFile = await file.open(mode: FileMode.read);
            await randomAccessFile.close();
          } catch (e) {
            debugPrint('文件被锁定，无法读取: $localFilePath');
            // 如果文件被锁定，等待一段时间后重试
            await Future.delayed(const Duration(seconds: 1));
            retryCount++;
            continue;
          }

          // 获取文件的MIME类型
          String? mimeType = lookupMimeType(localFilePath);
          mimeType ??= 'application/octet-stream'; // 默认MIME类型

          // 设置请求头
          _client!.setHeaders({
            'Content-Type': mimeType,
            'Overwrite': 'T', // 覆盖已存在的文件
          });

          // 检查远程文件是否存在
          try {
            final response = await _client!.read(remoteFilePath);
            debugPrint('远程文件已存在，将覆盖: $remoteFilePath');
          } catch (e) {
            // 文件不存在或其他错误，继续上传
            debugPrint('检查远程文件时出错（可能是文件不存在）: $e');
          }

          // 上传文件
          await _client!.writeFromFile(localFilePath, remoteFilePath);
          debugPrint('文件已同步到WebDAV: $remoteFilePath');
          return; // 成功后退出循环
        }
      } catch (e) {
        debugPrint('同步文件到WebDAV失败 (尝试 ${retryCount + 1}/$maxRetries): $e');
        if (e.toString().contains('Locked')) {
          // 如果是锁定错误，等待更长时间
          await Future.delayed(Duration(seconds: 2 * (retryCount + 1)));
        } else {
          // 其他错误，短暂等待
          await Future.delayed(const Duration(seconds: 1));
        }
        retryCount++;
      }
    }

    if (retryCount == maxRetries) {
      debugPrint('同步文件到WebDAV失败: 已达到最大重试次数 $maxRetries');
    }
  }

  // 从WebDAV删除文件
  Future<void> _deleteFileFromWebDAV(String localFilePath) async {
    if (!_isConnected || _client == null) return;

    // 最大重试次数
    const maxRetries = 3;
    int retryCount = 0;

    while (retryCount < maxRetries) {
      try {
        final config = await getWebDAVConfig();
        if (config == null || !config['isConnected']) return;

        final remotePath = config['dataPath'];
        final directory = await getApplicationDocumentsDirectory();
        final localBasePath = '${directory.path}/app_data';

        // 计算相对路径
        final relativePath = localFilePath.substring(localBasePath.length + 1);
        final remoteFilePath = '$remotePath/$relativePath';

        // 检查文件是否存在并尝试删除
        try {
          await _client!.remove(remoteFilePath);
          debugPrint('文件已从WebDAV删除: $remoteFilePath');
          return; // 成功删除后退出
        } catch (e) {
          if (e.toString().contains('404')) {
            debugPrint('远程文件不存在，无需删除: $remoteFilePath');
            return;
          }
          // 其他错误则继续重试
          rethrow;
        }
      } catch (e) {
        debugPrint('从WebDAV删除文件失败 (尝试 ${retryCount + 1}/$maxRetries): $e');
        if (e.toString().contains('Locked')) {
          // 如果是锁定错误，等待更长时间
          await Future.delayed(Duration(seconds: 2 * (retryCount + 1)));
        } else {
          // 其他错误，短暂等待
          await Future.delayed(const Duration(seconds: 1));
        }
        retryCount++;
      }
    }

    if (retryCount == maxRetries) {
      debugPrint('从WebDAV删除文件失败: 已达到最大重试次数 $maxRetries');
    }
  }
}
