import 'package:get/get.dart';

import 'package:flutter/material.dart';
import 'package:Memento/widgets/super_cupertino_navigation_wrapper.dart';
import 'package:Memento/widgets/super_cupertino_navigation_wrapper/index.dart';
import 'package:Memento/widgets/preset_edit_form.dart';
import 'package:Memento/plugins/openai/models/prompt_preset.dart';
import 'package:Memento/plugins/openai/services/prompt_preset_service.dart';

class PromptPresetScreen extends StatefulWidget {
  const PromptPresetScreen({super.key});

  @override
  State<PromptPresetScreen> createState() => _PromptPresetScreenState();
}

class _PromptPresetScreenState extends State<PromptPresetScreen> {
  late final PromptPresetService _service;
  List<PromptPreset> _filteredPresets = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _service = PromptPresetService();

    // 加载预设数据
    _loadPresets();
  }

  Future<void> _loadPresets() async {
    setState(() {
      _isLoading = true;
    });

    await _service.loadPresets();

    if (mounted) {
      setState(() {
        _isLoading = false;
        _filteredPresets = _service.presets;
      });
    }
  }

  /// 构建过滤条件列表
  List<FilterItem> _buildFilterItems() {
    // 获取所有可用标签
    final allTags = <String>{};
    for (final preset in _service.presets) {
      allTags.addAll(preset.tags);
    }

    return [
      // 标签过滤
      FilterItem(
        id: 'tags',
        title: 'openai_tags'.tr,
        type: FilterType.tagsMultiple,
        builder: (context, currentValue, onChanged) {
          return FilterBuilders.buildTagsFilter(
            context: context,
            currentValue: currentValue,
            onChanged: onChanged,
            availableTags: allTags.toList(),
          );
        },
        getBadge: FilterBuilders.tagsBadge,
      ),
    ];
  }

  /// 应用过滤条件
  void _applyFilters(Map<String, dynamic> filters) {
    List<PromptPreset> result = [..._service.presets];

    // 标签过滤
    if (filters['tags'] != null && (filters['tags'] as List).isNotEmpty) {
      final selectedTags = filters['tags'] as List<String>;
      result =
          result.where((preset) {
            return selectedTags.any((tag) => preset.tags.contains(tag));
          }).toList();
    }

    setState(() {
      _filteredPresets = result;
    });
  }

  /// 处理搜索
  void _handleSearch(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredPresets = _service.presets;
      });
      return;
    }

    final keyword = query.toLowerCase();
    final filteredBySearch =
        _service.presets.where((preset) {
          return preset.name.toLowerCase().contains(keyword) ||
              preset.description.toLowerCase().contains(keyword) ||
              preset.content.toLowerCase().contains(keyword);
        }).toList();

    setState(() {
      _filteredPresets = filteredBySearch;
    });
  }

  /// 显示编辑对话框
  Future<void> _showEditDialog({PromptPreset? preset}) async {
    await showPresetEditDialog(
      context: context,
      preset: preset,
      onSave: (newPreset, prompts) async {
        // 确保 prompts 正确设置到 preset 中
        final updatedPreset = newPreset.copyWith(prompts: prompts);

        // 保存包含 prompts 的预设
        if (preset == null) {
          await _service.addPreset(updatedPreset);
        } else {
          await _service.updatePreset(updatedPreset);
        }
        // 重新加载以获取最新的 prompts 数据
        await _loadPresets();
      },
    );
  }

  /// 删除预设
  Future<void> _deletePreset(PromptPreset preset) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('openai_deletePreset'.tr),
            content: Text('openai_confirmDeletePreset'.tr),
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

    if (confirmed == true) {
      await _service.deletePreset(preset.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SuperCupertinoNavigationWrapper(
      title: Text('openai_promptPresetManagement'.tr),
      largeTitle: 'openai_promptPresetManagement'.tr,
      enableLargeTitle: false,

      // 启用多条件过滤
      enableMultiFilter: true,
      multiFilterItems: _buildFilterItems(),
      onMultiFilterChanged: _applyFilters,

      // 启用搜索栏
      enableSearchBar: true,
      onSearchChanged: _handleSearch,

      actions: [
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: () => _showEditDialog(),
        ),
      ],
      body: AnimatedBuilder(
        animation: _service,
        builder: (context, _) {
          if (_isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_service.presets.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.text_snippet_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'openai_noPresetsYet'.tr,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'openai_createFirstPreset'.tr,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _showEditDialog(),
                    icon: const Icon(Icons.add),
                    label: Text('openai_addPreset'.tr),
                  ),
                ],
              ),
            );
          }

          if (_filteredPresets.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.search_off, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'openai_noMatchingPresets'.tr,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'openai_tryAdjustingFilters'.tr,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _filteredPresets.length,
            itemBuilder: (context, index) {
              final preset = _filteredPresets[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text(
                    preset.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (preset.description.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            preset.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      if (preset.tags.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            children:
                                preset.tags
                                    .map(
                                      (tag) => Chip(
                                        label: Text(
                                          tag,
                                          style: const TextStyle(fontSize: 10),
                                        ),
                                        materialTapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                        visualDensity: VisualDensity.compact,
                                        padding: EdgeInsets.zero,
                                      ),
                                    )
                                    .toList(),
                          ),
                        ),
                    ],
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'edit') {
                        await _showEditDialog(preset: preset);
                      } else if (value == 'delete') {
                        await _deletePreset(preset);
                      }
                    },
                    itemBuilder:
                        (context) => [
                          PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                const Icon(Icons.edit, size: 20),
                                const SizedBox(width: 8),
                                Text('openai_editPreset'.tr),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.delete,
                                  size: 20,
                                  color: Colors.red,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'openai_deletePreset'.tr,
                                  style: const TextStyle(color: Colors.red),
                                ),
                              ],
                            ),
                          ),
                        ],
                  ),
                  onTap: () => _showEditDialog(preset: preset),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
