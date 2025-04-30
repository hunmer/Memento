import 'package:flutter/material.dart';
import '../models/tool_app.dart';
import 'tool_app_card.dart';

class ToolAppGridView extends StatelessWidget {
  final List<ToolApp> apps;
  final Function(ToolApp)? onAppSelected;

  const ToolAppGridView({
    Key? key,
    required this.apps,
    this.onAppSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (apps.isEmpty) {
      return const Center(
        child: Text('No tools available'),
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
          onTap: () => onAppSelected?.call(app),
        );
      },
    );
  }
}