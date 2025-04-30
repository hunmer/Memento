import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/plugin_analysis_method.dart';
import '../services/plugin_analysis_service.dart';
import 'agent_list_drawer.dart';
import '../models/ai_agent.dart';
import '../controllers/agent_controller.dart';

class PluginAnalysisForm extends StatefulWidget {
  final PluginAnalysisMethod method;

  const PluginAnalysisForm({
    Key? key,
    required this.method,
  }) : super(key: key);

  @override
  State<PluginAnalysisForm> createState() => _PluginAnalysisFormState();
}

class _PluginAnalysisFormState extends State<PluginAnalysisForm> {
  final Map<String, TextEditingController> _controllers = {};
  final PluginAnalysisService _service = PluginAnalysisService();
  String? _responseMessage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // 为每个字段创建控制器
    widget.method.template.forEach((key, value) {
      _controllers[key] = TextEditingController(text: value.toString());
    });
  }

  @override
  void dispose() {
    // 释放所有控制器
    _controllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

  // 复制JSON到剪贴板
  Future<void> _copyToClipboard() async {
    final json = widget.method.formattedJson;
    final success = await _service.copyToClipboard(json);
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已复制到剪贴板')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('复制失败')),
      );
    }
  }

  // 打开智能体选择抽屉
  void _openAgentSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AgentListDrawer(
        selectedAgents: const [],
        onAgentSelected: (selectedAgents) {
          if (selectedAgents.isNotEmpty) {
            _sendToAgent(selectedAgents.first);
          }
        },
        allowMultipleSelection: false,
        title: '选择智能体',
        confirmButtonText: '选择',
      ),
    );
  }

  // 发送到智能体
  Future<void> _sendToAgent(Map<String, String> agentData) async {
    setState(() {
      _isLoading = true;
      _responseMessage = null;
    });

    try {
      // 从 AgentController 获取智能体
      final agentController = AgentController();
      final agent = await agentController.getAgent(agentData['id'] ?? '');
      
      if (agent == null) {
        throw Exception('未找到智能体');
      }

      // 发送消息
      final response = await _service.sendToAgent(
        agent, 
        widget.method.formattedJson,
      );

      setState(() {
        _responseMessage = response;
      });
    } catch (e) {
      setState(() {
        _responseMessage = '发送失败: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题
            Row(
              children: [
                const Icon(Icons.analytics),
                const SizedBox(width: 8),
                Text(
                  '插件分析: ${widget.method.name}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const Divider(),
            
            // 表单字段
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 动态生成表单字段
                    ...widget.method.template.entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: TextField(
                          controller: _controllers[entry.key],
                          decoration: InputDecoration(
                            labelText: entry.key,
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      );
                    }).toList(),
                    
                    // 显示JSON预览
                    const Text(
                      'JSON预览:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        widget.method.formattedJson,
                        style: const TextStyle(fontFamily: 'monospace'),
                      ),
                    ),
                    
                    // 智能体响应
                    if (_responseMessage != null || _isLoading) ...[
                      const SizedBox(height: 16),
                      const Text(
                        '智能体响应:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      if (_isLoading)
                        const Center(child: CircularProgressIndicator())
                      else
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(_responseMessage!),
                        ),
                    ],
                  ],
                ),
              ),
            ),
            
            // 底部按钮
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('关闭'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _copyToClipboard,
                  icon: const Icon(Icons.copy),
                  label: const Text('复制'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _openAgentSelector,
                  icon: const Icon(Icons.smart_toy),
                  label: const Text('选择智能体'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}