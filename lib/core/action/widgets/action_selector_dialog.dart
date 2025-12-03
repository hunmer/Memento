/// 动作选择对话框
/// 用于选择和配置动作
library action_selector_dialog;

import 'dart:async';
import 'package:flutter/material.dart';
import '../action_manager.dart';
import '../models/action_definition.dart';
import '../models/action_instance.dart';
import '../models/action_group.dart';
import '../../floating_ball/models/floating_ball_gesture.dart';
import 'action_config_form.dart';
import 'action_group_editor.dart';

/// 对话框结果
class ActionSelectorResult {
  final ActionInstance? singleAction;
  final ActionGroup? actionGroup;
  final ActionDefinition? selectedDefinition;
  final Map<String, dynamic>? formData;

  const ActionSelectorResult({
    this.singleAction,
    this.actionGroup,
    this.selectedDefinition,
    this.formData,
  });

  bool get isGroup => actionGroup != null;
  bool get isSingleAction => singleAction != null;
  bool get isEmpty => singleAction == null && actionGroup == null;
}

/// 动作选择器选项卡
enum ActionSelectorTab {
  single,    // 单动作
  group,     // 动作组
  custom,    // 自定义动作
}

/// 动作选择对话框
class ActionSelectorDialog extends StatefulWidget {
  final FloatingBallGesture? gesture;
  final ActionSelectorResult? initialValue;
  final bool showGroupEditor;

  const ActionSelectorDialog({
    super.key,
    this.gesture,
    this.initialValue,
    this.showGroupEditor = true,
  });

  @override
  State<ActionSelectorDialog> createState() => _ActionSelectorDialogState();
}

