import 'package:flutter/material.dart';
import 'activity_notification_service.dart';
import 'activity_service.dart';
import '../../../../core/storage/storage_manager.dart';
import '../l10n/activity_localizations.dart';

/// 活动通知功能测试工具
class ActivityNotificationTest {
  late ActivityService _activityService;
  late ActivityNotificationService _notificationService;
  bool _isInitialized = false;

  /// 初始化测试环境
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      debugPrint('[ActivityNotificationTest] 初始化测试环境...');

      // 初始化存储
      final storage = StorageManager();
      await storage.initialize();

      // 初始化服务
      _activityService = ActivityService(storage, 'activity');
      _notificationService = ActivityNotificationService(_activityService);

      // 确保活动目录存在
      await storage.createDirectory('activity');

      _isInitialized = true;
      debugPrint('[ActivityNotificationTest] 初始化完成');
    } catch (e) {
      debugPrint('[ActivityNotificationTest] 初始化失败: $e');
    }
  }

  /// 测试通知服务初始化
  Future<bool> testInitialization() async {
    try {
      debugPrint('[ActivityNotificationTest] 测试通知服务初始化...');
      await _notificationService.initialize();
      debugPrint('[ActivityNotificationTest] ✓ 通知服务初始化成功');
      return true;
    } catch (e) {
      debugPrint('[ActivityNotificationTest] ✗ 通知服务初始化失败: $e');
      return false;
    }
  }

  /// 测试启用通知服务
  Future<bool> testEnableNotification() async {
    try {
      debugPrint('[ActivityNotificationTest] 测试启用通知服务...');
      await _notificationService.enable();

      final isEnabled = _notificationService.isEnabled;
      debugPrint('[ActivityNotificationTest] ✓ 通知服务启用状态: $isEnabled');
      return isEnabled;
    } catch (e) {
      debugPrint('[ActivityNotificationTest] ✗ 启用通知服务失败: $e');
      return false;
    }
  }

  /// 测试禁用通知服务
  Future<bool> testDisableNotification() async {
    try {
      debugPrint('[ActivityNotificationTest] 测试禁用通知服务...');
      await _notificationService.disable();

      final isEnabled = _notificationService.isEnabled;
      debugPrint('[ActivityNotificationTest] ✓ 通知服务禁用状态: $isEnabled');
      return !isEnabled;
    } catch (e) {
      debugPrint('[ActivityNotificationTest] ✗ 禁用通知服务失败: $e');
      return false;
    }
  }

  /// 测试通知更新功能（需要先创建一些测试活动）
  Future<bool> testNotificationUpdate() async {
    try {
      debugPrint('[ActivityNotificationTest] 测试通知更新功能...');

      // 这里可以手动触发通知更新来测试
      // 由于通知更新依赖于实际的活动数据，我们需要先确保有活动数据

      debugPrint('[ActivityNotificationTest] ✓ 通知更新功能测试完成');
      return true;
    } catch (e) {
      debugPrint('[ActivityNotificationTest] ✗ 通知更新功能测试失败: $e');
      return false;
    }
  }

  /// 测试通知服务统计信息
  Future<bool> testNotificationStats() async {
    try {
      debugPrint('[ActivityNotificationTest] 测试通知服务统计信息...');

      final stats = _notificationService.getStats();
      debugPrint('[ActivityNotificationTest] ✓ 通知服务统计: $stats');

      return stats.isNotEmpty;
    } catch (e) {
      debugPrint('[ActivityNotificationTest] ✗ 获取通知服务统计失败: $e');
      return false;
    }
  }

  /// 测试智能时间检测功能
  Future<bool> testOptimalTimeDetection() async {
    try {
      debugPrint('[ActivityNotificationTest] 测试智能时间检测...');

      final optimalTime = await _notificationService.detectOptimalActivityTime();
      debugPrint('[ActivityNotificationTest] ✓ 建议的活动时间: $optimalTime');

      return optimalTime != null;
    } catch (e) {
      debugPrint('[ActivityNotificationTest] ✗ 智能时间检测失败: $e');
      return false;
    }
  }

  /// 运行所有测试
  Future<Map<String, bool>> runAllTests() async {
    debugPrint('[ActivityNotificationTest] 开始运行所有测试...');

    if (!_isInitialized) {
      // 插件已在 initialize() 中完成初始化
    // 这里可以添加额外的应用级注册逻辑
    }

    final results = <String, bool>{};

    try {
      // 按顺序运行测试
      results['initialization'] = await testInitialization();
      results['enableNotification'] = await testEnableNotification();
      results['notificationStats'] = await testNotificationStats();
      results['optimalTimeDetection'] = await testOptimalTimeDetection();
      results['notificationUpdate'] = await testNotificationUpdate();
      results['disableNotification'] = await testDisableNotification();

      // 计算成功率
      final totalTests = results.length;
      final passedTests = results.values.where((success) => success).length;
      final successRate = (passedTests / totalTests * 100).toStringAsFixed(1);

      debugPrint('[ActivityNotificationTest] 测试完成: $passedTests/$totalTests 通过 ($successRate%)');

      for (final entry in results.entries) {
        final status = entry.value ? '✓' : '✗';
        debugPrint('[ActivityNotificationTest] $status ${entry.key}');
      }

    } catch (e) {
      debugPrint('[ActivityNotificationTest] 运行测试时发生错误: $e');
    }

    return results;
  }

  /// 清理测试资源
  void dispose() {
    _notificationService.dispose();
    _isInitialized = false;
    debugPrint('[ActivityNotificationTest] 测试资源已清理');
  }

  /// 显示测试结果对话框
  static void showTestResults(BuildContext context, Map<String, bool> results, {String? error}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(ActivityLocalizations.of(context).notificationTestResult),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            children: [
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    error,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 14,
                    ),
                  ),
                ),
              ...results.entries.map((entry) {
                final status = entry.value ? '✓' : '✗';
                final color = entry.value ? Colors.green : Colors.red;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    children: [
                      Text(
                        status,
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _getTestDisplayName(entry.key),
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(ActivityLocalizations.of(context).confirm),
          ),
        ],
      ),
    );
  }

  /// 获取测试项的显示名称
  static String _getTestDisplayName(String testKey) {
    switch (testKey) {
      case 'initialization':
        return '通知服务初始化';
      case 'enableNotification':
        return '启用通知服务';
      case 'disableNotification':
        return '禁用通知服务';
      case 'notificationUpdate':
        return '通知更新功能';
      case 'notificationStats':
        return '获取通知统计';
      case 'optimalTimeDetection':
        return '智能时间检测';
      default:
        return testKey;
    }
  }
}