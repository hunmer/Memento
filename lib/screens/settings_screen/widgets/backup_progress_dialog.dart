import 'package:flutter/material.dart';
import 'package:get/get.dart';

class BackupProgressDialog extends StatelessWidget {
  final Stream<BackupProgress> progressStream;
  final String title;
  final VoidCallback? onCancel;

  const BackupProgressDialog({
    super.key,
    required this.progressStream,
    required this.title,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Dialog(
        child: Container(
          width: 400,
          constraints: const BoxConstraints(maxHeight: 400),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleLarge),
                  if (onCancel != null)
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: onCancel,
                      tooltip: '取消操作',
                    ),
                ],
              ),
              const SizedBox(height: 16),
              StreamBuilder<BackupProgress>(
                stream: progressStream,
                builder: (context, snapshot) {
                  final progress = snapshot.data ?? BackupProgress.initial();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 总进度条
                      LinearProgressIndicator(
                        value: progress.totalProgress,
                        backgroundColor:
                            Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                      ),
                      const SizedBox(height: 8),
                      // 总进度百分比
                      Text(
                        '总进度: ${(progress.totalProgress * 100).toStringAsFixed(1)}%',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 16),
                      // 当前操作
                      Text(
                        progress.currentOperation,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // 文件列表
                      Flexible(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest
                                .withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.all(8),
                          child: ListView.builder(
                            shrinkWrap: true,
                            reverse: true,
                            itemCount: progress.recentFiles.length,
                            itemBuilder: (context, index) {
                              final file = progress.recentFiles[index];
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 2,
                                ),
                                child: Text(
                                  file,
                                  style: Theme.of(context).textTheme.bodySmall,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BackupProgress {
  final double totalProgress;
  final String currentOperation;
  final List<String> recentFiles;

  const BackupProgress({
    required this.totalProgress,
    required this.currentOperation,
    required this.recentFiles,
  });

  factory BackupProgress.initial() {
    return const BackupProgress(
      totalProgress: 0,
      currentOperation: '准备中...',
      recentFiles: [],
    );
  }

  BackupProgress copyWith({
    double? totalProgress,
    String? currentOperation,
    List<String>? recentFiles,
  }) {
    return BackupProgress(
      totalProgress: totalProgress ?? this.totalProgress,
      currentOperation: currentOperation ?? this.currentOperation,
      recentFiles: recentFiles ?? this.recentFiles,
    );
  }
}
