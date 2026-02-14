import 'package:flutter/material.dart';
import 'package:Memento/plugins/openai/models/service_provider.dart';
import 'package:Memento/plugins/openai/openai_plugin.dart';

class ProviderController {
  // 使用OpenAI插件的storage
  final storage = OpenAIPlugin().storage;
  final String storageKey = 'providers.json';
  final String storagePath;

  ProviderController()
    : storagePath = '${OpenAIPlugin().storageDir}/providers.json';

  // 获取所有服务商
  Future<List<ServiceProvider>> getProviders() async {
    try {
      final data = await storage.read(storagePath);

      if (data.isEmpty) {
        // 首次使用，加载默认服务商并保存
        final defaultProviders = getDefaultProviders();
        await saveProviders(defaultProviders);
        return defaultProviders;
      }

      final List<dynamic> jsonList = data['providers'] as List<dynamic>;
      final providers = jsonList
          .map((json) => ServiceProvider.fromJson(json as Map<String, dynamic>))
          .toList();

      // 智能合并：检查是否有新的默认服务商，如果有则添加
      final defaultProviders = getDefaultProviders();
      bool hasNewProviders = false;

      for (final defaultProvider in defaultProviders) {
        final exists = providers.any((p) => p.id == defaultProvider.id);
        if (!exists) {
          providers.add(defaultProvider);
          hasNewProviders = true;
        }
      }

      // 如果有新增的服务商，保存到本地存储
      if (hasNewProviders) {
        await saveProviders(providers);
      }

      return providers;
    } catch (e) {
      debugPrint('Error loading providers: $e');
      // 加载失败时，返回默认服务商列表而不是空列表
      return getDefaultProviders();
    }
  }

  // 保存所有服务商
  Future<void> saveProviders(List<ServiceProvider> providers) async {
    try {
      await storage.write(storagePath, {
        'providers': providers.map((p) => p.toJson()).toList(),
      });
    } catch (e) {
      debugPrint('Error saving providers: $e');
      throw Exception('Failed to save providers');
    }
  }

  // 添加服务商
  Future<void> addProvider(ServiceProvider provider) async {
    final providers = await getProviders();
    if (providers.any((p) => p.id == provider.id)) {
      throw Exception('Provider with ID ${provider.id} already exists');
    }
    providers.add(provider);
    await saveProviders(providers);
  }

  // 更新服务商
  Future<void> updateProvider(ServiceProvider provider) async {
    final providers = await getProviders();
    final index = providers.indexWhere((p) => p.id == provider.id);
    if (index == -1) {
      throw Exception('Provider with ID ${provider.id} not found');
    }
    providers[index] = provider;
    await saveProviders(providers);
  }

  // 删除服务商
  Future<void> deleteProvider(String id) async {
    final providers = await getProviders();
    providers.removeWhere((p) => p.id == id);
    await saveProviders(providers);
  }

