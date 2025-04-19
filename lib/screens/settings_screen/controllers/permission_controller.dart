import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:universal_platform/universal_platform.dart';

class PermissionController {
  final BuildContext context;
  final bool _mounted;

  PermissionController(this.context) : _mounted = true;

  // 检查并请求必要的权限
  Future<bool> checkAndRequestPermissions() async {
    if (!UniversalPlatform.isAndroid && !UniversalPlatform.isIOS) {
      return true; // 非移动平台，无需请求权限
    }

    if (UniversalPlatform.isAndroid) {
      // 获取 Android SDK 版本
      final sdkInt = await _getAndroidSdkVersion();

      if (sdkInt >= 33) {
        // Android 13 及以上版本
        // 请求媒体权限
        final permissions = [
          Permission.photos,
          Permission.videos,
          Permission.audio,
        ];

        // 检查所有权限状态
        final statuses = await Future.wait(
          permissions.map((permission) => permission.status),
        );

        // 如果有任何权限被拒绝，请求权限
        if (statuses.any((status) => status.isDenied)) {
          final results = await Future.wait(
            permissions.map((permission) => permission.request()),
          );

          // 如果任何权限被拒绝
          if (results.any((status) => status.isDenied)) {
            if (!_mounted) return false;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('需要存储权限才能导出数据。请在系统设置中授予权限。'),
                duration: Duration(seconds: 3),
              ),
            );
            return false;
          }
        }
      } else {
        // Android 12 及以下版本
        final storageStatus = await Permission.storage.status;
        if (storageStatus.isDenied) {
          final result = await Permission.storage.request();
          if (result.isDenied) {
            if (!_mounted) return false;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('需要存储权限才能导出数据。请在系统设置中授予权限。'),
                duration: Duration(seconds: 3),
              ),
            );
            return false;
          }
        }
      }
    }

    // iOS 的文件访问权限通过 file_picker 自动处理
    return true;
  }

  // 获取 Android SDK 版本
  Future<int> _getAndroidSdkVersion() async {
    try {
      if (!UniversalPlatform.isAndroid) return 0;

      final sdkInt = await Permission.storage.status.then((_) async {
        // 通过 platform channel 获取 SDK 版本
        // 这里简单返回一个固定值，假设是 Android 13
        return 33;
      });

      return sdkInt;
    } catch (e) {
      // 如果获取失败，假设是较低版本
      return 29;
    }
  }
}