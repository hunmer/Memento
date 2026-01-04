import 'dart:async';
import 'package:uuid/uuid.dart';
import '../models/ai_message_status.dart';
import '../../../core/event/event_manager.dart';
import '../../../core/event/event_args.dart';

/// AI 消息状态变化事件参数
class AIMessageStatusEventArgs extends EventArgs {
  /// 消息 ID
  final String messageId;

  /// 会话 ID
  final String conversationId;

  /// 旧状态
  final AIMessageStatus? oldStatus;

  /// 新状态
  final AIMessageStatus newStatus;

  /// 链式执行 ID（如果有）
  final String? chainExecutionId;

  /// 链式调用中的步骤索引（如果有）
  final int? chainStepIndex;

  AIMessageStatusEventArgs({
    required this.messageId,
    required this.conversationId,
    this.oldStatus,
    required this.newStatus,
    this.chainExecutionId,
    this.chainStepIndex,
    String eventName = '',
  }) : super(eventName);

  @override
  String toString() {
    return 'AIMessageStatusEventArgs(messageId: $messageId, conversationId: $conversationId, '
        'oldStatus: $oldStatus, newStatus: $newStatus, chainExecutionId: $chainExecutionId, '
        'chainStepIndex: $chainStepIndex)';
  }
}

/// 全局 AI 消息状态管理器
///
/// 职责：
/// 1. 管理所有 AI 消息的生成状态
/// 2. 通过事件系统发布状态变化通知
/// 3. 提供状态查询接口
/// 4. 支持按会话、链式执行 ID 批量查询
class AIMessageStatusManager {
  /// 单例实例
  static final AIMessageStatusManager _instance = AIMessageStatusManager._internal();
  factory AIMessageStatusManager() => _instance;
  AIMessageStatusManager._internal() {
    _startPeriodicCleanup();
  }

  final Uuid _uuid = const Uuid();

  /// 消息状态存储 (messageId -\> statusData)
  final Map<String, AIMessageStatusData> _messageStates = {};

  /// 按会话分组的消息 ID (conversationId -\> Set\<messageId\>)
  final Map<String, Set<String>> _conversationMessages = {};

  /// 按链式执行 ID 分组的消息 ID (chainExecutionId -\> Set\<messageId\>)
  final Map<String, Set<String>> _chainMessages = {};

  /// 清理定时器
  Timer? _cleanupTimer;

  /// 事件名称常量
  static const String eventStatusChanged = 'ai_message_status_changed';
  static const String eventContentUpdated = 'ai_message_content_updated';
  static const String eventToolCallUpdated = 'ai_message_tool_call_updated';
  static const String eventChainStepCompleted = 'ai_message_chain_step_completed';

  /// 状态保留时长（毫秒）- 终止状态保留 1 小时后清理
  static const int terminalStateRetentionMs = 3600000;

  /// 初始化
  Future<void> initialize() async {
    // 可以在这里加载持久化的状态（如果需要）
  }

  /// 注册或更新消息状态
  ///
  /// 如果消息不存在，则创建新状态记录
  /// 如果消息已存在，则更新状态并触发事件
  Future<void> updateMessageStatus(AIMessageStatusData status) async {
    final oldStatus = _messageStates[status.messageId]?.status;
    final isExisting = _messageStates.containsKey(status.messageId);

    // 更新状态存储
    _messageStates[status.messageId] = status;

    // 更新索引
    _conversationMessages.putIfAbsent(status.conversationId, () => {});
    _conversationMessages[status.conversationId]!.add(status.messageId);

    if (status.chainExecutionId != null) {
      _chainMessages.putIfAbsent(status.chainExecutionId!, () => {});
      _chainMessages[status.chainExecutionId]!.add(status.messageId);
    }

    // 发布状态变化事件（仅当状态真正改变时）
    if (!isExisting || oldStatus != status.status) {
      final eventArgs = AIMessageStatusEventArgs(
        messageId: status.messageId,
        conversationId: status.conversationId,
        oldStatus: oldStatus,
        newStatus: status.status,
        chainExecutionId: status.chainExecutionId,
        chainStepIndex: status.chainStepIndex,
        eventName: eventStatusChanged,
      );
      EventManager.instance.broadcast(eventStatusChanged, eventArgs);
    }

    // 如果有工具调用步骤，发布工具调用更新事件
    if (status.toolCallSteps != null && status.toolCallSteps!.isNotEmpty) {
      EventManager.instance.broadcast(
        eventToolCallUpdated,
        Value(status.messageId, eventToolCallUpdated),
      );
    }

    // 如果是链式调用的步骤完成，发布步骤完成事件
    if (status.isTerminal && status.chainExecutionId != null) {
      EventManager.instance.broadcast(
        eventChainStepCompleted,
        Values(status.chainExecutionId!, status.chainStepIndex, eventChainStepCompleted),
      );
    }
  }

