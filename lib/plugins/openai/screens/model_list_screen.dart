import 'package:flutter/material.dart';
import '../models/llm_models.dart';
import '../controllers/model_controller.dart';
import '../l10n/openai_localizations.dart';

class ModelListScreen extends StatefulWidget {
  const ModelListScreen({super.key});

  @override
  State<ModelListScreen> createState() => _ModelListScreenState();
}

class _ModelListScreenState extends State<ModelListScreen>
    with TickerProviderStateMixin {
  TabController? _tabController;
  late List<LLMModelGroup> _modelGroups;
  late ModelController _modelController;
  final Map<String, String> _defaultModels = {};
  String _searchQuery = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _modelController = ModelController();
    _loadModels();
  }

  Future<void> _loadModels() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final models = await _modelController.getModels();
      // 加载每个分组的默认模型
      for (final group in models) {
        final defaultModel = await _modelController.getDefaultModel(group.id);
        if (defaultModel != null) {
          _defaultModels[group.id] = defaultModel;
        }
      }
      if (mounted) {
        setState(() {
          _modelGroups = models;
          _tabController?.dispose(); // 在创建新的之前释放旧的
          _tabController = TabController(
            length: _modelGroups.length,
            vsync: this,
          );
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${OpenAILocalizations.of(context).loadModelsFailed}: $e',
            ),
          ),
        );
        setState(() {
          _modelGroups = [];
          _tabController?.dispose(); // 在创建新的之前释放旧的
          _tabController = TabController(length: 1, vsync: this);
          _isLoading = false;
        });
      }
    }
  }

  String? _getDefaultModelForGroup(String groupId) {
    return _defaultModels[groupId];
  }

  Future<void> _setDefaultModel(String groupId, String modelId) async {
    try {
      await _modelController.setDefaultModel(groupId, modelId);
      setState(() {
        _defaultModels[groupId] = modelId;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已设置默认模型: $modelId')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('设置默认模型失败: $e')),
        );
      }
    }
  }

  List<LLMModel> _getFilteredModels(List<LLMModel> models) {
    if (_searchQuery.isEmpty) {
      return models;
    }
    return models
        .where(
          (model) =>
              model.name.toLowerCase().contains(_searchQuery.toLowerCase()),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(OpenAILocalizations.of(context).modelManagement),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: _addNewModel),
        ],
        bottom:
            _isLoading
                ? null
                : PreferredSize(
                  preferredSize: const Size.fromHeight(
                    104.0,
                  ), // 增加高度，为搜索框和TabBar提供足够空间
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 8.0,
                        ),
                        child: TextField(
                          decoration: InputDecoration(
                            hintText:
                                OpenAILocalizations.of(context).searchModel,
                            prefixIcon: Icon(Icons.search),
                            border: OutlineInputBorder(), // 添加边框使搜索框更明显
                            contentPadding: EdgeInsets.symmetric(vertical: 8.0),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                            });
                          },
                        ),
                      ),
                      if (_tabController != null)
                        TabBar(
                          controller: _tabController,
                          isScrollable: true,
                          tabs:
                              _modelGroups
                                  .map((group) => Tab(text: group.name))
                                  .toList(),
                        ),
                    ],
                  ),
                ),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _tabController == null
              ? Center(
                child: Text(OpenAILocalizations.of(context).cannotLoadModels),
              )
              : TabBarView(
                controller: _tabController,
                children:
                    _modelGroups.map((group) {
                      final filteredModels = _getFilteredModels(group.models);
                      return filteredModels.isEmpty
                          ? Center(
                            child: Text(
                              OpenAILocalizations.of(context).noModelsFound,
                            ),
                          )
                          : ListView.builder(
                            itemCount: filteredModels.length,
                            itemBuilder: (context, index) {
                              final model = filteredModels[index];
                              final isDefault = _getDefaultModelForGroup(group.id) == model.id;
                              return ListTile(
                                leading: IconButton(
                                  icon: Icon(
                                    isDefault ? Icons.star : Icons.star_border,
                                    color: isDefault ? Colors.amber : null,
                                  ),
                                  onPressed: () => _setDefaultModel(group.id, model.id),
                                  tooltip: '设为默认模型',
                                ),
                                title: Text(model.name),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () => _deleteModel(model),
                                ),
                                onTap: () => _editModel(model),
                              );
                            },
                          );
                    }).toList(),
              ),
    );
  }

  Future<void> _addNewModel() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder:
          (context) =>
              _ModelEditDialog(groups: _modelGroups.map((g) => g.id).toList()),
    );

    if (result != null) {
      try {
        final newModel = LLMModel(
          id: result['id'] as String,
          name: result['name'] as String,
          group: result['group'] as String,
        );

        await _modelController.addModel(newModel);
        await _loadModels();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${OpenAILocalizations.of(context).addModelFailed}: $e',
              ),
            ),
          );
        }
      }
    }
  }

  Future<void> _editModel(LLMModel model) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder:
          (context) => _ModelEditDialog(
            model: model,
            groups: _modelGroups.map((g) => g.id).toList(),
          ),
    );

    if (result != null) {
      try {
        final updatedModel = LLMModel(
          id: model.id,
          name: result['name'] as String,
          group: result['group'] as String,
        );

        await _modelController.updateModel(updatedModel);
        await _loadModels();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${OpenAILocalizations.of(context).updateModelFailed}: $e',
              ),
            ),
          );
        }
      }
    }
  }

  Future<void> _deleteModel(LLMModel model) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(OpenAILocalizations.of(context).confirmDelete),
            content: Text(
              OpenAILocalizations.of(
                context,
              ).confirmDeleteModel.replaceAll('{modelName}', model.name),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(OpenAILocalizations.of(context).cancel),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(OpenAILocalizations.of(context).delete),
              ),
            ],
          ),
    );

    if (confirm == true) {
      try {
        await _modelController.deleteModel(model.id);
        await _loadModels();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${OpenAILocalizations.of(context).deleteModelFailed}: $e',
              ),
            ),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }
}

