import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'floating_ball_plugin_method_channel.dart';

abstract class FloatingBallPluginPlatform extends PlatformInterface {
  /// Constructs a FloatingBallPluginPlatform.
  FloatingBallPluginPlatform() : super(token: _token);

  static final Object _token = Object();

  static FloatingBallPluginPlatform _instance = MethodChannelFloatingBallPlugin();

  /// The default instance of [FloatingBallPluginPlatform] to use.
  ///
  /// Defaults to [MethodChannelFloatingBallPlugin].
  static FloatingBallPluginPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [FloatingBallPluginPlatform] when
  /// they register themselves.
  static set instance(FloatingBallPluginPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
