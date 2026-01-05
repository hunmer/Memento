import 'package:get/get.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:Memento/core/services/toast_service.dart';
import 'package:Memento/core/services/plugin_data_selector/index.dart';
import 'package:Memento/core/services/clipboard_service.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
import 'package:uuid/uuid.dart';
import 'package:Memento/core/widgets/custom_bottom_bar.dart';
import 'package:flutter/gestures.dart';
import 'package:Memento/plugins/base_plugin.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/core/config_manager.dart';
import 'package:Memento/core/js_bridge/js_bridge_plugin.dart';
import 'package:shared_models/usecases/openai/openai_usecase.dart';
import 'package:Memento/widgets/preset_edit_form.dart';
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
import 'models/ai_agent.dart';
import 'services/prompt_preset_service.dart';
import 'sample_data.dart';

part 'openai_js_api.dart';
part 'openai_data_selectors.dart';

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
  Map<String, Function> defineJSAPI() {
    return {
      // AI 助手管理
      'getAgents': _jsGetAgents,
      'getAgent': _jsGetAgent,
      'sendMessage': _jsSendMessage,

      // 服务商管理
      'getProviders': _jsGetProviders,
      'testProvider': _jsTestProvider,
    };
  }

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

  void _showPresetEditPage() async {
    await showPresetEditPage(
      context: context,
      onSave: (preset, prompts) async {
        final service = PromptPresetService();
        await service.addPreset(preset);

        if (mounted) {
          Toast.success('openai_presetSaved'.tr);
          setState(() {});
        }
      },
    );
  }

  /// 构建 FAB
  Widget _buildFab() {
    return FloatingActionButton(
      onPressed: () {
        if (_currentPage == 0) {
          NavigationHelper.openContainerWithHero(context, (
            BuildContext context,
          ) {
            return AgentEditScreen();
          });
        } else {
          _showPresetEditPage();
        }
      },
      backgroundColor: Colors.deepOrange,
      elevation: 4,
      shape: const CircleBorder(),
      child: Icon(
        _currentPage == 0 ? Icons.smart_toy : Icons.text_snippet,
        color: Colors.white,
        size: 32,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CustomBottomBar(
      colors: _colors,
      currentIndex: _currentPage,
      tabController: _tabController,
      bottomBarKey: _bottomBarKey,
      body: (context, controller) => TabBarView(
        controller: _tabController,
        dragStartBehavior: DragStartBehavior.down,
        physics: const NeverScrollableScrollPhysics(),
        children: const [AgentListScreen(), PromptPresetScreen()],
      ),
      fab: _buildFab(),
      children: [
        Tab(
          icon: const Icon(Icons.smart_toy_outlined),
          text: 'openai_agentsTab'.tr,
        ),
        Tab(
          icon: const Icon(Icons.text_snippet_outlined),
          text: 'openai_promptPreset'.tr,
        ),
      ],
    );
  }
}
