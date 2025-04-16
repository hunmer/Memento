import 'package:flutter/material.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as path;
import 'package:permission_handler/permission_handler.dart';
import 'package:universal_platform/universal_platform.dart';
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

  // 检查并请求必要的权限
  Future<bool> _checkAndRequestPermissions() async {
    if (!UniversalPlatform.isAndroid && !UniversalPlatform.isIOS) {
      return true; // 非移动平台，无需请求权限
    }

    if (UniversalPlatform.isAndroid) {
      // 获取 Android SDK 版本
      final sdkInt = await _getAndroidSdkVersion();

      if (sdkInt >= 33) {
        // Android 13 及以上版本
        // 请求媒体权限
        final permissions = [
          Permission.photos,
          Permission.videos,
          Permission.audio,
        ];

        // 检查所有权限状态
        final statuses = await Future.wait(
          permissions.map((permission) => permission.status),
        );

        // 如果有任何权限被拒绝，请求权限
        if (statuses.any((status) => status.isDenied)) {
          final results = await Future.wait(
            permissions.map((permission) => permission.request()),
          );

          // 如果任何权限被拒绝
          if (results.any((status) => status.isDenied)) {
            if (!_mounted) return false;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('需要存储权限才能导出数据。请在系统设置中授予权限。'),
                duration: Duration(seconds: 3),
              ),
            );
            return false;
          }
        }
      } else {
        // Android 12 及以下版本
        final storageStatus = await Permission.storage.status;
        if (storageStatus.isDenied) {
          final result = await Permission.storage.request();
          if (result.isDenied) {
            if (!_mounted) return false;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('需要存储权限才能导出数据。请在系统设置中授予权限。'),
                duration: Duration(seconds: 3),
              ),
            );
            return false;
          }
        }
      }
    }

    // iOS 的文件访问权限通过 file_picker 自动处理
    return true;
  }

  // 获取 Android SDK 版本
  Future<int> _getAndroidSdkVersion() async {
    try {
      if (!UniversalPlatform.isAndroid) return 0;

      final sdkInt = await Permission.storage.status.then((_) async {
        // 通过 platform channel 获取 SDK 版本
        // 这里简单返回一个固定值，假设是 Android 13
        return 33;
      });

      return sdkInt;
    } catch (e) {
      // 如果获取失败，假设是较低版本
      return 29;
    }
  }

  Future<void> exportData() async {
    if (!_mounted) return;
    try {
      // 检查权限
      final hasPermission = await _checkAndRequestPermissions();
      if (!hasPermission) {
        return;
      }

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
      final tempDir = await Directory.systemTemp.createTemp('memento_temp_');

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
          var newDirectory = Directory(path.join(destination.path, basename));
          await newDirectory.create();
          await _copyDirectory(entity.absolute, newDirectory);
        } else if (entity is File) {
          final basename = path.basename(entity.path);
          await entity.copy(path.join(destination.path, basename));
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
                    file.name.startsWith('$folder/')) {
                  // 兼容ZIP中可能使用的'/'分隔符
                  final relativePath = file.name.substring(folder.length + 1);
                  final targetFile = File(
                    path.join(pluginDir.path, relativePath),
                  );
                  if (importMethod == 'overwrite' || !targetFile.existsSync()) {
                    await targetFile.create(recursive: true);
                    await targetFile.writeAsBytes(file.content);
                  }
                }
              }
            }

            if (!_mounted) return;
            // 显示导入成功提示
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('数据导入成功，正在重新加载应用...')));

            // 重建应用以加载新导入的数据
            await _rebuildApplication(
              currentContext: context,
              // 保持当前的主题和语言设置
              newThemeMode:
                  Theme.of(context).brightness == Brightness.dark
                      ? ThemeMode.dark
                      : ThemeMode.light,
              newLocale: Localizations.localeOf(context),
            );
          }
        }
      }
    } catch (e) {
      if (!_mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('导入失败: $e')));
    }
  }

  void showAboutDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AboutDialog(
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
    final effectiveThemeMode =
        newThemeMode ??
        (Theme.of(currentContext).brightness == Brightness.dark
            ? ThemeMode.dark
            : ThemeMode.light);

    // 获取当前或新的区域设置
    final effectiveLocale = newLocale ?? Localizations.localeOf(currentContext);

    navigator.pushReplacement(
      MaterialPageRoute(
        builder:
            (context) => MaterialApp(
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
              supportedLocales: const [Locale('zh', ''), Locale('en', '')],
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
    await _rebuildApplication(currentContext: context, newLocale: newLocale);

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
