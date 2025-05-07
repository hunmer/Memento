import 'package:flutter/material.dart';
import '../../../l10n/chat_localizations.dart';
import '../../../models/channel.dart';
import '../../../models/user.dart';
import '../../../chat_plugin.dart';
import '../models/timeline_filter.dart';

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
    final l10n = ChatLocalizations.of(context);
    final theme = Theme.of(context);
    
    return AlertDialog(
      title: Text(l10n?.advancedFilter ?? 'Advanced Filter'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView(
          shrinkWrap: true,
          children: [
            // 搜索范围选项
            Text(
              l10n?.searchIn ?? 'Search in:',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            
            CheckboxListTile(
              title: Text(l10n?.channelNames ?? 'Channel names'),
              value: _filter.includeChannels,
              onChanged: (value) {
                setState(() {
                  _filter.includeChannels = value ?? true;
                });
              },
              dense: true,
            ),
            
            CheckboxListTile(
              title: Text(l10n?.usernames ?? 'Usernames'),
              value: _filter.includeUsernames,
              onChanged: (value) {
                setState(() {
                  _filter.includeUsernames = value ?? true;
                });
              },
              dense: true,
            ),
            
            CheckboxListTile(
              title: Text(l10n?.messageContent ?? 'Message content'),
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
              'Metadata filters:',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            
            // AI 消息过滤选项
            CheckboxListTile(
              title: const Text('AI Messages'),
              subtitle: const Text('Filter messages created by AI'),
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
              title: const Text('Favorite Messages'),
              subtitle: const Text('Show only favorited messages'),
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
              l10n?.dateRange ?? 'Date range:',
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
                          : l10n?.startDate ?? 'Start date',
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
                          : l10n?.endDate ?? 'End date',
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
                  child: Text(l10n?.clearDates ?? 'Clear dates'),
                ),
              ),
            
            const Divider(),
            
            // 频道选择
            Text(
              l10n?.selectChannels ?? 'Select channels:',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            
            if (_availableChannels.isEmpty)
              Text(l10n?.noChannelsAvailable ?? 'No channels available')
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _availableChannels.map((channel) {
                  final isSelected = _filter.selectedChannelIds.contains(channel.id);
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
              l10n?.selectUsers ?? 'Select users:',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            
            if (_availableUsers.isEmpty)
              Text(l10n?.noUsersAvailable ?? 'No users available')
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _availableUsers.map((user) {
                  final isSelected = _filter.selectedUserIds.contains(user.id);
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
          child: Text(l10n?.cancel ?? 'Cancel'),
        ),
        TextButton(
          onPressed: () {
            _filter.reset();
            setState(() {});
          },
          child: Text(l10n?.reset ?? 'Reset'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop(_filter);
          },
          child: Text(l10n?.apply ?? 'Apply'),
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