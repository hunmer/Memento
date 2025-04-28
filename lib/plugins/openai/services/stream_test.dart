import 'dart:developer' as developer;
import '../models/ai_agent.dart';
import 'ai_service.dart';

/// 测试流式响应功能的工具类
class StreamTester {
  /// 执行流式响应测试
  static Future<void> testStreamResponse(AIAgent agent, String prompt) async {
    developer.log('开始流式响应测试', name: 'StreamTester');
    developer.log('使用Agent: ${agent.name}', name: 'StreamTester');
    developer.log('提示词: $prompt', name: 'StreamTester');
    
    final aiService = AIService();
    
    // 累积的响应内容
    StringBuffer buffer = StringBuffer();
    int tokenCount = 0;
    
    try {
      await aiService.streamResponse(
        agent: agent,
        prompt: prompt,
        onToken: (token) {
          buffer.write(token);
          tokenCount++;
          
          if (tokenCount % 10 == 0) {
            developer.log(
              '收到token: $tokenCount, 当前内容长度: ${buffer.length}',
              name: 'StreamTester'
            );
          }
        },
        onError: (error) {
          developer.log(
            '流式响应错误: $error',
            name: 'StreamTester',
            error: error
          );
        },
        onComplete: () {
          developer.log(
            '流式响应完成: 共收到 $tokenCount 个token，总长度: ${buffer.length}',
            name: 'StreamTester'
          );
          developer.log(
            '完整响应内容: ${buffer.toString()}',
            name: 'StreamTester'
          );
        },
      );
    } catch (e, stackTrace) {
      developer.log(
        '测试过程中出现异常: $e',
        name: 'StreamTester',
        error: e,
        stackTrace: stackTrace
      );
    }
  }
}