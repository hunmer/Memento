import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
import 'package:Memento/widgets/super_cupertino_navigation_wrapper.dart';
import 'package:Memento/widgets/super_cupertino_navigation_wrapper/filter_models.dart';
import 'package:Memento/plugins/agent_chat/agent_chat_plugin.dart';
import 'package:Memento/plugins/agent_chat/controllers/conversation_controller.dart';
import 'package:Memento/plugins/agent_chat/models/conversation.dart';
import 'package:Memento/plugins/agent_chat/screens/chat_screen/chat_screen.dart';
import 'package:Memento/plugins/agent_chat/screens/agent_chat_settings_screen.dart';
import 'package:Memento/plugins/agent_chat/screens/tool_management_screen/tool_management_screen.dart';
import 'package:Memento/plugins/agent_chat/screens/tool_template_screen/tool_template_screen.dart';
import 'package:Memento/plugins/agent_chat/services/tool_template_service.dart';
import 'package:Memento/core/route/route_history_manager.dart';
import 'package:Memento/core/services/toast_service.dart';

/// 会话列表屏幕
class ConversationListScreen extends StatefulWidget {
  const ConversationListScreen({super.key});

  @override
  State<ConversationListScreen> createState() => _ConversationListScreenState();
}

class _ConversationListScreenState extends State<ConversationListScreen> {
  late ConversationController _controller;
  late ToolTemplateService _templateService;

  /// 缓存的会话数量，用于检测实际变化
  int _cachedConversationCount = 0;

  /// 缓存的会话ID列表哈希，用于快速检测变化
  int _cachedConversationHash = 0;

