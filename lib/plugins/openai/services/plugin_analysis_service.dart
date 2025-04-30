import 'package:flutter/services.dart';
import '../models/plugin_analysis_method.dart';
import '../models/ai_agent.dart';

class PluginAnalysisService {
  // 单例模式
  static final PluginAnalysisService _instance = PluginAnalysisService._internal();
  
  factory PluginAnalysisService() => _instance;
  
  PluginAnalysisService._internal();

  // 获取预定义的方法列表
  List<PluginAnalysisMethod> getMethods() {
    return PluginAnalysisMethod.predefinedMethods;
  }

  // 复制JSON到剪贴板
  Future<bool> copyToClipboard(String text) async {
    try {
      await Clipboard.setData(ClipboardData(text: text));
      return true;
    } catch (e) {
      print('Error copying to clipboard: $e');
      return false;
    }
  }

  // 向智能体发送消息并获取响应
  Future<String> sendToAgent(AIAgent agent, String message) async {
    // 这里应该实现与智能体通信的逻辑
    // 目前返回模拟响应
    await Future.delayed(const Duration(seconds: 1)); // 模拟网络延迟
    
    return '已分析完成：\n\n该插件API调用了${message.contains('activity') ? '活动' : '账单'}相关功能，'
           '时间范围是从2025-04-01到2025-05-01。\n\n'
           '建议优化：\n'
           '1. 添加分页参数\n'
           '2. 增加错误处理机制\n'
           '3. 考虑添加缓存策略';
  }
}