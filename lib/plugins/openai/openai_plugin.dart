import 'dart:convert';
import 'package:Memento/plugins/openai/l10n/openai_localizations.dart';
import 'package:flutter/material.dart';
import 'package:Memento/core/services/toast_service.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:flutter/gestures.dart';
import 'package:universal_platform/universal_platform.dart';
import '../base_plugin.dart';
import '../../core/plugin_manager.dart';
import '../../core/config_manager.dart';
import '../../core/js_bridge/js_bridge_plugin.dart';
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
import 'services/prompt_preset_service.dart';

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

    // 注册 JS API（最后一步）
    await registerJSAPI();
  }

  @override
  Future<void> initializeDefaultData() async {
    // 确保 agents.json 文件存在并初始化默认智能体
    final agentData = await storage.read('openai/agents.json');
    if (agentData.isEmpty) {
      // 如果文件为空，创建包含默认智能体的文件
      final defaultAgents = [
        {
          'id': 'assistant-1',
          'name': '通用助手',
          'description': '一个友好的AI助手，可以帮助回答各种问题和完成各种任务。',
          'serviceProviderId': 'ollama',
          'baseUrl': 'http://localhost:11434',
          'headers': {'api-key': 'ollama'},
          'model': 'llama3',
          'systemPrompt': '你是一个乐于助人的AI助手，擅长回答问题并提供有用的建议。请用友好的语气与用户交流。',
          'tags': ['通用', '问答', '建议'],
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        },
      ];

      await storage.write('$storageDir/agents.json', {'agents': defaultAgents});
      debugPrint('已初始化默认智能体');
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
    await initialize();
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
    return OpenAILocalizations.of(context).name;
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

  // ==================== 分页控制器 ====================

  /// 分页控制器 - 对列表进行分页处理
  /// @param list 原始数据列表
  /// @param offset 起始位置（默认 0）
  /// @param count 返回数量（默认 100）
  /// @return 分页后的数据，包含 data、total、offset、count、hasMore
  Map<String, dynamic> _paginate<T>(
    List<T> list, {
    int offset = 0,
    int count = 100,
  }) {
    final total = list.length;
    final start = offset.clamp(0, total);
    final end = (start + count).clamp(start, total);
    final data = list.sublist(start, end);

    return {
      'data': data,
      'total': total,
      'offset': start,
      'count': data.length,
      'hasMore': end < total,
    };
  }

  // ==================== JS API 实现 ====================

  /// 获取所有 AI 助手列表
  /// 支持分页参数: offset, count
  Future<String> _jsGetAgents(Map<String, dynamic> params) async {
    try {
      final controller = AgentController();
      final agents = await controller.loadAgents();
      final agentsJson = agents.map((a) => a.toJson()).toList();

      // 检查是否需要分页
      final int? offset = params['offset'];
      final int? count = params['count'];

      if (offset != null || count != null) {
        final paginated = _paginate(
          agentsJson,
          offset: offset ?? 0,
          count: count ?? 100,
        );
        return jsonEncode(paginated);
      }

      // 兼容旧版本：无分页参数时返回全部数据
      return jsonEncode(agentsJson);
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
      final controller = AgentController();
      final agent = await controller.getAgent(agentId);
      if (agent == null) {
        return jsonEncode({'error': 'Agent not found: $agentId'});
      }
      return jsonEncode(agent.toJson());
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
      // 获取助手信息
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
      final controller = ServiceProviderController();
      final providers = await controller.loadProviders();
      final providersJson = providers.map((p) => p.toJson()).toList();

      // 检查是否需要分页
      final int? offset = params['offset'];
      final int? count = params['count'];

      if (offset != null || count != null) {
        final paginated = _paginate(
          providersJson,
          offset: offset ?? 0,
          count: count ?? 100,
        );
        return jsonEncode(paginated);
      }

      // 兼容旧版本：无分页参数时返回全部数据
      return jsonEncode(providersJson);
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
      final controller = ServiceProviderController();
      await controller.loadProviders();

      // 根据 ID/label 查找服务商
      final provider = controller.providers.firstWhere(
        (p) => p.id == providerId || p.label == providerId,
        orElse: () => throw Exception('Provider not found: $providerId'),
      );

      // 获取该服务商的任意一个 agent 进行测试
      final agentController = AgentController();
      await agentController.loadAgents();

      final testAgent = agentController.agents.firstWhere(
        (a) => a.serviceProviderId == provider.id,
        orElse:
            () =>
                throw Exception(
                  'No agent configured for provider: ${provider.label}',
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
        'provider': provider.label,
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
                    OpenAILocalizations.of(context).name,
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
                            OpenAILocalizations.of(context).totalAgents,
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
        final RenderBox renderBox = _bottomBarKey.currentContext!.findRenderObject() as RenderBox;
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
            title: Text(OpenAILocalizations.of(context).addPreset),
            content: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: OpenAILocalizations.of(context).presetTitle,
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descriptionController,
                    decoration: InputDecoration(
                      labelText:
                          OpenAILocalizations.of(context).presetDescription,
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: contentController,
                    decoration: InputDecoration(
                      labelText: OpenAILocalizations.of(context).contentLabel,
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
                child: Text(OpenAILocalizations.of(context).cancel),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(OpenAILocalizations.of(context).addPreset),
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
        Toast.success(OpenAILocalizations.of(context).presetSaved);
      }
    }

    nameController.dispose();
    descriptionController.dispose();
    contentController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _scheduleBottomBarHeightMeasurement();
    final Color unselectedColor =
        _colors[_currentPage].computeLuminance() < 0.5
            ? Colors.black.withOpacity(0.6)
            : Colors.white.withOpacity(0.6);
    final Color bottomAreaColor = Theme.of(context).scaffoldBackgroundColor;

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
      barColor:
          _colors[_currentPage].computeLuminance() > 0.5
              ? Colors.black
              : Colors.white,
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
                text: OpenAILocalizations.of(context).agentsTab,
              ),
              Tab(
                icon: const Icon(Icons.text_snippet_outlined),
                text: OpenAILocalizations.of(context).promptPreset,
              ),
            ],
          ),
          Positioned(
            top: -25,
            child: FloatingActionButton(
              backgroundColor: Colors.deepOrange,
              elevation: 4,
              shape: const CircleBorder(),
              child: Icon(
                _currentPage == 0 ? Icons.smart_toy : Icons.text_snippet,
                color: Colors.white,
                size: 32,
              ),
              onPressed: () {
                if (_currentPage == 0) {
                  // AI助手 tab - 创建新助手
                  Navigator.of(context).push(AgentEditScreen.route(context));
                } else {
                  // 提示词预设 tab - 创建新预设
                  _showPresetEditDialog();
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
