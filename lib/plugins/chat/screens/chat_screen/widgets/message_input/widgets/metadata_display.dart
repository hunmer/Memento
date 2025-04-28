import 'package:flutter/material.dart';
import 'dart:io' show Platform, Process;

class MetadataDisplay extends StatelessWidget {
  final Map<String, dynamic>? selectedFile;
  final List<Map<String, String>> selectedAgents;
  final Function() onShowAgentListDrawer;
  final Function() onFileRemove;
  final Function(String) onAgentRemove;

  const MetadataDisplay({
    super.key,
    this.selectedFile,
    required this.selectedAgents,
    required this.onShowAgentListDrawer,
    required this.onFileRemove,
    required this.onAgentRemove,
  });

  @override
  Widget build(BuildContext context) {
    if (selectedFile == null && selectedAgents.isEmpty) return const SizedBox();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          // 文件状态展示
          if (selectedFile != null)
            Expanded(
              flex: 1,
              child: Container(
                padding: EdgeInsets.zero,
                child: GestureDetector(
                  onTap: () async {
                    // 预览文件
                    if (selectedFile != null) {
                      final fileInfo =
                          selectedFile!['fileInfo'] as Map<String, dynamic>?;
                      if (fileInfo != null && fileInfo['path'] != null) {
                        final filePath = fileInfo['path'] as String;
                        if (Platform.isWindows) {
                          Process.run('explorer', [filePath]);
                        } else if (Platform.isMacOS) {
                          Process.run('open', [filePath]);
                        } else if (Platform.isLinux) {
                          Process.run('xdg-open', [filePath]);
                        }
                      }
                    }
                  },
                  child: Chip(
                    avatar: Icon(
                      (selectedFile!['fileInfo']?['type'] as String?) == 'image'
                          ? Icons.image
                          : Icons.insert_drive_file,
                      size: 18,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                    label: Text('1个文件'),
                    onDeleted: onFileRemove,
                    backgroundColor:
                        Theme.of(context).colorScheme.primaryContainer,
                    labelStyle: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                    deleteIconColor:
                        Theme.of(context).colorScheme.onPrimaryContainer,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                  ),
                ),
              ),
            ),
          // 如果两者都存在，添加一个间隔
          if (selectedFile != null && selectedAgents.isNotEmpty)
            const SizedBox(width: 8),

          // 智能体状态展示
          if (selectedAgents.isNotEmpty)
            Expanded(
              flex: 2,
              child: GestureDetector(
                onTap: onShowAgentListDrawer,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                      selectedAgents.map((agent) {
                        return Chip(
                          avatar: const Icon(Icons.smart_toy, size: 18),
                          label: Text(agent['name'] ?? ''),
                          onDeleted: () => onAgentRemove(agent['id'] ?? ''),
                          backgroundColor:
                              Theme.of(context).colorScheme.primaryContainer,
                          labelStyle: TextStyle(
                            color:
                                Theme.of(
                                  context,
                                ).colorScheme.onPrimaryContainer,
                          ),
                          deleteIconColor:
                              Theme.of(context).colorScheme.onPrimaryContainer,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                        );
                      }).toList(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
