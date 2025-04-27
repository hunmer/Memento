import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/plugin_base.dart';
import 'controllers/nodes_controller.dart';
import 'screens/notebooks_screen.dart';
import 'l10n/nodes_localizations.dart';
import 'models/node.dart';

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
        ChangeNotifierProvider<NodesController>.value(value: _controller),
      ],
      child: const NotebooksScreen(),
    );
  }

  @override
  Widget buildSettingsView(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nodes Settings')),
      body: super.buildSettingsView(context),
    );
  }

  @override
  IconData get icon => Icons.account_tree;

  @override
  List<Locale> get supportedLocales => const [Locale('en'), Locale('zh')];

  @override
  LocalizationsDelegate<NodesLocalizations> get localizationsDelegate =>
      NodesLocalizationsDelegate.delegate;

  // 计算所有笔记本中的节点总数
  int _countAllNodes(List<Node> nodes) {
    int count = nodes.length;
    for (var node in nodes) {
      count += _countAllNodes(node.children);
    }
    return count;
  }

  // 计算所有待办节点数量
  int _countTodoNodes(List<Node> nodes) {
    int count = 0;
    for (var node in nodes) {
      if (node.status == NodeStatus.todo) {
        count++;
      }
      count += _countTodoNodes(node.children);
    }
    return count;
  }

  @override
  Widget buildCardView(BuildContext context) {
    final theme = Theme.of(context);

    return FutureBuilder<(int, int, int)>(
      future: Future(() {
        final notebookCount = _controller.notebooks.length;

        int totalNodes = 0;
        int todoNodes = 0;

        for (var notebook in _controller.notebooks) {
          totalNodes += _countAllNodes(notebook.nodes);
          todoNodes += _countTodoNodes(notebook.nodes);
        }

        return (notebookCount, totalNodes, todoNodes);
      }),
      builder: (context, snapshot) {
        final notebookCount = snapshot.data?.$1 ?? 0;
        final nodeCount = snapshot.data?.$2 ?? 0;
        final todoCount = snapshot.data?.$3 ?? 0;

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
                  color: theme.colorScheme.surfaceContainerHighest.withAlpha(
                    76,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    // 笔记本数量
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('笔记本数量', style: theme.textTheme.bodyMedium),
                        Text(
                          '$notebookCount',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color:
                                notebookCount > 0
                                    ? theme.colorScheme.primary
                                    : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Divider(),
                    const SizedBox(height: 8),

                    // 节点数量
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('节点数量', style: theme.textTheme.bodyMedium),
                        Text(
                          '$nodeCount',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Divider(),
                    const SizedBox(height: 8),

                    // 待办节点数量
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('待办节点数', style: theme.textTheme.bodyMedium),
                        Text(
                          '$todoCount',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color:
                                todoCount > 0
                                    ? theme.colorScheme.primary
                                    : null,
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
      },
    );
  }
}

// Make the delegate public and add a static instance
class NodesLocalizationsDelegate
    extends LocalizationsDelegate<NodesLocalizations> {
  static final NodesLocalizationsDelegate delegate =
      NodesLocalizationsDelegate();

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
