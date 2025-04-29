import 'package:flutter/material.dart';
import '../models/llm_models.dart';
import '../controllers/model_controller.dart';

class ModelListScreen extends StatefulWidget {
  const ModelListScreen({Key? key}) : super(key: key);

  @override
  State<ModelListScreen> createState() => _ModelListScreenState();
}

class _ModelListScreenState extends State<ModelListScreen> with TickerProviderStateMixin {
  TabController? _tabController;
  late List<LLMModelGroup> _modelGroups;
  late ModelController _modelController;
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
      if (mounted) {
        setState(() {
          _modelGroups = models;
          _tabController?.dispose(); // 在创建新的之前释放旧的
          _tabController = TabController(length: _modelGroups.length, vsync: this);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载模型失败: $e')),
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

  List<LLMModel> _getFilteredModels(List<LLMModel> models) {
    if (_searchQuery.isEmpty) {
      return models;
    }
    return models.where((model) => 
      model.name.toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('模型管理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addNewModel,
          ),
        ],
        bottom: _isLoading 
          ? null 
          : PreferredSize(
              preferredSize: const Size.fromHeight(104.0), // 增加高度，为搜索框和TabBar提供足够空间
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: TextField(
                      decoration: const InputDecoration(
                        hintText: '搜索模型...',
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
                  if (_tabController != null) TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    tabs: _modelGroups.map((group) => Tab(text: group.name)).toList(),
                  ),
                ],
              ),
            ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _tabController == null 
          ? const Center(child: Text('无法加载模型列表'))
          : TabBarView(
            controller: _tabController,
            children: _modelGroups.map((group) {
              final filteredModels = _getFilteredModels(group.models);
              return filteredModels.isEmpty
                ? const Center(child: Text('没有找到匹配的模型'))
                : ListView.builder(
                    itemCount: filteredModels.length,
                    itemBuilder: (context, index) {
                      final model = filteredModels[index];
                      return ListTile(
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
      builder: (context) => _ModelEditDialog(
        groups: _modelGroups.map((g) => g.id).toList(),
      ),
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
            SnackBar(content: Text('添加模型失败: $e')),
          );
        }
      }
    }
  }

  Future<void> _editModel(LLMModel model) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _ModelEditDialog(
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
            SnackBar(content: Text('更新模型失败: $e')),
          );
        }
      }
    }
  }

  Future<void> _deleteModel(LLMModel model) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除模型 ${model.name} 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('删除'),
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
            SnackBar(content: Text('删除模型失败: $e')),
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

  const _ModelEditDialog({
    this.model,
    required this.groups,
  });

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
      title: Text(widget.model == null ? '添加模型' : '编辑模型'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.model == null)
                TextFormField(
                  controller: _idController,
                  decoration: const InputDecoration(
                    labelText: '模型ID',
                    hintText: '例如: gpt-4',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '请输入模型ID';
                    }
                    return null;
                  },
                ),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: '模型名称',
                  hintText: '例如: GPT-4',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入模型名称';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedGroup,
                decoration: const InputDecoration(
                  labelText: '模型组',
                ),
                items: widget.groups.map((group) {
                  return DropdownMenuItem(
                    value: group,
                    child: Text(group),
                  );
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
                    return '请选择模型组';
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
          child: const Text('取消'),
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
          child: const Text('保存'),
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