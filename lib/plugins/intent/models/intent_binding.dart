import 'dart:convert';

/// Intent 绑定配置
class IntentBinding {
  final String id;
  final String name;
  final String action;
  final String? data;
  final String? dataType;
  final List<String> categories;
  final Map<String, dynamic> extras;
  final bool isEnabled;
  final DateTime createdAt;
  final DateTime updatedAt;

  IntentBinding({
    required this.id,
    required this.name,
    required this.action,
    this.data,
    this.dataType,
    List<String>? categories,
    Map<String, dynamic>? extras,
    this.isEnabled = true,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : categories = categories ?? [],
        extras = extras ?? {},
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'action': action,
      'data': data,
      'dataType': dataType,
      'categories': categories,
      'extras': extras,
      'isEnabled': isEnabled,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// 从 JSON 创建
  factory IntentBinding.fromJson(Map<String, dynamic> json) {
    return IntentBinding(
      id: json['id'] as String,
      name: json['name'] as String,
      action: json['action'] as String,
      data: json['data'] as String?,
      dataType: json['dataType'] as String?,
      categories: (json['categories'] as List<dynamic>).map((e) => e as String).toList(),
      extras: json['extras'] as Map<String, dynamic>? ?? {},
      isEnabled: json['isEnabled'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// 复制并更新
  IntentBinding copyWith({
    String? id,
    String? name,
    String? action,
    String? data,
    String? dataType,
    List<String>? categories,
    Map<String, dynamic>? extras,
    bool? isEnabled,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return IntentBinding(
      id: id ?? this.id,
      name: name ?? this.name,
      action: action ?? this.action,
      data: data ?? this.data,
      dataType: dataType ?? this.dataType,
      categories: categories ?? this.categories,
      extras: extras ?? this.extras,
      isEnabled: isEnabled ?? this.isEnabled,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'IntentBinding{name: $name, action: $action}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is IntentBinding && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Intent 测试结果
class IntentTestResult {
  final String bindingId;
  final bool success;
  final String? error;
  final DateTime timestamp;
  final Map<String, dynamic> data;

  IntentTestResult({
    required this.bindingId,
    required this.success,
    this.error,
    required this.timestamp,
    Map<String, dynamic>? data,
  }) : data = data ?? {};

  Map<String, dynamic> toJson() {
    return {
      'bindingId': bindingId,
      'success': success,
      'error': error,
      'timestamp': timestamp.toIso8601String(),
      'data': data,
    };
  }

  factory IntentTestResult.fromJson(Map<String, dynamic> json) {
    return IntentTestResult(
      bindingId: json['bindingId'] as String,
      success: json['success'] as bool,
      error: json['error'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
      data: json['data'] as Map<String, dynamic>? ?? {},
    );
  }
}

/// 常用 Intent 动作常量
class IntentActions {
  static const String view = 'android.intent.action.VIEW';
  static const String edit = 'android.intent.action.EDIT';
  static const String search = 'android.intent.action.SEARCH';
  static const String webSearch = 'android.intent.action.WEB_SEARCH';
  static const String call = 'android.intent.action.CALL';
  static const String send = 'android.intent.action.SEND';
  static const String sendMultiple = 'android.intent.action.SEND_MULTIPLE';
  static const String pick = 'android.intent.action.PICK';
  static const String getContent = 'android.intent.action.GET_CONTENT';

  /// 获取所有常用动作
  static List<String> get commonActions => [
        view,
        edit,
        search,
        webSearch,
        send,
        getContent,
      ];
}
