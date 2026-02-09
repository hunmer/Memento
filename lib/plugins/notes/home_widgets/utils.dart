/// 笔记插件主页小组件工具函数
library;

import 'package:flutter/material.dart';

/// 笔记插件主题色
const Color notesColor = Color.fromARGB(255, 61, 204, 185);

/// 格式化笔记时间为相对时间显示
String formatNoteTime(String isoTime) {
  try {
    final date = DateTime.parse(isoTime);
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return '刚刚';
    if (diff.inHours < 1) return '${diff.inMinutes}分钟前';
    if (diff.inDays < 1) return '${diff.inHours}小时前';
    if (diff.inDays < 7) return '${diff.inDays}天前';
    return '${date.month}/${date.day}';
  } catch (e) {
    return '';
  }
}

/// 从选择器数据数组中提取文件夹数据
Map<String, dynamic> extractFolderData(List<dynamic> dataArray) {
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
  result['folderPath'] = itemData['folderPath'] as String?;
  result['icon'] = itemData['icon'] as int?;
  result['color'] = itemData['color'] as int?;
  result['notesCount'] = itemData['notesCount'] as int?;
  return result;
}
