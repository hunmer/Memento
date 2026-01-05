part of 'openai_plugin.dart';

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

/// 获取所有 AI 助手列表
/// 支持分页参数: offset, count
Future<String> _jsGetAgents(Map<String, dynamic> params) async {
  try {
    final result = await _useCase.getAgents(params);

    if (result.isFailure) {
      return jsonEncode({'error': result.errorOrNull?.message});
    }

    final data = result.dataOrNull;
    if (data == null) {
      return jsonEncode([]);
    }

    return jsonEncode(data);
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
    final result = await _useCase.getAgentById({'id': agentId});

    if (result.isFailure) {
      return jsonEncode({'error': result.errorOrNull?.message});
    }

    final agent = result.dataOrNull;
    if (agent == null) {
      return jsonEncode({'error': 'Agent not found: $agentId'});
    }

    return jsonEncode(agent);
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
    // 验证 agent 是否存在（使用 UseCase）
    final agentResult = await _useCase.getAgentById({'id': agentId});
    if (agentResult.isFailure) {
      return jsonEncode({'error': 'Agent not found: $agentId'});
    }

    // 获取助手信息（使用现有控制器，因为 RequestService 需要 AIAgent 类型）
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

    // 使用流式 API（带重试机制，最多10次重试）
    await RequestService.streamResponseWithRetry(
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
      maxRetries: 10,
      retryDelay: 1000,
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
/// 支持分页参数: offset, count
Future<String> _jsGetProviders(Map<String, dynamic> params) async {
  try {
    final result = await _useCase.getServiceProviders(params);

    if (result.isFailure) {
      return jsonEncode({'error': result.errorOrNull?.message});
    }

    final data = result.dataOrNull;
    if (data == null) {
      return jsonEncode([]);
    }

    return jsonEncode(data);
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
    // 使用 UseCase 获取服务商列表
    final result = await _useCase.getServiceProviders({});

    if (result.isFailure) {
      return jsonEncode({
        'success': false,
        'error': result.errorOrNull?.message,
      });
    }

    final providers = result.dataOrNull ?? [];

    // 查找匹配的服务商（支持 ID 或 label 匹配）
    final providerJson = providers.firstWhere(
      (p) => p['id'] == providerId || p['label'] == providerId,
      orElse: () => throw Exception('Provider not found: $providerId'),
    );

    // 获取该服务商的任意一个 agent 进行测试
    final agentController = AgentController();
    await agentController.loadAgents();

    final testAgent = agentController.agents.firstWhere(
      (a) => a.serviceProviderId == providerJson['id'],
      orElse:
          () =>
              throw Exception(
                'No agent configured for provider: ${providerJson['label']}',
              ),
    );

    // 发送简单的测试消息
    final response = await RequestService.chat('Hello', testAgent).timeout(
      const Duration(seconds: 10),
      onTimeout: () => throw Exception('Connection timeout'),
    );

    final success = !response.startsWith('Error:');
    return jsonEncode({
      'success': success,
      'provider': providerJson['label'],
      'response': response.substring(
        0,
        response.length > 100 ? 100 : response.length,
      ),
    });
  } catch (e) {
    return jsonEncode({'success': false, 'error': e.toString()});
  }
}
