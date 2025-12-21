import 'package:flutter/material.dart';
import 'package:Memento/plugins/agent_chat/models/chat_message.dart';
import 'package:Memento/plugins/agent_chat/services/message_service.dart';
import 'markdown_content.dart';
import 'tool_call_steps.dart';

/// 链式消息容器组件
///
/// 用于整合和显示同一次链式调用的所有消息，支持 tab 切换
class ChainMessageContainer extends StatefulWidget {
  /// 会话ID
  final String conversationId;

  /// 链式执行ID
  final String chainExecutionId;

  /// 消息服务
  final MessageService messageService;

  /// 获取 Agent 名称的回调
  final String? Function(String agentId)? getAgentName;

  /// 重新执行步骤的回调
  final Future<void> Function(String messageId, int stepIndex)? onRerunStep;

  const ChainMessageContainer({
    super.key,
    required this.conversationId,
    required this.chainExecutionId,
    required this.messageService,
    this.getAgentName,
    this.onRerunStep,
  });

  @override
  State<ChainMessageContainer> createState() => _ChainMessageContainerState();
}

class _ChainMessageContainerState extends State<ChainMessageContainer> {
  /// 当前选中的 tab 索引
  int _selectedTabIndex = 0;

  /// 链式消息列表（不包含最终总结）
  List<ChatMessage> _chainMessages = [];

  /// 最终总结消息
  ChatMessage? _finalSummaryMessage;

  /// 上一次最终总结的生成状态
  bool? _lastSummaryGeneratingState;

  @override
  void initState() {
    super.initState();
    _loadChainMessages();
    // 监听消息变化
    widget.messageService.addListener(_onMessageChanged);
  }

  @override
  void dispose() {
    widget.messageService.removeListener(_onMessageChanged);
    super.dispose();
  }

  /// 监听消息变化
  void _onMessageChanged() {
    _loadChainMessages();
  }

