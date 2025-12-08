import 'package:Memento/plugins/chat/models/message.dart';
import 'package:Memento/plugins/chat/chat_plugin.dart';

/// 负责管理消息相关的功能
class MessageService {
  final ChatPlugin _plugin;

  MessageService(this._plugin);

  Future<void> initialize() async {
    // 初始化消息服务
  }

  /// 获取所有频道中的所有消息
  Future<List<Message>> getAllMessages() async {
    List<Message> allMessages = [];

    // 遍历所有频道，收集所有消息
    for (var channel in _plugin.channelService.channels) {
      allMessages.addAll(channel.messages);
    }

    // 按时间排序，最新的消息在前面
    allMessages.sort((a, b) => b.date.compareTo(a.date));

    return allMessages;
  }

  /// 根据消息ID获取完整消息
  Future<Message?> getMessageById(String messageId) async {
    return _plugin.channelService.getMessageById(messageId);
  }

  /// 保存单条消息
  Future<bool> saveMessage(Message message) async {
    return await _plugin.channelService.saveMessage(message);
  }

  /// 更新消息内容
  Future<void> updateMessage(Message message) async {
    await _plugin.channelService.updateMessage(message);
  }
}
