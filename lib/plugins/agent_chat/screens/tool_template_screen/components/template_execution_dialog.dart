import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import 'package:Memento/plugins/agent_chat/models/tool_call_step.dart';
import 'package:Memento/plugins/agent_chat/services/tool_service.dart';
import 'package:Memento/core/js_bridge/js_bridge_manager.dart';
import 'package:Memento/core/services/toast_service.dart';
import 'package:Memento/plugins/agent_chat/l10n/agent_chat_localizations.dart';

const _uuid = Uuid();

/// 工具模板执行对话框
///
/// 执行模板的所有步骤并显示结果
class TemplateExecutionDialog extends StatefulWidget {
  final String templateName;
  final List<ToolCallStep> steps;

  const TemplateExecutionDialog({
    super.key,
    required this.templateName,
    required this.steps,
  });

  @override
  State<TemplateExecutionDialog> createState() =>
      _TemplateExecutionDialogState();
}

class _TemplateExecutionDialogState extends State<TemplateExecutionDialog> {
  bool _isExecuting = false;
  bool _isCompleted = false;
  int _currentStepIndex = -1;
  final List<Map<String, dynamic>> _results = [];
  int? _expandedStepIndex; // 当前展开的步骤索引

  @override
  void initState() {
    super.initState();
    _executeSteps();
  }

