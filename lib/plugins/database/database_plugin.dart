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

  @override
  Widget? buildCardView(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: FutureBuilder<int>(
        future: _service.getDatabaseCount(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final dbCount = snapshot.data!;

          return Column(
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
                    child: Icon(Icons.storage, size: 24, color: Colors.blue),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    DatabaseLocalizations.pluginName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 统计信息
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          Text('总数据库数', style: theme.textTheme.bodyMedium),
                          Text(
                            '$dbCount',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
