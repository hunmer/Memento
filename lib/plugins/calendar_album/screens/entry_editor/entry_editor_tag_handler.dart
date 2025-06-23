import 'package:flutter/material.dart';
import '../../../../core/plugin_manager.dart';
import '../../controllers/tag_controller.dart';
import '../../l10n/calendar_album_localizations.dart';
import 'entry_editor_controller.dart';

class EntryEditorTagHandler extends StatelessWidget {
  final EntryEditorController controller;
  final CalendarAlbumLocalizations l10n;
  late final TagController tagController;

  EntryEditorTagHandler({
    super.key,
    required this.controller,
    required this.l10n,
  }) {
    final plugin = PluginManager.instance.getPlugin('calendar_album');
    tagController = (plugin as dynamic).tagController;
    if (controller.selectedTags.isEmpty && controller.entry != null) {
      controller.selectedTags = List.from(controller.entry!.tags);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          decoration: InputDecoration(
            labelText: l10n.get('tags'),
            hintText: l10n.get('tagsHint'),
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              icon: const Icon(Icons.label),
              onPressed: () async {
                final result = await tagController.showTagManagerDialog(
                  context,
                );
                if (result != null && context.mounted) {
                  controller.selectedTags = List.from(result);
                  (context as Element).markNeedsBuild();
                }
              },
              tooltip: l10n.get('tagManagement'),
            ),
          ),
          readOnly: true,
          controller: TextEditingController(
            text: controller.selectedTags.join(', '),
          ),
        ),
        if (tagController.recentTags.isNotEmpty) ...[
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.only(left: 4.0, bottom: 4.0),
            child: Text(
              '最近使用的标签',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                tagController.recentTags.map((tag) {
                  final isSelected = controller.selectedTags.any(
                    (t) => t == tag,
                  );
                  return GestureDetector(
                    onTap: () {
                      if (isSelected) {
                        controller.selectedTags.removeWhere((t) => t == tag);
                      } else {
                        controller.selectedTags.add(tag);
                      }
                      if (context.mounted) {
                        (context as Element).markNeedsBuild();
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color:
                            isSelected
                                ? Theme.of(context).primaryColor.withAlpha(50)
                                : Colors.grey.withAlpha(30),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color:
                              isSelected
                                  ? Theme.of(context).primaryColor
                                  : Colors.transparent,
                        ),
                      ),
                      child: Text(
                        tag,
                        style: TextStyle(
                          color:
                              isSelected
                                  ? Theme.of(context).primaryColor
                                  : Colors.grey[700],
                        ),
                      ),
                    ),
                  );
                }).toList(),
          ),
        ],
      ],
    );
  }
}
