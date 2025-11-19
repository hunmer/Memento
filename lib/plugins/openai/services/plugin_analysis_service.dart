import '../models/plugin_analysis_method.dart';

/// 插件分析服务
///
/// 提供获取插件分析方法列表的功能
/// 注意：原有的分析预设管理功能已移除，仅保留方法列表提供
class PluginAnalysisService {
  // 单例模式
  static final PluginAnalysisService _instance = PluginAnalysisService._internal();

  factory PluginAnalysisService() => _instance;

  PluginAnalysisService._internal();

  /// 获取预定义的插件分析方法列表
  ///
  /// 返回所有已注册插件的分析方法
  List<PluginAnalysisMethod> getMethods() {
    return PluginAnalysisMethod.predefinedMethods;
  }
}