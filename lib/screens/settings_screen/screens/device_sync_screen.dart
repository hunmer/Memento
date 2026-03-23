import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:universal_platform/universal_platform.dart';
import 'package:Memento/core/services/fcm_service.dart';
import 'package:Memento/core/services/device_registration_service.dart';
import 'package:Memento/screens/settings_screen/models/server_sync_config.dart';
import 'package:Memento/screens/settings_screen/widgets/server_sync_settings_section.dart';
import 'package:Memento/widgets/toast_service.dart';

/// 设备同步设置页面
///
/// 独立页面，显示当前设备信息和服务器同步设置
class DeviceSyncScreen extends StatefulWidget {
  const DeviceSyncScreen({super.key});

  @override
  State<DeviceSyncScreen> createState() => _DeviceSyncScreenState();
}

class _DeviceSyncScreenState extends State<DeviceSyncScreen> {
  String? _fcmToken;
  bool _isLoadingToken = false;
  ServerSyncConfig? _config;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    _config = await ServerSyncConfig.load();
    _fcmToken = FcmService.instance.token;

    setState(() => _isLoading = false);
  }

  Future<void> _refreshFcmToken() async {
    setState(() => _isLoadingToken = true);

    try {
      // 重新获取 Token
      await FcmService.instance.deleteToken();
      await FcmService.instance.initialize();

      _fcmToken = FcmService.instance.token;

      if (_fcmToken != null && _config?.isLoggedIn == true) {
        // 同步到服务器
        await DeviceRegistrationService.instance.updateFcmToken(_fcmToken!);
        toastService.showToast('FCM Token 已更新并同步到服务器');
      } else if (_fcmToken != null) {
        toastService.showToast('FCM Token 已更新');
      } else {
        toastService.showToast('获取 FCM Token 失败');
      }
    } catch (e) {
      toastService.showToast('刷新失败: $e');
    } finally {
      setState(() => _isLoadingToken = false);
    }
  }

  void _copyFcmToken() {
    if (_fcmToken == null) return;

    Clipboard.setData(ClipboardData(text: _fcmToken!));
    toastService.showToast('FCM Token 已复制到剪贴板');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('server_sync_title'.tr),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 设备信息卡片
                  _buildDeviceInfoCard(),
                  const SizedBox(height: 16),
                  // 原有的同步设置
                  const ServerSyncSettingsSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildDeviceInfoCard() {
    final isMobile = UniversalPlatform.isAndroid || UniversalPlatform.isIOS;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.devices),
                const SizedBox(width: 8),
                Text(
                  '当前设备',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 设备 ID
            _buildInfoRow('设备 ID', _config?.deviceId ?? '未设置'),

            const SizedBox(height: 12),

            // 设备名称
            FutureBuilder<String>(
              future: DeviceRegistrationService.instance.getDeviceName(),
              builder: (context, snapshot) {
                return _buildInfoRow('设备名称', snapshot.data ?? '加载中...');
              },
            ),

            const SizedBox(height: 12),

            // 服务器状态
            _buildInfoRow(
              '服务器状态',
              _config?.isLoggedIn == true ? '已连接' : '未连接',
              valueColor: _config?.isLoggedIn == true ? Colors.green : Colors.grey,
            ),

            // FCM Token（仅移动端显示）
            if (isMobile) ...[
              const Divider(height: 32),

              Row(
                children: [
                  Text(
                    'FCM Token',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const Spacer(),
                  if (_isLoadingToken)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else ...[
                    TextButton.icon(
                      onPressed: _refreshFcmToken,
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('刷新'),
                    ),
                    if (_fcmToken != null)
                      IconButton(
                        onPressed: _copyFcmToken,
                        icon: const Icon(Icons.copy, size: 18),
                        tooltip: '复制',
                      ),
                  ],
                ],
              ),

              const SizedBox(height: 8),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _fcmToken ?? '未获取',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: _fcmToken != null
                        ? Theme.of(context).colorScheme.onSurface
                        : Theme.of(context).disabledColor,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: valueColor,
            ),
          ),
        ),
      ],
    );
  }
}