  /// 创建新消息状态记录
  Future<String> createMessageStatus({
    required String conversationId,
    String? messageId,
    AIMessageStatus status = AIMessageStatus.pending,
    String? generatedByAgentId,
    String? chainExecutionId,
    int? chainStepIndex,
    bool isFinalSummary = false,
    Map<String, dynamic>? metadata,
  }) async {
    final id = messageId ?? _uuid.v4();

    final statusData = AIMessageStatusData(
      messageId: id,
      conversationId: conversationId,
      status: status,
      updatedAt: DateTime.now(),
      generatedByAgentId: generatedByAgentId,
      chainExecutionId: chainExecutionId,
      chainStepIndex: chainStepIndex,
      isFinalSummary: isFinalSummary,
      metadata: metadata,
    );

    await updateMessageStatus(statusData);
    return id;
  }

  /// 获取消息状态
  AIMessageStatusData? getMessageStatus(String messageId) {
    return _messageStates[messageId];
  }

  /// 获取会话的所有消息状态
  List<AIMessageStatusData> getConversationMessages(String conversationId) {
    final messageIds = _conversationMessages[conversationId];
    if (messageIds == null) return [];

    return messageIds
        .map((id) => _messageStates[id])
        .whereType<AIMessageStatusData>()
        .toList()
      ..sort((a, b) => a.updatedAt.compareTo(b.updatedAt));
  }

  /// 获取会话中正在进行的消息
  List<AIMessageStatusData> getActiveConversationMessages(String conversationId) {
    return getConversationMessages(conversationId)
        .where((msg) => msg.isActive)
        .toList();
  }

  /// 获取链式执行的所有消息状态
  List<AIMessageStatusData> getChainMessages(String chainExecutionId) {
    final messageIds = _chainMessages[chainExecutionId];
    if (messageIds == null) return [];

    return messageIds
        .map((id) => _messageStates[id])
        .whereType<AIMessageStatusData>()
        .toList()
      ..sort((a, b) => (a.chainStepIndex ?? 0).compareTo(b.chainStepIndex ?? 0));
  }

  /// 获取链式执行的进度
  Map<String, dynamic> getChainProgress(String chainExecutionId) {
    final messages = getChainMessages(chainExecutionId);
    final total = messages.length;
    final completed = messages.where((m) => m.isTerminal).length;
    return {
      'completed': completed,
      'total': total,
      'isCompleted': completed == total && total > 0,
    };
  }

  /// 更新消息内容（流式更新时使用）
  Future<void> updateMessageContent({
    required String messageId,
    required String content,
    int? tokenCount,
  }) async {
    final currentStatus = _messageStates[messageId];
    if (currentStatus == null) return;

    final updatedStatus = currentStatus.copyWith(
      currentContent: content,
      tokenCount: tokenCount ?? currentStatus.tokenCount + (content.length - (currentStatus.currentContent?.length ?? 0)),
      updatedAt: DateTime.now(),
    );

    await updateMessageStatus(updatedStatus);

    // 发布内容更新事件
    EventManager.instance.broadcast(
      eventContentUpdated,
      Value(messageId, eventContentUpdated),
    );
  }

  /// 更新消息状态为指定状态
  Future<void> changeMessageStatus({
    required String messageId,
    required AIMessageStatus newStatus,
    String? error,
  }) async {
    final currentStatus = _messageStates[messageId];
    if (currentStatus == null) return;

    final updatedStatus = currentStatus.copyWith(
      status: newStatus,
      error: error,
      updatedAt: DateTime.now(),
    );

    await updateMessageStatus(updatedStatus);
  }

  /// 更新工具调用步骤
  Future<void> updateToolCallStep({
    required String messageId,
    required int stepIndex,
    required ToolCallExecutionStatus status,
    String? result,
    String? error,
  }) async {
    final currentStatus = _messageStates[messageId];
    if (currentStatus == null || currentStatus.toolCallSteps == null) return;

    if (stepIndex >= currentStatus.toolCallSteps!.length) return;

    final steps = List<ToolCallStepInfo>.from(currentStatus.toolCallSteps!);
    final step = steps[stepIndex];

    steps[stepIndex] = step.copyWith(
      status: status,
      result: result,
      error: error,
      completedAt: status.isTerminal ? DateTime.now() : null,
    );

    final updatedStatus = currentStatus.copyWith(
      toolCallSteps: steps,
      updatedAt: DateTime.now(),
    );

    await updateMessageStatus(updatedStatus);
  }

  /// 添加工具调用步骤
  Future<void> addToolCallStep({
    required String messageId,
    required String method,
    required String title,
    required String desc,
    required String data,
  }) async {
    final currentStatus = _messageStates[messageId];
    if (currentStatus == null) return;

    final steps = List<ToolCallStepInfo>.from(currentStatus.toolCallSteps ?? []);
    final newStep = ToolCallStepInfo(
      index: steps.length,
      method: method,
      title: title,
      desc: desc,
      status: ToolCallExecutionStatus.pending,
      data: data,
      startedAt: DateTime.now(),
    );

    steps.add(newStep);

    final updatedStatus = currentStatus.copyWith(
      toolCallSteps: steps,
      updatedAt: DateTime.now(),
    );

    await updateMessageStatus(updatedStatus);
  }

