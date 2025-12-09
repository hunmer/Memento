import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
import 'package:uuid/uuid.dart';
import 'package:Memento/plugins/openai/models/service_provider.dart';
import 'package:Memento/plugins/openai/models/llm_models.dart';
import 'package:Memento/plugins/openai/controllers/provider_controller.dart';
import 'model_search_screen.dart';

class ProviderEditScreen extends StatefulWidget {
  final ServiceProvider? provider;

  const ProviderEditScreen({super.key, this.provider});

  @override
  State<ProviderEditScreen> createState() => _ProviderEditScreenState();
}

class _ProviderEditScreenState extends State<ProviderEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _labelController = TextEditingController();
  final _baseUrlController = TextEditingController();
  final _defaultModelController = TextEditingController();

  // 用于添加/编辑 header
  final _headerKeyController = TextEditingController();
  final _headerValueController = TextEditingController();

  // 存储当前的 headers
  Map<String, String> _headers = {};

  @override
  void initState() {
    super.initState();
    if (widget.provider != null) {
      _labelController.text = widget.provider!.label;
      _baseUrlController.text = widget.provider!.baseUrl;
      _headers = Map<String, String>.from(widget.provider!.headers);
      _defaultModelController.text = widget.provider!.defaultModel ?? '';
    }
  }

  @override
  void dispose() {
    _labelController.dispose();
    _baseUrlController.dispose();
    _defaultModelController.dispose();
    _headerKeyController.dispose();
    _headerValueController.dispose();
    super.dispose();
  }

  void _addHeader() {
    final key = _headerKeyController.text.trim();
    final value = _headerValueController.text.trim();

    if (key.isEmpty) {
      return;
    }

    setState(() {
      _headers[key] = value;
      _headerKeyController.clear();
      _headerValueController.clear();
    });
  }

  void _removeHeader(String key) {
    setState(() {
      _headers.remove(key);
    });
  }

  void _editHeader(String key) {
    _headerKeyController.text = key;
    _headerValueController.text = _headers[key] ?? '';
    _removeHeader(key);
  }

  Future<void> _selectDefaultModel() async {
    final selectedModel = await NavigationHelper.push<LLMModel>(
      context,
      ModelSearchScreen(
        initialModelId: _defaultModelController.text,
      ),
    );

    if (selectedModel != null) {
      setState(() {
        _defaultModelController.text = selectedModel.id;
      });
    }
  }

  Future<void> _saveProvider() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final controller = ProviderController();

    final provider = ServiceProvider(
      id:
          widget.provider?.id ??
          const Uuid().v4(),
      label: _labelController.text.trim(),
      baseUrl: _baseUrlController.text.trim(),
      headers: _headers,
      defaultModel: _defaultModelController.text.trim().isEmpty
          ? null
          : _defaultModelController.text.trim(),
    );

    if (widget.provider == null) {
      await controller.addProvider(provider);
    } else {
      await controller.updateProvider(provider);
    }
    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  // 检查是否有未添加的 header 输入
  bool _hasUnsavedHeaderInput() {
    return _headerKeyController.text.trim().isNotEmpty ||
        _headerValueController.text.trim().isNotEmpty;
  }

  // 显示确认对话框
  Future<bool> _showUnsavedChangesDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('openai_unsavedChangesTitle'.tr),
        content: Text('openai_unsavedHeaderWarning'.tr),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('openai_cancel'.tr),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('openai_discard'.tr),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) return;

        // 检查是否有未添加的 header 输入
        if (_hasUnsavedHeaderInput()) {
          final shouldPop = await _showUnsavedChangesDialog();
          if (shouldPop && context.mounted) {
            Navigator.pop(context);
          }
        } else {
          if (context.mounted) {
            Navigator.pop(context);
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.provider == null
                ? 'openai_addProvider'.tr
                : 'openai_editProvider'.tr,
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveProvider,
              tooltip: 'openai_saveTooltip'.tr,
            ),
          ],
        ),
        body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _labelController,
              decoration: InputDecoration(
                labelText: 'openai_serviceProvider'.tr,
                hintText: 'openai_pleaseSelectProvider'.tr,
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'openai_providerLabelError'.tr;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _baseUrlController,
              decoration: InputDecoration(
                labelText: 'openai_baseUrl'.tr,
                hintText: 'openai_enterBaseUrl'.tr,
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'openai_pleaseEnterBaseUrl'.tr;
                }
                if (!value.startsWith('http://') &&
                    !value.startsWith('https://')) {
                  return 'openai_baseUrlError'.tr;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _defaultModelController,
                    decoration: InputDecoration(
                      labelText: '默认模型',
                      hintText: '选择此服务商的默认模型',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _selectDefaultModel,
                  tooltip: 'openai_searchModel'.tr,
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Headers',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _headerKeyController,
                            decoration: InputDecoration(
                              labelText:
                                  'openai_headerKey'.tr,
                              hintText:
                                  'openai_enterHeaders'.tr,
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _headerValueController,
                            decoration: InputDecoration(
                              labelText:
                                  'openai_headerValue'.tr,
                              hintText:
                                  'openai_enterHeaders'.tr,
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.add_circle),
                          onPressed: _addHeader,
                          tooltip: 'openai_addHeader'.tr,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _headers.isEmpty
                        ? Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text(
                              'openai_noHeaders'.tr,
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        )
                        : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _headers.length,
                          itemBuilder: (context, index) {
                            final key = _headers.keys.elementAt(index);
                            final value = _headers[key]!;
                            return ListTile(
                              title: Text(key),
                              subtitle: Text(
                                value,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () => _editHeader(key),
                                    tooltip: 'openai_editHeader'.tr,
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete),
                                    onPressed: () => _removeHeader(key),
                                    tooltip: 'openai_deleteHeader'.tr,
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}
