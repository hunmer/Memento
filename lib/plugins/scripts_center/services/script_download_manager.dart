import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as path;
import 'package:Memento/plugins/scripts_center/models/script_store_models.dart';
import 'package:Memento/plugins/scripts_center/services/script_loader.dart';
import 'package:Memento/plugins/scripts_center/services/script_store_manager.dart';

/// 脚本下载管理器
///
/// 负责：
/// - 文件列表获取
/// - 队列下载（并发控制）
/// - MD5校验
/// - 脚本文件安装
/// - 错误处理与回滚
class ScriptDownloadManager extends ChangeNotifier {
  final ScriptLoader _scriptLoader;
  final ScriptStoreManager _scriptStoreManager;
  final http.Client _httpClient;

  // 当前安装任务（仅支持单任务）
  ScriptInstallTask? _currentTask;

  ScriptInstallTask? get currentTask => _currentTask;
  bool get isInstalling => _currentTask != null;

  ScriptDownloadManager({
    required ScriptLoader scriptLoader,
    required ScriptStoreManager scriptStoreManager,
  })  : _scriptLoader = scriptLoader,
        _scriptStoreManager = scriptStoreManager,
        _httpClient = http.Client();

  /// 开始安装脚本
  Future<void> installScript(ScriptStoreItem script) async {
    debugPrint('🚀 [ScriptDownloadManager] 开始安装脚本: ${script.name} (id: ${script.id}, version: ${script.version})');

    if (_currentTask != null) {
      debugPrint('❌ [ScriptDownloadManager] 另一个安装任务正在进行中');
      throw Exception('Another installation is in progress');
    }

    Directory? scriptDir;
    try {
      // 1. 获取对应源的 baseUrl
      debugPrint('📡 [ScriptDownloadManager] 步骤1: 查找源信息 (sourceId: ${script.sourceId})');
      final source = _scriptStoreManager.sources.firstWhere(
        (s) => s.id == script.sourceId,
        orElse: () {
          debugPrint('❌ [ScriptDownloadManager] 源未找到: ${script.sourceId}');
          throw Exception('Source not found');
        },
      );
      debugPrint('✅ [ScriptDownloadManager] 找到源: ${source.name} (baseUrl: ${source.baseUrl})');

      // 2. 获取文件列表
      debugPrint('📋 [ScriptDownloadManager] 步骤2: 获取文件列表 (filesUrl: ${script.filesUrl})');
      final files = await _fetchFileList(script.filesUrl, source.baseUrl);
      debugPrint('✅ [ScriptDownloadManager] 文件列表获取成功，共 ${files.length} 个文件');

      // 3. 创建安装任务
      debugPrint('📦 [ScriptDownloadManager] 步骤3: 创建安装任务');
      _currentTask = ScriptInstallTask(
        scriptId: script.id,
        scriptName: script.name,
        files: files,
        startTime: DateTime.now(),
      );
      notifyListeners();
      debugPrint('✅ [ScriptDownloadManager] 安装任务已创建');

      // 4. 创建脚本目录
      debugPrint('📁 [ScriptDownloadManager] 步骤4: 创建脚本目录');
      final scriptsPath = await _scriptLoader.getScriptsDirectory();
      scriptDir = Directory(path.join(scriptsPath, script.id));
      await scriptDir.create(recursive: true);
      debugPrint('✅ [ScriptDownloadManager] 脚本目录已创建: ${scriptDir.path}');

      // 5. 并发下载所有文件
      debugPrint('⬇️ [ScriptDownloadManager] 步骤5: 开始下载文件 (总计 ${files.length} 个)');
      await _downloadFilesConcurrently(scriptDir, files, source, script.id);
      debugPrint('✅ [ScriptDownloadManager] 所有文件下载完成');

      // 6. 完成
      _currentTask!.status = ScriptInstallTaskStatus.completed;
      notifyListeners();
      debugPrint('🎉 [ScriptDownloadManager] 下载完成');

      // 7. 标记为已安装
      debugPrint('💾 [ScriptDownloadManager] 步骤7: 标记脚本为已安装');
      await _scriptStoreManager.markAsInstalled(
        script.id,
        script.version,
        script.sourceId,
      );
      debugPrint('✅ [ScriptDownloadManager] 脚本已标记为已安装');

      // 延迟清空任务
      Future.delayed(const Duration(seconds: 2), () {
        _currentTask = null;
        notifyListeners();
      });
    } catch (e, stackTrace) {
      debugPrint('❌ [ScriptDownloadManager] 安装失败: $e');
      debugPrint('📚 [ScriptDownloadManager] 堆栈跟踪:\n$stackTrace');

      // 回滚：删除已下载的文件
      if (scriptDir != null && await scriptDir.exists()) {
        try {
          debugPrint('🔄 [ScriptDownloadManager] 回滚: 删除脚本目录 ${scriptDir.path}');
          await scriptDir.delete(recursive: true);
          debugPrint('✅ [ScriptDownloadManager] 回滚成功');
        } catch (deleteError) {
          debugPrint('❌ [ScriptDownloadManager] 回滚失败: $deleteError');
        }
      }

      if (_currentTask != null) {
        _currentTask!.status = ScriptInstallTaskStatus.failed;
        _currentTask!.error = e.toString();
        notifyListeners();
      }
      rethrow;
    }
  }

