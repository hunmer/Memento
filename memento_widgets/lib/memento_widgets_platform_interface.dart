import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'memento_widgets_method_channel.dart';

abstract class MementoWidgetsPlatform extends PlatformInterface {
  /// Constructs a MementoWidgetsPlatform.
  MementoWidgetsPlatform() : super(token: _token);

  static final Object _token = Object();

  static MementoWidgetsPlatform _instance = MethodChannelMementoWidgets();

  /// The default instance of [MementoWidgetsPlatform] to use.
  ///
  /// Defaults to [MethodChannelMementoWidgets].
  static MementoWidgetsPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [MementoWidgetsPlatform] when
  /// they register themselves.
  static set instance(MementoWidgetsPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
