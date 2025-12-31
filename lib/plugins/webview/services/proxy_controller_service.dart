import 'package:flutter/foundation.dart';
import 'package:universal_platform/universal_platform.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../models/proxy_settings.dart' as models;

/// Proxy 控制器服务（Android 专用）
class ProxyControllerService {
  static final ProxyControllerService _instance = ProxyControllerService._internal();

  factory ProxyControllerService() => _instance;

  ProxyControllerService._internal();

  bool _isInitialized = false;
  bool _isSupported = false;

  /// 检查当前设备是否支持 ProxyController
  Future<bool> checkSupport() async {
    if (kIsWeb || !UniversalPlatform.isAndroid) {
      _isSupported = false;
      return false;
    }

    try {
      _isSupported = await WebViewFeature.isFeatureSupported(
        WebViewFeature.PROXY_OVERRIDE,
      );
      return _isSupported;
    } catch (e) {
      debugPrint('[ProxyController] 检查支持失败: $e');
      _isSupported = false;
      return false;
    }
  }

  /// 是否支持代理功能
  bool get isSupported => _isSupported;

  /// 应用 proxy 设置
  Future<bool> applyProxySettings(models.ProxySettings settings) async {
    if (!_isSupported) {
      debugPrint('[ProxyController] 当前设备不支持代理功能');
      return false;
    }

    try {
      final proxyController = ProxyController.instance();

      // 如果未启用或没有规则，清除 proxy
      if (!settings.enabled || !settings.hasValidConfig) {
        await proxyController.clearProxyOverride();
        _isInitialized = false;
        debugPrint('[ProxyController] 已清除代理配置');
        return true;
      }

      // 转换规则 - flutter_inappwebview 的 ProxyRule 只支持 url 和 schemeFilter
      final proxyRules = settings.proxyRules.map((rule) {
        // 构建完整的 URL（包含过滤器信息）
        String proxyUrl = rule.url;

        // 如果有其他过滤器，记录警告（flutter_inappwebview 不直接支持）
        if (rule.hostFilter != null || rule.portFilter != null || rule.pathFilter != null) {
          debugPrint(
            '[ProxyController] 警告: hostFilter/portFilter/pathFilter 过滤器在当前版本不完全支持',
          );
        }

        return ProxyRule(url: proxyUrl);
      }).toList();

      // 应用 proxy 配置
      await proxyController.setProxyOverride(
        settings: ProxySettings(
          proxyRules: proxyRules,
          bypassRules: settings.bypassRules,
          reverseBypassEnabled: settings.reverseBypassEnabled,
        ),
      );

      _isInitialized = true;
      debugPrint('[ProxyController] 已应用代理配置: ${settings.proxyRules.length} 条规则');
      return true;
    } catch (e) {
      debugPrint('[ProxyController] 应用代理配置失败: $e');
      return false;
    }
  }

  /// 清除 proxy 设置
  Future<void> clearProxySettings() async {
    if (!_isSupported) return;

    try {
      final proxyController = ProxyController.instance();
      await proxyController.clearProxyOverride();
      _isInitialized = false;
      debugPrint('[ProxyController] 已清除代理配置');
    } catch (e) {
      debugPrint('[ProxyController] 清除代理配置失败: $e');
    }
  }

  /// 是否已初始化代理配置
  bool get isInitialized => _isInitialized;
}
