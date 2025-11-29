// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:memento_widgets/memento_widgets.dart';

import 'package:memento_widgets_example/main.dart';

void main() {
  testWidgets('Verify widget test page loads', (WidgetTester tester) async {
    // 创建 manager 实例
    final manager = MyWidgetManager();

    // Build our app and trigger a frame.
    await tester.pumpWidget(MyApp(manager: manager));

    // Verify that the app bar title is correct.
    expect(find.text('小组件测试'), findsOneWidget);

    // Verify that status message is shown
    expect(find.text('准备就绪'), findsOneWidget);

    // Verify that buttons are present
    expect(find.text('更新文本小组件'), findsOneWidget);
    expect(find.text('更新图像小组件'), findsOneWidget);
  });
}

