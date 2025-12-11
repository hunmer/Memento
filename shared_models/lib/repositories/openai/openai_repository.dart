/// OpenAI 插件 - Repository 接口定义

import 'package:shared_models/utils/result.dart';
import 'package:shared_models/utils/pagination.dart';

// ============ DTOs ============

/// AI 助手 DTO
class OpenAIAgentDto {
  final String id;
  final String name;
  final String description;
  final String systemPrompt;
  final List<String> tags;
  final String serviceProviderId;
  final String baseUrl;
  final Map<String, String> headers;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String model;
  final double temperature;
  final int maxLength;
  final double topP;
  final double frequencyPenalty;
  final double presencePenalty;
  final List<String>? stop;
  final String? avatarUrl;
  final bool enableFunctionCalling;
  final String? promptPresetId;
  final bool enableOpeningQuestions;
  final List<String> openingQuestions;

  const OpenAIAgentDto({
    required this.id,
    required this.name,
    required this.description,
    required this.systemPrompt,
    required this.tags,
    required this.serviceProviderId,
    required this.baseUrl,
    required this.headers,
    required this.createdAt,
    required this.updatedAt,
    required this.model,
    this.temperature = 0.7,
    this.maxLength = 2000,
    this.topP = 1.0,
    this.frequencyPenalty = 0.0,
    this.presencePenalty = 0.0,
    this.stop,
    this.avatarUrl,
    this.enableFunctionCalling = false,
    this.promptPresetId,
    this.enableOpeningQuestions = false,
    this.openingQuestions = const [],
  });

  /// 从 JSON 构造
  factory OpenAIAgentDto.fromJson(Map<String, dynamic> json) {
    return OpenAIAgentDto(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      systemPrompt: json['systemPrompt'] as String,
      tags: (json['tags'] as List).cast<String>(),
      serviceProviderId: json['serviceProviderId'] as String,
      baseUrl: json['baseUrl'] as String,
      headers: Map<String, String>.from(json['headers'] as Map),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      model: json['model'] as String? ?? 'gpt-3.5-turbo',
      temperature: (json['temperature'] as num?)?.toDouble() ?? 0.7,
      maxLength: json['maxLength'] as int? ?? 2000,
      topP: (json['topP'] as num?)?.toDouble() ?? 1.0,
      frequencyPenalty: (json['frequencyPenalty'] as num?)?.toDouble() ?? 0.0,
      presencePenalty: (json['presencePenalty'] as num?)?.toDouble() ?? 0.0,
      stop: (json['stop'] as List<dynamic>?)?.cast<String>(),
      avatarUrl: json['avatarUrl'] as String?,
      enableFunctionCalling: json['enableFunctionCalling'] as bool? ?? false,
      promptPresetId: json['promptPresetId'] as String?,
      enableOpeningQuestions: json['enableOpeningQuestions'] as bool? ?? false,
      openingQuestions: (json['openingQuestions'] as List<dynamic>?)?.cast<String>() ?? const [],
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'systemPrompt': systemPrompt,
      'tags': tags,
      'serviceProviderId': serviceProviderId,
      'baseUrl': baseUrl,
      'headers': headers,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'model': model,
      'temperature': temperature,
      'maxLength': maxLength,
      'topP': topP,
      'frequencyPenalty': frequencyPenalty,
      'presencePenalty': presencePenalty,
      'stop': stop,
      'avatarUrl': avatarUrl,
      'enableFunctionCalling': enableFunctionCalling,
      'promptPresetId': promptPresetId,
      'enableOpeningQuestions': enableOpeningQuestions,
      'openingQuestions': openingQuestions,
    };
  }

  /// 复制并修改
  OpenAIAgentDto copyWith({
    String? id,
    String? name,
    String? description,
    String? systemPrompt,
    List<String>? tags,
    String? serviceProviderId,
    String? baseUrl,
    Map<String, String>? headers,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? model,
    double? temperature,
    int? maxLength,
    double? topP,
    double? frequencyPenalty,
    double? presencePenalty,
    List<String>? stop,
    String? avatarUrl,
    bool? enableFunctionCalling,
    String? promptPresetId,
    bool? enableOpeningQuestions,
    List<String>? openingQuestions,
  }) {
    return OpenAIAgentDto(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      systemPrompt: systemPrompt ?? this.systemPrompt,
      tags: tags ?? this.tags,
      serviceProviderId: serviceProviderId ?? this.serviceProviderId,
      baseUrl: baseUrl ?? this.baseUrl,
      headers: headers ?? this.headers,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      model: model ?? this.model,
      temperature: temperature ?? this.temperature,
      maxLength: maxLength ?? this.maxLength,
      topP: topP ?? this.topP,
      frequencyPenalty: frequencyPenalty ?? this.frequencyPenalty,
      presencePenalty: presencePenalty ?? this.presencePenalty,
      stop: stop ?? this.stop,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      enableFunctionCalling: enableFunctionCalling ?? this.enableFunctionCalling,
      promptPresetId: promptPresetId ?? this.promptPresetId,
      enableOpeningQuestions: enableOpeningQuestions ?? this.enableOpeningQuestions,
      openingQuestions: openingQuestions ?? this.openingQuestions,
    );
  }
}

/// 服务商 DTO
class OpenAIServiceProviderDto {
  final String id;
  final String label;
  final String baseUrl;
  final Map<String, String> headers;
  final String? defaultModel;

  const OpenAIServiceProviderDto({
    required this.id,
    required this.label,
    required this.baseUrl,
    this.headers = const {},
    this.defaultModel,
  });

