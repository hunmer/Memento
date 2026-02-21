/// 计时器插件主页小组件工具函数
library;

import 'package:Memento/core/services/plugin_data_selector/models/selector_result.dart';

/// 格式化时长
String formatDuration(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes % 60;
  final seconds = duration.inSeconds % 60;

  if (hours > 0) {
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
  return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
}

/// 从 SelectorResult 获取任务 ID
String? getTaskIdFromResult(SelectorResult result) {
  if (result.data == null) return null;
  // result.data 是 List，取第一个元素的 id
  if (result.data is List && result.data.isNotEmpty) {
    final first = result.data.first;
    if (first is Map<String, dynamic>) {
      return first['id'] as String?;
    }
  }
  if (result.data is Map<String, dynamic>) {
    return (result.data as Map<String, dynamic>)['id'] as String?;
  }
  return null;
}

/// 从选择器数据数组中提取小组件需要的数据
Map<String, dynamic> extractTimerData(List<dynamic> dataArray) {
  Map<String, dynamic> itemData = {};
  final rawData = dataArray[0];

  if (rawData is Map<String, dynamic>) {
    itemData = rawData;
  } else if (rawData is dynamic && rawData.toJson != null) {
    final jsonResult = rawData.toJson();
    if (jsonResult is Map<String, dynamic>) {
      itemData = jsonResult;
    }
  }

  final result = <String, dynamic>{};
  result['id'] = itemData['id'] as String?;
  result['name'] = itemData['name'] as String?;
  result['icon'] = itemData['icon'] as int?;
  result['color'] = itemData['color'] as int?;
  return result;
}

/// 获取计时器类型描述
String getTimerTypeDescription(int typeIndex, int durationSeconds) {
  switch (typeIndex) {
    case 0: // 正计时
      return '正计时';
    case 1: // 倒计时
      return '倒计时 ${durationSeconds}s';
    case 2: // 番茄钟
      return '番茄钟';
    default:
      return '';
  }
}
