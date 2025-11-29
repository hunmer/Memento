import 'package:flutter_test/flutter_test.dart';
import 'package:memento_widgets/memento_widgets.dart';
import 'package:memento_widgets/memento_widgets_platform_interface.dart';
import 'package:memento_widgets/memento_widgets_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockMementoWidgetsPlatform
    with MockPlatformInterfaceMixin
    implements MementoWidgetsPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final MementoWidgetsPlatform initialPlatform = MementoWidgetsPlatform.instance;

  test('$MethodChannelMementoWidgets is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelMementoWidgets>());
  });

  test('getPlatformVersion', () async {
    MementoWidgets mementoWidgetsPlugin = MementoWidgets();
    MockMementoWidgetsPlatform fakePlatform = MockMementoWidgetsPlatform();
    MementoWidgetsPlatform.instance = fakePlatform;

    expect(await mementoWidgetsPlugin.getPlatformVersion(), '42');
  });
}
