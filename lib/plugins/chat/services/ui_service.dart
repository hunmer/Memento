import 'dart:io';
import 'package:flutter/material.dart';
import '../l10n/chat_localizations.dart';
import '../screens/channel_list/channel_list_screen.dart';
import '../screens/timeline/timeline_screen.dart';
import '../screens/profile_edit_dialog.dart';
import '../chat_plugin.dart';

/// 负责构建聊天插件的UI界面
class UIService {
  final ChatPlugin _plugin;

  UIService(this._plugin);

  Widget buildCardView(BuildContext context) {
    final theme = Theme.of(context);

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
                      '${_plugin.channels.length}',
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
                      '${_plugin.getTotalMessageCount()}',
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
                      '${_plugin.getTodayMessageCount()}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color:
                            _plugin.getTodayMessageCount() > 0
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

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        body: TabBarView(
          children: [
            // 频道列表标签页
            ChannelListScreen(channels: _plugin.channels, chatPlugin: _plugin),
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

  Widget buildSettingsView(BuildContext context) {
    return StatefulBuilder(
      builder: (BuildContext context, StateSetter setState) {
        // final l10n = ChatLocalizations.of(context)!;
        return Column(
          children: [
            // 用户个人资料卡片
            Card(
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
                            color:
                                Theme.of(context).colorScheme.primaryContainer,
                          ),
                          child:
                              _plugin.currentUser.iconPath != null
                                  ? FutureBuilder<String>(
                                    future: _plugin.getAvatarPath(
                                      _plugin.currentUser.iconPath!,
                                    ),
                                    builder: (context, snapshot) {
                                      if (snapshot.hasData &&
                                          snapshot.data != null) {
                                        return ClipOval(
                                          child: Image.file(
                                            File(snapshot.data!),
                                            width: 60,
                                            height: 60,
                                            fit: BoxFit.cover,
                                          ),
                                        );
                                      }
                                      return Center(
                                        child: Text(
                                          _plugin
                                                  .currentUser
                                                  .username
                                                  .isNotEmpty
                                              ? _plugin.currentUser.username[0]
                                                  .toUpperCase()
                                              : '?',
                                          style: TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                            color:
                                                Theme.of(context)
                                                    .colorScheme
                                                    .onPrimaryContainer,
                                          ),
                                        ),
                                      );
                                    },
                                  )
                                  : Center(
                                    child: Text(
                                      _plugin.currentUser.username.isNotEmpty
                                          ? _plugin.currentUser.username[0]
                                              .toUpperCase()
                                          : '?',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color:
                                            Theme.of(
                                              context,
                                            ).colorScheme.onPrimaryContainer,
                                      ),
                                    ),
                                  ),
                        ),
                        const SizedBox(width: 16),
                        // 用户名和ID
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _plugin.currentUser.username,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'ID: ${_plugin.currentUser.id}',
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
                              builder:
                                  (context) => ProfileEditDialog(
                                    user: _plugin.currentUser,
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
            ),
            const SizedBox(height: 16),
            // 聊天设置
            Card(
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
                    value: _plugin.showAvatarInChat,
                    onChanged: (bool value) {
                      setState(() {
                        _plugin.setShowAvatarInChat(value);
                      });
                    },
                  ),
                  SwitchListTile(
                    title: const Text('发送消息播放提示音'),
                    value: _plugin.playSoundOnSend,
                    onChanged: (bool value) {
                      setState(() {
                        _plugin.setPlaySoundOnSend(value);
                      });
                    },
                  ),
                ],
              ),
            ),
            const Divider(),
            // 调用超类的设置视图
            // 注意：UIService 不是 Widget，所以不能使用 super
            // 应该使用 _plugin 的超类方法
            // 调用基类的设置视图
            _plugin.buildSettingsView(context),
          ],
        );
      },
    );
  }
}
