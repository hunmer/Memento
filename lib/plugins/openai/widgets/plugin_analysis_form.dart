import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import '../models/plugin_analysis_method.dart';
import '../models/parameter_definition.dart';
import '../l10n/openai_localizations.dart';
import '../openai_plugin.dart';

class PluginAnalysisForm extends StatefulWidget {
  final PluginAnalysisMethod method;
  final Function(String) onConfirm;

  const PluginAnalysisForm({
    super.key,
    required this.method,
    required this.onConfirm,
  });

  @override
  State<PluginAnalysisForm> createState() => _PluginAnalysisFormState();
}

class _PluginAnalysisFormState extends State<PluginAnalysisForm> {
  final Map<String, TextEditingController> _controllers = {};
  late Map<String, dynamic> _currentTemplate;

  @override
  void initState() {
    super.initState();
    // 创建模板的副本
    _currentTemplate = Map<String, dynamic>.from(widget.method.template);

    // 为每个字段创建控制器
    _currentTemplate.forEach((key, value) {
      _controllers[key] = TextEditingController(text: value.toString());
    });
  }

  @override
  void dispose() {
    // 释放所有控制器
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  // 更新模板值
  void _updateTemplateValue(String key, dynamic value) {
    setState(() {
      _currentTemplate[key] = value;
    });
  }

  // 获取当前模板的JSON字符串
  String _getJsonString() {
    return jsonEncode(_currentTemplate);
  }

  // 测试 Prompt 方法并显示结果
  Future<void> _testPromptMethod() async {
    try {
      // 获取方法名
      final methodName = _currentTemplate['method'] as String?;
      if (methodName == null) {
        _showTestResult('错误', '未指定方法名');
        return;
      }

      // 显示加载中对话框
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // 通过 PromptReplacementController 获取注册的方法
      final controller = OpenAIPlugin.instance.getPromptReplacementController();

      // 检查方法是否已注册
      if (!controller.hasMethod(methodName)) {
        if (!mounted) return;
        Navigator.pop(context);
        _showTestResult('错误', '方法 "$methodName" 未注册\n\n请确保对应的插件已初始化');
        return;
      }

      // 直接调用 processPrompt 来执行方法替换
      final jsonStr = _getJsonString();
      final result = await controller.processPrompt(jsonStr);

      // 关闭加载对话框
      if (!mounted) return;
      Navigator.pop(context);

      // 显示结果
      _showTestResult('测试结果', result);
    } catch (e) {
      // 关闭加载对话框
      if (mounted) {
        Navigator.pop(context);
      }
      _showTestResult('错误', e.toString());
    }
  }

  // 显示测试结果对话框
  void _showTestResult(String title, String content) {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              title == '错误' ? Icons.error_outline : Icons.check_circle_outline,
              color: title == '错误' ? Colors.red : Colors.green,
            ),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Container(
          constraints: const BoxConstraints(maxHeight: 500, maxWidth: 600),
          child: SingleChildScrollView(
            child: SelectableText(
              content,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              // 复制到剪贴板
              Clipboard.setData(ClipboardData(text: content));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('已复制到剪贴板')),
              );
            },
            child: const Text('复制'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  // 根据参数类型构建输入控件
  Widget _buildFieldWidget(ParameterDefinition param) {
    switch (param.type) {
      case ParameterType.date:
        return _buildDateField(param);
      case ParameterType.mode:
        return _buildModeField(param);
      case ParameterType.number:
        return _buildNumberField(param);
      case ParameterType.string:
      case ParameterType.array:
        return _buildTextField(param);
    }
  }

  // 构建日期选择器
  Widget _buildDateField(ParameterDefinition param) {
    final controller = _controllers[param.name]!;

    return InkWell(
      onTap: () async {
        // 解析当前日期
        DateTime? initialDate;
        try {
          initialDate = DateTime.parse(controller.text);
        } catch (_) {
          initialDate = DateTime.now();
        }

        // 显示日期选择器
        final picked = await showDatePicker(
          context: context,
          initialDate: initialDate,
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );

        if (picked != null) {
          final dateStr = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
          controller.text = dateStr;
          _updateTemplateValue(param.name, dateStr);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: param.getDisplayLabel(),
          hintText: param.getHint(),
          border: const OutlineInputBorder(),
          suffixIcon: const Icon(Icons.calendar_today),
        ),
        child: Text(
          controller.text,
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }

  // 构建数据模式下拉选择器
  Widget _buildModeField(ParameterDefinition param) {
    final currentValue = _currentTemplate[param.name]?.toString() ?? param.defaultValue?.toString() ?? 'summary';
    final options = param.options ?? ['summary', 'compact', 'full'];

    return DropdownButtonFormField<String>(
      initialValue: currentValue,
      decoration: InputDecoration(
        labelText: param.getDisplayLabel(),
        hintText: param.getHint(),
        border: const OutlineInputBorder(),
      ),
      items: options.map((option) {
        String displayText = option;
        String subtitle = '';

        // 添加中文说明
        switch (option) {
          case 'summary':
            displayText = 'Summary';
            subtitle = '摘要 - 仅统计数据 (~10% token)';
            break;
          case 'compact':
            displayText = 'Compact';
            subtitle = '紧凑 - 简化列表 (~30% token)';
            break;
          case 'full':
            displayText = 'Full';
            subtitle = '完整 - 所有数据 (100% token)';
            break;
        }

        return DropdownMenuItem(
          value: option,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(displayText),
              if (subtitle.isNotEmpty)
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                  ),
                ),
            ],
          ),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          _controllers[param.name]!.text = value;
          _updateTemplateValue(param.name, value);
        }
      },
    );
  }

  // 构建数字输入框
  Widget _buildNumberField(ParameterDefinition param) {
    final controller = _controllers[param.name]!;

    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: param.getDisplayLabel(),
        hintText: param.getHint(),
        border: const OutlineInputBorder(),
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
      ],
      onChanged: (value) {
        final numValue = int.tryParse(value);
        _updateTemplateValue(param.name, numValue ?? value);
      },
    );
  }

