import 'package:flutter/foundation.dart';
import 'package:Memento/core/storage/storage_manager.dart';
import 'package:Memento/plugins/agent_chat/models/agent_chain_node.dart';

/// 路由 Agent 配置
class RouteAgentConfig {
  /// 单 Agent 模式的 Agent ID
  final String? agentId;

  /// Agent 链模式的配置
  final List<AgentChainNode>? agentChain;

  /// 是否为链模式
  bool get isChainMode => agentChain != null && agentChain!.isNotEmpty;

  const RouteAgentConfig({
    this.agentId,
    this.agentChain,
  });

  factory RouteAgentConfig.fromJson(Map<String, dynamic> json) {
    return RouteAgentConfig(
      agentId: json['agentId'] as String?,
      agentChain: (json['agentChain'] as List<dynamic>?)
          ?.map((e) => AgentChainNode.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (agentId != null) 'agentId': agentId,
      if (agentChain != null && agentChain!.isNotEmpty)
        'agentChain': agentChain!.map((node) => node.toJson()).toList(),
    };
  }
}

/// 路由 Agent 配置服务
///
/// 管理路由与 Agent 配置的关联，实现配置记忆功能
class RouteAgentConfigService {
  final StorageManager storage;
  static const String _storageKey = 'agent_chat/route_agent_configs';

  /// 路由配置缓存
  Map<String, RouteAgentConfig> _configs = {};

  RouteAgentConfigService({required this.storage});

  /// 初始化服务
  Future<void> initialize() async {
    await _loadConfigs();
  }

  /// 加载所有路由配置
  Future<void> _loadConfigs() async {
    try {
      final data = await storage.read(_storageKey);
      if (data is Map<String, dynamic>) {
        _configs = data.map(
          (key, value) => MapEntry(
            key,
            RouteAgentConfig.fromJson(value as Map<String, dynamic>),
          ),
        );
      }
    } catch (e) {
      debugPrint('加载路由配置失败: $e');
      _configs = {};
    }
  }

  /// 保存所有配置
  Future<void> _saveConfigs() async {
    try {
      final data = _configs.map(
        (key, value) => MapEntry(key, value.toJson()),
      );
      await storage.write(_storageKey, data);
    } catch (e) {
      debugPrint('保存路由配置失败: $e');
    }
  }

  /// 获取指定路由的 Agent 配置
  RouteAgentConfig? getConfig(String routeName) {
    return _configs[routeName];
  }

  /// 保存路由的 Agent 配置
  Future<void> saveConfig(
    String routeName,
    RouteAgentConfig config,
  ) async {
    _configs[routeName] = config;
    await _saveConfigs();
  }

  /// 删除路由的 Agent 配置
  Future<void> deleteConfig(String routeName) async {
    _configs.remove(routeName);
    await _saveConfigs();
  }

  /// 清空所有配置
  Future<void> clearAll() async {
    _configs.clear();
    await _saveConfigs();
  }
}
