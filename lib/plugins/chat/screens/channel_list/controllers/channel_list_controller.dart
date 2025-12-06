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
  String searchQuery = ""; // 搜索关键词

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
    List<Channel> tempChannels;
    if (selectedGroup == "all") {
      tempChannels = List<Channel>.from(channels);
    } else if (selectedGroup == "ungrouped") {
      tempChannels = channels.where((channel) => channel.groups.isEmpty).toList();
    } else {
      tempChannels =
          channels.where((channel) => channel.groups.contains(selectedGroup)).toList();
    }

    // 去重：确保每个 ID 只出现一次（保留第一个出现的）
    final seenIds = <String>{};
    sortedChannels = tempChannels.where((channel) {
      if (seenIds.contains(channel.id)) {
        return false;
      }
      seenIds.add(channel.id);
      return true;
    }).toList()..sort(Channel.compare);
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

  /// 获取过滤后的频道列表（应用搜索和分组过滤）
  List<Channel> get filteredChannels {
    List<Channel> filtered = List.from(sortedChannels);

    // 应用搜索过滤
    if (searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      filtered = filtered.where((channel) {
        return channel.title.toLowerCase().contains(query);
      }).toList();
    }

    return filtered;
  }

  /// 设置搜索关键词
  void setSearchQuery(String query) {
    searchQuery = query;
    notifyListeners();
  }

  /// 清除搜索
  void clearSearch() {
    searchQuery = "";
    notifyListeners();
  }
}
