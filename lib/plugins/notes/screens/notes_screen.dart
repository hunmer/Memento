import 'package:flutter/material.dart';
import '../controllers/notes_controller.dart';

class NotesScreen extends StatefulWidget {
  final NotesController controller;

  const NotesScreen({super.key, required this.controller});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // TODO: 实现添加笔记功能
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('添加笔记功能即将推出')),
              );
            },
          ),
        ],
      ),
      body: const Center(
        child: Text('笔记功能开发中...'),
      ),
    );
  }
}