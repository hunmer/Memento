import 'package:flutter/material.dart';
import '../models/channel.dart';
import '../utils/date_formatter.dart';
import '../widgets/custom_dialog.dart';
import '../widgets/circle_icon_picker.dart';
import 'chat_screen.dart';
import '../plugins/chat/chat_plugin.dart';
import '../models/serialization_helpers.dart'; // 导入预定义图标映射表
import 'package:shared_preferences/shared_preferences.dart';

class ChannelListScreen extends StatefulWidget {
  final List<Channel> channels;
  final ChatPlugin chatPlugin;

  const ChannelListScreen({
    super.key,
    required this.channels,
    required this.chatPlugin,
  });

  @override
  State<ChannelListScreen> createState() => _ChannelListScreenState();
}

class _ChannelListScreenState extends State<ChannelListScreen> {
  late List<Channel> _sortedChannels = [];
  String _selectedGroup = "默认"; // 当前选择的频道组，默认为"默认"
  late SharedPreferences prefs;
  List<String> _availableGroups = ["全部", "默认", "未分组"]; // 可用的频道组列表
  Color selectedColor = Colors.blue; // 默认背景颜色

  @override
  void initState() {
    super.initState();
    _initializePrefs();
    _updateAvailableGroups();
    widget.chatPlugin.addListener(_onChannelsUpdated);
  }

  @override
  void dispose() {
    widget.chatPlugin.removeListener(_onChannelsUpdated);
    super.dispose();
  }

  void _onChannelsUpdated() {
    setState(() {
      _updateSortedChannels();
    });
  }

  Future<void> _initializePrefs() async {
    prefs = await SharedPreferences.getInstance();
    setState(() {
      // 从本地存储加载选中的分组，如果没有则使用"默认"分组
      _selectedGroup = prefs.getString('selectedGroup') ?? "默认";
      _updateSortedChannels();
    });
  }

