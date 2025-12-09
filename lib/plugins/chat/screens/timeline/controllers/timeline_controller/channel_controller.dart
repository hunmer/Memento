import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/plugins/chat/models/channel.dart';
import 'package:Memento/plugins/chat/models/message.dart';
import 'base_controller.dart';

/// 频道相关功能的混入类
mixin ChannelControllerMixin on BaseTimelineController {
  /// 获取所有频道
  List<Channel> get allChannels => chatPlugin.channelService.channels;

  /// 获取所有用户ID
  Set<String> getAllUserIds() {
    final userIds = <String>{};
    for (final message in allMessages) {
      userIds.add(message.user.id);
    }
    return userIds;
  }

  /// 获取所有频道ID
  Set<String> getAllChannelIds() {
    final channelIds = <String>{};
    for (final message in allMessages) {
      final channelId = message.channelId;
      if (channelId != null) {
        channelIds.add(channelId);
      }
    }
    return channelIds;
  }

  /// 根据ID获取频道
  Channel? getChannelById(String channelId) {
    try {
      return chatPlugin.channelService.channels.firstWhere(
        (c) => c.id == channelId,
      );
    } catch (e) {
      return null;
    }
  }

  /// 获取频道名称
  String getChannelName(String channelId) {
    final channel = getChannelById(channelId);
    return channel?.title ?? '未知频道';
  }

  /// 获取频道消息
  List<Message> getChannelMessages(String channelId) {
    return allMessages.where((message) {
      return message.channelId == channelId;
    }).toList();
  }

  /// 跳转到特定频道
  void navigateToChannel(BuildContext context, String channelId) {
    final channel = getChannelById(channelId);
    if (channel != null) {
      // chatPlugin.navigateToChannel(context, channel);
    } else {
      debugPrint('Timeline: 无法导航到频道，ID: \$channelId 不存在');
    }
  }
}