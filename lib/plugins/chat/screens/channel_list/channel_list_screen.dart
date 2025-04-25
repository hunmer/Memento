import 'package:Memento/core/plugin_manager.dart';
import 'package:flutter/material.dart';
import '../../models/channel.dart';
import '../../chat_plugin.dart';
import '../../l10n/chat_localizations.dart';
import '../chat_screen/chat_screen.dart';
import 'controllers/channel_list_controller.dart';
import 'widgets/channel_tile.dart';
import 'widgets/empty_channel_view.dart';
import 'widgets/channel_group_selector.dart';
import 'widgets/channel_dialogs/channel_dialog.dart';
import 'widgets/channel_dialogs/delete_channel_dialog.dart';

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
  late final ChannelListController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ChannelListController(
      channels: widget.channels,
      chatPlugin: widget.chatPlugin,
    );
    _controller.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => PluginManager.toHomeScreen(context),
        ),
        title: Text(
          ChatLocalizations.of(context)?.channelList ?? 'Channel List',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddChannelDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          ChannelGroupSelector(
            selectedGroup: _controller.selectedGroup,
            availableGroups: _controller.availableGroups,
            onGroupSelected: (group) {
              _controller.saveSelectedGroup(group);
            },
          ),
          Expanded(
            child:
                _controller.sortedChannels.isEmpty
                    ? EmptyChannelView(onAddChannel: _showAddChannelDialog)
                    : ReorderableListView.builder(
                      itemCount: _controller.sortedChannels.length,
                      onReorder: _controller.reorderChannels,
                      itemBuilder: (context, index) {
                        final channel = _controller.sortedChannels[index];
                        return Padding(
                          key: ValueKey(channel.id),
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: ChannelTile(
                            channel: channel,
                            onTap: () => _navigateToChat(channel),
                            onEdit:
                                (channel) => _showEditChannelDialog(channel),
                            onDelete:
                                (channel) => _showDeleteChannelDialog(channel),
                          ),
                        );
                      },
                      buildDefaultDragHandles: false,
                    ),
          ),
        ],
      ),
    );
  }

  void _showAddChannelDialog() {
    showDialog(
      context: context,
      builder: (context) => ChannelDialog(
        onAddChannel: (channel) async {
          await _controller.addChannel(channel);
        },
      ),
    );
  }

  void _showEditChannelDialog(Channel channel) {
    showDialog(
      context: context,
      builder: (context) => ChannelDialog(
        isEditMode: true,
        channel: channel,
        onUpdateChannel: _controller.updateChannel,
      ),
    );
  }

  void _showDeleteChannelDialog(Channel channel) {
    showDialog(
      context: context,
      builder:
          (context) => DeleteChannelDialog(
            channel: channel,
            onDeleteChannel: _controller.deleteChannel,
          ),
    );
  }

  void _navigateToChat(Channel channel) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ChatScreen(channel: channel)),
    );
  }
}
