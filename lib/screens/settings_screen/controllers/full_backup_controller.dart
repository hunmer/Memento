import 'dart:io';
import 'dart:async'; // 添加 StreamController 和 TimeoutException 的导入
import 'dart:typed_data'; // 添加 Uint8List 的导入
import 'package:Memento/core/storage/storage_manager.dart';
import 'package:Memento/l10n/app_localizations.dart';
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
    await PackageInfo.fromPlatform();
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
                title: Text(AppLocalizations.of(context)!.exportingData),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    LinearProgressIndicator(value: snapshot.data),
                    const SizedBox(height: 16),
                    Text('${((snapshot.data ?? 0) * 100).toStringAsFixed(1)}%'),
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
          dialogTitle: AppLocalizations.of(context)!.selectBackupMethod,
          fileName: 'full_backup_$timestamp.zip',
          allowedExtensions: ['zip'],
          type: FileType.custom,
          bytes: Uint8List.fromList(validBytes), // 转换为Uint8List类型
        );

        if (!_mounted) return;
        final updatedContext = _safeContext;
        if (updatedContext == null) return;

        if (result == null) {
          ScaffoldMessenger.of(updatedContext).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.exportCancelled),
            ),
          );
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
          ScaffoldMessenger.of(updatedContext).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.exportCancelled),
            ),
          );
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
      ScaffoldMessenger.of(finalContext).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.exportSuccess)),
      );
    } catch (e) {
      // 关闭进度对话框并显示错误消息
      if (!_mounted) return;
      final errorContext = _safeContext;
      if (errorContext == null) return;

      Navigator.of(errorContext, rootNavigator: true).pop();
      ScaffoldMessenger.of(errorContext).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.exportFailed(e.toString()),
          ),
        ),
      );
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
                title: Text(AppLocalizations.of(context)!.warning),
                content: Text(AppLocalizations.of(context)!.importWarning),
                actions: [
                  TextButton(
                    child: Text(AppLocalizations.of(context)!.cancel),
                    onPressed: () {
                      Navigator.of(dialogContext).pop(false);
                    },
                  ),
                  TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red, // 使用红色强调风险
                    ),
                    child: Text(AppLocalizations.of(context)!.confirm),
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
        ScaffoldMessenger.of(afterDialogContext).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.importCancelled),
          ),
        );
        return;
      }

      // 直接显示文件选择器，不再显示中间加载对话框
      if (!_mounted) return;
      final beforePickContext = _safeContext;
      if (beforePickContext == null) return;

      // 显示短暂的提示
      ScaffoldMessenger.of(beforePickContext).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.selectBackupFile),
          duration: Duration(seconds: 1),
        ),
      );

      // 选择备份文件
      try {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['zip'],
          allowMultiple: false,
          dialogTitle: AppLocalizations.of(context)!.selectBackupFile,
          withData: true, // 确保可以读取文件数据
        );

        if (!_mounted) return;
        final afterPickContext = _safeContext;
        if (afterPickContext == null) return;

        if (result == null || result.files.isEmpty) {
          ScaffoldMessenger.of(afterPickContext).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.noFileSelected),
            ),
          );
          return;
        }

        // 显示导入进度对话框
        showDialog(
          context: afterPickContext,
          barrierDismissible: false,
          builder:
              (dialogContext) => AlertDialog(
                title: Text(AppLocalizations.of(context)!.importingData),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(AppLocalizations.of(context)!.pleaseWait),
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

        ScaffoldMessenger.of(afterImportContext).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.importSuccess)),
        );

        // 提示重启应用
        await showDialog(
          context: afterImportContext,
          barrierDismissible: false,
          builder:
              (dialogContext) => AlertDialog(
                title: Text(AppLocalizations.of(context)!.restartRequired),
                content: Text(AppLocalizations.of(context)!.restartMessage),
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
        ScaffoldMessenger.of(errorContext).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.fileSelectionFailed(e)),
          ),
        );
      }
    } catch (e, stackTrace) {
      // 确保关闭所有可能的对话框
      if (!_mounted) return;
      final finalErrorContext = _safeContext;
      if (finalErrorContext == null) return;

      Navigator.of(
        finalErrorContext,
        rootNavigator: true,
      ).popUntil((route) => route.isFirst);

      String errorMessage = AppLocalizations.of(context)!.importFailed;
      if (e is TimeoutException) {
        errorMessage = AppLocalizations.of(context)!.importTimeout;
      } else if (e is FileSystemException) {
        errorMessage = AppLocalizations.of(context)!.filesystemError;
      } else if (e.toString().contains('ArchiveException')) {
        errorMessage = AppLocalizations.of(context)!.invalidBackupFile;
      } else {
        errorMessage =
            AppLocalizations.of(context)!.importFailed + ': ${e.toString()}';
      }

      ScaffoldMessenger.of(finalErrorContext).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: AppLocalizations.of(context)!.retry,
            onPressed: () => importAllData(),
          ),
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
