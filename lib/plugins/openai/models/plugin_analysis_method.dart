class PluginAnalysisMethod {
  final String name;
  final String title;
  final Map<String, dynamic> template;

  const PluginAnalysisMethod({
    required this.name,
    required this.title,
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
      title: '获取活动列表',
      template: {
        'method': 'activity_getActivitys',
        'startDate': '2025-04-01',
        'endDate': '2025-05-01',
      },
    ),
    PluginAnalysisMethod(
      name: 'bill_getBills',
      title: '获取账单列表',
      template: {
        'method': 'bill_getBills',
        'startDate': '2025-04-01',
        'endDate': '2025-05-01',
      },
    ),
    PluginAnalysisMethod(
      name: 'checkin_getCheckinHistory',
      title: '获取打卡历史记录',
      template: {
        'method': 'checkin_getCheckinHistory',
        'startDate': '2025-04-01',
        'endDate': '2025-05-01',
      },
    ),
    PluginAnalysisMethod(
      name: 'diary_getDiaries',
      title: '获取日记列表',
      template: {
        'method': 'diary_getDiaries',
        'startDate': '2025-04-15',
        'endDate': '2025-05-03',
      },
    ),
  ];
}