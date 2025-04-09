import 'package:flutter/material.dart';
import '../../l10n/day_localizations.dart';
import 'color_picker.dart';

class AppearanceTab extends StatelessWidget {
  final Color selectedColor;
  final Function(Color) onColorSelected;
  final String? backgroundImageUrl;
  final Function(String?) onBackgroundImageSelected;
  final List<String> predefinedBackgroundImages;

  const AppearanceTab({
    Key? key,
    required this.selectedColor,
    required this.onColorSelected,
    required this.backgroundImageUrl,
    required this.onBackgroundImageSelected,
    required this.predefinedBackgroundImages,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final localizations = DayLocalizations.of(context);
    final scrollController = ScrollController();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            localizations.backgroundColor,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          ColorPicker(
            selectedColor: selectedColor,
            onColorSelected: onColorSelected,
          ),
          const SizedBox(height: 24),
          Text(
            localizations.backgroundImage,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: Scrollbar(
              controller: scrollController,
              thumbVisibility: true,
              child: ListView(
                controller: scrollController,
                scrollDirection: Axis.horizontal,
                children: [
                  // 清除背景图片选项
                  GestureDetector(
                    onTap: () => onBackgroundImageSelected(null),
                    child: Container(
                      width: 120,
                      height: 120,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: backgroundImageUrl == null
                              ? Theme.of(context).primaryColor
                              : Colors.grey,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Icon(Icons.clear),
                      ),
                    ),
                  ),
                  ...predefinedBackgroundImages.map((imageUrl) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => onBackgroundImageSelected(imageUrl),
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: backgroundImageUrl == imageUrl
                                    ? Theme.of(context).primaryColor
                                    : Colors.grey,
                              ),
                              borderRadius: BorderRadius.circular(8),
                              image: DecorationImage(
                                image: NetworkImage(imageUrl),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      )),
                ],
              ),
            ),
          ),
          // TODO: 实现图片上传功能
        ],
      ),
    );
  }
}