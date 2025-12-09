/// Chat插件示例数据
/// 用于初始化和演示用途

import 'dart:convert';

/// 获取示例频道数据
Map<String, dynamic> getSampleChannelsData() {
  return {
    "channels": [
      {
        "id": "default",
        "title": "默认频道",
        "icon": 0xE0B7, // chat图标
        "iconFontFamily": "MaterialIcons",
        "backgroundColor": "#2196F3", // 蓝色
        "priority": 1,
        "lastMessageTime":
            DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
        "metadata": {"description": "系统的默认频道，包含欢迎消息和使用说明", "isDefault": true},
      },
      {
        "id": "ai_assistant",
        "title": "AI助手",
        "icon": 0xE0B7, // chat图标
        "iconFontFamily": "MaterialIcons",
        "backgroundColor": "#9C27B0", // 紫色
        "priority": 0,
        "lastMessageTime":
            DateTime.now()
                .subtract(const Duration(minutes: 30))
                .toIso8601String(),
        "metadata": {"description": "与AI助手的对话记录，包含各种有用的问答"},
      },
      {
        "id": "work_notes",
        "title": "工作备忘",
        "icon": 0xE0B7, // chat图标
        "iconFontFamily": "MaterialIcons",
        "backgroundColor": "#4CAF50", // 绿色
        "priority": 0,
        "lastMessageTime":
            DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
        "metadata": {"description": "记录工作相关的重要信息和待办事项"},
      },
      {
        "id": "ideas",
        "title": "灵感收集",
        "icon": 0xE0B7, // chat图标
        "iconFontFamily": "MaterialIcons",
        "backgroundColor": "#FF9800", // 橙色
        "priority": 0,
        "lastMessageTime":
            DateTime.now().subtract(const Duration(hours: 6)).toIso8601String(),
        "metadata": {"description": "随时记录创意和想法"},
      },
      {
        "id": "daily_log",
        "title": "日常记录",
        "icon": 0xE0B7, // chat图标
        "iconFontFamily": "MaterialIcons",
        "backgroundColor": "#009688", // 青色
        "priority": 0,
        "lastMessageTime": DateTime.now().toIso8601String(),
        "metadata": {"description": "记录日常生活的点点滴滴"},
      },
    ],
    "defaultChannelId": "default",
    "settings": {
      "messageFontSize": 14.0,
      "enableTimestamp": true,
      "enableMarkdown": true,
      "autoSave": true,
      "maxMessagesPerChannel": 1000,
    },
  };
}

