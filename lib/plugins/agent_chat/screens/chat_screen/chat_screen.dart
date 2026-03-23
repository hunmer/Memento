import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:Memento/plugins/openai/models/ai_agent.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/plugins/tts/widgets/tts_settings_dialog.dart';
import 'package:Memento/widgets/smooth_bottom_sheet.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
import 'package:Memento/plugins/agent_chat/controllers/chat_controller.dart';
import 'package:Memento/plugins/agent_chat/models/conversation.dart';
import 'package:Memento/plugins/agent_chat/models/chat_message.dart';
import 'package:Memento/plugins/agent_chat/services/message_service.dart';
import 'package:Memento/plugins/agent_chat/services/conversation_service.dart';
import 'package:Memento/plugins/agent_chat/services/tool_template_service.dart';
import 'package:Memento/plugins/agent_chat/services/message_detail_service.dart';
import 'package:Memento/plugins/agent_chat/services/suggested_questions_service.dart';
import 'package:Memento/plugins/agent_chat/services/voice_call/voice_call_manager.dart';
import 'package:Memento/plugins/agent_chat/models/voice_call_config.dart';
import 'package:Memento/plugins/agent_chat/services/voice_call/voice_call_config_dialog.dart';
import 'package:Memento/plugins/agent_chat/screens/chat_screen/components/voice_call_screen.dart';
import 'package:Memento/plugins/agent_chat/services/speech/tencent_asr_service.dart';
import 'package:Memento/core/services/speech_recognition_config_service.dart';
import 'package:Memento/core/storage/storage_manager.dart';
import 'package:Memento/core/js_bridge/js_bridge_manager.dart';
import 'package:Memento/plugins/tts/tts_plugin.dart';
import 'package:Memento/core/services/toast_service.dart';
import 'package:Memento/plugins/openai/widgets/agent_list_drawer.dart';
import 'package:memento_foreground_service/memento_foreground_service.dart';
import 'package:universal_platform/universal_platform.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'components/message_bubble.dart';
import 'components/message_input.dart';
import 'components/save_tool_dialog.dart';
import 'components/agent_chain_config_dialog.dart';
import 'components/tool_agents_config_dialog.dart';
import 'package:Memento/plugins/agent_chat/screens/tool_management_screen/tool_management_screen.dart';
import 'package:Memento/plugins/agent_chat/screens/tool_template_screen/tool_template_screen.dart';

/// 聊天界面
class ChatScreen extends StatefulWidget {
  final Conversation conversation;
  final StorageManager storage;
  final ConversationService? conversationService;
  final Map<String, dynamic> Function()? getSettings; // 获取插件设置的回调
  final String? initialMessage; // 初始消息文本（预填充到输入框）
  final List<File>? initialFiles; // 初始附件文件（预添加到消息）
  final bool autoSend; // 是否自动发送 initialMessage

  const ChatScreen({
    super.key,
    required this.conversation,
    required this.storage,
    this.conversationService,
    this.getSettings,
    this.initialMessage,
    this.initialFiles,
    this.autoSend = false,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late final ChatController _controller;
  late final ToolTemplateService _templateService;
  final ScrollController _scrollController = ScrollController();
  bool _uiHandlersRegistered = false;
  int _lastMessageCount = 0; // 记录上次的消息数量
  bool _autoReadEnabled = false; // 自动朗读开关
  String? _selectedTTSServiceId; // 选择的TTS服务ID
  String? _lastReadMessageId; // 上次朗读的消息ID
  String? _lastVoiceCallMessageId; // 上次发送到语音通话的消息ID（防止重复处理）
  bool _isListReady = false; // 列表是否准备好显示（滚动到底部后）

  // Agent 选择状态 - 由 ChatScreen 自己管理
  AIAgent? _currentAgent;
  List<AIAgent>? _agentChain; // 使用 AIAgent 列表而不是 AgentChainNode
  bool _isChainMode = false;

  // 猜你想问相关
  List<String> _suggestedQuestions = [];
  bool _isLoadingSuggestions = false;
  final SuggestedQuestionsService _suggestionsService =
      SuggestedQuestionsService();

  // 语音通话相关
  VoiceCallManager? _voiceCallManager;
  VoiceCallConfig _voiceCallConfig = const VoiceCallConfig();
  final StreamController<String> _aiMessageStreamController = StreamController<String>.broadcast();

  @override
  void initState() {
    super.initState();
    debugPrint(
      '🎬 ChatScreen initState: conversationId=${widget.conversation.id}, agentId=${widget.conversation.agentId}',
    );

    // 在第一帧渲染后注册 UI 处理器
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_uiHandlersRegistered && mounted) {
        JSBridgeManager.instance.registerUIHandlers(context);
        _uiHandlersRegistered = true;
        debugPrint('✓ ChatScreen: UI 处理器已注册');
      }
    });

