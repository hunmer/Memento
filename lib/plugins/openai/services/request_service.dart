import 'package:openai_dart/openai_dart.dart';
import '../models/ai_agent.dart';

class RequestService {
  static final Map<String, OpenAIClient> _clients = {};

  /// 获取或创建OpenAI客户端
  static OpenAIClient _getClient(AIAgent agent) {
    if (!_clients.containsKey(agent.id)) {
      // 从headers中提取API密钥
      final apiKey =
          agent.headers['Authorization']?.replaceAll('Bearer ', '') ??
          agent.headers['api-key'] ??
          '';

      // 可选的组织ID
      final organization = agent.headers['OpenAI-Organization'];

      _clients[agent.id] = OpenAIClient(
        apiKey: apiKey,
        organization: organization,
        baseUrl: agent.baseUrl,
        headers: agent.headers,
      );
    }
    return _clients[agent.id]!;
  }

  /// 发送聊天请求
  static Future<String> chat(String input, AIAgent agent) async {
    try {
      final client = _getClient(agent);

      final request = CreateChatCompletionRequest(
        model: ChatCompletionModel.modelId('deepseek-r1:14b'),
        messages: [
          ChatCompletionMessage.system(content: agent.systemPrompt),
          ChatCompletionMessage.user(
            content: ChatCompletionUserMessageContent.string(input),
          ),
        ],
        temperature: 0.7,
        maxTokens: 1000,
      );

      final response = await client.createChatCompletion(request: request);
      return response.choices.first.message.content ?? 'No response content';
    } catch (e) {
      return 'Error: ${e.toString()}';
    }
  }

  /// 流式聊天请求
  static Stream<String> chatStream(String input, AIAgent agent) async* {
    try {
      final client = _getClient(agent);

      final request = CreateChatCompletionRequest(
        model: ChatCompletionModel.modelId('gpt-3.5-turbo'),
        messages: [
          ChatCompletionMessage.system(content: agent.systemPrompt),
          ChatCompletionMessage.user(
            content: ChatCompletionUserMessageContent.string(input),
          ),
        ],
        temperature: 0.7,
      );

      final stream = client.createChatCompletionStream(request: request);

      await for (final res in stream) {
        final content = res.choices.first.delta.content;
        if (content != null) {
          yield content;
        }
      }
    } catch (e) {
      yield 'Error: ${e.toString()}';
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

      final response = await client.createImage(request: request);
      return response.data.map((image) => image.url ?? '').toList();
    } catch (e) {
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
      final client = _getClient(agent);

      final request = CreateEmbeddingRequest(
        model: EmbeddingModel.modelId(model),
        input: EmbeddingInput.string(input),
      );

      final response = await client.createEmbedding(request: request);
      return response.data.first.embeddingVector;
    } catch (e) {
      return [];
    }
  }

  /// 清理客户端资源
  static void dispose() {
    _clients.clear();
  }
}
