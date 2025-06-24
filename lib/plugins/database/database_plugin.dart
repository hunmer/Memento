import 'package:Memento/core/config_manager.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'package:flutter/material.dart';
import '../base_plugin.dart';
import './l10n/database_localizations.dart';
import './services/database_service.dart';
import './widgets/database_list_widget.dart';

/// 数据库插件主视图
class DatabaseMainView extends StatefulWidget {
  const DatabaseMainView({super.key});
  @override
  State<DatabaseMainView> createState() => _DatabaseMainViewState();
}

class _DatabaseMainViewState extends State<DatabaseMainView> {
  late DatabasePlugin _plugin;
  @override
  Widget build(BuildContext context) {
    _plugin = DatabasePlugin.instance;
    return DatabaseListWidget(service: _plugin.service);
  }
}

class DatabasePlugin extends BasePlugin {
  late final DatabaseService service = DatabaseService(this);

  @override
  String get id => 'database';

  @override
  String get name => DatabaseLocalizations.pluginName;

  @override
  String get description => DatabaseLocalizations.pluginDescription;

  static DatabasePlugin? _instance;
  static DatabasePlugin get instance {
    if (_instance == null) {
      _instance =
          PluginManager.instance.getPlugin('database') as DatabasePlugin?;
      if (_instance == null) {
        throw StateError('DatabasePlugin has not been initialized');
      }
    }
    return _instance!;
  }

  @override
  Future<void> initialize() async {
    await service.initializeDefaultData();
  }

  @override
  Widget buildMainView(BuildContext context) {
    return DatabaseMainView();
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
        future: service.getDatabaseCount(),
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
