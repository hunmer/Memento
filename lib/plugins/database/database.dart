import 'package:Memento/core/config_manager.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'package:flutter/material.dart';
import '../base_plugin.dart';
import './l10n/database_localizations.dart';
import './services/database_service.dart';
import './widgets/database_list_widget.dart';

class DatabasePlugin extends BasePlugin {
  late final DatabaseService _service = DatabaseService(this);

  @override
  String get id => 'database_plugin';

  @override
  String get name => DatabaseLocalizations.pluginName;

  @override
  String get version => '1.0.0';

  @override
  String get description => DatabaseLocalizations.pluginDescription;

  @override
  String get author => 'Your Name';

  @override
  Future<void> initialize() async {
    await _service.initializeDefaultData();
  }

  @override
  Widget buildMainView(BuildContext context) {
    return DatabaseListWidget(service: _service);
  }

  @override
  Future<void> registerToApp(
    PluginManager pluginManager,
    ConfigManager configManager,
  ) async {
    await initialize();
  }
}
