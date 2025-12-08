import 'dart:io';

import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
import 'package:Memento/widgets/super_cupertino_navigation_wrapper.dart';
import 'package:Memento/plugins/agent_chat/agent_chat_plugin.dart';
import 'package:Memento/plugins/agent_chat/controllers/conversation_controller.dart';
import 'package:Memento/plugins/agent_chat/models/conversation.dart';
import 'package:Memento/plugins/agent_chat/models/conversation_group.dart';
import 'package:Memento/plugins/agent_chat/screens/chat_screen/chat_screen.dart';
import 'package:Memento/plugins/agent_chat/screens/agent_chat_settings_screen.dart';
import 'package:Memento/plugins/agent_chat/screens/tool_management_screen/tool_management_screen.dart';
import 'package:Memento/plugins/agent_chat/screens/tool_template_screen/tool_template_screen.dart';
import 'package:Memento/plugins/agent_chat/services/tool_template_service.dart';
import 'package:Memento/core/route/route_history_manager.dart';
import 'package:Memento/core/services/toast_service.dart';
import 'package:Memento/plugins/agent_chat/l10n/agent_chat_localizations.dart';

/// 会话列表屏幕
class ConversationListScreen extends StatefulWidget {
  const ConversationListScreen({super.key});

  @override
  State<ConversationListScreen> createState() => _ConversationListScreenState();
}

class _ConversationListScreenState extends State<ConversationListScreen> {
  late ConversationController _controller;
  late ToolTemplateService _templateService;

  /// 缓存的分组列表，确保UI稳定性
  List<ConversationGroup> _cachedGroups = [];

