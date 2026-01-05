part of 'chat_plugin.dart';

/// JS API 定义
@override
Map<String, Function> defineJSAPI() {
  return {

    // 频道相关
    'getChannels': _jsGetChannels,
    'createChannel': _jsCreateChannel,
    'deleteChannel': _jsDeleteChannel,

    // 消息相关
    'sendMessage': _jsSendMessage,
    'getMessages': _jsGetMessages,
    'getMessagesByDate': _jsGetMessagesByDate, // 按日期范围获取所有消息
    'deleteMessage': _jsDeleteMessage,

    // 用户相关
    'getCurrentUser': _jsGetCurrentUser,
    'getAIUser': _jsGetAIUser,

    // 频道查找方法
    'findChannelBy': _jsFindChannelBy,
    'findChannelById': _jsFindChannelById,
    'findChannelByTitle': _jsFindChannelByTitle,

    // 消息查找方法
    'findMessageBy': _jsFindMessageBy,
    'findMessageById': _jsFindMessageById,
    'findMessageByContent': _jsFindMessageByContent,
  };
}

// ==================== JS API 实现 ====================

/// 获取所有频道
/// 支持分页参数: offset, count
Future<String> _jsGetChannels(Map<String, dynamic> params) async {
  final result = await chatUseCase.getChannels(params);
  return result.toJsonString();
}

/// 创建频道
Future<String> _jsCreateChannel(Map<String, dynamic> params) async {
  final result = await chatUseCase.createChannel(params);
  return result.toJsonString();
}

/// 删除频道
Future<String> _jsDeleteChannel(Map<String, dynamic> params) async {
  final result = await chatUseCase.deleteChannel(params);
  return result.toJsonString();
}

/// 发送消息
Future<String> _jsSendMessage(Map<String, dynamic> params) async {
  final result = await chatUseCase.sendMessage(params);
  return result.toJsonString();
}

/// 获取频道消息
/// 支持分页参数: offset, count (或旧版 limit)
Future<String> _jsGetMessages(Map<String, dynamic> params) async {
  final result = await chatUseCase.getMessages(params);
  return result.toJsonString();
}

/// 删除消息
Future<String> _jsDeleteMessage(Map<String, dynamic> params) async {
  final result = await chatUseCase.deleteMessage(params);
  return result.toJsonString();
}

/// 获取当前用户
Future<String> _jsGetCurrentUser(Map<String, dynamic> params) async {
  final result = await chatUseCase.getCurrentUser(params);
  return result.toJsonString();
}

/// 获取 AI 用户
Future<String> _jsGetAIUser(Map<String, dynamic> params) async {
  final result = await chatUseCase.getAIUser();
  return result.toJsonString();
}

// ==================== 频道查找方法 ====================

/// 通用频道查找
/// @param params.field 要匹配的字段名 (必需)
/// @param params.value 要匹配的值 (必需)
/// @param params.findAll 是否返回所有匹配项 (可选，默认 false)
/// @param params.offset 分页起始位置 (可选，仅 findAll=true 时有效)
/// @param params.count 分页返回数量 (可选，仅 findAll=true 时有效，默认 100)
Future<String> _jsFindChannelBy(Map<String, dynamic> params) async {
  final result = await chatUseCase.findChannelBy(params);
  return result.toJsonString();
}

/// 根据ID查找频道
/// @param params.id 频道ID (必需)
Future<String> _jsFindChannelById(Map<String, dynamic> params) async {
  final result = await chatUseCase.findChannelById(params);
  return result.toJsonString();
}

/// 根据标题查找频道
/// @param params.title 频道标题 (必需)
/// @param params.fuzzy 是否模糊匹配 (可选，默认 false)
/// @param params.findAll 是否返回所有匹配项 (可选，默认 false)
/// @param params.offset 分页起始位置 (可选，仅 findAll=true 时有效)
/// @param params.count 分页返回数量 (可选，仅 findAll=true 时有效，默认 100)
Future<String> _jsFindChannelByTitle(Map<String, dynamic> params) async {
  final result = await chatUseCase.findChannelByTitle(params);
  return result.toJsonString();
}

// ==================== 消息查找方法 ====================

/// 通用消息查找
/// @param params.field 要匹配的字段名 (必需)
/// @param params.value 要匹配的值 (必需)
/// @param params.channelId 限定在特定频道内查找 (可选)
/// @param params.findAll 是否返回所有匹配项 (可选，默认 false)
/// @param params.offset 分页起始位置 (可选，仅 findAll=true 时有效)
/// @param params.count 分页返回数量 (可选，仅 findAll=true 时有效，默认 100)
Future<String> _jsFindMessageBy(Map<String, dynamic> params) async {
  final result = await chatUseCase.findMessageBy(params);
  return result.toJsonString();
}

