import 'package:flutter_test/flutter_test.dart';
import 'package:Memento/plugins/agent_chat/services/tool_config_manager.dart';
import 'package:Memento/plugins/agent_chat/services/tool_service.dart';

/// 测试工具服务的Prompt生成功能
void main() {
  group('ToolService Prompt 测试', () {
    test('插件别名映射应该包含所有主要插件', () {
      final aliases = ToolConfigManager.getPluginAliases();

      // 验证关键插件的别名存在
      expect(aliases.containsKey('bill'), true);
      expect(aliases.containsKey('chat'), true);
      expect(aliases.containsKey('diary'), true);
      expect(aliases.containsKey('todo'), true);

      // 验证别名内容
      expect(aliases['bill']?.contains('账单'), true);
      expect(aliases['bill']?.contains('记账'), true);
      expect(aliases['chat']?.contains('聊天'), true);
      expect(aliases['chat']?.contains('频道'), true);
      expect(aliases['chat']?.contains('消息'), true);
    });

    test('插件别名Prompt应该包含正确的格式', () {
      final prompt = ToolConfigManager.generatePluginAliasesPrompt();

      // 验证包含标题
      expect(prompt.contains('插件别名映射'), true);

      // 验证包含具体插件
      expect(prompt.contains('bill'), true);
      expect(prompt.contains('chat'), true);
      expect(prompt.contains('账单'), true);
      expect(prompt.contains('聊天'), true);

      // 验证包含示例
      expect(prompt.contains('示例'), true);
    });

    test('工具列表Prompt应该包含禁止硬编码日期的警告', () async {
      // 需要初始化才能获取完整prompt
      // 这里只测试fallback版本
      final prompt = ToolService.getToolListPrompt();

      // 验证包含关键警告
      expect(prompt.contains('绝对禁止'), true);
      expect(prompt.contains('硬编码日期'), true);
      expect(prompt.contains('Memento.system.getCurrentTime()'), true);
      expect(prompt.contains('禁止使用占位符'), true);
      expect(prompt.contains('your_'), true);
    });

    test('工具列表Prompt应该包含正确和错误的示例', () {
      final prompt = ToolService.getToolListPrompt();

      // 验证包含错误示例标记
      expect(prompt.contains('❌ 错误'), true);

      // 验证包含正确示例标记
      expect(prompt.contains('✅ 正确'), true);

      // 验证包含具体的错误案例
      expect(prompt.contains('"2025-01-15"'), true);
      expect(prompt.contains('"your_channel_id"'), true);
    });

    test('详细工具Prompt应该包含插件别名映射', () async {
      final detailPrompt = await ToolService.getToolDetailPrompt(['todo_getTasks']);

      // 验证包含别名映射
      expect(detailPrompt.contains('插件别名映射') || detailPrompt.contains('插件别名'), true);
    });

    test('Prompt应该强调系统API的使用', () {
      final prompt = ToolService.getToolListPrompt();

      // 验证包含系统API说明
      expect(prompt.contains('系统 API'), true);
      expect(prompt.contains('必须使用'), true);
      expect(prompt.contains('getCurrentTime'), true);
      expect(prompt.contains('getTimestamp'), true);
    });

    test('Prompt应该包含避免占位符的策略', () {
      final prompt = ToolService.getToolListPrompt();

      // 验证包含策略说明
      expect(prompt.contains('优先遍历') || prompt.contains('优先选择'), true);
      expect(prompt.contains('第一个') || prompt.contains('最近的'), true);
      expect(prompt.contains('先创建') || prompt.contains('明确错误'), true);
    });
  });
}