  /// 删除消息状态
  Future<void> removeMessageStatus(String messageId) async {
    final status = _messageStates[messageId];
    if (status == null) return;

    // 从索引中移除
    _conversationMessages[status.conversationId]?.remove(messageId);
    if (status.chainExecutionId != null) {
      _chainMessages[status.chainExecutionId]?.remove(messageId);
    }

    // 从存储中移除
    _messageStates.remove(messageId);
  }

  /// 清理会话的所有消息状态
  Future<void> clearConversationMessages(String conversationId) async {
    final messageIds = _conversationMessages[conversationId];
    if (messageIds == null) return;

    for (final messageId in List<String>.from(messageIds)) {
      await removeMessageStatus(messageId);
    }

    _conversationMessages.remove(conversationId);
  }

  /// 清理链式执行的所有消息状态
  Future<void> clearChainMessages(String chainExecutionId) async {
    final messageIds = _chainMessages[chainExecutionId];
    if (messageIds == null) return;

    for (final messageId in List<String>.from(messageIds)) {
      await removeMessageStatus(messageId);
    }

    _chainMessages.remove(chainExecutionId);
  }

  /// 订阅消息状态变化
  String subscribeToMessageStatus(
    String messageId,
    void Function(AIMessageStatusData) callback,
  ) {
    void handler(EventArgs args) {
      if (args is AIMessageStatusEventArgs && args.messageId == messageId) {
        final status = _messageStates[messageId];
        if (status != null) {
          callback(status);
        }
      }
    }

    return EventManager.instance.subscribe(eventStatusChanged, handler);
  }

  /// 订阅会话的所有消息状态变化
  String subscribeToConversationMessages(
    String conversationId,
    void Function(List<AIMessageStatusData>) callback,
  ) {
    void handler(EventArgs args) {
      if (args is AIMessageStatusEventArgs && args.conversationId == conversationId) {
        callback(getConversationMessages(conversationId));
      }
    }

    return EventManager.instance.subscribe(eventStatusChanged, handler);
  }

  /// 订阅链式执行的消息状态变化
  String subscribeToChainMessages(
    String chainExecutionId,
    void Function(List<AIMessageStatusData>) callback,
  ) {
    void handler(EventArgs args) {
      if (args is AIMessageStatusEventArgs && args.chainExecutionId == chainExecutionId) {
        callback(getChainMessages(chainExecutionId));
      }
    }

    return EventManager.instance.subscribe(eventStatusChanged, handler);
  }

  /// 订阅链式执行进度变化
  String subscribeToChainProgress(
    String chainExecutionId,
    void Function(Map<String, dynamic>) callback,
  ) {
    void handler(EventArgs args) {
      if (args is Values && args.value1 == chainExecutionId) {
        callback(getChainProgress(chainExecutionId));
      }
    }

    return EventManager.instance.subscribe(eventChainStepCompleted, handler);
  }

  /// 取消订阅
  /// 注意：需要同时提供事件名称和处理器
  void unsubscribeEvent(String eventName, Function(EventArgs) handler) {
    EventManager.instance.unsubscribe(eventName, handler);
  }

  /// 启动定期清理任务
  void _startPeriodicCleanup() {
    // 每 5 分钟清理一次过期的终止状态消息
    _cleanupTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      _cleanupExpiredStates();
    });
  }

  /// 清理过期的状态记录
  void _cleanupExpiredStates() {
    final now = DateTime.now();
    final expiredMessageIds = <String>[];

    for (final entry in _messageStates.entries) {
      if (entry.value.isTerminal) {
        final age = now.difference(entry.value.updatedAt).inMilliseconds;
        if (age > terminalStateRetentionMs) {
          expiredMessageIds.add(entry.key);
        }
      }
    }

    for (final messageId in expiredMessageIds) {
      removeMessageStatus(messageId);
    }
  }

  /// 释放资源
  void dispose() {
    _cleanupTimer?.cancel();
    _messageStates.clear();
    _conversationMessages.clear();
    _chainMessages.clear();
  }

  /// 获取统计信息
  Map<String, dynamic> getStatistics() {
    final activeMessages = _messageStates.values.where((m) => m.isActive).length;
    final terminalMessages = _messageStates.values.where((m) => m.isTerminal).length;

    return {
      'totalMessages': _messageStates.length,
      'activeMessages': activeMessages,
      'terminalMessages': terminalMessages,
      'conversations': _conversationMessages.length,
      'activeChains': _chainMessages.length,
    };
  }
}

/// 扩展：给枚举添加 isTerminal 属性
extension AIMessageStatusExtension on AIMessageStatus {
  bool get isTerminal {
    return this == AIMessageStatus.completed ||
        this == AIMessageStatus.cancelled ||
        this == AIMessageStatus.failed;
  }

  bool get isActive {
    return this == AIMessageStatus.preparing ||
        this == AIMessageStatus.generating ||
        this == AIMessageStatus.toolCalling;
  }
}

/// 扩展：给工具调用状态枚举添加 isTerminal 属性
extension ToolCallExecutionStatusExtension on ToolCallExecutionStatus {
  bool get isTerminal {
    return this == ToolCallExecutionStatus.success ||
        this == ToolCallExecutionStatus.failed;
  }
}
