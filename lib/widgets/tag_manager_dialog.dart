import 'package:flutter/material.dart';

/// 标签组数据模型
class TagGroup {
  final String name;
  final List<String> tags;

  TagGroup({required this.name, required this.tags});

  /// 从Map创建TagGroup实例
  factory TagGroup.fromMap(Map<String, dynamic> map) {
    return TagGroup(
      name: map['name'] as String,
      tags: List<String>.from(map['tags'] as List),
    );
  }

  /// 转换为Map
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'tags': tags,
    };
  }

  /// 创建TagGroup副本
  TagGroup copyWith({
    String? name,
    List<String>? tags,
  }) {
    return TagGroup(
      name: name ?? this.name,
      tags: tags ?? List.from(this.tags),
    );
  }
}

/// 标签管理器对话框配置选项
class TagManagerConfig {
  final String title;
  final String addGroupHint;
  final String addTagHint;
  final String editGroupHint;
  final String allTagsLabel;
  final String newGroupLabel;
  final Color? selectedTagColor;
  final Color? checkmarkColor;

  const TagManagerConfig({
    this.title = '标签管理',
    this.addGroupHint = '请输入分组名称',
    this.addTagHint = '请输入标签名称',
    this.editGroupHint = '请输入新的分组名称',
    this.allTagsLabel = '所有标签',
    this.newGroupLabel = '新建分组',
    this.selectedTagColor,
    this.checkmarkColor,
  });
}

/// 标签管理器对话框组件
class TagManagerDialog extends StatefulWidget {
  /// 标签组列表
  final List<TagGroup> groups;
  
  /// 已选中的标签列表
  final List<String> selectedTags;
  
  /// 标签组变更回调
  final Function(List<TagGroup>) onGroupsChanged;
  
  /// 标签选择变更回调
  final Function(List<String>)? onTagsSelected;
  
  /// 对话框配置选项
  final TagManagerConfig? config;
  
  /// 是否允许编辑（新增、修改、删除）
  final bool enableEditing;

  const TagManagerDialog({
    super.key,
    required this.groups,
    required this.selectedTags,
    required this.onGroupsChanged,
    this.onTagsSelected,
    this.config,
    this.enableEditing = true,
  });

  @override
  State<TagManagerDialog> createState() => _TagManagerDialogState();
}

class _TagManagerDialogState extends State<TagManagerDialog> {
  late String _selectedGroup;
  late List<String> _selectedTags;
  late List<TagGroup> _groups;
  late final TagManagerConfig _config;
  
  List<String> get _allTags => _groups.expand((group) => group.tags).toList();

  @override
  void initState() {
    super.initState();
    _groups = List.from(widget.groups);
    _selectedTags = List.from(widget.selectedTags);
    _selectedGroup = widget.config?.allTagsLabel ?? '所有标签';
    _config = widget.config ?? const TagManagerConfig();
  }

