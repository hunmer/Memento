import '../../openai/openai_plugin.dart';
import '../calendar_album_plugin.dart';
import '../services/prompt_replacements.dart';

/// CalendarAlbum 插件的 Prompt 控制器
///
/// 负责注册 Prompt 替换方法到 OpenAI 插件
class CalendarAlbumPromptController {
  final CalendarAlbumPlugin plugin;
  late final CalendarAlbumPromptReplacements _replacements;

  CalendarAlbumPromptController(this.plugin) {
    _replacements = CalendarAlbumPromptReplacements(plugin);
  }

  /// 初始化并注册Prompt方法
  void initialize() {
    // 延迟注册以确保OpenAI插件已初始化
    _registerPromptMethods();
  }

  /// 注册Prompt替换方法
  void _registerPromptMethods() {
    Future.delayed(const Duration(seconds: 1), () {
      try {
        // 注册所有6个方法
        OpenAIPlugin.instance.registerPromptReplacementMethod(
          'calendar_album_getEntries',
          _replacements.getEntries,
        );

        OpenAIPlugin.instance.registerPromptReplacementMethod(
          'calendar_album_getPhotos',
          _replacements.getPhotos,
        );

        OpenAIPlugin.instance.registerPromptReplacementMethod(
          'calendar_album_getTagStats',
          _replacements.getTagStats,
        );

        OpenAIPlugin.instance.registerPromptReplacementMethod(
          'calendar_album_getMoodWeatherStats',
          _replacements.getMoodWeatherStats,
        );

        OpenAIPlugin.instance.registerPromptReplacementMethod(
          'calendar_album_getLocationStats',
          _replacements.getLocationStats,
        );

        OpenAIPlugin.instance.registerPromptReplacementMethod(
          'calendar_album_getStatistics',
          _replacements.getStatistics,
        );
      } catch (e) {
        // 如果注册失败,可能是OpenAI插件还未初始化,稍后重试
        Future.delayed(const Duration(seconds: 5), _registerPromptMethods);
      }
    });
  }

  /// 释放资源
  void dispose() {
    _replacements.dispose();
  }
}
