import 'package:flutter/material.dart';
import '../models/ai_agent.dart';
import '../controllers/agent_controller.dart';
import '../services/test_service.dart';

class AgentEditScreen extends StatefulWidget {
  final AIAgent? agent;

  const AgentEditScreen({Key? key, this.agent}) : super(key: key);

  @override
  State<AgentEditScreen> createState() => _AgentEditScreenState();
}

class _AgentEditScreenState extends State<AgentEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _promptController = TextEditingController();
  String _selectedType = 'Assistant';
  final List<String> _tags = [];
  final _tagController = TextEditingController();

  final List<String> _agentTypes = [
    'Assistant',
    'Translator',
    'Writer',
    'Analyst',
    'Developer',
    'Custom',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.agent != null) {
      _nameController.text = widget.agent!.name;
      _descriptionController.text = widget.agent!.description;
      _promptController.text = widget.agent!.systemPrompt;
      _selectedType = widget.agent!.type;
      _tags.addAll(widget.agent!.tags);
    }
  }

  void _addTag() {
    final tag = _tagController.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _tagController.clear();
      });
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  Future<void> _saveAgent() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final agent = AIAgent(
      id: widget.agent?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text,
      description: _descriptionController.text,
      type: _selectedType,
      systemPrompt: _promptController.text,
      tags: _tags,
      createdAt: widget.agent?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      final controller = AgentController();
      if (widget.agent == null) {
        await controller.addAgent(agent);
      } else {
        await controller.updateAgent(agent);
      }
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving agent: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.agent == null ? 'Create Agent' : 'Edit Agent'),
        actions: [
          IconButton(icon: const Icon(Icons.save), onPressed: _saveAgent),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'Enter agent name',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedType,
              decoration: const InputDecoration(labelText: 'Type'),
              items:
                  _agentTypes
                      .map(
                        (type) =>
                            DropdownMenuItem(value: type, child: Text(type)),
                      )
                      .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedType = value;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Enter agent description',
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a description';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _promptController,
              decoration: const InputDecoration(
                labelText: 'System Prompt',
                hintText: 'Enter system prompt',
              ),
              maxLines: 5,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a system prompt';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _tagController,
                    decoration: const InputDecoration(
                      labelText: 'Tags',
                      hintText: 'Enter a tag',
                    ),
                  ),
                ),
                IconButton(icon: const Icon(Icons.add), onPressed: _addTag),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children:
                  _tags
                      .map(
                        (tag) => Chip(
                          label: Text(tag),
                          onDeleted: () => _removeTag(tag),
                        ),
                      )
                      .toList(),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _testAgent,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
              child: const Text('测试智能体'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Future<void> _testAgent() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // 创建临时agent用于测试
    final testAgent = AIAgent(
      id: 'test',
      name: _nameController.text,
      description: _descriptionController.text,
      type: _selectedType,
      systemPrompt: _promptController.text,
      tags: _tags,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // 显示长文本输入对话框
    final input = await TestService.showLongTextInputDialog(
      context,
      title: '测试${testAgent.name}',
      hintText: '请输入测试文本...',
    );

    if (input != null && input.isNotEmpty && mounted) {
      try {
        // 处理请求并获取响应
        final response = await TestService.processTestRequest(input, testAgent);

        // 显示响应结果
        if (mounted) {
          TestService.showResponseDialog(context, response);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('测试过程中出错: $e')));
        }
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _promptController.dispose();
    _tagController.dispose();
    super.dispose();
  }
}
