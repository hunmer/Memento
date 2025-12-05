import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'memento_intent_platform_interface.dart';
import 'memento_intent.dart';

/// An implementation of [MementoIntentPlatform] that uses method channels.
class MethodChannelMementoIntent extends MementoIntentPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('memento_intent');

  // Event channels for streaming data
  static const String _deepLinkEventChannel = 'memento_intent/deep_link/events';
  static const String _sharedTextEventChannel = 'memento_intent/shared_text/events';
  static const String _sharedFilesEventChannel = 'memento_intent/shared_files/events';
  static const String _intentDataEventChannel = 'memento_intent/intent_data/events';

  // Event channel handlers
  late final Stream<Uri> _onDeepLink;
  late final Stream<String> _onSharedText;
  late final Stream<List<SharedMediaFile>> _onSharedFiles;
  late final Stream<IntentData> _onIntentData;

  MethodChannelMementoIntent() {
    _setupEventStreams();
  }

  void _setupEventStreams() {
    // Setup deep link stream
    _onDeepLink = EventChannel(_deepLinkEventChannel)
        .receiveBroadcastStream()
        .map((data) => Uri.parse(data.toString()));

    // Setup shared text stream
    _onSharedText = EventChannel(_sharedTextEventChannel)
        .receiveBroadcastStream()
        .map((data) => data.toString());

    // Setup shared files stream
    _onSharedFiles = EventChannel(_sharedFilesEventChannel)
        .receiveBroadcastStream()
        .map((data) {
      if (data is List) {
        return data.map((item) => SharedMediaFile.fromJson(
          Map<String, dynamic>.from(item as Map),
        )).toList();
      }
      return <SharedMediaFile>[];
    });

    // Setup intent data stream
    _onIntentData = EventChannel(_intentDataEventChannel)
        .receiveBroadcastStream()
        .map((data) => IntentData.fromJson(
          Map<String, dynamic>.from(data as Map),
        ));
  }

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }

  @override
  Stream<Uri> get onDeepLink => _onDeepLink;

  @override
  Stream<String> get onSharedText => _onSharedText;

  @override
  Stream<List<SharedMediaFile>> get onSharedFiles => _onSharedFiles;

  @override
  Stream<IntentData> get onIntentData => _onIntentData;

  @override
  Future<bool> registerDynamicScheme({
    required String scheme,
    String? host,
    String? pathPrefix,
  }) async {
    try {
      final result = await methodChannel.invokeMethod<bool>(
        'registerDynamicScheme',
        {
          'scheme': scheme,
          'host': host,
          'pathPrefix': pathPrefix,
        },
      );
      return result ?? false;
    } catch (e) {
      debugPrint('Error registering dynamic scheme: $e');
      return false;
    }
  }

  @override
  Future<bool> unregisterDynamicScheme() async {
    try {
      final result = await methodChannel.invokeMethod<bool>('unregisterDynamicScheme');
      return result ?? false;
    } catch (e) {
      debugPrint('Error unregistering dynamic scheme: $e');
      return false;
    }
  }

  @override
  Future<List<String>> getDynamicSchemes() async {
    try {
      final result = await methodChannel.invokeMethod<List<dynamic>>('getDynamicSchemes');
      return result?.cast<String>() ?? <String>[];
    } catch (e) {
      debugPrint('Error getting dynamic schemes: $e');
      return <String>[];
    }
  }
}
