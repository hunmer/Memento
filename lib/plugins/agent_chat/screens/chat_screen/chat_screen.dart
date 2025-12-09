import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
import 'package:Memento/plugins/agent_chat/controllers/chat_controller.dart';
import 'package:Memento/plugins/agent_chat/models/conversation.dart';
import 'package:Memento/plugins/agent_chat/models/chat_message.dart';
import 'package:Memento/plugins/agent_chat/services/message_service.dart';
import 'package:Memento/plugins/agent_chat/services/conversation_service.dart';
import 'package:Memento/plugins/agent_chat/services/tool_template_service.dart';
import 'package:Memento/plugins/agent_chat/services/message_detail_service.dart';
import 'package:Memento/plugins/agent_chat/services/suggested_questions_service.dart';
import 'package:Memento/core/storage/storage_manager.dart';
import 'package:Memento/core/js_bridge/js_bridge_manager.dart';
import 'package:Memento/core/route/route_history_manager.dart';
import 'package:Memento/plugins/tts/tts_plugin.dart';
import 'package:Memento/widgets/tts_settings_dialog.dart';
import 'package:Memento/core/services/toast_service.dart';
import 'components/message_bubble.dart';
import 'components/message_input.dart';
import 'components/save_tool_dialog.dart';
import 'package:Memento/plugins/agent_chat/screens/tool_management_screen/tool_management_screen.dart';
import 'package:Memento/plugins/agent_chat/screens/tool_template_screen/tool_template_screen.dart';
import 'package:Memento/plugins/agent_chat/l10n/agent_chat_localizations.dart';

/// 聊天界面
class ChatScreen extends StatefulWidget {
  final Conversation conversation;
  final StorageManager storage;
  final ConversationService? conversationService;
  final Map<String, dynamic> Function()? getSettings; // 获取插件设置的回调

