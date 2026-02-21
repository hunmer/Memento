/// WebView插件主页小组件数据模型
library;

/// 卡片数据模型
/// 用于从选择器中提取和传递卡片数据
class WebViewCardData {
  final String? id;
  final String? title;
  final String? url;
  final String? type;

  const WebViewCardData({
    this.id,
    this.title,
    this.url,
    this.type,
  });

  /// 从 Map 创建
  factory WebViewCardData.fromMap(Map<String, dynamic> map) {
    return WebViewCardData(
      id: map['id'] as String?,
      title: map['title'] as String?,
      url: map['url'] as String?,
      type: map['type'] as String?,
    );
  }

  /// 转换为 Map
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (url != null) 'url': url,
      if (type != null) 'type': type,
    };
  }

  /// 是否为本地文件
  bool get isLocalFile => type == 'local';
}
