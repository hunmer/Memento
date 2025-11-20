import 'package:flutter/material.dart';

/// 页面访问记录模型
class PageVisitRecord {
  /// 页面唯一标识符
  final String pageId;

  /// 页面标题（用于显示）
  final String title;

  /// 页面图标的 codePoint（可选）
  final int? iconCodePoint;

  /// 最后访问时间戳
  final int timestamp;

  /// 访问次数
  final int visitCount;

  /// 附加参数（可选，用于恢复页面状态）
  final Map<String, dynamic>? params;

  PageVisitRecord({
    required this.pageId,
    required this.title,
    this.iconCodePoint,
    required this.timestamp,
    this.visitCount = 1,
    this.params,
  });

  /// 从 JSON 创建
  factory PageVisitRecord.fromJson(Map<String, dynamic> json) {
    return PageVisitRecord(
      pageId: json['pageId'] as String,
      title: json['title'] as String,
      iconCodePoint: json['iconCodePoint'] as int?,
      timestamp: json['timestamp'] as int,
      visitCount: json['visitCount'] as int? ?? 1,
      params: json['params'] as Map<String, dynamic>?,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'pageId': pageId,
      'title': title,
      if (iconCodePoint != null) 'iconCodePoint': iconCodePoint,
      'timestamp': timestamp,
      'visitCount': visitCount,
      if (params != null) 'params': params,
    };
  }

  /// 获取图标对象
  IconData? get icon {
    if (iconCodePoint == null) return null;
    return IconData(iconCodePoint!, fontFamily: 'MaterialIcons');
  }

  /// 创建副本（用于更新访问次数和时间）
  PageVisitRecord copyWith({
    String? pageId,
    String? title,
    int? iconCodePoint,
    int? timestamp,
    int? visitCount,
    Map<String, dynamic>? params,
  }) {
    return PageVisitRecord(
      pageId: pageId ?? this.pageId,
      title: title ?? this.title,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      timestamp: timestamp ?? this.timestamp,
      visitCount: visitCount ?? this.visitCount,
      params: params ?? this.params,
    );
  }

  /// 获取相对时间描述
  String getRelativeTime() {
    final now = DateTime.now();
    final visitTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final difference = now.difference(visitTime);

    if (difference.inSeconds < 60) {
      return '刚刚';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}分钟前';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}小时前';
    } else if (difference.inDays == 1) {
      return '昨天 ${visitTime.hour}:${visitTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}天前';
    } else {
      return '${visitTime.month}月${visitTime.day}日';
    }
  }

  @override
  String toString() {
    return 'PageVisitRecord(pageId: $pageId, title: $title, timestamp: $timestamp, visitCount: $visitCount)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PageVisitRecord && other.pageId == pageId;
  }

  @override
  int get hashCode => pageId.hashCode;
}
