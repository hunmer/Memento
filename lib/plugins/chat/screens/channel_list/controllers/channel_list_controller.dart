import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../models/channel.dart';
import '../../../chat_plugin.dart';

class ChannelListController extends ChangeNotifier {
  final List<Channel> channels;
  final ChatPlugin chatPlugin;
  late List<Channel> sortedChannels = [];
  String selectedGroup = "all"; // 当前选择的频道组
  late SharedPreferences prefs;
  List<String> availableGroups = ["all", "ungrouped"]; // 可用的频道组列表

  ChannelListController({required this.channels, required this.chatPlugin}) {
    _initializePrefs();
    _updateAvailableGroups();
    chatPlugin.addListener(_onChannelsUpdated);
  }

  @override
  void dispose() {
    chatPlugin.removeListener(_onChannelsUpdated);
    super.dispose();
  }

  void _onChannelsUpdated() {
    _updateSortedChannels();
    notifyListeners();
  }

  Future<void> _initializePrefs() async {
    prefs = await SharedPreferences.getInstance();
    selectedGroup = prefs.getString('selectedGroup') ?? "all";
    _updateSortedChannels();
    notifyListeners();
  }

  Future<void> loadSelectedGroup() async {
    prefs = await SharedPreferences.getInstance();
    selectedGroup = prefs.getString('selectedGroup') ?? "all";
    notifyListeners();
  }

  Future<void> saveSelectedGroup(String group) async {
    await prefs.setString('selectedGroup', group);
    selectedGroup = group;
    _updateSortedChannels();
    notifyListeners();
  }

  void _updateSortedChannels() {
    if (selectedGroup == "all") {
      sortedChannels = List<Channel>.from(channels)..sort(Channel.compare);
    } else if (selectedGroup == "ungrouped") {
      sortedChannels =
          channels.where((channel) => channel.groups.isEmpty).toList()
            ..sort(Channel.compare);
    } else {
      sortedChannels =
          channels
              .where((channel) => channel.groups.contains(selectedGroup))
              .toList()
            ..sort(Channel.compare);
    }
  }

  void _updateAvailableGroups() {
    Set<String> groups = {"all", "ungrouped"};
    for (var channel in channels) {
      groups.addAll(channel.groups);
    }
    availableGroups = groups.toList()..sort();
    _updateSortedChannels();
  }

  Future<void> addChannel(Channel channel) async {
    await ChatPlugin.instance.channelService.createChannel(channel);
    _updateAvailableGroups();
    _updateSortedChannels();
    notifyListeners();
  }

  void updateChannel(Channel updatedChannel) {
    final index = channels.indexWhere((c) => c.id == updatedChannel.id);
    if (index != -1) {
      channels[index] = updatedChannel;
      _updateAvailableGroups();
      _updateSortedChannels();
      ChatPlugin.instance.channelService.saveChannels();
      notifyListeners();
    }
  }

  void deleteChannel(String channelId) {
    ChatPlugin.instance.channelService.deleteChannel(channelId);
    _updateSortedChannels();
    notifyListeners();
  }

  void reorderChannels(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final Channel item = sortedChannels.removeAt(oldIndex);
    sortedChannels.insert(newIndex, item);

    // 更新优先级以反映新的顺序
    for (int i = 0; i < sortedChannels.length; i++) {
      final channel = sortedChannels[i];
      final index = channels.indexWhere((c) => c.id == channel.id);
      if (index != -1) {
        final newPriority = sortedChannels.length - i;
        channels[index].priority = newPriority;
      }
    }
    ChatPlugin.instance.channelService.saveChannels();
    notifyListeners();
  }
}
