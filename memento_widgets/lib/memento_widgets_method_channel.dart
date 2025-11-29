import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'memento_widgets_platform_interface.dart';

/// An implementation of [MementoWidgetsPlatform] that uses method channels.
class MethodChannelMementoWidgets extends MementoWidgetsPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('memento_widgets');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