/// 根据ID查找消息
/// @param params.id 消息ID (必需)
/// @param params.channelId 限定在特定频道内查找 (可选)
Future<String> _jsFindMessageById(Map<String, dynamic> params) async {
  final result = await chatUseCase.findMessageById(params);
  return result.toJsonString();
}

/// 根据内容查找消息
/// @param params.content 消息内容 (必需)
/// @param params.fuzzy 是否模糊匹配 (可选，默认 false)
/// @param params.channelId 限定在特定频道内查找 (可选)
/// @param params.findAll 是否返回所有匹配项 (可选，默认 false)
/// @param params.offset 分页起始位置 (可选，仅 findAll=true 时有效)
/// @param params.count 分页返回数量 (可选，仅 findAll=true 时有效，默认 100)
Future<String> _jsFindMessageByContent(Map<String, dynamic> params) async {
  final result = await chatUseCase.findMessageByContent(params);
  return result.toJsonString();
}

/// 根据日期范围获取所有频道的消息
/// @param params.startDate 开始日期，格式 "YYYY-MM-DD" (必需)
/// @param params.endDate 结束日期，格式 "YYYY-MM-DD" (必需)
/// @param params.offset 分页起始位置 (可选)
/// @param params.count 返回数量 (可选，默认 100)
/// @return JSON 字符串，包含消息列表
Future<String> _jsGetMessagesByDate(Map<String, dynamic> params) async {
  try {
    // 验证必需参数
    if (!params.containsKey('startDate')) {
      return '{"error": "缺少必需参数: startDate", "messages": []}';
    }
    if (!params.containsKey('endDate')) {
      return '{"error": "缺少必需参数: endDate", "messages": []}';
    }

    final startDateStr = params['startDate'] as String;
    final endDateStr = params['endDate'] as String;

    // 解析日期
    final startDate = DateTime.parse(startDateStr);
    final endDate = DateTime.parse(endDateStr).add(const Duration(days: 1)); // 包含结束日期当天的消息

    // 获取所有频道
    final channelsResult = await chatUseCase.getChannels({});
    if (channelsResult.isFailure) {
      return '{"error": "获取频道失败", "messages": []}';
    }

    final channelsData = channelsResult.dataOrNull;
    if (channelsData is! List) {
      return '{"error": "频道数据格式错误", "messages": []}';
    }

    final channelsList = channelsData;
    final allMessages = <Map<String, dynamic>>[];

    // 遍历每个频道获取消息
    for (final channelData in channelsList) {
      if (channelData is! Map) continue;

      final channel = channelData as Map<String, dynamic>;
      final channelId = channel['id'] as String?;

      if (channelId == null || channelId.isEmpty) continue;

      try {
        // 获取频道的所有消息
        final messagesResult = await chatUseCase.getMessages({
          'channelId': channelId,
        });

        if (messagesResult.isSuccess) {
          final messagesData = messagesResult.dataOrNull;
          if (messagesData is List) {
            final messages = messagesData;

            // 过滤日期范围内的消息
            for (final msgData in messages) {
              if (msgData is! Map) continue;

              final msg = msgData as Map<String, dynamic>;
              final timestampStr = msg['date'] as String?;

              if (timestampStr != null) {
                try {
                  final timestamp = DateTime.parse(timestampStr);

                  // 检查是否在日期范围内
                  if (timestamp.isAfter(startDate) && timestamp.isBefore(endDate)) {
                    allMessages.add(msg);
                  }
                } catch (e) {
                  // 忽略日期解析错误的消息
                }
              }
            }
          }
        }
      } catch (e) {
        // 忽略获取单个频道消息的错误，继续处理其他频道
        debugPrint('Error getting messages for channel $channelId: $e');
      }
    }

    // 按时间排序（最新的在前）
    allMessages.sort((a, b) {
      final aTime = DateTime.parse(a['date'] as String);
      final bTime = DateTime.parse(b['date'] as String);
      return bTime.compareTo(aTime);
    });

    // 处理分页
    final offset = params['offset'] as int? ?? 0;
    final count = params['count'] as int? ?? 100;

    final paginatedMessages = allMessages.skip(offset).take(count).toList();

    // 返回结果
    final result = {
      'total': allMessages.length,
      'offset': offset,
      'count': count,
      'hasMore': offset + count < allMessages.length,
      'messages': paginatedMessages,
    };

    return const JsonEncoder().convert(result);
  } catch (e) {
    debugPrint('Error in getMessagesByDate: $e');
    return '{"error": "获取消息失败: $e", "messages": []}';
  }
}
