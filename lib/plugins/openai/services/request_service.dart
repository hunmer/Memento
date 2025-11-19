import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:openai_dart/openai_dart.dart';
import '../models/ai_agent.dart';
import 'prompt_preset_service.dart';
import 'dart:developer' as developer;

class RequestService {
  /// 获取有效的系统提示词
  /// 如果 agent 设置了 promptPresetId，则返回预设的内容
  /// 否则返回 agent 原有的 systemPrompt
  static Future<String> getEffectiveSystemPrompt(AIAgent agent) async {
    developer.log(
      '检查 Agent ${agent.name} 的 Prompt 预设: promptPresetId=${agent.promptPresetId}',
      name: 'RequestService',
    );

    if (agent.promptPresetId != null && agent.promptPresetId!.isNotEmpty) {
      developer.log(
        '正在获取预设 Prompt: ${agent.promptPresetId}',
        name: 'RequestService',
      );
      final presetContent = await PromptPresetService().getPresetContent(agent.promptPresetId);
      if (presetContent != null && presetContent.isNotEmpty) {
        developer.log(
          '✓ 使用预设 Prompt (${agent.promptPresetId}), 长度: ${presetContent.length}字符',
          name: 'RequestService',
        );
        return presetContent;
      } else {
        developer.log(
          '⚠ 预设 ${agent.promptPresetId} 未找到或为空，使用原始 systemPrompt',
          name: 'RequestService',
        );
      }
    } else {
      developer.log(
        '未设置预设，使用原始 systemPrompt (长度: ${agent.systemPrompt.length}字符)',
        name: 'RequestService',
      );
    }
    return agent.systemPrompt;
  }

  /// 处理思考内容，将<think>标签转换为Markdown格式
  static String processThinkingContent(String content) {
    // 使用正则表达式匹配<think>标签内的内容
    final thinkPattern = RegExp(r'<think>(.*?)</think>', dotAll: true);

    // 创建一个StringBuffer来构建最终的内容
    final StringBuffer result = StringBuffer();
    int lastMatchEnd = 0;

    // 查找所有匹配项
    for (final match in thinkPattern.allMatches(content)) {
      // 添加标签之前的内容（不在think标签内的内容）
      result.write(content.substring(lastMatchEnd, match.start));

      // 获取标签内的文本
      String thinkContent = match.group(1) ?? '';

      // 如果内容不为空，则格式化并添加
      if (thinkContent.trim().isNotEmpty) {
        // 分割成行，为每行添加前缀 ">"
        String formattedContent = thinkContent
            .split('\n')
            .map((line) => line.trim().isEmpty ? '>' : '> $line')
            .join('\n');

        // 添加格式化后的内容
        result.write(formattedContent);
      }

      // 更新lastMatchEnd为当前匹配的结束位置
      lastMatchEnd = match.end;
    }

    // 添加最后一个标签之后的内容
    result.write(content.substring(lastMatchEnd));

    return result.toString();
  }

  static final Map<String, OpenAIClient> _clients = {};

  /// 获取或创建OpenAI客户端（公开方法，供其他服务使用）
  static OpenAIClient getClient(AIAgent agent) => _getClient(agent);

  /// 获取或创建OpenAI客户端（内部实现）
  static OpenAIClient _getClient(AIAgent agent) {
    // 从headers中提取API密钥
    final apiKey =
        agent.headers['Authorization']?.replaceAll('Bearer ', '') ??
        agent.headers['api-key'] ??
        '';

    // 可选的组织ID
    final organization = agent.headers['OpenAI-Organization'];

    developer.log('创建新的OpenAI客户端: ${agent.id}', name: 'RequestService');
    developer.log('baseUrl: ${agent.baseUrl}', name: 'RequestService');
    developer.log('model: ${agent.model}', name: 'RequestService');

    // 创建新的headers对象，合并api-key和Authorization
    final Map<String, String> mergedHeaders = Map<String, String>.from(
      agent.headers,
    );
    mergedHeaders['api-key'] = apiKey;
    mergedHeaders['Authorization'] = 'Bearer $apiKey';
    print(mergedHeaders);
    return OpenAIClient(
      apiKey: apiKey,
      organization: organization,
      baseUrl: agent.baseUrl,
      headers: mergedHeaders,
    );
  }

