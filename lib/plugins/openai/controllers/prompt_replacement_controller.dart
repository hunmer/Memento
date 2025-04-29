import 'dart:convert';
import 'package:flutter/material.dart';

/// 用于替换prompt中特定方法的回调函数类型
typedef PromptReplacementCallback = Future<String> Function(Map<String, dynamic> params);

/// Prompt替换控制器
/// 用于管理和执行prompt中的方法替换
class PromptReplacementController {
  static final PromptReplacementController _instance = PromptReplacementController._internal();
  factory PromptReplacementController() => _instance;
  PromptReplacementController._internal();

  /// 存储注册的方法映射
  final Map<String, PromptReplacementCallback> _methods = {};

  /// 注册一个新的prompt替换方法
  void registerMethod(String methodName, PromptReplacementCallback callback) {
    _methods[methodName] = callback;
    debugPrint('注册prompt替换方法: $methodName');
  }

  /// 注销一个prompt替换方法
  void unregisterMethod(String methodName) {
    _methods.remove(methodName);
    debugPrint('注销prompt替换方法: $methodName');
  }

  /// 处理prompt中的替换
  /// 查找形如 {method: "methodName", param1: "value1", ...} 的JSON字符串并进行替换
  Future<String> processPrompt(String prompt) async {
    try {
      // 使用正则表达式查找所有 {...} 格式的内容
      final regex = RegExp(r'{[^}]+}');
      String processedPrompt = prompt;

      for (final match in regex.allMatches(prompt)) {
        final jsonStr = match.group(0);
        if (jsonStr == null) continue;

        try {
          final Map<String, dynamic> params = json.decode(jsonStr);
          
          // 检查是否包含method字段
          if (params.containsKey('method')) {
            final methodName = params['method'];
            final callback = _methods[methodName];

            if (callback != null) {
              // 执行对应的方法并替换结果
              final result = await callback(params);
              processedPrompt = processedPrompt.replaceFirst(jsonStr, result);
              debugPrint('替换prompt中的方法: $methodName');
            }
          }
        } catch (e) {
          debugPrint('解析JSON失败: $e');
          // 如果不是有效的JSON或不符合预期格式，跳过这个匹配项
          continue;
        }
      }

      return processedPrompt;
    } catch (e) {
      debugPrint('处理prompt替换时出错: $e');
      return prompt; // 发生错误时返回原始prompt
    }
  }

  /// 清理所有注册的方法
  void dispose() {
    _methods.clear();
    debugPrint('清理所有prompt替换方法');
  }
}