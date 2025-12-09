import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:universal_platform/universal_platform.dart';
import 'package:Memento/core/services/toast_service.dart';

class PermissionController {
  final BuildContext context;
  final bool _mounted;

  PermissionController(this.context) : _mounted = true;

  // 获取所需的权限列表
  List<Permission> _getRequiredPermissions() {
    if (!UniversalPlatform.isAndroid) {
      return [];
    }
    return [
      Permission.photos,
      Permission.videos,
      Permission.audio,
      Permission.notification,
    ];
  }

  // 检查单个权限的状态
  Future<bool> _checkSinglePermission(Permission permission) async {
    final status = await permission.status;
    return status.isGranted;
  }

  // 请求单个权限
  Future<bool> _requestSinglePermission(Permission permission) async {
    try {
      final result = await permission.request();
      return result.isGranted;
    } catch (e) {
      debugPrint('请求权限失败: $e');
      return false;
    }
  }

  // 显示权限说明对话框
  Future<bool> _showPermissionDialog(String permissionName) async {
    if (!_mounted) return false;

    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('app_permissionRequired'
                  .tr
                  .replaceFirst('{permissionName}', permissionName)),
              content: Text('app_permissionRequiredForApp'
                  .tr
                  .replaceFirst('{permissionName}', permissionName)),
              actions: <Widget>[
                TextButton(
                  child: Text('app_notNow'.tr),
                  onPressed: () => Navigator.of(context).pop(false),
                ),
                TextButton(
                  child: Text('app_grantPermission'.tr),
                  onPressed: () => Navigator.of(context).pop(true),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  // 获取权限的显示名称
  String _getPermissionName(Permission permission) {
    switch (permission) {
      case Permission.photos:
        return '照片';
      case Permission.videos:
        return '视频';
      case Permission.audio:
        return '音频';
      case Permission.storage:
        return '存储';
      case Permission.notification:
        return '通知';
      default:
        return '未知';
    }
  }

  // 检查并逐个请求必要的权限
  Future<bool> checkAndRequestPermissions() async {
    if (!UniversalPlatform.isAndroid && !UniversalPlatform.isIOS) {
      return true; // 非移动平台，无需请求权限
    }

    if (UniversalPlatform.isAndroid) {
      // 获取 Android SDK 版本
      final sdkInt = await _getAndroidSdkVersion();

      if (sdkInt >= 33) {
        // Android 13 及以上版本需要单独请求媒体权限
        final permissions = _getRequiredPermissions();

        for (final permission in permissions) {
          // 检查权限状态
          final isGranted = await _checkSinglePermission(permission);
          if (!isGranted) {
            // 显示权限说明对话框
            final permissionName = _getPermissionName(permission);
            final shouldRequest = await _showPermissionDialog(permissionName);

            if (!shouldRequest || !_mounted) {
              // 用户拒绝显示权限对话框
              return false;
            }

            // 请求单个权限
            final granted = await _requestSinglePermission(permission);
            if (!granted) {
              if (!_mounted) return false;

              Toast.error('app_permissionRequiredInSettings'
                  .tr
                  .replaceFirst('{permissionName}', permissionName));
              return false;
            }
          }
        }
      } else {
        // Android 12 及以下版本
        final isGranted = await _checkSinglePermission(Permission.storage);
        if (!isGranted) {
          // 显示权限说明对话框
          final shouldRequest = await _showPermissionDialog('存储');

          if (!shouldRequest || !_mounted) {
            return false;
          }

          // 请求存储权限
          final granted = await _requestSinglePermission(Permission.storage);
          if (!granted) {
            if (!_mounted) return false;

            Toast.error('app_storagePermissionRequired'.tr);
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
