import 'package:get/get.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:Memento/core/services/toast_service.dart';
import 'package:Memento/core/services/plugin_data_selector/index.dart';
import 'package:Memento/core/services/clipboard_service.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:flutter/gestures.dart';
import 'package:universal_platform/universal_platform.dart';
import 'package:Memento/plugins/base_plugin.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/core/config_manager.dart';
import 'package:Memento/core/js_bridge/js_bridge_plugin.dart';
import 'package:shared_models/usecases/openai/openai_usecase.dart';
import 'repositories/client_openai_repository.dart';
import 'screens/agent_list_screen.dart';
import 'screens/plugin_settings_screen.dart';
import 'screens/prompt_preset_screen.dart';
import 'screens/agent_edit_screen.dart';
import 'handlers/chat_event_handler.dart';
import 'controllers/agent_controller.dart';
import 'controllers/service_provider_controller.dart';
import 'controllers/model_controller.dart';
import 'services/request_service.dart';
import 'models/prompt_preset.dart';
import 'models/ai_agent.dart';
import 'services/prompt_preset_service.dart';
import 'sample_data.dart';

class OpenAIPlugin extends BasePlugin with JSBridgePlugin {
  static OpenAIPlugin? _instance;
  static OpenAIPlugin get instance {
    if (_instance == null) {
      _instance = PluginManager.instance.getPlugin('openai') as OpenAIPlugin?;
      if (_instance == null) {
        throw StateError('OpenAIPlugin has not been initialized');
      }
    }
    return _instance!;
  }

  final ChatEventHandler _chatEventHandler = ChatEventHandler();

  // UseCase 实例
  late final OpenAIUseCase _useCase;

  /// 获取 UseCase 实例
  OpenAIUseCase get useCase => _useCase;

  @override
  String get id => 'openai';

  @override
  Color get color => Colors.deepOrange;

  @override
  Future<void> initialize() async {
    // Initialize default service providers
    await initializeDefaultData();

    // 初始化聊天事件处理器
    _chatEventHandler.initialize();

    // 初始化 UseCase
    _initializeUseCase();

    // 注册数据选择器
    _registerDataSelectors();

    // 注册剪贴板处理器
    _registerClipboardHandler();

    // 注册 JS API（最后一步）
    await registerJSAPI();
  }

  /// 初始化 UseCase
  void _initializeUseCase() {
    // 创建控制器实例
    final agentController = AgentController();
    final serviceProviderController = ServiceProviderController();
    final modelController = ModelController();

    // 创建 Repository 实例
    final repository = ClientOpenAIRepository(
      agentController: agentController,
      serviceProviderController: serviceProviderController,
      modelController: modelController,
    );

    // 创建 UseCase 实例
    _useCase = OpenAIUseCase(repository);
  }

  /// 注册数据选择器
  void _registerDataSelectors() {
    final agentController = AgentController();
    final presetService = PromptPresetService();

    // 1. AI 助手选择器
    pluginDataSelectorService.registerSelector(
      SelectorDefinition(
        id: 'openai.agent',
        pluginId: id,
        name: '选择 AI 助手',
        description: '选择一个 AI 助手',
        icon: Icons.smart_toy,
        color: color,
        steps: [
          SelectorStep(
            id: 'agent',
            title: 'AI 助手列表',
            viewType: SelectorViewType.grid,
            gridCrossAxisCount: 2,
            gridChildAspectRatio: 0.85,
            isFinalStep: true,
            emptyText: '暂无 AI 助手',
            dataLoader: (_) async {
              final agents = await agentController.loadAgents();
              return agents
                  .map(
                    (agent) => SelectableItem(
                      id: agent.id,
                      title: agent.name,
                      subtitle:
                          agent.description.isEmpty
                              ? agent.model
                              : agent.description,
                      icon: agent.icon,
                      color: agent.iconColor,
                      avatarPath: agent.avatarUrl,
                      rawData: agent,
                      metadata: {'model': agent.model},
                    ),
                  )
                  .toList();
            },
            searchFilter: (items, query) {
              final lowerQuery = query.toLowerCase();
              return items
                  .where(
                    (item) =>
                        item.title.toLowerCase().contains(lowerQuery) ||
                        (item.subtitle?.toLowerCase().contains(lowerQuery) ??
                            false),
                  )
                  .toList();
            },
          ),
        ],
      ),
    );

    // 2. Prompt 预设选择器
    pluginDataSelectorService.registerSelector(
      SelectorDefinition(
        id: 'openai.prompt',
        pluginId: id,
        name: '选择 Prompt 预设',
        description: '选择一个提示词预设',
        icon: Icons.description,
        color: color,
        steps: [
          SelectorStep(
            id: 'prompt',
            title: 'Prompt 列表',
            viewType: SelectorViewType.list,
            isFinalStep: true,
            emptyText: '暂无 Prompt 预设',
            dataLoader: (_) async {
              await presetService.loadPresets();
              return presetService.presets
                  .map(
                    (preset) => SelectableItem(
                      id: preset.id,
                      title: preset.name,
                      subtitle:
                          preset.description.isEmpty
                              ? (preset.content.length > 50
                                  ? '${preset.content.substring(0, 50)}...'
                                  : preset.content)
                              : preset.description,
                      icon: Icons.text_snippet,
                      rawData: preset,
                      metadata: {'category': preset.category},
                    ),
                  )
                  .toList();
            },
            searchFilter: (items, query) {
              final lowerQuery = query.toLowerCase();
              return items
                  .where(
                    (item) =>
                        item.title.toLowerCase().contains(lowerQuery) ||
                        (item.subtitle?.toLowerCase().contains(lowerQuery) ??
                            false),
                  )
                  .toList();
            },
          ),
        ],
      ),
    );
  }

