import 'package:Memento/plugins/openai/l10n/openai_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/tool_app_controller.dart';
import '../models/tool_app.dart';

class ToolAppGrid extends StatelessWidget {
  const ToolAppGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ToolAppController>(
      builder: (context, controller, child) {
        if (controller.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.apps.isEmpty) {
          return Center(
            child: Text(OpenAILocalizations.of(context).noToolsAvailable),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 1.5,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: controller.apps.length,
          itemBuilder: (context, index) {
            final app = controller.apps[index];
            return _buildAppCard(context, app, controller);
          },
        );
      },
    );
  }

  Widget _buildAppCard(
    BuildContext context,
    ToolApp app,
    ToolAppController controller,
  ) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () => controller.handleAppClick(context, app.id),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _getIconForApp(app.id),
                size: 36,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(height: 8),
              Text(
                app.title,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                app.description,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIconForApp(String appId) {
    switch (appId) {
      case 'plugin-analysis':
        return Icons.analytics;
      default:
        return Icons.apps;
    }
  }
}
