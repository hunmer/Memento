import 'parameter_definition.dart';

class PluginAnalysisMethod {
  final String name;
  final String title;
  final Map<String, dynamic> template;
  final String? pluginId;
  final List<ParameterDefinition>? parameters; // 参数定义列表

  const PluginAnalysisMethod({
    required this.name,
    required this.title,
    required this.template,
    this.pluginId,
    this.parameters,
  });

  String get formattedJson {
    return _prettyPrintJson(template);
  }

  // 格式化JSON字符串
  String _prettyPrintJson(Map<String, dynamic> json) {
    var indent = '  ';
    var result = '{\n';

    json.forEach((key, value) {
      result += '$indent"$key": ${_formatValue(value)},\n';
    });

    // 移除最后一个逗号
    if (result.endsWith(',\n')) {
      result = '${result.substring(0, result.length - 2)}\n';
    }

    result += '}';
    return result;
  }

  String _formatValue(dynamic value) {
    if (value is String) {
      return '"$value"';
    }
    return value.toString();
  }

  /// @deprecated 已废弃 - 请使用 jsAPI + 字段过滤参数代替
  ///
  /// 新架构说明:
  /// - 所有 jsAPI 方法现在自动支持 mode/fields/excludeFields 参数
  /// - 无需再定义单独的分析方法
  /// - 参考文档: docs/JSAPI_FILTER_INTEGRATION.md
  static List<PluginAnalysisMethod> get predefinedMethods => [];
}
