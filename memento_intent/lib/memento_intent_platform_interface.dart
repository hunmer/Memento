import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'memento_intent_method_channel.dart';
import 'memento_intent.dart';

abstract class MementoIntentPlatform extends PlatformInterface {
  /// Constructs a MementoIntentPlatform.
  MementoIntentPlatform() : super(token: _token);

  static final Object _token = Object();

  static MementoIntentPlatform _instance = MethodChannelMementoIntent();

  /// The default instance of [MementoIntentPlatform] to use.
  ///
  /// Defaults to [MethodChannelMementoIntent].
  static MementoIntentPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [MementoIntentPlatform] when
  /// they register themselves.
  static set instance(MementoIntentPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// 获取平台版本
  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  /// 深度链接事件流
  Stream<Uri> get onDeepLink {
    throw UnimplementedError('onDeepLink has not been implemented.');
  }

  /// 分享文本事件流
  Stream<String> get onSharedText {
    throw UnimplementedError('onSharedText has not been implemented.');
  }

  /// 分享文件事件流
  Stream<List<SharedMediaFile>> get onSharedFiles {
    throw UnimplementedError('onSharedFiles has not been implemented.');
  }

  /// Intent 数据事件流
  Stream<IntentData> get onIntentData {
    throw UnimplementedError('onIntentData has not been implemented.');
  }

  /// 动态注册深度链接 Scheme
  Future<bool> registerDynamicScheme({
    required String scheme,
    String? host,
    String? pathPrefix,
  }) {
    throw UnimplementedError('registerDynamicScheme() has not been implemented.');
  }

  /// 注销动态注册的 Scheme
  Future<bool> unregisterDynamicScheme() {
    throw UnimplementedError('unregisterDynamicScheme() has not been implemented.');
  }

  /// 获取所有已注册的动态 Schemes
  Future<List<String>> getDynamicSchemes() {
    throw UnimplementedError('getDynamicSchemes() has not been implemented.');
  }
}
