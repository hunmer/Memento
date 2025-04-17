import 'package:flutter/material.dart';
import '../base_plugin.dart';
import 'controllers/notes_controller.dart';
import 'screens/notes_screen.dart';

class NotesPlugin extends BasePlugin {
  late NotesController _controller;

  @override
  String get id => 'notes';

  @override
  String get name => 'Notes';

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
      await _controller.initialize();
    } catch (e) {
      debugPrint('Failed to initialize NotesPlugin: $e');
      rethrow;
    }
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
  String getPluginStoragePath() {
    return storage.getPluginStoragePath(id);
  }
}