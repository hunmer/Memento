import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import 'package:Memento/widgets/location_picker.dart';
import 'package:smooth_sheets/smooth_sheets.dart';
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
    // Ensure location controller listener updates UI
    controller.locationController.addListener(_onLocationChanged);
  }

  @override
  void dispose() {
    controller.locationController.removeListener(_onLocationChanged);
    super.dispose();
  }

  void _onLocationChanged() {
    if (mounted) setState(() {});
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
                    _buildContentCard(),
                    const SizedBox(height: 20),
                    EntryEditorTagHandler(controller: controller),
                    const SizedBox(height: 20),
                    _buildMetadataGrid(),
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
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: Colors.blue,
                fontSize: 17,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          Text(
            isEditing ? 'Edit Post' : 'New Post',
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
            child: const Text(
              'Save',
              style: TextStyle(
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

  Widget _buildContentCard() {
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                _buildMoodButton(),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: controller.titleController,
                    decoration: const InputDecoration(
                      hintText: 'Title',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      hintStyle: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600),
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
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: controller.contentController,
              decoration: const InputDecoration(
                hintText: "What's on your mind?",
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

  Widget _buildMoodButton() {
    final mood = controller.mood ?? 'Happy';
    return GestureDetector(
      onTap: _showMoodPicker,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.sentiment_satisfied, size: 20, color: Colors.orange.shade600),
            const SizedBox(width: 8),
            Text(
              mood,
              style: TextStyle(
                color: Colors.orange.shade600,
                fontWeight: FontWeight.w500,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMoodPicker() {
    final moods = ['Happy', 'Sad', 'Excited', 'Tired', 'Calm', 'Anxious', 'Angry', 'Content'];
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
             const Text('Select Mood', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
             const SizedBox(height: 16),
             Wrap(
               spacing: 8,
               runSpacing: 8,
               children: moods.map((m) => ActionChip(
                 label: Text(m),
                 backgroundColor: controller.mood == m ? Colors.orange.shade100 : null,
                 onPressed: () {
                   setState(() {
                     controller.mood = m;
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

  Widget _buildMetadataGrid() {
    return Row(
      children: [
        Expanded(child: _buildMetadataCard(
          icon: Icons.location_on,
          iconColor: Colors.red.shade500,
          iconBg: Colors.red.shade50,
          label: 'LOCATION',
          value: controller.locationController.text.isNotEmpty 
              ? controller.locationController.text 
              : 'Add Location',
          onTap: () => _handleLocationSelection(widget.parentContext),
        )),
        const SizedBox(width: 12),
        Expanded(child: _buildMetadataCard(
          icon: Icons.sunny,
          iconColor: Colors.blue.shade500,
          iconBg: Colors.blue.shade50,
          label: 'WEATHER',
          value: controller.weather ?? 'Add Weather',
          onTap: _showWeatherPicker,
        )),
      ],
    );
  }

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

  Future<void> _handleLocationSelection(BuildContext dialogContext) async {
    final isMobile =
        !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);

    await Navigator.of(dialogContext).push(
      ModalSheetRoute(
        swipeDismissible: true,
        builder:
            (context) => Sheet(
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

  void _showWeatherPicker() {
     final weathers = ['Sunny', 'Cloudy', 'Rainy', 'Snowy', 'Windy', 'Foggy', 'Stormy', 'Clear'];
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
             const Text('Select Weather', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
             const SizedBox(height: 16),
             Wrap(
               spacing: 8,
               runSpacing: 8,
               children: weathers.map((w) => ActionChip(
                 label: Text(w),
                 backgroundColor: controller.weather == w ? Colors.blue.shade100 : null,
                 onPressed: () {
                   setState(() {
                     controller.weather = w;
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
