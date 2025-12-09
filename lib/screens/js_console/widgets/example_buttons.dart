import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'package:provider/provider.dart';
import 'package:Memento/screens/js_console/controllers/js_console_controller.dart';
import '../../l10n/screens_localizations.dart';

class ExampleButtons extends StatelessWidget {
  const ExampleButtons({super.key});

  /// 判断是否为桌面平台
  bool get isDesktop {
    if (kIsWeb) return false;
    return Platform.isWindows || Platform.isMacOS || Platform.isLinux;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<JSConsoleController>(
      builder: (context, controller, _) {
        // 如果示例未加载，显示加载提示
        if (!controller.examplesLoaded) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            color: Colors.grey[200],
            child: Center(
              child: Text(
                'screens_loadingExamples'.tr,
                style: const TextStyle(fontSize: 12),
              ),
            ),
          );
        }

        // 如果没有示例，显示提示
        if (controller.examples.isEmpty) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            color: Colors.grey[200],
            child: Center(
              child: Text(
                'screens_noAvailableExamples'.tr,
                style: TextStyle(fontSize: 12),
              ),
            ),
          );
        }

        // 获取当前要显示的示例
        final currentExamples = controller.currentFileExamples;

        // 显示示例按钮
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          color: Colors.grey[200],
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 文件选择下拉框
              if (controller.exampleFiles.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Text(
                        'screens_selectExampleFile'.tr,
                        style: TextStyle(fontSize: 12),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButton<String>(
                          value: controller.selectedFilePath,
                          isExpanded: true,
                          hint: Text(
                            'screens_allExamples'.tr,
                            style: TextStyle(fontSize: 12),
                          ),
                          items: [
                            // "全部" 选项
                            DropdownMenuItem<String>(
                              value: null,
                              child: Text('screens_allExamples'.tr, style: TextStyle(fontSize: 12)),
                            ),
                            // 各个文件选项
                            ...controller.exampleFiles.map((file) {
                              return DropdownMenuItem<String>(
                                value: file.path,
                                child: Text(file.name, style: const TextStyle(fontSize: 12)),
                              );
                            }),
                          ],
                          onChanged: (value) => controller.selectFile(value),
                        ),
                      ),
                    ],
                  ),
                ),

              // 示例按钮列表（带滚动条）
              SizedBox(
                height: 40,
                child: _buildButtonList(context, controller, currentExamples),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 构建按钮列表（根据平台决定是否显示滚动条）
  Widget _buildButtonList(
    BuildContext context,
    JSConsoleController controller,
    Map<String, String> examples,
  ) {
    final scrollController = ScrollController();

    final buttonRow = SingleChildScrollView(
      controller: scrollController,
      scrollDirection: Axis.horizontal,
      child: Row(
        children: examples.keys.map((key) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: OutlinedButton.icon(
              onPressed: () => controller.loadExample(key),
              icon: const Icon(Icons.code, size: 16),
              label: Text(key),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );

    // 桌面端显示滚动条
    if (isDesktop) {
      return Scrollbar(
        controller: scrollController,
        thumbVisibility: true, // 始终显示滚动条
        child: buttonRow,
      );
    }

    // 移动端不显示滚动条
    return buttonRow;
  }
}
