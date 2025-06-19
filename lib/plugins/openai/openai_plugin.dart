import 'package:Memento/plugins/openai/l10n/openai_localizations.dart';
import 'package:flutter/material.dart';
import '../base_plugin.dart';
import '../../core/plugin_manager.dart';
import '../../core/config_manager.dart';
import 'screens/agent_list_screen.dart';
import 'screens/plugin_settings_screen.dart';
import 'handlers/chat_event_handler.dart';
import 'controllers/prompt_replacement_controller.dart';
import 'controllers/agent_controller.dart';

class OpenAIPlugin extends BasePlugin {
  static OpenAIPlugin? _instance;

  // 获取插件实例的静态方法
  static OpenAIPlugin get instance {
    if (_instance == null) {
      _instance = PluginManager.instance.getPlugin('openai') as OpenAIPlugin?;
      if (_instance == null) {
        throw StateError('OpenAIPlugin has not been initialized');
      }
    }
    return _instance!;
  }

  final PromptReplacementController _promptReplacementController =
      PromptReplacementController();
  final ChatEventHandler _chatEventHandler = ChatEventHandler();
  @override
  final String storageDir = 'openai';

  @override
  String get id => 'openai';

  @override
  String get name => 'AI Assistant'; // 保持英文ID不变

  @override
  String get description =>
      'AI assistant plugin supporting multiple LLM providers'; // 保持英文描述作为默认值

  @override
  String get author => 'Comate';

  @override
  Future<void> initialize() async {
    // Initialize default service providers
    await initializeDefaultData();

    // 初始化聊天事件处理器
    _chatEventHandler.initialize();
    // 初始化prompt替换控制器已在构造函数中完成
  }

  @override
  Future<void> initializeDefaultData() async {
    // 确保 agents.json 文件存在并初始化默认智能体
    final agentData = await storage.read('$storageDir/agents.json');
    if (agentData.isEmpty) {
      // 如果文件为空，创建包含默认智能体的文件
      final defaultAgents = [
        {
          'id': 'assistant-1',
          'name': '通用助手', // 默认使用中文，后续可通过UI更新
          'description': '一个友好的AI助手，可以帮助回答各种问题和完成各种任务。',
          'serviceProviderId': 'ollama',
          'baseUrl': 'http://localhost:11434',
          'headers': {'api-key': 'ollama'},
          'model': 'llama3',
          'systemPrompt': '你是一个乐于助人的AI助手，擅长回答问题并提供有用的建议。请用友好的语气与用户交流。',
          'tags': ['通用', '问答', '建议'],
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        },
      ];

      await storage.write('$storageDir/agents.json', {'agents': defaultAgents});
      debugPrint('已初始化默认智能体');
    }
  }

  @override
  Widget buildMainView(BuildContext context) {
    return Localizations.override(
      context: context,
      child: const AgentListScreen(),
    );
  }

  @override
  Widget buildSettingsView(BuildContext context) {
    return const PluginSettingsScreen();
  }

  @override
  Future<void> registerToApp(
    PluginManager pluginManager,
    ConfigManager configManager,
  ) async {
    // Register plugin settings
    await initialize();
    await configManager.savePluginConfig(id, {'providers': []});
  }

  Future<Map<String, dynamic>> _getAgentsData() async {
    try {
      final agentData = await storage.read('$storageDir/agents.json');
      if (agentData.isNotEmpty) {
        return Map<String, dynamic>.from(agentData);
      }
    } catch (e) {
      debugPrint('Error reading agents data: $e');
    }
    return {'agents': []};
  }

  @override
  Future<void> uninstall() async {
    // Clean up plugin data
    await storage.delete(storageDir);

    // 清理事件处理器
    _chatEventHandler.dispose();

    // 清理prompt替换控制器
    _promptReplacementController.dispose();
  }

  /// 注册prompt替换方法
  void registerPromptReplacementMethod(
    String methodName,
    PromptReplacementCallback callback,
  ) {
    _promptReplacementController.registerMethod(methodName, callback);
  }

  /// 注销prompt替换方法
  void unregisterPromptReplacementMethod(String methodName) {
    _promptReplacementController.unregisterMethod(methodName);
  }

  /// 获取prompt替换控制器实例
  PromptReplacementController getPromptReplacementController() {
    return _promptReplacementController;
  }

  /// 获取 AgentController 实例
  AgentController get controller => AgentController();

  @override
  IconData get icon => Icons.smart_toy;

  @override
  Widget buildCardView(BuildContext context) {
    return Localizations.override(
      context: context,
      child: _buildCardViewContent(context),
    );
  }

  Widget _buildCardViewContent(BuildContext context) {
    final theme = Theme.of(context);

    return FutureBuilder<Map<String, dynamic>>(
      future: _getAgentsData(),
      builder: (context, snapshot) {
        final agentsCount = (snapshot.data?['agents'] as List?)?.length ?? 0;
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
                    OpenAILocalizations.of(context).pluginName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 统计信息卡片
              Column(
                children: [
                  // 第一行 - 智能体总数和活跃智能体
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      // 智能体总数
                      Column(
                        children: [
                          Text(
                            OpenAILocalizations.of(context).totalAgents,
                            style: theme.textTheme.bodyMedium,
                          ),
                          Text(
                            '$agentsCount',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color:
                                  agentsCount > 0
                                      ? theme.colorScheme.primary
                                      : null,
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
