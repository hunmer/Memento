import 'package:Memento/core/config_manager.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/plugin_base.dart';
import '../../core/plugin_manager.dart';
import '../openai/openai_plugin.dart';
import 'services/prompt_replacements.dart';
import 'controllers/nodes_controller.dart';
import 'screens/notebooks_screen.dart';
import 'l10n/nodes_localizations.dart';
import 'models/node.dart';

class NodesMainView extends StatefulWidget {
  const NodesMainView({super.key});

  @override
  State<NodesMainView> createState() => _NodesMainViewState();
}

class _NodesMainViewState extends State<NodesMainView> {
  late NodesPlugin _plugin;

  @override
  void initState() {
    super.initState();
    _plugin = NodesPlugin.instance;
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _plugin.controller,
      child: const NotebooksScreen(),
    );
  }
}

class NodesPlugin extends PluginBase {
  static NodesPlugin? _instance;
  static NodesPlugin get instance {
    if (_instance == null) {
      _instance = PluginManager.instance.getPlugin('nodes') as NodesPlugin?;
      if (_instance == null) {
        throw StateError('NodesPlugin has not been initialized');
      }
    }
    return _instance!;
  }

  late NodesController _controller;
  final NodesPromptReplacements _promptReplacements = NodesPromptReplacements();
  bool _isInitialized = false;

  NodesPlugin();

  NodesController get controller => _controller;

  @override
  String get id => 'nodes';

  @override
  String get name => 'Nodes';

  @override
  Future<void> initialize() async {
    _controller = NodesController(storage);
    _promptReplacements.initialize();

    // 延迟注册 prompt 替换方法，等待 OpenAI 插件初始化完成
    Future.delayed(const Duration(seconds: 1), () {
      _registerPromptMethods();
    });

    _isInitialized = true;
  }

  @override
  String? getPluginName(context) {
    return NodesLocalizations.of(context).name;
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
    // 确保controller已经初始化
    if (!_isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<NodesController>.value(value: _controller),
      ],
      child: const NodesMainView(),
    );
  }

  @override
  Widget buildSettingsView(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(NodesLocalizations.of(context).nodesSettings)),
      body: super.buildSettingsView(context),
    );
  }

  @override
  IconData get icon => Icons.account_tree;

  /// 注册 prompt 替换方法
  void _registerPromptMethods() {
    try {
      final openaiPlugin =
          PluginManager.instance.getPlugin('openai') as OpenAIPlugin?;
      if (openaiPlugin != null) {
        openaiPlugin.registerPromptReplacementMethod(
          'nodes_getNodePaths',
          _promptReplacements.getNodePaths,
        );
      } else {
        // 如果 OpenAI 插件还未准备好，5 秒后重试
        Future.delayed(const Duration(seconds: 5), _registerPromptMethods);
      }
    } catch (e) {
      // 发生错误时，5 秒后重试
      Future.delayed(const Duration(seconds: 5), _registerPromptMethods);
    }
  }

  /// 清理资源
  void dispose() {
    _promptReplacements.dispose();
  }

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

              Column(
                children: [
                  // 第一行 - 笔记本数量和节点数量
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      // 笔记本数量
                      Column(
                        children: [
                          Text(
                            NodesLocalizations.of(context).notebooksCount,
                            style: theme.textTheme.bodyMedium,
                          ),
                          Text(
                            '$notebookCount',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),

                      // 节点数量
                      Column(
                        children: [
                          Text(
                            NodesLocalizations.of(context).nodesCount,
                            style: theme.textTheme.bodyMedium,
                          ),
                          Text(
                            '$nodeCount',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // 第二行 - 待办节点数
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Column(
                        children: [
                          Text(
                            NodesLocalizations.of(context).pendingNodesCount,
                            style: theme.textTheme.bodyMedium,
                          ),
                          Text(
                            '$todoCount',
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
      },
    );
  }
}
