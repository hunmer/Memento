import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:archive/archive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../core/storage/storage_manager.dart';
import '../utils/file_utils.dart';
import '../../../main.dart';

class FullBackupController {
  final BuildContext context;
  bool _mounted = true;
  String _appVersion = "1.0.0"; // 默认版本号

  FullBackupController(this.context) {
    _initPackageInfo();
  }

  Future<void> _initPackageInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      _appVersion = packageInfo.version;
    } catch (e) {
      debugPrint('获取应用版本信息失败: $e');
      // 使用默认版本号
    }
  }

  String _getAppVersion() {
    return _appVersion;
  }

  void dispose() {
    _mounted = false;
  }

  Future<void> exportAllData() async {
    try {
      // 获取应用文档目录
      final appDir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');

      // 创建一个临时目录来存储压缩文件
      final tempDir = await getTemporaryDirectory();
      final archivePath = '${tempDir.path}/full_backup_$timestamp.zip';

      // 创建一个 ZipEncoder 实例
      final encoder = ZipEncoder();
      final archive = Archive();

      // 添加版本信息
      final versionBytes = utf8.encode(_getAppVersion());
      archive.addFile(
        ArchiveFile('version.txt', versionBytes.length, versionBytes),
      );

      // 递归添加所有文件到压缩包
      await _addFilesToArchive(appDir, appDir.path, archive);

      // 保存压缩文件
      final archiveData = encoder.encode(archive);
      if (archiveData == null) throw Exception('Failed to create archive');

      final archiveFile = File(archivePath);
      await archiveFile.writeAsBytes(archiveData);

      if (!_mounted) return;

      // 让用户选择保存位置
      final savedFile = await FilePicker.platform.saveFile(
        dialogTitle: '选择备份保存位置',
        fileName: 'full_backup_$timestamp.zip',
        allowedExtensions: ['zip'],
        type: FileType.custom,
      );

      if (!_mounted) return;

      if (savedFile == null) {
        if (_mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('导出已取消')));
        }
        return;
      }

      // 移动文件到用户选择的位置
      await archiveFile.copy(savedFile);
      await archiveFile.delete(); // 删除临时文件

      if (_mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('数据导出成功')));
      }
    } catch (e) {
      if (_mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('导出失败: $e')));
      }
    }
  }

  Future<void> importAllData() async {
    try {
      if (!_mounted) return;

      // 提示用户确认
      final bool? confirmed = await showDialog<bool>(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('警告'),
              content: const Text(
                '导入操作将完全覆盖当前的应用数据。\n'
                '建议在导入前备份现有数据。\n\n'
                '是否继续？',
              ),
              actions: [
                TextButton(
                  child: const Text('取消'),
                  onPressed: () => Navigator.of(context).pop(false),
                ),
                TextButton(
                  child: const Text('继续'),
                  onPressed: () => Navigator.of(context).pop(true),
                ),
              ],
            ),
      );

      if (!_mounted || confirmed != true) return;

      // 选择备份文件
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip'],
        allowMultiple: false,
      );

      if (!_mounted) return;

      if (result == null || result.files.isEmpty) {
        if (_mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('未选择文件')));
        }
        return;
      }

      final file = File(result.files.first.path!);
      final bytes = await file.readAsBytes();

      // 解压缩文件
      final archive = ZipDecoder().decodeBytes(bytes);

      // 检查版本兼容性
      final versionFile = archive.findFile('version.txt');
      if (versionFile == null) throw Exception('无效的备份文件：缺少版本信息');

      final exportVersion = utf8.decode(versionFile.content as List<int>);
      final currentVersion = _getAppVersion();

      if (!FileUtils.isVersionCompatible(exportVersion, currentVersion)) {
        if (!_mounted) return;

        final bool? proceed = await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('版本不兼容'),
                content: Text(
                  '备份文件版本($exportVersion)与当前应用版本($currentVersion)不兼容。\n'
                  '继续导入可能会导致数据损坏或应用崩溃。\n\n'
                  '是否仍要继续？',
                ),
                actions: [
                  TextButton(
                    child: const Text('取消'),
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                  TextButton(
                    child: const Text('继续'),
                    onPressed: () => Navigator.of(context).pop(true),
                  ),
                ],
              ),
        );

        if (!_mounted || proceed != true) return;
      }

      // 获取应用文档目录
      final appDir = await getApplicationDocumentsDirectory();

      // 清空现有数据
      await appDir.delete(recursive: true);
      await appDir.create();

      // 解压文件
      for (final file in archive) {
        if (file.isFile) {
          final outFile = File('${appDir.path}/${file.name}');
          await outFile.create(recursive: true);
          await outFile.writeAsBytes(file.content as List<int>);
        }
      }

      if (!_mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('数据导入成功，请重启应用')));

      // 提示重启应用
      if (_mounted) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder:
              (context) => AlertDialog(
                title: const Text('需要重启'),
                content: const Text('数据已导入完成，需要重启应用才能生效。'),
                actions: [
                  TextButton(
                    child: const Text('立即重启'),
                    onPressed: () => _restartApp(context),
                  ),
                ],
              ),
        );
      }
    } catch (e) {
      if (_mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('导入失败: $e')));
      }
    }
  }

  Future<void> _addFilesToArchive(
    Directory directory,
    String basePath,
    Archive archive,
  ) async {
    final entities = directory.listSync();
    for (final entity in entities) {
      final relativePath = entity.path.substring(basePath.length + 1);
      if (entity is File) {
        final bytes = await entity.readAsBytes();
        archive.addFile(ArchiveFile(relativePath, bytes.length, bytes));
      } else if (entity is Directory) {
        await _addFilesToArchive(entity, basePath, archive);
      }
    }
  }

  void _restartApp(BuildContext context) {
    globalStorage.clearMemoryCache();
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (context) => const MyApp()));
  }
}
