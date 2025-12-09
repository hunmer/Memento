import 'package:get/get.dart';
import 'agent_chat_translations_zh.dart';
import 'agent_chat_translations_en.dart';

/// Agent Chat插件GetX翻译类
class AgentChatTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
        'zh_CN': agentChatTranslationsZh,
        'en_US': agentChatTranslationsEn,
      };
}
