import 'package:flutter/material.dart';
import '../base_plugin.dart';
import '../../core/plugin_manager.dart';
import '../../core/config_manager.dart';
import 'l10n/diary_localizations.dart';
import 'controls/prompt_controller.dart';
import 'screens/diary_calendar_screen.dart';
import 'dart:io';
import 'package:path/path.dart' as path;

class DiaryPlugin extends BasePlugin {
  final DiaryPromptController _promptController = DiaryPromptController();
  final String pluginDir = 'diary';
  static final DiaryPlugin instance = DiaryPlugin._internal();
  DiaryPlugin._internal();

  @override
  String get id => 'diary_plugin';

  @override
  String get name => 'Diary';

  @override
  final String version = '1.0.0';

  @override
  String get description => 'Diary management plugin';

  @override
  String get author => 'Zhuanz';

    @override
  IconData get icon =>  Icons.book;

  // 获取今日文字数
  Future<int> getTodayWordCount() async {
    final today = DateTime.now();
    final todayFile = path.join(
      storage.getPluginStoragePath(id),
      '${today.year}/${today.month}/${today.day}.md',
    );

    try {
      if (await File(todayFile).exists()) {
        final content = await storage.readFile(todayFile);
        return content.trim().length;
      }
    } catch (e) {
      debugPrint('Error reading today\'s diary: $e');
    }
    return 0;
  }

  // 获取本月文字数
  Future<int> getMonthWordCount() async {
    final now = DateTime.now();
    var totalCount = 0;
    final monthDir = path.join(
      storage.getPluginStoragePath(id),
      '${now.year}/${now.month}',
    );

    try {
      final dir = Directory(monthDir);
      if (await dir.exists()) {
        await for (final file in dir.list()) {
          if (file.path.endsWith('.md')) {
            final content = await storage.readFile(file.path);
            totalCount += content.trim().length;
          }
        }
      }
    } catch (e) {
      debugPrint('Error calculating month word count: $e');
    }
    return totalCount;
  }

  // 获取本月完成进度
  Future<(int, int)> getMonthProgress() async {
    final now = DateTime.now();
    final monthDir = path.join(
      storage.getPluginStoragePath(id),
      '${now.year}/${now.month}',
    );

    var completedDays = 0;
    final totalDays = DateTime(now.year, now.month + 1, 0).day;

    try {
      final dir = Directory(monthDir);
      if (await dir.exists()) {
        await for (final file in dir.list()) {
          if (file.path.endsWith('.md')) {
            completedDays++;
          }
        }
      }
    } catch (e) {
      debugPrint('Error calculating month progress: $e');
    }
    return (completedDays, totalDays);
  }

  @override
  Future<void> initialize() async {
    // 确保日记数据目录存在
    await storage.createDirectory(pluginDir);
    
    // 初始化 prompt 控制器
    _promptController.initialize();

    // 初始化默认配置
    await loadSettings({
      'theme': 'light',
      'version': version,
      'enabled': true,
    });
  }

  @override
  Future<void> registerToApp(
    PluginManager pluginManager,
    ConfigManager configManager,
  ) async {
    // 初始化插件
    await initialize();

    // 注册插件到插件管理器
    await pluginManager.registerPlugin(this);

    // 保存插件配置
    await configManager.savePluginConfig(id, {
      'version': version,
      'enabled': true,
      'settings': settings,
    });
  }

  Future<void> dispose() async {
    _promptController.unregisterPromptMethods();
  }

  @override
  Widget buildMainView(BuildContext context) {
    return DiaryCalendarScreen(storage: storage);
  }

  @override
  Widget buildCardView(BuildContext context) {
    final theme = Theme.of(context);

    return FutureBuilder<(int, int, int)>(
      future: Future.wait([
        getTodayWordCount(),
        getMonthWordCount(),
        getMonthProgress().then((value) => value.$1),
      ]).then((values) => (values[0], values[1], values[2])),
      builder: (context, snapshot) {
        final todayCount = snapshot.data?.$1 ?? 0;
        final monthCount = snapshot.data?.$2 ?? 0;
        final completedDays = snapshot.data?.$3 ?? 0;
        final totalDays =
            DateTime(DateTime.now().year, DateTime.now().month + 1, 0).day;

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 顶部图标和标题
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: theme.primaryColor.withAlpha(30),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      icon,
                      size: 24,
                      color: color ?? theme.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 统计信息卡片
              Column(
                  children: [
                    // 第一行
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            Text(
                              DiaryLocalizations.of(context)!.todayWordCount,
                               style: theme.textTheme.bodyMedium,
                            ),
                            Text(
                              '$todayCount',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color:
                                    todayCount > 0
                                        ? theme.colorScheme.primary
                                        : null,
                              ),
                            ),
                          ],
                        ),
                        const VerticalDivider(),
                        Column(
                          children: [
                            Text(
                              DiaryLocalizations.of(context)!.monthWordCount,
                              style: theme.textTheme.bodyMedium
                            ),
                            Text(
                              '$monthCount',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    // 第二行
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            Text(
                              DiaryLocalizations.of(context)!.monthProgress,
                              style: theme.textTheme.bodyMedium
                            ),
                            Text(
                              '$completedDays/$totalDays',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color:
                                    completedDays > 0
                                        ? theme.colorScheme.primary
                                        : null,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget buildSettingsView(BuildContext context) {
    return Column(
      children: [
        // TODO 插件设置项
      ],
    );
  }
}