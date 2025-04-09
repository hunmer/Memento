import '../../../models/message.dart';

class MessageListBuilder {
  /// 构建带有日期分隔符的消息列表
  static List<dynamic> buildMessageListWithDateSeparators(List<Message> messages, DateTime? selectedDate) {
    if (messages.isEmpty) {
      return [];
    }

    // 创建消息列表的副本
    List<Message> filteredMessages = List.from(messages);

    // 按日期时间升序排序（因为ListView是reverse的，所以这里用升序）
    filteredMessages.sort((a, b) => a.date.millisecondsSinceEpoch.compareTo(b.date.millisecondsSinceEpoch));

    // 构建包含日期分隔符的列表
    List<dynamic> result = [];
    DateTime? lastDate;

    // 由于ListView是reverse的，所以这里反向遍历消息列表
    for (int i = filteredMessages.length - 1; i >= 0; i--) {
      final message = filteredMessages[i];
      final messageDate = DateTime(
        message.date.year,
        message.date.month,
        message.date.day,
      );

      // 如果是新的一天或者是最后一条消息，添加日期分隔符
      if (lastDate == null || !_isSameDay(lastDate, messageDate)) {
        // 添加日期分隔符（如果不是第一条消息）
        if (lastDate != null) {
          result.add(lastDate);
        }
        lastDate = messageDate;
      }
      result.add(message);
    }

    // 添加最后一个日期分隔符
    if (lastDate != null) {
      result.add(lastDate);
    }

    return result;
  }

  /// 判断两个日期是否为同一天
  static bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }
}