  factory OpenAIServiceProviderDto.fromJson(Map<String, dynamic> json) {
    return OpenAIServiceProviderDto(
      id: json['id'] as String,
      label: json['label'] as String,
      baseUrl: json['baseUrl'] as String,
      headers: Map<String, String>.from(json['headers'] as Map),
      defaultModel: json['defaultModel'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'baseUrl': baseUrl,
      'headers': headers,
      if (defaultModel != null) 'defaultModel': defaultModel,
    };
  }

  OpenAIServiceProviderDto copyWith({
    String? id,
    String? label,
    String? baseUrl,
    Map<String, String>? headers,
    String? defaultModel,
  }) {
    return OpenAIServiceProviderDto(
      id: id ?? this.id,
      label: label ?? this.label,
      baseUrl: baseUrl ?? this.baseUrl,
      headers: headers ?? Map<String, String>.from(this.headers),
      defaultModel: defaultModel ?? this.defaultModel,
    );
  }
}

/// 工具应用 DTO
class OpenAIToolAppDto {
  final String id;
  final String title;
  final String description;

  const OpenAIToolAppDto({
    required this.id,
    required this.title,
    required this.description,
  });

  factory OpenAIToolAppDto.fromJson(Map<String, dynamic> json) {
    return OpenAIToolAppDto(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
    };
  }

  OpenAIToolAppDto copyWith({
    String? id,
    String? title,
    String? description,
  }) {
    return OpenAIToolAppDto(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
    );
  }
}

/// LLM 模型 DTO
class OpenAIModelDto {
  final String id;
  final String name;
  final String? description;
  final String? url;
  final String group;

  const OpenAIModelDto({
    required this.id,
    required this.name,
    this.description,
    this.url,
    required this.group,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'url': url,
        'group': group,
      };

  factory OpenAIModelDto.fromJson(Map<String, dynamic> json) => OpenAIModelDto(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String?,
        url: json['url'] as String?,
        group: json['group'] as String,
      );
}

// ============ Query Objects ============

/// AI 助手查询参数对象
class OpenAIAgentQuery {
  final String? nameKeyword;
  final String? serviceProviderId;
  final List<String>? tags;
  final PaginationParams? pagination;

  const OpenAIAgentQuery({
    this.nameKeyword,
    this.serviceProviderId,
    this.tags,
    this.pagination,
  });
}

/// 服务商查询参数对象
class OpenAIServiceProviderQuery {
  final String? nameKeyword;
  final PaginationParams? pagination;

  const OpenAIServiceProviderQuery({
    this.nameKeyword,
    this.pagination,
  });
}

/// 工具应用查询参数对象
class OpenAIToolAppQuery {
  final String? titleKeyword;
  final PaginationParams? pagination;

  const OpenAIToolAppQuery({
    this.titleKeyword,
    this.pagination,
  });
}

// ============ Repository Interface ============

/// OpenAI 插件 Repository 接口
abstract class IOpenAIRepository {
  // ============ AI 助手操作 ============

  /// 获取所有 AI 助手
  Future<Result<List<OpenAIAgentDto>>> getAgents({PaginationParams? pagination});

  /// 根据 ID 获取 AI 助手
  Future<Result<OpenAIAgentDto?>> getAgentById(String id);

  /// 创建 AI 助手
  Future<Result<OpenAIAgentDto>> createAgent(OpenAIAgentDto agent);

  /// 更新 AI 助手
  Future<Result<OpenAIAgentDto>> updateAgent(String id, OpenAIAgentDto agent);

  /// 删除 AI 助手
  Future<Result<bool>> deleteAgent(String id);

  /// 搜索 AI 助手
  Future<Result<List<OpenAIAgentDto>>> searchAgents(OpenAIAgentQuery query);

  // ============ 服务商操作 ============

  /// 获取所有服务商
  Future<Result<List<OpenAIServiceProviderDto>>> getServiceProviders(
      {PaginationParams? pagination});

  /// 根据 ID 获取服务商
  Future<Result<OpenAIServiceProviderDto?>> getServiceProviderById(String id);

  /// 创建服务商
  Future<Result<OpenAIServiceProviderDto>> createServiceProvider(
      OpenAIServiceProviderDto provider);

  /// 更新服务商
  Future<Result<OpenAIServiceProviderDto>> updateServiceProvider(
      String id, OpenAIServiceProviderDto provider);

  /// 删除服务商
  Future<Result<bool>> deleteServiceProvider(String id);

  /// 搜索服务商
  Future<Result<List<OpenAIServiceProviderDto>>> searchServiceProviders(
      OpenAIServiceProviderQuery query);

  // ============ 工具应用操作 ============

  /// 获取所有工具应用
  Future<Result<List<OpenAIToolAppDto>>> getToolApps(
      {PaginationParams? pagination});

  /// 根据 ID 获取工具应用
  Future<Result<OpenAIToolAppDto?>> getToolAppById(String id);

  /// 创建工具应用
  Future<Result<OpenAIToolAppDto>> createToolApp(OpenAIToolAppDto toolApp);

  /// 更新工具应用
  Future<Result<OpenAIToolAppDto>> updateToolApp(
      String id, OpenAIToolAppDto toolApp);

  /// 删除工具应用
  Future<Result<bool>> deleteToolApp(String id);

  /// 搜索工具应用
  Future<Result<List<OpenAIToolAppDto>>> searchToolApps(
      OpenAIToolAppQuery query);

  // ============ 模型操作 ============

  /// 获取所有模型
  Future<Result<List<OpenAIModelDto>>> getModels(
      {PaginationParams? pagination});

  /// 根据 ID 获取模型
  Future<Result<OpenAIModelDto?>> getModelById(String id);
}