  /// 注册剪贴板处理器
  void _registerClipboardHandler() {
    ClipboardService.instance.registerHandler(
      'openai_agent_import',
      _handleAgentImport,
    );
  }

  /// 处理 Agent 导入
  Future<void> _handleAgentImport(Map<String, dynamic> args) async {
    try {
      // 验证必需字段
      if (args['id'] == null || args['name'] == null) {
        debugPrint('[OpenAIPlugin] 导入失败：缺少必需字段');
        return;
      }

      final agent = AIAgent.fromJson(args);

      // 获取当前 context
      final context = Get.context;
      if (context == null) {
        debugPrint('[OpenAIPlugin] 无法获取 context');
        return;
      }

      // 显示导入确认对话框
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('openai_importAgent'.tr),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('openai_importAgentConfirm'.tr),
              const SizedBox(height: 16),
              Text('${'openai_nameLabel'.tr}: ${agent.name}',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              if (agent.description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('${'openai_descriptionLabel'.tr}: ${agent.description}'),
              ],
              if (agent.tags.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4,
                  children: agent.tags
                      .map((tag) => Chip(
                            label: Text(tag, style: const TextStyle(fontSize: 12)),
                            padding: EdgeInsets.zero,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ))
                      .toList(),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('openai_cancel'.tr),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('openai_import'.tr),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      // 生成新的 ID 避免冲突
      final newAgent = agent.copyWith(
        id: const Uuid().v4(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // 保存 Agent
      final agentController = AgentController();
      await agentController.saveAgent(newAgent);

      Toast.success('openai_agentImported'.tr);
    } catch (e) {
      debugPrint('[OpenAIPlugin] 导入 Agent 失败: $e');
      Toast.error('openai_importFailed'.tr);
    }
  }

  @override
  Future<void> initializeDefaultData() async {
    // 确保 agents.json 文件存在并初始化默认智能体
    final agentData = await storage.read('$storageDir/agents.json');
    if (agentData.isEmpty) {
      // 如果文件为空，使用示例数据中的默认智能体
      final defaultAgents = OpenAISampleData.defaultAgents;

      await storage.write('$storageDir/agents.json', {'agents': defaultAgents});
      debugPrint('已初始化 ${defaultAgents.length} 个默认智能体');
    }

    // 初始化提示词预设数据
    await _initializePromptPresets();
  }

  /// 初始化提示词预设数据
  Future<void> _initializePromptPresets() async {
    try {
      final presetData = await storage.read('openai/prompt_presets.json');
      if (presetData.isEmpty || presetData['presets'] == null) {
        // 如果没有预设数据，使用示例数据中的默认预设
        final defaultPresets = OpenAISampleData.defaultPresets;

        await storage.write('openai/prompt_presets.json', {
          'presets': defaultPresets.map((p) => p.toJson()).toList(),
        });
        debugPrint('已初始化 ${defaultPresets.length} 个默认提示词预设');
      }
    } catch (e) {
      debugPrint('初始化提示词预设失败: $e');
    }
  }

  @override
  Widget buildMainView(BuildContext context) {
    return Localizations.override(
      context: context,
      child: const OpenAIMainView(),
    );
  }

  @override
  Widget buildSettingsView(BuildContext context) {
    return const PluginSettingsScreen();
  }

  @override
  Future<void> registerToApp(
    PluginManager pluginManager,
    ConfigManager configManager,
  ) async {
    // Register plugin settings
    // 插件已在 initialize() 中完成初始化
    // 这里可以添加额外的应用级注册逻辑
    await configManager.savePluginConfig(id, {'providers': []});
  }

  Future<Map<String, dynamic>> _getAgentsData() async {
    try {
      final agentData = await storage.read('$storageDir/agents.json');
      if (agentData.isNotEmpty) {
        return Map<String, dynamic>.from(agentData);
      }
    } catch (e) {
      debugPrint('Error reading agents data: $e');
    }
    return {'agents': []};
  }

  @override
  Future<void> uninstall() async {
    // Clean up plugin data
    await storage.delete(storageDir);

    // 清理事件处理器
    _chatEventHandler.dispose();
  }

  /// 获取 AgentController 实例
  AgentController get controller => AgentController();

  // ==================== 小组件统计方法 ====================

  /// 获取总助手数
  Future<int> getTotalAgentsCount() async {
    try {
      final agents = await controller.loadAgents();
      return agents.length;
    } catch (e) {
      debugPrint('获取总助手数失败: $e');
      return 0;
    }
  }

  /// 获取今日请求次数
  /// 注意: 当前实现返回0,因为项目中未实现请求历史记录功能
  Future<int> getTodayRequestCount() async {
    // TODO: 实现请求历史记录功能后,从存储中读取今日请求数
    // 可能的实现路径: openai/request_history.json
    return 0;
  }

  /// 获取可用模型数
  /// 统计所有模型的总数
  Future<int> getAvailableModelsCount() async {
    try {
      final modelController = ModelController();
      final modelGroups = await modelController.getModels();

      int totalModels = 0;
      for (final group in modelGroups) {
        totalModels += group.models.length;
      }

      return totalModels;
    } catch (e) {
      debugPrint('获取可用模型数失败: $e');
      return 0;
    }
  }

  @override
  IconData get icon => Icons.smart_toy;

  @override
  Widget buildCardView(BuildContext context) {
    return Localizations.override(
      context: context,
      child: _buildCardViewContent(context),
    );
  }

  @override
  String? getPluginName(context) {
    return 'openai_name'.tr;
  }

  // ==================== JS API 定义 ====================

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

  // ==================== JS API 实现 ====================

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

      // 使用流式 API，设置 30 秒超时
      await RequestService.streamResponse(
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
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          hasError = true;
          errorMessage = 'Request timeout (30s)';
        },
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

  Widget _buildCardViewContent(BuildContext context) {
    final theme = Theme.of(context);

    return FutureBuilder<Map<String, dynamic>>(
      future: _getAgentsData(),
      builder: (context, snapshot) {
        final agentsCount = (snapshot.data?['agents'] as List?)?.length ?? 0;
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 顶部图标和标题
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color.withAlpha(30),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, size: 24, color: color),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'openai_name'.tr,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 统计信息卡片
              Column(
                children: [
                  // 第一行 - 智能体总数和活跃智能体
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      // 智能体总数
                      Column(
                        children: [
                          Text(
                            'openai_totalAgents'.tr,
                            style: theme.textTheme.bodyMedium,
                          ),
                          Text(
                            '$agentsCount',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color:
                                  agentsCount > 0
                                      ? theme.colorScheme.primary
                                      : null,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class OpenAIMainView extends StatefulWidget {
  const OpenAIMainView({super.key});

  @override
  State<OpenAIMainView> createState() => _OpenAIMainViewState();
}

class _OpenAIMainViewState extends State<OpenAIMainView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late int _currentPage;
  double _bottomBarHeight = 60; // 默认底部栏高度
  final GlobalKey _bottomBarKey = GlobalKey();
  final List<Color> _colors = [
    Colors.deepOrange,
    Colors.blue,
    Colors.purple,
    Colors.green,
  ];

  @override
  void initState() {
    super.initState();
    _currentPage = 0;
    _tabController = TabController(length: 2, vsync: this);
    _tabController.animation?.addListener(() {
      final value = _tabController.animation!.value.round();
      if (value != _currentPage && mounted) {
        setState(() {
          _currentPage = value;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// 调度底部栏高度测量
  void _scheduleBottomBarHeightMeasurement() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _bottomBarKey.currentContext != null) {
        final RenderBox renderBox =
            _bottomBarKey.currentContext!.findRenderObject() as RenderBox;
        final newHeight = renderBox.size.height;
        if (_bottomBarHeight != newHeight) {
          setState(() {
            _bottomBarHeight = newHeight;
          });
        }
      }
    });
  }

  void _showPresetEditDialog() async {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final contentController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('openai_addPreset'.tr),
            content: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'openai_presetTitle'.tr,
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descriptionController,
                    decoration: InputDecoration(
                      labelText: 'openai_presetDescription'.tr,
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: contentController,
                    decoration: InputDecoration(
                      labelText: 'openai_contentLabel'.tr,
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 5,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('openai_cancel'.tr),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text('openai_addPreset'.tr),
              ),
            ],
          ),
    );

    if (result == true &&
        nameController.text.isNotEmpty &&
        contentController.text.isNotEmpty) {
      final service = PromptPresetService();
      final preset = PromptPreset(
        id: const Uuid().v4(),
        name: nameController.text,
        description: descriptionController.text,
        content: contentController.text,
        tags: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await service.addPreset(preset);

      if (mounted) {
        Toast.success('openai_presetSaved'.tr);
      }
    }

    nameController.dispose();
    descriptionController.dispose();
    contentController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _scheduleBottomBarHeightMeasurement();
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final Color unselectedColor = colorScheme.onSurface.withOpacity(0.6);
    final Color bottomAreaColor = colorScheme.surface;

    return BottomBar(
      fit: StackFit.expand,
      icon:
          (width, height) => Center(
            child: IconButton(
              padding: EdgeInsets.zero,
              onPressed: () {
                // 滚动到顶部功能
                if (_tabController.indexIsChanging) return;

                // 切换到第一个tab
                if (_currentPage != 0) {
                  _tabController.animateTo(0);
                }
              },
              icon: Icon(
                Icons.keyboard_arrow_up,
                color: _colors[_currentPage],
                size: width,
              ),
            ),
          ),
      borderRadius: BorderRadius.circular(25),
      duration: const Duration(milliseconds: 300),
      curve: Curves.decelerate,
      showIcon: true,
      width: MediaQuery.of(context).size.width * 0.85,
      barColor: colorScheme.surface,
      start: 2,
      end: 0,
      offset: 12,
      barAlignment: Alignment.bottomCenter,
      iconHeight: 35,
      iconWidth: 35,
      reverse: false,
      barDecoration: BoxDecoration(
        color: _colors[_currentPage].withOpacity(0.1),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: _colors[_currentPage].withOpacity(0.3),
          width: 1,
        ),
      ),
      iconDecoration: BoxDecoration(
        color: _colors[_currentPage].withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _colors[_currentPage].withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      hideOnScroll: !UniversalPlatform.isDesktop,
      scrollOpposite: false,
      onBottomBarHidden: () {},
      onBottomBarShown: () {},
      body:
          (context, controller) => Stack(
            children: [
              Positioned.fill(
                child: Padding(
                  padding: EdgeInsets.only(bottom: _bottomBarHeight),
                  child: TabBarView(
                    controller: _tabController,
                    dragStartBehavior: DragStartBehavior.down,
                    physics: const NeverScrollableScrollPhysics(),
                    children: const [AgentListScreen(), PromptPresetScreen()],
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  height: _bottomBarHeight,
                  color: bottomAreaColor,
                ),
              ),
            ],
          ),
      child: Stack(
        key: _bottomBarKey,
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          TabBar(
            controller: _tabController,
            dividerColor: Colors.transparent,
            overlayColor: WidgetStateProperty.all(Colors.transparent),
            indicatorPadding: const EdgeInsets.fromLTRB(6, 0, 6, 0),
            indicator: UnderlineTabIndicator(
              borderSide: BorderSide(
                color:
                    _currentPage < 2 ? _colors[_currentPage] : unselectedColor,
                width: 4,
              ),
              insets: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            ),
            labelColor:
                _currentPage < 2 ? _colors[_currentPage] : unselectedColor,
            unselectedLabelColor: unselectedColor,
            tabs: [
              Tab(
                icon: const Icon(Icons.smart_toy_outlined),
                text: 'openai_agentsTab'.tr,
              ),
              Tab(
                icon: const Icon(Icons.text_snippet_outlined),
                text: 'openai_promptPreset'.tr,
              ),
            ],
          ),
          Positioned(
            top: -25,
            child:
                _currentPage == 0
                    ? FloatingActionButton(
                      onPressed: () {
                        NavigationHelper.openContainerWithHero(context, (
                          BuildContext context,
                        ) {
                          return AgentEditScreen();
                        });
                      },
                      backgroundColor: Colors.deepOrange,
                      elevation: 4,
                      shape: const CircleBorder(),
                      child: const Icon(
                        Icons.smart_toy,
                        color: Colors.white,
                        size: 32,
                      ),
                    )
                    : FloatingActionButton(
                      onPressed: () {
                        _showPresetEditDialog();
                      },
                      backgroundColor: Colors.deepOrange,
                      elevation: 4,
                      shape: const CircleBorder(),
                      child: const Icon(
                        Icons.text_snippet,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
          ),
        ],
      ),
    );
  }
}
