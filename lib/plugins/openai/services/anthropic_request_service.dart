import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:anthropic_sdk_dart/anthropic_sdk_dart.dart';
import 'package:Memento/plugins/openai/models/ai_agent.dart';
import 'dart:developer' as developer;

/// Anthropic API 请求服务
///
/// 处理与 Anthropic Claude API 的通信
class AnthropicRequestService {
  static final Map<String, AnthropicClient> _clients = {};

  /// 获取或创建 Anthropic 客户端
  static AnthropicClient _getClient(AIAgent agent) {
    // 从 headers 中提取 API 密钥
    // Anthropic 使用 x-api-key 或 Authorization: Bearer
    final apiKey = agent.headers['x-api-key'] ??
        agent.headers['X-Api-Key'] ??
        agent.headers['Authorization']?.replaceAll('Bearer ', '') ??
        '';

    developer.log('创建 Anthropic 客户端: ${agent.id}', name: 'AnthropicRequestService');
    developer.log('baseUrl: ${agent.baseUrl}', name: 'AnthropicRequestService');
    developer.log('model: ${agent.model}', name: 'AnthropicRequestService');

    return AnthropicClient(
      apiKey: apiKey,
      baseUrl: agent.baseUrl.isNotEmpty ? agent.baseUrl : null,
    );
  }

  /// 流式处理 Anthropic API 响应
  ///
  /// [agent] - AI 助手配置
  /// [systemPrompt] - 系统提示词
  /// [messages] - 消息列表（不包含 system）
  /// [onToken] - 每接收到一个 token 时的回调
  /// [onError] - 发生错误时的回调
  /// [onComplete] - 完成时的回调
  /// [filePath] - 图片文件路径（vision 模式）
  /// [shouldCancel] - 检查是否应该取消的函数
  /// [maxTokens] - 最大生成 token 数（Anthropic 必须指定）
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
      final client = _getClient(agent);

      // 转换消息格式为 Anthropic 格式
      final anthropicMessages = await _convertMessages(messages, filePath);

      developer.log(
        '发送 Anthropic 流式请求: ${agent.model}',
        name: 'AnthropicRequestService',
      );
      developer.log(
        '系统提示词长度: ${systemPrompt.length}字符',
        name: 'AnthropicRequestService',
      );
      developer.log(
        '消息数量: ${anthropicMessages.length}条',
        name: 'AnthropicRequestService',
      );

      final request = CreateMessageRequest(
        model: Model.modelId(agent.model),
        messages: anthropicMessages,
        system: systemPrompt.isNotEmpty
            ? CreateMessageRequestSystem.text(systemPrompt)
            : null,
        maxTokens: maxTokens ?? (agent.maxLength > 0 ? agent.maxLength : 4096),
        temperature: agent.temperature,
        topP: agent.topP > 0 ? agent.topP : null,
        stopSequences: agent.stop,
      );

      final stopwatch = Stopwatch()..start();
      final stream = client.createMessageStream(request: request);

      int totalChars = 0;
      int chunkCount = 0;
      bool wasCancelled = false;

      StreamSubscription? subscription;
      Timer? cancelCheckTimer;
      final completer = Completer<void>();

      // 定期检查是否需要取消
      if (shouldCancel != null) {
        cancelCheckTimer = Timer.periodic(const Duration(milliseconds: 100), (
          timer,
        ) {
          if (shouldCancel() && !wasCancelled) {
            developer.log('🛑 定时检查发现取消请求', name: 'AnthropicRequestService');
            wasCancelled = true;
            timer.cancel();
            subscription?.cancel();
            onError('已取消发送');
            if (!completer.isCompleted) {
              completer.complete();
            }
          }
        });
      }

      subscription = stream.listen(
        (event) {
          // 检查是否应该取消
          if (shouldCancel != null && shouldCancel() && !wasCancelled) {
            developer.log('🛑 流数据处理中检测到取消请求', name: 'AnthropicRequestService');
            wasCancelled = true;
            cancelCheckTimer?.cancel();
            subscription?.cancel();
            onError('已取消发送');
            if (!completer.isCompleted) {
              completer.complete();
            }
            return;
          }

          // 处理 Anthropic 流式事件
          event.map(
            messageStart: (e) {
              developer.log('消息开始', name: 'AnthropicRequestService');
            },
            contentBlockStart: (e) {
              developer.log('内容块开始', name: 'AnthropicRequestService');
            },
            contentBlockDelta: (e) {
              final delta = e.delta;
              if (delta is TextBlockDelta) {
                final content = delta.text;
                if (content.isNotEmpty) {
                  totalChars += content.length;
                  chunkCount++;
                  onToken(content);
                }
              }
            },
            contentBlockStop: (e) {
              developer.log('内容块结束', name: 'AnthropicRequestService');
            },
            messageDelta: (e) {
              developer.log('消息增量', name: 'AnthropicRequestService');
            },
            messageStop: (e) {
              developer.log('消息结束', name: 'AnthropicRequestService');
            },
            ping: (e) {
              developer.log('Ping', name: 'AnthropicRequestService');
            },
            error: (e) {
              final error = e.error;
              developer.log(
                '流式响应错误: ${error.message}',
                name: 'AnthropicRequestService',
                error: error,
              );
              if (!wasCancelled) {
                onError('处理AI响应时出错: ${error.message}');
              }
            },
          );
        },
        onError: (error) {
          cancelCheckTimer?.cancel();
          if (!wasCancelled) {
            String errorMessage = error.toString();
            developer.log(
              '流式响应错误: $errorMessage',
              name: 'AnthropicRequestService',
              error: error,
            );
            onError('处理AI响应时出错: $errorMessage');
          }
          if (!completer.isCompleted) {
            completer.complete();
          }
        },
        onDone: () {
          cancelCheckTimer?.cancel();
          if (!wasCancelled) {
            stopwatch.stop();
            developer.log(
              '流式响应完成: 总计$totalChars字符, $chunkCount个块, 总耗时: ${stopwatch.elapsedMilliseconds}ms',
              name: 'AnthropicRequestService',
            );
            onComplete();
          }
          if (!completer.isCompleted) {
            completer.complete();
          }
        },
        cancelOnError: true,
      );

