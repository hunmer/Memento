import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:Memento/plugins/openai/models/ai_agent.dart';
import 'package:http/http.dart' as http;
import 'dart:developer' as developer;

/// MiniMax API 请求服务
///
/// 处理与 MiniMax API 的通信
class MiniMaxRequestService {
  /// 流式处理 MiniMax API 响应
  ///
  /// [agent] - AI 助手配置
  /// [systemPrompt] - 系统提示词
  /// [messages] - 消息列表（不包含 system）
  /// [onToken] - 每接收到一个 token 时的回调
  /// [onError] - 发生错误时的回调
  /// [onComplete] - 完成时的回调
  /// [filePath] - 图片文件路径（vision 模式）
  /// [shouldCancel] - 检查是否应该取消的函数
  /// [maxTokens] - 最大生成 token 数
  static Future<void> streamResponse({
    required AIAgent agent,
    required String systemPrompt,
    required List<Map<String, dynamic>> messages,
    required Function(String) onToken,
    required Function(String) onError,
    required Function() onComplete,
    String? filePath,
    bool Function()? shouldCancel,
    int? maxTokens,
  }) async {
    try {
      // 从 headers 中提取 API 密钥
      final apiKey = agent.headers['x-api-key'] ??
          agent.headers['X-Api-Key'] ??
          agent.headers['Authorization']?.replaceAll('Bearer ', '') ??
          '';

      developer.log('发送 MiniMax 流式请求: ${agent.model}', name: 'MiniMaxRequestService');
      developer.log('baseUrl: ${agent.baseUrl}', name: 'MiniMaxRequestService');
      developer.log('系统提示词长度: ${systemPrompt.length}字符', name: 'MiniMaxRequestService');
      developer.log('消息数量: ${messages.length}条', name: 'MiniMaxRequestService');

      // 构建 MiniMax 请求消息
      final apiMessages = <Map<String, dynamic>>[];

      // 添加系统提示词
      if (systemPrompt.isNotEmpty) {
        apiMessages.add({
          'sender_type': 'SYSTEM',
          'sender_name': 'System',
          'text': systemPrompt,
        });
      }

      // 添加用户和助手消息
      for (final msg in messages) {
        final role = msg['role'] as String?;
        final content = msg['content'];

        if (role == 'user') {
          apiMessages.add({
            'sender_type': 'USER',
            'sender_name': 'User',
            'text': content is String ? content : jsonEncode(content),
          });
        } else if (role == 'assistant') {
          apiMessages.add({
            'sender_type': 'BOT',
            'sender_name': 'AI',
            'text': content is String ? content : jsonEncode(content),
          });
        }
      }

      // 构建请求体
      final requestBody = {
        'model': agent.model,
        'messages': apiMessages,
        'stream': true,
        'max_tokens': maxTokens ?? (agent.maxLength > 0 ? agent.maxLength : 2000),
        'temperature': agent.temperature,
        if (agent.topP > 0) 'top_p': agent.topP,
        if (agent.stop != null && agent.stop!.isNotEmpty) 'stop': agent.stop,
      };

      final url = Uri.parse('${agent.baseUrl}/text/chatcompletion_v2');

      final stopwatch = Stopwatch()..start();

      int totalChars = 0;
      int chunkCount = 0;
      bool wasCancelled = false;

      // 发送请求
      final request = http.Request('POST', url);
      request.headers.addAll({
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
        ...agent.headers,
      });
      request.body = jsonEncode(requestBody);

      final response = await http.Client().send(request);

      if (response.statusCode != 200) {
        final errorBody = await response.stream.bytesToString();
        developer.log(
          'MiniMax API 错误: ${response.statusCode}',
          name: 'MiniMaxRequestService',
          error: errorBody,
        );
        onError('MiniMax API 错误: ${response.statusCode} - $errorBody');
        return;
      }

      // 处理流式响应
      final stream = response.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter());

      await for (final line in stream) {
        // 检查是否应该取消
        if (shouldCancel != null && shouldCancel() && !wasCancelled) {
          developer.log('🛑 流数据处理中检测到取消请求', name: 'MiniMaxRequestService');
          wasCancelled = true;
          onError('已取消发送');
          break;
        }

        if (line.isEmpty) continue;
        if (!line.startsWith('data: ')) continue;

        final data = line.substring(6).trim();
        if (data == '[DONE]') continue;

        try {
          final json = jsonDecode(data) as Map<String, dynamic>;
          final choices = json['choices'] as List?;
          if (choices != null && choices.isNotEmpty) {
            final choice = choices.first as Map<String, dynamic>;
            final delta = choice['delta'] as Map<String, dynamic>?;
            if (delta != null) {
              final content = delta['text'] as String?;
              if (content != null && content.isNotEmpty) {
                totalChars += content.length;
                chunkCount++;
                onToken(content);

                // 每10个块记录一次进度
                if (chunkCount % 10 == 0) {
                  developer.log(
                    '流式响应进度: $totalChars字符, $chunkCount个块, 已耗时: ${stopwatch.elapsedMilliseconds}ms',
                    name: 'MiniMaxRequestService',
                  );
                }
              }
            }
          }
        } catch (e) {
          developer.log('解析流数据失败: $e', name: 'MiniMaxRequestService');
        }
      }

      if (!wasCancelled) {
        stopwatch.stop();
        developer.log(
          '流式响应完成: 总计$totalChars字符, $chunkCount个块, 总耗时: ${stopwatch.elapsedMilliseconds}ms',
          name: 'MiniMaxRequestService',
        );
        onComplete();
      }
    } catch (e, stackTrace) {
      String errorMessage = e.toString();
      developer.log(
        '处理 MiniMax 响应时出错: $errorMessage',
        name: 'MiniMaxRequestService',
        error: e,
        stackTrace: stackTrace,
      );
      onError('处理AI响应时出错: $errorMessage');
    }
  }
}
