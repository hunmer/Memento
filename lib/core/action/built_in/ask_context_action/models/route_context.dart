/// 路由上下文模型
///
/// 封装路由信息和解析后的描述文本
class RouteContext {
  /// 原始路由名称（如：/diary_detail）
  final String routeName;

  /// 路由参数（可能是Map或其他类型）
  final dynamic arguments;

  /// 人类可读的描述文本
  final String description;

  /// 额外的元数据（可选）
  final Map<String, dynamic>? metadata;

  const RouteContext({
    required this.routeName,
    this.arguments,
    required this.description,
    this.metadata,
  });

  @override
  String toString() => 'RouteContext(route: $routeName, desc: $description)';
}