class _ActionSelectorDialogState extends State<ActionSelectorDialog>
    with TickerProviderStateMixin {
  // Tab 控制器
  late TabController _tabController;

  // 搜索控制器
  final TextEditingController _searchController = TextEditingController();

  // 当前选中的 Tab
  ActionSelectorTab _currentTab = ActionSelectorTab.single;

  // 搜索关键词
  String _searchQuery = '';

  // 动作定义列表
  List<ActionDefinition> _allActions = [];
  List<ActionDefinition> _filteredActions = [];

  // 动作组列表
  List<ActionGroup> _allGroups = [];
  List<ActionGroup> _filteredGroups = [];

  // 自定义动作实例列表
  List<ActionInstance> _allCustomActions = [];
  List<ActionInstance> _filteredCustomActions = [];

  // 选中的动作
  ActionDefinition? _selectedDefinition;
  ActionGroup? _selectedGroup;
  ActionInstance? _selectedCustomAction;

  // 表单数据
  Map<String, dynamic> _formData = {};

  // 初始表单数据（用于恢复已有配置）
  Map<String, dynamic>? _initialFormData;

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);

    // 加载数据
    _loadActions();

    // 初始化搜索
    _filterActions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      setState(() {
        _currentTab = ActionSelectorTab.values[_tabController.index];
        _filterActions();
      });
    }
  }

  void _loadActions() {
    final actionManager = ActionManager();

    setState(() {
      _allActions = actionManager.allActions;
      _allGroups = actionManager.actionGroups;
      _allCustomActions = actionManager.customActions;
    });

    // 如果有初始值，在动作加载完成后设置
    _setInitialFromWidget();
  }

  void _setInitialFromWidget() {
    final initial = widget.initialValue;
    if (initial == null) return;

    if (initial.singleAction != null) {
      // 根据 actionId 找到对应的 ActionDefinition
      try {
        final actionDef = _allActions.firstWhere(
          (action) => action.id == initial.singleAction!.actionId,
        );

        setState(() {
          _selectedDefinition = actionDef;
          _initialFormData = initial.singleAction?.data ?? {};
          _currentTab = ActionSelectorTab.single;
          // 恢复表单数据
          _formData = Map<String, dynamic>.from(_initialFormData ?? {});
        });

        // 异步设置 Tab 索引
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _tabController.index = _currentTab.index;
        });
      } catch (e) {
        print('Warning: Action not found: ${initial.singleAction?.actionId}');
      }
    } else if (initial.actionGroup != null) {
      // 异步检查动作组是否存在
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final groupExists = _allGroups.any((g) => g.id == initial.actionGroup!.id);
        if (groupExists) {
          setState(() {
            _selectedGroup = initial.actionGroup;
            _currentTab = ActionSelectorTab.group;
          });

          // 设置 Tab 索引
          _tabController.index = _currentTab.index;
        } else {
          print('Warning: Action group not found: ${initial.actionGroup?.id}');
        }
      });
    }
  }

  void _filterActions() {
    final query = _searchQuery.toLowerCase();

    if (query.isEmpty) {
      _filteredActions = List.from(_allActions);
      _filteredGroups = List.from(_allGroups);
      _filteredCustomActions = List.from(_allCustomActions);
    } else {
      _filteredActions = _allActions
          .where((action) =>
              action.title.toLowerCase().contains(query) ||
              action.description?.toLowerCase().contains(query) == true)
          .toList();

      _filteredGroups = _allGroups
          .where((group) =>
              group.title.toLowerCase().contains(query) ||
              group.description?.toLowerCase().contains(query) == true)
          .toList();

      _filteredCustomActions = _allCustomActions
          .where((action) =>
              action.displayTitle.toLowerCase().contains(query) ||
              action.displayDescription?.toLowerCase().contains(query) == true)
          .toList();
    }

    setState(() {});
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      _filterActions();
    });
  }

  void _onSelectDefinition(ActionDefinition definition) {
    setState(() {
      _selectedDefinition = definition;
      _selectedGroup = null;
      _selectedCustomAction = null;

      // 如果选择的不是初始动作，清空表单数据
      if (_initialFormData == null ||
          _initialFormData!.isEmpty ||
          _selectedDefinition?.id != definition.id) {
        _formData = {};
      }
    });
  }

  void _onSelectGroup(ActionGroup group) {
    setState(() {
      _selectedGroup = group;
      _selectedDefinition = null;
      _selectedCustomAction = null;
    });
  }

  void _onSelectCustomAction(ActionInstance action) {
    setState(() {
      _selectedCustomAction = action;
      _selectedDefinition = null;
      _selectedGroup = null;
    });
  }

  void _onFormDataChanged(Map<String, dynamic> data) {
    setState(() {
      _formData = data;
    });
  }

  Future<void> _onCreateGroup() async {
    final result = await showDialog<ActionGroup>(
      context: context,
      builder: (context) => const ActionGroupEditor(),
    );

    if (result != null) {
      // 保存动作组到 ActionManager
      await ActionManager().saveActionGroup(result);

      setState(() {
        _allGroups.add(result);
        _selectedGroup = result;
      });

      _filterActions();
    }
  }

  void _onConfirm() {
    if (_currentTab == ActionSelectorTab.single) {
      if (_selectedDefinition != null) {
        Navigator.pop(
          context,
          ActionSelectorResult(
            singleAction: ActionInstance.create(
              actionId: _selectedDefinition!.id,
              data: _formData,
            ),
            selectedDefinition: _selectedDefinition,
            formData: _formData,
          ),
        );
      }
    } else if (_currentTab == ActionSelectorTab.group) {
      if (_selectedGroup != null) {
        Navigator.pop(
          context,
          ActionSelectorResult(
            actionGroup: _selectedGroup,
          ),
        );
      }
    } else if (_currentTab == ActionSelectorTab.custom) {
      if (_selectedCustomAction != null) {
        Navigator.pop(
          context,
          ActionSelectorResult(
            singleAction: _selectedCustomAction,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 标题栏
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Icon(
                    Icons.bolt,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '选择动作',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // 搜索框
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: '搜索动作...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onChanged: _onSearchChanged,
              ),
            ),

            const SizedBox(height: 16),

            // Tab 栏
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: '单动作'),
                  Tab(text: '动作组'),
                  Tab(text: '自定义'),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 内容区域
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildSingleActionTab(),
                    _buildGroupTab(),
                    _buildCustomTab(),
                  ],
                ),
              ),
            ),

            // 底部按钮
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 左侧：清除按钮
                  if (widget.initialValue != null &&
                      !widget.initialValue!.isEmpty) ...[
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(
                          context,
                          const ActionSelectorResult(), // 返回空的结果
                        );
                      },
                      icon: const Icon(Icons.clear_all, size: 18),
                      label: const Text('清除已设置'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[300],
                        foregroundColor: Colors.black87,
                      ),
                    ),
                  ] else
                    const SizedBox(),

                  // 右侧：取消和确认按钮
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('取消'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _onConfirm,
                        child: const Text('确认'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSingleActionTab() {
    return Column(
      children: [
        // 动作列表
        Expanded(
          child: _filteredActions.isEmpty
              ? Center(
                  child: Text(
                    '没有找到动作',
                    style: TextStyle(
                      color: Colors.grey[600],
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: _filteredActions.length,
                  itemBuilder: (context, index) {
                    final action = _filteredActions[index];
                    final isSelected = _selectedDefinition?.id == action.id;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.grey[300],
                          child: Icon(
                            action.icon ?? Icons.help_outline,
                            color: Colors.white,
                          ),
                        ),
                        title: Text(action.title),
                        subtitle: Text(
                          action.description ?? '无描述',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: isSelected
                            ? Icon(
                                Icons.check_circle,
                                color: Theme.of(context).colorScheme.primary,
                              )
                            : const Icon(Icons.radio_button_unchecked),
                        onTap: () => _onSelectDefinition(action),
                        onLongPress: () => _onSelectDefinition(action),
                      ),
                    );
                  },
                ),
        ),

        // 配置表单（如果选择了动作）
        if (_selectedDefinition != null) ...[
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '动作配置',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                ActionConfigForm(
                  actionDefinition: _selectedDefinition!,
                  initialData: _initialFormData,
                  onChanged: _onFormDataChanged,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildGroupTab() {
    return Column(
      children: [
        // 动作组列表
        Expanded(
          child: _filteredGroups.isEmpty
              ? Center(
                  child: Text(
                    '没有动作组',
                    style: TextStyle(
                      color: Colors.grey[600],
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: _filteredGroups.length,
                  itemBuilder: (context, index) {
                    final group = _filteredGroups[index];
                    final isSelected = _selectedGroup?.id == group.id;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: group.displayColor?.withOpacity(0.2) ??
                              Colors.grey[300],
                          child: Icon(
                            group.displayIcon ?? Icons.folder,
                            color: group.displayColor ?? Colors.grey,
                          ),
                        ),
                        title: Text(group.title),
                        subtitle: Text(
                          '${group.actionCount} 个动作',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        trailing: isSelected
                            ? Icon(
                                Icons.check_circle,
                                color: Theme.of(context).colorScheme.primary,
                              )
                            : const Icon(Icons.radio_button_unchecked),
                        onTap: () => _onSelectGroup(group),
                      ),
                    );
                  },
                ),
        ),

        // 创建组按钮
        if (widget.showGroupEditor) ...[
          const SizedBox(height: 16),
          SingleChildScrollView(
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _onCreateGroup,
                icon: const Icon(Icons.add),
                label: const Text('创建动作组'),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCustomTab() {
    return _filteredCustomActions.isEmpty
        ? Center(
            child: Text(
              '没有自定义动作',
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
          )
        : ListView.builder(
            itemCount: _filteredCustomActions.length,
            itemBuilder: (context, index) {
              final action = _filteredCustomActions[index];
              final isSelected = _selectedCustomAction?.id == action.id;

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.grey[300],
                    child: Icon(
                      action.displayIcon ?? Icons.star,
                      color: Colors.white,
                    ),
                  ),
                  title: Text(action.displayTitle),
                  subtitle: Text(
                    action.displayDescription ?? action.actionId,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: isSelected
                      ? Icon(
                          Icons.check_circle,
                          color: Theme.of(context).colorScheme.primary,
                        )
                      : const Icon(Icons.radio_button_unchecked),
                  onTap: () => _onSelectCustomAction(action),
                ),
              );
            },
          );
  }
}
