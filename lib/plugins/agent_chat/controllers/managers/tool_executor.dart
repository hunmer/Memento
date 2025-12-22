import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../models/tool_call_step.dart';
import '../../services/tool_service.dart';
import '../../services/token_counter_service.dart';
import 'package:Memento/core/js_bridge/js_bridge_manager.dart';
import 'shared/manager_context.dart';

/// 工具调用执行管理器
///
/// 负责工具调用的解析、执行和状态管理
/// 遵循单一职责原则 (SRP)
class ToolExecutor {
  final ManagerContext context;

  /// 工具结果续写回调
  /// 参数: (messageId, toolResult, currentContent)
  final Future<void> Function(String, String, String)? onContinueWithToolResult;

  ToolExecutor({required this.context, this.onContinueWithToolResult});

  // ========== 核心方法 ==========

  /// 处理工具调用
  ///
  /// 解析 AI 返回的工具调用 JSON,执行工具步骤,并处理结果
  Future<void> handleToolCall(String messageId, String aiResponse) async {
    debugPrint('🔧 开始处理工具调用, messageId=${messageId.substring(0, 8)}');

    try {
      // 1. 解析工具调用
      final toolCall = ToolService.parseToolCallFromResponse(aiResponse);
      if (toolCall == null) {
        debugPrint('❌ 工具调用解析失败');
        // 解析失败，直接完成消息
        context.messageService.completeAIMessage(
          context.conversationId,
          messageId,
        );
        return;
      }

      debugPrint('✅ 解析到 ${toolCall.steps.length} 个工具步骤');

      // 2. 更新消息，将 toolCall 保存到消息中
      final message = context.messageService.getMessage(
        context.conversationId,
        messageId,
      );
      if (message == null) {
        debugPrint('❌ 未找到消息: $messageId');
        return;
      }

      // 提取 AI 的思考内容（去除工具调用 JSON）
      final thinkingContent = _extractThinkingContent(aiResponse);
      debugPrint('💭 思考内容长度: ${thinkingContent.length}');

      var updatedMessage = message.copyWith(
        content: thinkingContent,
        toolCall: toolCall,
      );
      await context.messageService.updateMessage(updatedMessage);

      // 3. 逐步执行工具调用
      final toolResultsBuffer = StringBuffer();
      debugPrint('🚀 开始执行 ${toolCall.steps.length} 个步骤');

      // 初始化工具调用上下文（用于步骤间结果传递）
      final jsBridge = JSBridgeManager.instance;
      jsBridge.initToolCallContext(messageId);

      try {
        for (int i = 0; i < toolCall.steps.length; i++) {
          final step = toolCall.steps[i];
          debugPrint('  步骤 ${i + 1}: ${step.title}');

          // 更新步骤为执行中
          step.status = ToolCallStatus.running;
          final updatedSteps = List<ToolCallStep>.from(toolCall.steps);
          updatedMessage = updatedMessage.copyWith(
            toolCall: ToolCallResponse(steps: updatedSteps),
          );
          await context.messageService.updateMessage(updatedMessage);
          context.notify();

          // 执行工具调用
          if (step.method == 'run_js') {
            try {
              // 设置当前执行上下文（供 JavaScript 中的 setResult/getResult 使用）
              jsBridge.setCurrentExecution(messageId, i);

              final result = await ToolService.executeJsCode(step.data);
              debugPrint('  ✅ 步骤 ${i + 1} 执行成功');

              // 自动将步骤结果保存到上下文（供后续步骤通过索引获取）
              try {
                // 尝试解析结果为 JSON 对象
                final parsedResult = jsonDecode(result);
                jsBridge.setToolCallResult('step_$i', parsedResult);
              } catch (e) {
                // 如果不是 JSON，直接保存原始字符串
                jsBridge.setToolCallResult('step_$i', result);
              }

              // 更新步骤为成功
              step.result = result;
              step.status = ToolCallStatus.success;
              final successSteps = List<ToolCallStep>.from(toolCall.steps);
              updatedMessage = updatedMessage.copyWith(
                toolCall: ToolCallResponse(steps: successSteps),
              );
              await context.messageService.updateMessage(updatedMessage);
              context.notify();

              // 收集工具结果到 buffer
              toolResultsBuffer.writeln('步骤 ${i + 1}: ${step.title}');
              toolResultsBuffer.writeln('结果: $result');
              toolResultsBuffer.writeln();
            } catch (e) {
              // 更新步骤为失败
              step.error = e.toString();
              step.status = ToolCallStatus.failed;
              final failedSteps = List<ToolCallStep>.from(toolCall.steps);
              updatedMessage = updatedMessage.copyWith(
                toolCall: ToolCallResponse(steps: failedSteps),
              );
              await context.messageService.updateMessage(updatedMessage);
              context.notify();

              // 收集错误到 buffer
              toolResultsBuffer.writeln('步骤 ${i + 1}: ${step.title}');
              toolResultsBuffer.writeln('错误: $e');
              toolResultsBuffer.writeln();

              // 将工具结果追加到 content（即使失败）
              final contentWithToolResult =
                  '$thinkingContent\n\n[工具执行结果]\n${toolResultsBuffer.toString()}';
              updatedMessage = updatedMessage.copyWith(
                content: contentWithToolResult,
              );
              await context.messageService.updateMessage(updatedMessage);

              // 完成消息生成（失败）
              context.messageService.completeAIMessage(
                context.conversationId,
                messageId,
              );
              return; // 中断流程
            }
          }
        }

        // 4. 将工具结果追加到 content
        final contentWithToolResult =
            '$thinkingContent\n\n[工具执行结果]\n${toolResultsBuffer.toString()}';
        updatedMessage = updatedMessage.copyWith(
          content: contentWithToolResult,
        );
        await context.messageService.updateMessage(updatedMessage);
        debugPrint(
          '📝 已将工具结果追加到 content, 总长度: ${contentWithToolResult.length}',
        );

        // 5. 所有工具调用成功，将结果发送给 AI 继续生成
        final toolResultMessage = buildToolResultMessage(toolCall.steps);
        debugPrint('🤖 准备让 AI 继续生成回复');

        // 调用续写回调
        if (onContinueWithToolResult != null) {
          await onContinueWithToolResult!(
            messageId,
            toolResultMessage,
            contentWithToolResult,
          );
        }
      } finally {
        // 清除工具调用上下文
        jsBridge.clearToolCallContext(messageId);
      }
    } catch (e) {
      // 解析失败
      final errorContent = '❌ 工具调用处理失败: $e';

      // 清除工具调用上下文
      final jsBridge = JSBridgeManager.instance;
      jsBridge.clearToolCallContext(messageId);

      context.messageService.updateAIMessageContent(
        context.conversationId,
        messageId,
        errorContent,
        TokenCounterService.estimateTokenCount(errorContent),
      );
      context.messageService.completeAIMessage(
        context.conversationId,
        messageId,
      );
    }
  }

