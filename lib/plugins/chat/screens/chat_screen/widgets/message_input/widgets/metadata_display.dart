import 'package:Memento/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'dart:io' show Platform, Process;

class MetadataDisplay extends StatelessWidget {
  final Map<String, dynamic>? selectedFile;
  final List<Map<String, String>> selectedAgents;
  final Function() onShowAgentListDrawer;
  final Function() onFileRemove;
  final Function(String) onAgentRemove;
  final int contextRange;
  final Function(int) onContextRangeChange;

  static const int minRange = 0;
  static const int maxRange = 50;
  static const int defaultRange = 10;

  const MetadataDisplay({
    super.key,
    this.selectedFile,
    required this.selectedAgents,
    required this.onShowAgentListDrawer,
    required this.onFileRemove,
    required this.onAgentRemove,
    this.contextRange = defaultRange,
    required this.onContextRangeChange,
  });

  @override
  Widget build(BuildContext context) {
    if (selectedFile == null && selectedAgents.isEmpty) {
      // 没有文件和智能体时不显示任何内容
      return const SizedBox();
    }

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

          // 只有在选择了智能体时才显示上下文范围
          if (selectedAgents.isNotEmpty) ...[
            _buildContextRangeChip(context),
            const SizedBox(width: 8),
          ],

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

  Widget _buildContextRangeChip(BuildContext context) {
    return Container(
      padding: EdgeInsets.zero,
      child: GestureDetector(
        onTap: () => _showContextRangeDialog(context),
        child: Chip(
          avatar: Icon(
            Icons.history,
            size: 18,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
          label: Text('上下文: $contextRange'),
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          labelStyle: TextStyle(
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 4),
        ),
      ),
    );
  }

  Future<void> _showContextRangeDialog(BuildContext context) async {
    double currentValue = contextRange.toDouble();

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('设置上下文范围'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('当前范围: ${currentValue.round()}'),
                  Slider(
                    value: currentValue,
                    min: minRange.toDouble(),
                    max: maxRange.toDouble(),
                    divisions: maxRange - minRange,
                    label: currentValue.round().toString(),
                    onChanged: (value) {
                      setState(() {
                        currentValue = value;
                      });
                    },
                  ),
                  const Text(
                    '范围: 0-50，0表示不使用上下文',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text(AppLocalizations.of(context)!.cancel),
                ),
                TextButton(
                  onPressed: () {
                    onContextRangeChange(currentValue.round());
                    Navigator.of(context).pop();
                  },
                  child: Text(AppLocalizations.of(context)!.ok),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
