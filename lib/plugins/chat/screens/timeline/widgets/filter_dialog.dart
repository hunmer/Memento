import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/plugins/chat/models/channel.dart';
import 'package:Memento/plugins/chat/models/user.dart';
import 'package:Memento/plugins/chat/chat_plugin.dart';
import 'package:Memento/plugins/chat/screens/timeline/models/timeline_filter.dart';

/// 高级过滤器对话框
class FilterDialog extends StatefulWidget {
  final TimelineFilter filter;
  final ChatPlugin chatPlugin;

  const FilterDialog({
    super.key,
    required this.filter,
    required this.chatPlugin,
  });

  @override
  State<FilterDialog> createState() => _FilterDialogState();
}

class _FilterDialogState extends State<FilterDialog> {
  late TimelineFilter _filter;
  late List<Channel> _availableChannels;
  late List<User> _availableUsers;

  @override
  void initState() {
    super.initState();
    // 创建过滤器的副本以便在对话框中编辑
    _filter = widget.filter.copyWith();

    // 获取所有可用的频道和用户
    _availableChannels = widget.chatPlugin.channelService.channels;

    // 从所有频道中收集唯一的用户
    final Set<String> userIds = {};
    final List<User> users = [];

    for (final channel in _availableChannels) {
      for (final message in channel.messages) {
        if (!userIds.contains(message.user.id)) {
          userIds.add(message.user.id);
          users.add(message.user);
        }
      }
    }

    _availableUsers = users;
  }

  @override
  Widget build(BuildContext context) {

    final theme = Theme.of(context);

    return AlertDialog(
      title: Text('chat_advancedFilter'.tr),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView(
          shrinkWrap: true,
          children: [
            // 搜索范围选项
            Text(
              'chat_searchIn'.tr,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),

            CheckboxListTile(
              title: Text('chat_channelNames'.tr),
              value: _filter.includeChannels,
              onChanged: (value) {
                setState(() {
                  _filter.includeChannels = value ?? true;
                });
              },
              dense: true,
            ),

            CheckboxListTile(
              title: Text('chat_usernames'.tr),
              value: _filter.includeUsernames,
              onChanged: (value) {
                setState(() {
                  _filter.includeUsernames = value ?? true;
                });
              },
              dense: true,
            ),

            CheckboxListTile(
              title: Text('chat_messageContent'.tr),
              value: _filter.includeContent,
              onChanged: (value) {
                setState(() {
                  _filter.includeContent = value ?? true;
                });
              },
              dense: true,
            ),

            const Divider(),

            // 元数据过滤选项
            Text(
              'chat_metadataFilters'.tr,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),

            // AI 消息过滤选项
            CheckboxListTile(
              title: Text('chat_aiMessages'.tr),
              subtitle: Text('chat_filterAiMessages'.tr),
              value: _filter.isAI,
              tristate: true,
              onChanged: (value) {
                setState(() {
                  _filter.isAI = value;
                });
              },
              dense: true,
            ),

            // 收藏消息过滤选项
            CheckboxListTile(
              title: Text('chat_favoriteMessages'.tr),
              subtitle: Text('chat_showOnlyFavorites'.tr),
              value: _filter.isFavorite,
              tristate: true,
              onChanged: (value) {
                setState(() {
                  _filter.isFavorite = value;
                });
              },
              dense: true,
            ),

            const Divider(),

            // 日期范围选择
            Text(
              'chat_dateRange'.tr,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.calendar_today),
                    label: Text(
                      _filter.startDate != null
                          ? '${_filter.startDate!.day}/${_filter.startDate!.month}/${_filter.startDate!.year}'
                          : 'chat_startDate'.tr,
                    ),
                    onPressed: () => _selectDate(context, true),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.calendar_today),
                    label: Text(
                      _filter.endDate != null
                          ? '${_filter.endDate!.day}/${_filter.endDate!.month}/${_filter.endDate!.year}'
                          : 'chat_endDate'.tr,
                    ),
                    onPressed: () => _selectDate(context, false),
                  ),
                ),
              ],
            ),

            if (_filter.startDate != null || _filter.endDate != null)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    setState(() {
                      _filter.startDate = null;
                      _filter.endDate = null;
                    });
                  },
                  child: Text('chat_clearDates'.tr),
                ),
              ),

            const Divider(),

            // 频道选择
            Text(
              'chat_selectChannels'.tr,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),

            if (_availableChannels.isEmpty)
              Text('chat_noChannelsAvailable'.tr)
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    _availableChannels.map((channel) {
                      final isSelected = _filter.selectedChannelIds.contains(
                        channel.id,
                      );
                      return FilterChip(
                        label: Text(channel.title),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _filter.selectedChannelIds.add(channel.id);
                            } else {
                              _filter.selectedChannelIds.remove(channel.id);
                            }
                          });
                        },
                      );
                    }).toList(),
              ),

            const SizedBox(height: 16),

            // 用户选择
            Text(
              'chat_selectUsers'.tr,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),

            if (_availableUsers.isEmpty)
              Text('chat_noUsersAvailable'.tr)
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    _availableUsers.map((user) {
                      final isSelected = _filter.selectedUserIds.contains(
                        user.id,
                      );
                      return FilterChip(
                        avatar: CircleAvatar(
                          child: Text(user.username[0].toUpperCase()),
                        ),
                        label: Text(user.username),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _filter.selectedUserIds.add(user.id);
                            } else {
                              _filter.selectedUserIds.remove(user.id);
                            }
                          });
                        },
                      );
                    }).toList(),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text('app_cancel'.tr),
        ),
        TextButton(
          onPressed: () {
            _filter.reset();
            setState(() {});
          },
          child: Text('app_reset'.tr),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop(_filter.toJson());
          },
          child: Text('app_apply'.tr),
        ),
      ],
    );
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final initialDate = isStartDate ? _filter.startDate : _filter.endDate;
    final now = DateTime.now();

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1),
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _filter.startDate = picked;
          // 确保结束日期不早于开始日期
          if (_filter.endDate != null && _filter.endDate!.isBefore(picked)) {
            _filter.endDate = picked;
          }
        } else {
          _filter.endDate = picked;
          // 确保开始日期不晚于结束日期
          if (_filter.startDate != null && _filter.startDate!.isAfter(picked)) {
            _filter.startDate = picked;
          }
        }
      });
    }
  }
}
