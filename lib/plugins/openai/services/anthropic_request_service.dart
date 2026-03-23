import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:Memento/plugins/openai/models/ai_agent.dart';
import 'package:http/http.dart' as http;
import 'dart:developer' as developer;

/// Anthropic API 请求服务
///
/// 处理与 Anthropic Claude API 及其兼容 API 的通信
/// 自动兼容各种 Anthropic 格式的 API，无需特殊配置
class AnthropicRequestService {
  /// 流式处理 Anthropic API 响应
  ///
  /// [agent] - AI 助手配置
  /// [systemPrompt] - 系统提示词
  /// [messages] - 消息列表（不包含 system）
  /// [onToken] - 每接收到一个 text token 时的回调
  /// [onThinking] - 每接收到一个 thinking token 时的回调
  /// [onError] - 发生错误时的回调
  /// [onComplete] - 完成时的回调
  /// [filePath] - 图片文件路径（vision 模式）
  /// [shouldCancel] - 检查是否应该取消的函数
  /// [maxTokens] - 最大生成 token 数（Anthropic 必须指定）
  ///
  /// 自动兼容各种 Anthropic 格式的 API，无需特殊配置
  static Future<void> streamResponse({
    required AIAgent agent,
    required String systemPrompt,
    required List<Map<String, dynamic>> messages,
    required Function(String) onToken,
    Function(String)? onThinking,
    required Function(String) onError,
    required Function() onComplete,
    String? filePath,
    bool Function()? shouldCancel,
    int? maxTokens,
  }) async {
    // 统一使用原生 HTTP 请求处理，自动兼容各种 Anthropic 格式 API
    await _streamResponseUniversal(
      agent: agent,
      systemPrompt: systemPrompt,
      messages: messages,
      onToken: onToken,
      onThinking: onThinking,
      onError: onError,
      onComplete: onComplete,
      filePath: filePath,
      shouldCancel: shouldCancel,
      maxTokens: maxTokens,
    );
  }

