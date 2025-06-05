import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/plugin_manager.dart';
import '../../core/config_manager.dart';
import '../../core/storage/storage_manager.dart';
import '../base_plugin.dart';
import 'screens/main_screen.dart';
import 'controllers/calendar_controller.dart';
import 'controllers/tag_controller.dart';

class CalendarAlbumPlugin extends BasePlugin {
  @override
  String get id => 'calendar_album_plugin';

  @override
  String get name => 'Calendar Album';

  @override
  String get version => '1.0.0';

  @override
  String get description => 'A calendar-based photo album and diary plugin';

  @override
  String get author => 'Zulu';

  @override
  Future<void> initialize() async {
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
        ChangeNotifierProvider(
          create: (context) => CalendarController(StorageManager()),
        ),
        ChangeNotifierProvider(
          create: (context) => TagController(StorageManager()),
        ),
      ],
      child: const MainScreen(),
    );
  }
}