  // 获取默认服务商列表
  List<ServiceProvider> getDefaultProviders() {
    return [
      ServiceProvider(
        label: 'Ollama',
        id: 'ollama',
        baseUrl: 'http://localhost:11434',
        headers: {'api-key': 'YOUR_API_KEY'},
        apiFormat: 'openai',
      ),
      ServiceProvider(
        label: 'DeepSeek',
        id: 'deepseek',
        baseUrl: 'https://api.deepseek.com/v1',
        headers: {'api-key': 'YOUR_API_KEY'},
        apiFormat: 'openai',
      ),
      ServiceProvider(
        id: 'openai',
        label: 'OpenAI',
        baseUrl: 'https://api.openai.com/v1',
        headers: {'Authorization': 'Bearer YOUR_API_KEY'},
        apiFormat: 'openai',
      ),
      ServiceProvider(
        id: 'azure',
        label: 'Azure OpenAI',
        baseUrl: 'https://YOUR_RESOURCE_NAME.openai.azure.com',
        headers: {'api-key': 'YOUR_API_KEY', 'api-version': '2023-05-15'},
        apiFormat: 'openai',
      ),
      ServiceProvider(
        id: 'anthropic',
        label: 'Anthropic (Claude)',
        baseUrl: 'https://api.anthropic.com/v1',
        headers: {
          'x-api-key': 'YOUR_API_KEY',
          'anthropic-version': '2023-06-01',
        },
        apiFormat: 'anthropic',
      ),
      ServiceProvider(
        id: 'google',
        label: 'Google (Gemini)',
        baseUrl: 'https://generativelanguage.googleapis.com/v1',
        headers: {'x-goog-api-key': 'YOUR_API_KEY'},
        apiFormat: 'openai',
      ),
      ServiceProvider(
        id: 'alibaba',
        label: '阿里云百炼 (通义千问)',
        baseUrl: 'https://dashscope.aliyuncs.com/compatible-mode/v1',
        headers: {'Authorization': 'Bearer YOUR_API_KEY'},
        apiFormat: 'openai',
      ),
      ServiceProvider(
        id: 'zhipu',
        label: '智谱 AI (GLM)',
        baseUrl: 'https://open.bigmodel.cn/api/paas/v4',
        headers: {'Authorization': 'Bearer YOUR_API_KEY'},
        apiFormat: 'openai',
      ),
      ServiceProvider(
        id: 'moonshot',
        label: '月之暗面 (Kimi)',
        baseUrl: 'https://api.moonshot.cn/v1',
        headers: {'Authorization': 'Bearer YOUR_API_KEY'},
        apiFormat: 'openai',
      ),
      ServiceProvider(
        id: 'xfyun',
        label: '讯飞星火',
        baseUrl: 'https://spark-api-open.xf-yun.com/v1',
        headers: {'Authorization': 'Bearer YOUR_API_KEY'},
        apiFormat: 'openai',
      ),
      ServiceProvider(
        id: 'openrouter',
        label: 'OpenRouter',
        baseUrl: 'https://openrouter.ai/api/v1',
        headers: {'Authorization': 'Bearer YOUR_API_KEY'},
        apiFormat: 'openai',
      ),
      ServiceProvider(
        id: 'together',
        label: 'Together AI',
        baseUrl: 'https://api.together.xyz/v1',
        headers: {'Authorization': 'Bearer YOUR_API_KEY'},
        apiFormat: 'openai',
      ),
      ServiceProvider(
        id: 'groq',
        label: 'Groq',
        baseUrl: 'https://api.groq.com/openai/v1',
        headers: {'Authorization': 'Bearer YOUR_API_KEY'},
        apiFormat: 'openai',
      ),
      ServiceProvider(
        id: 'cohere',
        label: 'Cohere',
        baseUrl: 'https://api.cohere.ai/v1',
        headers: {'Authorization': 'Bearer YOUR_API_KEY'},
        apiFormat: 'openai',
      ),
      ServiceProvider(
        id: 'perplexity',
        label: 'Perplexity',
        baseUrl: 'https://api.perplexity.ai',
        headers: {'Authorization': 'Bearer YOUR_API_KEY'},
        apiFormat: 'openai',
      ),
      ServiceProvider(
        id: 'xai',
        label: 'xAI (Grok)',
        baseUrl: 'https://api.x.ai/v1',
        headers: {'Authorization': 'Bearer YOUR_API_KEY'},
        apiFormat: 'openai',
      ),
      ServiceProvider(
        id: 'mistral',
        label: 'Mistral AI',
        baseUrl: 'https://api.mistral.ai/v1',
        headers: {'Authorization': 'Bearer YOUR_API_KEY'},
        apiFormat: 'openai',
      ),
      ServiceProvider(
        id: 'minimax',
        label: 'MiniMax',
        baseUrl: 'https://api.minimax.chat/v1',
        headers: {'Authorization': 'Bearer YOUR_API_KEY'},
        defaultModel: 'MiniMax-M2.5',
        apiFormat: 'minimax',
      ),
    ];
  }
}
