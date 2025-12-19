import 'package:flutter/material.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/plugins/calendar_album/controllers/tag_controller.dart';
import 'entry_editor_controller.dart';
class EntryEditorTagHandler extends StatefulWidget {
  final EntryEditorController controller;

  const EntryEditorTagHandler({
    super.key,
    required this.controller,
  });

  @override
  State<EntryEditorTagHandler> createState() => _EntryEditorTagHandlerState();
}

class _EntryEditorTagHandlerState extends State<EntryEditorTagHandler> {
  late final TagController tagController;

  final List<({Color bg, Color text, Color border})> _colorStyles = [
    (bg: Colors.blue.shade50, text: Colors.blue.shade700, border: Colors.blue.shade100),
    (bg: Colors.purple.shade50, text: Colors.purple.shade700, border: Colors.purple.shade100),
    (bg: Colors.orange.shade50, text: Colors.orange.shade800, border: Colors.orange.shade100),
    (bg: Colors.green.shade50, text: Colors.green.shade800, border: Colors.green.shade100),
    (bg: Colors.pink.shade50, text: Colors.pink.shade700, border: Colors.pink.shade100),
  ];

  @override
  void initState() {
    super.initState();
    final plugin = PluginManager.instance.getPlugin('calendar_album');
    tagController = (plugin as dynamic).tagController;
    if (widget.controller.selectedTags.isEmpty && widget.controller.entry != null) {
      widget.controller.selectedTags = List.from(widget.controller.entry!.tags);
    }
  }

  Widget _buildTagChip(String tag, int index) {
    final style = _colorStyles[index % _colorStyles.length];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: style.bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: style.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '#$tag',
            style: TextStyle(
              color: style.text,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () {
              setState(() {
                widget.controller.selectedTags.remove(tag);
              });
            },
            child: Icon(
              Icons.close,
              size: 14,
              color: style.text.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddTagButton() {
    return GestureDetector(
      onTap: () async {
        final result = await tagController.showTagManagerDialog(context);
        if (result != null && mounted) {
          setState(() {
            widget.controller.selectedTags = List.from(result);
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid), // Simulating dashed with solid light grey for simplicity, or use CustomPaint if strict. The previous image handler used standard border, so consistent here.
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add, size: 16, color: Colors.grey.shade600),
            const SizedBox(width: 4),
            Text(
              'Add Tag',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'TAGS',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade500,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...widget.controller.selectedTags.asMap().entries.map((entry) {
              return _buildTagChip(entry.value, entry.key);
            }),
            _buildAddTagButton(),
          ],
        ),
      ],
    );
  }
}
