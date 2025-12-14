import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as path;
import 'package:Memento/core/storage/storage_manager.dart';
import '../models/app_store_models.dart';
import '../models/webview_card.dart';
import '../services/card_manager.dart';
import '../services/app_store_manager.dart';

/// 下载管理器
///
/// 负责：
/// - 文件列表获取
/// - 队列下载（并发控制）
/// - MD5校验
/// - WebViewCard自动创建
/// - 错误处理与回滚
class DownloadManager extends ChangeNotifier {
  final StorageManager _storage;
  final CardManager _cardManager;
  final AppStoreManager _appStoreManager;
  final http.Client _httpClient;

  // 当前安装任务（仅支持单任务）
  InstallTask? _currentTask;

  InstallTask? get currentTask => _currentTask;
  bool get isInstalling => _currentTask != null;

  DownloadManager({
    required StorageManager storage,
    required CardManager cardManager,
    required AppStoreManager appStoreManager,
  })  : _storage = storage,
        _cardManager = cardManager,
        _appStoreManager = appStoreManager,
        _httpClient = http.Client();

  /// 开始安装应用
  Future<void> installApp(MiniApp app) async {
    debugPrint('🚀 [DownloadManager] 开始安装应用: ${app.title} (id: ${app.id}, version: ${app.version})');

    if (_currentTask != null) {
      debugPrint('❌ [DownloadManager] 另一个安装任务正在进行中');
      throw Exception('Another installation is in progress');
    }

    Directory? appDir;
    try {
      // 1. 获取对应源的 baseUrl
      debugPrint('📡 [DownloadManager] 步骤1: 查找源信息 (sourceId: ${app.sourceId})');
      final source = _appStoreManager.sources.firstWhere(
        (s) => s.id == app.sourceId,
        orElse: () {
          debugPrint('❌ [DownloadManager] 源未找到: ${app.sourceId}');
          throw Exception('Source not found');
        },
      );
      debugPrint('✅ [DownloadManager] 找到源: ${source.name} (baseUrl: ${source.baseUrl})');

      // 2. 获取文件列表
      debugPrint('📋 [DownloadManager] 步骤2: 获取文件列表 (filesUrl: ${app.filesUrl})');
      final files = await _fetchFileList(app.filesUrl, source.baseUrl);
      debugPrint('✅ [DownloadManager] 文件列表获取成功，共 ${files.length} 个文件');

      // 3. 创建安装任务
      debugPrint('📦 [DownloadManager] 步骤3: 创建安装任务');
      _currentTask = InstallTask(
        appId: app.id,
        appName: app.title,
        files: files,
        startTime: DateTime.now(),
      );
      notifyListeners();
      debugPrint('✅ [DownloadManager] 安装任务已创建');

      // 4. 创建应用目录
      debugPrint('📁 [DownloadManager] 步骤4: 创建应用目录');
      appDir = await _getAppDirectory(app.id);
      await appDir.create(recursive: true);
      debugPrint('✅ [DownloadManager] 应用目录已创建: ${appDir.path}');

      // 5. 并发下载所有文件
      debugPrint('⬇️ [DownloadManager] 步骤5: 开始下载文件 (总计 ${files.length} 个)');
      await _downloadFilesConcurrently(appDir, files, source, app.id);
      debugPrint('✅ [DownloadManager] 所有文件下载完成');

      // 6. 创建WebViewCard
      debugPrint('🃏 [DownloadManager] 步骤6: 创建 WebViewCard');
      _currentTask!.status = InstallTaskStatus.installing;
      notifyListeners();

      final cardId = await _createCard(app);
      debugPrint('✅ [DownloadManager] WebViewCard 已创建 (cardId: $cardId)');

      // 7. 标记为已安装
      debugPrint('💾 [DownloadManager] 步骤7: 标记应用为已安装');
      await _appStoreManager.markAsInstalled(
        app.id,
        app.version,
        app.sourceId,
        cardId,
      );
      debugPrint('✅ [DownloadManager] 应用已标记为已安装');

      // 8. 完成
      _currentTask!.status = InstallTaskStatus.completed;
      notifyListeners();
      debugPrint('🎉 [DownloadManager] 安装完成: ${app.title}');

      // 延迟清空任务
      Future.delayed(const Duration(seconds: 2), () {
        _currentTask = null;
        notifyListeners();
      });
    } catch (e, stackTrace) {
      debugPrint('❌ [DownloadManager] 安装失败: $e');
      debugPrint('📚 [DownloadManager] 堆栈跟踪:\n$stackTrace');

      // 回滚：删除已下载的文件
      if (appDir != null && await appDir.exists()) {
        try {
          debugPrint('🔄 [DownloadManager] 回滚: 删除应用目录 ${appDir.path}');
          await appDir.delete(recursive: true);
          debugPrint('✅ [DownloadManager] 回滚成功');
        } catch (deleteError) {
          debugPrint('❌ [DownloadManager] 回滚失败: $deleteError');
        }
      }

      if (_currentTask != null) {
        _currentTask!.status = InstallTaskStatus.failed;
        _currentTask!.error = e.toString();
        notifyListeners();
      }
      rethrow;
    }
  }

