import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:universal_platform/universal_platform.dart';
import 'package:Memento/core/services/toast_service.dart';
import 'package:Memento/plugins/calendar/services/system_calendar_manager.dart';

class PermissionController {
  PermissionController();

  Future<List<PermissionStateInfo>> loadPermissionStates() async {
    final requirements = await _getPermissionRequirements();
    final states = <PermissionStateInfo>[];

    for (final requirement in requirements) {
      final status = await requirement.permission.status;
      states.add(PermissionStateInfo(requirement, status));
    }

    return states;
  }

  Future<bool> requestPermission(Permission permission) async {
    try {
      // 检查是否有自定义处理器
      final requirements = await _getPermissionRequirements();
      final requirement = requirements.firstWhereOrNull(
        (req) => req.permission == permission,
      );

      // 如果有自定义处理器,使用自定义处理器
      if (requirement?.customHandler != null) {
        return await requirement!.customHandler!();
      }

      // 否则使用默认请求流程
      final result = await permission.request();
      if (result.isPermanentlyDenied) {
        Toast.error(
          'app_permissionRequiredInSettings'.trParams({
            'permission': _getPermissionName(permission),
          }),
        );
      }
      return result.isGranted;
    } catch (e) {
      debugPrint('请求权限失败: $e');
      return false;
    }
  }

  Future<bool> requestPermissions(
    List<PermissionRequirement> requirements,
  ) async {
    bool allGranted = true;
    for (final requirement in requirements) {
      final status = await requirement.permission.status;
      if (status.isGranted) continue;

      final granted = await requestPermission(requirement.permission);
      if (!granted) {
        allGranted = false;
      }
    }
    return allGranted;
  }

  Future<int> _getAndroidSdkVersion() async {
    try {
      if (!UniversalPlatform.isAndroid) return 0;
      final sdkInt = await Permission.storage.status.then((_) async => 33);
      return sdkInt;
    } catch (e) {
      return 29;
    }
  }

  Future<List<PermissionRequirement>> _getPermissionRequirements() async {
    final List<PermissionRequirement> requirements = [];

    if (UniversalPlatform.isAndroid) {
      final sdkInt = await _getAndroidSdkVersion();
      if (sdkInt >= 33) {
        requirements.addAll([
          PermissionRequirement(
            permission: Permission.photos,
            titleKey: 'app_permission_photosTitle',
            descriptionKey: 'app_permission_photosDescription',
            icon: Icons.photo_outlined,
          ),
          PermissionRequirement(
            permission: Permission.videos,
            titleKey: 'app_permission_videosTitle',
            descriptionKey: 'app_permission_videosDescription',
            icon: Icons.video_library_outlined,
          ),
          PermissionRequirement(
            permission: Permission.audio,
            titleKey: 'app_permission_audioTitle',
            descriptionKey: 'app_permission_audioDescription',
            icon: Icons.audiotrack,
          ),
          PermissionRequirement(
            permission: Permission.notification,
            titleKey: 'app_permission_notificationsTitle',
            descriptionKey: 'app_permission_notificationsDescription',
            icon: Icons.notifications_active_outlined,
          ),
        ]);
      } else {
        requirements.add(
          PermissionRequirement(
            permission: Permission.storage,
            titleKey: 'app_permission_storageTitle',
            descriptionKey: 'app_permission_storageDescription',
            icon: Icons.sd_storage,
          ),
        );
      }
    }

    // 添加日历权限（iOS 和 Android 通用）
    requirements.add(
      PermissionRequirement(
        permission: Permission.calendar,
        titleKey: 'app_permission_calendarTitle',
        descriptionKey: 'app_permission_calendarDescription',
        icon: Icons.calendar_today,
        customHandler: _handleCalendarPermission,
      ),
    );

    return requirements;
  }

  /// 日历权限的自定义处理器
  /// 请求权限并在授予后初始化系统日历管理器
  Future<bool> _handleCalendarPermission() async {
    try {
      // 先请求权限
      final status = await Permission.calendar.request();

      if (status.isGranted) {
        // 权限授予后初始化系统日历管理器
        // 注意: 现在 initialize() 不会再请求权限,只会检查权限并初始化
        final initialized = await SystemCalendarManager.instance.initialize();
        if (!initialized) {
          Toast.error('日历初始化失败');
          return false;
        }
        Toast.success('日历权限已授予并初始化成功');
        return true;
      } else if (status.isPermanentlyDenied) {
        Toast.error(
          'app_permissionRequiredInSettings'.trParams({
            'permission': _getPermissionName(Permission.calendar),
          }),
        );
        return false;
      }

      return false;
    } catch (e) {
      debugPrint('请求日历权限失败: $e');
      Toast.error('日历权限请求失败');
      return false;
    }
  }

  String _getPermissionName(Permission permission) {
    switch (permission) {
      case Permission.photos:
        return 'app_permission_photosTitle'.tr;
      case Permission.videos:
        return 'app_permission_videosTitle'.tr;
      case Permission.audio:
        return 'app_permission_audioTitle'.tr;
      case Permission.notification:
        return 'app_permission_notificationsTitle'.tr;
      case Permission.storage:
        return 'app_permission_storageTitle'.tr;
      case Permission.calendar:
        return 'app_permission_calendarTitle'.tr;
      default:
        return permission.toString();
    }
  }
}

class PermissionRequirement {
  PermissionRequirement({
    required this.permission,
    required this.titleKey,
    required this.descriptionKey,
    required this.icon,
    this.customHandler,
  });

  final Permission permission;
  final String titleKey;
  final String descriptionKey;
  final IconData icon;
  final Future<bool> Function()? customHandler;
}

class PermissionStateInfo {
  PermissionStateInfo(this.requirement, this.status);

  final PermissionRequirement requirement;
  final PermissionStatus status;

  bool get isGranted => status.isGranted;
  bool get isPermanentlyDenied => status.isPermanentlyDenied;
}
