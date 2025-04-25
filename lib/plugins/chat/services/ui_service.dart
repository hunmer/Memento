import 'dart:io';
import 'package:flutter/material.dart';
import '../l10n/chat_localizations.dart';
import '../screens/channel_list/channel_list_screen.dart';
import '../screens/timeline/timeline_screen.dart';
import '../screens/profile_edit_dialog.dart';
import '../chat_plugin.dart';
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
                  color: theme.primaryColor.withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _plugin.icon ?? Icons.chat_bubble_outline,
                  size: 24,
                  color: _plugin.color ?? theme.primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                _plugin.name,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 统计信息卡片
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withAlpha(77),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                // 频道数量
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('频道数量', style: theme.textTheme.bodyMedium),
                    Text(
                      '${channels.length}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Divider(),
                const SizedBox(height: 8),

                // 总消息数量
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('总消息数量', style: theme.textTheme.bodyMedium),
                    Text(
                      '${_plugin.channelService.getTotalMessageCount()}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Divider(),
                const SizedBox(height: 8),

                // 今日新增消息
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('今日新增消息', style: theme.textTheme.bodyMedium),
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
              text: l10n?.channelsTab ?? 'Channels',
            ),
            Tab(
              icon: const Icon(Icons.timeline),
              text: l10n?.timelineTab ?? 'Timeline',
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
            const Text(
              '个人资料',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
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
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                // 编辑按钮
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () async {
                    final result = await showDialog<bool>(
                      context: context,
                      builder: (context) => ProfileEditDialog(
                        user: _userService.currentUser,
                        chatPlugin: _plugin,
                      ),
                    );

                    if (result == true) {
                      setState(() {
                        // 对话框中已经更新了用户信息，这里只需要刷新UI
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
        future: _userService.getAvatarPath(currentUser.iconPath!),
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
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              '聊天设置',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SwitchListTile(
            title: const Text('在聊天中显示头像'),
            value: _settingsService.showAvatarInChat,
            onChanged: (bool value) {
              setState(() {
                _settingsService.setShowAvatarInChat(value);
              });
            },
          ),
          SwitchListTile(
            title: const Text('发送消息播放提示音'),
            value: _settingsService.playSoundOnSend,
            onChanged: (bool value) {
              setState(() {
                _settingsService.setPlaySoundOnSend(value);
              });
            },
          ),
        ],
      ),
    );
  }
}