  /// 获取文件列表
  Future<List<ScriptFile>> _fetchFileList(String filesUrl, String baseUrl) async {
    try {
      // 拼接完整的 URL: {baseUrl}/{filesUrl}
      final fullUrl = '${baseUrl.replaceAll(RegExp(r'\/+$'), '')}/$filesUrl';
      debugPrint('🌐 [ScriptDownloadManager] 请求文件列表 URL: $fullUrl');

      final response = await _httpClient.get(
        Uri.parse(fullUrl),
      ).timeout(const Duration(seconds: 30));

      debugPrint('📊 [ScriptDownloadManager] 响应状态码: ${response.statusCode}');

      if (response.statusCode != 200) {
        debugPrint('❌ [ScriptDownloadManager] HTTP 错误: ${response.statusCode}');
        throw Exception('HTTP ${response.statusCode}');
      }

      final List<dynamic> jsonList = json.decode(utf8.decode(response.bodyBytes));
      final files = jsonList.map((json) => ScriptFile.fromJson(json as Map<String, dynamic>)).toList();

      debugPrint('✅ [ScriptDownloadManager] 解析文件列表成功，共 ${files.length} 个文件:');
      for (var i = 0; i < files.length; i++) {
        final file = files[i];
        debugPrint('   ${i + 1}. ${file.path} (${_formatBytes(file.size)}, MD5: ${file.md5})');
      }

      return files;
    } on SocketException catch (e) {
      debugPrint('❌ [ScriptDownloadManager] 网络错误 (SocketException): $e');
      throw Exception('Network error: Failed to fetch file list');
    } on http.ClientException catch (e) {
      debugPrint('❌ [ScriptDownloadManager] 客户端错误 (ClientException): $e');
      throw Exception('Network error: Failed to connect');
    } catch (e) {
      debugPrint('❌ [ScriptDownloadManager] 获取文件列表失败: $e');
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
  Future<void> _downloadFilesConcurrently(Directory scriptDir, List<ScriptFile> files, ScriptStoreSource source, String scriptId) async {
    const maxConcurrency = 3;
    final tasks = <Future>[];

    debugPrint('⚡ [ScriptDownloadManager] 并发下载设置: 最大并发数 = $maxConcurrency');

    for (var i = 0; i < files.length; i += maxConcurrency) {
      final batch = files.skip(i).take(maxConcurrency).toList();
      final batchNum = (i ~/ maxConcurrency) + 1;
      final totalBatches = (files.length + maxConcurrency - 1) ~/ maxConcurrency;

      debugPrint('📦 [ScriptDownloadManager] 处理批次 $batchNum/$totalBatches (${batch.length} 个文件)');
      tasks.clear();

      for (var file in batch) {
        tasks.add(_downloadFile(scriptDir, file, source, scriptId).then((_) {
          _currentTask!.completedFiles++;
          notifyListeners();
          debugPrint('✅ [ScriptDownloadManager] 进度: ${_currentTask!.completedFiles}/${files.length} 文件已完成');
        }));
      }

      await Future.wait(tasks);
      debugPrint('✅ [ScriptDownloadManager] 批次 $batchNum 完成');
    }
  }

  /// 下载单个文件
  Future<void> _downloadFile(Directory scriptDir, ScriptFile file, ScriptStoreSource source, String scriptId) async {
    debugPrint('⬇️ [ScriptDownloadManager] 开始下载: ${file.path} (${_formatBytes(file.size)})');

    file.status = ScriptDownloadStatus.downloading;
    notifyListeners();

    File? localFile;
    try {
      // 构建完整URL: {source.baseUrl}/{scriptId}/{file.path}
      final fileUrl = '${source.baseUrl.replaceAll(RegExp(r'\/+$'), '')}/$scriptId/${file.path}';
      debugPrint('🌐 [ScriptDownloadManager] 下载 URL: $fileUrl');

      // 流式下载 + MD5计算
      final request = http.Request('GET', Uri.parse(fileUrl));
      final response = await _httpClient.send(request).timeout(const Duration(minutes: 5));

      debugPrint('📊 [ScriptDownloadManager] ${file.path} 响应状态: ${response.statusCode}');

      if (response.statusCode != 200) {
        debugPrint('❌ [ScriptDownloadManager] ${file.path} HTTP 错误: ${response.statusCode}');
        throw Exception('HTTP ${response.statusCode}');
      }

      // 创建本地文件
      localFile = File('${scriptDir.path}/${file.path}');
      await localFile.parent.create(recursive: true);
      debugPrint('📁 [ScriptDownloadManager] ${file.path} 本地路径: ${localFile.path}');

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
      debugPrint('💾 [ScriptDownloadManager] ${file.path} 下载完成，实际大小: ${_formatBytes(bytes.length)}');

      // 校验MD5
      file.status = ScriptDownloadStatus.verifying;
      notifyListeners();
      debugPrint('🔍 [ScriptDownloadManager] ${file.path} 开始 MD5 校验');

      final digest = md5.convert(bytes);
      final calculatedMd5 = digest.toString();
      debugPrint('🔐 [ScriptDownloadManager] ${file.path} MD5 计算: $calculatedMd5 (期望: ${file.md5})');

      if (calculatedMd5 != file.md5.toLowerCase()) {
        debugPrint('❌ [ScriptDownloadManager] ${file.path} MD5 不匹配！');
        throw Exception('MD5 mismatch: expected ${file.md5}, got $calculatedMd5');
      }

      file.status = ScriptDownloadStatus.completed;
      notifyListeners();
      debugPrint('✅ [ScriptDownloadManager] ${file.path} MD5 校验通过');
    } on SocketException catch (e) {
      debugPrint('❌ [ScriptDownloadManager] ${file.path} 网络错误: $e');
      file.status = ScriptDownloadStatus.failed;
      file.error = 'Network error';
      notifyListeners();
      throw Exception('Network error downloading ${file.path}');
    } on TimeoutException catch (e) {
      debugPrint('❌ [ScriptDownloadManager] ${file.path} 下载超时: $e');
      file.status = ScriptDownloadStatus.failed;
      file.error = 'Timeout';
      notifyListeners();
      throw Exception('Download timeout for ${file.path}');
    } catch (e) {
      debugPrint('❌ [ScriptDownloadManager] ${file.path} 下载失败: $e');
      file.status = ScriptDownloadStatus.failed;
      file.error = e.toString();
      notifyListeners();

      // 删除损坏的文件
      if (localFile != null && await localFile.exists()) {
        try {
          debugPrint('🗑️ [ScriptDownloadManager] ${file.path} 删除损坏文件');
          await localFile.delete();
        } catch (_) {}
      }

      throw Exception('Failed to download ${file.path}: $e');
    }
  }

  /// 取消安装
  void cancelInstall() {
    if (_currentTask != null) {
      _currentTask!.status = ScriptInstallTaskStatus.failed;
      _currentTask!.error = 'Cancelled by user';
      _currentTask = null;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _httpClient.close();
    super.dispose();
  }
}
