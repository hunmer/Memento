import 'package:flutter/material.dart';
import '../models/ai_agent.dart';

class TestService {
  /// 显示长文本输入对话框
  static Future<String?> showLongTextInputDialog(
    BuildContext context, {
    String title = '测试输入',
    String hintText = '请输入测试文本',
    String initialValue = '',
  }) async {
    final TextEditingController controller = TextEditingController(text: initialValue);
    
    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: controller,
                    maxLines: 10,
                    decoration: InputDecoration(
                      hintText: hintText,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('取消'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('确定'),
              onPressed: () {
                Navigator.of(context).pop(controller.text);
              },
            ),
          ],
        );
      },
    ).then((value) {
      controller.dispose();
      return value;
    });
  }

  /// 模拟发送请求并获取响应
  static Future<String> processTestRequest(String input, AIAgent agent) async {
    // 这里可以实现真实的API调用逻辑
    // 目前只是模拟一个响应
    await Future.delayed(const Duration(seconds: 1)); // 模拟网络延迟
    
    final response = '''
根据您的输入: "${input.length > 50 ? '${input.substring(0, 50)}...' : input}"
    
作为${agent.name}(${agent.type})，我的回应是:

${_generateMockResponse(input, agent)}

---
系统提示词: ${agent.systemPrompt.length > 30 ? '${agent.systemPrompt.substring(0, 30)}...' : agent.systemPrompt}
标签: ${agent.tags.join(', ')}
''';
    
    return response;
  }
  
  /// 生成模拟响应
  static String _generateMockResponse(String input, AIAgent agent) {
    if (input.isEmpty) {
      return "您没有提供任何输入。请提供一些文本以便我能够回应。";
    }
    
    final wordCount = input.split(' ').length;
    final charCount = input.length;
    
    switch (agent.type) {
      case 'Assistant':
        return "我很乐意帮助您解答问题。您的输入包含了约$wordCount个单词，$charCount个字符。";
      case 'Translator':
        return "已将您的文本翻译完成。原文包含约$wordCount个单词，$charCount个字符。";
      case 'Writer':
        return "基于您的提示，我创作了一篇内容。您的输入包含约$wordCount个单词，$charCount个字符。";
      case 'Analyst':
        return "分析完成。您提供的数据包含约$wordCount个单词，$charCount个字符。主要发现：这是一个测试响应。";
      case 'Developer':
        return "```\n// 代码生成完成\nfunction processText(text) {\n  console.log('处理文本，长度:', $charCount);\n  return 'Processed: ' + text;\n}\n```";
      default:
        return "已收到您的输入。文本长度为$charCount个字符。这是一个测试响应。";
    }
  }
  
  /// 显示响应结果对话框
  static void showResponseDialog(BuildContext context, String response) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('测试响应'),
          content: SingleChildScrollView(
            child: SelectableText(response),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('关闭'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}