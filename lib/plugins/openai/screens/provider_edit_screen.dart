import 'package:flutter/material.dart';
import '../models/service_provider.dart';
import '../controllers/provider_controller.dart';

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
    }
  }

  @override
  void dispose() {
    _labelController.dispose();
    _baseUrlController.dispose();
    _headerKeyController.dispose();
    _headerValueController.dispose();
    super.dispose();
  }

  void _addHeader() {
    final key = _headerKeyController.text.trim();
    final value = _headerValueController.text.trim();
    
    if (key.isEmpty) {
      _showErrorSnackBar('Header 键不能为空');
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

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _saveProvider() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final controller = ProviderController();
    
    final provider = ServiceProvider(
      id: widget.provider?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      label: _labelController.text.trim(),
      baseUrl: _baseUrlController.text.trim(),
      headers: _headers,
    );

    try {
      if (widget.provider == null) {
        await controller.addProvider(provider);
      } else {
        await controller.updateProvider(provider);
      }
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      _showErrorSnackBar('保存服务商失败: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.provider == null ? '添加服务商' : '编辑服务商'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveProvider,
            tooltip: '保存',
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
              decoration: const InputDecoration(
                labelText: '服务商名称',
                hintText: '例如：OpenAI, Azure OpenAI',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '请输入服务商名称';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _baseUrlController,
              decoration: const InputDecoration(
                labelText: 'API 基础 URL',
                hintText: '例如：https://api.openai.com/v1',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '请输入 API 基础 URL';
                }
                if (!value.startsWith('http://') && !value.startsWith('https://')) {
                  return 'URL 必须以 http:// 或 https:// 开头';
                }
                return null;
              },
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
                            decoration: const InputDecoration(
                              labelText: 'Key',
                              hintText: '例如：Authorization',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _headerValueController,
                            decoration: const InputDecoration(
                              labelText: 'Value',
                              hintText: '例如：Bearer YOUR_API_KEY',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.add_circle),
                          onPressed: _addHeader,
                          tooltip: '添加 Header',
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _headers.isEmpty
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Text(
                                '没有 Headers',
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
                                      tooltip: '编辑',
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete),
                                      onPressed: () => _removeHeader(key),
                                      tooltip: '删除',
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
    );
  }
}