import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:Memento/plugins/openai/models/ai_agent.dart';

/// Agent 商场服务
/// 负责从远程服务器获取 Agent 列表
class AgentMarketplaceService {
  static const String _defaultMarketplaceUrl =
      'https://gitee.com/neysummer2000/memento/raw/master/mini_apps_store/agents.json';

  /// 获取商场 Agent 列表
  ///
  /// [url] 商场 JSON 文件的 URL（可选，使用默认 URL）
  /// 返回 Agent 列表
  Future<List<AIAgent>> fetchMarketplaceAgents({String? url}) async {
    try {
      final targetUrl = url ?? _defaultMarketplaceUrl;
      final response = await http.get(Uri.parse(targetUrl));

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        final List<dynamic> agentsJson = data['agents'] as List<dynamic>;

        return agentsJson
            .map((json) => AIAgent.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Failed to load agents: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching marketplace agents: $e');
    }
  }

  /// 检查 Agent 是否已安装
  ///
  /// [marketplaceAgent] 商场中的 Agent
  /// [localAgents] 本地已安装的 Agent 列表
  /// 返回是否已安装
  bool isAgentInstalled(AIAgent marketplaceAgent, List<AIAgent> localAgents) {
    return localAgents.any((agent) => agent.id == marketplaceAgent.id);
  }

  /// 检查 Agent 是否需要更新
  ///
  /// [marketplaceAgent] 商场中的 Agent
  /// [localAgents] 本地已安装的 Agent 列表
  /// 返回是否需要更新（提示词不一致）
  bool isAgentUpdateAvailable(
    AIAgent marketplaceAgent,
    List<AIAgent> localAgents,
  ) {
    final localAgent = localAgents.firstWhere(
      (agent) => agent.id == marketplaceAgent.id,
      orElse: () => marketplaceAgent,
    );

    // 如果找不到本地 Agent，说明未安装，不需要更新
    if (localAgent == marketplaceAgent) {
      return false;
    }

    // 比较 systemPrompt 是否一致
    return localAgent.systemPrompt != marketplaceAgent.systemPrompt;
  }

  /// 获取 Agent 的安装状态信息
  ///
  /// 返回包含状态的 Map：
  /// - 'installed': bool - 是否已安装
  /// - 'updateAvailable': bool - 是否有更新
  Map<String, bool> getAgentStatus(
    AIAgent marketplaceAgent,
    List<AIAgent> localAgents,
  ) {
    final installed = isAgentInstalled(marketplaceAgent, localAgents);
    final updateAvailable =
        installed
            ? isAgentUpdateAvailable(marketplaceAgent, localAgents)
            : false;

    return {'installed': installed, 'updateAvailable': updateAvailable};
  }
}
