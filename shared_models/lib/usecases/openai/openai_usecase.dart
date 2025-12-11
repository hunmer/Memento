/// OpenAI 插件 - UseCase 业务逻辑层

import 'package:uuid/uuid.dart';
import 'package:shared_models/repositories/openai/openai_repository.dart';
import 'package:shared_models/utils/result.dart';
import 'package:shared_models/utils/pagination.dart';
import 'package:shared_models/utils/validation.dart';

/// OpenAI 插件 UseCase - 封装所有业务逻辑
class OpenAIUseCase {
  final IOpenAIRepository repository;
  final Uuid _uuid = const Uuid();

  OpenAIUseCase(this.repository);

  // ============ AI 助手 CRUD 操作 ============

  /// 获取 AI 助手列表
  ///
  /// [params] 可选参数:
  /// - `offset`: 起始偏移量
  /// - `count`: 返回数量
  Future<Result<dynamic>> getAgents(Map<String, dynamic> params) async {
    try {
      final pagination = _extractPagination(params);
      final result = await repository.getAgents(pagination: pagination);

      return result.map((agents) {
        final jsonList = agents.map((a) => a.toJson()).toList();

        if (pagination != null && pagination.hasPagination) {
          return PaginationUtils.toMap(
            jsonList,
            offset: pagination.offset,
            count: pagination.count,
          );
        }
        return jsonList;
      });
    } catch (e) {
      return Result.failure('获取 AI 助手列表失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 根据 ID 获取 AI 助手
  Future<Result<Map<String, dynamic>?>> getAgentById(
    Map<String, dynamic> params,
  ) async {
    final id = params['id'] as String?;
    if (id == null || id.isEmpty) {
      return Result.failure('缺少必需参数: id', code: ErrorCodes.invalidParams);
    }

    try {
      final result = await repository.getAgentById(id);
      return result.map((agent) => agent?.toJson());
    } catch (e) {
      return Result.failure('获取 AI 助手失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 创建 AI 助手
  ///
  /// [params] 必需参数:
  /// - `name`: 助手名称
  /// - `description`: 助手描述
  /// - `systemPrompt`: 系统提示词
  /// - `serviceProviderId`: 服务商 ID
  /// - `baseUrl`: API 基础 URL
  /// - `model`: 模型名称
  Future<Result<Map<String, dynamic>>> createAgent(
    Map<String, dynamic> params,
  ) async {
    // 参数验证
    final nameValidation = ParamValidator.requireString(params, 'name');
    if (!nameValidation.isValid) {
      return Result.failure(
        nameValidation.errorMessage!,
        code: ErrorCodes.invalidParams,
      );
    }

    final descriptionValidation = ParamValidator.requireString(params, 'description');
    if (!descriptionValidation.isValid) {
      return Result.failure(
        descriptionValidation.errorMessage!,
        code: ErrorCodes.invalidParams,
      );
    }

    final systemPromptValidation = ParamValidator.requireString(params, 'systemPrompt');
    if (!systemPromptValidation.isValid) {
      return Result.failure(
        systemPromptValidation.errorMessage!,
        code: ErrorCodes.invalidParams,
      );
    }

    final providerIdValidation = ParamValidator.requireString(params, 'serviceProviderId');
    if (!providerIdValidation.isValid) {
      return Result.failure(
        providerIdValidation.errorMessage!,
        code: ErrorCodes.invalidParams,
      );
    }

    final baseUrlValidation = ParamValidator.requireString(params, 'baseUrl');
    if (!baseUrlValidation.isValid) {
      return Result.failure(
        baseUrlValidation.errorMessage!,
        code: ErrorCodes.invalidParams,
      );
    }

    final modelValidation = ParamValidator.requireString(params, 'model');
    if (!modelValidation.isValid) {
      return Result.failure(
        modelValidation.errorMessage!,
        code: ErrorCodes.invalidParams,
      );
    }

    try {
      final now = DateTime.now();
      final agent = OpenAIAgentDto(
        id: params['id'] as String? ?? _uuid.v4(),
        name: params['name'] as String,
        description: params['description'] as String,
        systemPrompt: params['systemPrompt'] as String,
        tags: (params['tags'] as List<dynamic>?)?.cast<String>() ?? const [],
        serviceProviderId: params['serviceProviderId'] as String,
        baseUrl: params['baseUrl'] as String,
        headers: (params['headers'] as Map<String, String>?) ??
            (params['headers'] as Map<dynamic, dynamic>?)
                ?.map((k, v) => MapEntry(k as String, v as String)) ??
            {},
        createdAt: now,
        updatedAt: now,
        model: params['model'] as String,
        temperature: (params['temperature'] as num?)?.toDouble() ?? 0.7,
        maxLength: params['maxLength'] as int? ?? 2000,
        topP: (params['topP'] as num?)?.toDouble() ?? 1.0,
        frequencyPenalty: (params['frequencyPenalty'] as num?)?.toDouble() ?? 0.0,
        presencePenalty: (params['presencePenalty'] as num?)?.toDouble() ?? 0.0,
        stop: (params['stop'] as List<dynamic>?)?.cast<String>(),
        avatarUrl: params['avatarUrl'] as String?,
        enableFunctionCalling: params['enableFunctionCalling'] as bool? ?? false,
        promptPresetId: params['promptPresetId'] as String?,
        enableOpeningQuestions: params['enableOpeningQuestions'] as bool? ?? false,
        openingQuestions: (params['openingQuestions'] as List<dynamic>?)?.cast<String>() ?? const [],
      );

      final result = await repository.createAgent(agent);
      return result.map((a) => a.toJson());
    } catch (e) {
      return Result.failure('创建 AI 助手失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 更新 AI 助手
  Future<Result<Map<String, dynamic>>> updateAgent(
    Map<String, dynamic> params,
  ) async {
    final id = params['id'] as String?;
    if (id == null || id.isEmpty) {
      return Result.failure('缺少必需参数: id', code: ErrorCodes.invalidParams);
    }

    try {
      // 获取现有数据
      final existingResult = await repository.getAgentById(id);
      if (existingResult.isFailure) {
        return Result.failure('AI 助手不存在', code: ErrorCodes.notFound);
      }

      final existing = existingResult.dataOrNull;
      if (existing == null) {
        return Result.failure('AI 助手不存在', code: ErrorCodes.notFound);
      }

      // 合并更新
      final updated = existing.copyWith(
        name: params['name'] as String?,
        description: params['description'] as String?,
        systemPrompt: params['systemPrompt'] as String?,
        tags: params.containsKey('tags')
            ? (params['tags'] as List<dynamic>?)?.cast<String>() ?? existing.tags
            : existing.tags,
        serviceProviderId: params['serviceProviderId'] as String?,
        baseUrl: params['baseUrl'] as String?,
        headers: params.containsKey('headers')
            ? (params['headers'] as Map<dynamic, dynamic>?)
                ?.map((k, v) => MapEntry(k as String, v as String)) ??
                existing.headers
            : existing.headers,
        updatedAt: DateTime.now(),
        model: params['model'] as String?,
        temperature: params.containsKey('temperature')
            ? (params['temperature'] as num?)?.toDouble()
            : existing.temperature,
        maxLength: params['maxLength'] as int?,
        topP: params.containsKey('topP') ? (params['topP'] as num?)?.toDouble() : existing.topP,
        frequencyPenalty: params.containsKey('frequencyPenalty')
            ? (params['frequencyPenalty'] as num?)?.toDouble()
            : existing.frequencyPenalty,
        presencePenalty: params.containsKey('presencePenalty')
            ? (params['presencePenalty'] as num?)?.toDouble()
            : existing.presencePenalty,
        stop: params.containsKey('stop') ? (params['stop'] as List<dynamic>?)?.cast<String>() : existing.stop,
        avatarUrl: params['avatarUrl'] as String?,
        enableFunctionCalling: params['enableFunctionCalling'] as bool?,
        promptPresetId: params['promptPresetId'] as String?,
        enableOpeningQuestions: params['enableOpeningQuestions'] as bool?,
        openingQuestions: params.containsKey('openingQuestions')
            ? (params['openingQuestions'] as List<dynamic>?)?.cast<String>() ?? existing.openingQuestions
            : existing.openingQuestions,
      );

      final result = await repository.updateAgent(id, updated);
      return result.map((a) => a.toJson());
    } catch (e) {
      return Result.failure('更新 AI 助手失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 删除 AI 助手
  Future<Result<bool>> deleteAgent(Map<String, dynamic> params) async {
    final id = params['id'] as String?;
    if (id == null || id.isEmpty) {
      return Result.failure('缺少必需参数: id', code: ErrorCodes.invalidParams);
    }

    try {
      return repository.deleteAgent(id);
    } catch (e) {
      return Result.failure('删除 AI 助手失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 搜索 AI 助手
  Future<Result<dynamic>> searchAgents(Map<String, dynamic> params) async {
    try {
      final query = OpenAIAgentQuery(
        nameKeyword: params['nameKeyword'] as String?,
        serviceProviderId: params['serviceProviderId'] as String?,
        tags: params.containsKey('tags')
            ? (params['tags'] as List<dynamic>?)?.cast<String>()
            : null,
        pagination: _extractPagination(params),
      );

      final result = await repository.searchAgents(query);
      return result.map((agents) {
        final jsonList = agents.map((a) => a.toJson()).toList();

        if (query.pagination != null && query.pagination!.hasPagination) {
          return PaginationUtils.toMap(
            jsonList,
            offset: query.pagination!.offset,
            count: query.pagination!.count,
          );
        }
        return jsonList;
      });
    } catch (e) {
      return Result.failure('搜索 AI 助手失败: $e', code: ErrorCodes.serverError);
    }
  }

  // ============ 服务商 CRUD 操作 ============

  /// 获取服务商列表
  Future<Result<dynamic>> getServiceProviders(Map<String, dynamic> params) async {
    try {
      final pagination = _extractPagination(params);
      final result = await repository.getServiceProviders(pagination: pagination);

      return result.map((providers) {
        final jsonList = providers.map((p) => p.toJson()).toList();

        if (pagination != null && pagination.hasPagination) {
          return PaginationUtils.toMap(
            jsonList,
            offset: pagination.offset,
            count: pagination.count,
          );
        }
        return jsonList;
      });
    } catch (e) {
      return Result.failure('获取服务商列表失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 根据 ID 获取服务商
  Future<Result<Map<String, dynamic>?>> getServiceProviderById(
    Map<String, dynamic> params,
  ) async {
    final id = params['id'] as String?;
    if (id == null || id.isEmpty) {
      return Result.failure('缺少必需参数: id', code: ErrorCodes.invalidParams);
    }

    try {
      final result = await repository.getServiceProviderById(id);
      return result.map((provider) => provider?.toJson());
    } catch (e) {
      return Result.failure('获取服务商失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 创建服务商
  Future<Result<Map<String, dynamic>>> createServiceProvider(
    Map<String, dynamic> params,
  ) async {
    // 参数验证
    final idValidation = ParamValidator.requireString(params, 'id');
    if (!idValidation.isValid) {
      return Result.failure(
        idValidation.errorMessage!,
        code: ErrorCodes.invalidParams,
      );
    }

    final labelValidation = ParamValidator.requireString(params, 'label');
    if (!labelValidation.isValid) {
      return Result.failure(
        labelValidation.errorMessage!,
        code: ErrorCodes.invalidParams,
      );
    }

    final baseUrlValidation = ParamValidator.requireString(params, 'baseUrl');
    if (!baseUrlValidation.isValid) {
      return Result.failure(
        baseUrlValidation.errorMessage!,
        code: ErrorCodes.invalidParams,
      );
    }

    try {
      final provider = OpenAIServiceProviderDto(
        id: params['id'] as String,
        label: params['label'] as String,
        baseUrl: params['baseUrl'] as String,
        headers: (params['headers'] as Map<String, String>?) ??
            (params['headers'] as Map<dynamic, dynamic>?)
                ?.map((k, v) => MapEntry(k as String, v as String)) ??
            {},
        defaultModel: params['defaultModel'] as String?,
      );

      final result = await repository.createServiceProvider(provider);
      return result.map((p) => p.toJson());
    } catch (e) {
      return Result.failure('创建服务商失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 更新服务商
  Future<Result<Map<String, dynamic>>> updateServiceProvider(
    Map<String, dynamic> params,
  ) async {
    final id = params['id'] as String?;
    if (id == null || id.isEmpty) {
      return Result.failure('缺少必需参数: id', code: ErrorCodes.invalidParams);
    }

    try {
      // 获取现有数据
      final existingResult = await repository.getServiceProviderById(id);
      if (existingResult.isFailure) {
        return Result.failure('服务商不存在', code: ErrorCodes.notFound);
      }

      final existing = existingResult.dataOrNull;
      if (existing == null) {
        return Result.failure('服务商不存在', code: ErrorCodes.notFound);
      }

      // 合并更新
      final updated = existing.copyWith(
        label: params['label'] as String?,
        baseUrl: params['baseUrl'] as String?,
        headers: params.containsKey('headers')
            ? (params['headers'] as Map<dynamic, dynamic>?)
                ?.map((k, v) => MapEntry(k as String, v as String)) ??
                existing.headers
            : existing.headers,
        defaultModel: params['defaultModel'] as String?,
      );

      final result = await repository.updateServiceProvider(id, updated);
      return result.map((p) => p.toJson());
    } catch (e) {
      return Result.failure('更新服务商失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 删除服务商
  Future<Result<bool>> deleteServiceProvider(Map<String, dynamic> params) async {
    final id = params['id'] as String?;
    if (id == null || id.isEmpty) {
      return Result.failure('缺少必需参数: id', code: ErrorCodes.invalidParams);
    }

    try {
      return repository.deleteServiceProvider(id);
    } catch (e) {
      return Result.failure('删除服务商失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 搜索服务商
  Future<Result<dynamic>> searchServiceProviders(Map<String, dynamic> params) async {
    try {
      final query = OpenAIServiceProviderQuery(
        nameKeyword: params['nameKeyword'] as String?,
        pagination: _extractPagination(params),
      );

      final result = await repository.searchServiceProviders(query);
      return result.map((providers) {
        final jsonList = providers.map((p) => p.toJson()).toList();

        if (query.pagination != null && query.pagination!.hasPagination) {
          return PaginationUtils.toMap(
            jsonList,
            offset: query.pagination!.offset,
            count: query.pagination!.count,
          );
        }
        return jsonList;
      });
    } catch (e) {
      return Result.failure('搜索服务商失败: $e', code: ErrorCodes.serverError);
    }
  }

  // ============ 工具应用 CRUD 操作 ============

  /// 获取工具应用列表
  Future<Result<dynamic>> getToolApps(Map<String, dynamic> params) async {
    try {
      final pagination = _extractPagination(params);
      final result = await repository.getToolApps(pagination: pagination);

      return result.map((toolApps) {
        final jsonList = toolApps.map((t) => t.toJson()).toList();

        if (pagination != null && pagination.hasPagination) {
          return PaginationUtils.toMap(
            jsonList,
            offset: pagination.offset,
            count: pagination.count,
          );
        }
        return jsonList;
      });
    } catch (e) {
      return Result.failure('获取工具应用列表失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 根据 ID 获取工具应用
  Future<Result<Map<String, dynamic>?>> getToolAppById(
    Map<String, dynamic> params,
  ) async {
    final id = params['id'] as String?;
    if (id == null || id.isEmpty) {
      return Result.failure('缺少必需参数: id', code: ErrorCodes.invalidParams);
    }

    try {
      final result = await repository.getToolAppById(id);
      return result.map((toolApp) => toolApp?.toJson());
    } catch (e) {
      return Result.failure('获取工具应用失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 创建工具应用
  Future<Result<Map<String, dynamic>>> createToolApp(
    Map<String, dynamic> params,
  ) async {
    // 参数验证
    final idValidation = ParamValidator.requireString(params, 'id');
    if (!idValidation.isValid) {
      return Result.failure(
        idValidation.errorMessage!,
        code: ErrorCodes.invalidParams,
      );
    }

    final titleValidation = ParamValidator.requireString(params, 'title');
    if (!titleValidation.isValid) {
      return Result.failure(
        titleValidation.errorMessage!,
        code: ErrorCodes.invalidParams,
      );
    }

    final descriptionValidation = ParamValidator.requireString(params, 'description');
    if (!descriptionValidation.isValid) {
      return Result.failure(
        descriptionValidation.errorMessage!,
        code: ErrorCodes.invalidParams,
      );
    }

    try {
      final toolApp = OpenAIToolAppDto(
        id: params['id'] as String,
        title: params['title'] as String,
        description: params['description'] as String,
      );

      final result = await repository.createToolApp(toolApp);
      return result.map((t) => t.toJson());
    } catch (e) {
      return Result.failure('创建工具应用失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 更新工具应用
  Future<Result<Map<String, dynamic>>> updateToolApp(
    Map<String, dynamic> params,
  ) async {
    final id = params['id'] as String?;
    if (id == null || id.isEmpty) {
      return Result.failure('缺少必需参数: id', code: ErrorCodes.invalidParams);
    }

    try {
      // 获取现有数据
      final existingResult = await repository.getToolAppById(id);
      if (existingResult.isFailure) {
        return Result.failure('工具应用不存在', code: ErrorCodes.notFound);
      }

      final existing = existingResult.dataOrNull;
      if (existing == null) {
        return Result.failure('工具应用不存在', code: ErrorCodes.notFound);
      }

      // 合并更新
      final updated = existing.copyWith(
        title: params['title'] as String?,
        description: params['description'] as String?,
      );

      final result = await repository.updateToolApp(id, updated);
      return result.map((t) => t.toJson());
    } catch (e) {
      return Result.failure('更新工具应用失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 删除工具应用
  Future<Result<bool>> deleteToolApp(Map<String, dynamic> params) async {
    final id = params['id'] as String?;
    if (id == null || id.isEmpty) {
      return Result.failure('缺少必需参数: id', code: ErrorCodes.invalidParams);
    }

    try {
      return repository.deleteToolApp(id);
    } catch (e) {
      return Result.failure('删除工具应用失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 搜索工具应用
  Future<Result<dynamic>> searchToolApps(Map<String, dynamic> params) async {
    try {
      final query = OpenAIToolAppQuery(
        titleKeyword: params['titleKeyword'] as String?,
        pagination: _extractPagination(params),
      );

      final result = await repository.searchToolApps(query);
      return result.map((toolApps) {
        final jsonList = toolApps.map((t) => t.toJson()).toList();

        if (query.pagination != null && query.pagination!.hasPagination) {
          return PaginationUtils.toMap(
            jsonList,
            offset: query.pagination!.offset,
            count: query.pagination!.count,
          );
        }
        return jsonList;
      });
    } catch (e) {
      return Result.failure('搜索工具应用失败: $e', code: ErrorCodes.serverError);
    }
  }

  // ============ 模型操作 ============

  /// 获取模型列表
  Future<Result<dynamic>> getModels(Map<String, dynamic> params) async {
    try {
      final pagination = _extractPagination(params);
      final result = await repository.getModels(pagination: pagination);

      return result.map((models) {
        final jsonList = models.map((m) => m.toJson()).toList();

        if (pagination != null && pagination.hasPagination) {
          return PaginationUtils.toMap(
            jsonList,
            offset: pagination.offset,
            count: pagination.count,
          );
        }
        return jsonList;
      });
    } catch (e) {
      return Result.failure('获取模型列表失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 根据 ID 获取模型
  Future<Result<Map<String, dynamic>?>> getModelById(
    Map<String, dynamic> params,
  ) async {
    final id = params['id'] as String?;
    if (id == null || id.isEmpty) {
      return Result.failure('缺少必需参数: id', code: ErrorCodes.invalidParams);
    }

    try {
      final result = await repository.getModelById(id);
      return result.map((model) => model?.toJson());
    } catch (e) {
      return Result.failure('获取模型失败: $e', code: ErrorCodes.serverError);
    }
  }

  // ============ 辅助方法 ============

  PaginationParams? _extractPagination(Map<String, dynamic> params) {
    final offset = params['offset'] as int?;
    final count = params['count'] as int?;

    if (offset == null && count == null) return null;

    return PaginationParams(
      offset: offset ?? 0,
      count: count ?? 100,
    );
  }
}