      // 等待流处理完成
      await completer.future;

      // 确保资源被清理
      cancelCheckTimer?.cancel();
      await subscription.cancel();
    } catch (e, stackTrace) {
      String errorMessage = e.toString();
      developer.log(
        '处理AI响应时出错: $errorMessage',
        name: 'AnthropicRequestService',
        error: e,
        stackTrace: stackTrace,
      );
      onError('处理AI响应时出错: $errorMessage');
    }
  }

  /// 将消息列表转换为 Anthropic 格式
  ///
  /// Anthropic 的消息格式:
  /// - 不包含 system 消息（system 作为单独参数传递）
  /// - 只有 user 和 assistant 两种角色
  static Future<List<Message>> _convertMessages(
    List<Map<String, dynamic>> messages,
    String? imagePath,
  ) async {
    final result = <Message>[];

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
              result.add(
                Message(
                  role: MessageRole.user,
                  content: MessageContent.blocks([
                    Block.text(text: content),
                    imageBlock,
                  ]),
                ),
              );
            } else {
              result.add(
                Message(
                  role: MessageRole.user,
                  content: MessageContent.text(content),
                ),
              );
            }
          } else {
            result.add(
              Message(
                role: MessageRole.user,
                content: MessageContent.text(content),
              ),
            );
          }
        } else if (content is List) {
          // 多部分内容
          final blocks = <Block>[];
          for (final part in content) {
            if (part is Map) {
              final type = part['type'] as String?;
              if (type == 'text') {
                blocks.add(Block.text(text: part['text'] as String? ?? ''));
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
          result.add(Message(role: MessageRole.user, content: MessageContent.blocks(blocks)));
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
        result.add(
          Message(
            role: MessageRole.assistant,
            content: MessageContent.text(textContent),
          ),
        );
      }
    }

    return result;
  }

  /// 加载图片为 Block
  static Future<Block?> _loadImageBlock(String imagePath) async {
    try {
      final file = File(imagePath);
      if (!await file.exists()) return null;

      final bytes = await file.readAsBytes();
      final base64Data = base64Encode(bytes);

      // 检测图片类型
      ImageBlockSourceMediaType mediaType = ImageBlockSourceMediaType.imageJpeg;
      if (imagePath.endsWith('.png')) {
        mediaType = ImageBlockSourceMediaType.imagePng;
      } else if (imagePath.endsWith('.gif')) {
        mediaType = ImageBlockSourceMediaType.imageGif;
      } else if (imagePath.endsWith('.webp')) {
        mediaType = ImageBlockSourceMediaType.imageWebp;
      }

      return Block.image(
        source: ImageBlockSource(
          type: ImageBlockSourceType.base64,
          mediaType: mediaType,
          data: base64Data,
        ),
      );
    } catch (e) {
      developer.log(
        '加载图片失败: $imagePath',
        name: 'AnthropicRequestService',
        error: e,
      );
      return null;
    }
  }

  /// 转换 OpenAI 格式的 image_url 为 Anthropic 格式
  static Block? _convertImageUrl(String url) {
    try {
      if (url.startsWith('data:')) {
        // Data URL 格式: data:image/jpeg;base64,xxxx
        final separatorIndex = url.indexOf(',');
        if (separatorIndex == -1) return null;

        final header = url.substring(5, separatorIndex);
        final data = url.substring(separatorIndex + 1);

        // 解析 media type
        final mediaTypeEnd = header.indexOf(';');
        final mediaTypeStr = mediaTypeEnd > 0
            ? header.substring(0, mediaTypeEnd)
            : header;

        // 转换为枚举
        ImageBlockSourceMediaType mediaType;
        switch (mediaTypeStr) {
          case 'image/png':
            mediaType = ImageBlockSourceMediaType.imagePng;
            break;
          case 'image/gif':
            mediaType = ImageBlockSourceMediaType.imageGif;
            break;
          case 'image/webp':
            mediaType = ImageBlockSourceMediaType.imageWebp;
            break;
          default:
            mediaType = ImageBlockSourceMediaType.imageJpeg;
        }

        return Block.image(
          source: ImageBlockSource(
            type: ImageBlockSourceType.base64,
            mediaType: mediaType,
            data: data,
          ),
        );
      }
      // 不支持外部 URL，返回 null
      return null;
    } catch (e) {
      developer.log(
        '转换图片URL失败',
        name: 'AnthropicRequestService',
        error: e,
      );
      return null;
    }
  }

  /// 清理客户端资源
  static void dispose() {
    developer.log(
      '清理所有 Anthropic 客户端资源: ${_clients.length}个客户端',
      name: 'AnthropicRequestService',
    );
    _clients.clear();
  }
}
