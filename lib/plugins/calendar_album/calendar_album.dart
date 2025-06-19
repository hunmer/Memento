import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/plugin_manager.dart';
import '../../core/config_manager.dart';
import '../base_plugin.dart';
import 'screens/main_screen.dart';
import 'controllers/calendar_controller.dart';
import 'controllers/tag_controller.dart';

class CalendarAlbumPlugin extends BasePlugin {
  late final CalendarController _calendarController;
  late final TagController tagController;

  @override
  String get id => 'calendar_album_plugin';

  @override
  String get name => '日记相册';

  @override
  String get description => 'A calendar-based photo album and diary plugin';

  @override
  String get author => 'Zulu';

  @override
  IconData get icon => Icons.notes_rounded;

  @override
  Future<void> initialize() async {
    _calendarController = CalendarController();
    tagController = TagController(
      onTagsChanged: () {
        tagController.notifyListeners();
      },
    );
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
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _calendarController),
        ChangeNotifierProvider.value(value: tagController),
      ],
      child: const MainScreen(),
    );
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
                      Text('今日日记', style: theme.textTheme.bodyMedium),
                      Text(
                        '${_calendarController.getTodayEntriesCount()} 篇',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  // 七日日记
                  Column(
                    children: [
                      Text('七日日记', style: theme.textTheme.bodyMedium),
                      Text(
                        '${_calendarController.getLast7DaysEntriesCount()} 篇',
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
                      Text('所有日记', style: theme.textTheme.bodyMedium),
                      Text(
                        '${_calendarController.getAllEntriesCount()} 篇',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  // 标签数量
                  Column(
                    children: [
                      Text('标签数量', style: theme.textTheme.bodyMedium),
                      Text(
                        '${tagController.tags.length} 个',
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
