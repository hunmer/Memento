import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:universal_platform/universal_platform.dart';
import 'package:Memento/screens/settings_screen/models/server_sync_config.dart';
import 'package:Memento/core/services/fcm_service.dart';

/// 设备注册服务
///
/// 负责将设备信息（包括 FCM Token）同步到服务器
class DeviceRegistrationService {
  static final DeviceRegistrationService instance = DeviceRegistrationService._();
  DeviceRegistrationService._();

  /// 获取设备名称
  Future<String> getDeviceName() async {
    final deviceInfo = DeviceInfoPlugin();
    String deviceName = 'Unknown Device';

    try {
      if (UniversalPlatform.isAndroid) {
        final info = await deviceInfo.androidInfo;
        deviceName = '${info.brand} ${info.model}';
      } else if (UniversalPlatform.isIOS) {
        final info = await deviceInfo.iosInfo;
        deviceName = info.name;
      } else if (UniversalPlatform.isWindows) {
        final info = await deviceInfo.windowsInfo;
        deviceName = info.computerName;
      } else if (UniversalPlatform.isMacOS) {
        final info = await deviceInfo.macOsInfo;
        deviceName = info.computerName;
      } else if (UniversalPlatform.isLinux) {
        final info = await deviceInfo.linuxInfo;
        deviceName = info.name;
      } else if (UniversalPlatform.isWeb) {
        deviceName = 'Web Browser';
      }
    } catch (e) {
      print('[DeviceRegistration] 获取设备名称失败: $e');
    }

    return deviceName;
  }

  /// 获取平台名称
  String getPlatformName() {
    if (UniversalPlatform.isAndroid) return 'Android';
    if (UniversalPlatform.isIOS) return 'iOS';
    if (UniversalPlatform.isWindows) return 'Windows';
    if (UniversalPlatform.isMacOS) return 'macOS';
    if (UniversalPlatform.isLinux) return 'Linux';
    if (UniversalPlatform.isWeb) return 'Web';
    return 'Unknown';
  }

  /// 注册或更新设备信息
  ///
  /// 在登录成功后或 FCM Token 更新时调用
  Future<bool> registerDevice({
    String? fcmToken,
  }) async {
    try {
      final config = await ServerSyncConfig.load();
      if (!config.isLoggedIn) {
        print('[DeviceRegistration] 用户未登录，跳过注册');
        return false;
      }

      // 如果没有传入 fcmToken，使用配置中保存的
      final tokenToRegister = fcmToken ?? config.fcmToken;

      final deviceName = await getDeviceName();
      final platform = getPlatformName();

      final response = await http.post(
        Uri.parse('${config.server}/api/v1/auth/devices'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${config.token}',
        },
        body: jsonEncode({
          'device_id': config.deviceId,
          'device_name': deviceName,
          'fcm_token': tokenToRegister,
          'platform': platform,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          print('[DeviceRegistration] 设备注册成功: ${config.deviceId}');
          // 保存 fcmToken 到配置
          if (tokenToRegister != null) {
            await config.saveFcmToken(tokenToRegister);
          }
          return true;
        }
      }

      print('[DeviceRegistration] 设备注册失败: ${response.statusCode} ${response.body}');
      return false;
    } catch (e) {
      print('[DeviceRegistration] 设备注册异常: $e');
      return false;
    }
  }

  /// 更新 FCM Token
  ///
  /// 在 FCM Token 刷新时自动调用
  Future<bool> updateFcmToken(String fcmToken) async {
    print('[DeviceRegistration] 更新 FCM Token: ${fcmToken.substring(0, 20)}...');
    return await registerDevice(fcmToken: fcmToken);
  }

  /// 初始化服务并设置 FCM Token 回调
  Future<void> initialize() async {
    // 设置 FCM Token 刷新回调
    FcmService.instance.onTokenRefresh = (newToken) {
      updateFcmToken(newToken);
    };

    // 如果已有 Token，立即同步
    final fcmToken = FcmService.instance.token;
    if (fcmToken != null) {
      final config = await ServerSyncConfig.load();
      if (config.isLoggedIn) {
        await registerDevice(fcmToken: fcmToken);
      }
    }
  }
}
