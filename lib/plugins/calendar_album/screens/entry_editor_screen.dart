import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/plugins/calendar_album/models/calendar_entry.dart';
import 'entry_editor/entry_editor_controller.dart';
import 'entry_editor/entry_editor_ui.dart';

class EntryEditorScreen extends StatefulWidget {
  final CalendarEntry? entry;
  final DateTime? initialDate;
  final bool isEditing;

  const EntryEditorScreen({
    super.key,
    this.entry,
    this.initialDate,
    required this.isEditing,
  });

  @override
  State<EntryEditorScreen> createState() => _EntryEditorScreenState();
}

class _EntryEditorScreenState extends State<EntryEditorScreen> {
  late EntryEditorController _controller;

  @override
  void initState() {
    super.initState();
    _controller = EntryEditorController(
      entry: widget.entry,
      isEditing: widget.isEditing,
      initialDate: widget.initialDate,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return EntryEditorUI(
      controller: _controller,
      isEditing: widget.isEditing,
      parentContext: context,
    );
  }
}
