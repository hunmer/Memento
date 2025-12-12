/// Proxy 规则配置
class ProxyRule {
  /// Proxy 服务器地址，格式: "http://host:port" 或 "http://user:pass@host:port"
  final String url;

  /// 协议过滤器（可选）: "http", "https" 等
  final String? schemeFilter;

  /// 主机过滤器（可选）: 例如 "example.com"
  final String? hostFilter;

  /// 端口过滤器（可选）: 例如 8080
  final int? portFilter;

  /// 路径过滤器（可选）: 例如 "/api/*"
  final String? pathFilter;

  ProxyRule({
    required this.url,
    this.schemeFilter,
    this.hostFilter,
    this.portFilter,
    this.pathFilter,
  });

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      if (schemeFilter != null) 'schemeFilter': schemeFilter,
      if (hostFilter != null) 'hostFilter': hostFilter,
      if (portFilter != null) 'portFilter': portFilter,
      if (pathFilter != null) 'pathFilter': pathFilter,
    };
  }

  factory ProxyRule.fromJson(Map<String, dynamic> json) {
    return ProxyRule(
      url: json['url'] as String,
      schemeFilter: json['schemeFilter'] as String?,
      hostFilter: json['hostFilter'] as String?,
      portFilter: json['portFilter'] as int?,
      pathFilter: json['pathFilter'] as String?,
    );
  }

  ProxyRule copyWith({
    String? url,
    String? schemeFilter,
    String? hostFilter,
    int? portFilter,
    String? pathFilter,
  }) {
    return ProxyRule(
      url: url ?? this.url,
      schemeFilter: schemeFilter ?? this.schemeFilter,
      hostFilter: hostFilter ?? this.hostFilter,
      portFilter: portFilter ?? this.portFilter,
      pathFilter: pathFilter ?? this.pathFilter,
    );
  }

  @override
  String toString() {
    final filters = <String>[];
    if (schemeFilter != null) filters.add('scheme=$schemeFilter');
    if (hostFilter != null) filters.add('host=$hostFilter');
    if (portFilter != null) filters.add('port=$portFilter');
    if (pathFilter != null) filters.add('path=$pathFilter');

    if (filters.isEmpty) {
      return url;
    }
    return '$url [${filters.join(', ')}]';
  }
}

/// Proxy 设置（仅 Android 支持）
class ProxySettings {
  /// 是否启用 proxy
  final bool enabled;

  /// Proxy 规则列表
  final List<ProxyRule> proxyRules;

  /// 绕过规则列表（匹配的 URL 不使用 proxy）
  final List<String> bypassRules;

  /// 反转绕过规则（true: 仅对匹配的使用 proxy，其他直连）
  final bool reverseBypassEnabled;

  ProxySettings({
    this.enabled = false,
    this.proxyRules = const [],
    this.bypassRules = const [],
    this.reverseBypassEnabled = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'proxyRules': proxyRules.map((r) => r.toJson()).toList(),
      'bypassRules': bypassRules,
      'reverseBypassEnabled': reverseBypassEnabled,
    };
  }

  factory ProxySettings.fromJson(Map<String, dynamic> json) {
    return ProxySettings(
      enabled: json['enabled'] as bool? ?? false,
      proxyRules: (json['proxyRules'] as List<dynamic>?)
              ?.map((e) => ProxyRule.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      bypassRules:
          (json['bypassRules'] as List<dynamic>?)?.cast<String>() ?? [],
      reverseBypassEnabled: json['reverseBypassEnabled'] as bool? ?? false,
    );
  }

  ProxySettings copyWith({
    bool? enabled,
    List<ProxyRule>? proxyRules,
    List<String>? bypassRules,
    bool? reverseBypassEnabled,
  }) {
    return ProxySettings(
      enabled: enabled ?? this.enabled,
      proxyRules: proxyRules ?? this.proxyRules,
      bypassRules: bypassRules ?? this.bypassRules,
      reverseBypassEnabled: reverseBypassEnabled ?? this.reverseBypassEnabled,
    );
  }

  /// 是否有有效的 proxy 配置
  bool get hasValidConfig => enabled && proxyRules.isNotEmpty;
}
