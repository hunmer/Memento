/// OpenAI 插件 - 服务端 Repository 实现
library;

import 'package:shared_models/shared_models.dart';
import '../services/plugin_data_service.dart';

class ServerOpenAIRepository implements IOpenAIRepository {
  final PluginDataService dataService;
  final String userId;

  static const String _pluginId = 'openai';

  ServerOpenAIRepository({
    required this.dataService,
    required this.userId,
  });

  // ============ 内部方法 ============

  Future<List<OpenAIAgentDto>> _readAllAgents() async {
    final data = await dataService.readPluginData(
      userId,
      _pluginId,
      'agents.json',
    );
    if (data == null) return [];

    final agents = data['agents'] as List<dynamic>? ?? [];
    return agents
        .map((e) => OpenAIAgentDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> _saveAllAgents(List<OpenAIAgentDto> agents) async {
    await dataService.writePluginData(
      userId,
      _pluginId,
      'agents.json',
      {'agents': agents.map((a) => a.toJson()).toList()},
    );
  }

  Future<List<OpenAIServiceProviderDto>> _readAllServiceProviders() async {
    final data = await dataService.readPluginData(
      userId,
      _pluginId,
      'service_providers.json',
    );
    if (data == null) return [];

    final providers = data['service_providers'] as List<dynamic>? ?? [];
    return providers
        .map(
            (e) => OpenAIServiceProviderDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> _saveAllServiceProviders(
      List<OpenAIServiceProviderDto> providers) async {
    await dataService.writePluginData(
      userId,
      _pluginId,
      'service_providers.json',
      {'service_providers': providers.map((p) => p.toJson()).toList()},
    );
  }

  Future<List<OpenAIToolAppDto>> _readAllToolApps() async {
    final data = await dataService.readPluginData(
      userId,
      _pluginId,
      'tool_apps.json',
    );
    if (data == null) return [];

    final toolApps = data['tool_apps'] as List<dynamic>? ?? [];
    return toolApps
        .map((e) => OpenAIToolAppDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> _saveAllToolApps(List<OpenAIToolAppDto> toolApps) async {
    await dataService.writePluginData(
      userId,
      _pluginId,
      'tool_apps.json',
      {'tool_apps': toolApps.map((t) => t.toJson()).toList()},
    );
  }

  List<OpenAIModelDto> _getAllModels() {
    // 预定义的模型列表（从 OpenAI 插件的 llm_models.dart 迁移）
    return [
      // DeepSeek 系列
      OpenAIModelDto(
        id: 'deepseek-v3.1',
        name: 'DeepSeek-V3.1',
        description:
            'Hybrid architecture model with thinking and non-thinking modes',
        url: 'https://huggingface.co/deepseek-ai/DeepSeek-V3.1',
        group: 'deepseek',
      ),
      OpenAIModelDto(
        id: 'deepseek-r1',
        name: 'DeepSeek-R1',
        description: 'Reasoning model series',
        url: 'https://www.deepseek.com/models',
        group: 'deepseek',
      ),
      // OpenAI 系列
      OpenAIModelDto(
        id: 'gpt-4',
        name: 'GPT-4',
        description: 'Most capable GPT-4 model',
        url: 'https://platform.openai.com/docs/models/gpt-4',
        group: 'openai',
      ),
      OpenAIModelDto(
        id: 'gpt-4-turbo',
        name: 'GPT-4 Turbo',
        description: 'Latest GPT-4 Turbo model',
        url: 'https://platform.openai.com/docs/models/gpt-4-turbo',
        group: 'openai',
      ),
      OpenAIModelDto(
        id: 'gpt-3.5-turbo',
        name: 'GPT-3.5 Turbo',
        description: 'Fast and cost-effective model',
        url: 'https://platform.openai.com/docs/models/gpt-3-5',
        group: 'openai',
      ),
      // Anthropic 系列
      OpenAIModelDto(
        id: 'claude-3-opus',
        name: 'Claude 3 Opus',
        description: 'Most powerful Claude 3 model',
        url: 'https://docs.anthropic.com/claude/docs/models-overview',
        group: 'anthropic',
      ),
      OpenAIModelDto(
        id: 'claude-3-sonnet',
        name: 'Claude 3 Sonnet',
        description: 'Balanced Claude 3 model',
        url: 'https://docs.anthropic.com/claude/docs/models-overview',
        group: 'anthropic',
      ),
      // Google 系列
      OpenAIModelDto(
        id: 'gemini-pro',
        name: 'Gemini Pro',
        description: 'Google Gemini Pro model',
        url: 'https://ai.google.dev/docs',
        group: 'google',
      ),
    ];
  }

  // ============ AI 助手操作实现 ============

  @override
  Future<Result<List<OpenAIAgentDto>>> getAgents(
      {PaginationParams? pagination}) async {
    try {
      var agents = await _readAllAgents();

      if (pagination != null && pagination.hasPagination) {
        final paginated = PaginationUtils.paginate(
          agents,
          offset: pagination.offset,
          count: pagination.count,
        );
        return Result.success(paginated.data);
      }

      return Result.success(agents);
    } catch (e) {
      return Result.failure('获取 AI 助手列表失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<OpenAIAgentDto?>> getAgentById(String id) async {
    try {
      final agents = await _readAllAgents();
      final agent = agents.where((a) => a.id == id).firstOrNull;
      return Result.success(agent);
    } catch (e) {
      return Result.failure('获取 AI 助手失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<OpenAIAgentDto>> createAgent(OpenAIAgentDto agent) async {
    try {
      final agents = await _readAllAgents();
      agents.add(agent);
      await _saveAllAgents(agents);
      return Result.success(agent);
    } catch (e) {
      return Result.failure('创建 AI 助手失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<OpenAIAgentDto>> updateAgent(
      String id, OpenAIAgentDto agent) async {
    try {
      final agents = await _readAllAgents();
      final index = agents.indexWhere((a) => a.id == id);

      if (index == -1) {
        return Result.failure('AI 助手不存在', code: ErrorCodes.notFound);
      }

      agents[index] = agent;
      await _saveAllAgents(agents);
      return Result.success(agent);
    } catch (e) {
      return Result.failure('更新 AI 助手失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<bool>> deleteAgent(String id) async {
    try {
      final agents = await _readAllAgents();
      final initialLength = agents.length;
      agents.removeWhere((a) => a.id == id);

      if (agents.length == initialLength) {
        return Result.failure('AI 助手不存在', code: ErrorCodes.notFound);
      }

      await _saveAllAgents(agents);
      return Result.success(true);
    } catch (e) {
      return Result.failure('删除 AI 助手失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<List<OpenAIAgentDto>>> searchAgents(
      OpenAIAgentQuery query) async {
    try {
      var agents = await _readAllAgents();

      // 按名称关键词过滤
      if (query.nameKeyword != null && query.nameKeyword!.isNotEmpty) {
        final keyword = query.nameKeyword!.toLowerCase();
        agents = agents
            .where((a) => a.name.toLowerCase().contains(keyword))
            .toList();
      }

      // 按服务商 ID 过滤
      if (query.serviceProviderId != null &&
          query.serviceProviderId!.isNotEmpty) {
        agents = agents
            .where((a) => a.serviceProviderId == query.serviceProviderId)
            .toList();
      }

      // 按标签过滤
      if (query.tags != null && query.tags!.isNotEmpty) {
        agents = agents
            .where((a) => a.tags.any((tag) => query.tags!.contains(tag)))
            .toList();
      }

      if (query.pagination != null && query.pagination!.hasPagination) {
        final paginated = PaginationUtils.paginate(
          agents,
          offset: query.pagination!.offset,
          count: query.pagination!.count,
        );
        return Result.success(paginated.data);
      }

      return Result.success(agents);
    } catch (e) {
      return Result.failure('搜索 AI 助手失败: $e', code: ErrorCodes.serverError);
    }
  }

  // ============ 服务商操作实现 ============

  @override
  Future<Result<List<OpenAIServiceProviderDto>>> getServiceProviders(
      {PaginationParams? pagination}) async {
    try {
      var providers = await _readAllServiceProviders();

      if (pagination != null && pagination.hasPagination) {
        final paginated = PaginationUtils.paginate(
          providers,
          offset: pagination.offset,
          count: pagination.count,
        );
        return Result.success(paginated.data);
      }

      return Result.success(providers);
    } catch (e) {
      return Result.failure('获取服务商列表失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<OpenAIServiceProviderDto?>> getServiceProviderById(
      String id) async {
    try {
      final providers = await _readAllServiceProviders();
      final provider = providers.where((p) => p.id == id).firstOrNull;
      return Result.success(provider);
    } catch (e) {
      return Result.failure('获取服务商失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<OpenAIServiceProviderDto>> createServiceProvider(
      OpenAIServiceProviderDto provider) async {
    try {
      final providers = await _readAllServiceProviders();
      providers.add(provider);
      await _saveAllServiceProviders(providers);
      return Result.success(provider);
    } catch (e) {
      return Result.failure('创建服务商失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<OpenAIServiceProviderDto>> updateServiceProvider(
      String id, OpenAIServiceProviderDto provider) async {
    try {
      final providers = await _readAllServiceProviders();
      final index = providers.indexWhere((p) => p.id == id);

      if (index == -1) {
        return Result.failure('服务商不存在', code: ErrorCodes.notFound);
      }

      providers[index] = provider;
      await _saveAllServiceProviders(providers);
      return Result.success(provider);
    } catch (e) {
      return Result.failure('更新服务商失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<bool>> deleteServiceProvider(String id) async {
    try {
      final providers = await _readAllServiceProviders();
      final initialLength = providers.length;
      providers.removeWhere((p) => p.id == id);

      if (providers.length == initialLength) {
        return Result.failure('服务商不存在', code: ErrorCodes.notFound);
      }

      await _saveAllServiceProviders(providers);
      return Result.success(true);
    } catch (e) {
      return Result.failure('删除服务商失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<List<OpenAIServiceProviderDto>>> searchServiceProviders(
      OpenAIServiceProviderQuery query) async {
    try {
      var providers = await _readAllServiceProviders();

      // 按标签关键词过滤
      if (query.nameKeyword != null && query.nameKeyword!.isNotEmpty) {
        final keyword = query.nameKeyword!.toLowerCase();
        providers = providers
            .where((p) => p.label.toLowerCase().contains(keyword))
            .toList();
      }

      if (query.pagination != null && query.pagination!.hasPagination) {
        final paginated = PaginationUtils.paginate(
          providers,
          offset: query.pagination!.offset,
          count: query.pagination!.count,
        );
        return Result.success(paginated.data);
      }

      return Result.success(providers);
    } catch (e) {
      return Result.failure('搜索服务商失败: $e', code: ErrorCodes.serverError);
    }
  }

  // ============ 工具应用操作实现 ============

  @override
  Future<Result<List<OpenAIToolAppDto>>> getToolApps(
      {PaginationParams? pagination}) async {
    try {
      var toolApps = await _readAllToolApps();

      if (pagination != null && pagination.hasPagination) {
        final paginated = PaginationUtils.paginate(
          toolApps,
          offset: pagination.offset,
          count: pagination.count,
        );
        return Result.success(paginated.data);
      }

      return Result.success(toolApps);
    } catch (e) {
      return Result.failure('获取工具应用列表失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<OpenAIToolAppDto?>> getToolAppById(String id) async {
    try {
      final toolApps = await _readAllToolApps();
      final toolApp = toolApps.where((t) => t.id == id).firstOrNull;
      return Result.success(toolApp);
    } catch (e) {
      return Result.failure('获取工具应用失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<OpenAIToolAppDto>> createToolApp(
      OpenAIToolAppDto toolApp) async {
    try {
      final toolApps = await _readAllToolApps();
      toolApps.add(toolApp);
      await _saveAllToolApps(toolApps);
      return Result.success(toolApp);
    } catch (e) {
      return Result.failure('创建工具应用失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<OpenAIToolAppDto>> updateToolApp(
      String id, OpenAIToolAppDto toolApp) async {
    try {
      final toolApps = await _readAllToolApps();
      final index = toolApps.indexWhere((t) => t.id == id);

      if (index == -1) {
        return Result.failure('工具应用不存在', code: ErrorCodes.notFound);
      }

      toolApps[index] = toolApp;
      await _saveAllToolApps(toolApps);
      return Result.success(toolApp);
    } catch (e) {
      return Result.failure('更新工具应用失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<bool>> deleteToolApp(String id) async {
    try {
      final toolApps = await _readAllToolApps();
      final initialLength = toolApps.length;
      toolApps.removeWhere((t) => t.id == id);

      if (toolApps.length == initialLength) {
        return Result.failure('工具应用不存在', code: ErrorCodes.notFound);
      }

      await _saveAllToolApps(toolApps);
      return Result.success(true);
    } catch (e) {
      return Result.failure('删除工具应用失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<List<OpenAIToolAppDto>>> searchToolApps(
      OpenAIToolAppQuery query) async {
    try {
      var toolApps = await _readAllToolApps();

      // 按标题关键词过滤
      if (query.titleKeyword != null && query.titleKeyword!.isNotEmpty) {
        final keyword = query.titleKeyword!.toLowerCase();
        toolApps = toolApps
            .where((t) => t.title.toLowerCase().contains(keyword))
            .toList();
      }

      if (query.pagination != null && query.pagination!.hasPagination) {
        final paginated = PaginationUtils.paginate(
          toolApps,
          offset: query.pagination!.offset,
          count: query.pagination!.count,
        );
        return Result.success(paginated.data);
      }

      return Result.success(toolApps);
    } catch (e) {
      return Result.failure('搜索工具应用失败: $e', code: ErrorCodes.serverError);
    }
  }

  // ============ 模型操作实现 ============

  @override
  Future<Result<List<OpenAIModelDto>>> getModels(
      {PaginationParams? pagination}) async {
    try {
      var models = _getAllModels();

      if (pagination != null && pagination.hasPagination) {
        final paginated = PaginationUtils.paginate(
          models,
          offset: pagination.offset,
          count: pagination.count,
        );
        return Result.success(paginated.data);
      }

      return Result.success(models);
    } catch (e) {
      return Result.failure('获取模型列表失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<OpenAIModelDto?>> getModelById(String id) async {
    try {
      final models = _getAllModels();
      final model = models.where((m) => m.id == id).firstOrNull;
      return Result.success(model);
    } catch (e) {
      return Result.failure('获取模型失败: $e', code: ErrorCodes.serverError);
    }
  }
}
