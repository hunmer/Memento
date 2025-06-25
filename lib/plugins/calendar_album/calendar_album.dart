import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/plugin_manager.dart';
import '../../core/config_manager.dart';
import '../base_plugin.dart';
import 'screens/main_screen.dart';
import 'controllers/calendar_controller.dart';
import 'controllers/tag_controller.dart';
import 'l10n/calendar_album_localizations.dart';

/// 日历相册插件主视图
class CalendarAlbumMainView extends StatefulWidget {
  const CalendarAlbumMainView({super.key});

  @override
  State<CalendarAlbumMainView> createState() => _CalendarAlbumMainViewState();
}

class _CalendarAlbumMainViewState extends State<CalendarAlbumMainView> {
  late CalendarAlbumPlugin _plugin;
  @override
  void initState() {
    super.initState();
    _plugin = CalendarAlbumPlugin.instance;
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _plugin.calendarController),
        ChangeNotifierProvider.value(value: _plugin.tagController),
      ],
      child: const MainScreen(),
    );
  }
}

class CalendarAlbumPlugin extends BasePlugin {
  static CalendarAlbumPlugin? _instance;
  static CalendarAlbumPlugin get instance {
    if (_instance == null) {
      _instance =
          PluginManager.instance.getPlugin('calendar_album')
              as CalendarAlbumPlugin?;
      if (_instance == null) {
        throw StateError('CalendarAlbumPlugin has not been initialized');
      }
    }
    return _instance!;
  }

  late final CalendarController calendarController;
  late final TagController tagController;

  @override
  String get id => 'calendar_album';

  @override
  String get name => 'calendar album';

  @override
  IconData get icon => Icons.notes_rounded;

  @override
  Future<void> initialize() async {
    calendarController = CalendarController();
    tagController = TagController(onTagsChanged: () {});
    await initializeDefaultData();
  }

  @override
  Future<void> registerToApp(
    PluginManager pluginManager,
    ConfigManager configManager,
  ) async {
    await initialize();
  }

  @override
  Widget buildMainView(BuildContext context) {
    return CalendarAlbumMainView();
  }

  @override
  Widget? buildCardView(BuildContext context) {
    final theme = Theme.of(context);

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
                  color: Colors.blue.withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 24, color: color ?? theme.primaryColor),
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
              // 第一行 - 今日日记和七日日记
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // 今日日记
                  Column(
                    children: [
                      Text(
                        CalendarAlbumLocalizations.of(context).todayDiary,
                        style: theme.textTheme.bodyMedium,
                      ),
                      Text(
                        '${calendarController.getTodayEntriesCount()} ${CalendarAlbumLocalizations.of(context).entriesUnit}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  // 七日日记
                  Column(
                    children: [
                      Text(
                        CalendarAlbumLocalizations.of(context).sevenDayDiary,
                        style: theme.textTheme.bodyMedium,
                      ),
                      Text(
                        '${calendarController.getLast7DaysEntriesCount()} ${CalendarAlbumLocalizations.of(context).entriesUnit}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 第二行 - 所有日记和标签
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // 所有日记
                  Column(
                    children: [
                      Text(
                        CalendarAlbumLocalizations.of(context).allDiaries,
                        style: theme.textTheme.bodyMedium,
                      ),
                      Text(
                        '${calendarController.getAllEntriesCount()} ${CalendarAlbumLocalizations.of(context).entriesUnit}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  // 标签数量
                  Column(
                    children: [
                      Text(
                        CalendarAlbumLocalizations.of(context).tagCount,
                        style: theme.textTheme.bodyMedium,
                      ),
                      Text(
                        '${tagController.tags.length} ${CalendarAlbumLocalizations.of(context).itemsUnit}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
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
  }
}
