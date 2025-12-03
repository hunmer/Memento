/// 自定义JavaScript动作使用示例
/// 展示如何输入和使用自定义JavaScript代码（无预设代码）

import 'package:flutter/material.dart';
import 'package:Memento/core/action/action_manager.dart';
import 'package:Memento/core/action/models/action_definition.dart';
import 'package:Memento/core/action/models/action_group.dart';
import 'package:Memento/core/action/models/action_instance.dart';

/// 自定义JavaScript动作示例类
class CustomActionExamples {
  /// 动态注册用户输入的JavaScript代码为动作
  static void registerUserJavaScript(
    ActionManager manager, {
    required String id,
    required String title,
    required String script,
    String? description,
    IconData? icon,
  }) {
    manager.registerJavaScriptAction(
      id: id,
      title: title,
      description: description ?? '用户自定义JavaScript动作',
      script: script, // 用户输入的原始JavaScript代码
      icon: icon ?? Icons.code,
    );
  }

  /// 示例1: 用户直接输入JavaScript代码执行
  static Future<void> executeUserJavaScript(
    BuildContext context,
    ActionManager manager,
  ) async {
    // 模拟用户输入的JavaScript代码
    final userScript = '''
      // 用户可以在这里编写任何JavaScript代码
      const data = inputData.data || [];
      const operation = inputData.operation || 'count';

      let result;
      switch(operation) {
        case 'count':
          result = data.length;
          break;
        case 'sum':
          result = data.reduce((a, b) => a + b, 0);
          break;
        case 'average':
          result = data.reduce((a, b) => a + b, 0) / data.length;
          break;
        default:
          result = 'Unknown operation';
      }

      return {
        success: true,
        operation: operation,
        input: data,
        result: result,
        timestamp: Date.now()
      };
    ''';

    final result = await manager.executeJavaScript(
      context,
      userScript,
      data: {
        'data': [1, 2, 3, 4, 5],
        'operation': 'sum',
      },
    );

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('JS执行成功: 结果=${result.data?['result']}'),
          duration: const Duration(seconds: 3),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('JS执行失败: ${result.error}'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  /// 示例2: 用户输入JavaScript代码后注册为命名动作
  static void registerUserCodeAsAction(ActionManager manager) {
    // 模拟用户从文本框输入的JavaScript代码
    final userInputCode = '''
      // 用户输入的JavaScript代码
      const text = inputData.text || '';
      const transform = inputData.transform || 'uppercase';

      let result;
      switch(transform) {
        case 'uppercase':
          result = text.toUpperCase();
          break;
        case 'lowercase':
          result = text.toLowerCase();
          break;
        case 'reverse':
          result = text.split('').reverse().join('');
          break;
        default:
          result = text;
      }

      return {
        success: true,
        original: text,
        transform: transform,
        result: result,
        length: result.length
      };
    ''';

    // 将用户代码注册为动作
    manager.registerJavaScriptAction(
      id: 'user_text_transformer',
      title: '文本转换器',
      description: '用户自定义的文本转换工具',
      script: userInputCode, // 直接使用用户输入的代码
      icon: Icons.text_fields,
    );
  }

  /// 示例3: 创建JavaScript代码输入表单
  static Widget buildJavaScriptInputForm({
    required BuildContext context,
    required ActionManager manager,
    required String actionId,
  }) {
    final scriptController = TextEditingController();
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();

    return AlertDialog(
      title: const Text('输入JavaScript代码'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: '动作标题',
                hintText: '例如：我的计算器',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: '动作描述',
                hintText: '描述这个动作的功能',
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TextField(
                controller: scriptController,
                decoration: const InputDecoration(
                  labelText: 'JavaScript代码',
                  hintText: '在这里输入您的JavaScript代码',
                  border: OutlineInputBorder(),
                ),
                maxLines: null,
                minLines: 10,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '提示：使用 inputData 访问输入数据，返回格式：{ success: true, ... }',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: () {
            // 注册用户输入的代码
            manager.registerJavaScriptAction(
              id: actionId,
              title: titleController.text.isEmpty ? '未命名动作' : titleController.text,
              description: descriptionController.text,
              script: scriptController.text,
              icon: Icons.code,
            );

            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('JavaScript动作已注册')),
            );
          },
          child: const Text('保存'),
        ),
      ],
    );
  }

