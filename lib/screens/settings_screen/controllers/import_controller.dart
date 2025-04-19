import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:archive/archive.dart';
import '../../../main.dart';
import '../utils/file_utils.dart';
import '../widgets/folder_selection_dialog.dart';
import 'permission_controller.dart';

class ImportController {
  final BuildContext context;
  bool _mounted = true;
  final PermissionController _permissionController;

  ImportController(this.context)
    : _permissionController = PermissionController(context);

  void dispose() {
    _mounted = false;
  }

  Future<void> importData() async {
    if (!_mounted) return;
    try {
      // 检查权限
      final hasPermission =
          await _permissionController.checkAndRequestPermissions();
      if (!hasPermission || !_mounted) {
        return;
      }

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
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('无法获取文件路径')));
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

        // 检查元数据文件
        final metadataFile = File('${tempDir.path}/metadata.json');
        if (!await metadataFile.exists()) {
          throw Exception('导入文件格式不正确：缺少元数据文件');
        }

        // 解析元数据
        final metadata = json.decode(await metadataFile.readAsString());
        final exportVersion = metadata['appVersion'] as String? ?? '0.0.0';
        const currentVersion = '1.0.0'; // 替换为实际的应用版本

        // 检查版本兼容性
        if (!FileUtils.isVersionCompatible(exportVersion, currentVersion)) {
          if (!_mounted) return;
          final proceed = await showDialog<bool>(
            context: context,
            builder:
                (context) => AlertDialog(
                  title: const Text('版本不兼容'),
                  content: Text(
                    '导出文件版本($exportVersion)与当前应用版本($currentVersion)不兼容。\n'
                    '导入可能会导致数据损坏或应用崩溃。\n\n'
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

          if (!_mounted || proceed != true) {
            return;
          }
        }

        // 获取导出的插件列表
        final exportedPlugins =
            (metadata['plugins'] as List<dynamic>)
                .map(
                  (p) => {
                    'id': p['id'] as String,
                    'name': p['name'] as String,
                    'version': p['version'] as String,
                  },
                )
                .toList();

        // 获取当前已安装的插件
        final installedPlugins = globalPluginManager.allPlugins;
        final installedPluginIds = installedPlugins.map((p) => p.id).toSet();

        // 找出可导入的插件（已安装的插件中存在于导出文件中的插件）
        final availablePlugins =
            exportedPlugins
                .where((p) => installedPluginIds.contains(p['id']))
                .toList();

        if (availablePlugins.isEmpty) {
          if (_mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('没有找到可导入的插件数据')));
          }
          return;
        }

        if (!_mounted) return;
        // 显示插件选择对话框
        final selectedPlugins = await showDialog<List<String>>(
          context: context,
          builder: (BuildContext context) {
            return FolderSelectionDialog(
              items:
                  availablePlugins
                      .map(
                        (p) => {'id': p['id'] ?? '', 'name': p['name'] ?? ''},
                      )
                      .toList(),
            );
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
                title: const Text('导入成功'),
                content: const Text('数据已成功导入。需要重启应用以应用更改。'),
                actions: [
                  TextButton(
                    child: const Text('稍后重启'),
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                  TextButton(
                    child: const Text('立即重启'),
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
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('导入失败: $e')));
        }
      } finally {
        // 清理临时目录
        await tempDir.delete(recursive: true);
      }
    } catch (e) {
      if (_mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('导入失败: $e')));
      }
    }
  }
}
