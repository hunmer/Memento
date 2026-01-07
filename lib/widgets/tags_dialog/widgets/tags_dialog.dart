import 'package:flutter/material.dart';
import 'package:Memento/widgets/super_cupertino_navigation_wrapper.dart';
import 'package:Memento/widgets/super_cupertino_navigation_wrapper/filter_models.dart';
import '../models/models.dart';
import 'tags_list.dart';
import 'bottom_sheet_menu.dart';
import '../utils/json_storage.dart';

/// 标签管理对话框
///
/// 支持的功能：
/// - 传入 JSON 文件路径自动读取/保存
/// - 或直接传入分组和标签数据
/// - 搜索功能（标题、注释搜索）
/// - 多条件过滤（分组过滤、排序）
/// - 长按弹出底部抽屉（编辑、删除）
/// - 批量编辑功能
/// - 单击选择模式（单选/多选）
/// - 嵌入/对话框两种显示模式
class TagsDialog extends StatefulWidget {
  /// JSON 文件路径（传入后自动读取/保存）
  final String? jsonFilePath;

  /// 标签分组列表（支持新格式 TagGroupWithTags 或旧格式 TagGroup）
  final List<dynamic>? groups;

  /// 已选择的标签名称列表
  final List<String> selectedTags;

  /// 配置选项
  final TagsDialogConfig config;

  /// 显示模式
  final TagsDisplayMode displayMode;

  /// 标签选择变更回调
  final Function(List<String>)? onTagsSelected;

  /// 标签分组变更回调
  final Function(List<TagGroupWithTags>)? onGroupsChanged;

  /// 添加标签回调
  final Future<TagItem?> Function(String group, {TagItem? tag})? onAddTag;

  /// 删除标签回调
  final Future<bool> Function(TagItem tag)? onDeleteTag;

  /// 编辑标签回调
  final Future<TagItem?> Function(TagItem oldTag, TagItem newTag)? onEditTag;

  const TagsDialog({
    super.key,
    this.jsonFilePath,
    this.groups,
    this.selectedTags = const [],
    this.config = const TagsDialogConfig(),
    this.displayMode = TagsDisplayMode.dialog,
    this.onTagsSelected,
    this.onGroupsChanged,
    this.onAddTag,
    this.onDeleteTag,
    this.onEditTag,
  });

  /// 兼容旧版 TagGroup 的工厂构造函数
  factory TagsDialog.fromLegacy({
    Key? key,
    required List<dynamic> legacyGroups,
    List<String> selectedTags = const [],
    TagsDialogConfig config = const TagsDialogConfig(),
    TagsDisplayMode displayMode = TagsDisplayMode.dialog,
    Function(List<String>)? onTagsSelected,
    Function(List<TagGroupWithTags>)? onGroupsChanged,
    Future<TagItem?> Function(String group, {TagItem? tag})? onAddTag,
    Future<bool> Function(TagItem tag)? onDeleteTag,
    Future<TagItem?> Function(TagItem oldTag, TagItem newTag)? onEditTag,
  }) {
    return TagsDialog(
      key: key,
      groups: legacyGroups,
      selectedTags: selectedTags,
      config: config,
      displayMode: displayMode,
      onTagsSelected: onTagsSelected,
      onGroupsChanged: onGroupsChanged,
      onAddTag: onAddTag,
      onDeleteTag: onDeleteTag,
      onEditTag: onEditTag,
    );
  }

  @override
  State<TagsDialog> createState() => _TagsDialogState();

  /// 显示对话框
  static Future<List<String>?> show(
    BuildContext context, {
    String? jsonFilePath,
    List<dynamic>? groups, // 支持新格式 TagGroupWithTags 或旧格式 TagGroup
    List<String> selectedTags = const [],
    TagsDialogConfig config = const TagsDialogConfig(),
    Function(List<TagGroupWithTags>)? onGroupsChanged,
    Future<TagItem?> Function(String group, {TagItem? tag})? onAddTag,
    Future<bool> Function(TagItem tag)? onDeleteTag,
    Future<TagItem?> Function(TagItem oldTag, TagItem newTag)? onEditTag,
  }) {
    return showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TagsDialog(
        jsonFilePath: jsonFilePath,
        groups: groups,
        selectedTags: selectedTags,
        config: config,
        onGroupsChanged: onGroupsChanged,
        onAddTag: onAddTag,
        onDeleteTag: onDeleteTag,
        onEditTag: onEditTag,
      ),
    );
  }
}

