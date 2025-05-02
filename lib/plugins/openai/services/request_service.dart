import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:openai_dart/openai_dart.dart';
import '../models/ai_agent.dart';
import '../controllers/prompt_replacement_controller.dart';
import 'dart:developer' as developer;

class RequestService {
  static final Map<String, OpenAIClient> _clients = {};

  /// 获取或创建OpenAI客户端
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
    bool replacePrompt = true,
  }) async {
    try {
      developer.log('开始聊天请求: ${agent.id}', name: 'RequestService');
      developer.log('用户输入: $input', name: 'RequestService');

      // 处理prompt替换
      String processedInput = input;
      if (replacePrompt) {
        try {
          processedInput = await PromptReplacementController().processPrompt(input);
          developer.log(
            'Prompt替换结果: $processedInput',
            name: 'RequestService',
          );
        } catch (e) {
          developer.log(
            'Prompt替换失败: $e',
            name: 'RequestService',
            error: e,
          );
        }
      }

      final client = _getClient(agent);

      late final CreateChatCompletionRequest request;

      if (imageFile != null) {
        // 读取图片文件并转换为base64
        final bytes = await imageFile.readAsBytes();
        final base64Image = base64Encode(bytes);

        request = CreateChatCompletionRequest(
          model: ChatCompletionModel.modelId(agent.model),
          messages: [
            ChatCompletionMessage.system(content: agent.systemPrompt),
            ChatCompletionMessage.user(
              content: ChatCompletionUserMessageContent.parts([
                ChatCompletionMessageContentPart.text(text: processedInput),
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
        request = CreateChatCompletionRequest(
          model: ChatCompletionModel.modelId(agent.model),
          messages: [
            ChatCompletionMessage.system(content: agent.systemPrompt),
            ChatCompletionMessage.user(
              content: ChatCompletionUserMessageContent.string(processedInput),
            ),
          ],
          temperature: 0.7,
          maxTokens: 1000,
        );
      }

      developer.log('发送请求: ${request.model}', name: 'RequestService');
      developer.log(
        '系统提示词长度: ${agent.systemPrompt.length}字符',
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
  /// [prompt] - 用户输入的提示
  /// [onToken] - 每接收到一个完整响应时的回调
  /// [onError] - 发生错误时的回调
  /// [onComplete] - 完成时的回调
  /// [vision] - 是否启用vision模式
  /// [filePath] - 图片文件路径（vision模式下使用）
  /// [replacePrompt] - 是否启用prompt替换
  static Future<void> streamResponse({
    required AIAgent agent,
    required String prompt,
    required Function(String) onToken,
    required Function(String) onError,
    required Function() onComplete,
    bool vision = false,
    String? filePath,
    bool replacePrompt = true,
  }) async {
    try {
      if (vision && filePath != null) {
        // Vision模式，使用图片文件
        final file = File(filePath);
        if (await file.exists()) {
          final response = await chat(prompt, agent, imageFile: file);
          onToken(response);
          onComplete();
          return;
        } else {
          onError('图片文件不存在: $filePath');
          return;
        }
      }

      // 处理prompt替换
      String processedPrompt = prompt;
      if (replacePrompt) {
        try {
          processedPrompt = await PromptReplacementController().processPrompt(prompt);
          developer.log(
            'Prompt替换结果: $processedPrompt',
            name: 'RequestService',
          );
        } catch (e) {
          developer.log(
            'Prompt替换失败: $e',
            name: 'RequestService',
            error: e,
          );
        }
      }

      // 普通流式对话模式
      final client = _getClient(agent);

      final request = CreateChatCompletionRequest(
        model: ChatCompletionModel.modelId(agent.model),
        messages: [
          ChatCompletionMessage.system(content: agent.systemPrompt),
          ChatCompletionMessage.user(
            content: ChatCompletionUserMessageContent.string(processedPrompt),
          ),
        ],
        temperature: 0.7,
      );

      developer.log('发送流式请求: ${request.model}', name: 'RequestService');

      final stopwatch = Stopwatch()..start();
      final stream = client.createChatCompletionStream(request: request);

      int totalChars = 0;
      int chunkCount = 0;

      await for (final res in stream) {
        final content = res.choices.first.delta.content;
        if (content != null) {
          totalChars += content.length;
          chunkCount++;

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