  const ChatScreen({
    super.key,
    required this.conversation,
    required this.storage,
    this.conversationService,
    this.getSettings,
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

  // 猜你想问相关
  List<String> _suggestedQuestions = [];
  bool _isLoadingSuggestions = false;
  final SuggestedQuestionsService _suggestionsService = SuggestedQuestionsService();

  // 消息淡入动画相关
  final Set<String> _fadingMessages = {}; // 记录正在淡入的消息ID

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
  }

  Future<void> _initializeController() async {
    // 初始化工具模板服务
    _templateService = ToolTemplateService(widget.storage);

    _controller = ChatController(
      conversation: widget.conversation,
      messageService: MessageService(storage: widget.storage),
      conversationService: widget.conversationService ??
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

    // 初始化完成后在下一帧添加监听器，避免在build期间触发setState
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _controller.addListener(_onControllerChanged);
          _controller.messageService.addListener(_onControllerChanged);
          // 触发一次更新以显示初始化后的数据
          if (mounted) {
            setState(() {});
          }
          // 滚动到底部
          _scrollToBottom();
        }
      });
    }
  }

  void _onControllerChanged() {
    if (mounted) {
      final currentMessageCount = _controller.messages.length;
      final hasNewMessage = currentMessageCount > _lastMessageCount;
      final wasEmpty = _lastMessageCount == 0;
      final newMessageCount = currentMessageCount - _lastMessageCount;
      _lastMessageCount = currentMessageCount;

      // 如果有新消息，标记它们以添加淡入动画
      if (hasNewMessage && newMessageCount > 0) {
        // 标记新消息以添加淡入动画
        for (
          int i = currentMessageCount - newMessageCount;
          i < currentMessageCount;
          i++
        ) {
          if (i >= 0 && i < _controller.messages.length) {
            _fadingMessages.add(_controller.messages[i].id);
          }
        }
      }

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
          _scrollToBottom(animate: hasNewMessage);
        });
      }

      // 检查是否有新的AI消息完成，如果开启了自动朗读则进行朗读
      if (_autoReadEnabled) {
        _checkAndReadNewAIMessage();
      }
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
          if (_lastReadMessageId != message.id && message.content.trim().isNotEmpty) {
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

  /// 加载建议问题
  Future<void> _loadSuggestedQuestions() async {
    // 检查 agent 是否开启了猜你想问功能
    if (_controller.currentAgent == null ||
        !_controller.currentAgent!.enableOpeningQuestions) {
      setState(() {
        _suggestedQuestions = [];
      });
      return;
    }

    // 如果有预设问题,使用预设问题
    if (_controller.currentAgent!.openingQuestions.isNotEmpty) {
      setState(() {
        _suggestedQuestions = List.from(_controller.currentAgent!.openingQuestions);
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
    if (_controller.currentAgent == null) return;

    setState(() {
      _isLoadingSuggestions = true;
    });

    try {
      // 使用 AI 生成新问题
      final questions = await _suggestionsService.generateQuestionsWithAI(
        agent: _controller.currentAgent!,
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

      // 显示提示
      if (mounted) {
        toastService.showToast(
          result.enabled ? '已开启自动朗读' : '已关闭自动朗读',
        );
      }
    }
  }

  void _scrollToBottom({bool animate = false}) {
    // 尝试滚动，如果控制器还未准备好则延迟重试
    if (_scrollController.hasClients) {
      if (animate) {
        // 使用更短的持续时间和更柔和的曲线，减少动画的明显程度
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutCubic,
        );
      } else {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    } else {
      // 延迟一帧后重试，确保控制器已准备好
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          if (animate) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOutCubic,
            );
          } else {
            _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
          }
        }
      });
    }
  }

  @override
  void dispose() {
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
                  Text(
                    _controller.currentAgent?.name ?? AgentChatLocalizations.of(context).selectAgent,
                    style: TextStyle(
                      fontSize: 12,
                      color:
                          _controller.currentAgent != null
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
            itemBuilder: (context) => [
                  PopupMenuItem(
                value: 'tool_management',
                child: Row(
                  children: [
                        const Icon(Icons.build_outlined),
                        const SizedBox(width: 12),
                    Text(AgentChatLocalizations.of(context).toolManagement),
                  ],
                ),
              ),
                  PopupMenuItem(
                value: 'token_stats',
                child: Row(
                  children: [
                        const Icon(Icons.analytics_outlined),
                        const SizedBox(width: 12),
                    Text(AgentChatLocalizations.of(context).tokenStatistics),
                  ],
                ),
              ),
                  PopupMenuItem(
                value: 'clear_messages',
                child: Row(
                  children: [
                        const Icon(Icons.delete_sweep),
                        const SizedBox(width: 12),
                    Text(AgentChatLocalizations.of(context).confirmClear),
                  ],
                ),
              ),
                  PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                        const Icon(Icons.settings),
                        const SizedBox(width: 12),
                    Text(AgentChatLocalizations.of(context).conversationSettings),
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
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                              const Icon(Icons.build, size: 16, color: Colors.blue),
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
                                    builder: (context) => AlertDialog(
                                      title: Text(AgentChatLocalizations.of(context).confirmClear),
                                      content: Text(AgentChatLocalizations.of(context).confirmClearTools),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context, false),
                                          child: Text(AgentChatLocalizations.of(context).cancel),
                                        ),
                                        TextButton(
                                          onPressed: () => Navigator.pop(context, true),
                                          child: Text(AgentChatLocalizations.of(context).confirm),
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
                                  AgentChatLocalizations.of(context).clear,
                                  style: TextStyle(fontSize: 12),
                                ),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  minimumSize: const Size(0, 28),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: _controller.selectedTools.map((tool) {
                              return Chip(
                                label: Text(
                                  tool['toolName'] ?? tool['toolId'] ?? '',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                deleteIcon: const Icon(Icons.close, size: 16),
                                onDeleted: () async {
                                  await _controller.removeToolFromConversation(
                                    tool['pluginId']!,
                                    tool['toolId']!,
                                  );
                                },
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                visualDensity: VisualDensity.compact,
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),

                  // 猜你想问区域
                  if (_suggestedQuestions.isNotEmpty && _controller.messages.isEmpty)
                    _buildSuggestedQuestionsBar(),

                  // 消息列表
                  Expanded(
                    child:
                        _controller.messages.isEmpty
                            ? _buildEmptyState()
                            : ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.all(16),
                              itemCount:
                                  _controller.messages.length +
                                  1, // +1 for new session button
                              physics: const BouncingScrollPhysics(
                                parent: AlwaysScrollableScrollPhysics(),
                              ),
                              itemBuilder: (context, index) {
                                // 最后一个 item 显示新会话按钮
                                if (index == _controller.messages.length) {
                                  return _buildNewSessionButton();
                                }

                                final message = _controller.messages[index];
                                final isNewMessage = _fadingMessages.contains(
                                  message.id,
                                );

                                return AnimatedOpacity(
                                  opacity: isNewMessage ? 0.0 : 1.0,
                                  duration: const Duration(milliseconds: 200),
                                  curve: Curves.easeIn,
                                  onEnd: () {
                                    // 动画结束后移除标记
                                    if (isNewMessage && mounted) {
                                      // 使用 addPostFrameCallback 避免在构建过程中调用 setState
                                      WidgetsBinding.instance
                                          .addPostFrameCallback((_) {
                                            if (mounted) {
                                              setState(() {
                                                _fadingMessages.remove(
                                                  message.id,
                                                );
                                              });
                                            }
                                          });
                                    }
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: MessageBubble(
                                      message: message,
                                      hasAgent:
                                          _controller.currentAgent != null,
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
                                        await _controller
                                            .executeMatchedTemplate(
                                              messageId,
                                              templateId,
                                            );
                                      },
                                      getTemplateName: (templateId) {
                                        return _controller.templateService
                                            ?.getTemplateById(templateId)
                                            ?.name;
                                      },
                                      onCancel:
                                          message.isGenerating
                                              ? () =>
                                                  _controller.cancelSending()
                                              : null,
                                    ),
                                  ),
                                );
                              },
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
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
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
                        color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
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
            icon: _isLoadingSuggestions
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
            onPressed: _isLoadingSuggestions ? null : _refreshSuggestedQuestions,
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
            _controller.currentAgent != null ? '开始新的对话' : '请先选择一个Agent',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          if (_controller.currentAgent != null)
            Text(
              '当前Agent: ${_controller.currentAgent!.name}',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            )
          else
            OutlinedButton.icon(
              onPressed: _showAgentSelector,
              icon: const Icon(Icons.smart_toy),
              label: Text(AgentChatLocalizations.of(context).selectAgent),
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
        child: _controller.isLastMessageSessionDivider
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                    Icon(Icons.check_circle, size: 16, color: Colors.blue[700]),
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
                    _scrollToBottom(animate: true);
                  });
                },
                icon: const Icon(Icons.add_circle_outline, size: 18),
                label: Text(AgentChatLocalizations.of(context).createNewChat),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
            title: Text(AgentChatLocalizations.of(context).tokenStatistics),
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
                child: Text(AgentChatLocalizations.of(context).close),
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
    // 记录路由访问历史
    RouteHistoryManager.recordPageVisit(
      pageId: 'tool_template',
      title: '工具模板管理',
      icon: Icons.inventory_2_outlined,
    );

    NavigationHelper.push(context, ToolTemplateScreen(
              templateService: _templateService,
              onUseTemplate: (template) {
                _controller.setSelectedToolTemplate(template);
              },),
    );
  }

  /// 打开工具管理界面
  void _openToolManagement() {
    // 记录路由访问历史
    RouteHistoryManager.recordPageVisit(
      pageId: 'tool_management',
      title: '工具配置管理',
      icon: Icons.settings_outlined,
    );

    NavigationHelper.push(context, ToolManagementScreen(
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
                  title: Text(AgentChatLocalizations.of(context).conversationSettings),
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
                              title: Text(AgentChatLocalizations.of(context).useGlobalSettings),
                              value: null,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: RadioListTile<int?>(
                              title: Text(AgentChatLocalizations.of(context).custom),
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
                      child: Text(AgentChatLocalizations.of(context).cancel),
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
                      child: Text(AgentChatLocalizations.of(context).save),
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
            title: Text(AgentChatLocalizations.of(context).confirmClear),
            content: Text(
              '确定要清空当前会话的所有消息吗？\n\n'
              '当前共有 ${_controller.messages.length} 条消息，此操作不可恢复。',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(AgentChatLocalizations.of(context).cancel),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(AgentChatLocalizations.of(context).clear),
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

  /// 显示Agent选择器
  Future<void> _showAgentSelector() async {
    try {
      final agents = await _controller.getAvailableAgents();

      if (!mounted) return;

      if (agents.isEmpty) {
        toastService.showToast('未找到可用的Agent，请先在OpenAI插件中创建');
        return;
      }

      final selectedAgent = await showDialog<String>(
        context: context,
        builder:
            (context) => AlertDialog(
              title: Text(AgentChatLocalizations.of(context).selectAgent),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: agents.length,
                  itemBuilder: (context, index) {
                    final agent = agents[index];
                    final isSelected = _controller.currentAgent?.id == agent.id;

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                            isSelected ? Colors.blue : Colors.grey[300],
                        child: Icon(
                          Icons.smart_toy,
                          color: isSelected ? Colors.white : Colors.grey[600],
                        ),
                      ),
                      title: Text(
                        agent.name,
                        style: TextStyle(
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      subtitle: Text(
                        agent.description.isEmpty ? '暂无描述' : agent.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing:
                          isSelected
                              ? const Icon(
                                Icons.check_circle,
                                color: Colors.blue,
                              )
                              : null,
                      selected: isSelected,
                      onTap: () => Navigator.pop(context, agent.id),
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(AgentChatLocalizations.of(context).cancel),
                ),
              ],
            ),
      );

      if (selectedAgent != null && mounted) {
        try {
          await _controller.selectAgent(selectedAgent);
          // 切换 agent 后重新加载建议问题
          await _loadSuggestedQuestions();
          if (mounted) {
            toastService.showToast('已切换到 ${_controller.currentAgent?.name}');
          }
        } catch (e) {
          if (mounted) {
            toastService.showToast('切换Agent失败: $e');
          }
        }
      }
    } catch (e) {
      if (mounted) {
        toastService.showToast('加载Agent列表失败: $e');
      }
    }
  }

  /// 显示删除确认对话框
  Future<void> _showDeleteConfirmation(String messageId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(AgentChatLocalizations.of(context).confirmDelete),
            content: Text(AgentChatLocalizations.of(context).confirmDeleteMessage),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(AgentChatLocalizations.of(context).cancel),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: Text(AgentChatLocalizations.of(context).delete),
              ),
            ],
          ),
    );

    if (confirm == true) {
      await _controller.deleteMessage(messageId);
    }
  }
}