  /// 发送聊天请求
  static Future<String> chat(
    String input,
    AIAgent agent, {
    File? imageFile,
    List<ChatCompletionMessage>? contextMessages,
  }) async {
    try {
      developer.log('开始聊天请求: ${agent.id}', name: 'RequestService');
      developer.log('用户输入: $input', name: 'RequestService');

      final client = _getClient(agent);

      // 获取有效的系统提示词（可能是预设）
      final effectiveSystemPrompt = await getEffectiveSystemPrompt(agent);

      late final CreateChatCompletionRequest request;

      if (imageFile != null) {
        // 读取图片文件并转换为base64
        final bytes = await imageFile.readAsBytes();
        final base64Image = base64Encode(bytes);

        request = CreateChatCompletionRequest(
          model: ChatCompletionModel.modelId(agent.model),
          messages: [
            ChatCompletionMessage.system(content: effectiveSystemPrompt),
            ChatCompletionMessage.user(
              content: ChatCompletionUserMessageContent.parts([
                ChatCompletionMessageContentPart.text(text: input),
                ChatCompletionMessageContentPart.image(
                  imageUrl: ChatCompletionMessageImageUrl(
                    url: 'data:image/jpeg;base64,$base64Image',
                  ),
                ),
              ]),
            ),
          ],
          temperature: 0.7,
          maxTokens: 4096,
        );
      } else {
        // 构建消息列表
        final List<ChatCompletionMessage> messages = [
          ChatCompletionMessage.system(content: effectiveSystemPrompt),
        ];

        // 添加上下文消息（如果有）
        if (contextMessages != null && contextMessages.isNotEmpty) {
          messages.addAll(contextMessages);
        }

        // 添加当前用户消息
        messages.add(
          ChatCompletionMessage.user(
            content: ChatCompletionUserMessageContent.string(input),
          ),
        );

        request = CreateChatCompletionRequest(
          model: ChatCompletionModel.modelId(agent.model),
          messages: messages,
          temperature: 0.7,
          maxTokens: 1000,
        );
      }

      developer.log('发送请求: ${request.model}', name: 'RequestService');
      developer.log(
        '系统提示词长度: ${effectiveSystemPrompt.length}字符',
        name: 'RequestService',
      );

      final stopwatch = Stopwatch()..start();
      final response = await client.createChatCompletion(request: request);
      stopwatch.stop();

      final content =
          response.choices.first.message.content ?? 'No response content';
      developer.log(
        '收到响应: ${content.length}字符, 耗时: ${stopwatch.elapsedMilliseconds}ms',
        name: 'RequestService',
      );

      return content;
    } catch (e) {
      developer.log(
        '聊天请求错误: ${e.toString()}',
        name: 'RequestService',
        error: e,
      );
      return 'Error: ${e.toString()}';
    }
  }

