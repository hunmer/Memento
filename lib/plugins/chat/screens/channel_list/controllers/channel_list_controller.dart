import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../models/channel.dart';
import '../../../chat_plugin.dart';

class ChannelListController extends ChangeNotifier {
  final List<Channel> channels;
  final ChatPlugin chatPlugin;
  late List<Channel> sortedChannels = [];
  String selectedGroup = "默认"; // 当前选择的频道组
  late SharedPreferences prefs;
  List<String> availableGroups = ["全部", "默认", "未分组"]; // 可用的频道组列表

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
    selectedGroup = prefs.getString('selectedGroup') ?? "默认";
    _updateSortedChannels();
    notifyListeners();
  }

  Future<void> loadSelectedGroup() async {
    prefs = await SharedPreferences.getInstance();
    selectedGroup = prefs.getString('selectedGroup') ?? "默认";
    notifyListeners();
  }

  Future<void> saveSelectedGroup(String group) async {
    await prefs.setString('selectedGroup', group);
    selectedGroup = group;
    _updateSortedChannels();
    notifyListeners();
  }

  void _updateSortedChannels() {
    if (selectedGroup == "全部") {
      sortedChannels = List<Channel>.from(channels)..sort(Channel.compare);
    } else if (selectedGroup == "未分组") {
      sortedChannels =
          channels.where((channel) => channel.groups.isEmpty).toList()
            ..sort(Channel.compare);
    } else if (selectedGroup == "默认") {
      sortedChannels =
          channels.where((channel) => channel.groups.contains("默认")).toList()
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
    Set<String> groups = {"全部", "默认", "未分组"};
    for (var channel in channels) {
      groups.addAll(channel.groups);
    }
    availableGroups = groups.toList()..sort();
    _updateSortedChannels();
  }

  Future<void> addChannel(Channel channel) async {
    await ChatPlugin.instance.createChannel(channel);
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
      ChatPlugin.instance.saveChannels();
      notifyListeners();
    }
  }

  void deleteChannel(String channelId) {
    ChatPlugin.instance.deleteChannel(channelId);
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
    ChatPlugin.instance.saveChannels();
    notifyListeners();
  }
}
