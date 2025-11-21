import 'dart:io';
import 'package:Memento/plugins/agent_chat/models/tool_call_step.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../models/chat_message.dart';
import '../../../models/file_attachment.dart';
import '../../../services/token_counter_service.dart';
import '../../../services/message_detail_service.dart';
import '../../../../../core/storage/storage_manager.dart';
import '../../../../../widgets/file_preview/file_preview_screen.dart';
import 'markdown_content.dart';
import 'tool_detail_dialog.dart';
import 'tool_call_steps.dart';
import 'package:timeago/timeago.dart' as timeago;

/// 消息气泡组件
///
/// 极简设计，显示单条消息
class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final Future<void> Function(String messageId, String newContent)? onEdit;
  final Future<void> Function(String messageId)? onDelete;
  final Future<void> Function(String messageId)? onRegenerate;
  final Future<void> Function(ChatMessage message)? onSaveTool;
  final Future<void> Function(String messageId)? onRerunTool;
  final Future<void> Function(String messageId, int stepIndex)? onRerunStep;
  final Future<void> Function(String messageId, String templateId)?
  onExecuteTemplate; // 执行匹配的模版
  final String? Function(String templateId)? getTemplateName; // 获取模版名称
  final VoidCallback? onCancel; // 取消生成的回调
  final bool hasAgent;
  final StorageManager? storage;

  const MessageBubble({
    super.key,
    required this.message,
    this.onEdit,
    this.onDelete,
    this.onRegenerate,
    this.onSaveTool,
    this.onRerunTool,
    this.onRerunStep,
    this.onExecuteTemplate,
    this.getTemplateName,
    this.onCancel,
    this.hasAgent = true,
    this.storage,
  });

  @override
  Widget build(BuildContext context) {
    // 如果是会话分隔符，显示特殊样式
    if (message.isSessionDivider) {
      return _buildSessionDivider();
    }

    final isUser = message.isUser;
    final isToolCallMessage =
        message.toolCall != null && message.toolCall!.steps.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          // 消息内容
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                // 消息气泡
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isUser ? Colors.blue[50] : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 消息内容
                      if (message.isGenerating)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.blue[700],
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              '正在生成...',
                              style: TextStyle(
                                fontStyle: FontStyle.italic,
                                color: Colors.grey,
                              ),
                            ),
                            // 取消按钮
                            if (onCancel != null) ...[
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.cancel, size: 20),
                                color: Colors.red[400],
                                tooltip: '取消生成',
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 32,
                                  minHeight: 32,
                                ),
                                onPressed: onCancel,
                              ),
                            ],
                          ],
                        )
                      else if (message.matchedTemplateIds != null &&
                          message.matchedTemplateIds!.isNotEmpty)
                        // 显示模版选择按钮
                        _buildTemplateSelectionUI()
                      else if (isToolCallMessage)
                        // 如果是工具调用消息,显示工具调用步骤
                        _buildToolCallContent()
                      else
                        _buildMessageContent(),

                      // 附件显示
                      if (message.attachments.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _buildAttachments(),
                      ],
                    ],
                  ),
                ),

                // 底部信息栏
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Token统计
                    Text(
                      TokenCounterService.formatTokenCountShort(
                        message.tokenCount,
                      ),
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),

                    const SizedBox(width: 8),

                    // 时间
                    Text(
                      _formatTime(message.timestamp),
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),

                    // 已编辑标记
                    if (message.editedAt != null) ...[
                      const SizedBox(width: 4),
                      Text(
                        '(已编辑)',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[500],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],

                    // 操作按钮
                    if (!message.isGenerating) ...[
                      const SizedBox(width: 8),
                      _buildActionMenu(context),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建会话分隔符
  Widget _buildSessionDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          Expanded(child: Divider(color: Colors.blue[300], thickness: 1)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.fiber_new, size: 16, color: Colors.blue[700]),
                  const SizedBox(width: 6),
                  Text(
                    message.content,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(child: Divider(color: Colors.blue[300], thickness: 1)),
        ],
      ),
    );
  }

  /// 构建工具调用内容
  Widget _buildToolCallContent() {
    // 如果有工具调用,显示steps组件
    if (message.toolCall != null && message.toolCall!.steps.isNotEmpty) {
      // 智能解析content，提取思考内容和AI回复
      final parsedContent = _parseToolCallContent(message.content);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 显示思考内容
          if (parsedContent['thinking']?.isNotEmpty ?? false) ...[
            MarkdownContent(content: parsedContent['thinking']!),
            const SizedBox(height: 8),
          ],

          // 显示工具调用步骤
          ToolCallSteps(
            steps: message.toolCall!.steps,
            isGenerating: message.isGenerating,
            onRerunStep:
                onRerunStep != null
                    ? (stepIndex) => onRerunStep!(message.id, stepIndex)
                    : null,
          ),

          // 显示AI最终回复
          if (parsedContent['finalReply']?.isNotEmpty ?? false) ...[
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 8),
            MarkdownContent(content: parsedContent['finalReply']!),
          ],
        ],
      );
    }

    // 降级到普通文本显示
    return MarkdownContent(content: message.content);
  }

  /// 解析工具调用消息的content
  /// 返回: {'thinking': '...', 'finalReply': '...'}
  Map<String, String> _parseToolCallContent(String content) {
    final result = <String, String>{};

    // 查找工具执行结果的位置
    final toolResultIndex = content.indexOf('[工具执行结果]');
    final finalReplyIndex = content.indexOf('[AI最终回复]');

    if (toolResultIndex != -1) {
      // 提取思考内容（工具执行结果之前的内容）
      final thinkingRaw = content.substring(0, toolResultIndex);
      result['thinking'] = _stripToolJsonBlocks(thinkingRaw).trim();

      if (finalReplyIndex != -1) {
        // 提取AI最终回复
        final replyStart = finalReplyIndex + '[AI最终回复]'.length;
        result['finalReply'] = content.substring(replyStart).trim();
      }
    } else {
      // 没有工具结果标记，全部作为思考内容
      result['thinking'] = _stripToolJsonBlocks(content).trim();
    }

    return result;
  }

  /// 移除工具调用返回的JSON代码块，避免在思考区域显示
  String _stripToolJsonBlocks(String content) {
    var cleaned = content;
    cleaned = cleaned.replaceAll(
      RegExp(r'```json[\s\S]*?```', multiLine: true),
      '',
    );
    cleaned = cleaned.replaceAll(
      RegExp(r'\{\s*"steps"\s*:\s*\[[\s\S]*?\]\s*\}', multiLine: true),
      '',
    );
    return cleaned;
  }

  /// 构建附件显示
  Widget _buildAttachments() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children:
          message.attachments.map((attachment) {
            // 图片附件显示缩略图
            if (attachment.isImage) {
              return _buildImageAttachment(attachment);
            }

            // 非图片附件显示文件信息
            return _buildFileAttachment(attachment);
          }).toList(),
    );
  }

  /// 构建图片附件
  Widget _buildImageAttachment(FileAttachment attachment) {
    return Builder(
      builder:
          (context) => GestureDetector(
            onTap: () => _viewImage(context, attachment),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                constraints: const BoxConstraints(
                  maxWidth: 200,
                  maxHeight: 200,
                ),
                child: Image.file(
                  File(attachment.filePath),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 200,
                      height: 150,
                      color: Colors.grey[300],
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.broken_image,
                            size: 48,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '图片加载失败',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
    );
  }

  /// 构建文件附件
  Widget _buildFileAttachment(FileAttachment attachment) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.description, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Text(attachment.fileName, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text(
            attachment.formattedSize,
            style: TextStyle(fontSize: 10, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  /// 查看图片大图
  void _viewImage(BuildContext context, FileAttachment attachment) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) => FilePreviewScreen(
              filePath: attachment.filePath,
              fileName: attachment.fileName,
              mimeType: 'image/${_getImageExtension(attachment.fileName)}',
              fileSize: attachment.fileSize,
            ),
      ),
    );
  }

  /// 获取图片扩展名
  String _getImageExtension(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    return ext.isNotEmpty ? ext : 'jpg';
  }

  /// 构建操作菜单
  Widget _buildActionMenu(BuildContext context) {
    final isToolCallMessage =
        message.toolCall != null && message.toolCall!.steps.isNotEmpty;

    return PopupMenuButton<String>(
      padding: EdgeInsets.zero,
      icon: Icon(Icons.more_vert, size: 16, color: Colors.grey[600]),
      onSelected: (value) {
        switch (value) {
          case 'copy':
            Clipboard.setData(ClipboardData(text: message.content));
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('已复制到剪贴板')));
            break;
          case 'edit':
            _showEditDialog(context);
            break;
          case 'delete':
            onDelete?.call(message.id);
            break;
          case 'regenerate':
            onRegenerate?.call(message.id);
            break;
          case 'save_tool':
            onSaveTool?.call(message);
            break;
          case 'rerun_tool':
            onRerunTool?.call(message.id);
            break;
          case 'view_details':
            _showToolDetailDialog(context);
            break;
        }
      },
      itemBuilder:
          (context) => [
            const PopupMenuItem(
              value: 'copy',
              child: Row(
                children: [
                  Icon(Icons.copy, size: 18),
                  SizedBox(width: 8),
                  Text('复制'),
                ],
              ),
            ),
            // 允许编辑所有消息（除了工具调用消息）
            if (onEdit != null && !isToolCallMessage)
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 18),
                    SizedBox(width: 8),
                    Text('编辑'),
                  ],
                ),
              ),
            if (!message.isUser && onRegenerate != null && hasAgent)
              const PopupMenuItem(
                value: 'regenerate',
                child: Row(
                  children: [
                    Icon(Icons.refresh, size: 18),
                    SizedBox(width: 8),
                    Text('重新生成'),
                  ],
                ),
              ),
            if (!message.isUser && isToolCallMessage && onSaveTool != null)
              const PopupMenuItem(
                value: 'save_tool',
                child: Row(
                  children: [
                    Icon(Icons.save, size: 18, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('保存工具', style: TextStyle(color: Colors.blue)),
                  ],
                ),
              ),
            if (!message.isUser && isToolCallMessage && onRerunTool != null)
              const PopupMenuItem(
                value: 'rerun_tool',
                child: Row(
                  children: [
                    Icon(Icons.replay, size: 18, color: Colors.orange),
                    SizedBox(width: 8),
                    Text('重新执行工具', style: TextStyle(color: Colors.orange)),
                  ],
                ),
              ),
            if (!message.isUser && isToolCallMessage && storage != null)
              const PopupMenuItem(
                value: 'view_details',
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 18, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('查看详情', style: TextStyle(color: Colors.blue)),
                  ],
                ),
              ),
            if (onDelete != null)
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 18, color: Colors.red),
                    SizedBox(width: 8),
                    Text('删除', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
          ],
    );
  }

  /// 显示编辑对话框
  void _showEditDialog(BuildContext context) {
    final textController = TextEditingController(text: message.content);

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                const Text('编辑消息'),
                const SizedBox(width: 8),
                if (!message.isUser)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange[100],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'AI',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange[800],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            content: SizedBox(
              width: MediaQuery.of(context).size.width * 0.8,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: textController,
                    maxLines: null,
                    minLines: 5,
                    keyboardType: TextInputType.multiline,
                    decoration: const InputDecoration(
                      hintText: '输入消息内容...',
                      border: OutlineInputBorder(),
                      filled: true,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '${textController.text.length} 字符',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () {
                  final newContent = textController.text.trim();
                  if (newContent.isNotEmpty && newContent != message.content) {
                    onEdit?.call(message.id, newContent);
                  }
                  Navigator.pop(context);
                },
                child: const Text('保存'),
              ),
            ],
          ),
    );
  }

  /// 显示工具调用详情对话框
  Future<void> _showToolDetailDialog(BuildContext context) async {
    if (storage == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('无法加载详情数据')));
      return;
    }

    // 显示加载指示器
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // 加载消息详细数据
      final detailService = MessageDetailService(storage: storage!);
      final detail = await detailService.loadDetail(message.id);

      // 关闭加载指示器
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      if (detail == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('未找到详细数据，可能此消息是在更新前创建的')),
          );
        }
        return;
      }

      // 显示详情对话框
      if (context.mounted) {
        showDialog(
          context: context,
          builder:
              (context) => ToolDetailDialog(
                detail: detail,
                toolCallSteps: message.toolCall?.steps,
              ),
        );
      }
    } catch (e) {
      // 关闭加载指示器
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('加载详情失败: $e')));
      }
    }
  }

  /// 构建模版选择UI
  Widget _buildTemplateSelectionUI() {
    // 检查模版是否已运行（通过检查是否有工具调用记录）
    final hasToolCall =
        message.toolCall != null && message.toolCall!.steps.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 模版卡片列表
        ...message.matchedTemplateIds!.map((templateId) {
          // 获取模版名称
          final templateName = getTemplateName?.call(templateId) ?? '未知模版';
          // 判断当前模版是否已运行
          // 只要有 toolCall，就说明已经执行了
          final isExecuted = hasToolCall;

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 模版卡片
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isExecuted ? Colors.green[50] : Colors.blue[50],
                    border: Border.all(
                      color:
                          isExecuted ? Colors.green[300]! : Colors.blue[300]!,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      // 左侧：图标
                      Icon(
                        isExecuted
                            ? Icons.check_circle_outline
                            : Icons.play_circle_outline,
                        size: 24,
                        color:
                            isExecuted ? Colors.green[700] : Colors.blue[700],
                      ),
                      const SizedBox(width: 12),

                      // 中间：模版信息
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              templateName,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color:
                                    isExecuted
                                        ? Colors.green[900]
                                        : Colors.blue[900],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isExecuted ? '已运行' : '待运行',
                              style: TextStyle(
                                fontSize: 12,
                                color:
                                    isExecuted
                                        ? Colors.green[600]
                                        : Colors.orange[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // 右侧：操作按钮
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // 查看结果按钮（仅已运行时显示）
                          if (isExecuted) ...[
                            Builder(
                              builder:
                                  (context) => IconButton(
                                    icon: Icon(
                                      Icons.visibility_outlined,
                                      size: 20,
                                    ),
                                    color: Colors.green[700],
                                    tooltip: '查看结果',
                                    onPressed:
                                        () =>
                                            _showTemplateResultDialog(context),
                                  ),
                            ),
                            const SizedBox(width: 4),
                          ],

                          // 运行/重新运行按钮
                          ElevatedButton.icon(
                            onPressed:
                                onExecuteTemplate != null
                                    ? () => onExecuteTemplate!(
                                      message.id,
                                      templateId,
                                    )
                                    : null,
                            icon: Icon(
                              isExecuted ? Icons.replay : Icons.play_arrow,
                              size: 16,
                            ),
                            label: Text(isExecuted ? '重新运行' : '运行'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  isExecuted
                                      ? Colors.green[600]
                                      : Colors.blue[600],
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              textStyle: const TextStyle(fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // 分割线（如果有 AI 回复内容）
                if (message.content.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Divider(color: Colors.grey[300], thickness: 1),
                  const SizedBox(height: 12),
                ],

                // AI 最终回复（从 content 中提取，排除工具结果部分）
                if (message.content.isNotEmpty) _buildFinalReplyContent(),
              ],
            ),
          );
        }),
      ],
    );
  }

  /// 构建 AI 最终回复内容（排除工具执行结果部分）
  Widget _buildFinalReplyContent() {
    String content = message.content;

    // 支持多种格式的工具结果分隔符
    final markers = ['[工具执行结果]', '工具执行结果:', '工具执行结果：'];

    int toolResultIndex = -1;
    for (var marker in markers) {
      final index = content.indexOf(marker);
      if (index != -1) {
        toolResultIndex = index;
        break;
      }
    }

    // 没有找到工具结果标记，直接显示内容
    if (toolResultIndex == -1) {
      return MarkdownContent(content: content);
    }

    // 找到工具结果后面的内容
    final afterToolResult = content.substring(toolResultIndex);

    // 查找结束标记（如 "请根据以上工具执行结果直接回答用户的问题" 后的内容）
    final promptEndMarkers = [
      '请根据以上工具执行结果直接回答用户的问题，不要再次调用工具。',
      '请根据以上工具执行结果直接回答用户的问题',
    ];

    int finalReplyStart = -1;

    // 首先尝试查找 [AI最终回复] 标记
    final aiReplyIndex = content.indexOf('[AI最终回复]');
    if (aiReplyIndex != -1) {
      finalReplyStart = aiReplyIndex + '[AI最终回复]'.length;
    } else {
      // 尝试查找提示词结束标记后的内容
      for (var marker in promptEndMarkers) {
        final index = afterToolResult.indexOf(marker);
        if (index != -1) {
          finalReplyStart = toolResultIndex + index + marker.length;
          break;
        }
      }
    }

    if (finalReplyStart != -1) {
      // 找到了最终回复的开始位置
      final finalReply = content.substring(finalReplyStart).trim();

      if (finalReply.isEmpty) {
        // 最终回复为空，显示加载状态
        return _buildToolLoadingState();
      } else {
        // 显示最终回复
        return MarkdownContent(content: finalReply);
      }
    } else {
      // 没有找到最终回复，说明还在执行中，显示加载状态
      return _buildToolLoadingState();
    }
  }

  /// 构建工具执行时的加载状态
  Widget _buildToolLoadingState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.blue[700],
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'AI正在构建答案...',
              style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  /// 显示模版结果对话框
  void _showTemplateResultDialog(BuildContext context) {
    // 获取工具调用结果
    if (message.toolCall == null || message.toolCall!.steps.isEmpty) {
      return;
    }

    showDialog(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: Row(
              children: [
                Icon(
                  Icons.assessment_outlined,
                  color: Colors.blue[700],
                  size: 24,
                ),
                const SizedBox(width: 8),
                const Text('工具执行结果'),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: message.toolCall!.steps.length,
                separatorBuilder: (context, index) => const Divider(height: 24),
                itemBuilder: (context, index) {
                  final step = message.toolCall!.steps[index];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 步骤标题
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue[100],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '步骤 ${index + 1}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[700],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              step.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ],
                      ),

                      // 步骤描述
                      if (step.desc.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          step.desc,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],

                      // 执行结果
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color:
                              step.status == ToolCallStatus.success
                                  ? Colors.green[50]
                                  : step.status == ToolCallStatus.failed
                                  ? Colors.red[50]
                                  : Colors.grey[100],
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color:
                                step.status == ToolCallStatus.success
                                    ? Colors.green[300]!
                                    : step.status == ToolCallStatus.failed
                                    ? Colors.red[300]!
                                    : Colors.grey[300]!,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  step.status == ToolCallStatus.success
                                      ? Icons.check_circle
                                      : step.status == ToolCallStatus.failed
                                      ? Icons.error
                                      : Icons.hourglass_empty,
                                  size: 16,
                                  color:
                                      step.status == ToolCallStatus.success
                                          ? Colors.green[700]
                                          : step.status == ToolCallStatus.failed
                                          ? Colors.red[700]
                                          : Colors.grey[600],
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  step.status == ToolCallStatus.success
                                      ? '执行成功'
                                      : step.status == ToolCallStatus.failed
                                      ? '执行失败'
                                      : '执行中',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        step.status == ToolCallStatus.success
                                            ? Colors.green[700]
                                            : step.status ==
                                                ToolCallStatus.failed
                                            ? Colors.red[700]
                                            : Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                            if (step.result != null || step.error != null) ...[
                              const SizedBox(height: 8),
                              const Divider(height: 1),
                              const SizedBox(height: 8),
                              SelectableText(
                                step.error ?? step.result ?? '无结果',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('关闭'),
              ),
            ],
          ),
    );
  }

  /// 构建消息内容（处理工具模板和普通文本）
  Widget _buildMessageContent() {
    // 检查是否有工具模板信息（用户消息）
    final toolTemplate = message.metadata?['toolTemplate'] as Map<String, dynamic>?;
    final hasToolTemplate = toolTemplate != null;
    final hasContent = message.content.isNotEmpty;

    // 如果既没有内容也没有工具模板，显示空消息提示
    if (!hasContent && !hasToolTemplate) {
      return const Text(
        '(空消息)',
        style: TextStyle(
          fontStyle: FontStyle.italic,
          color: Colors.grey,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 显示工具模板（如果有）
        if (hasToolTemplate) ...[
          _buildUserToolTemplate(toolTemplate),
          // 如果同时有文本内容，添加分隔
          if (hasContent) ...[
            const SizedBox(height: 8),
            Divider(color: Colors.grey[300], thickness: 1),
            const SizedBox(height: 8),
          ],
        ],
        // 显示文本内容（如果有）
        if (hasContent) MarkdownContent(content: message.content),
      ],
    );
  }

  /// 构建用户选择的工具模板显示
  Widget _buildUserToolTemplate(Map<String, dynamic> toolTemplate) {
    final name = toolTemplate['name'] as String? ?? '未知模板';
    final description = toolTemplate['description'] as String?;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.build_circle, size: 18, color: Colors.orange[700]),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '工具模板:',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.orange[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange[900],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (description != null && description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange[700],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 格式化时间
  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return '刚刚';
    } else if (difference.inHours < 24) {
      return timeago.format(dateTime, locale: 'zh');
    } else {
      return '${dateTime.month}/${dateTime.day} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }
}
