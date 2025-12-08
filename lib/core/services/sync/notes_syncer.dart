import 'package:flutter/material.dart';
import 'package:Memento/plugins/notes/notes_plugin.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'plugin_widget_syncer.dart';
import 'package:memento_widgets/memento_widgets.dart';

/// 笔记插件同步器
class NotesSyncer extends PluginWidgetSyncer {
  @override
  Future<void> sync() async {
    await syncSafely('notes', () async {
      final plugin = PluginManager.instance.getPlugin('notes') as NotesPlugin?;
      if (plugin == null) return;

      final totalNotes = plugin.getTotalNotesCount();
      final todayNotes = plugin.getTodayNotesCount();
      final totalWords = plugin.getTotalWordCount();

      await updateWidget(
        pluginId: 'notes',
        pluginName: '笔记',
        iconCodePoint: Icons.note.codePoint,
        colorValue: Colors.yellow.shade700.value,
        stats: [
          WidgetStatItem(id: 'total', label: '总笔记数', value: '$totalNotes'),
          WidgetStatItem(
            id: 'today',
            label: '今日新增',
            value: '$todayNotes',
            highlight: todayNotes > 0,
            colorValue: todayNotes > 0 ? Colors.deepOrange.value : null,
          ),
          WidgetStatItem(id: 'words', label: '总字数', value: '$totalWords'),
        ],
      );
    });
  }
}
