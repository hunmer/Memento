import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import '../models/plugin_analysis_method.dart';
import '../services/plugin_analysis_service.dart';
import 'agent_list_drawer.dart';
import '../models/ai_agent.dart';
import '../controllers/agent_controller.dart';

class PluginAnalysisForm extends StatefulWidget {
  final PluginAnalysisMethod method;
  final Function(String) onConfirm;

  const PluginAnalysisForm({
    Key? key,
    required this.method,
    required this.onConfirm,
  }) : super(key: key);

  @override
  State<PluginAnalysisForm> createState() => _PluginAnalysisFormState();
}

class _PluginAnalysisFormState extends State<PluginAnalysisForm> {
  final Map<String, TextEditingController> _controllers = {};
  final PluginAnalysisService _service = PluginAnalysisService();
  late Map<String, dynamic> _currentTemplate;

  @override
  void initState() {
    super.initState();
    // 创建模板的副本
    _currentTemplate = Map<String, dynamic>.from(widget.method.template);
    
    // 为每个字段创建控制器并添加监听器
    _currentTemplate.forEach((key, value) {
      final controller = TextEditingController(text: value.toString());
      controller.addListener(() {
        _updateTemplateValue(key, controller.text);
      });
      _controllers[key] = controller;
    });
  }
  
  // 更新模板值
  void _updateTemplateValue(String key, String value) {
    setState(() {
      // 尝试转换为数字，如果失败则保持为字符串
      if (int.tryParse(value) != null) {
        _currentTemplate[key] = int.parse(value);
      } else if (double.tryParse(value) != null) {
        _currentTemplate[key] = double.parse(value);
      } else {
        _currentTemplate[key] = value;
      }
    });
  }

  @override
  void dispose() {
    // 释放所有控制器
    _controllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

  // 获取当前模板的JSON字符串
  String _getJsonString() {
    return jsonEncode(_currentTemplate);
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
                    
                    
                    // 底部按钮
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('取消'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    widget.onConfirm(_getJsonString());
                  },
                  child: const Text('确定'),
                ),
              ],
            ),
          ],
        ),
      )
            ),
          ]
        ),
      )
    );
  }
}