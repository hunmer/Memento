import 'package:flutter/material.dart';

class TagGroup {
  final String name;
  final List<String> tags;

  TagGroup({required this.name, required this.tags});
}

class TagManagerDialog extends StatefulWidget {
  final List<TagGroup> groups;
  final List<String> selectedTags;

  const TagManagerDialog({
    super.key,
    required this.groups,
    required this.selectedTags,
  });

  @override
  State<TagManagerDialog> createState() => _TagManagerDialogState();
}

class _TagManagerDialogState extends State<TagManagerDialog> {
  late String _selectedGroup;
  late List<String> _selectedTags;
  late List<TagGroup> _groups;

  @override
  void initState() {
    super.initState();
    _groups = List.from(widget.groups);
    _selectedTags = List.from(widget.selectedTags);
    _selectedGroup = _groups.isNotEmpty ? _groups[0].name : '新建分组';
  }

  Future<void> _createNewGroup() async {
    final TextEditingController textController = TextEditingController();

    final name = await showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('新建分组'),
            content: TextField(
              autofocus: true,
              controller: textController,
              decoration: const InputDecoration(hintText: '请输入分组名称'),
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
        _selectedGroup = name; // 自动切换到新创建的分组
      });
    }
  }

  Future<void> _addNewTag() async {
    if (_selectedGroup == '新建分组') return;

    final TextEditingController textController = TextEditingController();

    final name = await showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('新建标签'),
            content: TextField(
              autofocus: true,
              controller: textController,
              decoration: const InputDecoration(hintText: '请输入标签名称'),
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
          // 检查标签是否已存在
          if (!_groups[groupIndex].tags.contains(name)) {
            final currentTags = List<String>.from(_groups[groupIndex].tags);
            currentTags.add(name);
            _groups[groupIndex] = TagGroup(
              name: _selectedGroup,
              tags: currentTags,
            );
          }
        }
      });
    }
  }

  Future<void> _editCurrentGroup() async {
    final currentGroup = _groups.firstWhere(
      (group) => group.name == _selectedGroup,
    );

    final TextEditingController textController = TextEditingController(
      text: currentGroup.name,
    );

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('编辑分组'),
            content: TextField(
              autofocus: true,
              controller: textController,
              decoration: const InputDecoration(hintText: '请输入新的分组名称'),
            ),
            actions: [
              TextButton(
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                onPressed:
                    () => Navigator.of(context).pop({'action': 'delete'}),
                child: const Text('删除分组'),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed:
                    () => Navigator.of(
                      context,
                    ).pop({'action': 'rename', 'name': textController.text}),
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
  }

  void _deleteCurrentGroup() {
    if (_selectedGroup == '新建分组') return;

    setState(() {
      _groups.removeWhere((group) => group.name == _selectedGroup);
      if (_groups.isEmpty) {
        _selectedGroup = '新建分组';
      } else {
        _selectedGroup = _groups[0].name;
      }
    });
  }

  void _deleteSelectedTags() {
    if (_selectedGroup == '新建分组') return;

    setState(() {
      final groupIndex = _groups.indexWhere((g) => g.name == _selectedGroup);
      if (groupIndex != -1) {
        final currentTags = List<String>.from(_groups[groupIndex].tags);
        currentTags.removeWhere((tag) => _selectedTags.contains(tag));
        _groups[groupIndex] = TagGroup(name: _selectedGroup, tags: currentTags);
        _selectedTags.clear(); // 清空选中的标签
      }
    });
  }

  List<String> _getCurrentGroupTags() {
    final currentGroup = _groups.firstWhere(
      (group) => group.name == _selectedGroup,
      orElse: () => TagGroup(name: '新建分组', tags: []),
    );
    return currentGroup.tags;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 第一行：分组选择和删除按钮
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 分组下拉菜单
                DropdownButton<String>(
                  value: _selectedGroup,
                  items: [
                    const DropdownMenuItem(value: '新建分组', child: Text('新建分组')),
                    ..._groups.map(
                      (group) => DropdownMenuItem(
                        value: group.name,
                        child: Text(group.name),
                      ),
                    ),
                  ],
                  onChanged: (String? value) {
                    if (value != null) {
                      if (value == '新建分组') {
                        _createNewGroup();
                      } else {
                        setState(() {
                          _selectedGroup = value;
                        });
                      }
                    }
                  },
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 添加标签按钮
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: _selectedGroup == '新建分组' ? null : _addNewTag,
                      tooltip: '添加新标签',
                    ),
                    // 编辑按钮
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed:
                          _selectedGroup == '新建分组' ? null : _editCurrentGroup,
                      tooltip: '编辑分组',
                    ),
                    // 删除按钮（用于删除选中的标签）
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed:
                          _selectedGroup == '新建分组' || _selectedTags.isEmpty
                              ? null
                              : _deleteSelectedTags,
                      tooltip: '删除选中的标签',
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            // 第二行：标签列表
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  _getCurrentGroupTags().map((tag) {
                    final isSelected = _selectedTags.contains(tag);
                    return FilterChip(
                      label: Text(tag),
                      selected: isSelected,
                      onSelected: (_) => _onTagToggle(tag),
                      selectedColor: Theme.of(
                        context,
                      ).primaryColor.withValues(alpha: 51), // 0.2 * 255 ≈ 51
                      checkmarkColor: Theme.of(context).primaryColor,
                    );
                  }).toList(),
            ),
            const SizedBox(height: 16),
            // 确认和取消按钮
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 清空选中按钮
                TextButton.icon(
                  onPressed:
                      _selectedTags.isEmpty
                          ? null
                          : () {
                            setState(() {
                              _selectedTags.clear();
                            });
                          },
                  icon: const Icon(Icons.clear_all),
                  label: const Text('清空选中'),
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
