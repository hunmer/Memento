import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'floating_ball_plugin_platform_interface.dart';

/// An implementation of [FloatingBallPluginPlatform] that uses method channels.
class MethodChannelFloatingBallPlugin extends FloatingBallPluginPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('floating_ball_plugin');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
