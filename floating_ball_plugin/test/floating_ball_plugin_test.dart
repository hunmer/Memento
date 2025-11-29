import 'package:flutter_test/flutter_test.dart';
import 'package:floating_ball_plugin/floating_ball_plugin.dart';
import 'package:floating_ball_plugin/floating_ball_plugin_platform_interface.dart';
import 'package:floating_ball_plugin/floating_ball_plugin_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockFloatingBallPluginPlatform
    with MockPlatformInterfaceMixin
    implements FloatingBallPluginPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final FloatingBallPluginPlatform initialPlatform = FloatingBallPluginPlatform.instance;

  test('$MethodChannelFloatingBallPlugin is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelFloatingBallPlugin>());
  });

  test('getPlatformVersion', () async {
    FloatingBallPlugin floatingBallPlugin = FloatingBallPlugin();
    MockFloatingBallPluginPlatform fakePlatform = MockFloatingBallPluginPlatform();
    FloatingBallPluginPlatform.instance = fakePlatform;

    expect(await floatingBallPlugin.getPlatformVersion(), '42');
  });
}
