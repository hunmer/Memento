import 'dart:developer' as developer;
import '../models/ai_agent.dart';
import '../services/stream_test.dart';

/// 命令行工具，用于测试流式响应
void main() async {
  // 设置日志记录
  developer.log('启动流式响应测试工具', name: 'TestStream');
  
  // 创建一个测试用的AI Agent
  final testAgent = AIAgent(
    id: 'test-agent',
    name: 'Test Agent',
    description: '用于测试流式响应的AI助手',
    systemPrompt: '你是一个有用的助手。',
    tags: ['test', 'debug'],
    serviceProviderId: 'openai', // 使用OpenAI格式
    model: 'gpt-3.5-turbo',
    baseUrl: 'https://api.openai.com/v1', // 替换为你的API地址
    headers: {
      'Authorization': 'Bearer YOUR_API_KEY', // 替换为你的API密钥
      'Content-Type': 'application/json',
    },
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
  
  // 测试提示词
  const testPrompt = '你好，请用几句话介绍一下自己。';
  
  // 执行测试
  await StreamTester.testStreamResponse(testAgent, testPrompt);
  
  developer.log('测试完成', name: 'TestStream');
}