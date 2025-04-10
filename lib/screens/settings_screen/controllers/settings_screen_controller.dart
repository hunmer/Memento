import 'package:flutter/material.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as path;
import '../../../main.dart';
import '../../../core/plugin_base.dart';
import '../widgets/plugin_selection_dialog.dart';
import '../widgets/folder_selection_dialog.dart';

class SettingsScreenController extends ChangeNotifier {
  bool isDarkMode = false;
  final BuildContext context;
  bool _mounted = true;

  SettingsScreenController(this.context);

  void initTheme() {
    if (!_mounted) return;
    // 从当前主题获取初始值
    isDarkMode = Theme.of(context).brightness == Brightness.dark;
    notifyListeners();
  }

  void toggleTheme() {
    isDarkMode = !isDarkMode;
    notifyListeners();

    // 显示切换提示
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(isDarkMode ? '已切换到深色主题' : '已切换到浅色主题')),
    );
  }

  Future<void> exportData() async {
    try {
      // 获取所有插件
      final plugins = globalPluginManager.allPlugins;

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
      final tempDir = await Directory.systemTemp.createTemp('memento_export_');

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
          await _copyDirectory(sourceDir, pluginDir);
        } else {
          // 如果插件数据文件夹不存在，创建一个空文件夹
          debugPrint('插件 ${plugin.id} 的数据文件夹不存在，将创建空文件夹');
          // 确保目标目录存在
          await pluginDir.create(recursive: true);
        }
      }

      // 创建 ZIP 文件
      final zipFile = ZipFileEncoder();
      final savePath = await FilePicker.platform.saveFile(
        dialogTitle: '选择保存位置',
        fileName: 'memento.zip',
      );

      if (savePath != null) {
        zipFile.create(savePath);
        await zipFile.addDirectory(tempDir);
        zipFile.close();

        // 删除临时目录
        await tempDir.delete(recursive: true);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('数据已导出到: $savePath')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('导出失败: $e')),
      );
    }
  }

  Future<void> _copyDirectory(Directory source, Directory destination) async {
    // 检查源目录是否存在
    if (!await source.exists()) {
      // 源目录不存在，记录日志并返回
      debugPrint('警告: 源目录不存在: ${source.path}');
      return;
    }

    try {
      await for (var entity in source.list(recursive: false)) {
        if (entity is Directory) {
          // 使用path包获取平台无关的路径分隔符
          final basename = path.basename(entity.path);
          var newDirectory = Directory(
            path.join(destination.path, basename),
          );
          await newDirectory.create();
          await _copyDirectory(entity.absolute, newDirectory);
        } else if (entity is File) {
          final basename = path.basename(entity.path);
          await entity.copy(
            path.join(destination.path, basename),
          );
        }
      }
    } catch (e) {
      debugPrint('复制目录时出错: $e');
      // 重新抛出异常，让调用者处理
      rethrow;
    }
  }

  Future<void> importData() async {
    try {
      // 打开文件选择器
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final bytes = await file.readAsBytes();
        final archive = ZipDecoder().decodeBytes(bytes);

        // 获取压缩包中的文件夹列表
        final Set<String> folderSet = {};
        for (final file in archive) {
          // 通过文件路径分析来识别文件夹
          // 使用path包处理路径分隔符
          final pathParts = path.split(file.name);
          if (pathParts.length > 1 && pathParts[0].isNotEmpty) {
            folderSet.add(pathParts[0]);
          }
        }
        final folders = folderSet.toList();

        // 显示文件夹选择对话框
        final selectedFolders = await showDialog<List<String>>(
          context: context,
          builder: (BuildContext context) {
            return FolderSelectionDialog(folders: folders);
          },
        );

        if (selectedFolders != null && selectedFolders.isNotEmpty) {
          // 显示导入方式选择对话框
          final importMethod = await showDialog<String>(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('选择导入方式'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      title: const Text('覆盖'),
                      onTap: () => Navigator.of(context).pop('overwrite'),
                    ),
                    ListTile(
                      title: const Text('合并'),
                      onTap: () => Navigator.of(context).pop('merge'),
                    ),
                  ],
                ),
              );
            },
          );

          if (importMethod != null) {
            // 导入选中的文件夹数据
            for (final folder in selectedFolders) {
              // 尝试查找匹配的插件
              PluginBase? plugin;
              try {
                plugin = globalPluginManager.allPlugins.firstWhere(
                  (p) => p.id == folder,
                );
              } catch (e) {
                // 未找到匹配的插件，继续下一个
                continue;
              }

              final pluginDir = Directory(plugin.getPluginStoragePath());
              await pluginDir.create(recursive: true);

              for (final file in archive) {
                // 使用path包处理路径分隔符
                if (file.name.startsWith('$folder${path.separator}') || 
                    file.name.startsWith('$folder/')) {  // 兼容ZIP中可能使用的'/'分隔符
                  final relativePath = file.name.substring(folder.length + 1);
                  final targetFile = File(path.join(pluginDir.path, relativePath));
                  if (importMethod == 'overwrite' || !targetFile.existsSync()) {
                    await targetFile.create(recursive: true);
                    await targetFile.writeAsBytes(file.content);
                  }
                }
              }
            }

            // 重新加载应用
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('数据导入成功，正在重新加载应用...')),
            );
            // TODO: 实现应用重新加载逻辑
            // 例如：Phoenix.rebirth(context);
          }
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('导入失败: $e')),
      );
    }
  }

  void showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AboutDialog(
        applicationName: '插件管理器',
        applicationVersion: '1.0.0',
        applicationLegalese: '© 2023 插件管理器',
        children: [
          const SizedBox(height: 20),
          const Text('这是一个用于管理插件的应用程序。'),
        ],
      ),
    );
  }
}