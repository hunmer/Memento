import 'package:flutter/material.dart';
import 'icon_picker_dialog.dart';

class CircleIconPicker extends StatelessWidget {
  final IconData currentIcon;
  final Function(IconData) onIconSelected;

  const CircleIconPicker({
    super.key,
    required this.currentIcon,
    required this.onIconSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: () async {
          final IconData? result = await showIconPickerDialog(
            context,
            currentIcon,
          );
          if (result != null) {
            onIconSelected(result);
          }
        },
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            border: Border.all(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
              width: 2,
            ),
          ),
          child: Icon(
            currentIcon,
            size: 32,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }
}
