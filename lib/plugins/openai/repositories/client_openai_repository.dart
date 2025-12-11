/// OpenAI 插件 - 客户端 Repository 实现
///
/// 通过适配现有的 AgentController、ServiceProviderController 和 ModelController
/// 来实现 IOpenAIRepository 接口

import 'package:shared_models/repositories/openai/openai_repository.dart';
import 'package:shared_models/utils/result.dart';
import 'package:shared_models/utils/pagination.dart';
import 'package:Memento/plugins/openai/controllers/agent_controller.dart';
import 'package:Memento/plugins/openai/controllers/service_provider_controller.dart';
import 'package:Memento/plugins/openai/controllers/model_controller.dart';
import 'package:Memento/plugins/openai/models/ai_agent.dart';
import 'package:Memento/plugins/openai/models/service_provider.dart';
import 'package:Memento/plugins/openai/models/llm_models.dart';

/// 客户端 OpenAI Repository 实现
class ClientOpenAIRepository implements IOpenAIRepository {
  final AgentController agentController;
  final ServiceProviderController serviceProviderController;
  final ModelController modelController;

  ClientOpenAIRepository({
    required this.agentController,
    required this.serviceProviderController,
    required this.modelController,
  });

  // ============ AI 助手操作 ============

  @override
  Future<Result<List<OpenAIAgentDto>>> getAgents({
    PaginationParams? pagination,
  }) async {
    try {
      final agents = await agentController.loadAgents();
      final dtos = agents.map(_agentToDto).toList();

      if (pagination != null && pagination.hasPagination) {
        final paginated = PaginationUtils.paginate(
          dtos,
          offset: pagination.offset,
          count: pagination.count,
        );
        return Result.success(paginated.data);
      }

      return Result.success(dtos);
    } catch (e) {
      return Result.failure('获取 AI 助手失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<OpenAIAgentDto?>> getAgentById(String id) async {
    try {
      final agent = await agentController.getAgent(id);
      return Result.success(agent != null ? _agentToDto(agent) : null);
    } catch (e) {
      return Result.failure('获取 AI 助手失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<OpenAIAgentDto>> createAgent(OpenAIAgentDto dto) async {
    try {
      final agent = _dtoToAgent(dto);
      await agentController.saveAgent(agent);
      return Result.success(_agentToDto(agent));
    } catch (e) {
      return Result.failure('创建 AI 助手失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<OpenAIAgentDto>> updateAgent(String id, OpenAIAgentDto dto) async {
    try {
      final agent = _dtoToAgent(dto);
      await agentController.saveAgent(agent);
      return Result.success(_agentToDto(agent));
    } catch (e) {
      return Result.failure('更新 AI 助手失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<bool>> deleteAgent(String id) async {
    try {
      await agentController.deleteAgent(id);
      return Result.success(true);
    } catch (e) {
      return Result.failure('删除 AI 助手失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<List<OpenAIAgentDto>>> searchAgents(OpenAIAgentQuery query) async {
    try {
      final agents = await agentController.loadAgents();
      final List<AIAgent> filtered = [];

      for (final agent in agents) {
        bool isMatch = false;

        // 按名称关键词搜索
        if (query.nameKeyword != null) {
          isMatch = agent.name.toLowerCase().contains(
            query.nameKeyword!.toLowerCase(),
          );
        }

        // 按服务商ID搜索
        if (!isMatch && query.serviceProviderId != null) {
          isMatch = agent.serviceProviderId == query.serviceProviderId;
        }


        if (!isMatch && query.tags != null && query.tags!.isNotEmpty) {
          isMatch = query.tags!.any(
            (tag) => agent.tags.contains(tag),
          );
        }

        if (isMatch) {
          filtered.add(agent);
          if (query.pagination == null || !query.pagination!.hasPagination) {
            // 如果没有分页参数，找到第一个匹配项就停止
            break;
          }
        }
      }

      final dtos = filtered.map(_agentToDto).toList();

      if (query.pagination != null && query.pagination!.hasPagination) {
        final paginated = PaginationUtils.paginate(
          dtos,
          offset: query.pagination!.offset,
          count: query.pagination!.count,
        );
        return Result.success(paginated.data);
      }

      return Result.success(dtos);
    } catch (e) {
      return Result.failure('搜索 AI 助手失败: $e', code: ErrorCodes.serverError);
    }
  }

  // ============ 服务商操作 ============

  @override
  Future<Result<List<OpenAIServiceProviderDto>>> getServiceProviders({
    PaginationParams? pagination,
  }) async {
    try {
      final providers = await serviceProviderController.loadProviders();
      final dtos = providers.map(_providerToDto).toList();

      if (pagination != null && pagination.hasPagination) {
        final paginated = PaginationUtils.paginate(
          dtos,
          offset: pagination.offset,
          count: pagination.count,
        );
        return Result.success(paginated.data);
      }

      return Result.success(dtos);
    } catch (e) {
      return Result.failure('获取服务商失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<OpenAIServiceProviderDto?>> getServiceProviderById(
    String id,
  ) async {
    try {
      final providers = await serviceProviderController.loadProviders();
      final provider = providers.firstWhere(
        (p) => p.id == id,
        orElse: () => throw Exception('Provider not found'),
      );
      return Result.success(_providerToDto(provider));
    } catch (e) {
      return Result.failure('获取服务商失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<OpenAIServiceProviderDto>> createServiceProvider(
    OpenAIServiceProviderDto dto,
  ) async {
    try {
      final provider = _dtoToProvider(dto);
      await serviceProviderController.saveProvider(provider);
      return Result.success(_providerToDto(provider));
    } catch (e) {
      return Result.failure('创建服务商失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<OpenAIServiceProviderDto>> updateServiceProvider(
    String id,
    OpenAIServiceProviderDto dto,
  ) async {
    try {
      final provider = _dtoToProvider(dto);
      await serviceProviderController.saveProvider(provider);
      return Result.success(_providerToDto(provider));
    } catch (e) {
      return Result.failure('更新服务商失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<bool>> deleteServiceProvider(String id) async {
    try {
      // 注意：ServiceProviderController 使用的是 label 作为标识
      // 这里需要通过 ID 查找对应的 label
      final providers = await serviceProviderController.loadProviders();
      final provider = providers.firstWhere(
        (p) => p.id == id,
        orElse: () => throw Exception('Provider not found'),
      );
      await serviceProviderController.deleteProvider(provider.label);
      return Result.success(true);
    } catch (e) {
      return Result.failure('删除服务商失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<List<OpenAIServiceProviderDto>>> searchServiceProviders(
    OpenAIServiceProviderQuery query,
  ) async {
    try {
      final providers = await serviceProviderController.loadProviders();
      final List<ServiceProvider> filtered = [];

      for (final provider in providers) {
        bool isMatch = false;

        // 按名称关键词搜索
        if (query.nameKeyword != null) {
          isMatch = provider.label.toLowerCase().contains(
            query.nameKeyword!.toLowerCase(),
          );
        }

        if (isMatch) {
          filtered.add(provider);
          if (query.pagination == null || !query.pagination!.hasPagination) {
            break;
          }
        }
      }

      final dtos = filtered.map(_providerToDto).toList();

      if (query.pagination != null && query.pagination!.hasPagination) {
        final paginated = PaginationUtils.paginate(
          dtos,
          offset: query.pagination!.offset,
          count: query.pagination!.count,
        );
        return Result.success(paginated.data);
      }

      return Result.success(dtos);
    } catch (e) {
      return Result.failure('搜索服务商失败: $e', code: ErrorCodes.serverError);
    }
  }

  // ============ 工具应用操作 ============

  @override
  Future<Result<List<OpenAIToolAppDto>>> getToolApps({
    PaginationParams? pagination,
  }) async {
    try {
      // 注意：当前没有专门的 ToolAppController
      // ToolApp 数据可能需要从其他方式获取，这里先返回空列表
      // TODO: 实现 ToolApp 的存储和管理

      final dtos = <OpenAIToolAppDto>[];

      if (pagination != null && pagination.hasPagination) {
        final paginated = PaginationUtils.paginate(
          dtos,
          offset: pagination.offset,
          count: pagination.count,
        );
        return Result.success(paginated.data);
      }

      return Result.success(dtos);
    } catch (e) {
      return Result.failure('获取工具应用失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<OpenAIToolAppDto?>> getToolAppById(String id) async {
    try {
      // TODO: 实现 ToolApp 的存储和管理
      return Result.success(null);
    } catch (e) {
      return Result.failure('获取工具应用失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<OpenAIToolAppDto>> createToolApp(OpenAIToolAppDto dto) async {
    try {
      // TODO: 实现 ToolApp 的存储和管理
      return Result.success(dto);
    } catch (e) {
      return Result.failure('创建工具应用失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<OpenAIToolAppDto>> updateToolApp(
    String id,
    OpenAIToolAppDto dto,
  ) async {
    try {
      // TODO: 实现 ToolApp 的存储和管理
      return Result.success(dto);
    } catch (e) {
      return Result.failure('更新工具应用失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<bool>> deleteToolApp(String id) async {
    try {
      // TODO: 实现 ToolApp 的存储和管理
      return Result.success(true);
    } catch (e) {
      return Result.failure('删除工具应用失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<List<OpenAIToolAppDto>>> searchToolApps(
    OpenAIToolAppQuery query,
  ) async {
    try {
      // TODO: 实现 ToolApp 的存储和管理
      final dtos = <OpenAIToolAppDto>[];

      if (query.pagination != null && query.pagination!.hasPagination) {
        final paginated = PaginationUtils.paginate(
          dtos,
          offset: query.pagination!.offset,
          count: query.pagination!.count,
        );
        return Result.success(paginated.data);
      }

      return Result.success(dtos);
    } catch (e) {
      return Result.failure('搜索工具应用失败: $e', code: ErrorCodes.serverError);
    }
  }

  // ============ 模型操作 ============

  @override
  Future<Result<List<OpenAIModelDto>>> getModels({
    PaginationParams? pagination,
  }) async {
    try {
      final modelGroups = await modelController.getModels();
      final List<OpenAIModelDto> allModels = [];

      for (final group in modelGroups) {
        for (final model in group.models) {
          allModels.add(_modelToDto(model));
        }
      }

      if (pagination != null && pagination.hasPagination) {
        final paginated = PaginationUtils.paginate(
          allModels,
          offset: pagination.offset,
          count: pagination.count,
        );
        return Result.success(paginated.data);
      }

      return Result.success(allModels);
    } catch (e) {
      return Result.failure('获取模型失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<OpenAIModelDto?>> getModelById(String id) async {
    try {
      final model = await modelController.getModelById(id);
      if (model == null) {
        return Result.success(null);
      }
      return Result.success(_modelToDto(model));
    } catch (e) {
      return Result.failure('获取模型失败: $e', code: ErrorCodes.serverError);
    }
  }

  // ============ 转换方法 ============

  OpenAIAgentDto _agentToDto(AIAgent agent) {
    return OpenAIAgentDto(
      id: agent.id,
      name: agent.name,
      description: agent.description,
      systemPrompt: agent.systemPrompt,
      tags: agent.tags,
      serviceProviderId: agent.serviceProviderId,
      baseUrl: agent.baseUrl,
      headers: agent.headers,
      createdAt: agent.createdAt,
      updatedAt: agent.updatedAt,
      model: agent.model,
      temperature: agent.temperature,
      maxLength: agent.maxLength,
      topP: agent.topP,
      frequencyPenalty: agent.frequencyPenalty,
      presencePenalty: agent.presencePenalty,
      stop: agent.stop,
      avatarUrl: agent.avatarUrl,
      enableFunctionCalling: agent.enableFunctionCalling,
      promptPresetId: agent.promptPresetId,
      enableOpeningQuestions: agent.enableOpeningQuestions,
      openingQuestions: agent.openingQuestions,
    );
  }

  AIAgent _dtoToAgent(OpenAIAgentDto dto) {
    return AIAgent(
      id: dto.id,
      name: dto.name,
      description: dto.description,
      systemPrompt: dto.systemPrompt,
      tags: dto.tags,
      serviceProviderId: dto.serviceProviderId,
      baseUrl: dto.baseUrl,
      headers: dto.headers,
      createdAt: dto.createdAt,
      updatedAt: dto.updatedAt,
      model: dto.model,
      temperature: dto.temperature,
      maxLength: dto.maxLength,
      topP: dto.topP,
      frequencyPenalty: dto.frequencyPenalty,
      presencePenalty: dto.presencePenalty,
      stop: dto.stop,
      avatarUrl: dto.avatarUrl,
      enableFunctionCalling: dto.enableFunctionCalling,
      promptPresetId: dto.promptPresetId,
      enableOpeningQuestions: dto.enableOpeningQuestions,
      openingQuestions: dto.openingQuestions,
    );
  }

  OpenAIServiceProviderDto _providerToDto(ServiceProvider provider) {
    return OpenAIServiceProviderDto(
      id: provider.id,
      label: provider.label,
      baseUrl: provider.baseUrl,
      headers: provider.headers,
      defaultModel: provider.defaultModel,
    );
  }

  ServiceProvider _dtoToProvider(OpenAIServiceProviderDto dto) {
    return ServiceProvider(
      id: dto.id,
      label: dto.label,
      baseUrl: dto.baseUrl,
      headers: dto.headers,
      defaultModel: dto.defaultModel,
    );
  }

  OpenAIModelDto _modelToDto(LLMModel model) {
    return OpenAIModelDto(
      id: model.id,
      name: model.name,
      description: model.description,
      url: model.url,
      group: model.group,
    );
  }
}
