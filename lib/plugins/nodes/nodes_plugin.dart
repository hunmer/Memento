import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/plugin_base.dart';
import 'controllers/nodes_controller.dart';
import 'screens/notebooks_screen.dart';
import 'screens/nodes_screen.dart';
import 'l10n/nodes_localizations.dart';
import '../../core/storage/storage_manager.dart';

class NodesPlugin extends PluginBase {
  late NodesController _controller;

  NodesPlugin();

  @override
  String get id => 'nodes';

  @override
  String get name => 'Nodes';

  @override
  String get version => '1.0.0';

  @override
  String get description => 'A plugin for managing hierarchical notes';

  @override
  String get author => 'Memento Team';

  @override
  Future<void> initialize() async {
    _controller = NodesController(storage);
    await Future.delayed(Duration.zero); // Ensure initialization is complete
    debugPrint('Nodes plugin initialized');
  }

  @override
  Widget buildMainView(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<NodesController>.value(
          value: _controller,
        ),
      ],
      child: const NotebooksScreen(),
    );
  }

  @override
  Widget buildSettingsView(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nodes Settings'),
      ),
      body: super.buildSettingsView(context),
    );
  }

  @override
  IconData get icon => Icons.account_tree;

  @override
  List<Locale> get supportedLocales => const [
        Locale('en'),
        Locale('zh'),
      ];

  @override
  LocalizationsDelegate<NodesLocalizations> get localizationsDelegate =>
      NodesLocalizationsDelegate.delegate;
}

// Make the delegate public and add a static instance
class NodesLocalizationsDelegate extends LocalizationsDelegate<NodesLocalizations> {
  static final NodesLocalizationsDelegate delegate = NodesLocalizationsDelegate();

  const NodesLocalizationsDelegate();
  @override
  bool isSupported(Locale locale) {
    return ['en', 'zh'].contains(locale.languageCode);
  }

  @override
  Future<NodesLocalizations> load(Locale locale) async {
    return NodesLocalizations(locale);
  }

  @override
  bool shouldReload(NodesLocalizationsDelegate old) => false;
}