  /// 执行工具调用步骤
  ///
  /// 用于模板执行场景，不包含 AI 续写逻辑
  Future<void> executeSteps(String messageId, List<ToolCallStep> steps) async {
    // 初始化工具调用上下文（用于步骤间结果传递）
    final jsBridge = JSBridgeManager.instance;
    jsBridge.initToolCallContext(messageId);

    try {
      for (var i = 0; i < steps.length; i++) {
        final step = steps[i];

        // 更新步骤状态为运行中
        step.status = ToolCallStatus.running;
        final runningSteps = List<ToolCallStep>.from(steps);
        await _updateMessageToolSteps(messageId, runningSteps);
        context.notify();

        try {
          // 设置当前执行上下文（供 JavaScript 中的 setResult/getResult 使用）
          jsBridge.setCurrentExecution(messageId, i);

          // 执行步骤
          final result = await ToolService.executeToolStep(step);

          // 自动将步骤结果保存到上下文（供后续步骤通过索引获取）
          jsBridge.setToolCallResult('step_$i', result);

          // 更新步骤状态为成功
          step.status = ToolCallStatus.success;
          step.result = result;
          final successSteps = List<ToolCallStep>.from(steps);
          await _updateMessageToolSteps(messageId, successSteps);
          context.notify();
        } catch (e) {
          // 更新步骤状态为失败
          step.status = ToolCallStatus.failed;
          step.error = e.toString();
          final failedSteps = List<ToolCallStep>.from(steps);
          await _updateMessageToolSteps(messageId, failedSteps);
          context.notify();
          break; // 停止执行后续步骤
        }
      }

      context.notify();
    } finally {
      // 清除工具调用上下文
      jsBridge.clearToolCallContext(messageId);
    }
  }