    _initializeController();
    _loadSuggestedQuestions();
    _loadChatSettings(); // 加载聊天设置（TTS、语音通话配置）
    _initializeVoiceCall();
  }

  /// 加载聊天设置（从会话配置中加载）
  void _loadChatSettings() {
    // 从 ConversationService 获取最新的会话对象（而非 widget.conversation）
    final latestConversation = _controller.conversationService
        .getConversation(widget.conversation.id);

    // 从会话中加载 TTS 配置
    final ttsConfig = latestConversation?.ttsConfig;
    if (ttsConfig != null) {
      _autoReadEnabled = ttsConfig.enabled;
      _selectedTTSServiceId = ttsConfig.serviceId;
    }

    // 从会话中加载语音通话配置
    final voiceCallConfig = latestConversation?.voiceCallConfig;
    if (voiceCallConfig != null) {
      _voiceCallConfig = voiceCallConfig;
    }

    debugPrint('📖 已加载会话设置: autoReadEnabled=$_autoReadEnabled, voiceCallConfig=${voiceCallConfig != null}');
  }

  /// 保存聊天设置（保存到会话配置）
  Future<void> _saveChatSettings() async {
    try {
      // 更新会话配置
      final updatedConversation = widget.conversation.copyWith(
        ttsConfig: TTSConfig(
          enabled: _autoReadEnabled,
          serviceId: _selectedTTSServiceId,
        ),
        voiceCallConfig: _voiceCallConfig,
      );

      // 保存会话
      await _controller.conversationService.updateConversation(updatedConversation);
      debugPrint('💾 已保存会话设置到 conversation');
    } catch (e) {
      debugPrint('❌ 保存会话设置失败: $e');
    }
  }

  Future<void> _initializeController() async {
    // 初始化工具模板服务
    _templateService = ToolTemplateService(widget.storage);

    _controller = ChatController(
      conversation: widget.conversation,
      messageService: MessageService(storage: widget.storage),
      conversationService:
          widget.conversationService ??
          ConversationService(storage: widget.storage),
      messageDetailService: MessageDetailService(storage: widget.storage),
      templateService: _templateService,
      getSettings: widget.getSettings,
    );

    debugPrint('🚀 开始初始化ChatController');
    await _controller.initialize();
    debugPrint(
      '✅ ChatController初始化完成, currentAgent=${_controller.currentAgent?.name}',
    );

    // 如果提供了初始消息，设置到输入框
    if (widget.initialMessage != null && widget.initialMessage!.isNotEmpty) {
      _controller.setInputText(widget.initialMessage!);
      debugPrint('✅ 已设置初始消息到输入框: ${widget.initialMessage}');
    }

    // 如果提供了初始文件，设置到 controller
    if (widget.initialFiles != null && widget.initialFiles!.isNotEmpty) {
      _controller.setInitialFiles(widget.initialFiles!);
      debugPrint('✅ 已设置 ${widget.initialFiles!.length} 个初始文件');
    }

    // 从 controller 同步初始 agent 状态到本地
    _syncAgentStateFromController();

    // 初始化完成后在下一帧添加监听器，避免在build期间触发setState
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          // 先初始化消息计数，避免 _onControllerChanged 中 wasEmpty 触发额外滚动
          _lastMessageCount = _controller.messages.length;

          _controller.addListener(_onControllerChanged);
          _controller.messageService.addListener(_onControllerChanged);

          // 触发一次更新以显示初始化后的数据
          setState(() {});

          // 如果需要自动发送消息
          if (widget.autoSend &&
              widget.initialMessage != null &&
              widget.initialMessage!.isNotEmpty) {
            debugPrint('🚀 自动发送 Shortcuts 消息: ${widget.initialMessage}');
            // 延迟一帧确保 UI 完全初始化后再发送
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) {
                _controller.sendMessage().catchError((e) {
                  debugPrint('❌ 自动发送消息失败: $e');
                });
              }
            });
          }

          // 延迟等待 Markdown 等复杂组件渲染完成后再滚动和显示
          // Markdown 渲染会导致内容高度变化，需要等待高度稳定
          Future.delayed(const Duration(milliseconds: 200), () {
            if (mounted) {
              _scrollToBottom();
              // 滚动完成后显示列表
              setState(() {
                _isListReady = true;
              });
            }
          });
        }
      });
    }
  }

  /// 从 controller 同步 agent 状态到本地
  void _syncAgentStateFromController() {
    _isChainMode = _controller.isChainMode;
    _currentAgent = _controller.currentAgent;
    _agentChain = _controller.agentChain;
  }

  void _onControllerChanged() {
    if (mounted) {
      final currentMessageCount = _controller.messages.length;
      final hasNewMessage = currentMessageCount > _lastMessageCount;
      final wasEmpty = _lastMessageCount == 0;
      _lastMessageCount = currentMessageCount;

      // 使用 addPostFrameCallback 避免在构建过程中调用 setState
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {});
        }
      });

      // 在以下情况自动滚动到底部：
      // 1. 有新消息添加时
      // 2. 从空消息列表变为有消息时（首次进入或清空后）
      if (hasNewMessage || wasEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });
      }

      // 检查是否有新的AI消息完成，如果开启了自动朗读则进行朗读
      if (_autoReadEnabled) {
        _checkAndReadNewAIMessage();
      }

      // 检查是否需要发送AI消息到语音通话管理器
      _checkAndSendAIMessageToVoiceCall();
    }
  }

  /// 检查并朗读新的AI消息
  void _checkAndReadNewAIMessage() {
    try {
      // 获取所有消息
      final messages = _controller.messages;
      if (messages.isEmpty) return;

      // 从后往前查找第一条AI消息(非生成中)
      for (int i = messages.length - 1; i >= 0; i--) {
        final message = messages[i];

        // 只朗读AI消息，且消息已完成(非生成中)
        if (!message.isUser && !message.isGenerating) {
          // 检查是否是新消息(避免重复朗读)
          if (_lastReadMessageId != message.id &&
              message.content.trim().isNotEmpty) {
            _lastReadMessageId = message.id;

            // 调用TTS朗读
            _readMessage(message.content);
          }
          break; // 只处理最新的一条AI消息
        }
      }
    } catch (e) {
      debugPrint('检查并朗读AI消息失败: $e');
    }
  }

  /// 朗读消息
  Future<void> _readMessage(String text) async {
    try {
      final ttsPlugin = TTSPlugin.instance;
      await ttsPlugin.speak(
        text,
        serviceId: _selectedTTSServiceId, // 使用选择的服务
        onStart: () {
          debugPrint('开始朗读AI消息');
        },
        onComplete: () {
          debugPrint('朗读AI消息完成');
        },
        onError: (error) {
          debugPrint('朗读AI消息出错: $error');
        },
      );
    } catch (e) {
      debugPrint('调用TTS朗读失败: $e');
    }
  }

  // ========== 语音通话相关方法 ==========

  /// 初始化语音通话功能
  Future<void> _initializeVoiceCall() async {
    try {
      // 从全局配置服务获取ASR配置
      final asrConfig = SpeechRecognitionConfigService.instance.config;

      if (asrConfig == null || !asrConfig.isValid()) {
        debugPrint('⚠️ 未配置ASR服务，语音通话功能将不可用');
        return;
      }

      final recognitionService = TencentASRService(config: asrConfig);

      _voiceCallManager = VoiceCallManager(
        recognitionService: recognitionService,
        onUserMessage: (text) async {
          // 设置输入框文本并发送
          _controller.setInputText(text);
          await _controller.sendMessage();
        },
        aiMessageStream: _aiMessageStreamController.stream,
        onStateChanged: (state) {
          debugPrint('语音通话状态变更: $state');
        },
        onPhaseChanged: (phase) {
          debugPrint('语音通话阶段: $phase');
        },
        onError: (error) {
          if (mounted) {
            toastService.showToast('语音通话错误: $error');
          }
        },
      );

      // 应用从设置加载的配置
      _voiceCallManager!.updateConfig(_voiceCallConfig);

      await _voiceCallManager!.initialize();
      debugPrint('✅ 语音通话管理器初始化完成');
    } catch (e) {
      debugPrint('❌ 语音通话管理器初始化失败: $e');
    }
  }

  /// 检查并发送AI消息到语音通话管理器
  void _checkAndSendAIMessageToVoiceCall() {
    if (_voiceCallManager == null || !_voiceCallManager!.isCallActive) return;

    try {
      final messages = _controller.messages;
      if (messages.isEmpty) return;

      // 获取最新的AI消息
      for (int i = messages.length - 1; i >= 0; i--) {
        final message = messages[i];

        // 只处理AI消息，且消息已完成(非生成中)
        if (!message.isUser && !message.isGenerating) {
          // 检查是否是新消息（避免重复处理）
          if (_lastVoiceCallMessageId != message.id &&
              message.content.trim().isNotEmpty) {
            _lastVoiceCallMessageId = message.id;
            _voiceCallManager?.handleAIMessage(message.content);
          }
          break;
        }
      }
    } catch (e) {
      debugPrint('发送AI消息到语音通话管理器失败: $e');
    }
  }

  /// 打开语音通话界面
  Future<void> _openVoiceCall() async {
    if (_voiceCallManager == null) {
      toastService.showToast('语音通话功能未初始化，请先配置ASR服务');
      return;
    }

    // 启动前台服务
    await _startVoiceCallForegroundService();

    // 打开语音通话全屏界面
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => VoiceCallScreen(
          manager: _voiceCallManager!,
          agent: _currentAgent,
          onExit: () async {
            await _stopVoiceCallForegroundService();
            if (mounted) {
              Navigator.of(context).pop();
            }
          },
          onConfigChanged: (config) async {
            setState(() {
              _voiceCallConfig = config;
            });
            await _saveChatSettings();
          },
        ),
      ),
    );
  }

  /// 启动语音通话前台服务
  Future<void> _startVoiceCallForegroundService() async {
    if (!UniversalPlatform.isAndroid) return;

    try {
      final isRunning = await FlutterForegroundTask.isRunningService;

      if (!isRunning) {
        await FlutterForegroundTask.startService(
          serviceId: 258, // 使用不同的ID避免与聊天前台服务冲突
          notificationTitle: 'AI 语音通话',
          notificationText: '正在通话中...',
          notificationButtons: [
            NotificationButton(text: '暂停', id: 'pause'),
            NotificationButton(text: '结束', id: 'end'),
          ],
          callback: startVoiceCallTaskCallback,
        );
        debugPrint('✅ 语音通话前台服务已启动');
      }
    } catch (e) {
      debugPrint('❌ 启动语音通话前台服务失败: $e');
    }
  }

  /// 停止语音通话前台服务
  Future<void> _stopVoiceCallForegroundService() async {
    if (!UniversalPlatform.isAndroid) return;

    try {
      if (await FlutterForegroundTask.isRunningService) {
        await FlutterForegroundTask.stopService();
        debugPrint('✅ 语音通话前台服务已停止');
      }
    } catch (e) {
      debugPrint('❌ 停止语音通话前台服务失败: $e');
    }
  }

  /// 显示语音通话配置对话框的便捷方法
  Future<VoiceCallConfig?> showVoiceCallConfigDialog(
    BuildContext context, {
    required VoiceCallConfig initialConfig,
  }) {
    return showDialog<VoiceCallConfig>(
      context: context,
      builder: (context) => VoiceCallConfigDialog(initialConfig: initialConfig),
    );
  }

  /// 加载建议问题
  Future<void> _loadSuggestedQuestions() async {
    // 检查 agent 是否开启了猜你想问功能
    if (_currentAgent == null || !_currentAgent!.enableOpeningQuestions) {
      setState(() {
        _suggestedQuestions = [];
      });
      return;
    }

    // 如果有预设问题,使用预设问题
    if (_currentAgent!.openingQuestions.isNotEmpty) {
      setState(() {
        _suggestedQuestions = List.from(_currentAgent!.openingQuestions);
      });
    } else {
      // 否则使用随机问题
      final questions = await _suggestionsService.getRandomQuestions(count: 5);
      setState(() {
        _suggestedQuestions = questions;
      });
    }
  }

  /// 刷新建议问题（使用 AI 生成）
  Future<void> _refreshSuggestedQuestions() async {
    if (_currentAgent == null) return;

    setState(() {
      _isLoadingSuggestions = true;
    });

    try {
      // 使用 AI 生成新问题
      final questions = await _suggestionsService.generateQuestionsWithAI(
        agent: _currentAgent!,
        count: 5,
      );

      setState(() {
        _suggestedQuestions = questions;
        _isLoadingSuggestions = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingSuggestions = false;
      });

      if (mounted) {
        toastService.showToast('生成问题失败: $e');
      }
    }
  }

  /// 打开TTS设置对话框
  Future<void> _openTTSSettings() async {
    final result = await showTTSSettingsDialog(
      context,
      initialEnabled: _autoReadEnabled,
      initialServiceId: _selectedTTSServiceId,
    );

    if (result != null) {
      setState(() {
        _autoReadEnabled = result.enabled;
        _selectedTTSServiceId = result.serviceId;
      });

      // 保存设置到插件配置
      await _saveChatSettings();

      // 显示提示
      if (mounted) {
        toastService.showToast(result.enabled ? '已开启自动朗读' : '已关闭自动朗读');
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    }
  }

  @override
  void dispose() {
    _voiceCallManager?.dispose();
    _aiMessageStreamController.close();
    _controller.removeListener(_onControllerChanged);
    _controller.messageService.removeListener(_onControllerChanged);
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: InkWell(
          onTap: _showAgentSelector,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.conversation.title,
                style: const TextStyle(fontSize: 16),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 显示模式图标
                  Icon(
                    _isChainMode ? Icons.link : Icons.smart_toy,
                    size: 14,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),

                  // 显示 agent 信息
                  Text(
                    _getAgentDisplayText(),
                    style: TextStyle(
                      fontSize: 12,
                      color:
                          _hasValidAgent()
                              ? Colors.grey[600]
                              : Colors.orange[700],
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_drop_down,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          // 工具调用 Agent 配置按钮
          IconButton(
            icon: const Icon(Icons.build_circle_outlined),
            onPressed: _showToolAgentsConfig,
            tooltip: '工具调用 Agent',
          ),
          // 工具模板管理按钮
          IconButton(
            icon: const Icon(Icons.inventory_2_outlined),
            onPressed: _openToolTemplateManagement,
            tooltip: '工具模板',
          ),
          // 自动朗读设置按钮
          IconButton(
            icon: Icon(
              _autoReadEnabled ? Icons.volume_up : Icons.volume_off,
              color: _autoReadEnabled ? Colors.blue : null,
            ),
            onPressed: _openTTSSettings,
            tooltip: '语音播报设置',
          ),
          // 语音通话按钮
          IconButton(
            icon: const Icon(Icons.phone_in_talk),
            onPressed: _openVoiceCall,
            tooltip: '语音通话',
          ),
          // 更多菜单
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            tooltip: '更多',
            onSelected: (value) {
              switch (value) {
                case 'tool_management':
                  _openToolManagement();
                  break;
                case 'token_stats':
                  _showTokenStats();
                  break;
                case 'clear_messages':
                  _showClearMessagesConfirm();
                  break;
                case 'settings':
                  _showSettings();
                  break;
              }
            },
            itemBuilder:
                (context) => [
                  PopupMenuItem(
                    value: 'tool_management',
                    child: Row(
                      children: [
                        const Icon(Icons.build_outlined),
                        const SizedBox(width: 12),
                        Text('agent_chat_toolManagement'.tr),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'token_stats',
                    child: Row(
                      children: [
                        const Icon(Icons.analytics_outlined),
                        const SizedBox(width: 12),
                        Text('agent_chat_tokenStatistics'.tr),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'clear_messages',
                    child: Row(
                      children: [
                        const Icon(Icons.delete_sweep),
                        const SizedBox(width: 12),
                        Text('agent_chat_confirmClear'.tr),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'settings',
                    child: Row(
                      children: [
                        const Icon(Icons.settings),
                        const SizedBox(width: 12),
                        Text('agent_chat_conversationSettings'.tr),
                      ],
                    ),
                  ),
                ],
          ),
        ],
      ),
      body:
          _controller.isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  // 已选工具列表
                  if (_controller.selectedTools.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        border: Border(
                          bottom: BorderSide(
                            color: Colors.blue.withValues(alpha: 0.3),
                          ),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.build,
                                size: 16,
                                color: Colors.blue,
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                '已选工具:',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                              const Spacer(),
                              TextButton.icon(
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder:
                                        (context) => AlertDialog(
                                          title: Text(
                                            'agent_chat_confirmClear'.tr,
                                          ),
                                          content: Text(
                                            'agent_chat_confirmClearTools'.tr,
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed:
                                                  () => Navigator.pop(
                                                    context,
                                                    false,
                                                  ),
                                              child: Text(
                                                'agent_chat_cancel'.tr,
                                              ),
                                            ),
                                            TextButton(
                                              onPressed:
                                                  () => Navigator.pop(
                                                    context,
                                                    true,
                                                  ),
                                              child: Text(
                                                'agent_chat_confirm'.tr,
                                              ),
                                            ),
                                          ],
                                        ),
                                  );
                                  if (confirm == true) {
                                    await _controller.clearSelectedTools();
                                  }
                                },
                                icon: const Icon(Icons.clear_all, size: 14),
                                label: Text(
                                  'agent_chat_clear'.tr,
                                  style: TextStyle(fontSize: 12),
                                ),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  minimumSize: const Size(0, 28),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children:
                                _controller.selectedTools.map((tool) {
                                  return Chip(
                                    label: Text(
                                      tool['toolName'] ?? tool['toolId'] ?? '',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    deleteIcon: const Icon(
                                      Icons.close,
                                      size: 16,
                                    ),
                                    onDeleted: () async {
                                      await _controller
                                          .removeToolFromConversation(
                                            tool['id']!,
                                          );
                                    },
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                    visualDensity: VisualDensity.compact,
                                  );
                                }).toList(),
                          ),
                        ],
                      ),
                    ),

                  // 猜你想问区域
                  if (_suggestedQuestions.isNotEmpty &&
                      _controller.messages.isEmpty)
                    _buildSuggestedQuestionsBar(),

                  // 消息列表
                  Expanded(
                    child:
                        _controller.messages.isEmpty
                            ? _buildEmptyState()
                            : AnimatedOpacity(
                              opacity: _isListReady ? 1.0 : 0.0,
                              duration: const Duration(milliseconds: 150),
                              child: ListView.builder(
                                controller: _scrollController,
                                padding: const EdgeInsets.all(16),
                                itemCount:
                                    _controller.messages.length +
                                    1, // +1 for new session button
                                physics: const ClampingScrollPhysics(),
                                itemBuilder: (context, index) {
                                  // 最后一个 item 显示新会话按钮
                                  if (index == _controller.messages.length) {
                                    return _buildNewSessionButton();
                                  }

                                  final message = _controller.messages[index];

                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: MessageBubble(
                                      message: message,
                                      hasAgent: _currentAgent != null,
                                      storage: widget.storage,
                                      onEdit: (messageId, newContent) async {
                                        await _controller.editMessage(
                                          messageId,
                                          newContent,
                                        );
                                      },
                                      onDelete: (messageId) async {
                                        await _showDeleteConfirmation(
                                          messageId,
                                        );
                                      },
                                      onRegenerate: (messageId) async {
                                        await _controller.regenerateResponse(
                                          messageId,
                                        );
                                      },
                                      onSaveTool: (message) async {
                                        await _handleSaveTool(message);
                                      },
                                      onRerunTool: (messageId) async {
                                        await _handleRerunTool(messageId);
                                      },
                                      onRerunStep: (
                                        messageId,
                                        stepIndex,
                                      ) async {
                                        await _handleRerunStep(
                                          messageId,
                                          stepIndex,
                                        );
                                      },
                                      onExecuteTemplate: (
                                        messageId,
                                        templateId,
                                      ) async {
                                        final template = _controller
                                            .templateService
                                            ?.getTemplateById(templateId);
                                        if (template != null) {
                                          await _controller
                                              .executeMatchedTemplate(
                                                messageId,
                                                template,
                                              );
                                        }
                                      },
                                      getTemplateName: (templateId) {
                                        return _controller.templateService
                                            ?.getTemplateById(templateId)
                                            ?.name;
                                      },
                                      getAgentName: (agentId) {
                                        // 从 agent 链中查找
                                        if (_isChainMode &&
                                            _agentChain != null) {
                                          final agent = _agentChain!.firstWhere(
                                            (a) => a.id == agentId,
                                            orElse: () => _agentChain!.first,
                                          );
                                          return agent.name;
                                        }
                                        return _currentAgent?.name;
                                      },
                                      onCancel:
                                          message.isGenerating
                                              ? () =>
                                                  _controller.cancelSending()
                                              : null,
                                      messageService:
                                          _controller.messageService,
                                    ),
                                  );
                                },
                              ),
                            ),
                  ),

                  // 输入框
                  MessageInput(controller: _controller),
                ],
              ),
    );
  }

  /// 构建猜你想问横条
  Widget _buildSuggestedQuestionsBar() {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          Icon(
            Icons.tips_and_updates_outlined,
            size: 18,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Text(
            '猜你想问',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(context).copyWith(
                dragDevices: {
                  PointerDeviceKind.touch,
                  PointerDeviceKind.mouse,
                  PointerDeviceKind.trackpad,
                },
              ),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _suggestedQuestions.length,
                itemBuilder: (context, index) {
                  final question = _suggestedQuestions[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      label: Text(
                        question,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onPressed: () {
                        // 点击问题填入输入框
                        _controller.setInputText(question);
                      },
                      avatar: Icon(
                        Icons.chat_bubble_outline,
                        size: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      backgroundColor: Theme.of(context).colorScheme.surface,
                      side: BorderSide(
                        color: Theme.of(
                          context,
                        ).colorScheme.outline.withValues(alpha: 0.3),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 8),
          // 刷新按钮
          IconButton(
            icon:
                _isLoadingSuggestions
                    ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    )
                    : Icon(
                      Icons.refresh,
                      size: 20,
                      color: Theme.of(context).colorScheme.primary,
                    ),
            onPressed:
                _isLoadingSuggestions ? null : _refreshSuggestedQuestions,
            tooltip: '刷新问题',
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  /// 构建空状态
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            _currentAgent != null ? '开始新的对话' : '请先选择一个Agent',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          if (_currentAgent != null)
            Text(
              '当前Agent: ${_currentAgent!.name}',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            )
          else
            OutlinedButton.icon(
              onPressed: _showAgentSelector,
              icon: const Icon(Icons.smart_toy),
              label: Text('agent_chat_selectAgent'.tr),
            ),
        ],
      ),
    );
  }

  /// 构建新会话按钮
  Widget _buildNewSessionButton() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child:
            _controller.isLastMessageSessionDivider
                ? Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.blue.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 16,
                        color: Colors.blue[700],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '已开启新会话',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.blue[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                )
                : OutlinedButton.icon(
                  onPressed: () async {
                    await _controller.createNewSession();
                    // 自动滚动到底部
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _scrollToBottom();
                    });
                  },
                  icon: const Icon(Icons.add_circle_outline, size: 18),
                  label: Text('agent_chat_createNewChat'.tr),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    side: BorderSide(color: Colors.blue.withValues(alpha: 0.5)),
                    foregroundColor: Colors.blue[700],
                  ),
                ),
      ),
    );
  }

  /// 显示Token统计
  void _showTokenStats() {
    final totalTokens = _controller.getTotalTokens();
    final contextTokens = _controller.getContextTokens();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('agent_chat_tokenStatistics'.tr),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatRow('总Token数', totalTokens.toString()),
                const SizedBox(height: 8),
                _buildStatRow('上下文Token数', contextTokens.toString()),
                const SizedBox(height: 8),
                _buildStatRow('上下文消息数', '${_controller.contextMessageCount} 条'),
                const SizedBox(height: 16),
                Text(
                  '注：Token数为估算值，实际消耗以API返回为准',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('agent_chat_close'.tr),
              ),
            ],
          ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 14)),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  /// 处理保存工具
  Future<void> _handleSaveTool(ChatMessage message) async {
    await showSaveToolDialog(
      context,
      message,
      _templateService,
      declaredTools: _controller.selectedTools,
    );
  }

  /// 处理重新执行工具
  Future<void> _handleRerunTool(String messageId) async {
    try {
      await _controller.rerunToolCall(messageId);
      if (mounted) {
        toastService.showToast('工具重新执行完成');
      }
    } catch (e) {
      if (mounted) {
        toastService.showToast('重新执行工具失败: $e');
      }
    }
  }

  /// 处理重新执行单个步骤
  Future<void> _handleRerunStep(String messageId, int stepIndex) async {
    try {
      await _controller.rerunSingleStep(messageId, stepIndex);
      if (mounted) {
        toastService.showToast('步骤 ${stepIndex + 1} 重新执行完成');
      }
    } catch (e) {
      if (mounted) {
        toastService.showToast('重新执行步骤失败: $e');
      }
    }
  }

  /// 打开工具模板管理界面
  void _openToolTemplateManagement() {
    NavigationHelper.push(
      context,
      ToolTemplateScreen(
        templateService: _templateService,
        onUseTemplate: (template) {
          _controller.setSelectedToolTemplate(template);
        },
      ),
    );
  }

  /// 打开工具管理界面
  void _openToolManagement() {
    NavigationHelper.push(
      context,
      ToolManagementScreen(
        conversationId: widget.conversation.id,
        onAddToChat: (pluginId, toolId, config) async {
          await _controller.addToolToConversation(
            pluginId,
            toolId,
            config.title,
          );
          if (mounted) {
            toastService.showToast('已添加工具: ${config.title}');
          }
        },
      ),
    );
  }

  /// 显示设置对话框
  void _showSettings() {
    int? customContextCount = widget.conversation.contextMessageCount;

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setDialogState) => AlertDialog(
                  title: Text('agent_chat_conversationSettings'.tr),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '上下文消息数量',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: RadioListTile<int?>(
                              title: Text('agent_chat_useGlobalSettings'.tr),
                              value: null,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: RadioListTile<int?>(
                              title: Text('agent_chat_custom'.tr),
                              value: -1, // 用-1表示自定义模式
                            ),
                          ),
                        ],
                      ),
                      if (customContextCount != null)
                        Padding(
                          padding: const EdgeInsets.only(left: 16, top: 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: Slider(
                                  value: customContextCount!.toDouble(),
                                  min: 1,
                                  max: 50,
                                  divisions: 49,
                                  label: customContextCount.toString(),
                                  onChanged: (value) {
                                    setDialogState(() {
                                      customContextCount = value.toInt();
                                    });
                                  },
                                ),
                              ),
                              SizedBox(
                                width: 40,
                                child: Text(
                                  '$customContextCount',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('agent_chat_cancel'.tr),
                    ),
                    TextButton(
                      onPressed: () async {
                        // 保存设置
                        final updatedConversation = widget.conversation
                            .copyWith(contextMessageCount: customContextCount);
                        await _controller.conversationService
                            .updateConversation(updatedConversation);
                        if (mounted) {
                          Navigator.pop(context);
                          toastService.showToast('Settings saved');
                        }
                      },
                      child: Text('agent_chat_save'.tr),
                    ),
                  ],
                ),
          ),
    );
  }

  /// 显示清空聊天记录确认对话框
  Future<void> _showClearMessagesConfirm() async {
    if (_controller.messages.isEmpty) {
      toastService.showToast('当前没有消息记录');
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('agent_chat_confirmClear'.tr),
            content: Text(
              '确定要清空当前会话的所有消息吗？\n\n'
              '当前共有 ${_controller.messages.length} 条消息，此操作不可恢复。',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('agent_chat_cancel'.tr),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text('agent_chat_clear'.tr),
              ),
            ],
          ),
    );

    if (confirm == true) {
      try {
        await _controller.clearAllMessages();
        if (mounted) {
          toastService.showToast('聊天记录已清空');
        }
      } catch (e) {
        if (mounted) {
          toastService.showToast('清空失败: $e');
        }
      }
    }
  }

  /// 显示Agent选择器（支持单/链模式选择）
  Future<void> _showAgentSelector() async {
    if (!mounted) return;

    // 检查当前配置状态
    final isCurrentlySingleMode = !_isChainMode && _currentAgent != null;
    final isCurrentlyChainMode =
        _isChainMode && _agentChain != null && _agentChain!.isNotEmpty;

    // 获取当前配置的agent显示文本
    String getCurrentAgentDisplayText() {
      if (isCurrentlySingleMode) {
        return '当前: ${_currentAgent!.name}';
      } else if (isCurrentlyChainMode) {
        final chainLength = _agentChain!.length;
        final agentNames = _agentChain!.map((a) => a.name).join(' → ');
        return '当前 ($chainLength个): $agentNames';
      }
      return '未配置';
    }

    // 显示模式选择对话框
    final mode = await showDialog<String>(
      context: context,
      builder:
          (context) => SimpleDialog(
            title: const Text('选择配置模式'),
            children: [
              SimpleDialogOption(
                onPressed: () => Navigator.pop(context, 'single'),
                child: ListTile(
                  leading: Icon(
                    isCurrentlySingleMode
                        ? Icons.check_circle
                        : Icons.smart_toy,
                    color: isCurrentlySingleMode ? Colors.green : null,
                  ),
                  title: const Text('单 Agent 模式'),
                  subtitle: Text(
                    isCurrentlySingleMode
                        ? '${getCurrentAgentDisplayText()} | 选择一个 Agent 进行对话'
                        : '选择一个 Agent 进行对话',
                  ),
                ),
              ),
              SimpleDialogOption(
                onPressed: () => Navigator.pop(context, 'chain'),
                child: ListTile(
                  leading: Icon(
                    isCurrentlyChainMode ? Icons.check_circle : Icons.link,
                    color: isCurrentlyChainMode ? Colors.green : null,
                  ),
                  title: const Text('Agent 链模式'),
                  subtitle: Text(
                    isCurrentlyChainMode
                        ? '${getCurrentAgentDisplayText()} | 配置多个 Agent 顺序执行'
                        : '配置多个 Agent 顺序执行',
                  ),
                ),
              ),
            ],
          ),
    );

    if (mode == null || !mounted) return;

    if (mode == 'single') {
      await _showSingleAgentSelector();
    } else {
      await _showAgentChainConfig();
    }
  }

  /// 显示单 Agent 选择器
  Future<void> _showSingleAgentSelector() async {
    if (!mounted) return;

    final currentAgent = _currentAgent;
    final selectedAgents =
        currentAgent != null
            ? [
              {'id': currentAgent.id, 'name': currentAgent.name},
            ]
            : <Map<String, String>>[];

    await SmoothBottomSheet.show<void>(
      context: context,
      isScrollControlled: true,
      builder:
          (context) => AgentListDrawer(
            selectedAgents: selectedAgents,
            allowMultipleSelection: false,
            onAgentSelected: (List<Map<String, String>> agents) async {
              if (agents.isEmpty) return;

              final selectedAgentId = agents.first['id'];
              if (selectedAgentId == null) return;

              try {
                await _controller.switchToSingleAgent(selectedAgentId);
                await _loadSuggestedQuestions();

                // 立即更新本地状态并刷新 UI
                if (mounted) {
                  // 重新从 controller 同步状态
                  _syncAgentStateFromController();
                  // 强制刷新 UI
                  setState(() {});
                  toastService.showToast('已切换到 ${agents.first['name']}');
                }
              } catch (e) {
                if (mounted) {
                  toastService.showToast('切换Agent失败: $e');
                }
              }
            },
          ),
    );
  }

  /// 显示 Agent 链配置对话框
  Future<void> _showAgentChainConfig() async {
    if (!mounted) return;

    await showDialog(
      context: context,
      builder:
          (context) => AgentChainConfigDialog(
            initialChain: _controller.conversation.agentChain,
            onSave: (chain) async {
              try {
                await _controller.selectAgentChain(chain);

                // 立即更新本地状态并刷新 UI
                if (mounted) {
                  // 重新从 controller 同步状态
                  _syncAgentStateFromController();
                  // 强制刷新 UI
                  setState(() {});
                  toastService.showToast('Agent 链配置成功');
                }
              } catch (e) {
                if (mounted) {
                  toastService.showToast('配置失败: $e');
                }
              }
            },
          ),
    );
  }

  /// 显示工具调用 Agent 配置对话框
  Future<void> _showToolAgentsConfig() async {
    if (!mounted) return;

    await showDialog(
      context: context,
      builder:
          (context) => ToolAgentsConfigDialog(
            initialToolDetectionConfig:
                _controller.conversation.toolDetectionConfig,
            initialToolExecutionConfig:
                _controller.conversation.toolExecutionConfig,
            onSave: (toolDetectionConfig, toolExecutionConfig) async {
              try {
                await _controller.configureToolAgents(
                  toolDetectionConfig: toolDetectionConfig,
                  toolExecutionConfig: toolExecutionConfig,
                );
                if (mounted) {
                  toastService.showToast('工具 Agent 配置成功');
                }
              } catch (e) {
                if (mounted) {
                  toastService.showToast('配置失败: $e');
                }
              }
            },
          ),
    );
  }

  /// 获取 Agent 显示文本
  String _getAgentDisplayText() {
    if (_isChainMode) {
      final chainLength = _agentChain?.length ?? 0;
      if (chainLength == 0) return '配置 Agent 链';
      return '$chainLength 个 Agent 链';
    } else {
      return _currentAgent?.name ?? 'agent_chat_selectAgent'.tr;
    }
  }

  /// 检查是否有有效的 Agent
  bool _hasValidAgent() {
    if (_isChainMode) {
      return _agentChain != null && _agentChain!.isNotEmpty;
    } else {
      return _currentAgent != null;
    }
  }

  /// 显示删除确认对话框
  Future<void> _showDeleteConfirmation(String messageId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('agent_chat_confirmDelete'.tr),
            content: Text('agent_chat_confirmDeleteMessage'.tr),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('agent_chat_cancel'.tr),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: Text('agent_chat_delete'.tr),
              ),
            ],
          ),
    );

    if (confirm == true) {
      await _controller.deleteMessage(messageId);
    }
  }
}

