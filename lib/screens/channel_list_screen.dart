import 'package:flutter/material.dart';
import '../models/channel.dart';
import '../utils/date_formatter.dart';
import '../widgets/custom_dialog.dart';
import '../widgets/circle_icon_picker.dart';
import 'chat_screen.dart';
import '../plugins/chat/chat_plugin.dart';

class ChannelListScreen extends StatefulWidget {
  final List<Channel> channels;

  const ChannelListScreen({super.key, required this.channels});

  @override
  State<ChannelListScreen> createState() => _ChannelListScreenState();
}

class _ChannelListScreenState extends State<ChannelListScreen> {
  late List<Channel> _sortedChannels;

  @override
  void initState() {
    super.initState();
    _updateSortedChannels();
  }

  void _updateSortedChannels() {
    _sortedChannels = List<Channel>.from(widget.channels)
      ..sort(Channel.compare);
  }

  void _showAddChannelDialog() {
    final TextEditingController nameController = TextEditingController();
    IconData selectedIcon = Icons.chat;

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
                        _buildIconSelector((icon) {
                          setDialogState(() {
                            selectedIcon = icon;
                          });
                        }, selectedIcon),
                        const SizedBox(height: 16),
                        TextField(
                          controller: nameController,
                          decoration: const InputDecoration(
                            labelText: '频道名称',
                            border: OutlineInputBorder(),
                          ),
                          autofocus: true,
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
                          final newChannel = Channel(
                            id:
                                DateTime.now().millisecondsSinceEpoch
                                    .toString(),
                            title: name,
                            icon: selectedIcon,
                            members: [], // 初始为空，或添加当前用户
                            messages: [], // 初始为空
                            priority: 0,
                          );

                          setState(() {
                            widget.channels.add(newChannel);
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

  void _showPluginSettingsDialog() {
    final TextEditingController dirController = TextEditingController(
      text: ChatPlugin.instance.customPluginDir,
    );

    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setDialogState) => CustomDialog(
                  title: '插件设置',
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('插件UUID: ${ChatPlugin.instance.uuid}'),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: dirController,
                                decoration: const InputDecoration(
                                  labelText: '数据保存位置',
                                  border: OutlineInputBorder(),
                                  hintText: '留空则使用默认位置',
                                ),
                                readOnly: true,
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.folder_open),
                              onPressed: () async {
                                final selectedDir =
                                    await ChatPlugin.instance.pickDirectory();
                                if (selectedDir != null) {
                                  setDialogState(() {
                                    dirController.text = selectedDir;
                                  });
                                }
                              },
                              tooltip: '选择目录',
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '当前数据位置: ${ChatPlugin.instance.pluginDir}',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
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
                        final newDir = dirController.text.trim();
                        ChatPlugin.instance.setCustomPluginDir(newDir);
                        Navigator.pop(context);
                        // 刷新UI以显示新的路径
                        setState(() {});
                      },
                      child: const Text('保存'),
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
    IconData selectedIcon = channel.icon;

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
                        _buildIconSelector((icon) {
                          // 使用对话框内部的setState
                          setDialogState(() {
                            selectedIcon = icon;
                          });
                        }, selectedIcon),
                        const SizedBox(height: 16),
                        TextField(
                          controller: nameController,
                          decoration: const InputDecoration(
                            labelText: '频道名称',
                            border: OutlineInputBorder(),
                          ),
                          autofocus: true,
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
                            final updatedChannel = Channel(
                              id: channel.id,
                              title: name,
                              icon: selectedIcon,
                              members: channel.members,
                              messages: channel.messages,
                              priority: channel.priority,
                            );

                            setState(() {
                              widget.channels[index] = updatedChannel;
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
                    widget.channels.removeWhere((c) => c.id == channel.id);
                    _updateSortedChannels();
                    // 保存删除后的频道数据到本地存储
                    ChatPlugin.instance.saveChannels();
                    // 删除该频道的消息文件
                    ChatPlugin.instance.deleteChannelMessages(channel.id);
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
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('选择图标:', style: TextStyle(fontSize: 16)),
        const SizedBox(height: 16),
        CircleIconPicker(
          currentIcon: currentIcon,
          onIconSelected: onIconSelected,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('聊天'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showPluginSettingsDialog,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddChannelDialog,
          ),
        ],
      ),
      body: ReorderableListView.builder(
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
          return _buildChannelTile(context, channel, key: ObjectKey(channel));
        },
      ),
    );
  }

  Widget _buildChannelTile(BuildContext context, Channel channel, {Key? key}) {
    final lastMessage = channel.lastMessage;
    final subtitle =
        lastMessage != null
            ? '${lastMessage.content}\n${DateFormatter.formatDateTime(lastMessage.date)}'
            : '暂无消息';

    // 确保 key 被正确传递给 ListTile
    return ListTile(
      key: key, // 这个 key 是从 itemBuilder 传入的 ObjectKey
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: Icon(channel.icon, color: Colors.white),
      ),
      title: Text(
        channel.title,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        subtitle,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: Colors.grey[600], fontSize: 13),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (channel.priority > 0)
            const Padding(
              padding: EdgeInsets.only(right: 8.0),
              child: Icon(Icons.star, color: Colors.amber, size: 20),
            ),
          PopupMenuButton<String>(
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
