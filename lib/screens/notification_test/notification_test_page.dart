import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/core/notification_controller.dart';
import 'package:memento_notifications/memento_notifications.dart';
import '../l10n/screens_localizations.dart';

/// 通知测试页面 - 用于测试 awesome_notifications 功能
class NotificationTestPage extends StatefulWidget {
  const NotificationTestPage({super.key});

  @override
  State<NotificationTestPage> createState() => _NotificationTestPageState();
}

class _NotificationTestPageState extends State<NotificationTestPage> {
  int _notificationId = 1;
  bool _hasPermission = false;
  final List<String> _logs = [];

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final hasPermission = await NotificationController.checkPermission();
    setState(() {
      _hasPermission = hasPermission;
    });
    _addLog('通知权限状态: ${hasPermission ? "已授权" : "未授权"}');
  }

  void _addLog(String message) {
    setState(() {
      _logs.insert(0, '[${DateTime.now().toString().substring(11, 19)}] $message');
      if (_logs.length > 20) {
        _logs.removeLast();
      }
    });
  }

  int _getNextId() {
    return _notificationId++;
  }

  Future<void> _requestPermission() async {
    final granted = await NotificationController.requestPermission();
    setState(() {
      _hasPermission = granted;
    });
    _addLog(granted ? '通知权限已授权' : '通知权限被拒绝');
  }

  Future<void> _showBasicNotification() async {
    final id = _getNextId();
    await NotificationController.createBasicNotification(
      id: id,
      title: '基础通知',
      body: '这是一个基础通知示例 (ID: $id)',
    );
    _addLog('已发送基础通知 (ID: $id)');
  }

  Future<void> _showCustomNotification() async {
    final id = _getNextId();
    await NotificationController.createCustomNotification(
      id: id,
      title: '自定义通知',
      body: '这是一个带按钮的自定义通知! (ID: $id)',
      layout: MementoNotificationLayout.basic,
      actionButtons: [
        const MementoNotificationButton(
          key: 'YES',
          label: 'Yes',
          actionType: MementoButtonActionType.defaultAction,
          color: Colors.green,
        ),
        const MementoNotificationButton(
          key: 'NO',
          label: 'No',
          actionType: MementoButtonActionType.defaultAction,
          color: Colors.red,
        ),
        const MementoNotificationButton(
          key: 'MORE',
          label: 'More',
          actionType: MementoButtonActionType.defaultAction,
        ),
      ],
    );
    _addLog('已发送自定义通知 (ID: $id)');
  }

  Future<void> _showBigPictureNotification() async {
    final id = _getNextId();
    // 使用网络图片示例
    const imageUrl = 'https://picsum.photos/800/400';
    await NotificationController.createBigPictureNotification(
      id: id,
      title: '大图通知',
      body: '这是一个带大图的通知! (ID: $id)',
      bigPicture: imageUrl,
    );
    _addLog('已发送大图通知 (ID: $id)');
  }

  Future<void> _showProgressBarNotification() async {
    final id = _getNextId();
    await NotificationController.createCustomNotification(
      id: id,
      title: '进度通知',
      body: '下载进度: 50%',
      layout: MementoNotificationLayout.progressBar,
    );
    _addLog('已发送进度条通知 (ID: $id)');
  }

  Future<void> _cancelAllNotifications() async {
    await NotificationController.cancelAllNotifications();
    _addLog('已取消所有通知');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('screens_notificationTestPage'.tr),
        elevation: 2,
      ),
      body: Column(
        children: [
          // 权限状态卡片
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _hasPermission ? Colors.green.shade50 : Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _hasPermission ? Colors.green : Colors.red,
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _hasPermission ? Icons.check_circle : Icons.error,
                  color: _hasPermission ? Colors.green : Colors.red,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '通知权限状态',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _hasPermission ? Colors.green.shade900 : Colors.red.shade900,
                        ),
                      ),
                      Text(
                        _hasPermission ? '已授权' : '未授权',
                        style: TextStyle(
                          fontSize: 14,
                          color: _hasPermission ? Colors.green.shade700 : Colors.red.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!_hasPermission)
                  ElevatedButton(
                    onPressed: _requestPermission,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: Text('screens_requestPermission'.tr),
                  ),
              ],
            ),
          ),

          // 测试按钮列表
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                const Text(
                  '测试功能',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                _buildTestButton(
                  icon: Icons.notifications,
                  label: '基础通知',
                  description: '发送一个简单的通知',
                  onPressed: _showBasicNotification,
                  enabled: _hasPermission,
                ),
                _buildTestButton(
                  icon: Icons.notifications_active,
                  label: '自定义通知',
                  description: '发送带按钮的通知',
                  onPressed: _showCustomNotification,
                  enabled: _hasPermission,
                ),
                _buildTestButton(
                  icon: Icons.image,
                  label: '大图通知',
                  description: '发送带大图和按钮的通知',
                  onPressed: _showBigPictureNotification,
                  enabled: _hasPermission,
                ),
                _buildTestButton(
                  icon: Icons.download,
                  label: '进度条通知',
                  description: '发送带进度条的通知',
                  onPressed: _showProgressBarNotification,
                  enabled: _hasPermission,
                ),
                _buildTestButton(
                  icon: Icons.clear_all,
                  label: '取消所有通知',
                  description: '清除所有活动通知',
                  onPressed: _cancelAllNotifications,
                  enabled: _hasPermission,
                  color: Colors.red,
                ),
                const SizedBox(height: 16),
                const Text(
                  '日志记录',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: _logs.isEmpty
                      ? const Center(
                          child: Text(
                            '暂无日志',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _logs.length,
                          padding: const EdgeInsets.all(8),
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Text(
                                _logs[index],
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            );
                          },
                        ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestButton({
    required IconData icon,
    required String label,
    required String description,
    required VoidCallback onPressed,
    required bool enabled,
    Color? color,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(
          icon,
          color: enabled ? (color ?? Colors.blue) : Colors.grey,
          size: 32,
        ),
        title: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: enabled ? null : Colors.grey,
          ),
        ),
        subtitle: Text(
          description,
          style: TextStyle(
            fontSize: 12,
            color: enabled ? Colors.grey.shade600 : Colors.grey.shade400,
          ),
        ),
        trailing: ElevatedButton(
          onPressed: enabled ? onPressed : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: color ?? Colors.blue,
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.grey.shade300,
          ),
          child: Text('screens_test'.tr),
        ),
      ),
    );
  }
}
