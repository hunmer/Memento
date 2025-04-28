import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/ai_agent.dart';

class AIService {
  /// 流式处理AI响应
  /// 
  /// [agent] - AI助手配置
  /// [prompt] - 用户输入的提示
  /// [onToken] - 每接收到一个完整响应时的回调
  /// [onError] - 发生错误时的回调
  /// [onComplete] - 完成时的回调
  Future<void> streamResponse({
    required AIAgent agent,
    required String prompt,
    required Function(String) onToken,
    required Function(String) onError,
    required Function() onComplete,
  }) async {
    try {
      // 根据不同的服务提供商构建请求
      final baseUrl = agent.baseUrl;
      final headers = Map<String, String>.from(agent.headers);
      
      // 确保headers包含正确的内容类型
      headers['Content-Type'] = 'application/json';
      
      // 构建请求体
      final Map<String, dynamic> requestBody =  {
            'model': agent.model ?? 'gpt-3.5-turbo',
            'messages': [
              {'role': 'system', 'content': agent.systemPrompt},
              {'role': 'user', 'content': prompt},
            ],
            'stream': true,
          };
      
      // 确定正确的API端点
      String endpoint;
      switch (agent.serviceProviderId) {
        default:
          endpoint = '$baseUrl/chat/completions';
      }

      // 发送请求
      final request = http.Request('POST', Uri.parse(endpoint));
      request.headers.addAll(headers);
      request.body = jsonEncode(requestBody);

      developer.log('发送流式请求到: $endpoint', name: 'AIService');
      developer.log('请求头: ${headers.toString()}', name: 'AIService');
      developer.log('请求体: ${request.body}', name: 'AIService');

      // 发送请求并获取流式响应
      final response = await http.Client().send(request);
      
      if (response.statusCode != 200) {
        final errorBody = await response.stream.bytesToString();
        final errorMessage = 'HTTP错误 ${response.statusCode}: $errorBody';
        developer.log(errorMessage, name: 'AIService', error: errorBody);
        onError(errorMessage);
        return;
      }

      developer.log('成功建立流式连接', name: 'AIService');

      // 处理流式响应
      int chunkCount = 0;
      final stopwatch = Stopwatch()..start();

      // 处理真实的流式响应
      await for (var chunk in response.stream.transform(utf8.decoder)) {
        // 根据不同的服务提供商解析响应
        switch (agent.serviceProviderId) {
         default:
            // 处理SSE格式的响应
            final lines = chunk.split('\n');
            for (var line in lines) {
              if (line.startsWith('data: ') && line != 'data: [DONE]') {
                try {
                  final jsonStr = line.substring(6);
                  final json = jsonDecode(jsonStr);
                  
                  // 提取内容
                  final String? content = json['choices']?[0]?['delta']?['content'];
                  if (content != null && content.isNotEmpty) {
                    chunkCount++;
                    onToken(content);
                    
                    if (chunkCount % 10 == 0) {
                      developer.log(
                        '已接收 $chunkCount 个响应块，当前用时: ${stopwatch.elapsedMilliseconds}ms', 
                        name: 'AIService'
                      );
                    }
                  }
                } catch (e) {
                  // 忽略解析错误
                }
              }
            }
            break;
        }
      }

      stopwatch.stop();
      developer.log(
        '流式响应完成：共接收 $chunkCount 个响应块，总用时: ${stopwatch.elapsedMilliseconds}ms',
        name: 'AIService'
      );
      onComplete();
    } catch (e, stackTrace) {
      final errorMessage = '处理AI响应时出错: $e';
      developer.log(
        errorMessage,
        name: 'AIService',
        error: e,
        stackTrace: stackTrace
      );
      onError(errorMessage);
    }
  }
}