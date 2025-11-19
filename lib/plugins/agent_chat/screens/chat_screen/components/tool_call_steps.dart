import 'package:flutter/material.dart';
import '../../../models/tool_call_step.dart';

/// 工具调用步骤展示组件
///
/// 美化显示工具调用的执行步骤
class ToolCallSteps extends StatefulWidget {
  final List<ToolCallStep> steps;
  final bool isGenerating;
  final void Function(int stepIndex)? onRerunStep;

  const ToolCallSteps({
    super.key,
    required this.steps,
    this.isGenerating = false,
    this.onRerunStep,
  });

  @override
  State<ToolCallSteps> createState() => _ToolCallStepsState();
}

class _ToolCallStepsState extends State<ToolCallSteps> {
  // 展开的步骤索引集合
  final Set<int> _expandedSteps = {};

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题栏
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[100],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.construction,
                  size: 20,
                  color: Colors.blue[700],
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '工具调用 (${widget.steps.length} 个步骤)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[900],
                    ),
                  ),
                ),
                if (widget.isGenerating)
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.blue[700],
                    ),
                  ),
              ],
            ),
          ),

          // 步骤列表
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(8),
            itemCount: widget.steps.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final step = widget.steps[index];
              final isExpanded = _expandedSteps.contains(index);

              return _buildStepCard(step, index, isExpanded);
            },
          ),
        ],
      ),
    );
  }

  /// 构建单个步骤卡片
  Widget _buildStepCard(ToolCallStep step, int index, bool isExpanded) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 步骤头部
          InkWell(
            onTap: () {
              setState(() {
                if (isExpanded) {
                  _expandedSteps.remove(index);
                } else {
                  _expandedSteps.add(index);
                }
              });
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // 状态图标
                  _buildStatusIcon(step.status),
                  const SizedBox(width: 8),

                  // 步骤标题
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${index + 1}. ${step.title}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (step.desc.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            step.desc,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                            maxLines: isExpanded ? null : 1,
                            overflow: isExpanded ? null : TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),

                  // 展开/折叠图标
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 20,
                    color: Colors.grey[600],
                  ),
                ],
              ),
            ),
          ),

          // 展开的详细内容
          if (isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 执行方法
                  _buildInfoRow('方法', step.method),
                  const SizedBox(height: 8),

                  // 执行数据
                  if (step.data.isNotEmpty) ...[
                    const Text(
                      '执行代码:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: SelectableText(
                        step.data,
                        style: TextStyle(
                          fontSize: 11,
                          fontFamily: 'monospace',
                          color: Colors.grey[800],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],

                  // 执行结果
                  if (step.result != null) ...[
                    const Text(
                      '执行结果:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.green[200]!),
                      ),
                      child: SelectableText(
                        step.result!,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.green[900],
                        ),
                      ),
                    ),
                  ],

                  // 错误信息
                  if (step.error != null) ...[
                    const Text(
                      '错误信息:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.red[200]!),
                      ),
                      child: SelectableText(
                        step.error!,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.red[900],
                        ),
                      ),
                    ),
                  ],

                  // 重新执行按钮
                  if (!widget.isGenerating && widget.onRerunStep != null) ...[
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => widget.onRerunStep!(index),
                        icon: const Icon(Icons.replay, size: 16),
                        label: const Text('重新执行此步骤'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange[50],
                          foregroundColor: Colors.orange[700],
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                            side: BorderSide(color: Colors.orange[300]!),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 构建状态图标
  Widget _buildStatusIcon(ToolCallStatus status) {
    switch (status) {
      case ToolCallStatus.pending:
        return Icon(
          Icons.radio_button_unchecked,
          size: 20,
          color: Colors.grey[400],
        );
      case ToolCallStatus.running:
        return SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.blue[700],
          ),
        );
      case ToolCallStatus.success:
        return Icon(
          Icons.check_circle,
          size: 20,
          color: Colors.green[600],
        );
      case ToolCallStatus.failed:
        return Icon(
          Icons.error,
          size: 20,
          color: Colors.red[600],
        );
    }
  }

  /// 构建信息行
  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 60,
          child: Text(
            '$label:',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
            ),
          ),
        ),
      ],
    );
  }
}
