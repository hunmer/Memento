class PluginAnalysisMethod {
  final String name;
  final Map<String, dynamic> template;

  const PluginAnalysisMethod({
    required this.name,
    required this.template,
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
      result = result.substring(0, result.length - 2) + '\n';
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

  // 预定义的方法列表
  static List<PluginAnalysisMethod> get predefinedMethods => [
    PluginAnalysisMethod(
      name: 'activity_getActivitys',
      template: {
        'method': 'activity_getActivitys',
        'startDate': '2025-04-01',
        'endDate': '2025-05-01',
      },
    ),
    PluginAnalysisMethod(
      name: 'bill_getBills',
      template: {
        'method': 'bill_getBills',
        'startDate': '2025-04-01',
        'endDate': '2025-05-01',
      },
    ),
  ];
}