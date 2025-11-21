import 'package:Memento/plugins/openai/l10n/openai_localizations.dart';
import 'package:flutter/material.dart';
import '../models/service_provider.dart';
import '../models/llm_models.dart';
import '../controllers/provider_controller.dart';
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
    final selectedModel = await Navigator.push<LLMModel>(
      context,
      MaterialPageRoute(
        builder: (context) => ModelSearchScreen(
          initialModelId: _defaultModelController.text,
        ),
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
          DateTime.now().millisecondsSinceEpoch.toString(),
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
        title: Text(OpenAILocalizations.of(context).unsavedChangesTitle),
        content: Text(OpenAILocalizations.of(context).unsavedHeaderWarning),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(OpenAILocalizations.of(context).cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(OpenAILocalizations.of(context).discard),
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
                ? OpenAILocalizations.of(context).addProvider
                : OpenAILocalizations.of(context).editProvider,
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveProvider,
              tooltip: OpenAILocalizations.of(context).saveTooltip,
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
                labelText: OpenAILocalizations.of(context).serviceProvider,
                hintText: OpenAILocalizations.of(context).pleaseSelectProvider,
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return OpenAILocalizations.of(context).providerLabelError;
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
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return OpenAILocalizations.of(context).pleaseEnterBaseUrl;
                }
                if (!value.startsWith('http://') &&
                    !value.startsWith('https://')) {
                  return OpenAILocalizations.of(context).baseUrlError;
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
                  tooltip: OpenAILocalizations.of(context).searchModel,
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
                                  OpenAILocalizations.of(context).headerKey,
                              hintText:
                                  OpenAILocalizations.of(context).enterHeaders,
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
                                  OpenAILocalizations.of(context).headerValue,
                              hintText:
                                  OpenAILocalizations.of(context).enterHeaders,
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.add_circle),
                          onPressed: _addHeader,
                          tooltip: OpenAILocalizations.of(context).addHeader,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _headers.isEmpty
                        ? Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text(
                              OpenAILocalizations.of(context).noHeaders,
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
                                    tooltip:
                                        OpenAILocalizations.of(
                                          context,
                                        ).editHeader,
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete),
                                    onPressed: () => _removeHeader(key),
                                    tooltip:
                                        OpenAILocalizations.of(
                                          context,
                                        ).deleteHeader,
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
