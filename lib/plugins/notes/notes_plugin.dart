import 'package:Memento/core/plugin_manager.dart';
import 'package:flutter/material.dart';
import '../base_plugin.dart';
import 'controllers/notes_controller.dart';
import 'screens/notes_screen.dart';
import 'l10n/notes_localizations.dart';
import 'controls/prompt_controller.dart';

class NotesPlugin extends BasePlugin {
  static NotesPlugin? _instance;
  static NotesPlugin get instance {
    if (_instance == null) {
      _instance = PluginManager.instance.getPlugin('notes') as NotesPlugin?;
      if (_instance == null) {
        throw StateError('NotesPlugin has not been initialized');
      }
    }
    return _instance!;
  }

  @override
  String? getPluginName(context) {
    return NotesLocalizations.of(context).name;
  }

  late NotesController controller;
  late NotesPromptController _promptController;
  bool _isInitialized = false;

  @override
  String get id => 'notes';

  @override
  Color get color => const Color.fromARGB(255, 61, 204, 185);

  @override
  IconData get icon => Icons.note_alt_outlined;

  @override
  Future<void> initialize() async {
    controller = NotesController(storage);
    _promptController = NotesPromptController();
    await controller.initialize();
    _promptController.initialize(controller);
    _isInitialized = true;
  }

  // 获取总笔记数
  int getTotalNotesCount() {
    if (!_isInitialized) return 0;
    return controller.searchNotes(query: '').length;
  }

  // 获取最近7天的笔记数
  int getRecentNotesCount() {
    if (!_isInitialized) return 0;
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));

    return controller
        .searchNotes(query: '', startDate: sevenDaysAgo, endDate: now)
        .length;
  }

  @override
  Widget? buildCardView(BuildContext context) {
    if (!_isInitialized) return null;

    final theme = Theme.of(context);
    final totalNotes = getTotalNotesCount();
    final recentNotes = getRecentNotesCount();

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
                  color: color.withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 24, color: color),
              ),
              const SizedBox(width: 12),
              Text(
                NotesLocalizations.of(context).name,

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
              // 第一行 - 总笔记数和七日笔记数
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // 总笔记数
                  Column(
                    children: [
                      Text(
                        NotesLocalizations.of(context).totalNotes,
                        style: theme.textTheme.bodyMedium,
                      ),
                      Text(
                        '$totalNotes',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  // 七日笔记数
                  Column(
                    children: [
                      Text(
                        NotesLocalizations.of(context).recentNotes,
                        style: theme.textTheme.bodyMedium,
                      ),
                      Text(
                        '$recentNotes',
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

  @override
  Widget buildMainView(BuildContext context) {
    return NotesMainView();
  }

  @override
  Future<void> registerToApp(pluginManager, configManager) async {
    // 注册插件到应用
    await initialize();
  }

  @override
  Future<void> uninstall() async {
    _promptController.unregisterPromptMethods();
    await super.uninstall();
  }

  @override
  String getPluginStoragePath() {
    return storage.getPluginStoragePath(id);
  }
}
