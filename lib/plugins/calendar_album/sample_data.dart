import 'models/calendar_entry.dart';

/// 日历相册插件的示例数据
/// 当插件的 JSON 文件不存在时，自动加载这些示例数据
class CalendarAlbumSampleData {
  /// 获取示例日记条目列表
  static List<CalendarEntry> getSampleCalendarEntries() {
    final now = DateTime.now();

    return [
      // 今天的日记 - 最新
      CalendarEntry(
        id: 'entry-${now.millisecondsSinceEpoch}',
        title: '美好的一天开始啦',
        content: '''今天天气真不错！阳光明媚，心情也特别好。

早上起来后做了一杯手冲咖啡，香味弥漫在整个厨房。打开窗户，清新的空气扑面而来，让人瞬间清醒。

准备开始新的一天工作！加油！''',
        createdAt: DateTime(now.year, now.month, now.day, 8, 30),
        updatedAt: DateTime(now.year, now.month, now.day, 8, 30),
        tags: ['生活', '心情'],
        location: '家',
        mood: '😊',
        weather: '晴天',
        imageUrls: [],
        thumbUrls: [],
      ),

      // 昨天的日记
      CalendarEntry(
        id: 'entry-${now.subtract(const Duration(days: 1)).millisecondsSinceEpoch}',
        title: '工作总结',
        content: '''今天完成了项目的重要里程碑！

主要完成了：
- ✅ 用户界面优化
- ✅ 数据库性能调优
- ✅ 编写单元测试
- ✅ 修复了3个Bug

明天继续加油，准备开始下一个功能的开发。

```
代码示例：
void main() {
  print("Hello, World!");
}
```
''',
        createdAt: DateTime(now.year, now.month, now.day - 1, 18, 0),
        updatedAt: DateTime(now.year, now.month, now.day - 1, 18, 0),
        tags: ['工作', '项目', '开发'],
        location: '公司',
        mood: '💪',
        weather: '多云',
        imageUrls: [],
        thumbUrls: [],
      ),

      // 3天前的日记
      CalendarEntry(
        id: 'entry-${now.subtract(const Duration(days: 3)).millisecondsSinceEpoch}',
        title: '周末时光',
        content: '''今天是周末，和朋友约好一起去公园野餐。

带了水果、三明治和饮料，还带了飞盘和羽毛球。在草地上玩了一下午，感觉回到了童年。

**今天的亮点：**
- 和老朋友聊天很开心
- 天气很好，晒太阳很舒服
- 运动了一下，身体很舒服

希望每个周末都能这么愉快！''',
        createdAt: DateTime(now.year, now.month, now.day - 3, 15, 30),
        updatedAt: DateTime(now.year, now.month, now.day - 3, 15, 30),
        tags: ['休闲', '朋友', '运动'],
        location: '中央公园',
        mood: '🥳',
        weather: '晴天',
        imageUrls: [],
        thumbUrls: [],
      ),

      // 5天前的日记
      CalendarEntry(
        id: 'entry-${now.subtract(const Duration(days: 5)).millisecondsSinceEpoch}',
        title: '学习新技能',
        content: '''开始学习Flutter开发框架，虽然是全新的领域，但很有挑战性。

今天跟着教程完成了：
- 安装Flutter SDK
- 创建第一个项目
- 理解了Widget的概念
- 学会了StatefulWidget和StatelessWidget的区别

虽然遇到了几个小问题，但通过查阅文档都解决了。

继续努力！💪

> "学习是一种态度，成长是一种选择。"''',
        createdAt: DateTime(now.year, now.month, now.day - 5, 20, 0),
        updatedAt: DateTime(now.year, now.month, now.day - 5, 20, 0),
        tags: ['学习', 'Flutter', '开发'],
        location: '家',
        mood: '📚',
        weather: '晴天',
        imageUrls: [],
        thumbUrls: [],
      ),

      // 7天前的日记
      CalendarEntry(
        id: 'entry-${now.subtract(const Duration(days: 7)).millisecondsSinceEpoch}',
        title: '雨天感悟',
        content: '''外面下着雨，淅淅沥沥的。

雨天总是让人变得多愁善感。泡了一杯热茶，坐在窗前看着雨滴顺着玻璃流下。

想起了很多往事，想起了那些曾经陪伴过的人。

有时候觉得，生活就像这雨，有时急有时缓。但不管怎样，雨后总会有彩虹。

希望明天是个好天气。''',
        createdAt: DateTime(now.year, now.month, now.day - 7, 19, 30),
        updatedAt: DateTime(now.year, now.month, now.day - 7, 19, 30),
        tags: ['感悟', '思考'],
        location: '家',
        mood: '🤔',
        weather: '雨天',
        imageUrls: [],
        thumbUrls: [],
      ),

      // 10天前的日记
      CalendarEntry(
        id: 'entry-${now.subtract(const Duration(days: 10)).millisecondsSinceEpoch}',
        title: '生日聚会',
        content: '''今天是好友的生日，我们为他准备了惊喜派对！

大家偷偷聚在一起，买了生日蛋糕和礼物。当他推开门的那一刻，所有人都喊"生日快乐"，他感动得眼眶都湿润了。

**聚会的美好瞬间：**
- 一起唱生日歌
- 分享蛋糕的甜蜜
- 聊不完的话题
- 拍照留念

友谊真的是世界上最珍贵的财富！愿我们的友谊天长地久！''',
        createdAt: DateTime(now.year, now.month, now.day - 10, 20, 0),
        updatedAt: DateTime(now.year, now.month, now.day - 10, 20, 0),
        tags: ['聚会', '生日', '友谊'],
        location: '餐厅',
        mood: '🎉',
        weather: '多云',
        imageUrls: [],
        thumbUrls: [],
      ),
    ];
  }

  /// 获取按日期分组的示例数据
  /// Map的key是日期（仅日期部分），value是该日期的日记列表
  static Map<DateTime, List<CalendarEntry>> getSampleCalendarEntriesGrouped() {
    final entries = getSampleCalendarEntries();
    final Map<DateTime, List<CalendarEntry>> groupedEntries = {};

    for (final entry in entries) {
      // 只保留日期部分，去掉时间
      final dateKey = DateTime(
        entry.createdAt.year,
        entry.createdAt.month,
        entry.createdAt.day,
      );

      if (!groupedEntries.containsKey(dateKey)) {
        groupedEntries[dateKey] = [];
      }
      groupedEntries[dateKey]!.add(entry);
    }

    return groupedEntries;
  }
}
