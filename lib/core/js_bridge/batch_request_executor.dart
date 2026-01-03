import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'js_bridge_manager.dart';
import 'js_bridge_plugin.dart';
import 'package:Memento/core/plugin_base.dart';

/// 单个批处理请求
class _BatchRequest {
  final String requestId;
  final String pluginId;
  final String method;
  final Map<String, dynamic> params;
  final Completer<dynamic> completer;

  _BatchRequest({
    required this.requestId,
    required this.pluginId,
    required this.method,
    required this.params,
    required this.completer,
  });
}

/// 批处理执行器
///
/// 在一定时间窗口内收集多个请求，合并成一个批量请求统一执行，
/// 然后将结果分发给原始请求者。
class BatchRequestExecutor {
  // 批处理配置
  final Duration windowDuration;  // 时间窗口
  final int maxBatchSize;         // 最大批处理大小
  final int maxConcurrent;        // 最大并发数

  // 请求队列
  final List<_BatchRequest> _batchQueue = [];
  final Map<String, _BatchRequest> _pendingRequests = {};

  // 批处理控制
  Timer? _batchTimer;
  bool _isProcessing = false;
  int _runningBatches = 0;

  // 事件统计
  int _totalRequests = 0;
  int _totalBatches = 0;
  int _totalRequestsExecuted = 0;

  BatchRequestExecutor({
    this.windowDuration = const Duration(milliseconds: 50),  // 50ms 窗口
    this.maxBatchSize = 20,          // 最多20个请求合并
    this.maxConcurrent = 3,          // 最多3个批次并发
  });

  /// 添加请求到批处理队列
  Future<dynamic> addRequest({
    required String pluginId,
    required String method,
    required Map<String, dynamic> params,
  }) async {
    final requestId = _generateRequestId();
    final completer = Completer<dynamic>();

    final request = _BatchRequest(
      requestId: requestId,
      pluginId: pluginId,
      method: method,
      params: params,
      completer: completer,
    );

    _pendingRequests[requestId] = request;
    _batchQueue.add(request);
    _totalRequests++;

    debugPrint('[BatchExecutor] 添加请求: $pluginId.$method (队列: ${_batchQueue.length})');

    // 检查是否需要立即触发批处理
    if (_batchQueue.length >= maxBatchSize) {
      // 达到最大批次大小，立即执行
      _flushBatch(force: true);
    } else if (_batchTimer == null || !_batchTimer!.isActive) {
      // 启动新的时间窗口
      _startBatchWindow();
    }

    return completer.future;
  }

  /// 启动批处理时间窗口
  void _startBatchWindow() {
    _batchTimer?.cancel();
    _batchTimer = Timer(windowDuration, () {
      _flushBatch(force: true);
    });
    debugPrint('[BatchExecutor] 启动时间窗口: ${windowDuration.inMilliseconds}ms');
  }

  /// 刷新批处理队列
  Future<void> _flushBatch({required bool force}) async {
    if (_batchQueue.isEmpty) return;

    // 如果正在处理且未强制执行，等待当前批次完成
    if (_isProcessing && !force) {
      debugPrint('[BatchExecutor] 批处理中，等待...');
      return;
    }

    // 检查并发限制
    if (_runningBatches >= maxConcurrent) {
      debugPrint('[BatchExecutor] 达到最大并发数 ($maxConcurrent)，等待...');
      // 等待一段时间后重试
      Future.delayed(Duration(milliseconds: 10), () => _flushBatch(force: true));
      return;
    }

    // 取出当前批次
    final batch = List<_BatchRequest>.from(_batchQueue);
    _batchQueue.clear();
    _batchTimer?.cancel();

    if (batch.isEmpty) return;

    _isProcessing = true;
    _runningBatches++;
    _totalBatches++;

    final batchId = 'batch_${DateTime.now().millisecondsSinceEpoch}';
    debugPrint('[BatchExecutor] 执行批次 $batchId (${batch.length} 个请求)');

    try {
      // 执行批处理
      await _executeBatch(batch);
    } catch (e) {
      debugPrint('[BatchExecutor] 批次执行失败: $e');
      // 所有请求返回错误对象（而不是抛出异常）
      for (final request in batch) {
        if (!request.completer.isCompleted) {
          request.completer.complete({'error': e.toString()});
        }
        _pendingRequests.remove(request.requestId);
      }
    } finally {
      _isProcessing = false;
      _runningBatches--;
      _totalRequestsExecuted += batch.length;

      // 如果还有未处理的请求，继续下一批
      if (_batchQueue.isNotEmpty) {
        _flushBatch(force: force);
      }
    }
  }