class _TagsDialogState extends State<TagsDialog> {
  /// 标签分组列表
  late List<TagGroupWithTags> _groups;

  /// 已选择的标签
  List<String> _selectedTags = [];

  /// 搜索关键词
  String _searchQuery = '';

  /// 多条件过滤状态
  late MultiFilterState _filterState;

  /// 是否批量编辑模式
  bool _isBatchEditMode = false;

  /// JSON 存储工具
  JsonStorage? _jsonStorage;

  @override
  void initState() {
    super.initState();
    _filterState = MultiFilterState();
    _initializeData();
  }

  /// 初始化数据
  Future<void> _initializeData() async {
    _selectedTags = List.from(widget.selectedTags);

    // 优先使用 JSON 文件
    if (widget.jsonFilePath != null) {
      _jsonStorage = JsonStorage(widget.jsonFilePath!);
      final loadedGroups = await _jsonStorage!.load();
      if (loadedGroups != null) {
        _groups = loadedGroups;
        return;
      }
    }

    // 使用传入的分组数据（支持新旧格式）
    if (widget.groups != null && widget.groups!.isNotEmpty) {
      _groups = _convertGroupsToNewFormat(widget.groups!);
    } else {
      _groups = [];
    }

    setState(() {});
  }

  /// 转换分组数据为新格式（兼容旧版 TagGroup）
  List<TagGroupWithTags> _convertGroupsToNewFormat(List<dynamic> groups) {
    return groups.map((group) {
      // 如果已经是新格式，直接返回
      if (group is TagGroupWithTags) {
        return group;
      }
      // 否则使用兼容性方法转换
      return TagGroupWithTags.fromLegacyTagGroup(group);
    }).toList();
  }

