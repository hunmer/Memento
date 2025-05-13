import '../../../core/event/event_manager.dart';
import '../store_plugin.dart';

/// 积分奖励事件处理器
class PointAwardEvent {
  final StorePlugin _storePlugin;

  PointAwardEvent(this._storePlugin) {
    _initializeEventHandlers();
  }

  /// 初始化事件处理器
  void _initializeEventHandlers() {
    final eventManager = EventManager.instance;
    
    // 监听活动添加事件 (3点)
    eventManager.subscribe('activity_added', _handleActivityAdded);
    
    // 监听签到完成事件 (10点)
    eventManager.subscribe('checkin_completed', _handleCheckinCompleted);
    
    // 监听任务完成事件 (20点)
    eventManager.subscribe('task_completed', _handleTaskCompleted);
    
    // 监听笔记添加事件 (10点)
    eventManager.subscribe('note_added', _handleNoteAdded);
    
    // 监听物品添加事件 (5点)
    eventManager.subscribe('goods_added', _handleGoodsAdded);
    
    // 监听消息发送事件
    eventManager.subscribe('onMessageSent', _handleMessageSent);
    
    // 监听记录添加事件
    eventManager.subscribe('onRecordAdded', _handleRecordAdded);
    
    // 监听日记添加事件
    eventManager.subscribe('onDiaryAdded', _handleDiaryAdded);
  }

  /// 处理活动添加事件
  Future<void> _handleActivityAdded(EventArgs args) async {
    await _awardPoints(3, '添加活动奖励');
  }

  /// 处理签到完成事件
  Future<void> _handleCheckinCompleted(EventArgs args) async {
    await _awardPoints(10, '签到完成奖励');
  }

  /// 处理任务完成事件
  Future<void> _handleTaskCompleted(EventArgs args) async {
    await _awardPoints(20, '完成任务奖励');
  }

  /// 处理笔记添加事件
  Future<void> _handleNoteAdded(EventArgs args) async {
    await _awardPoints(10, '添加笔记奖励');
  }

  /// 处理物品添加事件
  Future<void> _handleGoodsAdded(EventArgs args) async {
    await _awardPoints(5, '添加物品奖励');
  }

  /// 处理消息发送事件
  Future<void> _handleMessageSent(EventArgs args) async {
    await _awardPoints(1, '发送消息奖励');
  }

  /// 处理记录添加事件
  Future<void> _handleRecordAdded(EventArgs args) async {
    await _awardPoints(2, '添加记录奖励');
  }

  /// 处理日记添加事件
  Future<void> _handleDiaryAdded(EventArgs args) async {
    await _awardPoints(5, '添加日记奖励');
  }

  /// 添加积分
  Future<void> _awardPoints(int points, String reason) async {
    await _storePlugin.controller.addPoints(points, reason);
  }

  /// 清理事件订阅
  void dispose() {
    final eventManager = EventManager.instance;
    eventManager.unsubscribe('activity_added', _handleActivityAdded);
    eventManager.unsubscribe('checkin_completed', _handleCheckinCompleted);
    eventManager.unsubscribe('task_completed', _handleTaskCompleted);
    eventManager.unsubscribe('note_added', _handleNoteAdded);
    eventManager.unsubscribe('goods_added', _handleGoodsAdded);
    eventManager.unsubscribe('onMessageSent', _handleMessageSent);
    eventManager.unsubscribe('onRecordAdded', _handleRecordAdded);
    eventManager.unsubscribe('onDiaryAdded', _handleDiaryAdded);
  }
}