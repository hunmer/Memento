import 'dart:io';
import 'package:Memento/plugins/chat/models/user.dart';
import 'package:Memento/plugins/goods/widgets/goods_item_form/index.dart';
import 'package:flutter/material.dart';
import 'package:Memento/plugins/chat/l10n/chat_localizations.dart';
import 'package:Memento/plugins/chat/screens/channel_list/channel_list_screen.dart';
import 'package:Memento/plugins/chat/screens/timeline/timeline_screen.dart';
import 'package:Memento/plugins/chat/screens/profile_edit_dialog.dart';
import 'package:Memento/plugins/chat/chat_plugin.dart';
import 'settings_service.dart';
import 'user_service.dart';

/// 负责构建聊天插件的UI界面
class UIService {
  final SettingsService _settingsService;
  final UserService _userService;
  final ChatPlugin _plugin;

  UIService(this._settingsService, this._userService, this._plugin);

  Future<void> initialize() async {
    // 初始化UI服务相关的内容
  }

  Widget buildCardView(BuildContext context) {
    final theme = Theme.of(context);
    final channels = _plugin.channelService.channels;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 顶部图标和标题
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _plugin.color.withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(_plugin.icon, size: 24, color: _plugin.color),
              ),
              const SizedBox(width: 12),
              Text(
                ChatLocalizations.of(context).name,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 统计信息卡片 - 两行显示
          Column(
            children: [
              // 第一行
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Text(
                        ChatLocalizations.of(context).channelCount,
                        style: theme.textTheme.bodyMedium,
                      ),
                      Text(
                        '${channels.length}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const VerticalDivider(),
                  Column(
                    children: [
                      Text(
                        ChatLocalizations.of(context).totalMessages,
                        style: theme.textTheme.bodyMedium,
                      ),
                      Text(
                        '${_plugin.channelService.getTotalMessageCount()}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 第二行
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Text(
                        ChatLocalizations.of(context).totalMessages,
                        style: theme.textTheme.bodyMedium,
                      ),
                      Text(
                        '${_plugin.channelService.getTodayMessageCount()}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color:
                              _plugin.channelService.getTodayMessageCount() > 0
                                  ? theme.colorScheme.primary
                                  : null,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildMainView(BuildContext context) {
    final l10n = ChatLocalizations.of(context);
    final theme = Theme.of(context);
    final channels = _plugin.channelService.channels;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        body: TabBarView(
          children: [
            // 频道列表标签页
            ChannelListScreen(channels: channels, chatPlugin: _plugin),
            // 时间线标签页
            TimelineScreen(chatPlugin: _plugin),
          ],
        ),
        bottomNavigationBar: TabBar(
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
          tabs: [
            Tab(
              icon: const Icon(Icons.chat_bubble_outline),
              text: l10n.channelsTab,
            ),
            Tab(
              icon: const Icon(Icons.timeline),
              text: l10n.timelineTab,
            ),
          ],
        ),
      ),
    );
  }

  Widget buildUserProfileCard(BuildContext context, StateSetter setState) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              ChatLocalizations.of(context).profileTitle,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                // 用户头像
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).colorScheme.primaryContainer,
                  ),
                  child: _buildUserAvatar(context),
                ),
                const SizedBox(width: 16),
                // 用户名和ID
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _userService.currentUser.username,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'ID: ${_userService.currentUser.id}',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                // 编辑按钮
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () async {
                    final updatedUser = await showDialog<User>(
                      context: context,
                      builder:
                          (context) => ProfileEditDialog(
                            user: _userService.currentUser,
                            chatPlugin: _plugin,
                          ),
                    );
                    if (updatedUser != null) {
                      setState(() {
                        // 使用返回的更新后的用户对象刷新UI
                        _userService.setCurrentUser(updatedUser);
                      });
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserAvatar(BuildContext context) {
    final currentUser = _userService.currentUser;
    if (currentUser.iconPath != null) {
      return FutureBuilder<String>(
        future: ImageUtils.getAbsolutePath(currentUser.iconPath!),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data != null) {
            return ClipOval(
              child: Image.file(
                File(snapshot.data!),
                width: 60,
                height: 60,
                fit: BoxFit.cover,
              ),
            );
          }
          return _buildDefaultAvatar(context);
        },
      );
    }
    return _buildDefaultAvatar(context);
  }

  Widget _buildDefaultAvatar(BuildContext context) {
    return Center(
      child: Text(
        _userService.currentUser.username.isNotEmpty
            ? _userService.currentUser.username[0].toUpperCase()
            : '?',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }

  Widget buildChatSettingsCard(BuildContext context, StateSetter setState) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              ChatLocalizations.of(context).chatSettings,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          SwitchListTile(
            title: Text(ChatLocalizations.of(context).showAvatarInChat),
            value: _settingsService.showAvatarInChat,
            onChanged: (bool value) {
              setState(() {
                _settingsService.setShowAvatarInChat(value);
              });
            },
          ),
          SwitchListTile(
            title: Text(ChatLocalizations.of(context).playSoundOnSend),
            value: _settingsService.playSoundOnSend,
            onChanged: (bool value) {
              setState(() {
                _settingsService.setPlaySoundOnSend(value);
              });
            },
          ),
          SwitchListTile(
            title: Text(ChatLocalizations.of(context).showAvatarInTimeline),
            value: _settingsService.showAvatarInTimeline,
            onChanged: (bool value) {
              setState(() {
                _settingsService.setShowAvatarInTimeline(value);
              });
            },
          ),
        ],
      ),
    );
  }
}
