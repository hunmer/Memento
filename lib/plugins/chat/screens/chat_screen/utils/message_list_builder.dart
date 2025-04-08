import '../../../models/message.dart';

class MessageListBuilder {
  /// 构建带有日期分隔符的消息列表
  static List<dynamic> buildMessageListWithDateSeparators(List<Message> messages, DateTime? selectedDate) {
    if (messages.isEmpty) {
      return [];
    }

    // 如果有选中日期，则过滤消息
    List<Message> filteredMessages = selectedDate != null
        ? messages.where((msg) {
            final msgDate = DateTime(
              msg.date.year,
              msg.date.month,
              msg.date.day,
            );
            final selected = DateTime(
              selectedDate.year,
              selectedDate.month,
              selectedDate.day,
            );
            return msgDate.isAtSameMomentAs(selected);
          }).toList()
        : List.from(messages);

    // 按日期降序排序
    filteredMessages.sort((a, b) => b.date.compareTo(a.date));

    // 构建包含日期分隔符的列表
    List<dynamic> result = [];
    DateTime? lastDate;

    for (var message in filteredMessages) {
      final messageDate = DateTime(
        message.date.year,
        message.date.month,
        message.date.day,
      );

      if (lastDate == null || !_isSameDay(lastDate, messageDate)) {
        result.add(messageDate);
        lastDate = messageDate;
      }
      result.add(message);
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