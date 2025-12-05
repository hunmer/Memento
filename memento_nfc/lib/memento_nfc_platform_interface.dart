import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'memento_nfc_method_channel.dart';
import 'memento_nfc.dart';

abstract class MementoNfcPlatform extends PlatformInterface {
  /// Constructs a MementoNfcPlatform.
  MementoNfcPlatform() : super(token: _token);

  static final Object _token = Object();

  static MementoNfcPlatform _instance = MethodChannelMementoNfc();

  /// The default instance of [MementoNfcPlatform] to use.
  ///
  /// Defaults to [MethodChannelMementoNfc].
  static MementoNfcPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [MementoNfcPlatform] when
  /// they register themselves.
  static set instance(MementoNfcPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  Future<bool> isNfcSupported() {
    throw UnimplementedError('isNfcSupported() has not been implemented.');
  }

  Future<bool> isNfcEnabled() {
    throw UnimplementedError('isNfcEnabled() has not been implemented.');
  }

  Future<NfcReadResult> readNfc() {
    throw UnimplementedError('readNfc() has not been implemented.');
  }

  Future<NfcWriteResult> writeNfc(String data, {String formatType = 'NDEF'}) {
    throw UnimplementedError('writeNfc() has not been implemented.');
  }

  Future<NfcWriteResult> writeNdefUrl(String url) {
    throw UnimplementedError('writeNdefUrl() has not been implemented.');
  }

  Future<NfcWriteResult> writeNdefText(String text) {
    throw UnimplementedError('writeNdefText() has not been implemented.');
  }
}
