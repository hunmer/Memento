import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
import 'package:Memento/core/services/clipboard_service.dart';
import 'package:uuid/uuid.dart';
import 'package:Memento/widgets/form_fields/index.dart';
import 'package:Memento/plugins/openai/models/ai_agent.dart';
import 'package:Memento/plugins/openai/models/api_format.dart';
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
  final bool isFromMarketplace; // 是否来自商场
  final String? extraStorageKey; // 如果提供,保存到extra storage;否则保存到临时agents
  final Future<AIAgent?> Function(AIAgent agent)? onSave; // 保存回调，如果不为null则调用回调而不保存到controller

  const AgentEditScreen({
    super.key,
    this.agent,
    this.isFromMarketplace = false,
    this.extraStorageKey,
    this.onSave,
  });

  @override
  State<AgentEditScreen> createState() => _AgentEditScreenState();

  static Route<T> route<T>(
    BuildContext context, {
    AIAgent? agent,
    bool isFromMarketplace = false,
  }) {
    return NavigationHelper.createRoute(
      AgentEditScreen(agent: agent, isFromMarketplace: isFromMarketplace),
    );
  }
}

class _AgentEditScreenState extends State<AgentEditScreen> {
  // FormBuilderWrapper key
  final _formKey = GlobalKey<FormBuilderState>();

  // 服务商相关状态（需要特殊处理）
  List<ServiceProvider> _providers = [];
  String _selectedProviderId = '';

  // 预设相关（用于下拉选项）
  final PromptPresetService _presetService = PromptPresetService();
  List<PromptPreset> _presets = [];

  @override
  void initState() {
    super.initState();
    _loadProviders();
    _loadPresets();
    if (widget.agent != null) {
      _selectedProviderId = widget.agent!.serviceProviderId;
    }
  }