  /// 流式处理AI响应
  ///
  /// [agent] - AI助手配置
  /// [prompt] - 用户输入的提示，如果为null，则从contextMessages中获取
  /// [onToken] - 每接收到一个完整响应时的回调
  /// [onError] - 发生错误时的回调
  /// [onComplete] - 完成时的回调
  /// [vision] - 是否启用vision模式
  /// [filePath] - 图片文件路径（vision模式下使用）
  /// [contextMessages] - 上下文消息列表，包含system消息和历史消息，按时间从旧到新排序
  /// [responseFormat] - 响应格式（用于 Structured Outputs）
  /// [shouldCancel] - 检查是否应该取消的函数
  /// [additionalPrompts] - 额外的 prompt 部分，使用占位符替换（如 {tool_templates}, {tool_brief}）
  static Future<void> streamResponse({
    required AIAgent agent,
    String? prompt,
    required Function(String) onToken,
    required Function(String) onError,
    required Function() onComplete,
    bool vision = false,
    String? filePath,
    List<ChatCompletionMessage>? contextMessages,
    ResponseFormat? responseFormat,
    bool Function()? shouldCancel,
    Map<String, String>? additionalPrompts,
  }) async {
    try {
      // 获取有效的系统提示词（可能是预设）
      var effectiveSystemPrompt = await getEffectiveSystemPrompt(agent);

      // 处理占位符替换
      if (additionalPrompts != null && additionalPrompts.isNotEmpty) {
        // 保存原始的 agent prompt
        final originalAgentPrompt = effectiveSystemPrompt;

        // 如果 effectiveSystemPrompt 中没有任何占位符，使用默认模板
        if (!effectiveSystemPrompt.contains('{agent_prompt}') &&
            !effectiveSystemPrompt.contains('{tool_templates}') &&
            !effectiveSystemPrompt.contains('{tool_brief}') &&
            !effectiveSystemPrompt.contains('{tool_detail}')) {
          // 构建默认模板：原始prompt + 工具相关占位符
          effectiveSystemPrompt = '{agent_prompt}\n{tool_templates}{tool_brief}{tool_detail}';
        }

        // 替换 {agent_prompt} 占位符为原始 agent prompt
        effectiveSystemPrompt = effectiveSystemPrompt.replaceAll('{agent_prompt}', originalAgentPrompt);

        // 替换其他占位符
        additionalPrompts.forEach((placeholder, content) {
          final fullPlaceholder = '{$placeholder}';
          if (content.isNotEmpty) {
            effectiveSystemPrompt = effectiveSystemPrompt.replaceAll(fullPlaceholder, content);
            developer.log(
              '替换占位符 $fullPlaceholder (长度: ${content.length})',
              name: 'RequestService',
            );
          } else {
            // 如果内容为空，移除占位符
            effectiveSystemPrompt = effectiveSystemPrompt.replaceAll(fullPlaceholder, '');
          }
        });

        developer.log(
          '应用占位符后的 systemPrompt 长度: ${effectiveSystemPrompt.length}',
          name: 'RequestService',
        );
      }

      // 构建消息列表
      List<ChatCompletionMessage> messages = [];
      if (contextMessages != null && contextMessages.isNotEmpty) {
        messages = List<ChatCompletionMessage>.from(contextMessages);

        // 替换 contextMessages 中的 system 消息为处理后的系统提示词
        bool hasSystemMessage = false;
        for (int i = 0; i < messages.length; i++) {
          if (messages[i].role == ChatCompletionMessageRole.system) {
            messages[i] = ChatCompletionMessage.system(content: effectiveSystemPrompt);
            hasSystemMessage = true;
            developer.log(
              '替换 contextMessages 中的 system 消息（已应用占位符）',
              name: 'RequestService',
            );
            break;
          }
        }

        // 如果没有 system 消息，在开头插入
        if (!hasSystemMessage) {
          messages.insert(0, ChatCompletionMessage.system(content: effectiveSystemPrompt));
          developer.log(
            '在 contextMessages 开头插入 system 消息（已应用占位符）',
            name: 'RequestService',
          );
        }
      } else if (prompt != null) {
        // 如果没有提供contextMessages但有prompt，则创建基本的消息列表
        messages = [
          ChatCompletionMessage.system(content: effectiveSystemPrompt),
          ChatCompletionMessage.user(
            content: ChatCompletionUserMessageContent.string(prompt),
          ),
        ];
      } else {
        // 如果既没有contextMessages也没有prompt，则报错
        onError('错误：未提供消息内容');
        return;
      }

      // Vision模式处理
      if (vision && filePath != null) {
        final file = File(filePath);
        if (await file.exists()) {
          // 读取图片文件并转换为base64
          final bytes = await file.readAsBytes();
          final base64Image = base64Encode(bytes);

          // 找到最后一个用户消息并添加图片
          for (int i = messages.length - 1; i >= 0; i--) {
            if (messages[i].role == ChatCompletionMessageRole.user) {
              final userMessage = messages[i];
              final content = userMessage.content;

              // 获取现有的文本内容
              String? textContent;
              if (content is String) {
                textContent = content;
              }

              // 创建新的消息，包含文本（如果有）和图片
              messages[i] = ChatCompletionMessage.user(
                content: ChatCompletionUserMessageContent.parts([
                  if (textContent != null)
                    ChatCompletionMessageContentPart.text(text: textContent),
                  ChatCompletionMessageContentPart.image(
                    imageUrl: ChatCompletionMessageImageUrl(
                      url: 'data:image/jpeg;base64,$base64Image',
                    ),
                  ),
                ]),
              );
              break;
            }
          }
        } else {
          onError('图片文件不存在: $filePath');
          return;
        }
      }

      // 获取OpenAI客户端
      final client = _getClient(agent);

      final request = CreateChatCompletionRequest(
        model: ChatCompletionModel.modelId(agent.model),
        messages: messages,
        temperature: 0.7,
        responseFormat: responseFormat,
      );

      developer.log('发送流式请求: ${request.model}', name: 'RequestService');
      developer.log(
        '发送所有文本内容：${messages.map((e) => e.content).join('')}',
        name: 'RequestService',
      );

      final stopwatch = Stopwatch()..start();
      final stream = client.createChatCompletionStream(request: request);

      int totalChars = 0;
      int chunkCount = 0;
      String finalResponse = '';

      await for (final res in stream) {
        // 检查是否应该取消
        if (shouldCancel != null && shouldCancel()) {
          developer.log('流式响应被用户取消', name: 'RequestService');
          onError('已取消发送');
          return;
        }

        final content = res.choices.first.delta.content;
        if (content != null) {
          totalChars += content.length;
          chunkCount++;
          finalResponse += content;

          // 每10个块记录一次进度
          if (chunkCount % 10 == 0) {
            developer.log(
              '流式响应进度: $totalChars字符, $chunkCount个块, 已耗时: ${stopwatch.elapsedMilliseconds}ms',
              name: 'RequestService',
            );
          }

          onToken(content);
        }
      }

      stopwatch.stop();
      developer.log('返回文本完成: $finalResponse', name: 'RequestService');
      developer.log(
        '流式响应完成: 总计$totalChars字符, $chunkCount个块, 总耗时: ${stopwatch.elapsedMilliseconds}ms',
        name: 'RequestService',
      );
      onComplete();
    } catch (e, stackTrace) {
      final errorMessage = '处理AI响应时出错: $e';
      developer.log(
        errorMessage,
        name: 'RequestService',
        error: e,
        stackTrace: stackTrace,
      );
      onError(errorMessage);
    }
  }