  /// 加载链式消息
  void _loadChainMessages() {
    final allMessages = widget.messageService.getChainMessages(
      widget.conversationId,
      widget.chainExecutionId,
    );

    // 分离常规消息和最终总结消息
    final regularMessages = <ChatMessage>[];
    ChatMessage? summaryMsg;

    for (var msg in allMessages) {
      if (msg.isFinalSummary) {
        summaryMsg = msg;
      } else {
        regularMessages.add(msg);
      }
    }

    setState(() {
      _chainMessages = regularMessages;

      // 检测最终总结状态变化
      final wasGenerating = _lastSummaryGeneratingState;
      final isNowGenerating = summaryMsg?.isGenerating;

      _finalSummaryMessage = summaryMsg;
      _lastSummaryGeneratingState = isNowGenerating;

      // 如果是首次加载且有完成的最终结果，默认选中
      if (wasGenerating == null && summaryMsg != null && !summaryMsg.isGenerating) {
        _selectedTabIndex = regularMessages.length; // 选中最终结果tab
      }
      // 如果最终总结刚刚完成生成，自动切换到该tab
      else if (wasGenerating == true && isNowGenerating == false && summaryMsg != null) {
        _selectedTabIndex = regularMessages.length; // 选中最终结果tab
      }
      // 计算总的tab数量（包括最终结果tab）
      else {
        final totalTabs = regularMessages.length + (summaryMsg != null ? 1 : 0);
        // 确保选中的索引不超出范围
        if (_selectedTabIndex >= totalTabs && totalTabs > 0) {
          _selectedTabIndex = totalTabs - 1;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_chainMessages.isEmpty && _finalSummaryMessage == null) {
      return const SizedBox.shrink();
    }

    // 如果只有一个步骤且没有最终结果，直接显示内容，不显示tab栏
    final shouldShowTabs = _chainMessages.length > 1 || _finalSummaryMessage != null;

    if (!shouldShowTabs) {
      return _buildMessageContent(context, _chainMessages[0]);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tab 栏
        _buildTabBar(context),
        const SizedBox(height: 12),

        // 当前选中的消息内容
        if (_selectedTabIndex < _chainMessages.length)
          _buildMessageContent(context, _chainMessages[_selectedTabIndex])
        else if (_selectedTabIndex == _chainMessages.length &&
            _finalSummaryMessage != null)
          _buildMessageContent(context, _finalSummaryMessage!),
      ],
    );
  }

  /// 构建 Tab 栏
  Widget _buildTabBar(BuildContext context) {
    final tabs = <Widget>[];

    // 添加常规步骤的tabs
    for (int index = 0; index < _chainMessages.length; index++) {
      final message = _chainMessages[index];
      final isSelected = index == _selectedTabIndex;
      final agentName = widget.getAgentName?.call(
            message.generatedByAgentId ?? '',
          ) ??
          'Agent';
      final stepIndex = message.chainStepIndex ?? index;

      tabs.add(
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: _buildTab(
            context: context,
            label: '步骤${stepIndex + 1}: $agentName',
            isSelected: isSelected,
            isGenerating: message.isGenerating,
            hasError: message.content.contains('❌'),
            tokenCount: null, // 常规步骤不显示token
            onTap: () {
              setState(() {
                _selectedTabIndex = index;
              });
            },
          ),
        ),
      );
    }

    // 添加最终结果tab
    if (_finalSummaryMessage != null) {
      final summaryIndex = _chainMessages.length;
      final isSelected = _selectedTabIndex == summaryIndex;

      tabs.add(
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: _buildTab(
            context: context,
            label: '最终结果',
            isSelected: isSelected,
            isGenerating: _finalSummaryMessage!.isGenerating,
            hasError: _finalSummaryMessage!.content.contains('❌'),
            tokenCount: _finalSummaryMessage!.isGenerating
                ? _finalSummaryMessage!.tokenCount
                : null,
            onTap: () {
              setState(() {
                _selectedTabIndex = summaryIndex;
              });
            },
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: tabs),
    );
  }

  /// 构建单个 Tab
  Widget _buildTab({
    required BuildContext context,
    required String label,
    required bool isSelected,
    required bool isGenerating,
    required bool hasError,
    required VoidCallback onTap,
    int? tokenCount, // token计数（仅最终结果tab生成时显示）
  }) {
    Color backgroundColor;
    Color borderColor;
    Color textColor;
    Widget? statusWidget; // 使用Widget替代IconData，支持动画

    if (hasError) {
      backgroundColor = isSelected
          ? Theme.of(context).colorScheme.errorContainer
          : Theme.of(context).colorScheme.errorContainer.withOpacity(0.3);
      borderColor = Theme.of(context).colorScheme.error;
      textColor = Theme.of(context).colorScheme.onErrorContainer;
      statusWidget = Icon(Icons.error_outline, size: 16, color: textColor);
    } else if (isGenerating) {
      backgroundColor = isSelected
          ? Theme.of(context).colorScheme.primaryContainer
          : Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3);
      borderColor = Theme.of(context).colorScheme.primary;
      textColor = Theme.of(context).colorScheme.onPrimaryContainer;
      // 使用旋转动画的加载图标
      statusWidget = SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(textColor),
        ),
      );
    } else {
      backgroundColor = isSelected
          ? Theme.of(context).colorScheme.tertiaryContainer
          : Theme.of(context).colorScheme.tertiaryContainer.withOpacity(0.3);
      borderColor = Theme.of(context).colorScheme.tertiary;
      textColor = Theme.of(context).colorScheme.onTertiaryContainer;
      statusWidget = Icon(Icons.check_circle_outline, size: 16, color: textColor);
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: borderColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (statusWidget != null) ...[
              statusWidget,
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: textColor,
              ),
            ),
            // 显示token计数（仅在生成中且有token时显示）
            if (tokenCount != null && tokenCount > 0) ...[
              const SizedBox(width: 4),
              Text(
                '(~$tokenCount)',
                style: TextStyle(
                  fontSize: 10,
                  color: textColor.withOpacity(0.7),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 构建消息内容
  Widget _buildMessageContent(BuildContext context, ChatMessage message) {
    // 检查是否有工具调用
    final hasToolCall =
        message.toolCall != null && message.toolCall!.steps.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 如果有工具调用，显示工具调用步骤
        if (hasToolCall) ...[
          // 解析并显示 AI 回复（如果有）
          if (_hasAIReply(message.content)) ...[
            MarkdownContent(content: _extractAIReply(message.content)),
            const SizedBox(height: 12),
          ]
          // 如果正在生成且没有回复，显示加载占位符
          else if (message.isGenerating) ...[
            _buildLoadingIndicator(context, 'AI 正在生成回复...'),
            const SizedBox(height: 12),
          ],

          // 显示工具调用步骤
          ToolCallSteps(
            steps: message.toolCall!.steps,
            isGenerating: message.isGenerating,
            onRerunStep: widget.onRerunStep != null
                ? (stepIndex) => widget.onRerunStep!(message.id, stepIndex)
                : null,
          ),
        ]
        // 如果正在生成普通消息
        else if (message.isGenerating)
          _buildLoadingIndicator(context, '正在生成...')
        // 普通消息内容
        else if (message.content.isNotEmpty)
          MarkdownContent(content: message.content)
        else
          Text(
            '(空消息)',
            style: TextStyle(
              fontStyle: FontStyle.italic,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
      ],
    );
  }

  /// 构建加载指示器
  Widget _buildLoadingIndicator(BuildContext context, String text) {
    return Row(
      children: [
        SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontSize: 14,
            fontStyle: FontStyle.italic,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  /// 检查是否有 AI 最终回复
  bool _hasAIReply(String content) {
    return content.contains('[AI最终回复]');
  }

  /// 提取 AI 最终回复
  String _extractAIReply(String content) {
    final finalReplyIndex = content.indexOf('[AI最终回复]');
    if (finalReplyIndex != -1) {
      final replyStart = finalReplyIndex + '[AI最终回复]'.length;
      return content.substring(replyStart).trim();
    }
    return '';
  }
}