  /// 获取文件列表
  Future<List<AppFile>> _fetchFileList(String filesUrl, String baseUrl) async {
    try {
      // 拼接完整的 URL: {baseUrl}/{filesUrl}
      final fullUrl = '${baseUrl.replaceAll(RegExp(r'\/+$'), '')}/$filesUrl';
      debugPrint('🌐 [DownloadManager] 请求文件列表 URL: $fullUrl');

      final response = await _httpClient.get(
        Uri.parse(fullUrl),
      ).timeout(const Duration(seconds: 30));

      debugPrint('📊 [DownloadManager] 响应状态码: ${response.statusCode}');

      if (response.statusCode != 200) {
        debugPrint('❌ [DownloadManager] HTTP 错误: ${response.statusCode}');
        throw Exception('HTTP ${response.statusCode}');
      }

      final List<dynamic> jsonList = json.decode(utf8.decode(response.bodyBytes));
      final files = jsonList.map((json) => AppFile.fromJson(json as Map<String, dynamic>)).toList();

      debugPrint('✅ [DownloadManager] 解析文件列表成功，共 ${files.length} 个文件:');
      for (var i = 0; i < files.length; i++) {
        final file = files[i];
        debugPrint('   ${i + 1}. ${file.path} (${_formatBytes(file.size)}, MD5: ${file.md5})');
      }

      return files;
    } on SocketException catch (e) {
      debugPrint('❌ [DownloadManager] 网络错误 (SocketException): $e');
      throw Exception('Network error: Failed to fetch file list');
    } on http.ClientException catch (e) {
      debugPrint('❌ [DownloadManager] 客户端错误 (ClientException): $e');
      throw Exception('Network error: Failed to connect');
    } catch (e) {
      debugPrint('❌ [DownloadManager] 获取文件列表失败: $e');
      throw Exception('Failed to fetch file list: $e');
    }
  }

  /// 格式化字节大小
  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// 并发下载文件（最多3个并发）
  Future<void> _downloadFilesConcurrently(Directory appDir, List<AppFile> files, AppStoreSource source, String appId) async {
    const maxConcurrency = 3;
    final tasks = <Future>[];

    debugPrint('⚡ [DownloadManager] 并发下载设置: 最大并发数 = $maxConcurrency');

    for (var i = 0; i < files.length; i += maxConcurrency) {
      final batch = files.skip(i).take(maxConcurrency).toList();
      final batchNum = (i ~/ maxConcurrency) + 1;
      final totalBatches = (files.length + maxConcurrency - 1) ~/ maxConcurrency;

      debugPrint('📦 [DownloadManager] 处理批次 $batchNum/$totalBatches (${batch.length} 个文件)');
      tasks.clear();

      for (var file in batch) {
        tasks.add(_downloadFile(appDir, file, source, appId).then((_) {
          _currentTask!.completedFiles++;
          notifyListeners();
          debugPrint('✅ [DownloadManager] 进度: ${_currentTask!.completedFiles}/${files.length} 文件已完成');
        }));
      }

      await Future.wait(tasks);
      debugPrint('✅ [DownloadManager] 批次 $batchNum 完成');
    }
  }

