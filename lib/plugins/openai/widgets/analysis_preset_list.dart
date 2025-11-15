import 'package:flutter/material.dart';
import '../models/analysis_preset.dart';
import '../controllers/analysis_preset_controller.dart';
import '../l10n/openai_localizations.dart';
import 'analysis_preset_card.dart';

/// 分析预设列表组件
///
/// 用于展示所有分析预设的网格列表
class AnalysisPresetList extends StatelessWidget {
  final AnalysisPresetController controller;
  final Function(AnalysisPreset) onPresetTap; // 编辑预设
  final Function(AnalysisPreset) onPresetRun; // 运行预设

  const AnalysisPresetList({
    super.key,
    required this.controller,
    required this.onPresetTap,
    required this.onPresetRun,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = OpenAILocalizations.of(context);

    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        // 加载状态
        if (controller.isLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        // 空状态
        if (controller.presets.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.analytics_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  localizations.noPresetsYet,
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  localizations.createFirstPreset,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        // 预设列表
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: controller.presets.length,
          itemBuilder: (context, index) {
            final preset = controller.presets[index];
            return AnalysisPresetCard(
              preset: preset,
              onTap: () => onPresetTap(preset),
              onRun: () => onPresetRun(preset),
              onDelete: () => _deletePreset(context, preset.id),
            );
          },
        );
      },
    );
  }

  /// 删除预设
  Future<void> _deletePreset(BuildContext context, String presetId) async {
    try {
      await controller.deletePreset(presetId);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(OpenAILocalizations.of(context).presetSaved),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${OpenAILocalizations.of(context).deleteFailed}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