class _ModelEditDialog extends StatefulWidget {
  final LLMModel? model;
  final List<String> groups;

  const _ModelEditDialog({this.model, required this.groups});

  @override
  State<_ModelEditDialog> createState() => _ModelEditDialogState();
}

class _ModelEditDialogState extends State<_ModelEditDialog> {
  final _formKey = GlobalKey<FormState>();
  final _idController = TextEditingController();
  final _nameController = TextEditingController();
  late String _selectedGroup;

  @override
  void initState() {
    super.initState();
    if (widget.model != null) {
      _idController.text = widget.model!.id;
      _nameController.text = widget.model!.name;
      _selectedGroup = widget.model!.group;
    } else {
      _selectedGroup = widget.groups.isNotEmpty ? widget.groups.first : '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.model == null
            ? OpenAILocalizations.of(context).addModel
            : OpenAILocalizations.of(context).editModel,
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.model == null)
                TextFormField(
                  controller: _idController,
                  decoration: InputDecoration(
                    labelText: OpenAILocalizations.of(context).modelId,
                    hintText: OpenAILocalizations.of(context).modelIdExample,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return OpenAILocalizations.of(context).pleaseEnterModelId;
                    }
                    return null;
                  },
                ),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: OpenAILocalizations.of(context).modelName,
                  hintText: OpenAILocalizations.of(context).modelNameExample,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return OpenAILocalizations.of(context).pleaseEnterModelName;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedGroup,
                decoration: InputDecoration(
                  labelText: OpenAILocalizations.of(context).modelGroup,
                ),
                items:
                    widget.groups.map((group) {
                      return DropdownMenuItem(value: group, child: Text(group));
                    }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedGroup = value;
                    });
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return OpenAILocalizations.of(
                      context,
                    ).pleaseSelectModelGroup;
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(OpenAILocalizations.of(context).cancel),
        ),
        TextButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.of(context).pop({
                'id': widget.model?.id ?? _idController.text,
                'name': _nameController.text,
                'group': _selectedGroup,
              });
            }
          },
          child: Text(OpenAILocalizations.of(context).save),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _idController.dispose();
    _nameController.dispose();
    super.dispose();
  }
}
