import 'dart:io';
import 'package:flutter/material.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
import 'package:uuid/uuid.dart';
import 'package:Memento/plugins/openai/l10n/openai_localizations.dart';
import 'package:Memento/utils/image_utils.dart';
import 'package:Memento/widgets/circle_icon_picker.dart';
import 'package:Memento/widgets/image_picker_dialog.dart';
import 'package:Memento/plugins/openai/models/ai_agent.dart';
import 'package:Memento/plugins/openai/models/service_provider.dart';
import 'package:Memento/plugins/openai/models/llm_models.dart';
import 'package:Memento/plugins/openai/models/prompt_preset.dart';
import 'package:Memento/plugins/openai/openai_plugin.dart';
import 'package:Memento/plugins/openai/controllers/provider_controller.dart';
import 'package:Memento/plugins/openai/services/test_service.dart';
import 'package:Memento/plugins/openai/services/prompt_preset_service.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/core/services/toast_service.dart';
import 'model_search_screen.dart';

class AgentEditScreen extends StatefulWidget {
  final AIAgent? agent;

  const AgentEditScreen({super.key, this.agent});

  @override
  State<AgentEditScreen> createState() => _AgentEditScreenState();

  static Route<T> route<T>(BuildContext context, {AIAgent? agent}) {
    return NavigationHelper.createRoute(
      Localizations.override(
        context: context,
        child: AgentEditScreen(agent: agent),
      ),
    );
  }
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
  bool _enableFunctionCalling = false;
  bool _enableOpeningQuestions = false;
  final List<String> _openingQuestions = [];
  final _openingQuestionController = TextEditingController();

  List<ServiceProvider> _providers = [];
  bool _isLoadingProviders = true;

  // Prompt 预设相关
  final PromptPresetService _presetService = PromptPresetService();
  List<PromptPreset> _presets = [];
  String? _selectedPresetId;

