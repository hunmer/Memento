import 'package:flutter/material.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as path;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../../plugins/chat/l10n/chat_localizations.dart';
import '../../../plugins/day/l10n/day_localizations.dart';
import '../../../plugins/nodes/l10n/nodes_localizations.dart' as nodes_l10n;
import '../../../main.dart';
import '../../../core/plugin_base.dart';
import '../../../screens/home_screen.dart';
import '../widgets/plugin_selection_dialog.dart';
import '../widgets/folder_selection_dialog.dart';

class SettingsScreenController extends ChangeNotifier {
  bool isDarkMode = false;
  final BuildContext context;
  final bool _mounted = true;

  SettingsScreenController(this.context);

  // 获取当前语言设置
  Locale get currentLocale => Localizations.localeOf(context);

  // 判断是否为中文
  bool get isChineseLocale => currentLocale.languageCode == 'zh';
  Future<void> initTheme() async {
    if (!_mounted) return;
    // 从配置管理器获取保存的主题设置
    final savedThemeMode = globalConfigManager.getThemeMode();
    isDarkMode = savedThemeMode == ThemeMode.dark;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    // 保存当前BuildContext，因为后面要在异步操作后使用
    final currentContext = context;
    
    isDarkMode = !isDarkMode;
    final newThemeMode = isDarkMode ? ThemeMode.dark : ThemeMode.light;
    
    // 保存主题设置到配置管理器
    await globalConfigManager.setThemeMode(newThemeMode);
    
    // 重建应用以应用新主题
    if (!_mounted) return;
    await _rebuildApplication(
      currentContext: currentContext,
      newThemeMode: newThemeMode,
    );

    // 显示切换提示
    if (!_mounted) return;
    ScaffoldMessenger.of(currentContext).showSnackBar(
      SnackBar(
        content: Text(isDarkMode ? '已切换到深色主题' : '已切换到浅色主题'),
        duration: const Duration(seconds: 1),
      ),
    );
    
    notifyListeners();
  }

  Future<void> exportData() async {
    if (!_mounted) return;
    try {
      // 获取所有插件
      final plugins = globalPluginManager.allPlugins;

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

        if (!_mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('数据已导出到: $savePath')),
        );
      }
    } catch (e) {
      if (!_mounted) return;
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
    if (!_mounted) return;
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

        if (!_mounted) return;
        // 显示文件夹选择对话框
        final selectedFolders = await showDialog<List<String>>(
          context: context,
          builder: (BuildContext context) {
            return FolderSelectionDialog(folders: folders);
          },
        );

        if (selectedFolders != null && selectedFolders.isNotEmpty) {
          if (!_mounted) return;
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

            if (!_mounted) return;
            // 重新加载应用
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('数据导入成功，正在重新加载应用...')),
            );
            // TODO: 实现应用重新加载逻辑，可以通过重新构建主应用来实现
            // 例如：Navigator.of(context).pushAndRemoveUntil(
            //   MaterialPageRoute(builder: (_) => const MyApp()),
            //   (route) => false,
            // );
          }
        }
      }
    } catch (e) {
      if (!_mounted) return;
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

  /// 重建应用以应用新的设置
  Future<void> _rebuildApplication({
    required BuildContext currentContext,
    Locale? newLocale,
    ThemeMode? newThemeMode,
  }) async {
    if (!_mounted) return;
    
    final navigator = Navigator.of(currentContext);
    final currentRoute = ModalRoute.of(currentContext);
    if (currentRoute == null) return;

    // 获取当前或新的主题模式
    final effectiveThemeMode = newThemeMode ?? (Theme.of(currentContext).brightness == Brightness.dark 
        ? ThemeMode.dark 
        : ThemeMode.light);

    // 获取当前或新的区域设置
    final effectiveLocale = newLocale ?? Localizations.localeOf(currentContext);

    navigator.pushReplacement(
      MaterialPageRoute(
        builder: (context) => MaterialApp(
          title: 'Memento',
          debugShowCheckedModeBanner: false,
          home: const HomeScreen(),
          locale: effectiveLocale,
          themeMode: effectiveThemeMode,
          theme: ThemeData(
            colorScheme: const ColorScheme.light(
              primary: Colors.blue,
              secondary: Colors.blueAccent,
            ),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            colorScheme: const ColorScheme.dark(
              primary: Colors.blue,
              secondary: Colors.blueAccent,
            ),
            useMaterial3: true,
          ),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            ChatLocalizations.delegate,
            DayLocalizationsDelegate.delegate,
            nodes_l10n.NodesLocalizationsDelegate.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('zh', ''),
            Locale('en', ''),
          ],
        ),
      ),
    );
  }

  // 切换语言
  Future<void> toggleLanguage() async {
    if (!_mounted) return;
    final newLocale = isChineseLocale ? const Locale('en') : const Locale('zh');
    
    // 保存语言设置到配置管理器
    await globalConfigManager.setLocale(newLocale);
    
    // 重建应用以应用新语言
    await _rebuildApplication(
      currentContext: context,
      newLocale: newLocale,
    );

    if (!_mounted) return;
    // 显示切换提示
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isChineseLocale ? 'Switched to English' : '已切换到中文'),
        duration: const Duration(seconds: 1),
      ),
    );
  }
}