  /// 下载单个文件
  Future<void> _downloadFile(Directory appDir, AppFile file, AppStoreSource source, String appId) async {
    debugPrint('⬇️ [DownloadManager] 开始下载: ${file.path} (${_formatBytes(file.size)})');

    file.status = DownloadStatus.downloading;
    notifyListeners();

    File? localFile;
    try {
      // 构建完整URL: {source.baseUrl}/{appId}/{file.path}
      final fileUrl = '${source.baseUrl.replaceAll(RegExp(r'\/+$'), '')}/$appId/${file.path}';
      debugPrint('🌐 [DownloadManager] 下载 URL: $fileUrl');

      // 流式下载 + MD5计算
      final request = http.Request('GET', Uri.parse(fileUrl));
      final response = await _httpClient.send(request).timeout(const Duration(minutes: 5));

      debugPrint('📊 [DownloadManager] ${file.path} 响应状态: ${response.statusCode}');

      if (response.statusCode != 200) {
        debugPrint('❌ [DownloadManager] ${file.path} HTTP 错误: ${response.statusCode}');
        throw Exception('HTTP ${response.statusCode}');
      }

      // 创建本地文件
      localFile = File('${appDir.path}/${file.path}');
      await localFile.parent.create(recursive: true);
      debugPrint('📁 [DownloadManager] ${file.path} 本地路径: ${localFile.path}');

      // 流式写入并计算MD5
      final sink = localFile.openWrite();
      final List<int> bytes = [];

      await for (var chunk in response.stream) {
        sink.add(chunk);
        bytes.addAll(chunk);
        file.downloadedBytes += chunk.length;
        notifyListeners();
      }

      await sink.close();
      debugPrint('💾 [DownloadManager] ${file.path} 下载完成，实际大小: ${_formatBytes(bytes.length)}');

      // 校验MD5
      file.status = DownloadStatus.verifying;
      notifyListeners();
      debugPrint('🔍 [DownloadManager] ${file.path} 开始 MD5 校验');

      final digest = md5.convert(bytes);
      final calculatedMd5 = digest.toString();
      debugPrint('🔐 [DownloadManager] ${file.path} MD5 计算: $calculatedMd5 (期望: ${file.md5})');

      if (calculatedMd5 != file.md5.toLowerCase()) {
        debugPrint('❌ [DownloadManager] ${file.path} MD5 不匹配！');
        throw Exception('MD5 mismatch: expected ${file.md5}, got $calculatedMd5');
      }

      file.status = DownloadStatus.completed;
      notifyListeners();
      debugPrint('✅ [DownloadManager] ${file.path} MD5 校验通过');
    } on SocketException catch (e) {
      debugPrint('❌ [DownloadManager] ${file.path} 网络错误: $e');
      file.status = DownloadStatus.failed;
      file.error = 'Network error';
      notifyListeners();
      throw Exception('Network error downloading ${file.path}');
    } on TimeoutException catch (e) {
      debugPrint('❌ [DownloadManager] ${file.path} 下载超时: $e');
      file.status = DownloadStatus.failed;
      file.error = 'Timeout';
      notifyListeners();
      throw Exception('Download timeout for ${file.path}');
    } catch (e) {
      debugPrint('❌ [DownloadManager] ${file.path} 下载失败: $e');
      file.status = DownloadStatus.failed;
      file.error = e.toString();
      notifyListeners();

      // 删除损坏的文件
      if (localFile != null && await localFile.exists()) {
        try {
          debugPrint('🗑️ [DownloadManager] ${file.path} 删除损坏文件');
          await localFile.delete();
        } catch (_) {}
      }

      throw Exception('Failed to download ${file.path}: $e');
    }
  }

  /// 创建WebViewCard
  Future<String> _createCard(MiniApp app) async {
    try {
      // 查找入口文件（index.html）
      final appDir = await _getAppDirectory(app.id);
      final indexFile = File('${appDir.path}/index.html');

      debugPrint('🔍 [DownloadManager] 检查入口文件: ${indexFile.path}');

      if (!await indexFile.exists()) {
        debugPrint('❌ [DownloadManager] 入口文件不存在: ${indexFile.path}');
        throw Exception('Entry file index.html not found');
      }

      debugPrint('✅ [DownloadManager] 入口文件存在');

      // 创建卡片
      final cardUrl = 'http://localhost:8080/${app.id}/index.html';
      debugPrint('🃏 [DownloadManager] 创建卡片，URL: $cardUrl');

      final card = await _cardManager.addCard(
        title: app.title,
        url: cardUrl,
        type: CardType.url,
        iconUrl: app.icon,
        tags: app.tags,
        description: app.desc,
      );

      debugPrint('✅ [DownloadManager] 卡片创建成功 (ID: ${card.id})');
      return card.id;
    } catch (e) {
      debugPrint('❌ [DownloadManager] 创建卡片失败: $e');
      throw Exception('Failed to create card: $e');
    }
  }

  /// 取消安装
  void cancelInstall() {
    if (_currentTask != null) {
      _currentTask!.status = InstallTaskStatus.failed;
      _currentTask!.error = 'Cancelled by user';
      _currentTask = null;
      notifyListeners();
    }
  }

  /// 获取应用目录
  Future<Directory> _getAppDirectory(String appId) async {
    // 使用与 card_manager 一致的路径获取方式
    final appDataDir = await _storage.getApplicationDataDirectory();
    final pluginPath = _storage.getPluginStoragePath('webview');
    final httpRoot = path.join(appDataDir.path, pluginPath, 'http_server');
    // 构建完整路径：app_data/webview/http_server/appId
    return Directory(path.join(httpRoot, appId));
  }

  @override
  void dispose() {
    _httpClient.close();
    super.dispose();
  }
}