  /// 执行单个批次
  Future<void> _executeBatch(List<_BatchRequest> batch) async {
    final jsBridge = JSBridgeManager.instance;

    // 按插件分组（优化：同一插件的请求可以进一步优化）
    final pluginGroups = <String, List<_BatchRequest>>{};
    for (final request in batch) {
      final key = '${request.pluginId}.${request.method}';
      pluginGroups.putIfAbsent(key, () => []).add(request);
    }

    debugPrint('[BatchExecutor] 分组结果: ${pluginGroups.length} 个组');

    // 并发执行所有请求
    final results = await Future.wait(
      batch.map((request) => _executeSingleRequest(request, jsBridge)),
    );

    // 分发结果
    for (var i = 0; i < batch.length; i++) {
      final request = batch[i];
      final result = results[i];

      if (!request.completer.isCompleted) {
        if (result['success'] == true) {
          // 成功：返回数据
          request.completer.complete(result['data']);
        } else {
          // 失败：返回错误对象（而不是抛出异常）
          request.completer.complete({'error': result['error'] ?? 'Unknown error'});
        }
      }

      _pendingRequests.remove(request.requestId);
    }

    final successCount = results.where((r) => r['success'] == true).length;
    debugPrint('[BatchExecutor] 批次完成: $successCount/${batch.length} 成功');
  }

  /// 执行单个请求（直接调用 Dart 方法，绕过 JS 引擎）
  Future<Map<String, dynamic>> _executeSingleRequest(
    _BatchRequest request,
    JSBridgeManager jsBridge,
  ) async {
    try {
      final stopwatch = Stopwatch()..start();

      // 直接获取插件，不通过 JS 引擎
      final plugin = jsBridge.getPlugin(request.pluginId);
      if (plugin == null) {
        return {
          'success': false,
          'error': 'Plugin not found: ${request.pluginId}',
        };
      }

      // 检查是否混入了 JSBridgePlugin
      if (plugin is! JSBridgePlugin) {
        return {
          'success': false,
          'error': 'Plugin does not support JSBridge: ${request.pluginId}',
        };
      }

      // 获取 API 方法
      final apis = plugin.defineJSAPI();
      if (!apis.containsKey(request.method)) {
        return {
          'success': false,
          'error': 'Method not found: ${request.pluginId}.${request.method}',
        };
      }

      // 直接调用 Dart 方法
      final method = apis[request.method]!;
      final result = await Function.apply(method, [request.params]);

      stopwatch.stop();
      debugPrint('[BatchExecutor] 直接调用完成: ${request.pluginId}.${request.method} (${stopwatch.elapsedMilliseconds}ms)');

      return {
        'success': true,
        'data': result,
      };
    } catch (e) {
      debugPrint('[BatchExecutor] 请求失败: ${request.pluginId}.${request.method} - $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// 生成请求 ID
  String _generateRequestId() {
    return 'req_${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond}';
  }

  /// 获取统计信息
  Map<String, dynamic> getStats() {
    final avgBatchSize = _totalBatches > 0
        ? (_totalRequestsExecuted / _totalBatches).toStringAsFixed(2)
        : '0.00';

    return {
      'totalRequests': _totalRequests,
      'totalBatches': _totalBatches,
      'requestsExecuted': _totalRequestsExecuted,
      'pendingRequests': _pendingRequests.length,
      'queuedRequests': _batchQueue.length,
      'runningBatches': _runningBatches,
      'avgBatchSize': avgBatchSize,
    };
  }

  /// 打印统计信息
  void printStats() {
    final stats = getStats();
    debugPrint('[BatchExecutor] 统计: $stats');
  }

  /// 清理资源
  void dispose() {
    _batchTimer?.cancel();

    // 完成所有待处理的请求
    for (final request in _pendingRequests.values) {
      if (!request.completer.isCompleted) {
        request.completer.complete({'error': 'BatchExecutor disposed'});
      }
    }

    _batchQueue.clear();
    _pendingRequests.clear();
  }
}