  /// 示例4: 快速执行用户输入的代码（不保存）
  static Future<void> quickExecute(
    BuildContext context,
    ActionManager manager,
    String userCode,
    Map<String, dynamic> inputData,
  ) async {
    final result = await manager.executeJavaScript(
      context,
      userCode,
      data: inputData,
    );

    // 显示结果
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('执行结果'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('执行状态: ${result.success ? "成功" : "失败"}'),
              const SizedBox(height: 8),
              if (result.success) ...[
                const Text('输出数据:'),
                SelectableText(
                  result.data?.toString() ?? '无数据',
                  style: const TextStyle(fontFamily: 'monospace'),
                ),
              ] else ...[
                const Text('错误信息:'),
                SelectableText(
                  result.error ?? '未知错误',
                  style: const TextStyle(color: Colors.red),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  /// 示例5: 用户输入JavaScript代码用于悬浮球
  static void registerFloatingBallAction(ActionManager manager) {
    showDialog(
      context: navigatorKey.currentContext!,
      builder: (context) => AlertDialog(
        title: const Text('输入悬浮球JavaScript代码'),
        content: const TextField(
          decoration: InputDecoration(
            labelText: 'JavaScript代码',
            hintText: '例如：return { message: "Hello" };',
          ),
          maxLines: 5,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              // 这里应该获取用户输入的代码
              // final userCode = ...;
              // manager.registerJavaScriptAction(...);
              Navigator.pop(context);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  /// 获取空的JavaScript代码模板（不预设任何代码）
  static String getEmptyTemplate() {
    return '''
// 在这里输入您的JavaScript代码
// 使用 inputData 访问输入的数据
// 返回格式：{ success: true, ... }

return {
  success: true,
  message: 'Hello from JavaScript!',
  timestamp: Date.now()
};
''';
  }

  /// 获取带注释的代码模板（帮助用户理解）
  static String getCommentedTemplate() {
    return '''
// ========================================
// JavaScript 代码模板
// ========================================

// 1. 访问输入数据
const input = inputData || {};

// 2. 处理数据
const data = input.data || [];
const operation = input.operation || 'count';

// 3. 执行逻辑
let result;
switch(operation) {
  case 'count':
    result = data.length;
    break;
  case 'sum':
    result = data.reduce((a, b) => a + b, 0);
    break;
  default:
    result = data;
}

// 4. 返回结果（必须包含 success 字段）
return {
  success: true,
  operation: operation,
  result: result,
  timestamp: Date.now()
};

// ========================================
// 更多示例代码请参考 README 文档
// ========================================
''';
  }

  /// 验证用户输入的JavaScript代码
  static List<String> validateJavaScript(String code) {
    final errors = <String>[];

    // 基本验证
    if (code.trim().isEmpty) {
      errors.add('代码不能为空');
    }

    if (!code.contains('return')) {
      errors.add('代码必须包含 return 语句');
    }

    // 检查是否有明显语法错误
    if (code.split('return').length < 2) {
      errors.add('return 语句格式错误');
    }

    return errors;
  }
}

/// 全局导航key（在实际使用中应该从根Widget获取）
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// 使用示例
/*
void exampleUsage() {
  final manager = ActionManager();

  // 1. 用户直接输入JavaScript代码执行
  CustomActionExamples.executeUserJavaScript(context, manager);

  // 2. 将用户代码注册为动作
  CustomActionExamples.registerUserCodeAsAction(manager);

  // 3. 构建用户输入表单
  // CustomActionExamples.buildJavaScriptInputForm(context, manager, 'my_action');

  // 4. 快速执行用户代码
  // CustomActionExamples.quickExecute(context, manager, userCode, inputData);

  // 5. 获取空模板
  final template = CustomActionExamples.getEmptyTemplate();
  print('JavaScript模板:\\n$template');

  // 6. 验证用户代码
  final errors = CustomActionExamples.validateJavaScript(userCode);
  if (errors.isNotEmpty) {
    print('代码错误: $errors');
  }
}
*/
