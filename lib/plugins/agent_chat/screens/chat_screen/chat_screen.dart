import 'package:flutter/material.dart';
import '../../controllers/chat_controller.dart';
import '../../models/conversation.dart';
import '../../models/chat_message.dart';
import '../../services/message_service.dart';
import '../../services/conversation_service.dart';
import '../../services/tool_template_service.dart';
import '../../services/message_detail_service.dart';
import '../../../../core/storage/storage_manager.dart';
import '../../../../core/js_bridge/js_bridge_manager.dart';
import '../../../../core/route/route_history_manager.dart';
import '../../../tts/tts_plugin.dart';
import '../../../../widgets/tts_settings_dialog.dart';
import 'components/message_bubble.dart';
import 'components/message_input.dart';
import 'components/save_tool_dialog.dart';
import '../tool_management_screen/tool_management_screen.dart';
import '../tool_template_screen/tool_template_screen.dart';

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

      setState(() {});

      // 仅在有新消息添加时自动滚动到底部，消息内容更新时不滚动
      if (hasNewMessage) {
        _lastMessageCount = currentMessageCount;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.enabled ? '已开启自动朗读' : '已关闭自动朗读',
            ),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    }
  }

  void _scrollToBottom({bool animate = false}) {
    if (_scrollController.hasClients) {
      if (animate) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      } else {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
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
                    _controller.currentAgent?.name ?? '点击选择Agent',
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
              const PopupMenuItem(
                value: 'tool_management',
                child: Row(
                  children: [
                    Icon(Icons.build_outlined),
                    SizedBox(width: 12),
                    Text('工具管理'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'token_stats',
                child: Row(
                  children: [
                    Icon(Icons.analytics_outlined),
                    SizedBox(width: 12),
                    Text('Token统计'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear_messages',
                child: Row(
                  children: [
                    Icon(Icons.delete_sweep),
                    SizedBox(width: 12),
                    Text('清空聊天记录'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings),
                    SizedBox(width: 12),
                    Text('会话设置'),
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
                                      title: const Text('确认清空'),
                                      content: const Text('确定要清空所有选中的工具吗？'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context, false),
                                          child: const Text('取消'),
                                        ),
                                        TextButton(
                                          onPressed: () => Navigator.pop(context, true),
                                          child: const Text('确定'),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirm == true) {
                                    await _controller.clearSelectedTools();
                                  }
                                },
                                icon: const Icon(Icons.clear_all, size: 14),
                                label: const Text('清空', style: TextStyle(fontSize: 12)),
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

                  // 消息列表
                  Expanded(
                    child:
                        _controller.messages.isEmpty
                            ? _buildEmptyState()
                            : ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.all(16),
                              itemCount: _controller.messages.length + 1, // +1 for new session button
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
                                    hasAgent: _controller.currentAgent != null,
                                    storage: widget.storage,
                                    onEdit: (messageId, newContent) async {
                                      await _controller.editMessage(
                                        messageId,
                                        newContent,
                                      );
                                    },
                                    onDelete: (messageId) async {
                                      await _showDeleteConfirmation(messageId);
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
                                    onRerunStep: (messageId, stepIndex) async {
                                      await _handleRerunStep(messageId, stepIndex);
                                    },
                                    onExecuteTemplate: (messageId, templateId) async {
                                      await _controller.executeMatchedTemplate(messageId, templateId);
                                    },
                                    getTemplateName: (templateId) {
                                      return _controller.templateService?.getTemplateById(templateId)?.name;
                                    },
                                    onCancel: message.isGenerating
                                        ? () => _controller.cancelSending()
                                        : null,
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
              label: const Text('选择Agent'),
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
                label: const Text('创建新聊天'),
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
            title: const Text('Token统计'),
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
                child: const Text('关闭'),
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('工具重新执行完成'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('重新执行工具失败: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// 处理重新执行单个步骤
  Future<void> _handleRerunStep(String messageId, int stepIndex) async {
    try {
      await _controller.rerunSingleStep(messageId, stepIndex);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('步骤 ${stepIndex + 1} 重新执行完成'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('重新执行步骤失败: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
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

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => ToolTemplateScreen(
              templateService: _templateService,
              onUseTemplate: (template) {
                _controller.setSelectedToolTemplate(template);
              },
            ),
      ),
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

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ToolManagementScreen(
          conversationId: widget.conversation.id,
          onAddToChat: (pluginId, toolId, config) async {
            await _controller.addToolToConversation(
              pluginId,
              toolId,
              config.title,
            );
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('已添加工具: ${config.title}'),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          },
        ),
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
                  title: const Text('会话设置'),
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
                              title: const Text('使用全局设置'),
                              value: null,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: RadioListTile<int?>(
                              title: const Text('自定义'),
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
                      child: const Text('取消'),
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
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('设置已保存')),
                          );
                        }
                      },
                      child: const Text('保存'),
                    ),
                  ],
                ),
          ),
    );
  }

  /// 显示清空聊天记录确认对话框
  Future<void> _showClearMessagesConfirm() async {
    if (_controller.messages.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('当前没有消息记录')));
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('确认清空'),
            content: Text(
              '确定要清空当前会话的所有消息吗？\n\n'
              '当前共有 ${_controller.messages.length} 条消息，此操作不可恢复。',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('取消'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('清空'),
              ),
            ],
          ),
    );

    if (confirm == true) {
      try {
        await _controller.clearAllMessages();
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('聊天记录已清空')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('清空失败: $e'), backgroundColor: Colors.red),
          );
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('未找到可用的Agent，请先在OpenAI插件中创建'),
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }

      final selectedAgent = await showDialog<String>(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('选择Agent'),
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
                  child: const Text('取消'),
                ),
              ],
            ),
      );

      if (selectedAgent != null && mounted) {
        try {
          await _controller.selectAgent(selectedAgent);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('已切换到 ${_controller.currentAgent?.name}'),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('切换Agent失败: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('加载Agent列表失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 显示删除确认对话框
  Future<void> _showDeleteConfirmation(String messageId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('确认删除'),
            content: const Text('确定要删除这条消息吗？'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('删除'),
              ),
            ],
          ),
    );

    if (confirm == true) {
      await _controller.deleteMessage(messageId);
    }
  }
}