  /// 获取过滤后的标签列表
  List<TagItem> get _filteredTags {
    List<TagItem> result = [];

    // 按分组收集所有标签
    for (var group in _groups) {
      result.addAll(group.tags);
    }

    // 搜索过滤
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      result = result.where((tag) {
        return tag.name.toLowerCase().contains(query) ||
            (tag.comment?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    // 分组过滤
    final selectedGroup = _filterState.getValue('group') as String?;
    if (selectedGroup != null && selectedGroup.isNotEmpty) {
      result = result.where((tag) => tag.group == selectedGroup).toList();
    }

    // 排序
    final sortType = _filterState.getValue('sort') as TagsSortType? ??
        TagsSortType.createdAt;
    result = _sortTags(result, sortType);

    return result;
  }

  /// 排序标签
  List<TagItem> _sortTags(List<TagItem> tags, TagsSortType sortType) {
    switch (sortType) {
      case TagsSortType.createdAt:
        return tags..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case TagsSortType.lastUsedAt:
        return tags..sort((a, b) {
          final aTime = a.lastUsedAt ?? a.createdAt;
          final bTime = b.lastUsedAt ?? b.createdAt;
          return bTime.compareTo(aTime);
        });
      case TagsSortType.name:
        return tags..sort((a, b) => a.name.compareTo(b.name));
    }
  }

  /// 保存数据
  Future<void> _saveData() async {
    // 保存到 JSON 文件
    if (_jsonStorage != null) {
      await _jsonStorage!.save(_groups);
    }

    // 回调通知
    widget.onGroupsChanged?.call(_groups);
  }

  /// 搜索变更
  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  /// 过滤变更
  void _onFilterChanged(Map<String, dynamic> filters) {
    setState(() {
      _filterState.initializeFromMap(filters);
    });
  }

  /// 切换批量编辑模式
  void _toggleBatchEditMode() {
    setState(() {
      _isBatchEditMode = !_isBatchEditMode;
      if (!_isBatchEditMode) {
        _selectedTags.clear();
      }
    });
  }

  /// 选择标签
  void _selectTag(String tagName) {
    setState(() {
      switch (widget.config.selectionMode) {
        case TagsSelectionMode.single:
          _selectedTags = [tagName];
          break;
        case TagsSelectionMode.multiple:
          if (_selectedTags.contains(tagName)) {
            _selectedTags.remove(tagName);
          } else {
            _selectedTags.add(tagName);
          }
          break;
        case TagsSelectionMode.none:
          break;
      }
      widget.onTagsSelected?.call(_selectedTags);
    });
  }

  /// 显示标签底部抽屉
  void _showTagBottomSheet(TagItem tag) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => BottomSheetMenu(
        tag: tag,
        onEdit: () => _editTag(tag),
        onDelete: () => _deleteTag(tag),
        config: widget.config,
      ),
    );
  }

  /// 编辑标签
  Future<void> _editTag(TagItem oldTag) async {
    if (widget.onEditTag != null) {
      final newTag = await widget.onEditTag!(oldTag, oldTag);
      if (newTag != null) {
        setState(() {
          for (var group in _groups) {
            final index = group.tags.indexWhere((t) => t.name == oldTag.name);
            if (index != -1) {
              group.tags[index] = newTag;
              break;
            }
          }
        });
        await _saveData();
      }
    }
  }

  /// 删除标签
  Future<void> _deleteTag(TagItem tag) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('确认删除'),
        content: Text('确定要删除标签「${tag.name}」吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (widget.onDeleteTag != null) {
        final success = await widget.onDeleteTag!(tag);
        if (success) {
          setState(() {
            for (var group in _groups) {
              group.tags.removeWhere((t) => t.name == tag.name);
            }
            _selectedTags.remove(tag.name);
          });
          await _saveData();
        }
      } else {
        setState(() {
          for (var group in _groups) {
            group.tags.removeWhere((t) => t.name == tag.name);
          }
          _selectedTags.remove(tag.name);
        });
        await _saveData();
      }
    }
  }

  /// 批量删除选中的标签
  Future<void> _batchDeleteSelected() async {
    if (_selectedTags.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('确认删除'),
        content: Text('确定要删除选中的 ${_selectedTags.length} 个标签吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        for (var tagName in _selectedTags) {
          for (var group in _groups) {
            group.tags.removeWhere((t) => t.name == tagName);
          }
        }
        _selectedTags.clear();
        _isBatchEditMode = false;
      });
      await _saveData();
    }
  }

  /// 添加标签
  Future<void> _addTag(String group) async {
    if (widget.onAddTag != null) {
      final newTag = await widget.onAddTag!(group);
      if (newTag != null) {
        setState(() {
          final groupIndex = _groups.indexWhere((g) => g.name == group);
          if (groupIndex != -1) {
            _groups[groupIndex].tags.add(newTag);
          } else {
            _groups.add(TagGroupWithTags(name: group, tags: [newTag]));
          }
        });
        await _saveData();
      }
    }
  }

  /// 确认选择
  void _confirmSelection() {
    Navigator.of(context).pop(_selectedTags);
  }

  @override
  Widget build(BuildContext context) {
    final content = _buildContent();

    if (widget.displayMode == TagsDisplayMode.dialog) {
      return Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: content,
      );
    }

    return content;
  }

  Widget _buildContent() {
    // 构建多条件过滤项
    final filterItems = _buildFilterItems();

    return SuperCupertinoNavigationWrapper(
      title: Text(widget.config.title),
      largeTitle: widget.config.largeTitle,
      enableLargeTitle: true,
      enableSearchBar: true,
      searchPlaceholder: widget.config.searchPlaceholder,
      onSearchChanged: _onSearchChanged,
      enableMultiFilter: true,
      multiFilterItems: filterItems,
      multiFilterBarHeight: 50,
      onMultiFilterChanged: _onFilterChanged,
      multiFilterToggleable: true,
      actions: _buildActions(),
      body: TagsList(
        tags: _filteredTags,
        selectedTags: _selectedTags,
        isBatchEditMode: _isBatchEditMode,
        config: widget.config,
        selectionMode: widget.config.selectionMode,
        onSelectTag: _selectTag,
        onLongPress: widget.config.enableLongPressMenu
            ? _showTagBottomSheet
            : null,
        onDeleteTap: _batchDeleteSelected,
        onAddTag: widget.config.enableEditing ? _addTag : null,
      ),
    );
  }

  /// 构建操作按钮
  List<Widget> _buildActions() {
    final actions = <Widget>[];

    // 批量编辑按钮
    if (widget.config.enableBatchEdit) {
      actions.add(
        IconButton(
          icon: Icon(_isBatchEditMode ? Icons.close : Icons.edit),
          tooltip: _isBatchEditMode ? '退出批量编辑' : '批量编辑',
          onPressed: _toggleBatchEditMode,
        ),
      );
    }

    // 添加标签按钮
    if (widget.config.enableEditing) {
      actions.add(
        IconButton(
          icon: Icon(Icons.add),
          tooltip: widget.config.addTagText,
          onPressed: () => _showAddTagDialog(),
        ),
      );
    }

    // 确认按钮（选择模式下）
    if (widget.config.selectionMode != TagsSelectionMode.none &&
        _selectedTags.isNotEmpty) {
      actions.add(
        TextButton(
          onPressed: _confirmSelection,
          child: Text('${widget.config.confirmButtonText}(${_selectedTags.length})'),
        ),
      );
    }

    return actions;
  }

  /// 显示添加标签对话框
  void _showAddTagDialog() {
    // 获取所有分组
    final groups = _groups.map((g) => g.name).toList();

    showDialog(
      context: context,
      builder: (context) => _AddTagDialog(
        groups: groups,
        onConfirm: (groupName, tagName, comment) async {
          await _addTag(groupName);
        },
      ),
    );
  }

  /// 构建过滤项
  List<FilterItem> _buildFilterItems() {
    final groups = _groups.map((g) => g.name).toList();

    return [
      // 分组过滤
      FilterItem(
        id: 'group',
        title: '分组',
        type: FilterType.tagsSingle,
        builder: (context, value, onChanged) {
          return Wrap(
            spacing: 8,
            children: [
              FilterChip(
                label: Text('全部'),
                selected: value == null || value == '',
                onSelected: (selected) {
                  if (selected) onChanged('');
                },
              ),
              ...groups.map((group) {
                return FilterChip(
                  label: Text(group),
                  selected: value == group,
                  onSelected: (selected) {
                    if (selected) onChanged(group);
                  },
                );
              }),
            ],
          );
        },
        getBadge: (value) {
          if (value == null || value == '') return null;
          return value as String;
        },
      ),

      // 排序方式
      FilterItem(
        id: 'sort',
        title: '排序',
        type: FilterType.tagsSingle,
        initialValue: TagsSortType.createdAt,
        builder: (context, value, onChanged) {
          return Wrap(
            spacing: 8,
            children: TagsSortType.values.map((type) {
              final label = switch (type) {
                TagsSortType.createdAt => '添加时间',
                TagsSortType.lastUsedAt => '使用时间',
                TagsSortType.name => '名称',
              };
              return FilterChip(
                label: Text(label),
                selected: value == type,
                onSelected: (selected) {
                  if (selected) onChanged(type);
                },
              );
            }).toList(),
          );
        },
        getBadge: (value) {
          if (value == null) return null;
          final type = value as TagsSortType;
          return switch (type) {
            TagsSortType.createdAt => '添加时间',
            TagsSortType.lastUsedAt => '使用时间',
            TagsSortType.name => '名称',
          };
        },
      ),
    ];
  }
}

