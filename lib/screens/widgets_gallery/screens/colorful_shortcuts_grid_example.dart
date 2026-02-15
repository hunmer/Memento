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
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('小尺寸'),
                const SizedBox(height: 8),
                Center(
                  child: SizedBox(
                    width: 150,
                    height: 150,
                    child: CommonWidgetBuilder.build(
                      context,
                      CommonWidgetId.colorfulShortcutsGrid,
                      ColorfulShortcutsGridData(
                        columns: 2,
                        itemHeight: 50,
                        spacing: 8,
                        borderRadius: 20,
                        shortcuts: const [
                          ShortcutItemData(
                            iconName: 'event_available',
                            label: 'Block',
                            color: 0xFFFF5E63,
                          ),
                          ShortcutItemData(
                            iconName: 'collections',
                            label: 'GIF',
                            color: 0xFFFFB74D,
                          ),
                        ],
                      ).toJson(),
                      const SmallSize(),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('中尺寸'),
                const SizedBox(height: 8),
                Center(
                  child: SizedBox(
                    width: 220,
                    height: 200,
                    child: CommonWidgetBuilder.build(
                      context,
                      CommonWidgetId.colorfulShortcutsGrid,
                      ColorfulShortcutsGridData(
                        columns: 2,
                        itemHeight: 70,
                        spacing: 10,
                        borderRadius: 30,
                        shortcuts: const [
                          ShortcutItemData(
                            iconName: 'event_available',
                            label: 'Block Off',
                            color: 0xFFFF5E63,
                          ),
                          ShortcutItemData(
                            iconName: 'collections',
                            label: 'Make GIF',
                            color: 0xFFFFB74D,
                          ),
                          ShortcutItemData(
                            iconName: 'note_add',
                            label: 'New Note',
                            color: 0xFFEBCB0E,
                          ),
                          ShortcutItemData(
                            iconName: 'add_comment',
                            label: 'Text Image',
                            color: 0xFF4CD964,
                          ),
                        ],
                      ).toJson(),
                      const MediumSize(),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('大尺寸'),
                const SizedBox(height: 8),
                Center(
                  child: SizedBox(
                    width: 300,
                    height: 280,
                    child: CommonWidgetBuilder.build(
                      context,
                      CommonWidgetId.colorfulShortcutsGrid,
                      ColorfulShortcutsGridData(
                        columns: 2,
                        itemHeight: 100,
                        spacing: 14,
                        borderRadius: 40,
                        shortcuts: const [
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
                        ],
                      ).toJson(),
                      const LargeSize(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.grey,
      ),
    );
  }
}
