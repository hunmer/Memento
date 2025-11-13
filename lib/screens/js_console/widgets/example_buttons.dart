import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/js_console_controller.dart';

class ExampleButtons extends StatelessWidget {
  const ExampleButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: Colors.grey[200],
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: JSConsoleController.examples.keys.map((key) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Consumer<JSConsoleController>(
                builder: (context, controller, _) {
                  return OutlinedButton.icon(
                    onPressed: () => controller.loadExample(key),
                    icon: const Icon(Icons.code, size: 16),
                    label: Text(key),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                    ),
                  );
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