  @override
  void initState() {
    super.initState();
    // 通过插件实例获取controller
    _controller = AgentChatPlugin.instance.conversationController!;

    // 初始化工具模板服务
    _templateService = ToolTemplateService(_controller.storage);

    // 延迟添加监听器，避免在build期间触发setState
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _controller.addListener(_onControllerChanged);

        // 初始化会话缓存，避免首次触发不必要的重建
        final initialConversations = _controller.conversations;
        _cachedConversationCount = initialConversations.length;
        _cachedConversationHash = _computeConversationHash(
          initialConversations,
        );

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
      // 检查会话列表是否有实际变化，避免不必要的重建导致闪烁
      final conversations = _controller.conversations;
      final newCount = conversations.length;
      final newHash = _computeConversationHash(conversations);

      // 仅当会话列表发生实际变化时才触发重建
      final hasChanges =
          newCount != _cachedConversationCount ||
          newHash != _cachedConversationHash;

      if (hasChanges) {
        _cachedConversationCount = newCount;
        _cachedConversationHash = newHash;

        // 使用 addPostFrameCallback 避免在构建过程中调用 setState
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {});
          }
        });
      }
    }
  }

  /// 计算会话列表的哈希值，用于快速检测变化
  int _computeConversationHash(List<Conversation> conversations) {
    if (conversations.isEmpty) return 0;
    // 基于会话ID和最后消息时间计算哈希
    int hash = 0;
    for (final conv in conversations) {
      hash = hash ^ conv.id.hashCode ^ conv.lastMessageAt.hashCode;
      if (conv.lastMessagePreview != null) {
        hash = hash ^ conv.lastMessagePreview.hashCode;
      }
    }
    return hash;
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

    NavigationHelper.push(context, const ToolManagementScreen());
  }

  /// 打开工具模板页面
  void _openToolTemplate() {
    // 记录路由访问历史
    RouteHistoryManager.recordPageVisit(
      pageId: 'tool_template',
      title: '工具模板管理',
      icon: Icons.inventory_2_outlined,
    );

    NavigationHelper.push(
      context,
      ToolTemplateScreen(templateService: _templateService),
    );
  }


  /// 构建分组过滤的 FilterItem
  List<FilterItem> _buildGroupFilterItems() {
    // 从所有会话（未过滤）的groups字段中提取唯一的分组名称
    final allGroupNames = <String>{};
    for (final conv in _controller.allConversations) {
      allGroupNames.addAll(conv.groups);
    }
    final groups = allGroupNames.toList()..sort();

    // 如果没有分组，返回空列表
    if (groups.isEmpty) {
      return [];
    }

    return [
      FilterItem(
        id: 'groups',
        title: '分组',
        type: FilterType.tagsMultiple,
        builder: (context, currentValue, onChanged) {
          final selectedGroups = currentValue as List<String>? ?? [];

          return Row(
            children: [
              // "全部"按钮
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: const Text('全部'),
                  selected: selectedGroups.isEmpty,
                  onSelected: (selected) {
                    if (selected || selectedGroups.isNotEmpty) {
                      onChanged(<String>[]);
                    }
                  },
                  showCheckmark: false,
                  labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                  visualDensity: VisualDensity.compact,
                ),
              ),
              // 分组按钮
              ...groups.map((groupName) {
                final isSelected = selectedGroups.contains(groupName);
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(groupName),
                    selected: isSelected,
                    onSelected: (selected) {
                      final newGroups = List<String>.from(selectedGroups);
                      if (selected) {
                        newGroups.add(groupName);
                      } else {
                        newGroups.remove(groupName);
                      }
                      onChanged(newGroups);
                    },
                    showCheckmark: true,
                    labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                    visualDensity: VisualDensity.compact,
                  ),
                );
              }),
            ],
          );
        },
        getBadge: (value) {
          final selectedGroups = value as List<String>? ?? [];
          return selectedGroups.isEmpty ? null : '${selectedGroups.length}';
        },
        initialValue: <String>[],
      ),
    ];
  }

  /// 显示添加频道对话框
  Future<void> _showAddChannelDialog() async {
    final nameController = TextEditingController();

    try {
      final result = await showDialog<bool>(
        context: context,
        builder:
            (context) => AlertDialog(
              title: Text('agent_chat_addChannel'.tr),
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
                  child: Text('agent_chat_cancel'.tr),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text('agent_chat_create'.tr),
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


  @override
  Widget build(BuildContext context) {
    final hasAnyConversations =
        _controller.conversationService.conversations.isNotEmpty;

    return SuperCupertinoNavigationWrapper(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      title: Text('agent_chat_aiChat'.tr),
      largeTitle: 'agent_chat_aiChat'.tr,
      enableLargeTitle: true,
      enableSearchBar: true,
      searchPlaceholder: 'agent_chat_searchPlaceholder'.tr,
      onSearchChanged: (query) {
        _controller.setSearchQuery(query);
      },
      onSearchSubmitted: (query) {
        _controller.setSearchQuery(query);
      },
      automaticallyImplyLeading: !(Platform.isAndroid || Platform.isIOS),
      actions: [
        // 添加按钮
        IconButton(
          icon: const Icon(Icons.add_circle_outline, size: 24),
          tooltip: '添加频道',
          onPressed: _showAddChannelDialog,
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
      // 多条件过滤配置
      enableMultiFilter: true,
      multiFilterItems: _buildGroupFilterItems(),
      onMultiFilterChanged: (filters) {
        final selectedGroups = filters['groups'] as List<String>? ?? [];
        // 清空现有过滤
        _controller.clearGroupFilters();
        // 应用新的过滤
        for (final group in selectedGroups) {
          _controller.toggleGroupFilter(group);
        }
      },
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

    return _conversationListTransition(
      isEmpty: conversations.isEmpty,
      emptyWidget: _buildEmptyListState(key: const ValueKey('empty')),
      listWidget: ListView.builder(
        key: ValueKey('conversation_list_${conversations.length}'),
        padding: EdgeInsets.zero,
        itemCount: conversations.length,
        itemBuilder: (context, index) {
          final conversation = conversations[index];
          return _buildConversationCard(conversation);
        },
      ),
    );
  }

  /// 会话列表过渡动画组件
  Widget _conversationListTransition({
    required bool isEmpty,
    required Widget emptyWidget,
    required Widget listWidget,
  }) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      switchInCurve: Curves.easeInOut,
      switchOutCurve: Curves.easeInOut,
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(opacity: animation, child: child);
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


  /// 会话卡片
  Widget _buildConversationCard(Conversation conversation) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          NavigationHelper.openContainerWithHero(
            context,
            (context) => ChatScreen(
              conversation: conversation,
              storage: _controller.storage,
              conversationService: _controller.conversationService,
              getSettings: () => AgentChatPlugin.instance.settings,
            ),
          );
        },
        highlightColor: Colors.transparent,
        splashColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300, width: 1.0),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.blue[100],
                  child: Icon(
                    conversation.isPinned ? Icons.push_pin : Icons.chat,
                    color: Colors.blue[700],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              conversation.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
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
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                      if (conversation.lastMessagePreview != null) ...[
                        const SizedBox(height: 8),
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
                ),
                PopupMenuButton<String>(
                  onSelected:
                      (value) =>
                          _onConversationMenuSelected(value, conversation),
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
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              const Icon(Icons.edit),
                              const SizedBox(width: 8),
                              Text('agent_chat_edit'.tr),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              const Icon(Icons.delete, color: Colors.red),
                              const SizedBox(width: 8),
                              Text(
                                'agent_chat_delete'.tr,
                                style: const TextStyle(color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                      ],
                ),
              ],
            ),
          ),
        ),
      ),
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
    final groupsController = TextEditingController(
      text: conversation.groups.join(', '),
    );

    try {
      final result = await showDialog<bool>(
        context: context,
        builder:
            (context) => AlertDialog(
              title: Text('agent_chat_editConversation'.tr),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: '会话标题'),
                    autofocus: true,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: groupsController,
                    decoration: const InputDecoration(
                      labelText: '分组',
                      hintText: '用逗号分隔多个分组，例如：工作, 生活',
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text('agent_chat_cancel'.tr),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text('agent_chat_save'.tr),
                ),
              ],
            ),
      );

      if (result == true && titleController.text.isNotEmpty) {
        // 解析分组字符串
        final groupsText = groupsController.text.trim();
        final groups = groupsText.isEmpty
            ? <String>[]
            : groupsText
                .split(',')
                .map((g) => g.trim())
                .where((g) => g.isNotEmpty)
                .toList();

        final updated = conversation.copyWith(
          title: titleController.text,
          groups: groups,
        );
        await _controller.updateConversation(updated);

        if (mounted) {
          ToastService.instance.showToast('会话已更新');
        }
      }
    } finally {
      // 确保无论如何都会 dispose controller
      titleController.dispose();
      groupsController.dispose();
    }
  }

  /// 显示删除确认对话框
  Future<void> _showDeleteConfirmDialog(Conversation conversation) async {
    final result = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('agent_chat_confirmDelete'.tr),
            content: Text(
              'agent_chat_confirmDeleteConversation'.trParams({
                'title': conversation.title,
              }),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('agent_chat_cancel'.tr),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: Text('agent_chat_delete'.tr),
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
