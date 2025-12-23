import 'package:get/get.dart';
import 'package:flutter/material.dart';

class AddTagDialog extends StatefulWidget {
  const AddTagDialog({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _AddTagDialogState createState() => _AddTagDialogState();
}

class _AddTagDialogState extends State<AddTagDialog> {
  final _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      backgroundColor: theme.colorScheme.surface,
      title: Text(
        'goods_addTag'.tr,
        style: TextStyle(color: theme.colorScheme.onSurface),
      ),
      content: TextField(
        controller: _controller,
        decoration: InputDecoration(
          labelText: 'goods_tagName'.tr,
          hintText: 'goods_tagNameHint'.tr,
        ),
      ),
      actions: [
        TextButton(
          child: Text('app_cancel'.tr),
          onPressed: () => Navigator.of(context).pop(),
        ),
        TextButton(
          child: Text('app_ok'.tr),
          onPressed: () {
            if (_controller.text.isNotEmpty) {
              Navigator.of(context).pop(_controller.text);
            }
          },
        ),
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
