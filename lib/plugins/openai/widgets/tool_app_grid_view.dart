import 'package:flutter/material.dart';
import '../models/tool_app.dart';
import 'tool_app_card.dart';
import '../controllers/tool_app_controller.dart';
import '../../l10n/openai_localizations.dart';

class ToolAppGridView extends StatelessWidget {
  final List<ToolApp> apps;
  final ToolAppController? controller;

  const ToolAppGridView({super.key, required this.apps, this.controller});

  @override
  Widget build(BuildContext context) {
    if (apps.isEmpty) {
      return Center(
        child: Text(OpenAILocalizations.of(context).noToolsAvailable),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: apps.length,
      itemBuilder: (context, index) {
        final app = apps[index];
        return ToolAppCard(
          app: app,
          onTap: () {
            if (controller != null) {
              controller!.handleAppClick(context, app.id);
            } else {
              // 如果没有提供控制器，创建一个临时的来处理点击
              final tempController = ToolAppController();
              tempController.handleAppClick(context, app.id);
            }
          },
        );
      },
    );
  }
}
