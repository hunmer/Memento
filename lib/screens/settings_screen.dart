import 'package:flutter/material.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:archive/archive_io.dart';
import '../main.dart';
import '../core/plugin_base.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class PluginSelectionDialog extends StatefulWidget {
  final List<PluginBase> plugins;

  const PluginSelectionDialog({super.key, required this.plugins});

  @override
  _PluginSelectionDialogState createState() => _PluginSelectionDialogState();
}

class _PluginSelectionDialogState extends State<PluginSelectionDialog> {
  final Set<String> _selectedPlugins = {};

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('选择要导出的插件'),
      content: SingleChildScrollView(
        child: ListBody(
          children:
              widget.plugins.map((plugin) {
                return CheckboxListTile(
                  title: Text(plugin.name),
                  value: _selectedPlugins.contains(plugin.id),
                  onChanged: (bool? value) {
                    setState(() {
                      if (value == true) {
                        _selectedPlugins.add(plugin.id);
                      } else {
                        _selectedPlugins.remove(plugin.id);
                      }
                    });
                  },
                );
              }).toList(),
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('取消'),
          onPressed: () => Navigator.of(context).pop(),
        ),
        TextButton(
          child: const Text('确定'),
          onPressed: () => Navigator.of(context).pop(_selectedPlugins.toList()),
        ),
      ],
    );
  }
}

class FolderSelectionDialog extends StatefulWidget {
  final List<String> folders;

  const FolderSelectionDialog({super.key, required this.folders});

  @override
  _FolderSelectionDialogState createState() => _FolderSelectionDialogState();
}

class _FolderSelectionDialogState extends State<FolderSelectionDialog> {
  final Set<String> _selectedFolders = {};

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('选择要导入的文件夹'),
      content: SingleChildScrollView(
        child: ListBody(
          children:
              widget.folders.map((folder) {
                return CheckboxListTile(
                  title: Text(folder),
                  value: _selectedFolders.contains(folder),
                  onChanged: (bool? value) {
                    setState(() {
                      if (value == true) {
                        _selectedFolders.add(folder);
                      } else {
                        _selectedFolders.remove(folder);
                      }
                    });
                  },
                );
              }).toList(),
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('取消'),
          onPressed: () => Navigator.of(context).pop(),
        ),
        TextButton(
          child: const Text('确定'),
          onPressed: () => Navigator.of(context).pop(_selectedFolders.toList()),
        ),
      ],
    );
  }
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadThemeSettings();
  }

  void _loadThemeSettings() {
    // 这里可以从SharedPreferences或其他存储加载主题设置
    // 暂时使用简单的状态管理
    setState(() {
      _isDarkMode = Theme.of(context).brightness == Brightness.dark;
    });
  }

  Future<void> _exportData() async {
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
        print(sourceDir.path);
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

        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('数据已导出到: $savePath')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('导出失败: $e')));
      }
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
          var newDirectory = Directory(
            '${destination.path}/${entity.path.split('/').last}',
          );
          await newDirectory.create();
          await _copyDirectory(entity.absolute, newDirectory);
        } else if (entity is File) {
          await entity.copy(
            '${destination.path}/${entity.path.split('/').last}',
          );
        }
      }
    } catch (e) {
      debugPrint('复制目录时出错: $e');
      // 重新抛出异常，让调用者处理
      rethrow;
    }
  }

  Future<void> _importData() async {
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
          final pathParts = file.name.split('/');
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
                if (file.name.startsWith('$folder/')) {
                  final relativePath = file.name.substring(folder.length + 1);
                  final targetFile = File('${pluginDir.path}/$relativePath');

                  if (importMethod == 'overwrite' || !targetFile.existsSync()) {
                    await targetFile.create(recursive: true);
                    await targetFile.writeAsBytes(file.content);
                  }
                }
              }
            }

            // 重新加载应用
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('数据导入成功，正在重新加载应用...')),
              );
              // TODO: 实现应用重新加载逻辑
              // 例如：Phoenix.rebirth(context);
            }
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('导入失败: $e')));
      }
    }
  }

  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });

    // 这里应该触发应用主题变更
    // 实际应用中，你可能需要使用Provider、GetX或其他状态管理来处理全局主题
    // 例如: ThemeProvider.of(context).toggleTheme();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_isDarkMode ? '已切换到深色主题' : '已切换到浅色主题')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.color_lens),
            title: const Text('深色主题'),
            trailing: Switch(
              value: _isDarkMode,
              onChanged: (value) => _toggleTheme(),
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.upload),
            title: const Text('导出数据'),
            subtitle: const Text('将应用数据导出到文件'),
            onTap: _exportData,
          ),
          ListTile(
            leading: const Icon(Icons.download),
            title: const Text('导入数据'),
            subtitle: const Text('从文件导入应用数据'),
            onTap: _importData,
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('关于'),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: '插件管理器',
                applicationVersion: '1.0.0',
                applicationLegalese: '© 2023 插件管理器',
                children: [
                  const SizedBox(height: 20),
                  const Text('这是一个用于管理插件的应用程序。'),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
