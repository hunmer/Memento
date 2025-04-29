import 'package:flutter/material.dart';
import '../base_plugin.dart';
import '../../core/plugin_manager.dart';
import '../../core/config_manager.dart';
import 'screens/agent_list_screen.dart';
import 'screens/plugin_settings_screen.dart';
import 'handlers/chat_event_handler.dart';
import 'controllers/prompt_replacement_controller.dart';

class OpenAIPlugin extends BasePlugin {
  final ChatEventHandler _chatEventHandler = ChatEventHandler();
  final PromptReplacementController _promptReplacementController = PromptReplacementController();
  @override
  String get id => 'openai';

  @override
  String get name => 'AI Assistant';

  @override
  String get version => '1.0.0';

  @override
  String get description =>
      'AI assistant plugin supporting multiple LLM providers';

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
    try {
      final agentData = await storage.read('$storageDir/agents.json');
      if (agentData.isEmpty) {
        // 如果文件为空，创建包含默认智能体的文件
        final defaultAgents = [
          {
            'id': 'assistant-1',
            'name': '通用助手',
            'description': '一个友好的AI助手，可以帮助回答各种问题和完成各种任务。',
            'serviceProviderId': 'ollama',
            'baseUrl': 'http://localhost:11434',
            'headers': {'api-key': 'ollama'},
            'model': 'llama3',
            'systemPrompt': '你是一个乐于助人的AI助手，擅长回答问题并提供有用的建议。请用友好的语气与用户交流。',
            'tags': ['通用', '问答', '建议'],
            'model': 'llama3',
            'createdAt': DateTime.now().toIso8601String(),
            'updatedAt': DateTime.now().toIso8601String(),
          },
          {
            'id': 'translator-1',
            'name': '多语言翻译',
            'description': '精通多种语言的翻译助手，可以帮助翻译各种文本内容。',
            'serviceProviderId': 'deepseek',
            'baseUrl': 'https://api.deepseek.com/v1',
            'headers': {'api-key': 'YOUR_API_KEY'},
            'systemPrompt':
                '你是一个专业的翻译助手。请准确理解原文的含义，并以地道的方式翻译成目标语言。注意保持文体风格的一致性。',
            'tags': ['翻译', '多语言', '本地化'],
            'model': 'deepseek-chat',
            'createdAt': DateTime.now().toIso8601String(),
            'updatedAt': DateTime.now().toIso8601String(),
          },
          {
            'id': 'writer-1',
            'name': '创意写手',
            'description': '富有创造力的写作助手，可以帮助创作各类文学作品。',
            'serviceProviderId': 'azure',
            'baseUrl': 'https://YOUR_RESOURCE_NAME.openai.azure.com',
            'headers': {'api-key': 'YOUR_API_KEY', 'api-version': '2023-05-15'},
            'systemPrompt':
                '你是一个富有创造力的写作助手。请根据用户的需求，创作出生动有趣、引人入胜的内容。注意文章的结构和情节发展。',
            'tags': ['写作', '创意', '文学'],
            'model': 'gpt-4',
            'createdAt': DateTime.now().toIso8601String(),
            'updatedAt': DateTime.now().toIso8601String(),
          },
          {
            'id': 'analyst-1',
            'name': '数据分析师',
            'description': '专业的数据分析助手，擅长处理和解释各类数据。',
            'serviceProviderId': 'ollama',
            'baseUrl': 'http://localhost:11434',
            'headers': {'api-key': 'ollama'},
            'systemPrompt': '你是一个专业的数据分析师。请帮助用户分析数据，发现数据中的模式和趋势，并提供有见地的分析报告。',
            'tags': ['数据', '分析', '报告'],
            'createdAt': DateTime.now().toIso8601String(),
            'updatedAt': DateTime.now().toIso8601String(),
          },
          {
            'id': 'developer-1',
            'name': '代码助手',
            'description': '专业的编程助手，可以帮助编写和优化代码。',
            'serviceProviderId': 'openai',
            'baseUrl': 'https://api.openai.com/v1',
            'headers': {'Authorization': 'Bearer YOUR_API_KEY'},
            'systemPrompt':
                '你是一个经验丰富的程序员。请帮助用户编写高质量的代码，解决编程问题，并提供最佳实践建议。注意代码的可读性和性能。',
            'tags': ['编程', '代码', '开发'],
            'createdAt': DateTime.now().toIso8601String(),
            'updatedAt': DateTime.now().toIso8601String(),
          },
          {
            'id': 'custom-1',
            'name': '头脑风暴',
            'description': '创意思维助手，帮助产生新想法和解决方案。',
            'serviceProviderId': 'deepseek',
            'baseUrl': 'https://api.deepseek.com/v1',
            'headers': {'api-key': 'YOUR_API_KEY'},
            'systemPrompt':
                '你是一个创意思维助手。请使用各种创新思维技巧，帮助用户进行头脑风暴，产生新颖的想法和解决方案。鼓励跳出思维定式。',
            'tags': ['创意', '思维', '创新'],
            'createdAt': DateTime.now().toIso8601String(),
            'updatedAt': DateTime.now().toIso8601String(),
          },
        ];

        await storage.write('$storageDir/agents.json', {
          'agents': defaultAgents,
        });
        debugPrint('已初始化默认智能体');
      }
    } catch (e) {
      // 如果发生错误，创建包含默认智能体的文件
      final defaultAgents = [
        {
          'id': 'assistant-1',
          'name': '通用助手',
          'description': '一个友好的AI助手，可以帮助回答各种问题和完成各种任务。',
          'serviceProviderId': 'openai',
          'baseUrl': 'https://api.openai.com/v1',
          'headers': {'Authorization': 'Bearer YOUR_API_KEY'},
          'systemPrompt': '你是一个乐于助人的AI助手，擅长回答问题并提供有用的建议。请用友好的语气与用户交流。',
          'tags': ['通用', '问答', '建议'],
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        },
      ];

      await storage.write('$storageDir/agents.json', {'agents': defaultAgents});
      debugPrint('已初始化默认智能体（仅基础助手）');
    }
  }

  @override
  Widget buildMainView(BuildContext context) {
    return const AgentListScreen();
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
  void registerPromptReplacementMethod(String methodName, PromptReplacementCallback callback) {
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

  @override
  IconData get icon => Icons.smart_toy;

  @override
  Widget buildCardView(BuildContext context) {
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
                    // 智能体总数
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('智能体总数', style: theme.textTheme.bodyMedium),
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
              ),
            ],
          ),
        );
      },
    );
  }
}