// ========== 前台服务回调 ==========

/// 语音通话前台服务启动回调
///
/// 必须是顶层函数，用于前台服务启动
@pragma('vm:entry-point')
void startVoiceCallTaskCallback() {
  FlutterForegroundTask.setTaskHandler(VoiceCallTaskHandler());
}

/// 语音通话前台服务任务处理器
class VoiceCallTaskHandler extends TaskHandler {
  static String notificationTitle = 'AI 语音通话';
  static String notificationText = '正在通话中...';

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    debugPrint('🚀 语音通话前台服务已启动');
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    // 定期任务（可选）
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    debugPrint('🗑️ 语音通话前台服务已销毁');
  }

  @override
  void onButtonPressed(String id) {
    debugPrint('🔔 通知按钮被点击: $id');
    // 发送事件到主应用
    switch (id) {
      case '0': // 第一个按钮
        FlutterForegroundTask.sendDataToTask({'event': 'pause_call'});
        break;
      case '1': // 第二个按钮
        FlutterForegroundTask.sendDataToTask({'event': 'end_call'});
        break;
    }
  }

  @override
  void onReceiveData(Object data) {
    // 接收来自主应用的数据
    if (data is Map<String, dynamic>) {
      final action = data['action'];
      if (action == 'update_notification') {
        notificationTitle = data['title'] ?? notificationTitle;
        notificationText = data['content'] ?? notificationText;

        FlutterForegroundTask.updateService(
          notificationTitle: notificationTitle,
          notificationText: notificationText,
        );
      }
    }
  }
}
