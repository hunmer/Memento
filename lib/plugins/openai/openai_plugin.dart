import 'dart:convert';
import 'package:flutter/material.dart';
import '../base_plugin.dart';
import '../../core/plugin_manager.dart';
import '../../core/config_manager.dart';
import 'screens/agent_list_screen.dart';
import 'models/service_provider.dart';
import 'controllers/agent_controller.dart';
import 'screens/provider_settings_screen.dart';

class OpenAIPlugin extends BasePlugin {
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
            'type': 'Assistant',
            'systemPrompt': '你是一个乐于助人的AI助手，擅长回答问题并提供有用的建议。请用友好的语气与用户交流。',
            'tags': ['通用', '问答', '建议'],
            'createdAt': DateTime.now().toIso8601String(),
            'updatedAt': DateTime.now().toIso8601String(),
          },
          {
            'id': 'translator-1',
            'name': '多语言翻译',
            'description': '精通多种语言的翻译助手，可以帮助翻译各种文本内容。',
            'type': 'Translator',
            'systemPrompt':
                '你是一个专业的翻译助手。请准确理解原文的含义，并以地道的方式翻译成目标语言。注意保持文体风格的一致性。',
            'tags': ['翻译', '多语言', '本地化'],
            'createdAt': DateTime.now().toIso8601String(),
            'updatedAt': DateTime.now().toIso8601String(),
          },
          {
            'id': 'writer-1',
            'name': '创意写手',
            'description': '富有创造力的写作助手，可以帮助创作各类文学作品。',
            'type': 'Writer',
            'systemPrompt':
                '你是一个富有创造力的写作助手。请根据用户的需求，创作出生动有趣、引人入胜的内容。注意文章的结构和情节发展。',
            'tags': ['写作', '创意', '文学'],
            'createdAt': DateTime.now().toIso8601String(),
            'updatedAt': DateTime.now().toIso8601String(),
          },
          {
            'id': 'analyst-1',
            'name': '数据分析师',
            'description': '专业的数据分析助手，擅长处理和解释各类数据。',
            'type': 'Analyst',
            'systemPrompt': '你是一个专业的数据分析师。请帮助用户分析数据，发现数据中的模式和趋势，并提供有见地的分析报告。',
            'tags': ['数据', '分析', '报告'],
            'createdAt': DateTime.now().toIso8601String(),
            'updatedAt': DateTime.now().toIso8601String(),
          },
          {
            'id': 'developer-1',
            'name': '代码助手',
            'description': '专业的编程助手，可以帮助编写和优化代码。',
            'type': 'Developer',
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
            'type': 'Custom',
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
          'type': 'Assistant',
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
    return const ProviderSettingsScreen();
  }

  @override
  Future<void> registerToApp(
    PluginManager pluginManager,
    ConfigManager configManager,
  ) async {
    // Register plugin settings
    await configManager.savePluginConfig(id, {'providers': []});
  }

  @override
  Future<void> uninstall() async {
    // Clean up plugin data
    await storage.delete(storageDir);
  }
}
