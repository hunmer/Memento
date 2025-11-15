import 'package:flutter/material.dart';
import '../models/service_provider.dart';
import '../openai_plugin.dart';

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
        return [];
      }

      final List<dynamic> jsonList = data['providers'] as List<dynamic>;
      return jsonList
          .map((json) => ServiceProvider.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error loading providers: $e');
      return [];
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
      ),
      ServiceProvider(
        label: 'DeepSeek',
        id: 'deepseek',
        baseUrl: 'https://api.deepseek.com/v1',
        headers: {'api-key': 'YOUR_API_KEY'},
      ),
      ServiceProvider(
        id: 'openai',
        label: 'OpenAI',
        baseUrl: 'https://api.openai.com/v1',
        headers: {'Authorization': 'Bearer YOUR_API_KEY'},
      ),
      ServiceProvider(
        id: 'azure',
        label: 'Azure OpenAI',
        baseUrl: 'https://YOUR_RESOURCE_NAME.openai.azure.com',
        headers: {'api-key': 'YOUR_API_KEY', 'api-version': '2023-05-15'},
      ),
      ServiceProvider(
        id: 'anthropic',
        label: 'Anthropic (Claude)',
        baseUrl: 'https://api.anthropic.com/v1',
        headers: {
          'x-api-key': 'YOUR_API_KEY',
          'anthropic-version': '2023-06-01',
        },
      ),
      ServiceProvider(
        id: 'google',
        label: 'Google (Gemini)',
        baseUrl: 'https://generativelanguage.googleapis.com/v1',
        headers: {'x-goog-api-key': 'YOUR_API_KEY'},
      ),
      ServiceProvider(
        id: 'alibaba',
        label: '阿里云百炼 (通义千问)',
        baseUrl: 'https://dashscope.aliyuncs.com/compatible-mode/v1',
        headers: {'Authorization': 'Bearer YOUR_API_KEY'},
      ),
      ServiceProvider(
        id: 'zhipu',
        label: '智谱 AI (GLM)',
        baseUrl: 'https://open.bigmodel.cn/api/paas/v4',
        headers: {'Authorization': 'Bearer YOUR_API_KEY'},
      ),
      ServiceProvider(
        id: 'moonshot',
        label: '月之暗面 (Kimi)',
        baseUrl: 'https://api.moonshot.cn/v1',
        headers: {'Authorization': 'Bearer YOUR_API_KEY'},
      ),
      ServiceProvider(
        id: 'xfyun',
        label: '讯飞星火',
        baseUrl: 'https://spark-api-open.xf-yun.com/v1',
        headers: {'Authorization': 'Bearer YOUR_API_KEY'},
      ),
      ServiceProvider(
        id: 'openrouter',
        label: 'OpenRouter',
        baseUrl: 'https://openrouter.ai/api/v1',
        headers: {'Authorization': 'Bearer YOUR_API_KEY'},
      ),
      ServiceProvider(
        id: 'together',
        label: 'Together AI',
        baseUrl: 'https://api.together.xyz/v1',
        headers: {'Authorization': 'Bearer YOUR_API_KEY'},
      ),
      ServiceProvider(
        id: 'groq',
        label: 'Groq',
        baseUrl: 'https://api.groq.com/openai/v1',
        headers: {'Authorization': 'Bearer YOUR_API_KEY'},
      ),
      ServiceProvider(
        id: 'cohere',
        label: 'Cohere',
        baseUrl: 'https://api.cohere.ai/v1',
        headers: {'Authorization': 'Bearer YOUR_API_KEY'},
      ),
      ServiceProvider(
        id: 'perplexity',
        label: 'Perplexity',
        baseUrl: 'https://api.perplexity.ai',
        headers: {'Authorization': 'Bearer YOUR_API_KEY'},
      ),
    ];
  }
}