  @override
  void initState() {
    super.initState();
    _loadProviders();
    _loadPresets();
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
      _enableFunctionCalling = widget.agent!.enableFunctionCalling;
      _selectedPresetId = widget.agent!.promptPresetId;
      _enableOpeningQuestions = widget.agent!.enableOpeningQuestions;
      _openingQuestions.addAll(widget.agent!.openingQuestions);
    }
  }

  Future<void> _loadPresets() async {
    _presets = await _presetService.loadPresets();
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadProviders() async {
    setState(() {
      _isLoadingProviders = true;
    });

    try {
      final providerController = ProviderController();
      _providers = await providerController.getProviders();

      if (_providers.isNotEmpty) {
        if (_selectedProviderId.isEmpty) {
          // 如果没有选择服务商，使用第一个
          _selectedProviderId = _providers.first.id;
          _updateProviderFields(_providers.first);
        } else {
          // 如果已经选择了服务商，找到对应的服务商
          final provider = _providers.firstWhere(
            (p) => p.id == _selectedProviderId,
            orElse: () => _providers.first,
          );
          _selectedProviderId = provider.id;

          // 如果是新建智能体，或者是编辑但字段为空，则使用服务商的默认配置
          if (widget.agent == null ||
              _baseUrlController.text.isEmpty ||
              _headersController.text.isEmpty) {
            _updateProviderFields(provider);
          }
        }
      } else {
        // 如果没有可用的服务商，创建一个默认的
        _selectedProviderId = 'default';
        final defaultProvider = ServiceProvider(
          id: 'default',
          label: 'Default',
          baseUrl: '',
          headers: {},
        );
        if (_baseUrlController.text.isEmpty ||
            _headersController.text.isEmpty) {
          _updateProviderFields(defaultProvider);
        }
      }
    } catch (e) {
      if (mounted) {
        ToastService.instance.showToast(
          '${OpenAILocalizations.of(context).loadProvidersError}: $e',
        );
      }
    } finally {
      setState(() {
        _isLoadingProviders = false;
      });
    }
  }

  void _updateProviderFields(ServiceProvider provider, {bool updateModel = true}) {
    // 如果是新建智能体，或者用户明确要更新配置，则使用服务商的默认配置
    setState(() {
      _baseUrlController.text = provider.baseUrl;
      _headersController.text = _formatHeaders(provider.headers);

      // 使用服务商的默认模型
      if (updateModel && provider.defaultModel != null && provider.defaultModel!.isNotEmpty) {
        _modelController.text = provider.defaultModel!;
      }
    });

    // 显示确认更新的消息
    if (mounted) {
      ToastService.instance.showToast(OpenAILocalizations.of(context).configUpdated);
    }
  }

  Future<void> _selectModel() async {
    final selectedModel = await NavigationHelper.push<LLMModel>(
      context,
      ModelSearchScreen(initialModelId: _modelController.text),
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
      id: widget.agent?.id ?? const Uuid().v4(),
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
      enableFunctionCalling: _enableFunctionCalling,
      promptPresetId: _selectedPresetId,
      enableOpeningQuestions: _enableOpeningQuestions,
      openingQuestions: _openingQuestions,
    );

    try {
      final plugin = PluginManager.instance.getPlugin('openai') as OpenAIPlugin;
      final controller = plugin.controller;
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
        ToastService.instance.showToast(
          '${OpenAILocalizations.of(context).errorSavingAgent}: $e',
        );
      }
    }
  }

  Future<void> _deleteAgent() async {
    // 确认删除对话框
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(OpenAILocalizations.of(context).deleteAgentConfirm),
            content: Text(OpenAILocalizations.of(context).deleteAgentMessage),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(OpenAILocalizations.of(context).cancel),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(
                  OpenAILocalizations.of(context).delete,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );

    if (confirmed != true || widget.agent == null) return;

    try {
      final plugin = PluginManager.instance.getPlugin('openai') as OpenAIPlugin;
      final controller = plugin.controller;
      await controller.deleteAgent(widget.agent!.id);
      if (mounted) {
        ToastService.instance.showToast(OpenAILocalizations.of(context).agentDeleted);
        // 返回true表示删除成功
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ToastService.instance.showToast(
          '${OpenAILocalizations.of(context).deleteFailed}: $e',
        );
      }
    }
  }

  Future<void> _cloneAgent() async {
    if (widget.agent == null) return;

    // 创建一个新的智能体，复制当前智能体的所有属性，但生成新ID并更新名称
    final clonedAgent = AIAgent(
      id: const Uuid().v4(),
      name: '${_nameController.text} (复制)',
      description: _descriptionController.text,
      serviceProviderId: _selectedProviderId,
      baseUrl: _baseUrlController.text,
      headers: _parseHeaders(_headersController.text),
      systemPrompt: _promptController.text,
      model:
          _modelController.text.isEmpty
              ? 'gpt-3.5-turbo'
              : _modelController.text,
      tags: List.from(_tags),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      icon: _selectedIcon,
      iconColor: _selectedIconColor,
      avatarUrl: _avatarUrl,
    );

    try {
      final plugin = PluginManager.instance.getPlugin('openai') as OpenAIPlugin;
      final controller = plugin.controller;
      await controller.addAgent(clonedAgent);
      if (mounted) {
        ToastService.instance.showToast(OpenAILocalizations.of(context).agentCloned);
        // 返回克隆的智能体，以便可能的进一步操作
        Navigator.of(context).pop(clonedAgent);
      }
    } catch (e) {
      if (mounted) {
        ToastService.instance.showToast(
          '${OpenAILocalizations.of(context).cloneFailed}: $e',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.agent == null
              ? OpenAILocalizations.of(context).createAgent
              : OpenAILocalizations.of(context).editAgent,
        ),
        actions: [
          // 只有在编辑现有智能体时才显示删除和克隆按钮
          if (widget.agent != null) ...[
            IconButton(
              icon: const Icon(Icons.copy),
              onPressed: _cloneAgent,
              tooltip: OpenAILocalizations.of(context).cloneAgent,
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteAgent,
              tooltip: OpenAILocalizations.of(context).deleteAgent,
            ),
          ],
          IconButton(icon: const Icon(Icons.save), onPressed: _saveAgent),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: CircleIconPicker(
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
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      final result = await showDialog<Map<String, dynamic>>(
                        context: context,
                        builder:
                            (context) => ImagePickerDialog(
                              initialUrl: _avatarUrl,
                              saveDirectory: 'openai/agent_avatars',
                              enableCrop: true,
                              cropAspectRatio: 1.0,
                            ),
                      );
                      if (result != null && result['url'] != null) {
                        setState(() {
                          _avatarUrl = result['url'] as String;
                        });
                      }
                    },
                    child: SizedBox(
                      width: 64,
                      height: 64,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.5),
                            width: 2,
                          ),
                        ),
                        child:
                            _avatarUrl != null && _avatarUrl!.isNotEmpty
                                ? FutureBuilder<String>(
                                  future:
                                      _avatarUrl!.startsWith('http')
                                          ? Future.value(_avatarUrl!)
                                          : ImageUtils.getAbsolutePath(
                                            _avatarUrl,
                                          ),
                                  builder: (context, snapshot) {
                                    if (snapshot.hasData) {
                                      return Center(
                                        child: AspectRatio(
                                          aspectRatio: 1.0,
                                          child: ClipOval(
                                            child:
                                                _avatarUrl!.startsWith('http')
                                                    ? Image.network(
                                                      snapshot.data!,
                                                      width: 64,
                                                      height: 64,
                                                      fit: BoxFit.cover,
                                                      errorBuilder:
                                                          (
                                                            context,
                                                            error,
                                                            stackTrace,
                                                          ) => const Icon(
                                                            Icons.broken_image,
                                                          ),
                                                    )
                                                    : Image.file(
                                                      File(snapshot.data!),
                                                      width: 64,
                                                      height: 64,
                                                      fit: BoxFit.cover,
                                                      errorBuilder:
                                                          (
                                                            context,
                                                            error,
                                                            stackTrace,
                                                          ) => const Icon(
                                                            Icons.broken_image,
                                                          ),
                                                    ),
                                          ),
                                        ),
                                      );
                                    } else if (snapshot.hasError) {
                                      return const Icon(Icons.broken_image);
                                    } else {
                                      return const CircularProgressIndicator();
                                    }
                                  },
                                )
                                : Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.add_photo_alternate_outlined,
                                        size: 24,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        OpenAILocalizations.of(context).avatar,
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ],
                                  ),
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
              decoration: InputDecoration(
                labelText: OpenAILocalizations.of(context).agentName,
                hintText: OpenAILocalizations.of(context).enterAgentName,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return OpenAILocalizations.of(context).pleaseEnterName;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _isLoadingProviders
                ? Center(
                  child: Text(OpenAILocalizations.of(context).loadingProviders),
                )
                : DropdownButtonFormField<String>(
                  value: _providers.isNotEmpty &&
                         _providers.any((p) => p.id == _selectedProviderId)
                      ? _selectedProviderId
                      : (_providers.isNotEmpty ? _providers.first.id : null),
                  decoration: InputDecoration(
                    labelText: OpenAILocalizations.of(context).serviceProvider,
                  ),
                  items:
                      _providers.map((provider) {
                        return DropdownMenuItem(
                          value: provider.id,
                          child: Text(provider.label),
                        );
                      }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      final provider = _providers.firstWhere(
                        (p) => p.id == value,
                      );

                      // 如果是编辑现有智能体，先询问用户是否要更新配置
                      if (widget.agent != null) {
                        showDialog(
                          context: context,
                          builder:
                              (context) => AlertDialog(
                                title: Text(
                                  OpenAILocalizations.of(context).updateConfig,
                                ),
                                content: Text(
                                  OpenAILocalizations.of(
                                    context,
                                  ).updateConfigConfirm,
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                      setState(() {
                                        _selectedProviderId = value;
                                      });
                                    },
                                    child: Text(
                                      OpenAILocalizations.of(
                                        context,
                                      ).keepCurrentConfig,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                      setState(() {
                                        _selectedProviderId = value;
                                        _updateProviderFields(provider);
                                      });
                                    },
                                    child: Text(
                                      OpenAILocalizations.of(
                                        context,
                                      ).useDefaultConfig,
                                    ),
                                  ),
                                ],
                              ),
                        );
                      } else {
                        // 如果是新建智能体，直接更新配置
                        setState(() {
                          _selectedProviderId = value;
                          _updateProviderFields(provider);
                        });
                      }
                    }
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return OpenAILocalizations.of(
                        context,
                      ).pleaseSelectProvider;
                    }
                    return null;
                  },
                ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: OpenAILocalizations.of(context).description,
                hintText: OpenAILocalizations.of(context).enterDescription,
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return OpenAILocalizations.of(context).pleaseEnterDescription;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            // Prompt 预设选择
            DropdownButtonFormField<String>(
              value: _selectedPresetId != null &&
                     _presets.any((p) => p.id == _selectedPresetId)
                  ? _selectedPresetId
                  : null,
              decoration: InputDecoration(
                labelText: OpenAILocalizations.of(context).promptPreset,
                hintText: OpenAILocalizations.of(context).selectPromptPreset,
              ),
              items: [
                DropdownMenuItem<String>(
                  value: null,
                  child: Text(OpenAILocalizations.of(context).noPreset),
                ),
                ..._presets.map((preset) {
                  return DropdownMenuItem<String>(
                    value: preset.id,
                    child: Text(preset.name),
                  );
                }),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedPresetId = value;
                });
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _promptController,
              decoration: InputDecoration(
                labelText: OpenAILocalizations.of(context).systemPrompt,
                hintText: OpenAILocalizations.of(context).enterSystemPrompt,
                helperText: _selectedPresetId != null
                    ? OpenAILocalizations.of(context).promptPresetActiveHint
                    : null,
                helperStyle: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              maxLines: 5,
              enabled: _selectedPresetId == null,
              validator: (value) {
                // 如果选择了预设，不需要验证原有的 prompt
                if (_selectedPresetId != null) {
                  return null;
                }
                if (value == null || value.isEmpty) {
                  return OpenAILocalizations.of(
                    context,
                  ).pleaseEnterSystemPrompt;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _baseUrlController,
              decoration: InputDecoration(
                labelText: OpenAILocalizations.of(context).baseUrl,
                hintText: OpenAILocalizations.of(context).enterBaseUrl,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return OpenAILocalizations.of(context).pleaseEnterBaseUrl;
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
                    decoration: InputDecoration(
                      labelText: OpenAILocalizations.of(context).model,
                      hintText: OpenAILocalizations.of(context).enterModel,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _selectModel,
                  tooltip: OpenAILocalizations.of(context).searchModel,
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _headersController,
              decoration: InputDecoration(
                labelText: OpenAILocalizations.of(context).headers,
                hintText: OpenAILocalizations.of(context).enterHeaders,
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _tagController,
                    decoration: InputDecoration(
                      labelText: OpenAILocalizations.of(context).tags,
                      hintText: OpenAILocalizations.of(context).enterTag,
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
            const SizedBox(height: 24),
            SwitchListTile(
              title: Text(OpenAILocalizations.of(context).enablePluginFunctionCalls),
              subtitle: Text(OpenAILocalizations.of(context).allowAICallPluginFunctions),
              value: _enableFunctionCalling,
              onChanged: (value) {
                setState(() {
                  _enableFunctionCalling = value;
                });
              },
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: Text(OpenAILocalizations.of(context).enableGuessWhatYouWantToAsk),
              subtitle: Text(OpenAILocalizations.of(context).showPresetOpeningQuestions),
              value: _enableOpeningQuestions,
              onChanged: (value) {
                setState(() {
                  _enableOpeningQuestions = value;
                });
              },
            ),
            if (_enableOpeningQuestions) ...[
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  '开场白问题列表',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _openingQuestionController,
                        decoration: const InputDecoration(
                          labelText: '添加开场白问题',
                          hintText: '输入一个问题',
                        ),
                        maxLines: 2,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () {
                        final question = _openingQuestionController.text.trim();
                        if (question.isNotEmpty) {
                          setState(() {
                            _openingQuestions.add(question);
                            _openingQuestionController.clear();
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              if (_openingQuestions.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: _openingQuestions.asMap().entries.map((entry) {
                      final index = entry.key;
                      final question = entry.value;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text(question),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, size: 20),
                                onPressed: () {
                                  _openingQuestionController.text = question;
                                  setState(() {
                                    _openingQuestions.removeAt(index);
                                  });
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, size: 20),
                                onPressed: () {
                                  setState(() {
                                    _openingQuestions.removeAt(index);
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
            ],
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _testAgent,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
              child: Text(OpenAILocalizations.of(context).testAgent),
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
    _providers.firstWhere(
      (p) => p.id == _selectedProviderId,
      orElse: () => throw Exception('未找到选定的服务商'),
    );

    // 创建临时agent用于测试，使用表单中的最新配置
    final headers = _parseHeaders(_headersController.text);
    final apiKey = headers['Authorization']?.replaceFirst('Bearer ', '') ?? '';

    final testAgent = AIAgent(
      id: 'test',
      // 如果模型为空，使用 gpt-4-vision-preview 作为默认模型
      model:
          _modelController.text.isEmpty
              ? 'gpt-4-vision-preview'
              : _modelController.text,
      name: _nameController.text,
      description: _descriptionController.text,
      serviceProviderId: _selectedProviderId,
      baseUrl: _baseUrlController.text,
      headers: headers,
      systemPrompt: _promptController.text,
      tags: _tags,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      // 默认参数值
      temperature: 0.7,
      maxLength: 2000,
      topP: 1.0,
      frequencyPenalty: 0.0,
      presencePenalty: 0.0,
    );

    // 获取当前表单的值
    final formValues = {
      'name': _nameController.text,
      'baseUrl': _baseUrlController.text,
      'model': _modelController.text,
      'systemPrompt': _promptController.text,
      'serviceProviderId': _selectedProviderId,
      'apiKey': apiKey,
      // 可以在这里添加更多参数，如果界面上有相应的输入控件
      'temperature': 0.7, // 默认值，如果界面上有输入控件，可以从控件获取
      'maxLength': 2000, // 默认值
      'topP': 1.0, // 默认值
      'frequencyPenalty': 0.0, // 默认值
      'presencePenalty': 0.0, // 默认值
    };

    // 使用 TestService 的对话框，传递 testAgent 和 formValues
    // 对话框内部会自动处理测试和显示结果
    await TestService.showLongTextInputDialog(
      context,
      title:
          '${OpenAILocalizations.of(context).testAgentTitle}${testAgent.name}',
      hintText: OpenAILocalizations.of(context).enterTestText,
      enableImagePicker: true,
      testAgent: testAgent,
      formValues: formValues,
    );
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
    _openingQuestionController.dispose();
    super.dispose();
  }
}

// 删除自定义对话框，因为现在使用 TestService 中的对话框
