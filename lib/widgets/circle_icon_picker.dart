import 'package:Memento/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'icon_picker_dialog.dart';

class CircleIconPicker extends StatelessWidget {
  final IconData currentIcon;
  final Color backgroundColor;
  final Function(IconData) onIconSelected;
  final Function(Color) onColorSelected;

  const CircleIconPicker({
    super.key,
    required this.currentIcon,
    required this.backgroundColor,
    required this.onIconSelected,
    required this.onColorSelected,
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
        child: Stack(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: backgroundColor,
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                  width: 2,
                ),
              ),
              child: Icon(currentIcon, size: 32, color: Colors.white),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: GestureDetector(
                onTap: () async {
                  final Color? color = await showDialog<Color>(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text(
                          AppLocalizations.of(context)!.selectBackgroundColor,
                        ),
                        content: SingleChildScrollView(
                          child: ColorPicker(
                            pickerColor: backgroundColor,
                            onColorChanged: onColorSelected,
                            showLabel: true,
                            pickerAreaHeightPercent: 0.8,
                          ),
                        ),
                        actions: <Widget>[
                          TextButton(
                            child: Text(AppLocalizations.of(context)!.ok),
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                          ),
                        ],
                      );
                    },
                  );
                  if (color != null) {
                    onColorSelected(color);
                  }
                },
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(color: Colors.grey),
                  ),
                  child: const Icon(Icons.color_lens, size: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
