import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:Memento/widgets/picker/location_picker.dart';
import 'package:smooth_sheets/smooth_sheets.dart';
import 'package:Memento/widgets/smooth_bottom_sheet.dart';
import 'package:Memento/widgets/form_fields/chip_selector_field.dart';
import 'entry_editor_controller.dart';
import 'entry_editor_image_handler.dart';
import 'entry_editor_tag_handler.dart';

class EntryEditorUI extends StatefulWidget {
  final EntryEditorController controller;
  final bool isEditing;
  final BuildContext parentContext;

  const EntryEditorUI({
    super.key,
    required this.controller,
    required this.isEditing,
    required this.parentContext,
  });

  @override
  State<EntryEditorUI> createState() => _EntryEditorUIState();
}

class _EntryEditorUIState extends State<EntryEditorUI> {
  late EntryEditorController controller;
  late bool isEditing;

  @override
  void initState() {
    super.initState();
    controller = widget.controller;
    isEditing = widget.isEditing;
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    EntryEditorImageHandler(
                      imageUrls: controller.imageUrls,
                      thumbUrls: controller.thumbUrls,
                      onImageAdded: (url, thumbUrl) {
                        controller.imageUrls.add(url);
                        controller.thumbUrls.add(thumbUrl ?? '');
                      },
                      onImageRemoved: (index) {
                        controller.imageUrls.removeAt(index);
                        if (index < controller.thumbUrls.length) {
                          controller.thumbUrls.removeAt(index);
                        }
                      },
                    ),
                    const SizedBox(height: 20),
                    _buildContentForm(),
                    const SizedBox(height: 20),
                    EntryEditorTagHandler(controller: controller),
                    const SizedBox(height: 20),
                    _buildMetadataForm(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Text(
              'calendar_album_cancel'.tr,
              style: const TextStyle(
                color: Colors.blue,
                fontSize: 17,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          Text(
            isEditing ? 'calendar_album_edit_post'.tr : 'calendar_album_new_post'.tr,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          GestureDetector(
            onTap: () async {
              final result = controller.saveEntry(context);
              if (result != null && mounted) {
                Navigator.of(context).pop();
              }
            },
            child: Text(
              'calendar_album_save'.tr,
              style: const TextStyle(
                color: Colors.blue,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建内容表单（标题、内容、心情）
  Widget _buildContentForm() {
    // 准备心情选项
    final moods = ['Happy', 'Sad', 'Excited', 'Tired', 'Calm', 'Anxious', 'Angry', 'Content'];
    final moodOptions = moods.map((m) => ChipOption(
      id: m,
      label: 'calendar_album_mood_${m.toLowerCase()}'.tr,
    )).toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          // 心情选择 + 标题输入行
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                // 心情选择器
                ChipSelectorField(
                  options: moodOptions,
                  selectedId: controller.mood,
                  hintText: 'calendar_album_mood'.tr,
                  selectorTitle: 'calendar_album_select_mood'.tr,
                  icon: Icons.sentiment_satisfied,
                  onValueChanged: (value) {
                    setState(() {
                      controller.mood = value;
                    });
                  },
                ),
                const SizedBox(width: 12),
                // 标题输入框
                Expanded(
                  child: TextField(
                    controller: controller.titleController,
                    decoration: InputDecoration(
                      hintText: 'calendar_album_title'.tr,
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      hintStyle: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w600),
                    ),
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey.shade100),
          // 内容输入
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: controller.contentController,
              decoration: InputDecoration(
                hintText: 'calendar_album_whats_on_mind'.tr,
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              maxLines: null,
              minLines: 8,
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建元数据表单（位置、天气）
  Widget _buildMetadataForm() {
    // 准备天气选项
    final weathers = ['Sunny', 'Cloudy', 'Rainy', 'Snowy', 'Windy', 'Foggy', 'Stormy', 'Clear'];
    final weatherOptions = weathers.map((w) => ChipOption(
      id: w,
      label: 'calendar_album_weather_${w.toLowerCase()}'.tr,
    )).toList();

    return Row(
      children: [
        // 位置选择器
        Expanded(
          child: _buildMetadataCard(
            icon: Icons.location_on,
            iconColor: Colors.red.shade500,
            iconBg: Colors.red.shade50,
            label: 'calendar_album_location'.tr.toUpperCase(),
            value: controller.locationController.text.isNotEmpty
                ? controller.locationController.text
                : 'calendar_album_add_location'.tr,
            onTap: () => _handleLocationSelection(widget.parentContext),
          ),
        ),
        const SizedBox(width: 12),
        // 天气选择器
        Expanded(
          child: _buildMetadataCard(
            icon: Icons.sunny,
            iconColor: Colors.blue.shade500,
            iconBg: Colors.blue.shade50,
            label: 'calendar_album_weather'.tr.toUpperCase(),
            value: controller.weather != null
                ? 'calendar_album_weather_${controller.weather!.toLowerCase()}'.tr
                : 'calendar_album_add_weather'.tr,
            onTap: () => _showWeatherPicker(weatherOptions),
          ),
        ),
      ],
    );
  }

  /// 构建元数据卡片
  Widget _buildMetadataCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade400,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 处理位置选择
  Future<void> _handleLocationSelection(BuildContext dialogContext) async {
    final isMobile =
        !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);

    await Navigator.of(dialogContext).push(
      ModalSheetRoute(
        swipeDismissible: true,
        builder: (context) => Sheet(
          decoration: const MaterialSheetDecoration(
            size: SheetSize.fit,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: LocationPicker(
            onLocationSelected: (location) {
              if (mounted) {
                setState(() {
                  controller.locationController.text = location;
                });
              }
            },
            isMobile: isMobile,
          ),
        ),
      ),
    );
  }

  /// 显示天气选择器
  void _showWeatherPicker(List<ChipOption> weatherOptions) {
    SmoothBottomSheet.show(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('calendar_album_select_weather'.tr, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: weatherOptions.map((opt) => ActionChip(
                label: Text(opt.label),
                backgroundColor: controller.weather == opt.id ? Colors.blue.shade100 : null,
                onPressed: () {
                  setState(() {
                    controller.weather = opt.id;
                  });
                  Navigator.pop(context);
                },
              )).toList(),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
