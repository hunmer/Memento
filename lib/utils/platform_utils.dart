import 'package:universal_platform/universal_platform.dart';

/// 平台工具类，提供跨平台的平台检测方法
/// 避免直接使用 dart:io 的 Platform 类导致 Web 平台报错
///
/// 使用示例：
/// ```dart
/// if (PlatformUtils.isAndroid) { ... }
/// if (PlatformUtils.isWeb) { ... }
/// String os = PlatformUtils.operatingSystem;
/// ```
class PlatformUtils {
  PlatformUtils._(); // 私有构造函数，防止实例化

  // ========== 平台检测方法 ==========

  /// 是否为 Web 平台
  static bool get isWeb => UniversalPlatform.isWeb;

  /// 是否为 Android 平台
  static bool get isAndroid => UniversalPlatform.isAndroid;

  /// 是否为 iOS 平台
  static bool get isIOS => UniversalPlatform.isIOS;

  /// 是否为移动平台（Android 或 iOS）
  static bool get isMobile => isAndroid || isIOS;

  /// 是否为 macOS 平台
  static bool get isMacOS => UniversalPlatform.isMacOS;

  /// 是否为 Windows 平台
  static bool get isWindows => UniversalPlatform.isWindows;

  /// 是否为 Linux 平台
  static bool get isLinux => UniversalPlatform.isLinux;

  /// 是否为桌面平台（macOS、Windows 或 Linux）
  static bool get isDesktop => isMacOS || isWindows || isLinux;

  /// 获取操作系统名称
  static String get operatingSystem {
    if (isWeb) return 'web';
    if (isAndroid) return 'android';
    if (isIOS) return 'ios';
    if (isMacOS) return 'macos';
    if (isWindows) return 'windows';
    if (isLinux) return 'linux';
    return 'unknown';
  }
}
