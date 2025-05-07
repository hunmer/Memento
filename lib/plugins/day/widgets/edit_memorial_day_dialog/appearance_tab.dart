import 'package:flutter/material.dart';
import '../../l10n/day_localizations.dart';
import 'color_picker.dart';
import '../../../../widgets/image_picker_dialog.dart';

class AppearanceTab extends StatelessWidget {
  final Color selectedColor;
  final Function(Color) onColorSelected;
  final String? backgroundImageUrl;
  final Function(String?) onBackgroundImageSelected;
  final List<String> predefinedBackgroundImages;

  const AppearanceTab({
    super.key,
    required this.selectedColor,
    required this.onColorSelected,
    required this.backgroundImageUrl,
    required this.onBackgroundImageSelected,
    required this.predefinedBackgroundImages,
  });

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
                          color:
                              backgroundImageUrl == null
                                  ? Theme.of(context).primaryColor
                                  : Colors.grey,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(child: Icon(Icons.clear)),
                    ),
                  ),
                  ...predefinedBackgroundImages.map(
                    (imageUrl) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => onBackgroundImageSelected(imageUrl),
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color:
                                  backgroundImageUrl == imageUrl
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
                    ),
                  ),
                  // 添加本地图片按钮
                  GestureDetector(
                    onTap: () async {
                      final result = await showDialog(
                        context: context,
                        builder: (context) => ImagePickerDialog(
                          initialUrl: backgroundImageUrl,
                          enableCrop: true,
                          cropAspectRatio: 1.0,
                          saveDirectory: 'day/backgrounds',
                        ),
                      );
                      
                      if (result != null && result is Map<String, dynamic>) {
                        final url = result['url'] as String;
                        onBackgroundImageSelected(url);
                      }
                    },
                    child: Container(
                      width: 120,
                      height: 120,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate, size: 32),
                          SizedBox(height: 8),
                          Text('本地图片', textAlign: TextAlign.center),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