  /// 获取服务商默认颜色
  Color _getColorForServiceProvider(String providerId) {
    switch (providerId) {
      case 'openai':
        return Colors.green;
      case 'azure':
        return Colors.blue;
      case 'ollama':
        return Colors.orange;
      case 'deepseek':
        return Colors.purple;
      case 'minimax':
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }

  Future<void> _loadPresets() async {
    _presets = await _presetService.loadPresets();
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadProviders() async {
    try {
      final providerController = ProviderController();
      _providers = await providerController.getProviders();

      if (_providers.isNotEmpty) {
        if (_selectedProviderId.isEmpty) {
          _selectedProviderId = _providers.first.id;
        }
      }
      setState(() {});
    } catch (e) {
      if (mounted) {
        ToastService.instance.showToast(
          '${'openai_loadProvidersError'.tr}: $e',
        );
      }
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

  Future<void> _saveAgent() async {
    if (_formKey.currentState == null ||
        !_formKey.currentState!.saveAndValidate()) {
      return;
    }

    final values = _formKey.currentState!.value;

    // 从 iconAvatarRow 字段获取图标和头像
    final iconAvatarData = values['iconAvatar'] as Map<String, dynamic>?;

    // 从 promptEditor 字段获取提示词
    final prompts = values['promptEditor'] as List<dynamic>? ?? [];
    // 构建完整的 messages 数组（包含 system 类型）
    final allMessages = <Prompt>[];
    String systemPrompt = '';

    for (final p in prompts) {
      if (p is Map<String, dynamic>) {
        final prompt = Prompt.fromJson(p);
        if (prompt.type == 'system') {
          systemPrompt = prompt.content;
        }
        allMessages.add(prompt);
      }
    }

    // 如果没有 system 类型的消息但有 systemPrompt，添加它
    if (systemPrompt.isNotEmpty &&
        !allMessages.any((m) => m.type == 'system')) {
      allMessages.insert(0, Prompt(type: 'system', content: systemPrompt));
    }

    final agent = AIAgent(
      id: widget.agent?.id ?? const Uuid().v4(),
      name: values['name'] as String? ?? '',
      description: values['description'] as String? ?? '',
      serviceProviderId: _selectedProviderId,
      baseUrl: values['baseUrl'] as String? ?? '',
      headers: _parseHeaders(values['headers'] as String? ?? ''),
      model: values['model'] as String? ?? 'gpt-3.5-turbo',
      tags: (values['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      createdAt: widget.agent?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
      icon: iconAvatarData?['icon'] as IconData?,
      iconColor: iconAvatarData?['iconColor'] as Color?,
      avatarUrl: iconAvatarData?['avatarUrl'] as String?,
      enableFunctionCalling: values['enableFunctionCalling'] as bool? ?? false,
      promptPresetId: values['promptPresetId'] as String?,
      enableOpeningQuestions:
          values['enableOpeningQuestions'] as bool? ?? false,
      openingQuestions:
          (values['openingQuestions'] as List<dynamic>?)?.cast<String>() ?? [],
      messages: allMessages.isNotEmpty ? allMessages : null,
      apiFormat: values['apiFormat'] as String? ?? 'openai',
    );

    try {
      // 如果提供了 onSave 回调，调用它并返回 agent
      if (widget.onSave != null) {
        final resultAgent = await widget.onSave!(agent);
        if (mounted) {
          // 回调返回的 agent（可能是处理后的版本）
          final finalAgent = resultAgent ?? agent;
          // 显示成功提示
          ToastService.instance.showToast('保存成功');
          // 返回配置
          Navigator.of(context).pop(finalAgent);
        }
        return;
      }

      // 否则按原有逻辑保存到 controller
      final plugin = PluginManager.instance.getPlugin('openai') as OpenAIPlugin;
      final controller = plugin.controller;

      // 根据 extraStorageKey 的值决定保存位置
      if (widget.extraStorageKey != null) {
        // 保存到 extra storage
        await controller.saveAgentToExtraStorage(
          agent,
          widget.extraStorageKey!,
        );
      } else if (widget.agent == null) {
        // 新建 agent，添加到正式 agents 列表
        await controller.addAgent(agent);
      } else if (widget.isFromMarketplace) {
        // 从商场安装，添加到正式agents列表
        await controller.addAgent(agent);
      } else {
        // 编辑现有 Agent
        await controller.updateAgent(agent);
      }

      if (mounted) {
        // 显示成功提示
        ToastService.instance.showToast(
          widget.isFromMarketplace
              ? '安装成功'
              : (widget.agent == null ? '创建成功' : '保存成功'),
        );
        // 返回true表示保存成功
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ToastService.instance.showToast('${'openai_errorSavingAgent'.tr}: $e');
      }
    }
  }

  Future<void> _deleteAgent() async {
    // 确认删除对话框
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('openai_deleteAgentConfirm'.tr),
            content: Text('openai_deleteAgentMessage'.tr),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('openai_cancel'.tr),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(
                  'openai_delete'.tr,
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
        ToastService.instance.showToast('openai_agentDeleted'.tr);
        // 返回true表示删除成功
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ToastService.instance.showToast('${'openai_deleteFailed'.tr}: $e');
      }
    }
  }

  Future<void> _shareAgent() async {
    if (widget.agent == null) return;

    final agentJson = widget.agent!.toJson();
    final hasHeaders = widget.agent!.headers.isNotEmpty;

    // 如果有 headers，询问用户是否包含
    if (hasHeaders) {
      final choice = await showDialog<String>(
        context: context,
        builder:
            (context) => AlertDialog(
              title: Text('openai_shareAgent'.tr),
              content: Text('openai_shareHeadersWarning'.tr),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop('cancel'),
                  child: Text('openai_cancel'.tr),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop('remove'),
                  child: Text('openai_removeHeaders'.tr),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop('keep'),
                  child: Text('openai_keepHeaders'.tr),
                ),
              ],
            ),
      );

      if (choice == 'cancel' || choice == null) return;
      if (choice == 'remove') {
        agentJson.remove('headers');
      }
    }

    // 使用 ClipboardService 复制
    final success = await ClipboardService.instance.copyToClipboard(
      method: 'openai_agent_import',
      args: agentJson,
    );

    if (success) {
      Toast.success('openai_agentCopied'.tr);
    } else {
      Toast.error('openai_copyFailed'.tr);
    }
  }

  Future<void> _cloneAgent() async {
    if (widget.agent == null || _formKey.currentState == null) return;

    // 先触发表单保存和验证，确保获取当前表单的最新值
    if (!_formKey.currentState!.saveAndValidate()) {
      // 表单验证失败，不进行克隆
      return;
    }

    final values = _formKey.currentState!.value;

    // 从 iconAvatarRow 字段获取图标和头像
    final iconAvatarData = values['iconAvatar'] as Map<String, dynamic>?;

    // 从 promptEditor 字段获取提示词
    final prompts = values['promptEditor'] as List<dynamic>? ?? [];
    // 构建完整的 messages 数组（包含 system 类型）
    final allMessages = <Prompt>[];
    String systemPrompt = '';

    for (final p in prompts) {
      if (p is Map<String, dynamic>) {
        final prompt = Prompt.fromJson(p);
        if (prompt.type == 'system') {
          systemPrompt = prompt.content;
        }
        allMessages.add(prompt);
      }
    }

    // 如果没有 system 类型的消息但有 systemPrompt，添加它
    if (systemPrompt.isNotEmpty &&
        !allMessages.any((m) => m.type == 'system')) {
      allMessages.insert(0, Prompt(type: 'system', content: systemPrompt));
    }

    // 创建一个新的智能体，复制当前智能体的所有属性，但生成新ID并更新名称
    final clonedAgent = AIAgent(
      id: const Uuid().v4(),
      name: '${values['name'] as String? ?? ''} (复制)',
      description: values['description'] as String? ?? '',
      serviceProviderId: _selectedProviderId,
      baseUrl: values['baseUrl'] as String? ?? '',
      headers: _parseHeaders(values['headers'] as String? ?? ''),
      model: values['model'] as String? ?? 'gpt-3.5-turbo',
      tags: (values['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      icon: iconAvatarData?['icon'] as IconData?,
      iconColor: iconAvatarData?['iconColor'] as Color?,
      avatarUrl: iconAvatarData?['avatarUrl'] as String?,
      enableFunctionCalling: values['enableFunctionCalling'] as bool? ?? false,
      promptPresetId: values['promptPresetId'] as String?,
      enableOpeningQuestions:
          values['enableOpeningQuestions'] as bool? ?? false,
      openingQuestions:
          (values['openingQuestions'] as List<dynamic>?)?.cast<String>() ?? [],
      messages: allMessages.isNotEmpty ? allMessages : null,
      apiFormat: values['apiFormat'] as String? ?? 'openai',
    );

    try {
      final plugin = PluginManager.instance.getPlugin('openai') as OpenAIPlugin;
      final controller = plugin.controller;
      await controller.addAgent(clonedAgent);
      if (mounted) {
        ToastService.instance.showToast('openai_agentCloned'.tr);
        // 返回克隆的智能体，以便可能的进一步操作
        Navigator.of(context).pop(clonedAgent);
      }
    } catch (e) {
      if (mounted) {
        ToastService.instance.showToast('${'openai_cloneFailed'.tr}: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.agent == null
              ? 'openai_createAgent'.tr
              : 'openai_editAgent'.tr,
        ),
        actions: [
          // 只有在非回调模式下才显示删除、分享、克隆按钮
          if (widget.onSave == null && widget.agent != null) ...[
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: _shareAgent,
              tooltip: 'openai_shareAgent'.tr,
            ),
            IconButton(
              icon: const Icon(Icons.copy),
              onPressed: _cloneAgent,
              tooltip: 'openai_cloneAgent'.tr,
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteAgent,
              tooltip: 'openai_deleteAgent'.tr,
            ),
          ],
          IconButton(
            icon: Icon(widget.isFromMarketplace ? Icons.download : Icons.save),
            onPressed: _saveAgent,
            tooltip: widget.isFromMarketplace ? '安装' : 'openai_save'.tr,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                FormBuilderWrapper(
                  formKey: _formKey,
                  buttonBuilder: (context, onSubmit, onReset) {
                    return const SizedBox.shrink();
                  },
                  config: FormConfig(
                    showSubmitButton: false,
                    showResetButton: false,
                    fieldSpacing: 16,
                    fields: [
                      // 图标头像行
                      FormFieldConfig(
                        name: 'iconAvatar',
                        type: FormFieldType.iconAvatarRow,
                        initialValue: {
                          'icon': widget.agent?.icon,
                          'iconColor':
                              widget.agent?.iconColor ??
                              _getColorForServiceProvider(_selectedProviderId),
                          'avatarUrl': widget.agent?.avatarUrl,
                        },
                        extra: {'avatarSaveDirectory': 'openai/agent_avatars'},
                      ),
                      // 名称
                      FormFieldConfig(
                        name: 'name',
                        type: FormFieldType.text,
                        labelText: 'openai_agentName'.tr,
                        hintText: 'openai_enterAgentName'.tr,
                        initialValue: widget.agent?.name ?? '',
                        required: true,
                        validationMessage: 'openai_pleaseEnterName'.tr,
                      ),
                      // 服务商选择 - 使用自定义渲染处理特殊逻辑
                      FormFieldConfig(
                        name: 'serviceProvider',
                        type: FormFieldType.select,
                        labelText: 'openai_serviceProvider'.tr,
                        initialValue:
                            _providers.any((p) => p.id == _selectedProviderId)
                                ? _selectedProviderId
                                : (_providers.isNotEmpty
                                    ? _providers.first.id
                                    : null),
                        required: true,
                        items:
                            _providers
                                .map(
                                  (p) => DropdownMenuItem(
                                    value: p.id,
                                    child: Text(p.label),
                                  ),
                                )
                                .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            final provider = _providers.firstWhere(
                              (p) => p.id == value,
                            );
                            setState(() => _selectedProviderId = value);
                            // 服务商切换时的特殊逻辑
                            _handleProviderChange(provider);
                          }
                        },
                      ),
                      // API 格式选择
                      FormFieldConfig(
                        name: 'apiFormat',
                        type: FormFieldType.select,
                        labelText: 'API 格式',
                        hintText: '选择 API 格式',
                        initialValue: widget.agent?.apiFormat ?? 'openai',
                        required: true,
                        items:
                            ApiFormat.values
                                .map(
                                  (format) => DropdownMenuItem(
                                    value: format.value,
                                    child: Text(format.label),
                                  ),
                                )
                                .toList(),
                      ),
                      // 描述
                      FormFieldConfig(
                        name: 'description',
                        type: FormFieldType.textArea,
                        labelText: 'openai_description'.tr,
                        hintText: 'openai_enterDescription'.tr,
                        initialValue: widget.agent?.description ?? '',
                        required: true,
                        validationMessage: 'openai_pleaseEnterDescription'.tr,
                        extra: {'minLines': 3, 'maxLines': 3},
                      ),
                      // Prompt 预设选择
                      FormFieldConfig(
                        name: 'promptPresetId',
                        type: FormFieldType.select,
                        labelText: 'openai_promptPreset'.tr,
                        hintText: 'openai_selectPromptPreset'.tr,
                        initialValue: widget.agent?.promptPresetId,
                        items: [
                          DropdownMenuItem<String>(
                            value: null,
                            child: Text('openai_noPreset'.tr),
                          ),
                          ..._presets.map(
                            (preset) => DropdownMenuItem<String>(
                              value: preset.id,
                              child: Text(preset.name),
                            ),
                          ),
                        ],
                      ),
                      // 提示词编辑器
                      FormFieldConfig(
                        name: 'promptEditor',
                        type: FormFieldType.promptEditor,
                        initialValue:
                            widget.agent?.messages
                                    ?.map((p) => p.toJson())
                                    .toList()
                                as List<dynamic>? ??
                            [],
                      ),
                      // BaseUrl
                      FormFieldConfig(
                        name: 'baseUrl',
                        type: FormFieldType.text,
                        labelText: 'openai_baseUrl'.tr,
                        hintText: 'openai_enterBaseUrl'.tr,
                        initialValue: widget.agent?.baseUrl ?? '',
                        required: true,
                        validationMessage: 'openai_pleaseEnterBaseUrl'.tr,
                      ),
                      // 模型（带搜索按钮）
                      FormFieldConfig(
                        name: 'model',
                        type: FormFieldType.text,
                        labelText: 'openai_model'.tr,
                        hintText: 'openai_enterModel'.tr,
                        initialValue: widget.agent?.model ?? '',
                        suffixButtons: [
                          InputGroupButton(
                            icon: Icons.search,
                            tooltip: 'openai_searchModel'.tr,
                            onPressed: () => _selectModel(),
                          ),
                        ],
                      ),
                      // Headers
                      FormFieldConfig(
                        name: 'headers',
                        type: FormFieldType.textArea,
                        labelText: 'openai_headers'.tr,
                        hintText: 'openai_enterHeaders'.tr,
                        initialValue: _formatHeaders(
                          widget.agent?.headers ?? {},
                        ),
                        extra: {'minLines': 3, 'maxLines': 3},
                      ),
                      // 标签
                      FormFieldConfig(
                        name: 'tags',
                        type: FormFieldType.tags,
                        initialTags: widget.agent?.tags ?? [],
                      ),
                      // 启用函数调用
                      FormFieldConfig(
                        name: 'enableFunctionCalling',
                        type: FormFieldType.switchField,
                        labelText: 'openai_enablePluginFunctionCalls'.tr,
                        hintText: 'openai_allowAICallPluginFunctions'.tr,
                        initialValue:
                            widget.agent?.enableFunctionCalling ?? false,
                      ),
                      // 启用开场白问题
                      FormFieldConfig(
                        name: 'enableOpeningQuestions',
                        type: FormFieldType.switchField,
                        labelText: 'openai_enableGuessWhatYouWantToAsk'.tr,
                        hintText: 'openai_showPresetOpeningQuestions'.tr,
                        initialValue:
                            widget.agent?.enableOpeningQuestions ?? false,
                      ),
                      // 开场白问题列表（条件显示）
                      FormFieldConfig(
                        name: 'openingQuestions',
                        type: FormFieldType.listAdd,
                        initialValue: widget.agent?.openingQuestions ?? [],
                        extra: {
                          'initialItems': widget.agent?.openingQuestions ?? [],
                        },
                        visible:
                            (values) =>
                                values['enableOpeningQuestions'] == true,
                      ),
                    ],
                    onSubmit: (values) {
                      // 由 _saveAgent 处理
                    },
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: _testAgent,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
              child: Text('openai_testAgent'.tr),
            ),
          ),
        ],
      ),
    );
  }

  // 处理服务商切换
  void _handleProviderChange(ServiceProvider provider) {
    // 如果是编辑现有智能体，先询问用户是否要更新配置
    if (widget.agent != null) {
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: Text('openai_updateConfig'.tr),
              content: Text('openai_updateConfigConfirm'.tr),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    // 保留当前配置，不更新
                  },
                  child: Text('openai_keepCurrentConfig'.tr),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    // 更新为服务商默认配置
                    _updateFormWithProvider(provider);
                  },
                  child: Text('openai_useDefaultConfig'.tr),
                ),
              ],
            ),
      );
    } else {
      // 新建智能体，直接使用服务商默认配置
      _updateFormWithProvider(provider);
    }
  }

  // 使用服务商配置更新表单
  void _updateFormWithProvider(ServiceProvider provider) {
    if (_formKey.currentState != null) {
      final currentValues = Map<String, dynamic>.from(
        _formKey.currentState!.value,
      );
      currentValues['baseUrl'] = provider.baseUrl;
      currentValues['headers'] = _formatHeaders(provider.headers);
      if (provider.defaultModel != null && provider.defaultModel!.isNotEmpty) {
        currentValues['model'] = provider.defaultModel!;
      }
      _formKey.currentState!.patchValue(currentValues);
    }
    ToastService.instance.showToast('openai_configUpdated'.tr);
  }

  // 模型选择
  Future<void> _selectModel() async {
    final currentModel = _formKey.currentState?.value['model'] as String? ?? '';
    final selectedModel = await NavigationHelper.push<LLMModel>(
      context,
      ModelSearchScreen(initialModelId: currentModel),
    );
    if (selectedModel != null && _formKey.currentState != null) {
      _formKey.currentState!.patchValue({'model': selectedModel.id});
    }
  }

  // 触发表单验证并测试 Agent
  Future<void> _testAgentWithSubmit(VoidCallback onSubmit) async {
    // 首先调用 onSubmit 回调触发表单验证和 onSubmitted
    onSubmit();

    // 等待一帧让表单状态更新
    await Future.delayed(Duration.zero);

    // 然后调用 _testAgent，它会再次验证并获取表单值
    await _testAgent();
  }

  Future<void> _testAgent() async {
    if (_formKey.currentState == null ||
        !_formKey.currentState!.saveAndValidate()) {
      return;
    }

    final values = _formKey.currentState!.value;

    // 从 iconAvatarRow 字段获取图标和头像
    final iconAvatarData = values['iconAvatar'] as Map<String, dynamic>?;

    // 从 promptEditor 字段获取提示词
    final prompts = values['promptEditor'] as List<dynamic>? ?? [];
    // 构建完整的 messages 数组（包含 system 类型）
    final allMessages = <Prompt>[];

    for (final p in prompts) {
      if (p is Map<String, dynamic>) {
        allMessages.add(Prompt.fromJson(p));
      }
    }

    // 创建临时agent用于测试，使用表单中的最新配置
    final headers = _parseHeaders(values['headers'] as String? ?? '');
    final apiKey = headers['Authorization']?.replaceFirst('Bearer ', '') ?? '';

    final testAgent = AIAgent(
      id: 'test',
      model: values['model'] as String? ?? 'gpt-4-vision-preview',
      name: values['name'] as String? ?? '',
      description: values['description'] as String? ?? '',
      serviceProviderId: _selectedProviderId,
      baseUrl: values['baseUrl'] as String? ?? '',
      headers: headers,
      tags: (values['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      icon: iconAvatarData?['icon'] as IconData?,
      iconColor: iconAvatarData?['iconColor'] as Color?,
      avatarUrl: iconAvatarData?['avatarUrl'] as String?,
      temperature: 0.7,
      maxLength: 2000,
      topP: 1.0,
      frequencyPenalty: 0.0,
      presencePenalty: 0.0,
      enableFunctionCalling: values['enableFunctionCalling'] as bool? ?? false,
      promptPresetId: values['promptPresetId'] as String?,
      enableOpeningQuestions:
          values['enableOpeningQuestions'] as bool? ?? false,
      openingQuestions:
          (values['openingQuestions'] as List<dynamic>?)?.cast<String>() ?? [],
      messages: allMessages.isNotEmpty ? allMessages : null,
      apiFormat: values['apiFormat'] as String? ?? 'openai',
    );

    // 获取当前表单的值
    final formValues = {
      'name': values['name'],
      'baseUrl': values['baseUrl'],
      'model': values['model'],
      'serviceProviderId': _selectedProviderId,
      'apiKey': apiKey,
      'temperature': 0.7,
      'maxLength': 2000,
      'topP': 1.0,
      'frequencyPenalty': 0.0,
      'presencePenalty': 0.0,
    };

    await TestService.showLongTextInputDialog(
      context,
      title: '${'openai_testAgentTitle'.tr}${testAgent.name}',
      hintText: 'openai_enterTestText'.tr,
      enableImagePicker: true,
      testAgent: testAgent,
      formValues: formValues,
    );
  }
}