  /// 重新执行工具调用
  Future<void> rerunAll(String messageId) async {
    try {
      // 获取消息
      final message = context.messageService.getMessage(
        context.conversationId,
        messageId,
      );
      if (message == null) {
        throw Exception('消息不存在');
      }

      // 检查是否有工具调用
      if (message.toolCall == null || message.toolCall!.steps.isEmpty) {
        throw Exception('该消息不包含工具调用');
      }

      debugPrint('🔄 开始重新执行工具调用, messageId=${messageId.substring(0, 8)}');

      // 重置所有步骤状态
      final resetSteps =
          message.toolCall!.steps.map((step) {
            return step.withoutRuntimeState(state: ToolCallStatus.pending);
          }).toList();

      // 更新消息
      var updatedMessage = message.copyWith(
        toolCall: ToolCallResponse(steps: resetSteps),
      );
      await context.messageService.updateMessage(updatedMessage);
      context.notify();

      debugPrint('✅ 步骤状态已重置, 开始重新执行 ${resetSteps.length} 个步骤');

      // 重新执行所有步骤
      await executeSteps(messageId, resetSteps);

      debugPrint('✅ 工具调用重新执行完成');
    } catch (e) {
      debugPrint('❌ 重新执行工具调用失败: $e');
      rethrow;
    }
  }

  /// 重新执行单个工具调用步骤
  Future<void> rerunSingle(String messageId, int stepIndex) async {
    try {
      // 获取消息
      final message = context.messageService.getMessage(
        context.conversationId,
        messageId,
      );
      if (message == null) {
        throw Exception('消息不存在');
      }

      // 检查是否有工具调用
      if (message.toolCall == null || message.toolCall!.steps.isEmpty) {
        throw Exception('该消息不包含工具调用');
      }

      if (stepIndex < 0 || stepIndex >= message.toolCall!.steps.length) {
        throw Exception('步骤索引超出范围');
      }

      debugPrint(
        '🔄 开始重新执行步骤 $stepIndex, messageId=${messageId.substring(0, 8)}',
      );

      final steps = List<ToolCallStep>.from(message.toolCall!.steps);
      final targetStep = steps[stepIndex];

      // 重置该步骤状态
      steps[stepIndex] = targetStep.withoutRuntimeState(
        state: ToolCallStatus.pending,
      );

      // 更新消息
      var updatedMessage = message.copyWith(
        toolCall: ToolCallResponse(steps: steps),
      );
      await context.messageService.updateMessage(updatedMessage);
      context.notify();

      debugPrint('✅ 步骤 $stepIndex 状态已重置, 开始执行');

      // 重新执行该步骤
      steps[stepIndex].status = ToolCallStatus.running;
      await _updateMessageToolSteps(messageId, steps);
      context.notify();

      try {
        // 执行步骤
        final result = await ToolService.executeToolStep(steps[stepIndex]);

        // 更新步骤状态为成功
        steps[stepIndex].status = ToolCallStatus.success;
        steps[stepIndex].result = result;
        steps[stepIndex].error = null; // 清除之前的错误
        await _updateMessageToolSteps(messageId, steps);
        context.notify();

        debugPrint('✅ 步骤 $stepIndex 重新执行成功');
      } catch (e) {
        // 更新步骤状态为失败
        steps[stepIndex].status = ToolCallStatus.failed;
        steps[stepIndex].error = e.toString();
        await _updateMessageToolSteps(messageId, steps);
        context.notify();

        debugPrint('❌ 步骤 $stepIndex 重新执行失败: $e');
        rethrow;
      }
    } catch (e) {
      debugPrint('❌ 重新执行单个步骤失败: $e');
      rethrow;
    }
  }

  /// 构建工具结果消息
  String buildToolResultMessage(List<ToolCallStep> steps) {
    final buffer = StringBuffer();
    buffer.writeln('工具执行结果:\n');

    for (int i = 0; i < steps.length; i++) {
      final step = steps[i];
      buffer.writeln('步骤 ${i + 1}: ${step.title}');
      if (step.result != null) {
        buffer.writeln('结果: ${step.result}');
      } else if (step.error != null) {
        buffer.writeln('错误: ${step.error}');
      }
      buffer.writeln();
    }

    buffer.writeln('---');
    buffer.writeln('请根据以上工具执行结果直接回答用户的问题，不要再次调用工具。');

    return buffer.toString();
  }

  // ========== 私有方法 ==========

  /// 提取思考内容（去除工具调用 JSON）
  String _extractThinkingContent(String aiResponse) {
    // 简单的思考内容提取逻辑
    // 去除可能的工具调用 JSON 部分
    final jsonStart = aiResponse.indexOf('```json');
    if (jsonStart != -1) {
      return aiResponse.substring(0, jsonStart).trim();
    }
    return aiResponse.trim();
  }

  /// 更新消息的工具调用步骤
  Future<void> _updateMessageToolSteps(
    String messageId,
    List<ToolCallStep> steps,
  ) async {
    final message = context.messageService.getMessage(
      context.conversationId,
      messageId,
    );
    if (message != null) {
      final updatedMessage = message.copyWith(
        toolCall: ToolCallResponse(steps: steps),
      );
      await context.messageService.updateMessage(updatedMessage);
      context.notify();
    }
  }
}
