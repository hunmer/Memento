import 'package:flutter/material.dart';
import 'package:Memento/screens/widgets_gallery/common_widgets/common_widgets.dart';
import 'package:Memento/screens/widgets_gallery/common_widgets/models/colorful_shortcuts_grid_data.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';

/// 彩色快捷方式网格示例
class ColorfulShortcutsGridExample extends StatelessWidget {
  const ColorfulShortcutsGridExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('彩色快捷方式网格')),
      body: Container(
        color: isDark ? Colors.black : const Color(0xFFF2F2F7),
        child: Center(
          child: CommonWidgetBuilder.build(
            context,
            CommonWidgetId.colorfulShortcutsGrid,
            ColorfulShortcutsGridData(
              columns: 2,
              itemHeight: 100,
              spacing: 14,
              borderRadius: 40,
              shortcuts: [
                ShortcutItemData(
                  iconName: 'event_available',
                  label: 'Block Off an Hour',
                  color: 0xFFFF5E63,
                ),
                ShortcutItemData(
                  iconName: 'collections',
                  label: 'Make GIF',
                  color: 0xFFFFB74D,
                ),
                ShortcutItemData(
                  iconName: 'note_add',
                  label: 'New Note with Date',
                  color: 0xFFEBCB0E,
                ),
                ShortcutItemData(
                  iconName: 'add_comment',
                  label: 'Text Last Image',
                  color: 0xFF4CD964,
                ),
                ShortcutItemData(
                  iconName: 'chat_bubble',
                  label: 'Text Running Late',
                  color: 0xFF00C7BE,
                ),
                ShortcutItemData(
                  iconName: 'mail',
                  label: 'Email Running Late',
                  color: 0xFF00D1F3,
                ),
                ShortcutItemData(
                  iconName: 'send',
                  label: 'Email Last Image',
                  color: 0xFF00B0FF,
                  iconTransform: _createSendIconTransform(),
                ),
              ],
            ).toJson(),
            HomeWidgetSize.large,
          ),
        ),
      ),
    );
  }

  static List<double> _createSendIconTransform() {
    // 创建旋转 -45 度的变换矩阵
    final matrix = Matrix4.rotationZ(-0.785);
    matrix.translate(0.05, 0.05);
    return matrix.storage;
  }
}