  /// 生成图片
  static Future<List<String>> generateImages(
    String prompt,
    AIAgent agent, {
    int n = 1,
    String size = '1024x1024',
    String model = 'dall-e-3',
    String quality = 'standard',
    String style = 'natural',
  }) async {
    try {
      developer.log('开始图像生成请求: ${agent.id}', name: 'RequestService');
      developer.log('提示词: $prompt', name: 'RequestService');
      developer.log(
        '参数: model=$model, size=$size, quality=$quality, style=$style, n=$n',
        name: 'RequestService',
      );

      final client = _getClient(agent);

      // 转换参数为枚举值
      ImageSize imageSize;
      switch (size) {
        case '1024x1024':
          imageSize = ImageSize.v1024x1024;
          break;
        case '1024x1792':
          imageSize = ImageSize.v1024x1792;
          break;
        case '1792x1024':
          imageSize = ImageSize.v1792x1024;
          break;
        default:
          imageSize = ImageSize.v1024x1024;
      }

      ImageQuality imageQuality;
      switch (quality) {
        case 'hd':
          imageQuality = ImageQuality.hd;
          break;
        default:
          imageQuality = ImageQuality.standard;
      }

      ImageStyle imageStyle;
      switch (style) {
        case 'vivid':
          imageStyle = ImageStyle.vivid;
          break;
        default:
          imageStyle = ImageStyle.natural;
      }

      final request = CreateImageRequest(
        model: CreateImageRequestModel.modelId(model),
        prompt: prompt,
        n: n,
        size: imageSize,
        quality: imageQuality,
        style: imageStyle,
      );

      final stopwatch = Stopwatch()..start();
      final response = await client.createImage(request: request);
      stopwatch.stop();

      final urls = response.data.map((image) => image.url ?? '').toList();
      developer.log(
        '图像生成完成: ${urls.length}张图片, 耗时: ${stopwatch.elapsedMilliseconds}ms',
        name: 'RequestService',
      );

      return urls;
    } catch (e) {
      developer.log(
        '图像生成错误: ${e.toString()}',
        name: 'RequestService',
        error: e,
      );
      return ['Error: ${e.toString()}'];
    }
  }

  /// 创建嵌入向量
  static Future<List<double>> createEmbedding(
    String input,
    AIAgent agent, {
    String model = 'text-embedding-3-small',
  }) async {
    try {
      developer.log('开始创建嵌入向量: ${agent.id}', name: 'RequestService');
      developer.log('输入文本长度: ${input.length}字符', name: 'RequestService');
      developer.log('使用模型: $model', name: 'RequestService');

      final client = _getClient(agent);

      final request = CreateEmbeddingRequest(
        model: EmbeddingModel.modelId(model),
        input: EmbeddingInput.string(input),
      );

      final stopwatch = Stopwatch()..start();
      final response = await client.createEmbedding(request: request);
      stopwatch.stop();

      final vector = response.data.first.embeddingVector;
      developer.log(
        '嵌入向量生成完成: ${vector.length}维, 耗时: ${stopwatch.elapsedMilliseconds}ms',
        name: 'RequestService',
      );

      return vector;
    } catch (e) {
      developer.log(
        '嵌入向量生成错误: ${e.toString()}',
        name: 'RequestService',
        error: e,
      );
      return [];
    }
  }

  /// 清理客户端资源
  static void dispose() {
    developer.log(
      '清理所有OpenAI客户端资源: ${_clients.length}个客户端',
      name: 'RequestService',
    );
    _clients.clear();
  }
}
