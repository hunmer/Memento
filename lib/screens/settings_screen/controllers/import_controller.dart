import 'dart:io';
import 'package:Memento/core/app_initializer.dart';
import 'package:Memento/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:archive/archive.dart';
import '../../../core/utils/file_utils.dart';
import '../widgets/folder_selection_dialog.dart';
import '../../../core/l10n/import_localizations.dart';
import 'package:Memento/core/services/toast_service.dart';

class ImportController {
  final BuildContext context;
  bool _mounted = true;

  ImportController(this.context);

  void dispose() {
    _mounted = false;
  }

  Future<void> importData() async {
    if (!_mounted) return;
    try {
      // 选择要导入的ZIP文件
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip'],
      );

      if (!_mounted) return;
      if (result == null || result.files.isEmpty) {
        return;
      }

      final filePath = result.files.first.path;
      if (filePath == null) {
        if (_mounted) {
          Toast.error(ImportLocalizations.of(context).filePathError);
        }
        return;
      }

      // 创建临时目录解压文件
      final tempDir = await Directory.systemTemp.createTemp('memento_import_');

      try {
        // 读取ZIP文件
        final bytes = await File(filePath).readAsBytes();
        final archive = ZipDecoder().decodeBytes(bytes);

        // 解压文件到临时目录
        for (final file in archive) {
          final filename = file.name;
          if (file.isFile) {
            final data = file.content as List<int>;
            File('${tempDir.path}/$filename')
              ..createSync(recursive: true)
              ..writeAsBytesSync(data);
          } else {
            Directory('${tempDir.path}/$filename').createSync(recursive: true);
          }
        }

        // 获取当前已安装的插件
        final installedPlugins = globalPluginManager.allPlugins;

        // 获取ZIP中的所有顶级目录作为可用插件ID
        final availablePluginIds =
            archive.files
                .where((file) => file.name.contains('/')) // 包含/表示是文件夹内的文件
                .map((file) => file.name.split('/')[0]) // 获取第一级目录名
                .toSet(); // 使用Set去重

        // 找出可导入的插件（已安装的插件中存在于导出文件中的插件）
        final availablePlugins =
            installedPlugins
                .where((p) => availablePluginIds.contains(p.id))
                .map((p) => {'id': p.id})
                .toList();

        if (availablePlugins.isEmpty) {
          if (_mounted) {
            Toast.error(AppLocalizations.of(context)!.noPluginDataFound);
          }
          return;
        }

        if (!_mounted) return;
        // 显示插件选择对话框
        final selectedPlugins = await showDialog<List<String>>(
          context: context,
          builder: (BuildContext context) {
            return FolderSelectionDialog(items: availablePlugins);
          },
        );

        if (!_mounted || selectedPlugins == null || selectedPlugins.isEmpty) {
          return;
        }

        // 备份当前数据
        final backupDir = await Directory.systemTemp.createTemp(
          'memento_backup_',
        );
        for (final pluginId in selectedPlugins) {
          final plugin = installedPlugins.firstWhere((p) => p.id == pluginId);
          final sourceDir = Directory(plugin.getPluginStoragePath());
          final backupPluginDir = Directory('${backupDir.path}/$pluginId');

          if (await sourceDir.exists()) {
            await FileUtils.copyDirectory(sourceDir, backupPluginDir);
          }
        }

        // 导入选中的插件数据
        for (final pluginId in selectedPlugins) {
          final plugin = installedPlugins.firstWhere((p) => p.id == pluginId);
          final importDir = Directory('${tempDir.path}/$pluginId');
          final targetDir = Directory(plugin.getPluginStoragePath());

          if (await importDir.exists()) {
            // 清空目标目录
            if (await targetDir.exists()) {
              await targetDir.delete(recursive: true);
            }
            await targetDir.create(recursive: true);

            // 复制导入数据到插件目录
            await FileUtils.copyDirectory(importDir, targetDir);
          }
        }

        if (!_mounted) return;
        // 提示用户导入成功并需要重启应用
        final restart = await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                title: Text(ImportLocalizations.of(context).importSuccess),
                content: Text(
                  ImportLocalizations.of(context).importSuccessContent,
                ),
                actions: [
                  TextButton(
                    child: Text(ImportLocalizations.of(context).restartLater),
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                  TextButton(
                    child: Text(ImportLocalizations.of(context).restartNow),
                    onPressed: () => Navigator.of(context).pop(true),
                  ),
                ],
              ),
        );

        if (restart == true && _mounted) {
          // 在实际应用中，这里应该调用重启应用的代码
          // 例如：Phoenix.rebirth(context);
          // 但由于这是示例，我们只是返回到主屏幕
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      } catch (e) {
        if (_mounted) {
          Toast.error('${ImportLocalizations.of(context).importFailed}: $e');
        }
      } finally {
        // 清理临时目录
        await tempDir.delete(recursive: true);
      }
    } catch (e) {
      if (_mounted) {
        Toast.error(AppLocalizations.of(context)!.importFailedWithError(e.toString()));
      }
    }
  }
}
