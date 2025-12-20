import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:universal_platform/universal_platform.dart';
import 'package:Memento/core/services/toast_service.dart';

class PermissionController {
  PermissionController();

  /// èŽ·å–å½“å‰å¹³å°éœ€è¦çš„æƒé™çŠ¶æ€?
  Future<List<PermissionStateInfo>> loadPermissionStates() async {
    final requirements = await _getPermissionRequirements();
    final states = <PermissionStateInfo>[];

    for (final requirement in requirements) {
      final status = await requirement.permission.status;
      states.add(PermissionStateInfo(requirement, status));
    }

    return states;
  }

  /// è¯·æ±‚å•ä¸ªæƒé™
  Future<bool> requestPermission(Permission permission) async {
    try {
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
      debugPrint('è¯·æ±‚æƒé™å¤±è´¥: $e');
      return false;
    }
  }

  /// éžç©ºåˆ—è¡¨ç”¨äºŽæ‰¹é‡è¯·æ±‚æƒé™?
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

  /// èŽ·å– Android SDK ç‰ˆæœ¬
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
    if (!UniversalPlatform.isAndroid) {
      return [];
    }

    final sdkInt = await _getAndroidSdkVersion();
    if (sdkInt >= 33) {
      return [
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
      ];
    }

    return [
      PermissionRequirement(
        permission: Permission.storage,
        titleKey: 'app_permission_storageTitle',
        descriptionKey: 'app_permission_storageDescription',
        icon: Icons.sd_storage,
      ),
    ];
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
  });

  final Permission permission;
  final String titleKey;
  final String descriptionKey;
  final IconData icon;
}

class PermissionStateInfo {
  PermissionStateInfo(this.requirement, this.status);

  final PermissionRequirement requirement;
  final PermissionStatus status;

  bool get isGranted => status.isGranted;
  bool get isPermanentlyDenied => status.isPermanentlyDenied;
}
