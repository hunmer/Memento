import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../../widgets/circle_icon_picker.dart';
import '../../../widgets/image_picker_dialog.dart';
import '../models/ai_agent.dart';
import '../models/service_provider.dart';
import '../models/llm_models.dart';
import '../controllers/agent_controller.dart';
import '../controllers/provider_controller.dart';
import '../services/test_service.dart';
import 'model_search_screen.dart';

class AgentEditScreen extends StatefulWidget {
  final AIAgent? agent;

  const AgentEditScreen({super.key, this.agent});

  @override
  State<AgentEditScreen> createState() => _AgentEditScreenState();
}

class _AgentEditScreenState extends State<AgentEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _promptController = TextEditingController();
  IconData _selectedIcon = Icons.smart_toy;
  Color _selectedIconColor = Colors.blue;
  String? _avatarUrl;
  final _baseUrlController = TextEditingController();
  final _headersController = TextEditingController();
  final _modelController = TextEditingController();
  String _selectedProviderId = '';
  final List<String> _tags = [];
  final _tagController = TextEditingController();

  List<ServiceProvider> _providers = [];
  bool _isLoadingProviders = true;

  @override
  void initState() {
    super.initState();
    _loadProviders();
    if (widget.agent != null) {
      _nameController.text = widget.agent!.name;
      _descriptionController.text = widget.agent!.description;
      _promptController.text = widget.agent!.systemPrompt;
      _selectedIcon = widget.agent!.icon ?? Icons.smart_toy;
      _selectedIconColor = widget.agent!.iconColor ?? Colors.blue;
      _avatarUrl = widget.agent!.avatarUrl;
      _selectedProviderId = widget.agent!.serviceProviderId;
      _baseUrlController.text = widget.agent!.baseUrl;
      _modelController.text = widget.agent!.model;
      _headersController.text = _formatHeaders(widget.agent!.headers);
      _tags.addAll(widget.agent!.tags);
    }
  }

  Future<void> _loadProviders() async {
    setState(() {
      _isLoadingProviders = true;
    });

    try {
      final providerController = ProviderController();
      _providers = await providerController.getProviders();

      if (_providers.isNotEmpty && _selectedProviderId.isEmpty) {
        _selectedProviderId = _providers.first.id;
        _updateProviderFields(_providers.first);
      } else if (_selectedProviderId.isNotEmpty) {
        final provider = _providers.firstWhere(
          (p) => p.id == _selectedProviderId,
          orElse:
              () =>
                  _providers.isNotEmpty
                      ? _providers.first
                      : ServiceProvider(
                        id: 'default',
                        label: 'Default',
                        baseUrl: '',
                        headers: {},
                      ),
        );
        _selectedProviderId = provider.id;
        if (widget.agent == null) {
          _updateProviderFields(provider);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('加载服务商失败: $e')));
      }
    } finally {
      setState(() {
        _isLoadingProviders = false;
      });
    }
  }

  void _updateProviderFields(ServiceProvider provider) {
    if (widget.agent == null) {
      _baseUrlController.text = provider.baseUrl;
      _headersController.text = _formatHeaders(provider.headers);
    }
  }

  Future<void> _selectModel() async {
    final selectedModel = await Navigator.push<LLMModel>(
      context,
      MaterialPageRoute(
        builder: (context) => ModelSearchScreen(
          initialModelId: _modelController.text,
        ),
      ),
    );

    if (selectedModel != null) {
      setState(() {
        _modelController.text = selectedModel.id;
      });
    }
  }

  String _formatHeaders(Map<String, String> headers) {
    return headers.entries.map((e) => '${e.key}: ${e.value}').join('\n');
  }

  Map<String, String> _parseHeaders(String headersText) {
    final Map<String, String> result = {};
    final lines = headersText.split('\n');

    for (var line in lines) {
      line = line.trim();
      if (line.isEmpty) continue;

      final colonIndex = line.indexOf(':');
      if (colonIndex > 0) {
        final key = line.substring(0, colonIndex).trim();
        final value = line.substring(colonIndex + 1).trim();
        if (key.isNotEmpty) {
          result[key] = value;
        }
      }
    }

    return result;
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
      serviceProviderId: _selectedProviderId,
      baseUrl: _baseUrlController.text,
      headers: _parseHeaders(_headersController.text),
      systemPrompt: _promptController.text,
      model:
          _modelController.text.isEmpty
              ? 'gpt-3.5-turbo'
              : _modelController.text,
      tags: _tags,
      createdAt: widget.agent?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
      icon: _selectedIcon,
      iconColor: _selectedIconColor,
      avatarUrl: _avatarUrl,
    );

    try {
      final controller = AgentController();
      if (widget.agent == null) {
        await controller.addAgent(agent);
      } else {
        await controller.updateAgent(agent);
      }
      if (mounted) {
        // 返回true表示保存成功
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
            Row(
              children: [
                CircleIconPicker(
                  currentIcon: _selectedIcon,
                  backgroundColor: _selectedIconColor,
                  onIconSelected: (icon) {
                    setState(() {
                      _selectedIcon = icon;
                    });
                  },
                  onColorSelected: (color) {
                    setState(() {
                      _selectedIconColor = color;
                    });
                  },
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      final result = await showDialog<Map<String, dynamic>>(
                        context: context,
                        builder: (context) => ImagePickerDialog(
                          initialUrl: _avatarUrl,
                          saveDirectory: 'agent_avatars',
                          enableCrop: true,
                          cropAspectRatio: 1.0,
                        ),
                      );
                      if (result != null) {
                        setState(() {
                          _avatarUrl = result['url'] as String;
                        });
                      }
                    },
                    child: Container(
                      height: 64,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                        ),
                      ),
                      child: _avatarUrl != null && _avatarUrl!.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(7),
                              child: _avatarUrl!.startsWith('http')
                                  ? Image.network(
                                      _avatarUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) =>
                                          const Icon(Icons.broken_image),
                                    )
                                  : Image.file(
                                      File(_avatarUrl!),
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) =>
                                          const Icon(Icons.broken_image),
                                    ),
                            )
                          : const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_photo_alternate_outlined),
                                  Text('添加头像'),
                                ],
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
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
            _isLoadingProviders
                ? const Center(child: CircularProgressIndicator())
                : DropdownButtonFormField<String>(
                  value:
                      _selectedProviderId.isEmpty && _providers.isNotEmpty
                          ? _providers.first.id
                          : _selectedProviderId,
                  decoration: const InputDecoration(labelText: '服务商'),
                  items:
                      _providers.map((provider) {
                        return DropdownMenuItem(
                          value: provider.id,
                          child: Text(provider.label),
                        );
                      }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedProviderId = value;
                        final provider = _providers.firstWhere(
                          (p) => p.id == value,
                        );
                        _updateProviderFields(provider);
                      });
                    }
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '请选择服务商';
                    }
                    return null;
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
            TextFormField(
              controller: _baseUrlController,
              decoration: const InputDecoration(
                labelText: 'Base URL',
                hintText: 'Enter base URL for API calls',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a base URL';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _modelController,
                    decoration: const InputDecoration(
                      labelText: 'Model',
                      hintText: 'Enter model name (e.g. gpt-3.5-turbo)',
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _selectModel,
                  tooltip: '搜索模型',
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _headersController,
              decoration: const InputDecoration(
                labelText: 'Headers',
                hintText: 'Enter headers (one per line, format: key: value)',
              ),
              maxLines: 3,
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

  Future<void> _testAgent() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // 获取当前选中的服务商
    final selectedProvider = _providers.firstWhere(
      (p) => p.id == _selectedProviderId,
      orElse: () => throw Exception('未找到选定的服务商'),
    );

    // 创建临时agent用于测试，使用服务商的最新配置
    final testAgent = AIAgent(
      id: 'test',
      // 如果模型为空，使用 gpt-4-vision-preview 作为默认模型
      model:
          _modelController.text.isEmpty
              ? 'gpt-4-vision-preview'
              : _modelController.text,
      name: _nameController.text,
      description: _descriptionController.text,
      serviceProviderId: selectedProvider.id,
      baseUrl: selectedProvider.baseUrl,
      headers: Map<String, String>.from(selectedProvider.headers),
      systemPrompt: _promptController.text,
      tags: _tags,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // 显示带有图片选择的测试对话框
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return _TestInputDialog(
          title: '测试${testAgent.name}',
          hintText: '请输入测试文本...',
        );
      },
    );

    if (result != null && mounted) {
      final input = result['text'] as String;
      final File? imageFile = result['image'] as File?;

      if (input.isNotEmpty) {
        try {
          // 处理请求并获取响应
          final response = await TestService.processTestRequest(
            input,
            testAgent,
            imageFile: imageFile,
          );

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
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _promptController.dispose();
    _baseUrlController.dispose();
    _headersController.dispose();
    _modelController.dispose();
    _tagController.dispose();
    super.dispose();
  }
}

class _TestInputDialog extends StatefulWidget {
  final String title;
  final String hintText;

  const _TestInputDialog({required this.title, required this.hintText});

  @override
  State<_TestInputDialog> createState() => _TestInputDialogState();
}

class _TestInputDialogState extends State<_TestInputDialog> {
  final TextEditingController _textController = TextEditingController();
  File? _selectedImage;

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );

    if (result != null &&
        result.files.isNotEmpty &&
        result.files.first.path != null) {
      setState(() {
        _selectedImage = File(result.files.first.path!);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _textController,
              decoration: InputDecoration(
                hintText: widget.hintText,
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.image),
                  label: const Text('选择图片'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child:
                      _selectedImage != null
                          ? Text(
                            '已选择: ${_selectedImage!.path.split('/').last}',
                            overflow: TextOverflow.ellipsis,
                          )
                          : const Text('未选择图片'),
                ),
              ],
            ),
            if (_selectedImage != null) ...[
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  _selectedImage!,
                  height: 100,
                  fit: BoxFit.cover,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(
              context,
            ).pop({'text': _textController.text, 'image': _selectedImage});
          },
          child: const Text('发送'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }
}