  /// 统一的 Anthropic 兼容 API 流式响应处理
  ///
  /// 使用原生 HTTP 请求解析 SSE，自动兼容各种 Anthropic 格式 API
  /// 支持 text_delta 和 thinking_delta 等内容块类型
  static Future<void> _streamResponseUniversal({
    required AIAgent agent,
    required String systemPrompt,
    required List<Map<String, dynamic>> messages,
    required Function(String) onToken,
    Function(String)? onThinking,
    required Function(String) onError,
    required Function() onComplete,
    String? filePath,
    bool Function()? shouldCancel,
    int? maxTokens,
  }) async {
    try {
      // 从 headers 中提取 API 密钥
      final apiKey =
          agent.headers['x-api-key'] ??
          agent.headers['X-Api-Key'] ??
          agent.headers['Authorization']?.replaceAll('Bearer ', '') ??
          '';

      developer.log(
        '发送 Anthropic 流式请求: ${agent.model}',
        name: 'AnthropicRequestService',
      );

      // 处理 baseUrl，自动添加 /v1（某些 API 需要此后缀）
      String baseUrl = agent.baseUrl;
      if (baseUrl.isNotEmpty) {
        // 移除末尾的斜杠
        baseUrl = baseUrl.replaceAll(RegExp(r'/+$'), '');
        // 检查是否以 /anthropic 结尾但没有 /v1，自动添加
        if (baseUrl.endsWith('/anthropic') && !baseUrl.endsWith('/v1')) {
          baseUrl = '$baseUrl/v1';
          developer.log(
            '检测到需要 /v1 后缀，自动添加: $baseUrl',
            name: 'AnthropicRequestService',
          );
        }
      }

      developer.log('baseUrl: $baseUrl', name: 'AnthropicRequestService');
      developer.log(
        '系统提示词长度: ${systemPrompt.length}字符',
        name: 'AnthropicRequestService',
      );

      // 转换消息格式为 Anthropic 格式
      final anthropicMessages = await _convertMessages(messages, filePath);

      developer.log(
        '消息数量: ${anthropicMessages.length}条',
        name: 'AnthropicRequestService',
      );

      // 构建请求体
      final requestBody = {
        'model': agent.model,
        'messages': anthropicMessages,
        'max_tokens':
            maxTokens ?? (agent.maxLength > 0 ? agent.maxLength : 4096),
        'stream': true,
        if (systemPrompt.isNotEmpty) 'system': systemPrompt,
        if (agent.temperature > 0) 'temperature': agent.temperature,
        if (agent.topP > 0) 'top_p': agent.topP,
        if (agent.stop != null && agent.stop!.isNotEmpty)
          'stop_sequences': agent.stop,
      };

      final url = Uri.parse('$baseUrl/messages');

      final stopwatch = Stopwatch()..start();

      // 发送请求
      final request = http.Request('POST', url);
      request.headers.addAll({
        'Content-Type': 'application/json',
        'x-api-key': apiKey,
        'anthropic-version': '2023-06-01',
        'anthropic-beta': 'prompt-caching-2024-07-31',
        ...agent.headers,
      });
      request.body = jsonEncode(requestBody);

      final response = await http.Client().send(request);

      if (response.statusCode != 200) {
        final errorBody = await response.stream.bytesToString();
        developer.log(
          'Anthropic API 错误: ${response.statusCode}',
          name: 'AnthropicRequestService',
          error: errorBody,
        );
        onError('API 错误: ${response.statusCode} - $errorBody');
        return;
      }

      int totalChars = 0;
      int chunkCount = 0;
      bool wasCancelled = false;

      // 处理流式响应
      final stream = response.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter());

      await for (final line in stream) {
        // 检查是否应该取消
        if (shouldCancel != null && shouldCancel() && !wasCancelled) {
          developer.log('🛑 流数据处理中检测到取消请求', name: 'AnthropicRequestService');
          wasCancelled = true;
          onError('已取消发送');
          break;
        }

        if (line.isEmpty) continue;

        // 解析 SSE 格式
        String? eventData;
        if (line.startsWith('data: ')) {
          eventData = line.substring(6).trim();
        } else if (line.startsWith('event:')) {
          // 跳过 event 行，等待 data 行
          continue;
        } else {
          continue;
        }

        if (eventData.isEmpty) continue;

        try {
          final json = jsonDecode(eventData) as Map<String, dynamic>;
          final type = json['type'] as String?;

          switch (type) {
            case 'content_block_start':
              final contentBlock =
                  json['content_block'] as Map<String, dynamic>?;
              if (contentBlock != null) {
                final blockType = contentBlock['type'] as String?;
                developer.log(
                  '内容块开始: $blockType',
                  name: 'AnthropicRequestService',
                );
              }
              break;

            case 'content_block_delta':
              final delta = json['delta'] as Map<String, dynamic>?;
              if (delta != null) {
                final deltaType = delta['type'] as String?;
                String? content;

                if (deltaType == 'text_delta') {
                  content = delta['text'] as String?;
                } else if (deltaType == 'thinking_delta') {
                  content = delta['thinking'] as String?;
                }

                if (content != null && content.isNotEmpty) {
                  totalChars += content.length;
                  chunkCount++;

                  // 根据类型调用不同的回调
                  if (deltaType == 'thinking_delta') {
                    // 思考内容使用单独的回调
                    developer.log(
                      '收到思考内容: ${content.length} 字符',
                      name: 'AnthropicRequestService',
                    );
                    onThinking?.call(content);
                  } else {
                    // 普通文本内容
                    onToken(content);
                  }

                  if (chunkCount % 10 == 0) {
                    developer.log(
                      '流式响应进度: $totalChars字符, $chunkCount个块, 已耗时: ${stopwatch.elapsedMilliseconds}ms',
                      name: 'AnthropicRequestService',
                    );
                  }
                }
              }
              break;

            case 'content_block_stop':
              developer.log('内容块结束', name: 'AnthropicRequestService');
              break;

            case 'message_stop':
              developer.log('消息结束', name: 'AnthropicRequestService');
              break;

            case 'error':
              final error = json['error'] as Map<String, dynamic>?;
              final errorMessage = error?['message'] as String? ?? '未知错误';
              developer.log(
                '流式响应错误: $errorMessage',
                name: 'AnthropicRequestService',
              );
              if (!wasCancelled) {
                onError('API 错误: $errorMessage');
              }
              return;
          }
        } catch (e) {
          developer.log('解析流数据失败: $e', name: 'AnthropicRequestService');
        }
      }

      if (!wasCancelled) {
        stopwatch.stop();
        developer.log(
          '流式响应完成: 总计$totalChars字符, $chunkCount个块, 总耗时: ${stopwatch.elapsedMilliseconds}ms',
          name: 'AnthropicRequestService',
        );
        onComplete();
      }
    } catch (e, stackTrace) {
      String errorMessage = e.toString();
      developer.log(
        '处理 AI 响应时出错: $errorMessage',
        name: 'AnthropicRequestService',
        error: e,
        stackTrace: stackTrace,
      );
      onError('处理 AI 响应时出错: $errorMessage');
    }
  }

  /// 将消息列表转换为 Anthropic 格式（JSON）
  ///
  /// Anthropic 的消息格式:
  /// - 不包含 system 消息（system 作为单独参数传递）
  /// - 只有 user 和 assistant 两种角色
  static Future<List<Map<String, dynamic>>> _convertMessages(
    List<Map<String, dynamic>> messages,
    String? imagePath,
  ) async {
    final result = <Map<String, dynamic>>[];

    for (final msg in messages) {
      final role = msg['role'] as String?;
      final content = msg['content'];

      // 跳过 system 消息（Anthropic 使用单独的 system 参数）
      if (role == 'system') continue;

      if (role == 'user') {
        // 处理用户消息
        if (content is String) {
          // 检查是否有图片
          if (imagePath != null && result.isEmpty) {
            // 第一条用户消息附带图片
            final imageBlock = await _loadImageBlock(imagePath);
            if (imageBlock != null) {
              result.add({
                'role': 'user',
                'content': [
                  {'type': 'text', 'text': content},
                  imageBlock,
                ],
              });
            } else {
              result.add({'role': 'user', 'content': content});
            }
          } else {
            result.add({'role': 'user', 'content': content});
          }
        } else if (content is List) {
          // 多部分内容
          final blocks = <Map<String, dynamic>>[];
          for (final part in content) {
            if (part is Map) {
              final type = part['type'] as String?;
              if (type == 'text') {
                blocks.add({
                  'type': 'text',
                  'text': part['text'] as String? ?? '',
                });
              } else if (type == 'image_url') {
                final imageUrl = part['image_url'] as Map?;
                final url = imageUrl?['url'] as String?;
                if (url != null) {
                  // 转换 base64 data URL 为 Anthropic 格式
                  final imageBlock = _convertImageUrl(url);
                  if (imageBlock != null) {
                    blocks.add(imageBlock);
                  }
                }
              }
            }
          }
          result.add({'role': 'user', 'content': blocks});
        }
      } else if (role == 'assistant') {
        // 处理助手消息
        String textContent = '';
        if (content is String) {
          textContent = content;
        } else if (content is List) {
          // 提取文本内容
          for (final part in content) {
            if (part is Map && part['type'] == 'text') {
              textContent = part['text'] as String? ?? '';
              break;
            }
          }
        }
        result.add({'role': 'assistant', 'content': textContent});
      }
    }

    return result;
  }

  /// 加载图片为 Anthropic 格式的 JSON
  static Future<Map<String, dynamic>?> _loadImageBlock(String imagePath) async {
    try {
      final file = File(imagePath);
      if (!await file.exists()) return null;

      final bytes = await file.readAsBytes();
      final base64Data = base64Encode(bytes);

      // 检测图片类型
      String mediaType = 'image/jpeg';
      if (imagePath.endsWith('.png')) {
        mediaType = 'image/png';
      } else if (imagePath.endsWith('.gif')) {
        mediaType = 'image/gif';
      } else if (imagePath.endsWith('.webp')) {
        mediaType = 'image/webp';
      }

      return {
        'type': 'image',
        'source': {
          'type': 'base64',
          'media_type': mediaType,
          'data': base64Data,
        },
      };
    } catch (e) {
      developer.log(
        '加载图片失败: $imagePath',
        name: 'AnthropicRequestService',
        error: e,
      );
      return null;
    }
  }

  /// 转换 OpenAI 格式的 image_url 为 Anthropic 格式（JSON）
  static Map<String, dynamic>? _convertImageUrl(String url) {
    try {
      if (url.startsWith('data:')) {
        // Data URL 格式: data:image/jpeg;base64,xxxx
        final separatorIndex = url.indexOf(',');
        if (separatorIndex == -1) return null;

        final header = url.substring(5, separatorIndex);
        final data = url.substring(separatorIndex + 1);

        // 解析 media type
        final mediaTypeEnd = header.indexOf(';');
        final mediaTypeStr =
            mediaTypeEnd > 0 ? header.substring(0, mediaTypeEnd) : header;

        return {
          'type': 'image',
          'source': {
            'type': 'base64',
            'media_type': mediaTypeStr,
            'data': data,
          },
        };
      }
      // 不支持外部 URL，返回 null
      return null;
    } catch (e) {
      developer.log('转换图片URL失败', name: 'AnthropicRequestService', error: e);
      return null;
    }
  }

  /// 清理资源
  static void dispose() {
    developer.log('清理 Anthropic 服务资源', name: 'AnthropicRequestService');
  }
}