  @override
  void initState() {
    super.initState();
    // 通过插件实例获取controller
    _controller = AgentChatPlugin.instance.conversationController;

    // 初始化工具模板服务
    _templateService = ToolTemplateService(_controller.storage);

    // 延迟添加监听器，避免在build期间触发setState
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _controller.addListener(_onControllerChanged);

        // 初始化缓存的分组列表
        final initialGroups = _controller.groups;
        if (initialGroups.isNotEmpty) {
          _cachedGroups = List.from(initialGroups);
        }

        // 触发一次更新以确保显示最新状态
        if (mounted) {
          setState(() {});
        }
      }
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) {
      // 更新缓存的分组列表，确保UI稳定性
      final currentGroups = _controller.groups;
      if (currentGroups.isNotEmpty || _cachedGroups.isEmpty) {
        _cachedGroups = List.from(currentGroups);
      }
      // 使用 addPostFrameCallback 避免在构建过程中调用 setState
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {});
        }
      });
    }
  }

  /// 打开设置页面
  void _openSettings() {
    NavigationHelper.push(
      context,
      AgentChatSettingsScreen(plugin: AgentChatPlugin.instance),
    );
  }

  /// 打开工具管理页面
  void _openToolManagement() {
    // 记录路由访问历史
    RouteHistoryManager.recordPageVisit(
      pageId: 'tool_management',
      title: '工具配置管理',
      icon: Icons.settings_outlined,
    );

    NavigationHelper.push(context, const ToolManagementScreen(),
    );
  }

  /// 打开工具模板页面
  void _openToolTemplate() {
    // 记录路由访问历史
    RouteHistoryManager.recordPageVisit(
      pageId: 'tool_template',
      title: '工具模板管理',
      icon: Icons.inventory_2_outlined,
    );

    NavigationHelper.push(context, ToolTemplateScreen(
              templateService: _templateService,
    ),
    );
  }

  /// 打开分组管理对话框
  Future<void> _openGroupManagement() async {
    final groups = _controller.groups;

    if (groups.isEmpty) {
      ToastService.instance.showToast('还没有创建任何分组');
      return;
    }

    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(AgentChatLocalizations.of(context)!.groupManagement),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: groups.length,
                itemBuilder: (context, index) {
                  final group = groups[index];
                  return ListTile(
                    leading: const Icon(Icons.folder),
                    title: Text(group.name),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) => _onGroupMenuSelected(value, group),
                      itemBuilder:
                          (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit),
                                  SizedBox(width: 8),
                                  Text(AgentChatLocalizations.of(context)!.edit),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text(
                                    AgentChatLocalizations.of(context)!.delete,
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ],
                              ),
                            ),
                          ],
                    ),
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(AgentChatLocalizations.of(context)!.close),
              ),
            ],
          ),
    );
  }

  /// 分组菜单选择
  Future<void> _onGroupMenuSelected(
    String value,
    ConversationGroup group,
  ) async {
    switch (value) {
      case 'edit':
        _showEditGroupDialog(group);
        break;

      case 'delete':
        _showDeleteGroupConfirmDialog(group);
        break;
    }
  }

  /// 显示编辑分组对话框
  Future<void> _showEditGroupDialog(ConversationGroup group) async {
    final nameController = TextEditingController(text: group.name);

    try {
      final result = await showDialog<bool>(
        context: context,
        builder:
            (context) => AlertDialog(
              title: Text(AgentChatLocalizations.of(context)!.editGroup),
              content: TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: '分组名称'),
                autofocus: true,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(AgentChatLocalizations.of(context)!.cancel),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(AgentChatLocalizations.of(context)!.save),
                ),
              ],
            ),
      );

      if (result == true && nameController.text.isNotEmpty) {
        final updated = group.copyWith(name: nameController.text);
        await _controller.updateGroup(updated);

        if (mounted) {
          ToastService.instance.showToast('分组已更新');
        }
      }
    } finally {
      nameController.dispose();
    }
  }

  /// 显示删除分组确认对话框
  Future<void> _showDeleteGroupConfirmDialog(ConversationGroup group) async {
    final result = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(AgentChatLocalizations.of(context)!.confirmDelete),
            content: Text(AgentChatLocalizations.of(context)!.confirmDeleteGroup(group.name)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(AgentChatLocalizations.of(context)!.cancel),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: Text(AgentChatLocalizations.of(context)!.delete),
              ),
            ],
          ),
    );

    if (result == true) {
      await _controller.deleteGroup(group.id);

      if (mounted) {
        ToastService.instance.showToast('分组已删除');
      }
    }
  }

  /// 打开添加对话框
  void _openAddDialog() {
    _showAddDialog();
  }

  /// 显示添加对话框（频道或分组）
  Future<void> _showAddDialog() async {
    final type = await showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(AgentChatLocalizations.of(context)!.selectTypeToCreate),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.chat),
                  title: Text(AgentChatLocalizations.of(context)!.channel),
                  subtitle: Text(AgentChatLocalizations.of(context)!.createNewConversationChannel),
                  onTap: () => Navigator.pop(context, 'channel'),
                ),
                ListTile(
                  leading: const Icon(Icons.folder),
                  title: Text(AgentChatLocalizations.of(context)!.group),
                  subtitle: Text(AgentChatLocalizations.of(context)!.createNewGroupCategory),
                  onTap: () => Navigator.pop(context, 'group'),
                ),
              ],
            ),
          ),
    );

    if (type == 'channel') {
      _showAddChannelDialog();
    } else if (type == 'group') {
      _showAddGroupDialog();
    }
  }

  /// 显示添加频道对话框
  Future<void> _showAddChannelDialog() async {
    final nameController = TextEditingController();

    try {
      final result = await showDialog<bool>(
        context: context,
        builder:
            (context) => AlertDialog(
              title: Text(AgentChatLocalizations.of(context)!.addChannel),
              content: TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: '频道名称',
                  hintText: '请输入频道名称',
                ),
                autofocus: true,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(AgentChatLocalizations.of(context)!.cancel),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(AgentChatLocalizations.of(context)!.create),
                ),
              ],
            ),
      );

      if (result == true && nameController.text.isNotEmpty) {
        try {
          await _controller.createConversation(title: nameController.text);

          if (mounted) {
            ToastService.instance.showToast('频道已创建');
          }
        } catch (e) {
          if (mounted) {
            ToastService.instance.showToast('创建频道失败: $e');
          }
          debugPrint('创建频道失败: $e');
        }
      }
    } finally {
      nameController.dispose();
    }
  }

  /// 显示添加分组对话框
  Future<void> _showAddGroupDialog() async {
    final nameController = TextEditingController();

    try {
      final result = await showDialog<bool>(
        context: context,
        builder:
            (context) => AlertDialog(
              title: Text(AgentChatLocalizations.of(context)!.addGroup),
              content: TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: '分组名称',
                  hintText: '请输入分组名称',
                ),
                autofocus: true,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(AgentChatLocalizations.of(context)!.cancel),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(AgentChatLocalizations.of(context)!.create),
                ),
              ],
            ),
      );

      if (result == true && nameController.text.isNotEmpty) {
        try {
          await _controller.createGroup(name: nameController.text);

          if (mounted) {
            ToastService.instance.showToast('分组已创建');
          }
        } catch (e) {
          if (mounted) {
            ToastService.instance.showToast('创建分组失败: $e');
          }
          debugPrint('创建分组失败: $e');
        }
      }
    } finally {
      nameController.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasAnyConversations =
        _controller.conversationService.conversations.isNotEmpty;

    return SuperCupertinoNavigationWrapper(
      title: Text(AgentChatLocalizations.of(context)!.aiChat),
      largeTitle: AgentChatLocalizations.of(context)!.aiChat,
      enableLargeTitle: true,
      enableSearchBar: true,
      searchPlaceholder: '搜索会话...',
      onSearchChanged: (query) {
        _controller.setSearchQuery(query);
      },
      onSearchSubmitted: (query) {
        _controller.setSearchQuery(query);
      },
      automaticallyImplyLeading: !(Platform.isAndroid || Platform.isIOS),
      actions: [
        // 添加按钮（频道或分组）
        IconButton(
          icon: const Icon(Icons.add_circle_outline, size: 24),
          tooltip: '添加',
          onPressed: _openAddDialog,
        ),
        // 分组管理按钮
        IconButton(
          icon: const Icon(Icons.folder_outlined, size: 24),
          tooltip: AgentChatLocalizations.of(context)!.groupManagement,
          onPressed: _openGroupManagement,
        ),
        // 工具管理按钮
        IconButton(
          icon: const Icon(Icons.build, size: 24),
          tooltip: '工具管理',
          onPressed: _openToolManagement,
        ),
        // 工具模板按钮
        IconButton(
          icon: const Icon(Icons.inventory_2, size: 24),
          tooltip: '工具模板',
          onPressed: _openToolTemplate,
        ),
        // 设置按钮
        IconButton(
          icon: const Icon(Icons.settings, size: 24),
          onPressed: _openSettings,
        ),
      ],
      body:
          _controller.isLoading
              ? const Center(child: CircularProgressIndicator())
              : hasAnyConversations
              ? _buildConversationList()
              : _buildEmptyState(),
    );
  }

  /// 空状态视图
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            '还没有任何会话',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            '点击右下角的 + 按钮创建新会话',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  /// 会话列表
  Widget _buildConversationList() {
    final conversations = _controller.conversations;
    // 使用缓存的groups列表确保UI稳定性
    final groups =
        _cachedGroups.isNotEmpty ? _cachedGroups : _controller.groups;

    // 使用更稳定的分组判断逻辑
    final hasGroups = groups.isNotEmpty;

    return Column(
      children: [
        // 分组过滤器区域 - 使用更稳定的判断
        if (hasGroups) _buildGroupFilters(groups) else const SizedBox.shrink(),
        // 会话列表 - 使用 FadeThroughTransition 实现淡入淡出效果
        Expanded(
          child: _conversationListTransition(
            isEmpty: conversations.isEmpty,
            emptyWidget: _buildEmptyListState(key: const ValueKey('empty')),
            listWidget: ListView.builder(
              key: ValueKey('conversation_list_${conversations.length}'),
              itemCount: conversations.length,
              itemBuilder: (context, index) {
                final conversation = conversations[index];
                return _buildConversationCard(conversation);
              },
            ),
          ),
        ),
      ],
    );
  }

  /// 会话列表过渡动画组件
  Widget _conversationListTransition({
    required bool isEmpty,
    required Widget emptyWidget,
    required Widget listWidget,
  }) {
    return PageTransitionSwitcher(
      transitionBuilder: (
        Widget child,
        Animation<double> animation,
        Animation<double> secondaryAnimation,
      ) {
        return FadeThroughTransition(
          animation: animation,
          secondaryAnimation: secondaryAnimation,
          child: child,
        );
      },
      child: isEmpty ? emptyWidget : listWidget,
    );
  }

  /// 空列表状态
  Widget _buildEmptyListState({Key? key}) {
    return Center(
      key: key,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            '没有匹配的会话',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            '尝试调整搜索条件或分组过滤器',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  /// 分组过滤器
  Widget _buildGroupFilters(List<ConversationGroup> groups) {
    // 额外的安全检查，确保groups列表不为空
    if (groups.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                '分组过滤',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const Spacer(),
              if (_controller.selectedGroupFilters.isNotEmpty)
                TextButton(
                  onPressed: () => _controller.clearGroupFilters(),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 0,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(AgentChatLocalizations.of(context)!.clear, style: TextStyle(fontSize: 12)),
                ),
            ],
          ),
          const SizedBox(height: 4),
          // 横向滚动的过滤器
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // 全部按钮 - 当没有选择任何分组时显示为选中状态
                _animatedFilterChip(
                  label: '全部',
                  isSelected: _controller.selectedGroupFilters.isEmpty,
                  onSelected: (selected) {
                    // 点击"全部"按钮会清除所有过滤器
                    if (selected ||
                        _controller.selectedGroupFilters.isNotEmpty) {
                      _controller.clearGroupFilters();
                    }
                  },
                ),
                // 分组按钮
                ...groups.map((group) {
                  final isSelected = _controller.selectedGroupFilters.contains(
                    group.id,
                  );
                  return _animatedFilterChip(
                    label: group.name,
                    isSelected: isSelected,
                    onSelected: (selected) {
                      _controller.toggleGroupFilter(group.id);
                    },
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 动画 FilterChip 组件
  Widget _animatedFilterChip({
    required String label,
    required bool isSelected,
    required ValueChanged<bool> onSelected,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: AnimatedScale(
        scale: isSelected ? 1.0 : 0.95,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeInOut,
        child: FilterChip(
          label: Text(label),
          selected: isSelected,
          onSelected: onSelected,
        ),
      ),
    );
  }

  /// 会话卡片
  Widget _buildConversationCard(Conversation conversation) {
    return OpenContainer<bool>(
      transitionType: ContainerTransitionType.fade,
      openBuilder: (BuildContext context, VoidCallback _) {
        // 直接返回聊天页面，OpenContainer 会处理过渡动画
        return ChatScreen(
          conversation: conversation,
          storage: _controller.storage,
          conversationService: _controller.conversationService,
          getSettings: () => AgentChatPlugin.instance.settings,
        );
      },
      closedBuilder: (BuildContext context, VoidCallback openContainer) {
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue[100],
              child: Icon(
                conversation.isPinned ? Icons.push_pin : Icons.chat,
                color: Colors.blue[700],
              ),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    conversation.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (conversation.unreadCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${conversation.unreadCount}',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (conversation.lastMessagePreview != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    conversation.lastMessagePreview!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  _formatDateTime(conversation.lastMessageAt),
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ),
            trailing: PopupMenuButton<String>(
              onSelected:
                  (value) => _onConversationMenuSelected(value, conversation),
              itemBuilder:
                  (context) => [
                    PopupMenuItem(
                      value: 'pin',
                      child: Row(
                        children: [
                          Icon(
                            conversation.isPinned
                                ? Icons.push_pin_outlined
                                : Icons.push_pin,
                          ),
                          const SizedBox(width: 8),
                          Text(conversation.isPinned ? '取消置顶' : '置顶'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit),
                          SizedBox(width: 8),
                          Text(AgentChatLocalizations.of(context)!.edit),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: 8),
                          Text(AgentChatLocalizations.of(context)!.delete, style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
            ),
            onTap: openContainer,
          ),
        );
      },
    );
  }

  /// 格式化时间
  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return '刚刚';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}分钟前';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}小时前';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}天前';
    } else {
      return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
    }
  }


  /// 会话菜单选择
  Future<void> _onConversationMenuSelected(
    String value,
    Conversation conversation,
  ) async {
    switch (value) {
      case 'pin':
        await _controller.togglePin(conversation.id);
        break;

      case 'edit':
        _showEditConversationDialog(conversation);
        break;

      case 'delete':
        _showDeleteConfirmDialog(conversation);
        break;
    }
  }


  /// 显示编辑会话对话框
  Future<void> _showEditConversationDialog(Conversation conversation) async {
    final titleController = TextEditingController(text: conversation.title);

    try {
      final result = await showDialog<bool>(
        context: context,
        builder:
            (context) => AlertDialog(
              title: Text(AgentChatLocalizations.of(context)!.editConversation),
              content: TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: '会话标题'),
                autofocus: true,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(AgentChatLocalizations.of(context)!.cancel),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(AgentChatLocalizations.of(context)!.save),
                ),
              ],
            ),
      );

      if (result == true && titleController.text.isNotEmpty) {
        final updated = conversation.copyWith(title: titleController.text);
        await _controller.updateConversation(updated);

        if (mounted) {
          ToastService.instance.showToast('会话已更新');
        }
      }
    } finally {
      // 确保无论如何都会 dispose controller
      titleController.dispose();
    }
  }

  /// 显示删除确认对话框
  Future<void> _showDeleteConfirmDialog(Conversation conversation) async {
    final result = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(AgentChatLocalizations.of(context)!.confirmDelete),
            content: Text(
              AgentChatLocalizations.of(context)!.confirmDeleteConversation(conversation.title),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(AgentChatLocalizations.of(context)!.cancel),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: Text(AgentChatLocalizations.of(context)!.delete),
              ),
            ],
          ),
    );

    if (result == true) {
      await _controller.deleteConversation(conversation.id);

      if (mounted) {
        ToastService.instance.showToast('会话已删除');
      }
    }
  }
}
