import '../../../../models/message.dart';

// 定义发送消息的回调函数类型
typedef OnSendMessage =
    void Function(
      String content, {
      Map<String, dynamic>? metadata,
      String type,
      Message? replyTo,
    });