/// 获取示例频道消息数据
Map<String, List<Map<String, dynamic>>> getSampleMessagesData() {
  final now = DateTime.now();

  return {
    "default": [
      {
        "id": "msg_default_001",
        "content":
            "🎉 欢迎使用 **Memento Chat**!\n\n这是您的默认频道。在这里您可以：\n- 💬 记录日常想法\n- 🤝 与AI助手对话\n- 📝 管理多个频道\n- 🏷️ 使用Markdown格式\n\n试试输入 **/help** 查看更多命令！",
        "type": "sent",
        "date": now.subtract(const Duration(days: 30)).toIso8601String(),
        "user": {"id": "system", "username": "系统"},
        "metadata": {
          "isWelcomeMessage": true,
          "style": "info",
          "fixedSymbol": "👋",
        },
      },
      {
        "id": "msg_default_002",
        "content":
            "### 📚 Markdown 支持展示\n\n您可以使用以下格式：\n\n1. **粗体文本**\n2. *斜体文本*\n3. ~~删除线~~\n4. `行内代码`\n\n```dart\n// 代码块示例\nvoid main() {\n  print('Hello, Memento!');\n}\n```\n\n> 💡 提示：所有消息都支持 Markdown 格式！",
        "type": "sent",
        "date":
            now.subtract(const Duration(days: 29, hours: 3)).toIso8601String(),
        "editedAt":
            now
                .subtract(const Duration(days: 29, hours: 2, minutes: 45))
                .toIso8601String(),
        "user": {"id": "default_user", "username": "我"},
        "metadata": {"wordCount": 68, "hasCode": true},
      },
      {
        "id": "msg_default_003",
        "content":
            "✅ 功能列表\n\n- [x] 创建频道\n- [x] 发送消息\n- [x] Markdown支持\n- [x] 消息搜索\n- [ ] 图片附件（即将推出）\n- [ ] 语音消息（计划中）",
        "type": "sent",
        "date": now.subtract(const Duration(days: 28)).toIso8601String(),
        "user": {"id": "default_user", "username": "我"},
        "metadata": {"isChecklist": true},
      },
      {
        "id": "msg_default_004",
        "content":
            "🔍 **搜索功能说明**\n\n使用搜索栏可以快速找到历史消息：\n- 支持关键词搜索\n- 支持正则表达式\n- 可以按频道筛选\n- 可以按时间范围筛选",
        "type": "received",
        "date": now.subtract(const Duration(days: 15)).toIso8601String(),
        "user": {"id": "system", "username": "系统"},
        "metadata": {"style": "tip"},
      },
      {
        "id": "msg_default_005",
        "content":
            "📊 **使用统计**\n\n您已经创建了 **5** 个频道，发送了 **60** 条消息。最活跃的频道是「日常记录」。\n\n继续保持记录的习惯吧！",
        "type": "received",
        "date": now.subtract(const Duration(hours: 2)).toIso8601String(),
        "user": {"id": "system", "username": "系统"},
        "metadata": {"style": "stats", "totalChannels": 5, "totalMessages": 60},
      },
    ],

    "ai_assistant": [
      {
        "id": "msg_ai_001",
        "content": "你好！我是你的AI助手。有什么可以帮助你的吗？",
        "type": "received",
        "date":
            now.subtract(const Duration(days: 25, hours: 10)).toIso8601String(),
        "user": {"id": "ai", "username": "AI助手"},
        "metadata": {"model": "gpt-3.5-turbo", "responseTime": 1.2},
      },
      {
        "id": "msg_ai_002",
        "content": "如何提高工作效率？",
        "type": "sent",
        "date":
            now
                .subtract(const Duration(days: 25, hours: 10, minutes: 1))
                .toIso8601String(),
        "user": {"id": "default_user", "username": "我"},
        "metadata": {},
      },
      {
        "id": "msg_ai_003",
        "content":
            "## 提高工作效率的建议\n\n### 🎯 设定明确目标\n- 使用SMART原则设定目标\n- 将大任务分解为小任务\n- 设定优先级\n\n### ⏰ 时间管理\n- 使用番茄工作法\n- 批处理相似任务\n- 设定固定的工作时间\n\n### 🛠️ 工具推荐\n- 任务管理：Todoist, Notion\n- 时间追踪：Toggl, RescueTime\n- 笔记整理：Obsidian, Evernote",
        "type": "received",
        "date":
            now
                .subtract(const Duration(days: 25, hours: 9, minutes: 58))
                .toIso8601String(),
        "user": {"id": "ai", "username": "AI助手"},
        "metadata": {
          "model": "gpt-3.5-turbo",
          "responseTime": 3.5,
          "tokensUsed": 256,
        },
      },
    ],

    "work_notes": [
      {
        "id": "msg_work_001",
        "content":
            "## 项目进展\n\n- ✅ 完成需求分析文档\n- 🔄 正在进行UI设计（预计本周完成）\n- ⏳ 等待客户反馈\n\n### 下周计划\n1. 完成原型设计\n2. 开始前端开发\n3. 准备技术方案评审",
        "type": "sent",
        "date": now.subtract(const Duration(days: 5)).toIso8601String(),
        "editedAt":
            now.subtract(const Duration(days: 5, hours: 2)).toIso8601String(),
        "user": {"id": "default_user", "username": "我"},
        "metadata": {"projectId": "PROJ-001", "priority": "high"},
      },
      {
        "id": "msg_work_002",
        "content":
            "💭 **会议纪要**\n\n**日期**: ${now.subtract(const Duration(days: 3)).toString().split(' ')[0]}\n**主题**: Q4规划讨论\n\n### 决策事项\n- 新产品线启动时间：2025年1月\n- 预算已批准：500万\n- 团队扩招：5人（3前端，2后端）",
        "type": "sent",
        "date": now.subtract(const Duration(days: 3)).toIso8601String(),
        "user": {"id": "default_user", "username": "我"},
        "metadata": {"meetingId": "MTG-045"},
      },
      {
        "id": "msg_work_003",
        "content": "⚠️ **紧急**: 客户反馈生产环境有Bug，需要立即处理\n\n影响范围：用户登录模块\n优先级：P0（最高）",
        "type": "sent",
        "date": now.subtract(const Duration(days: 1)).toIso8601String(),
        "user": {"id": "default_user", "username": "我"},
        "metadata": {"severity": "critical", "bugId": "BUG-789"},
      },
    ],

    "ideas": [
      {
        "id": "msg_ideas_001",
        "content": "💡 **新功能想法**：智能标签建议\n\n基于消息内容自动推荐标签，提高整理效率。",
        "type": "sent",
        "date": now.subtract(const Duration(days: 15)).toIso8601String(),
        "user": {"id": "default_user", "username": "我"},
        "metadata": {"ideaStatus": "concept", "estimatedEffort": "medium"},
      },
      {
        "id": "msg_ideas_002",
        "content": "🚀 **产品改进**：消息模板功能\n\n场景：经常发送相似内容（日报、周报、会议纪要等）",
        "type": "sent",
        "date": now.subtract(const Duration(days: 10)).toIso8601String(),
        "user": {"id": "default_user", "username": "我"},
        "metadata": {"ideaStatus": "design", "userRequests": 5},
      },
      {
        "id": "msg_ideas_003",
        "content": "🌟 **创意灵感**：AI思维导图\n\n将聊天记录自动转换为思维导图，帮助整理思路。",
        "type": "sent",
        "date": now.subtract(const Duration(hours: 6)).toIso8601String(),
        "user": {"id": "default_user", "username": "我"},
        "metadata": {"ideaStatus": "research"},
      },
    ],

    "daily_log": [
      {
        "id": "msg_daily_001",
        "content":
            "## ${now.subtract(const Duration(hours: 8)).toString().split(' ')[0]} ☀️\n\n### 今日完成\n- 晨跑 5公里 ✅\n- 完成项目提案 ✅",
        "type": "sent",
        "date": now.subtract(const Duration(hours: 8)).toIso8601String(),
        "user": {"id": "default_user", "username": "我"},
        "metadata": {"logType": "daily", "completedTasks": 2},
      },
      {
        "id": "msg_daily_002",
        "content": "### 今日感悟 🤔\n\n今天尝试了2个番茄钟的深度工作，效率确实提升了50%。",
        "type": "sent",
        "date": now.subtract(const Duration(hours: 4)).toIso8601String(),
        "user": {"id": "default_user", "username": "我"},
        "metadata": {"logType": "reflection"},
      },
    ],
  };
}

/// 生成示例消息文件内容
String generateMessageFileContent(
  String channelId,
  List<Map<String, dynamic>> messages,
) {
  return jsonEncode(messages);
}

/// 获取频道图标
String getChannelIcon(String iconCode) {
  switch (iconCode) {
    case 'chat':
      return '💬';
    case 'smart_toy':
      return '🤖';
    case 'work':
      return '💼';
    case 'lightbulb':
      return '💡';
    case 'today':
      return '📅';
    default:
      return '📌';
  }
}
