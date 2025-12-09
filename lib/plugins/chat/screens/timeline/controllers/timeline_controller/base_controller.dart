import 'package:flutter/material.dart';
import 'package:Memento/plugins/chat/models/message.dart';
import 'package:Memento/plugins/chat/screens/timeline/models/timeline_filter.dart';
import 'package:Memento/plugins/chat/chat_plugin.dart';

/// Timeline 基础控制器，包含共享状态和基本功能
abstract class BaseTimelineController extends ChangeNotifier {
  final ChatPlugin chatPlugin;
  final TextEditingController searchController;
  final ScrollController scrollController;

  // 消息操作回调
  final void Function(Message)? onMessageEdit;
  final Future<void> Function(Message)? onMessageDelete;
  final void Function(Message)? onMessageCopy;
  final void Function(Message, String?)? onSetFixedSymbol;
  final void Function(Message, Color?)? onSetBubbleColor;
  final void Function(Message)? onToggleFavorite;

  // 共享状态
  List<Message> allMessages = [];
  List<Message> filteredMessages = [];
  List<Message> displayMessages = [];
  bool isLoading = false;
  String searchQuery = '';
  final TimelineFilter filter;
  bool isFilterActive = false;

  /// 获取当前显示的消息列表
  List<Message> get messages => displayMessages;

  BaseTimelineController({
    required this.chatPlugin,
    required this.searchController,
    required this.scrollController,
    required this.filter,
    this.onMessageEdit,
    this.onMessageDelete,
    this.onMessageCopy,
    this.onSetFixedSymbol,
    this.onSetBubbleColor,
    this.onToggleFavorite,
  });

  /// 保存时间线状态的抽象方法
  Future<void> saveTimelineState();

  @override
  void dispose() {
    searchController.dispose();
    scrollController.dispose();
    super.dispose();
  }
}
