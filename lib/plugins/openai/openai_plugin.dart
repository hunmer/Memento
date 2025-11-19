import 'dart:convert';
import 'package:Memento/plugins/openai/l10n/openai_localizations.dart';
import 'package:flutter/material.dart';
import '../base_plugin.dart';
import '../../core/plugin_manager.dart';
import '../../core/config_manager.dart';
import '../../core/js_bridge/js_bridge_plugin.dart';
import 'screens/agent_list_screen.dart';
import 'screens/plugin_settings_screen.dart';
import 'screens/prompt_preset_screen.dart';
import 'handlers/chat_event_handler.dart';
import 'controllers/agent_controller.dart';
import 'controllers/service_provider_controller.dart';
import 'services/request_service.dart';

class OpenAIPlugin extends BasePlugin with JSBridgePlugin {
  static OpenAIPlugin? _instance;
  static OpenAIPlugin get instance {
    if (_instance == null) {
      _instance = PluginManager.instance.getPlugin('openai') as OpenAIPlugin?;
      if (_instance == null) {
        throw StateError('OpenAIPlugin has not been initialized');
      }
    }
    return _instance!;
  }

  final ChatEventHandler _chatEventHandler = ChatEventHandler();

  @override
  String get id => 'openai';

  @override
  Color get color => Colors.deepOrange;

  @override
  Future<void> initialize() async {
    // Initialize default service providers
    await initializeDefaultData();

    // 初始化聊天事件处理器
    _chatEventHandler.initialize();

    // 注册 JS API（最后一步）
    await registerJSAPI();
  }

  @override
  Future<void> initializeDefaultData() async {
    // 确保 agents.json 文件存在并初始化默认智能体
    final agentData = await storage.read('openai/agents.json');
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
      child: const OpenAIMainView(),
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

  @override
  String? getPluginName(context) {
    return OpenAILocalizations.of(context).name;
  }

  // ==================== JS API 定义 ====================

  @override
  Map<String, Function> defineJSAPI() {
    return {
      // 助手管理
      'getAgents': _jsGetAgents,
      'getAgent': _jsGetAgent,

      // 消息发送（带超时处理）
      'sendMessage': _jsSendMessage,

      // 服务商管理
      'getProviders': _jsGetProviders,
      'testProvider': _jsTestProvider,
    };
  }

  // ==================== JS API 实现 ====================

  /// 获取所有 AI 助手列表
  Future<String> _jsGetAgents(Map<String, dynamic> params) async {
    try {
      final controller = AgentController();
      final agents = await controller.loadAgents();
      return jsonEncode(agents.map((a) => a.toJson()).toList());
    } catch (e) {
      return jsonEncode({'error': e.toString()});
    }
  }

  /// 获取指定助手信息
  Future<String> _jsGetAgent(Map<String, dynamic> params) async {
    // 必需参数
    final String? agentId = params['agentId'];
    if (agentId == null) {
      return jsonEncode({'error': '缺少必需参数: agentId'});
    }

    try {
      final controller = AgentController();
      final agent = await controller.getAgent(agentId);
      if (agent == null) {
        return jsonEncode({'error': 'Agent not found: $agentId'});
      }
      return jsonEncode(agent.toJson());
    } catch (e) {
      return jsonEncode({'error': e.toString()});
    }
  }

  /// 发送消息给 AI
  Future<String> _jsSendMessage(Map<String, dynamic> params) async {
    // 必需参数
    final String? agentId = params['agentId'];
    final String? message = params['message'];

    if (agentId == null) {
      return jsonEncode({'error': '缺少必需参数: agentId'});
    }
    if (message == null) {
      return jsonEncode({'error': '缺少必需参数: message'});
    }

    // 可选参数

    try {
      // 获取助手信息
      final controller = AgentController();
      final agent = await controller.getAgent(agentId);
      if (agent == null) {
        return jsonEncode({'error': 'Agent not found: $agentId'});
      }

      // 解析上下文消息（如果有）
      // 这里使用简化的流式响应收集完整结果
      final StringBuffer responseBuffer = StringBuffer();
      bool hasError = false;
      String? errorMessage;

      // 使用流式 API，设置 30 秒超时
      await RequestService.streamResponse(
        agent: agent,
        prompt: message,
        onToken: (token) {
          responseBuffer.write(token);
        },
        onError: (error) {
          hasError = true;
          errorMessage = error;
        },
        onComplete: () {
          // 完成回调
        },
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          hasError = true;
          errorMessage = 'Request timeout (30s)';
        },
      );

      if (hasError) {
        return jsonEncode({
          'error': errorMessage ?? 'Unknown error',
          'partial_response': responseBuffer.toString(),
        });
      }

      return jsonEncode({
        'success': true,
        'response': responseBuffer.toString(),
        'agent': agent.name,
      });
    } catch (e) {
      return jsonEncode({
        'error': e.toString(),
        'stack': e is Error ? e.stackTrace.toString() : null,
      });
    }
  }

  /// 获取所有服务商
  Future<String> _jsGetProviders(Map<String, dynamic> params) async {
    try {
      final controller = ServiceProviderController();
      final providers = await controller.loadProviders();
      return jsonEncode(providers.map((p) => p.toJson()).toList());
    } catch (e) {
      return jsonEncode({'error': e.toString()});
    }
  }

  /// 测试服务商连接
  Future<String> _jsTestProvider(Map<String, dynamic> params) async {
    // 必需参数
    final String? providerId = params['providerId'];
    if (providerId == null) {
      return jsonEncode({'error': '缺少必需参数: providerId'});
    }

    try {
      final controller = ServiceProviderController();
      await controller.loadProviders();

      // 根据 ID/label 查找服务商
      final provider = controller.providers.firstWhere(
        (p) => p.id == providerId || p.label == providerId,
        orElse: () => throw Exception('Provider not found: $providerId'),
      );

      // 获取该服务商的任意一个 agent 进行测试
      final agentController = AgentController();
      await agentController.loadAgents();

      final testAgent = agentController.agents.firstWhere(
        (a) => a.serviceProviderId == provider.id,
        orElse: () => throw Exception(
            'No agent configured for provider: ${provider.label}'),
      );

      // 发送简单的测试消息
      final response = await RequestService.chat(
        'Hello',
        testAgent,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Connection timeout'),
      );

      final success = !response.startsWith('Error:');
      return jsonEncode({
        'success': success,
        'provider': provider.label,
        'response': response.substring(0, response.length > 100 ? 100 : response.length),
      });
    } catch (e) {
      return jsonEncode({
        'success': false,
        'error': e.toString(),
      });
    }
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
                      color: color.withAlpha(30),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, size: 24, color: color),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    OpenAILocalizations.of(context).name,
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

class OpenAIMainView extends StatefulWidget {
  const OpenAIMainView({super.key});

  @override
  State<OpenAIMainView> createState() => _OpenAIMainViewState();
}

class _OpenAIMainViewState extends State<OpenAIMainView> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    AgentListScreen(),
    PromptPresetScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.smart_toy_outlined),
            selectedIcon: const Icon(Icons.smart_toy),
            label: OpenAILocalizations.of(context).agentsTab,
          ),
          NavigationDestination(
            icon: const Icon(Icons.text_snippet_outlined),
            selectedIcon: const Icon(Icons.text_snippet),
            label: OpenAILocalizations.of(context).promptPreset,
          ),
        ],
      ),
    );
  }
}
