import 'parameter_definition.dart';

// 导入所有插件的分析方法定义
import '../../activity/analysis_methods.dart';
import '../../bill/analysis_methods.dart';
import '../../calendar/analysis_methods.dart';
import '../../calendar_album/analysis_methods.dart';
import '../../chat/analysis_methods.dart';
import '../../checkin/analysis_methods.dart';
import '../../database/analysis_methods.dart';
import '../../contact/analysis_methods.dart';
import '../../day/analysis_methods.dart';
import '../../diary/analysis_methods.dart';
import '../../goods/analysis_methods.dart';
import '../../habits/analysis_methods.dart';
import '../../nodes/analysis_methods.dart';
import '../../notes/analysis_methods.dart';
import '../../scripts_center/analysis_methods.dart';
import '../../store/analysis_methods.dart';
import '../../timer/analysis_methods.dart';
import '../../todo/analysis_methods.dart';
import '../../tracker/analysis_methods.dart';

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

  /// 预定义的方法列表 - 自动聚合所有插件的分析方法
  ///
  /// 新增插件方法时，只需在对应插件目录下的 analysis_methods.dart 文件中添加即可
  /// 无需修改此文件
  static List<PluginAnalysisMethod> get predefinedMethods => [
    ...activityAnalysisMethods,
    ...billAnalysisMethods,
    ...calendarAnalysisMethods,
    ...calendarAlbumAnalysisMethods,
    ...chatAnalysisMethods,
    ...checkinAnalysisMethods,
    ...databaseAnalysisMethods,
    ...contactAnalysisMethods,
    ...dayAnalysisMethods,
    ...diaryAnalysisMethods,
    ...goodsAnalysisMethods,
    ...habitsAnalysisMethods,
    ...nodesAnalysisMethods,
    ...notesAnalysisMethods,
    ...scriptsCenterAnalysisMethods,
    ...storeAnalysisMethods,
    ...timerAnalysisMethods,
    ...todoAnalysisMethods,
    ...trackerAnalysisMethods,
  ];
}
