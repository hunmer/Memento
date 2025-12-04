import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import '../models/intent_binding.dart';
import '../intent_plugin.dart';
import '../../../core/storage/storage_manager.dart';

/// Intent 服务 - 负责管理 Intent 绑定和测试
class IntentService {
  final IntentPlugin plugin;
  StorageManager get _storage => plugin.storage;

  IntentService(this.plugin);

  /// 获取所有 Intent 绑定
  Future<List<IntentBinding>> getBindings() async {
    try {
      final jsonData = await _storage.read('intent_bindings') as String?;
      if (jsonData == null || jsonData.isEmpty) return [];

      final List<dynamic> jsonList = jsonDecode(jsonData);
      return jsonList
          .map((json) => IntentBinding.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('读取 Intent 绑定失败: $e');
      return [];
    }
  }

  /// 保存 Intent 绑定
  Future<void> saveBinding(IntentBinding binding) async {
    final bindings = await getBindings();
    final index = bindings.indexWhere((b) => b.id == binding.id);

    if (index >= 0) {
      bindings[index] = binding;
    } else {
      bindings.add(binding);
    }

    final jsonList = bindings.map((b) => b.toJson()).toList();
    await _storage.write('intent_bindings', jsonEncode(jsonList));
  }

  /// 删除 Intent 绑定
  Future<void> deleteBinding(String bindingId) async {
    final bindings = await getBindings();
    bindings.removeWhere((b) => b.id == bindingId);
    final jsonList = bindings.map((b) => b.toJson()).toList();
    await _storage.write('intent_bindings', jsonEncode(jsonList));
  }

  /// 根据 ID 获取绑定
  Future<IntentBinding?> getBindingById(String bindingId) async {
    final bindings = await getBindings();
    try {
      return bindings.firstWhere((b) => b.id == bindingId);
    } catch (e) {
      return null;
    }
  }

  /// 测试 Intent
  Future<IntentTestResult> testIntent(IntentBinding binding) async {
    final timestamp = DateTime.now();
    final result = IntentTestResult(
      bindingId: binding.id,
      success: false,
      timestamp: timestamp,
    );

    try {
      // 模拟 Intent 测试（在真实环境中需要使用 platform channels）
      final testData = {
        'action': binding.action,
        'data': binding.data,
        'dataType': binding.dataType,
        'categories': binding.categories,
        'extras': binding.extras,
      };

      // 模拟成功响应
      await Future.delayed(const Duration(milliseconds: 500));

      print('测试 Intent: ${binding.name}');
      print('Action: ${binding.action}');
      print('Data: ${binding.data}');
      print('Extras: ${binding.extras}');

      return result.copyWith(
        success: true,
        data: testData,
      );
    } catch (e) {
      return result.copyWith(
        success: false,
        error: e.toString(),
      );
    }
  }

  /// 触发 Intent（在实际应用中可能需要不同的实现方式）
  Future<bool> triggerIntent(IntentBinding binding) async {
    try {
      // 这里只是一个示例，实际实现需要根据具体需求
      // 可能是打开其他应用、发送广播等
      print('触发 Intent: ${binding.name}');
      print('Action: ${binding.action}');
      print('Data: ${binding.data}');
      print('Extras: ${binding.extras}');

      // 模拟触发延迟
      await Future.delayed(const Duration(milliseconds: 300));

      return true;
    } catch (e) {
      print('触发 Intent 失败: $e');
      return false;
    }
  }

  /// 获取所有测试结果
  Future<List<IntentTestResult>> getTestResults() async {
    try {
      final jsonData = await _storage.read('intent_test_results') as String?;
      if (jsonData == null || jsonData.isEmpty) return [];

      final List<dynamic> jsonList = jsonDecode(jsonData);
      return jsonList
          .map((json) => IntentTestResult.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('读取测试结果失败: $e');
      return [];
    }
  }

  /// 保存测试结果
  Future<void> saveTestResult(IntentTestResult result) async {
    final results = await getTestResults();
    results.add(result);

    // 只保留最近 100 条记录
    if (results.length > 100) {
      results.removeRange(0, results.length - 100);
    }

    final jsonList = results.map((r) => r.toJson()).toList();
    await _storage.write('intent_test_results', jsonEncode(jsonList));
  }

  /// 清空测试结果
  Future<void> clearTestResults() async {
    await _storage.write('intent_test_results', jsonEncode([]));
  }

  /// 导出配置
  Future<String> exportConfig() async {
    final bindings = await getBindings();
    final config = {
      'version': '1.0',
      'exportTime': DateTime.now().toIso8601String(),
      'bindings': bindings.map((b) => b.toJson()).toList(),
    };
    return jsonEncode(config);
  }

  /// 导入配置
  Future<bool> importConfig(String jsonString) async {
    try {
      final config = jsonDecode(jsonString) as Map<String, dynamic>;
      final bindingsJson = config['bindings'] as List<dynamic>;
      final bindings = bindingsJson
          .map((json) => IntentBinding.fromJson(json as Map<String, dynamic>))
          .toList();

      for (final binding in bindings) {
        await saveBinding(binding);
      }

      return true;
    } catch (e) {
      print('导入配置失败: $e');
      return false;
    }
  }
}

/// 扩展方法
extension IntentTestResultExtension on IntentTestResult {
  IntentTestResult copyWith({
    String? bindingId,
    bool? success,
    String? error,
    DateTime? timestamp,
    Map<String, dynamic>? data,
  }) {
    return IntentTestResult(
      bindingId: bindingId ?? this.bindingId,
      success: success ?? this.success,
      error: error ?? this.error,
      timestamp: timestamp ?? this.timestamp,
      data: data ?? this.data,
    );
  }
}
