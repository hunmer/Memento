import 'package:flutter/material.dart';

/// 卡片类型枚举
enum CardType {
  url,       // 在线 URL
  localFile, // 本地文件
}

/// WebView 网址卡片/书签模型
class WebViewCard {
  final String id;
  String title;
  String url;
  CardType type;
  String? description;
  String? iconUrl;
  Color? backgroundColor;
  int? iconCodePoint;
  final DateTime createdAt;
  DateTime updatedAt;
  int openCount;
  bool isPinned;
  List<String> tags;
  String? groupId;
  String? sourcePath; // 原始路径（用于本地文件同步）

  WebViewCard({
    required this.id,
    required this.title,
    required this.url,
    required this.type,
    this.description,
    this.iconUrl,
    this.backgroundColor,
    this.iconCodePoint,
    required this.createdAt,
    required this.updatedAt,
    this.openCount = 0,
    this.isPinned = false,
    this.tags = const [],
    this.groupId,
    this.sourcePath,
  });

  /// 获取 Material 图标
  IconData? get icon =>
      iconCodePoint != null ? IconData(iconCodePoint!, fontFamily: 'MaterialIcons') : null;

  /// 获取显示用的 URL（本地文件显示文件名）
  String get displayUrl {
    if (type == CardType.localFile) {
      return url.split('/').last;
    }
    return url;
  }

  /// 检查是否为本地文件
  bool get isLocalFile => type == CardType.localFile;

  /// 获取域名（用于在线 URL）
  String? get domain {
    if (type != CardType.url) return null;
    try {
      final uri = Uri.parse(url);
      return uri.host;
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'url': url,
      'type': type.name,
      'description': description,
      'iconUrl': iconUrl,
      'backgroundColor': backgroundColor?.value,
      'iconCodePoint': iconCodePoint,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'openCount': openCount,
      'isPinned': isPinned,
      'tags': tags,
      'groupId': groupId,
      'sourcePath': sourcePath,
    };
  }

  factory WebViewCard.fromJson(Map<String, dynamic> json) {
    return WebViewCard(
      id: json['id'] as String,
      title: json['title'] as String,
      url: json['url'] as String,
      type: CardType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => CardType.url,
      ),
      description: json['description'] as String?,
      iconUrl: json['iconUrl'] as String?,
      backgroundColor:
          json['backgroundColor'] != null ? Color(json['backgroundColor'] as int) : null,
      iconCodePoint: json['iconCodePoint'] as int?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      openCount: json['openCount'] as int? ?? 0,
      isPinned: json['isPinned'] as bool? ?? false,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      groupId: json['groupId'] as String?,
      sourcePath: json['sourcePath'] as String?,
    );
  }

  WebViewCard copyWith({
    String? id,
    String? title,
    String? url,
    CardType? type,
    String? description,
    String? iconUrl,
    Color? backgroundColor,
    int? iconCodePoint,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? openCount,
    bool? isPinned,
    List<String>? tags,
    String? groupId,
    String? sourcePath,
  }) {
    return WebViewCard(
      id: id ?? this.id,
      title: title ?? this.title,
      url: url ?? this.url,
      type: type ?? this.type,
      description: description ?? this.description,
      iconUrl: iconUrl ?? this.iconUrl,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      openCount: openCount ?? this.openCount,
      isPinned: isPinned ?? this.isPinned,
      tags: tags ?? List.from(this.tags),
      groupId: groupId ?? this.groupId,
      sourcePath: sourcePath ?? this.sourcePath,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WebViewCard && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
