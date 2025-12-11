/// WebView 标签页模型
class WebViewTab {
  final String id;
  String url;
  String title;
  String? favicon;
  final DateTime createdAt;
  DateTime lastAccessedAt;
  bool isActive;
  double scrollPosition;
  bool canGoBack;
  bool canGoForward;
  bool isLoading;
  double progress;

  WebViewTab({
    required this.id,
    required this.url,
    this.title = '',
    this.favicon,
    required this.createdAt,
    required this.lastAccessedAt,
    this.isActive = false,
    this.scrollPosition = 0.0,
    this.canGoBack = false,
    this.canGoForward = false,
    this.isLoading = false,
    this.progress = 0.0,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      'title': title,
      'favicon': favicon,
      'createdAt': createdAt.toIso8601String(),
      'lastAccessedAt': lastAccessedAt.toIso8601String(),
      'isActive': isActive,
      'scrollPosition': scrollPosition,
      'canGoBack': canGoBack,
      'canGoForward': canGoForward,
      'isLoading': isLoading,
      'progress': progress,
    };
  }

  factory WebViewTab.fromJson(Map<String, dynamic> json) {
    return WebViewTab(
      id: json['id'] as String,
      url: json['url'] as String,
      title: json['title'] as String? ?? '',
      favicon: json['favicon'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastAccessedAt: DateTime.parse(json['lastAccessedAt'] as String),
      isActive: json['isActive'] as bool? ?? false,
      scrollPosition: (json['scrollPosition'] as num?)?.toDouble() ?? 0.0,
      canGoBack: json['canGoBack'] as bool? ?? false,
      canGoForward: json['canGoForward'] as bool? ?? false,
      isLoading: json['isLoading'] as bool? ?? false,
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
    );
  }

  WebViewTab copyWith({
    String? id,
    String? url,
    String? title,
    String? favicon,
    DateTime? createdAt,
    DateTime? lastAccessedAt,
    bool? isActive,
    double? scrollPosition,
    bool? canGoBack,
    bool? canGoForward,
    bool? isLoading,
    double? progress,
  }) {
    return WebViewTab(
      id: id ?? this.id,
      url: url ?? this.url,
      title: title ?? this.title,
      favicon: favicon ?? this.favicon,
      createdAt: createdAt ?? this.createdAt,
      lastAccessedAt: lastAccessedAt ?? this.lastAccessedAt,
      isActive: isActive ?? this.isActive,
      scrollPosition: scrollPosition ?? this.scrollPosition,
      canGoBack: canGoBack ?? this.canGoBack,
      canGoForward: canGoForward ?? this.canGoForward,
      isLoading: isLoading ?? this.isLoading,
      progress: progress ?? this.progress,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WebViewTab && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
