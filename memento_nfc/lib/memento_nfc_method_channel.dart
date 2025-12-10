import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'memento_nfc_platform_interface.dart';
import 'memento_nfc.dart';

/// An implementation of [MementoNfcPlatform] that uses method channels.
class MethodChannelMementoNfc extends MementoNfcPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('memento_nfc');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }

  @override
  Future<bool> isNfcSupported() async {
    final result = await methodChannel.invokeMethod<bool>('isNfcSupported');
    return result ?? false;
  }

  @override
  Future<bool> isNfcEnabled() async {
    final result = await methodChannel.invokeMethod<bool>('isNfcEnabled');
    return result ?? false;
  }

  @override
  Future<NfcReadResult> readNfc() async {
    final result = await methodChannel.invokeMapMethod<String, dynamic>('readNfc');
    if (result == null) {
      return NfcReadResult(success: false, error: 'Unknown error');
    }
    return NfcReadResult.fromMap(result);
  }

  @override
  Future<NfcWriteResult> writeNfc(String data, {String formatType = 'TEXT'}) async {
    final result = await methodChannel.invokeMapMethod<String, dynamic>(
      'writeNfc',
      {'data': data, 'formatType': formatType},
    );
    if (result == null) {
      return NfcWriteResult(success: false, error: 'Unknown error');
    }
    return NfcWriteResult.fromMap(result);
  }

  @override
  Future<NfcWriteResult> writeNfcRecords(List<Map<String, String>> records) async {
    final result = await methodChannel.invokeMapMethod<String, dynamic>(
      'writeNfcRecords',
      {'records': records},
    );
    if (result == null) {
      return NfcWriteResult(success: false, error: 'Unknown error');
    }
    return NfcWriteResult.fromMap(result);
  }

  @override
  Future<NfcWriteResult> writeNdefUrl(String url) async {
    final result = await methodChannel.invokeMapMethod<String, dynamic>(
      'writeNdefUrl',
      {'url': url},
    );
    if (result == null) {
      return NfcWriteResult(success: false, error: 'Unknown error');
    }
    return NfcWriteResult.fromMap(result);
  }

  @override
  Future<NfcWriteResult> writeNdefText(String text) async {
    final result = await methodChannel.invokeMapMethod<String, dynamic>(
      'writeNdefText',
      {'text': text},
    );
    if (result == null) {
      return NfcWriteResult(success: false, error: 'Unknown error');
    }
    return NfcWriteResult.fromMap(result);
  }

  @override
  Future<bool> openNfcSettings() async {
    final result = await methodChannel.invokeMethod<bool>('openNfcSettings');
    return result ?? false;
  }
}