  Future<void> _loadSelectedGroup() async {
    prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedGroup = prefs.getString('selectedGroup') ?? "默认";
    });
  }

  Future<void> _saveSelectedGroup(String group) async {
    await prefs.setString('selectedGroup', group);
  }

  void _updateSortedChannels() {
    if (_selectedGroup == "全部") {
      _sortedChannels = List<Channel>.from(widget.channels)
        ..sort(Channel.compare);
    } else if (_selectedGroup == "未分组") {
      _sortedChannels =
          widget.channels.where((channel) => channel.groups.isEmpty).toList()
            ..sort(Channel.compare);
    } else if (_selectedGroup == "默认") {
      // 默认分组显示所有带有"默认"标签的频道
      _sortedChannels =
          widget.channels
              .where((channel) => channel.groups.contains("默认"))
              .toList()
            ..sort(Channel.compare);
    } else {
      _sortedChannels =
          widget.channels
              .where((channel) => channel.groups.contains(_selectedGroup))
              .toList()
            ..sort(Channel.compare);
    }
  }

  void _updateAvailableGroups() {
    // 始终包含"全部"、"默认"和"未分组"选项
    Set<String> groups = {"全部", "默认", "未分组"};

    // 收集所有频道的所有组
    for (var channel in widget.channels) {
      groups.addAll(channel.groups);
    }

    _availableGroups = groups.toList()..sort();

    // 确保在更新可用分组后更新排序的频道列表
    _updateSortedChannels();
  }

  void _showAddChannelDialog() {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController groupController = TextEditingController();
    // 使用预定义图标映射表中的默认图标
    IconData selectedIcon = predefinedIcons['chat']!;
    // 使用类级别的 selectedColor 变量
    void updateSelectedColor(Color color) {
      setState(() {
        selectedColor = color;
      });
    }

    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setDialogState) => CustomDialog(
                  title: '新建频道',
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildIconSelector(
                          (icon) {
                            setDialogState(() {
                              selectedIcon = icon;
                            });
                          },
                          selectedIcon,
                          selectedColor,
                          (color) {
                            setDialogState(() {
                              selectedColor = color;
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: nameController,
                          decoration: const InputDecoration(
                            labelText: '频道名称',
                            border: OutlineInputBorder(),
                          ),
                          autofocus: true,
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: groupController,
                          decoration: const InputDecoration(
                            labelText: '频道分组（多个分组用逗号分隔）',
                            border: OutlineInputBorder(),
                            hintText: '例如：工作,学习,娱乐',
                          ),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('取消'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        final name = nameController.text.trim();
                        if (name.isNotEmpty) {
                          // TODO: 实际应用中，这里应该调用API或数据库操作
                          // 处理分组信息
                          List<String> groups = [];
                          if (groupController.text.trim().isNotEmpty) {
                            groups =
                                groupController.text
                                    .split(',')
                                    .map((g) => g.trim())
                                    .where((g) => g.isNotEmpty)
                                    .toList();
                          }

                          final newChannel = Channel(
                            id:
                                DateTime.now().millisecondsSinceEpoch
                                    .toString(),
                            title: name,
                            icon: selectedIcon,
                            members: [], // 初始为空，或添加当前用户
                            messages: [], // 初始为空
                            priority: 0,
                            groups: groups,
                          );

                          setState(() {
                            widget.channels.add(newChannel);
                            _updateAvailableGroups();
                            _updateSortedChannels();
                            // 保存频道数据到本地存储
                            ChatPlugin.instance.saveChannels();
                          });
                          Navigator.pop(context);
                        }
                      },
                      child: const Text('创建'),
                    ),
                  ],
                ),
          ),
    );
  }

  void _showEditChannelDialog(Channel channel) {
    final TextEditingController nameController = TextEditingController(
      text: channel.title,
    );
    final TextEditingController groupController = TextEditingController(
      text: channel.groups.join(', '),
    );
    IconData selectedIcon = channel.icon;
    // 加载频道的背景颜色
    Color dialogSelectedColor = channel.backgroundColor;

    // 使用我们的自定义对话框和StatefulBuilder，设置基础zIndex
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setDialogState) => CustomDialog(
                  title: '编辑频道',
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildIconSelector(
                          (icon) {
                            // 使用对话框内部的setState
                            setDialogState(() {
                              selectedIcon = icon;
                            });
                          },
                          selectedIcon,
                          dialogSelectedColor,
                          (color) {
                            setDialogState(() {
                              dialogSelectedColor = color;
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: nameController,
                          decoration: const InputDecoration(
                            labelText: '频道名称',
                            border: OutlineInputBorder(),
                          ),
                          autofocus: true,
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: groupController,
                          decoration: const InputDecoration(
                            labelText: '频道分组（多个分组用逗号分隔）',
                            border: OutlineInputBorder(),
                            hintText: '例如：工作,学习,娱乐',
                          ),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('取消'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        final name = nameController.text.trim();
                        if (name.isNotEmpty) {
                          // 在实际应用中，这里应该调用API或数据库操作来更新频道
                          // 这里我们只是更新内存中的数据
                          final index = widget.channels.indexWhere(
                            (c) => c.id == channel.id,
                          );
                          if (index != -1) {
                            // 处理分组信息
                            List<String> groups = [];
                            if (groupController.text.trim().isNotEmpty) {
                              groups =
                                  groupController.text
                                      .split(',')
                                      .map((g) => g.trim())
                                      .where((g) => g.isNotEmpty)
                                      .toList();
                            }

                            final updatedChannel = Channel(
                              id: channel.id,
                              title: name,
                              icon: selectedIcon,
                              backgroundColor: dialogSelectedColor,
                              members: channel.members,
                              messages: channel.messages,
                              priority: channel.priority,
                              groups: groups,
                            );

                            setState(() {
                              widget.channels[index] = updatedChannel;
                              _updateAvailableGroups();
                              _updateSortedChannels();
                              // 保存更新后的频道数据到本地存储
                              ChatPlugin.instance.saveChannels();
                            });
                          }
                          Navigator.pop(context);
                        }
                      },
                      child: const Text('保存'),
                    ),
                  ],
                ),
          ),
    );
  }

  void _deleteChannel(Channel channel) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      builder:
          (context) => CustomDialog(
            title: '删除频道',
            content: Text('确定要删除"${channel.title}"频道吗？此操作不可撤销。'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('取消'),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    // 使用新的删除频道方法，它会同时删除频道数据和消息
                    ChatPlugin.instance.deleteChannel(channel.id);
                    _updateSortedChannels();
                  });
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('删除'),
              ),
            ],
          ),
    );
  }

  Widget _buildIconSelector(
    Function(IconData) onIconSelected,
    IconData currentIcon,
    Color backgroundColor,
    Function(Color) onColorSelected,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('选择图标:', style: TextStyle(fontSize: 16)),
        const SizedBox(height: 16),
        CircleIconPicker(
          currentIcon: currentIcon,
          backgroundColor: backgroundColor,
          onIconSelected: onIconSelected,
          onColorSelected: onColorSelected,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: InkWell(
          onTap: () {
            _showGroupSelectionMenu(context);
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [Text(_selectedGroup), const Icon(Icons.arrow_drop_down)],
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddChannelDialog,
          ),
        ],
      ),
      body:
          _sortedChannels.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.chat_bubble_outline,
                      size: 64,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "这里没有任何频道",
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: _showAddChannelDialog,
                      icon: const Icon(Icons.add),
                      label: const Text("点击右上角添加频道"),
                    ),
                  ],
                ),
              )
              : ReorderableListView.builder(
                itemCount: _sortedChannels.length,
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (oldIndex < newIndex) {
                      newIndex -= 1;
                    }
                    final Channel item = _sortedChannels.removeAt(oldIndex);
                    _sortedChannels.insert(newIndex, item);

                    // 更新优先级以反映新的顺序
                    // 在实际应用中，这里应该调用API或数据库操作来持久化排序
                    for (int i = 0; i < _sortedChannels.length; i++) {
                      final channel = _sortedChannels[i];
                      final index = widget.channels.indexWhere(
                        (c) => c.id == channel.id,
                      );
                      if (index != -1) {
                        // 这里我们设置一个优先级，让排序在拖拽后能够保持
                        // 我们使用一个简单的计算方式：最大优先级 - 索引位置
                        // 这样，越靠前的项目优先级越高
                        final newPriority = _sortedChannels.length - i;
                        widget.channels[index].priority = newPriority;
                        // 保存频道排序数据到本地存储
                        ChatPlugin.instance.saveChannels();
                      }
                    }
                  });
                },
                itemBuilder: (context, index) {
                  final channel = _sortedChannels[index];
                  // 使用 ObjectKey 而不是 ValueKey 来避免 GlobalKey 冲突
                  return _buildChannelTile(
                    context,
                    channel,
                    key: ObjectKey(channel),
                  );
                },
              ),
    );
  }

  void _showGroupSelectionMenu(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('选择频道组'),
          content: SingleChildScrollView(
            child: ListBody(
              children:
                  _availableGroups.map((String group) {
                    return ListTile(
                      title: Text(group),
                      onTap: () {
                        Navigator.of(context).pop();
                        if (group != _selectedGroup) {
                          setState(() {
                            _selectedGroup = group;
                            _updateSortedChannels();
                          });
                          _saveSelectedGroup(group);
                        }
                      },
                    );
                  }).toList(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildChannelTile(BuildContext context, Channel channel, {Key? key}) {
    Widget subtitleWidget;
    if (channel.draft != null && channel.draft!.isNotEmpty) {
      subtitleWidget = RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '[草稿] ',
              style: TextStyle(color: Colors.red, fontSize: 13),
            ),
            TextSpan(
              text: channel.draft,
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
          ],
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      );
    } else {
      final lastMessage = channel.lastMessage;
      String subtitle =
          lastMessage != null
              ? '${lastMessage.content}\n${DateFormatter.formatDateTime(lastMessage.date)}'
              : '暂无消息';
      subtitleWidget = Text(
        subtitle,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: Colors.grey[600], fontSize: 13),
      );
    }

    // 确保 key 被正确传递给 ListTile
    return ListTile(
      key: key, // 这个 key 是从 itemBuilder 传入的 ObjectKey
      leading: CircleAvatar(
        backgroundColor: channel.backgroundColor,
        child: Icon(channel.icon, color: Colors.white),
      ),
      title: Text(
        channel.title,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: subtitleWidget,
      trailing: PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert, size: 20),
        onSelected: (value) {
          if (value == 'edit') {
            _showEditChannelDialog(channel);
          } else if (value == 'delete') {
            _deleteChannel(channel);
          }
        },
        itemBuilder:
            (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 20),
                    SizedBox(width: 8),
                    Text('编辑'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 20, color: Colors.red),
                    SizedBox(width: 8),
                    Text('删除', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ChatScreen(channel: channel)),
        );
      },
    );
  }
}