  // 构建普通文本输入框
  Widget _buildTextField(ParameterDefinition param) {
    final controller = _controllers[param.name]!;
    final isReadOnly = param.name == 'method'; // method 字段只读

    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: param.getDisplayLabel(),
        hintText: param.getHint(),
        border: const OutlineInputBorder(),
      ),
      readOnly: isReadOnly,
      enabled: !isReadOnly,
      onChanged: (value) {
        _updateTemplateValue(param.name, value);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // 如果有参数定义，使用参数定义；否则使用旧的 template 方式
    final hasParameterDefinitions = widget.method.parameters != null && widget.method.parameters!.isNotEmpty;

    return Dialog(
      child: Container(
        width: 550,
        constraints: const BoxConstraints(maxHeight: 700),
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
                Expanded(
                  child: Text(
                    widget.method.title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            const Divider(),

            // 表单字段
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (hasParameterDefinitions)
                      // 使用参数定义生成表单字段
                      ...widget.method.parameters!.map((param) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _buildFieldWidget(param),
                        );
                      })
                    else
                      // 使用旧的 template 方式（向后兼容）
                      ...widget.method.template.entries.map((entry) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: TextField(
                            controller: _controllers[entry.key],
                            decoration: InputDecoration(
                              labelText: entry.key,
                              border: const OutlineInputBorder(),
                            ),
                            onChanged: (value) {
                              _updateTemplateValue(entry.key, value);
                            },
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ),

            // 底部按钮
            const SizedBox(height: 16),
            Row(
              children: [
                // 测试按钮（左侧）
                OutlinedButton.icon(
                  onPressed: _testPromptMethod,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('测试'),
                ),
                const Spacer(),
                // 取消和确认按钮（右侧）
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(OpenAILocalizations.of(context).cancel),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    widget.onConfirm(_getJsonString());
                  },
                  child: Text(OpenAILocalizations.of(context).confirm),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
