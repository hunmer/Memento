import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ColorPicker extends StatelessWidget {
  final Color selectedColor;
  final Function(Color) onColorSelected;

  const ColorPicker({
    super.key,
    required this.selectedColor,
    required this.onColorSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colors = [
      Colors.red[300]!,
      Colors.pink[300]!,
      Colors.purple[300]!,
      Colors.deepPurple[300]!,
      Colors.indigo[300]!,
      Colors.blue[300]!,
      Colors.lightBlue[300]!,
      Colors.cyan[300]!,
      Colors.teal[300]!,
      Colors.green[300]!,
      Colors.lightGreen[300]!,
      Colors.amber[300]!,
      Colors.orange[300]!,
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children:
          colors.map((color) {
            return GestureDetector(
              onTap: () => onColorSelected(color),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color:
                        selectedColor == color
                            ? Colors.white
                            : Colors.transparent,
                    width: 2,
                  ),
                  boxShadow: [
                    if (selectedColor == color)
                      BoxShadow(
                        color: Color.fromRGBO(
                          color.r.round(),
                          color.g.round(),
                          color.b.round(),
                          0.5,
                        ),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                  ],
                ),
              ),
            );
          }).toList(),
    );
  }
}
