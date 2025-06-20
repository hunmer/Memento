import 'dart:io';
import 'dart:async'; // 添加 StreamController 和 TimeoutException 的导入
import 'dart:typed_data'; // 添加 Uint8List 的导入
import 'package:Memento/core/storage/storage_manager.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:archive/archive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:package_info_plus/package_info_plus.dart';

class FullBackupController {
  final BuildContext _originalContext;
  bool _mounted = true;
  final _progressController = StreamController<double>.broadcast();
  Stream<double> get progressStream => _progressController.stream;

  FullBackupController(this._originalContext) {
    _initPackageInfo();
  }

  // 获取当前有效的 context，如果 _mounted 为 false，则返回 null
  BuildContext? get _safeContext => _mounted ? _originalContext : null;

  Future<void> _initPackageInfo() async {
    try {
      await PackageInfo.fromPlatform();
      // 只是初始化，不需要使用返回值
    } catch (e) {
      debugPrint('获取应用版本信息失败: $e');
      // 使用默认版本号
    }
  }

  void dispose() {
    _mounted = false;
    _progressController.close();
  }

  Future<void> exportAllData() async {
    if (!_mounted) return;

    // 保存当前 context 的引用，避免在异步操作后直接使用
    final context = _safeContext;
    if (context == null) return;

    // 显示进度对话框
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (dialogContext) => StreamBuilder<double>(
            stream: progressStream,
            builder: (builderContext, snapshot) {
              return AlertDialog(
                title: const Text('正在备份'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    LinearProgressIndicator(value: snapshot.data),
                    const SizedBox(height: 16),
                    Text(
                      '已完成: ${((snapshot.data ?? 0) * 100).toStringAsFixed(1)}%',
                    ),
                  ],
                ),
              );
            },
          ),
    );

    try {
      _progressController.add(0.0); // 初始进度
      // 获取应用文档目录
      final appDir = await StorageManager.getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');

      // 创建一个临时目录来存储压缩文件
      final tempDir = await getTemporaryDirectory();
      final archivePath = '${tempDir.path}/full_backup_$timestamp.zip';

      // 创建一个 ZipEncoder 实例
      final encoder = ZipEncoder();
      final archive = Archive();

      // 递归添加所有文件到压缩包
      await _addFilesToArchive(appDir, appDir.path, archive);

      // 保存压缩文件
      final archiveData = encoder.encode(archive);
      if (archiveData == null) throw Exception('Failed to create archive');

      // 确保 archiveData 是有效的字节列表
      final List<int> validBytes = List<int>.from(archiveData);

      final archiveFile = File(archivePath);
      await archiveFile.writeAsBytes(validBytes);

      if (!_mounted) return;

      // 获取最新的安全 context
      final currentContext = _safeContext;
      if (currentContext == null) return;

      if (Platform.isAndroid || Platform.isIOS) {
        // 在移动平台上使用分享功能来保存文件
        final result = await FilePicker.platform.saveFile(
          dialogTitle: '选择备份保存位置',
          fileName: 'full_backup_$timestamp.zip',
          allowedExtensions: ['zip'],
          type: FileType.custom,
          bytes: Uint8List.fromList(validBytes), // 转换为Uint8List类型
        );

        if (!_mounted) return;
        final updatedContext = _safeContext;
        if (updatedContext == null) return;

        if (result == null) {
          ScaffoldMessenger.of(
            updatedContext,
          ).showSnackBar(const SnackBar(content: Text('导出已取消')));
          return;
        }
      } else {
        // 在桌面平台上使用文件系统API
        final savedFile = await FilePicker.platform.saveFile(
          dialogTitle: '选择备份保存位置',
          fileName: 'full_backup_$timestamp.zip',
          allowedExtensions: ['zip'],
          type: FileType.custom,
        );

        if (!_mounted) return;
        final updatedContext = _safeContext;
        if (updatedContext == null) return;

        if (savedFile == null) {
          ScaffoldMessenger.of(
            updatedContext,
          ).showSnackBar(const SnackBar(content: Text('导出已取消')));
          return;
        }

        // 移动文件到用户选择的位置
        await archiveFile.copy(savedFile);
      }

      // 删除临时文件
      await archiveFile.delete();

      // 关闭进度对话框并显示成功消息
      if (!_mounted) return;
      final finalContext = _safeContext;
      if (finalContext == null) return;

      Navigator.of(finalContext, rootNavigator: true).pop();
      ScaffoldMessenger.of(
        finalContext,
      ).showSnackBar(const SnackBar(content: Text('数据导出成功')));
    } catch (e) {
      // 关闭进度对话框并显示错误消息
      if (!_mounted) return;
      final errorContext = _safeContext;
      if (errorContext == null) return;

      Navigator.of(errorContext, rootNavigator: true).pop();
      ScaffoldMessenger.of(
        errorContext,
      ).showSnackBar(SnackBar(content: Text('导出失败: $e')));
    }
  }

  Future<void> importAllData() async {
    if (!_mounted) return;

    // 保存当前 context 的引用，避免在异步操作后直接使用
    final context = _safeContext;
    if (context == null) return;

    try {
      // 提示用户确认
      final bool? confirmed = await showDialog<bool>(
        context: context,
        barrierDismissible: false, // 防止点击外部关闭对话框
        builder:
            (dialogContext) => PopScope(
              // 使用 PopScope 代替已弃用的 WillPopScope
              canPop: false, // 防止返回键关闭对话框
              child: AlertDialog(
                title: const Text('警告'),
                content: const Text(
                  '导入操作将完全覆盖当前的应用数据。\n'
                  '建议在导入前备份现有数据。\n\n'
                  '是否继续？',
                ),
                actions: [
                  TextButton(
                    child: const Text('取消'),
                    onPressed: () {
                      Navigator.of(dialogContext).pop(false);
                    },
                  ),
                  TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red, // 使用红色强调风险
                    ),
                    child: const Text('继续'),
                    onPressed: () {
                      Navigator.of(dialogContext).pop(true);
                    },
                  ),
                ],
              ),
            ),
      );

      if (!_mounted) return;
      final afterDialogContext = _safeContext;
      if (afterDialogContext == null) return;

      if (confirmed != true) {
        ScaffoldMessenger.of(
          afterDialogContext,
        ).showSnackBar(const SnackBar(content: Text('已取消导入操作')));
        return;
      }

      // 直接显示文件选择器，不再显示中间加载对话框
      if (!_mounted) return;
      final beforePickContext = _safeContext;
      if (beforePickContext == null) return;

      // 显示短暂的提示
      ScaffoldMessenger.of(beforePickContext).showSnackBar(
        const SnackBar(
          content: Text('请选择备份文件'),
          duration: Duration(seconds: 1),
        ),
      );

      // 选择备份文件
      try {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['zip'],
          allowMultiple: false,
          dialogTitle: '选择备份文件',
          withData: true, // 确保可以读取文件数据
        );

        if (!_mounted) return;
        final afterPickContext = _safeContext;
        if (afterPickContext == null) return;

        if (result == null || result.files.isEmpty) {
          ScaffoldMessenger.of(
            afterPickContext,
          ).showSnackBar(const SnackBar(content: Text('未选择文件')));
          return;
        }

        // 显示导入进度对话框
        showDialog(
          context: afterPickContext,
          barrierDismissible: false,
          builder:
              (dialogContext) => const AlertDialog(
                title: Text('正在导入'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('正在处理备份文件...'),
                  ],
                ),
              ),
        );

        final file = File(result.files.first.path!);
        final bytes = await file.readAsBytes().timeout(
          const Duration(minutes: 2),
          onTimeout: () {
            throw TimeoutException('读取文件超时，请检查文件是否过大或是否有权限访问');
          },
        );

        // 确保字节是有效的 List<int>
        final validBytes = List<int>.from(bytes);

        // 解压缩文件
        final archive = ZipDecoder().decodeBytes(validBytes);

        // 版本信息不再验证，只检查文件是否存在
        final versionFile = archive.findFile('version.txt');
        if (versionFile == null) {
          debugPrint('备份文件缺少版本信息，但仍将继续导入');
        }

        // 获取应用文档目录
        final appDir = await StorageManager.getApplicationDocumentsDirectory();

        // 清空现有数据
        await appDir.delete(recursive: true);
        await appDir.create();

        // 解压文件
        for (final file in archive) {
          if (file.isFile) {
            final outFile = File('${appDir.path}/${file.name}');
            await outFile.create(recursive: true);
            // 确保内容是有效的 List<int>
            final validContent = List<int>.from(file.content as List<dynamic>);
            await outFile.writeAsBytes(validContent);
          }
        }

        if (!_mounted) return;
        final afterImportContext = _safeContext;
        if (afterImportContext == null) return;

        // 关闭导入进度对话框
        Navigator.of(afterImportContext, rootNavigator: true).pop();

        ScaffoldMessenger.of(
          afterImportContext,
        ).showSnackBar(const SnackBar(content: Text('数据导入成功，请重启应用')));

        // 提示重启应用
        await showDialog(
          context: afterImportContext,
          barrierDismissible: false,
          builder:
              (dialogContext) => AlertDialog(
                title: const Text('需要重启'),
                content: const Text('数据已导入完成，需要重启应用才能生效。'),
              ),
        );
      } catch (e, stackTrace) {
        // 确保关闭所有可能的对话框
        if (!_mounted) return;
        final errorContext = _safeContext;
        if (errorContext == null) return;

        Navigator.of(
          errorContext,
          rootNavigator: true,
        ).popUntil((route) => route.isFirst);
        debugPrint('文件选择器错误: $e\n$stackTrace');
        ScaffoldMessenger.of(
          errorContext,
        ).showSnackBar(SnackBar(content: Text('文件选择失败: $e')));
      }
    } catch (e, stackTrace) {
      debugPrint('导入失败: $e\n$stackTrace');

      // 确保关闭所有可能的对话框
      if (!_mounted) return;
      final finalErrorContext = _safeContext;
      if (finalErrorContext == null) return;

      Navigator.of(
        finalErrorContext,
        rootNavigator: true,
      ).popUntil((route) => route.isFirst);

      String errorMessage = '导入失败';
      if (e is TimeoutException) {
        errorMessage = '导入超时：文件可能过大或无法访问';
      } else if (e is FileSystemException) {
        errorMessage = '文件系统错误：无法读取或写入文件';
      } else if (e.toString().contains('ArchiveException')) {
        errorMessage = '无效的备份文件：文件可能已损坏';
      } else {
        errorMessage = '导入失败: ${e.toString()}';
      }

      ScaffoldMessenger.of(finalErrorContext).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          duration: const Duration(seconds: 5),
          action: SnackBarAction(label: '重试', onPressed: () => importAllData()),
        ),
      );
    }
  }

  Future<void> _addFilesToArchive(
    Directory directory,
    String basePath,
    Archive archive,
  ) async {
    // 首先计算总文件数
    int totalFiles = 0;
    int processedFiles = 0;

    Future<void> countFiles(Directory dir) async {
      final entities = dir.listSync();
      for (final entity in entities) {
        if (entity is File) {
          totalFiles++;
        } else if (entity is Directory) {
          await countFiles(entity);
        }
      }
    }

    await countFiles(directory);

    // 添加文件到压缩包
    Future<void> addFiles(Directory dir) async {
      final entities = dir.listSync();
      for (final entity in entities) {
        if (!_mounted) return;

        final relativePath = entity.path.substring(basePath.length + 1);
        if (entity is File) {
          final bytes = await entity.readAsBytes();
          // 确保字节是有效的 List<int>
          final validBytes = List<int>.from(bytes);
          archive.addFile(
            ArchiveFile(relativePath, validBytes.length, validBytes),
          );
          processedFiles++;

          // 更新进度
          if (_mounted && totalFiles > 0) {
            _progressController.add(processedFiles / totalFiles);
          }

          // 让出CPU时间片
          await Future.delayed(Duration.zero);
        } else if (entity is Directory) {
          await addFiles(entity);
        }
      }
    }

    await addFiles(directory);
  }
}