  Future<void> _createNewGroup() async {
    if (!widget.enableEditing) return;

    final TextEditingController textController = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('新建分组'),
        content: TextField(
          autofocus: true,
          controller: textController,
          decoration: InputDecoration(hintText: _config.addGroupHint),
          onSubmitted: (value) => Navigator.of(context).pop(value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(textController.text),
            child: const Text('确定'),
          ),
        ],
      ),
    );

    if (name != null && name.isNotEmpty) {
      setState(() {
        _groups.add(TagGroup(name: name, tags: []));
        _selectedGroup = name;
      });
      widget.onGroupsChanged(_groups);
    }
  }

  Future<void> _addNewTag() async {
    if (!widget.enableEditing || _selectedGroup == _config.newGroupLabel) return;

    final TextEditingController textController = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('新建标签'),
        content: TextField(
          autofocus: true,
          controller: textController,
          decoration: InputDecoration(hintText: _config.addTagHint),
          onSubmitted: (value) => Navigator.of(context).pop(value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(textController.text),
            child: const Text('确定'),
          ),
        ],
      ),
    );

    if (name != null && name.isNotEmpty) {
      setState(() {
        final groupIndex = _groups.indexWhere((g) => g.name == _selectedGroup);
        if (groupIndex != -1) {
          if (!_groups[groupIndex].tags.contains(name)) {
            final currentTags = List<String>.from(_groups[groupIndex].tags);
            currentTags.add(name);
            _groups[groupIndex] = TagGroup(
              name: _selectedGroup,
              tags: currentTags,
            );
            widget.onGroupsChanged(_groups);
          }
        }
      });
    }
  }

  Future<void> _editCurrentGroup() async {
    if (!widget.enableEditing) return;
    
    final currentGroup = _groups.firstWhere(
      (group) => group.name == _selectedGroup,
    );

    final TextEditingController textController = TextEditingController(
      text: currentGroup.name,
    );

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('编辑分组'),
        content: TextField(
          autofocus: true,
          controller: textController,
          decoration: InputDecoration(hintText: _config.editGroupHint),
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.of(context).pop({'action': 'delete'}),
            child: const Text('删除分组'),
          ),
          const Spacer(),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop({
              'action': 'rename',
              'name': textController.text
            }),
            child: const Text('确定'),
          ),
        ],
      ),
    );

    if (result != null) {
      if (result['action'] == 'delete') {
        _deleteCurrentGroup();
      } else if (result['action'] == 'rename' &&
          result['name'] != null &&
          result['name'].isNotEmpty) {
        setState(() {
          final index = _groups.indexWhere((g) => g.name == _selectedGroup);
          if (index != -1) {
            _groups[index] = TagGroup(
              name: result['name'],
              tags: _groups[index].tags,
            );
            _selectedGroup = result['name'];
            widget.onGroupsChanged(_groups);
          }
        });
      }
    }
  }

  void _onTagToggle(String tag) {
    setState(() {
      if (_selectedTags.contains(tag)) {
        _selectedTags.remove(tag);
      } else {
        _selectedTags.add(tag);
      }
    });
    widget.onTagsSelected?.call(_selectedTags);
  }

  void _deleteCurrentGroup() {
    if (!widget.enableEditing || _selectedGroup == _config.newGroupLabel) return;

    setState(() {
      _groups.removeWhere((group) => group.name == _selectedGroup);
      if (_groups.isEmpty) {
        _selectedGroup = _config.newGroupLabel;
      } else {
        _selectedGroup = _groups[0].name;
      }
      widget.onGroupsChanged(_groups);
    });
  }

  void _deleteSelectedTags() {
    if (!widget.enableEditing || _selectedGroup == _config.newGroupLabel) return;

    setState(() {
      final groupIndex = _groups.indexWhere((g) => g.name == _selectedGroup);
      if (groupIndex != -1) {
        final currentTags = List<String>.from(_groups[groupIndex].tags);
        currentTags.removeWhere((tag) => _selectedTags.contains(tag));
        _groups[groupIndex] = TagGroup(name: _selectedGroup, tags: currentTags);
        _selectedTags.clear();
        widget.onGroupsChanged(_groups);
        widget.onTagsSelected?.call(_selectedTags);
      }
    });
  }

  List<String> _getCurrentGroupTags() {
    if (_selectedGroup == _config.allTagsLabel) {
      return _allTags;
    }
    final currentGroup = _groups.firstWhere(
      (group) => group.name == _selectedGroup,
      orElse: () => TagGroup(name: _config.newGroupLabel, tags: []),
    );
    return currentGroup.tags;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                DropdownButton<String>(
                  value: _selectedGroup,
                  items: [
                    DropdownMenuItem(
                      value: _config.allTagsLabel,
                      child: Text(_config.allTagsLabel),
                    ),
                    if (widget.enableEditing)
                      DropdownMenuItem(
                        value: _config.newGroupLabel,
                        child: Text(_config.newGroupLabel),
                      ),
                    ..._groups.map(
                      (group) => DropdownMenuItem(
                        value: group.name,
                        child: Text(group.name),
                      ),
                    ),
                  ],
                  onChanged: (String? value) {
                    if (value != null) {
                      if (value == _config.newGroupLabel) {
                        _createNewGroup();
                      } else {
                        setState(() {
                          _selectedGroup = value;
                          if (value != _config.allTagsLabel) {
                            _selectedTags.clear();
                            widget.onTagsSelected?.call(_selectedTags);
                          }
                        });
                      }
                    }
                  },
                ),
                if (widget.enableEditing)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: _selectedGroup == _config.newGroupLabel ||
                                _selectedGroup == _config.allTagsLabel
                            ? null
                            : _addNewTag,
                        tooltip: '添加新标签',
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: _selectedGroup == _config.newGroupLabel ||
                                _selectedGroup == _config.allTagsLabel
                            ? null
                            : _editCurrentGroup,
                        tooltip: '编辑分组',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: _selectedGroup == _config.newGroupLabel ||
                                _selectedGroup == _config.allTagsLabel ||
                                _selectedTags.isEmpty
                            ? null
                            : _deleteSelectedTags,
                        tooltip: '删除选中的标签',
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _getCurrentGroupTags().map((tag) {
                final isSelected = _selectedTags.contains(tag);
                return FilterChip(
                  label: Text(tag),
                  selected: isSelected,
                  onSelected: (_) => _onTagToggle(tag),
                  selectedColor: widget.config?.selectedTagColor ??
                      theme.primaryColor.withOpacity(0.2),
                  checkmarkColor:
                      widget.config?.checkmarkColor ?? theme.primaryColor,
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  onPressed: _selectedTags.isEmpty
                      ? null
                      : () {
                          setState(() {
                            _selectedTags.clear();
                          });
                          widget.onTagsSelected?.call(_selectedTags);
                        },
                  icon: const Icon(Icons.clear_all),
                  label: Text('清空 ${_selectedTags.length} 选中'),
                ),
                Row(
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('取消'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(_selectedTags),
                      child: const Text('确认'),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}