import 'package:Memento/l10n/app_localizations.dart';
import 'package:Memento/plugins/openai/l10n/openai_localizations.dart';
import 'package:flutter/material.dart';
import 'package:Memento/plugins/openai/models/llm_models.dart';
import 'package:Memento/plugins/openai/controllers/model_controller.dart';
import '../../../../core/services/toast_service.dart';

class ModelSearchScreen extends StatefulWidget {
  final String? initialModelId;

  const ModelSearchScreen({super.key, this.initialModelId});

  @override
  State<ModelSearchScreen> createState() => _ModelSearchScreenState();
}

class _ModelSearchScreenState extends State<ModelSearchScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late List<LLMModelGroup> _modelGroups;
  late ModelController _modelController;
  String _searchQuery = '';
  bool _isLoading = true;
  LLMModel? _selectedModel;

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
      setState(() {
        _modelGroups = models;
        _tabController = TabController(
          length: _modelGroups.length,
          vsync: this,
        );
        _isLoading = false;
      });

      if (widget.initialModelId != null) {
        _findInitialModel();
      }
    } catch (e) {
      if (mounted) {
        toastService.showToast(
          '${OpenAILocalizations.of(context).loadModelsFailed}: $e',
        );
      }
      setState(() {
        _modelGroups = [];
        _tabController = TabController(length: 1, vsync: this);
        _isLoading = false;
      });
    }
  }

  void _findInitialModel() {
    for (int i = 0; i < _modelGroups.length; i++) {
      final groupModels = _modelGroups[i].models;
      for (int j = 0; j < groupModels.length; j++) {
        if (groupModels[j].id == widget.initialModelId) {
          _selectedModel = groupModels[j];
          _tabController.animateTo(i);
          break;
        }
      }
      if (_selectedModel != null) break;
    }
  }

  List<LLMModel> _getFilteredModels(List<LLMModel> models) {
    if (_searchQuery.isEmpty) {
      return models;
    }
    return models
        .where(
          (model) =>
              model.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              (model.description?.toLowerCase().contains(
                    _searchQuery.toLowerCase(),
                  ) ??
                  false),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(OpenAILocalizations.of(context).searchModel),
        actions: [
          if (_selectedModel != null)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(_selectedModel);
              },
              child: Text(AppLocalizations.of(context)!.ok),
            ),
        ],
        bottom:
            _isLoading
                ? null
                : PreferredSize(
                  preferredSize: const Size.fromHeight(96.0),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: TextField(
                          decoration: const InputDecoration(
                            hintText: '搜索模型...',
                            prefixIcon: Icon(Icons.search),
                            border: InputBorder.none,
                          ),
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                            });
                          },
                        ),
                      ),
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
                              final isSelected = _selectedModel?.id == model.id;

                              return ListTile(
                                title: Text(model.name),
                                subtitle:
                                    model.description != null
                                        ? Text(model.description!)
                                        : null,
                                trailing:
                                    isSelected
                                        ? const Icon(
                                          Icons.check_circle,
                                          color: Colors.green,
                                        )
                                        : null,
                                selected: isSelected,
                                onTap: () {
                                  setState(() {
                                    _selectedModel = model;
                                  });
                                },
                                onLongPress: () {
                                  if (model.url != null) {
                                    // 显示模型详情
                                    showDialog(
                                      context: context,
                                      builder:
                                          (context) => AlertDialog(
                                            title: Text(model.name),
                                            content: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                if (model.description != null)
                                                  Text(
                                                    '描述: ${model.description}',
                                                  ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  '${OpenAILocalizations.of(context).modelUrlLabel}: ${model.url}',
                                                ),
                                              ],
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed:
                                                    () =>
                                                        Navigator.of(
                                                          context,
                                                        ).pop(),
                                                child: Text(
                                                  OpenAILocalizations.of(
                                                    context,
                                                  ).close,
                                                ),
                                              ),
                                            ],
                                          ),
                                    );
                                  }
                                },
                              );
                            },
                          );
                    }).toList(),
              ),
      floatingActionButton:
          _selectedModel != null
              ? FloatingActionButton(
                onPressed: () {
                  Navigator.of(context).pop(_selectedModel);
                },
                child: const Icon(Icons.check),
              )
              : null,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