/// 添加标签对话框
class _AddTagDialog extends StatefulWidget {
  final List<String> groups;
  final Function(String group, String name, String comment) onConfirm;

  const _AddTagDialog({
    required this.groups,
    required this.onConfirm,
  });

  @override
  State<_AddTagDialog> createState() => _AddTagDialogState();
}

class _AddTagDialogState extends State<_AddTagDialog> {
  final _nameController = TextEditingController();
  final _commentController = TextEditingController();
  String _selectedGroup = 'default';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('添加标签'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: '标签名称',
              border: OutlineInputBorder(),
            ),
          ),
          SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedGroup,
            decoration: InputDecoration(
              labelText: '分组',
              border: OutlineInputBorder(),
            ),
            items: widget.groups.map((group) {
              return DropdownMenuItem(
                value: group,
                child: Text(group),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedGroup = value ?? 'default';
              });
            },
          ),
          SizedBox(height: 16),
          TextField(
            controller: _commentController,
            decoration: InputDecoration(
              labelText: '注释（可选）',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('取消'),
        ),
        TextButton(
          onPressed: () {
            if (_nameController.text.isNotEmpty) {
              widget.onConfirm(
                _selectedGroup,
                _nameController.text,
                _commentController.text,
              );
              Navigator.pop(context);
            }
          },
          child: Text('确定'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _commentController.dispose();
    super.dispose();
  }
}