  Future<void> _executeSteps() async {
    setState(() {
      _isExecuting = true;
      _results.clear();
    });

    // 生成唯一的工具调用ID
    final toolCallId = _uuid.v4();

    // 初始化工具调用上下文（用于步骤间结果传递）
    final jsBridge = JSBridgeManager.instance;
    jsBridge.initToolCallContext(toolCallId);

    try {
      for (var i = 0; i < widget.steps.length; i++) {
        if (!mounted) return;

        setState(() {
          _currentStepIndex = i;
          widget.steps[i].status = ToolCallStatus.running;
        });

        final step = widget.steps[i];

        try {
          // 设置当前执行上下文（供 JavaScript 中的 setResult/getResult 使用）
          jsBridge.setCurrentExecution(toolCallId, i);

          final result = await ToolService.executeToolStep(step);

          // 自动将步骤结果保存到上下文（供后续步骤通过索引获取）
          jsBridge.setToolCallResult('step_$i', result);

          if (!mounted) return;

          setState(() {
            widget.steps[i].status = ToolCallStatus.success;
            widget.steps[i].result = result;
            _results.add({
              'stepIndex': i,
              'title': step.title,
              'success': true,
              'result': result,
            });
            _expandedStepIndex = i; // 自动展开最后完成的步骤
          });
        } catch (e) {
          if (!mounted) return;

          setState(() {
            widget.steps[i].status = ToolCallStatus.failed;
            widget.steps[i].error = e.toString();
            _results.add({
              'stepIndex': i,
              'title': step.title,
              'success': false,
              'error': e.toString(),
            });
            _expandedStepIndex = i; // 自动展开最后完成的步骤（包括失败的）
          });
          // 步骤失败后继续执行后续步骤（测试模式下）
        }
      }

      if (mounted) {
        setState(() {
          _isExecuting = false;
          _isCompleted = true;
          _currentStepIndex = -1;
        });
      }
    } finally {
      // 清除工具调用上下文
      jsBridge.clearToolCallContext(toolCallId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.play_circle_outline, color: Colors.green),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '执行: ${widget.templateName}',
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.6,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 进度指示
            if (_isExecuting) ...[
              LinearProgressIndicator(
                value:
                    _currentStepIndex >= 0
                        ? (_currentStepIndex + 1) / widget.steps.length
                        : null,
              ),
              const SizedBox(height: 8),
              Text(
                '正在执行步骤 ${_currentStepIndex + 1}/${widget.steps.length}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
            ],

            // 步骤列表和结果
            Expanded(
              child: ListView.builder(
                itemCount: widget.steps.length,
                itemBuilder: (context, index) {
                  return _buildStepItem(index);
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        // 复制所有结果
        if (_isCompleted)
          TextButton.icon(
            onPressed: _copyAllResults,
            icon: const Icon(Icons.copy, size: 18),
            label: Text(AgentChatLocalizations.of(context)!.copyResult),
          ),
        // 关闭按钮
        FilledButton(
          onPressed: _isExecuting ? null : () => Navigator.pop(context),
          child: Text(_isCompleted ? '关闭' : '取消'),
        ),
      ],
    );
  }

  /// 构建步骤项
  Widget _buildStepItem(int index) {
    final step = widget.steps[index];
    final result = _results.firstWhere(
      (r) => r['stepIndex'] == index,
      orElse: () => {},
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        key: ValueKey(
          'step_${index}_${_expandedStepIndex == index}',
        ), // 使用key强制重建
        initiallyExpanded: _expandedStepIndex == index, // 仅展开最后完成的步骤
        onExpansionChanged: (expanded) {
          if (expanded) {
            // 用户手动展开时更新状态
            setState(() {
              _expandedStepIndex = index;
            });
          } else if (_expandedStepIndex == index) {
            // 用户手动折叠当前展开的步骤
            setState(() {
              _expandedStepIndex = null;
            });
          }
        },
        leading: _buildStatusIcon(step.status),
        title: Text(
          step.title.isNotEmpty ? step.title : '步骤 ${index + 1}',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          step.desc,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 代码预览
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    step.data,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                    ),
                    maxLines: 5,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // 执行结果
                if (result.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        result['success'] ? Icons.check_circle : Icons.error,
                        size: 16,
                        color: result['success'] ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        result['success'] ? '执行成功' : '执行失败',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: result['success'] ? Colors.green : Colors.red,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => _copyStepResult(index),
                        icon: const Icon(Icons.copy, size: 16),
                        tooltip: '复制结果',
                        iconSize: 16,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color:
                          result['success']
                              ? Colors.green.shade50
                              : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color:
                            result['success']
                                ? Colors.green.shade200
                                : Colors.red.shade200,
                      ),
                    ),
                    child: SelectableText(
                      result['success']
                          ? _formatResult(result['result'])
                          : result['error'],
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        color:
                            result['success']
                                ? Colors.green.shade900
                                : Colors.red.shade900,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建状态图标
  Widget _buildStatusIcon(ToolCallStatus status) {
    switch (status) {
      case ToolCallStatus.pending:
        return const Icon(Icons.pending, color: Colors.grey);
      case ToolCallStatus.running:
        return const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
      case ToolCallStatus.success:
        return const Icon(Icons.check_circle, color: Colors.green);
      case ToolCallStatus.failed:
        return const Icon(Icons.error, color: Colors.red);
    }
  }

  /// 格式化结果
  String _formatResult(String result) {
    try {
      final decoded = jsonDecode(result);
      return const JsonEncoder.withIndent('  ').convert(decoded);
    } catch (e) {
      return result;
    }
  }

  /// 复制单个步骤结果
  void _copyStepResult(int index) {
    final result = _results.firstWhere(
      (r) => r['stepIndex'] == index,
      orElse: () => {},
    );

    if (result.isEmpty) return;

    final text =
        result['success'] ? _formatResult(result['result']) : result['error'];

    Clipboard.setData(ClipboardData(text: text));

    toastService.showToast('已复制到剪贴板');
  }

  /// 复制所有结果
  void _copyAllResults() {
    final buffer = StringBuffer();
    buffer.writeln('执行结果: ${widget.templateName}');
    buffer.writeln('=' * 40);

    for (final result in _results) {
      buffer.writeln();
      buffer.writeln('步骤 ${result['stepIndex'] + 1}: ${result['title']}');
      buffer.writeln('-' * 40);

      if (result['success']) {
        buffer.writeln('状态: 成功');
        buffer.writeln('结果:');
        buffer.writeln(_formatResult(result['result']));
      } else {
        buffer.writeln('状态: 失败');
        buffer.writeln('错误: ${result['error']}');
      }
    }

    Clipboard.setData(ClipboardData(text: buffer.toString()));

    toastService.showToast('已复制所有结果到剪贴板');
  }
}
