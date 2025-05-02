import 'package:flutter/material.dart';
import '../base_plugin.dart';
import 'controllers/notes_controller.dart';
import 'screens/notes_screen.dart';
import 'l10n/notes_localizations.dart';
import 'controls/prompt_controller.dart';

class NotesPlugin extends BasePlugin {
  late NotesController _controller;
  late NotesPromptController _promptController;
  bool _isInitialized = false;

  @override
  String get id => 'notes';

  @override
  String get name =>  'Notes';

  @override
  String get author => 'Memento Team';

  @override
  String get description => 'A simple note-taking plugin for Memento';

  @override
  String get version => '1.0.0';

  @override
  IconData get icon => Icons.note_alt_outlined;

  @override
  Future<void> initialize() async {
    try {
      _controller = NotesController(storage);
      _promptController = NotesPromptController();
      await _controller.initialize();
      _promptController.initialize(_controller);
      _isInitialized = true;
    } catch (e) {
      debugPrint('Failed to initialize NotesPlugin: $e');
      rethrow;
    }
  }

  // 获取总笔记数
  int getTotalNotesCount() {
    if (!_isInitialized) return 0;
    return _controller.searchNotes(query: '').length;
  }

  // 获取最近7天的笔记数
  int getRecentNotesCount() {
    if (!_isInitialized) return 0;
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));

    return _controller
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
                  color: theme.primaryColor.withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 24, color: theme.primaryColor),
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
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 总笔记数
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      NotesLocalizations.of(context)?.totalNotes ?? 'Total Notes',
                      style: theme.textTheme.bodyMedium
                    ),
                    Text(
                      '$totalNotes',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color:
                            totalNotes > 0 ? theme.colorScheme.primary : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Divider(),
                const SizedBox(height: 8),
                // 七日笔记数
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('七日笔记数', style: theme.textTheme.bodyMedium),
                    Text(
                      '$recentNotes',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color:
                            recentNotes > 0 ? theme.colorScheme.primary : null,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget buildMainView(BuildContext context) {
    return NotesScreen(controller: _controller);
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
