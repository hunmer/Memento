import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:Memento/plugins/agent_chat/models/tool_call_step.dart';
import 'package:Memento/plugins/agent_chat/services/message_detail_service.dart';
import 'markdown_content.dart';
import 'tool_call_steps.dart';
import 'package:Memento/core/services/toast_service.dart';

/// 工具调用详情对话框
///
/// 展示工具调用消息的完整详细信息，包括：
/// - 用户输入
/// - 思考过程
/// - 工具调用详情
/// - AI最终回复
class ToolDetailDialog extends StatefulWidget {
  final MessageDetail detail;
  final List<ToolCallStep>? toolCallSteps;

  const ToolDetailDialog({super.key, required this.detail, this.toolCallSteps});

  @override
  State<ToolDetailDialog> createState() => _ToolDetailDialogState();
}

class _ToolDetailDialogState extends State<ToolDetailDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.85,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 标题栏
            Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  '工具调用详情',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Tab栏
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: TabBar(
                controller: _tabController,
                labelColor: Colors.blue[700],
                unselectedLabelColor: Colors.grey[600],
                indicator: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                tabs: const [
                  Tab(text: 'AI输入'),
                  Tab(text: '思考过程'),
                  Tab(text: '工具调用'),
                  Tab(text: '最终回复'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Tab内容
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildUserPromptTab(),
                  _buildThinkingTab(),
                  _buildToolCallTab(),
                  _buildFinalReplyTab(),
                ],
              ),
            ),

            // 底部按钮
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(AgentChatLocalizations.of(context)!.close),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// AI输入Tab
  Widget _buildUserPromptTab() {
    return _buildContentTab(
      content: widget.detail.userPrompt,
      icon: Icons.input,
      emptyText: '无AI输入数据',
    );
  }

  /// 思考过程Tab
  Widget _buildThinkingTab() {
    return _buildContentTab(
      content: widget.detail.thinkingProcess,
      icon: Icons.psychology,
      emptyText: '无思考过程',
    );
  }

  /// 工具调用Tab
  Widget _buildToolCallTab() {
    if (widget.toolCallSteps == null || widget.toolCallSteps!.isEmpty) {
      return _buildEmptyState(Icons.construction, '无工具调用');
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 复制按钮
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: const Icon(Icons.copy, size: 18),
                tooltip: '复制工具调用数据',
                onPressed:
                    () => _copyToClipboard(
                      widget.detail.toolCallData.toString(),
                      '工具调用数据',
                    ),
              ),
            ),
            // 工具调用步骤
            ToolCallSteps(steps: widget.toolCallSteps!, isGenerating: false),
          ],
        ),
      ),
    );
  }

  /// 最终回复Tab
  Widget _buildFinalReplyTab() {
    return _buildContentTab(
      content: widget.detail.finalReply,
      icon: Icons.chat_bubble_outline,
      emptyText: '无最终回复',
    );
  }

  /// 通用内容Tab构建器
  Widget _buildContentTab({
    required String content,
    required IconData icon,
    required String emptyText,
  }) {
    if (content.trim().isEmpty) {
      return _buildEmptyState(icon, emptyText);
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // 复制按钮
          Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: IconButton(
                icon: const Icon(Icons.copy, size: 18),
                tooltip: '复制内容',
                onPressed: () => _copyToClipboard(content, '内容'),
              ),
            ),
          ),
          // 内容
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: MarkdownContent(content: content),
            ),
          ),
        ],
      ),
    );
  }

  /// 空状态展示
  Widget _buildEmptyState(IconData icon, String text) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(text, style: TextStyle(fontSize: 16, color: Colors.grey[600])),
        ],
      ),
    );
  }

  /// 复制到剪贴板
  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    toastService.showToast('$label已复制到剪贴板');
  }
}
