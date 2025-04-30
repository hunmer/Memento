import 'package:flutter/services.dart';
import 'dart:async';
import '../models/plugin_analysis_method.dart';
import '../models/ai_agent.dart';
import 'request_service.dart';

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
    final completer = Completer<String>();
    final responseBuffer = StringBuffer();
    
    await RequestService.streamResponse(
      agent: agent,
      prompt: "$message",
      onToken: (token) {
        responseBuffer.write(token);
      },
      onError: (error) {
        if (!completer.isCompleted) {
          completer.completeError(error);
        }
      },
      onComplete: () {
        if (!completer.isCompleted) {
          completer.complete(responseBuffer.toString());
        }
      },
      replacePrompt: true,
    );
    
    return completer.future;
  }
}