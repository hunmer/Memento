import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as path;
import 'package:universal_platform/universal_platform.dart';
import '../../../main.dart';
import '../utils/file_utils.dart';
import '../widgets/plugin_selection_dialog.dart';
import 'permission_controller.dart';

class ExportController {
  final BuildContext context;
  final bool _mounted;
  final PermissionController _permissionController;

  ExportController(this.context)
      : _mounted = true,
        _permissionController = PermissionController(context);

  Future<void> exportData() async {
    if (!_mounted) return;
    try {
      // 检查权限
      final hasPermission = await _permissionController.checkAndRequestPermissions();
      if (!hasPermission) {
        return;
      }

      // 获取所有插件
      final plugins = globalPluginManager.allPlugins;

      // 验证所有插件的数据完整性
      final invalidPlugins = <String>[];
      for (final plugin in plugins) {
        try {
          final settingsPath = '${plugin.getPluginStoragePath()}/settings.json';
          if (await File(settingsPath).exists()) {
            final settings = await File(settingsPath).readAsString();
            // 尝试解析JSON以验证格式
            json.decode(settings);
          }
        } catch (e) {
          invalidPlugins.add(plugin.name);
          debugPrint('插件 ${plugin.name} 数据验证失败: $e');
        }
      }

      if (invalidPlugins.isNotEmpty) {
        if (!_mounted) return;
        final proceed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('数据完整性警告'),
            content: Text(
              '以下插件的数据可能不完整或已损坏：\n${invalidPlugins.join('\n')}\n\n是否仍要继续导出？',
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

        if (proceed != true) {
          return;
        }
      }

      if (!_mounted) return;
      // 显示插件选择对话框
      final selectedPlugins = await showDialog<List<String>>(
        context: context,
        builder: (BuildContext context) {
          return PluginSelectionDialog(plugins: plugins);
        },
      );

      if (selectedPlugins == null || selectedPlugins.isEmpty) {
        return;
      }

      // 创建一个临时目录来存储要压缩的文件
      final tempDir = await Directory.systemTemp.createTemp('memento_temp_');

      // 创建元数据文件
      final metadataFile = File('${tempDir.path}/metadata.json');
      await metadataFile.writeAsString(
        json.encode({
          'exportDate': DateTime.now().toIso8601String(),
          'appVersion': '1.0.0', // 替换为实际的应用版本
          'plugins': plugins
              .map(
                (p) => {'id': p.id, 'name': p.name, 'version': p.version},
              )
              .toList(),
        }),
      );

      // 为每个选中的插件创建一个目录并复制数据
      for (final pluginId in selectedPlugins) {
        final plugin = plugins.firstWhere((p) => p.id == pluginId);
        final pluginDir = Directory('${tempDir.path}/${plugin.id}');
        await pluginDir.create(recursive: true);

        // 复制插件数据到临时目录
        final sourceDir = Directory(plugin.getPluginStoragePath());
        debugPrint(sourceDir.path);
        // 检查插件数据文件夹是否存在
        if (await sourceDir.exists()) {
          await FileUtils.copyDirectory(sourceDir, pluginDir);
        } else {
          // 如果插件数据文件夹不存在，创建一个空文件夹
          debugPrint('插件 ${plugin.id} 的数据文件夹不存在，将创建空文件夹');
          // 确保目标目录存在
          await pluginDir.create(recursive: true);
        }
      }

      // 创建临时 ZIP 文件
      final tempZipPath = '${tempDir.path}/memento_export.zip';
      final zipFile = ZipFileEncoder();
      zipFile.create(tempZipPath);

      // 逐个添加插件目录到 ZIP
      for (final pluginId in selectedPlugins) {
        final pluginDir = Directory('${tempDir.path}/$pluginId');
        if (await pluginDir.exists()) {
          // 遍历插件目录中的所有文件和子目录
          await for (final entity in pluginDir.list(recursive: true)) {
            if (entity is File) {
              // 计算相对于插件目录的路径
              final relativePath = path.relative(
                entity.path,
                from: pluginDir.path,
              );
              // 在 ZIP 中使用 pluginId 作为顶级目录
              final zipPath = path.join(pluginId, relativePath);
              await zipFile.addFile(entity, zipPath);
            }
          }
        }
      }

      zipFile.close();

      // 读取生成的 ZIP 文件
      final zipBytes = await File(tempZipPath).readAsBytes();

      String? savePath;

      if (UniversalPlatform.isAndroid || UniversalPlatform.isIOS) {
        // 移动平台：使用 FilePicker 保存字节数据
        savePath = await FilePicker.platform.saveFile(
          dialogTitle: '选择保存位置',
          fileName: 'memento.zip',
          bytes: zipBytes, // 提供字节数据
        );
      } else {
        // 桌面平台：先选择保存位置，然后写入文件
        savePath = await FilePicker.platform.saveFile(
          dialogTitle: '选择保存位置',
          fileName: 'memento.zip',
        );

        if (savePath != null) {
          await File(savePath).writeAsBytes(zipBytes);
        }
      }

      // 删除临时目录
      await tempDir.delete(recursive: true);

      if (savePath != null) {
        if (!_mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('数据已导出到: $savePath')));
      }
    } catch (e) {
      if (!_mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('导出失败: $e')));
    }
  }
}