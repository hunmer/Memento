import 'package:uuid/uuid.dart';
import 'models/habit.dart';
import 'models/skill.dart';
import 'models/completion_record.dart';

/// 习惯追踪插件示例数据
/// 当插件首次使用且没有数据时，自动加载这些示例数据
class HabitsSampleData {
  static const uuid = Uuid();

  /// 获取完整示例数据（包含技能、习惯和完成记录）
  static Map<String, dynamic> getSampleData() {
    final now = DateTime.now();

    // ==================== 技能数据 ====================
    final skills = [
      // 技能1: 健康生活
      Skill(
        id: 'skill-health-001',
        title: '健康生活',
        description: '通过运动和冥想，保持身心健康',
        notes: '一万小时目标：1000小时',
        group: '健康',
        icon: '59512', // Icons.favorite
        targetMinutes: 60000, // 1000小时
        maxDurationMinutes: 120,
      ),
      // 技能2: 学习提升
      Skill(
        id: 'skill-learning-001',
        title: '学习提升',
        description: '持续学习新知识和技能',
        notes: '一万小时目标：500小时',
        group: '学习',
        icon: '59544', // Icons.school
        targetMinutes: 30000, // 500小时
        maxDurationMinutes: 180,
      ),
      // 技能3: 创意写作
      Skill(
        id: 'skill-writing-001',
        title: '创意写作',
        description: '培养写作能力和创意思维',
        notes: '一万小时目标：300小时',
        group: '创作',
        icon: '57975', // Icons.create
        targetMinutes: 18000, // 300小时
        maxDurationMinutes: 120,
      ),
      // 技能4: 工作效率
      Skill(
        id: 'skill-productivity-001',
        title: '工作效率',
        description: '提升工作专注度和效率',
        notes: '一万小时目标：400小时',
        group: '工作',
        icon: '59509', // Icons.work
        targetMinutes: 24000, // 400小时
        maxDurationMinutes: 60,
      ),
    ];

    // ==================== 习惯数据 ====================
    final habits = [
      // 习惯1: 晨跑 (健康生活)
      Habit(
        id: 'habit-run-001',
        title: '晨跑',
        notes: '早起跑步，开启美好一天',
        group: '健康生活',
        icon: '58352', // Icons.directions_run
        reminderDays: [1, 3, 5], // 周一、周三、周五
        intervalDays: 0, // 每天
        durationMinutes: 30,
        tags: ['运动', '有氧', '减脂'],
        skillId: 'skill-health-001',
        totalDurationMinutes: 150,
      ),
      // 习惯2: 冥想 (健康生活)
      Habit(
        id: 'habit-meditate-001',
        title: '冥想',
        notes: '每天冥想，保持内心平静',
        group: '健康生活',
        icon: '59569', // Icons.self_improvement
        reminderDays: [1, 2, 3, 4, 5], // 工作日
        intervalDays: 0,
        durationMinutes: 15,
        tags: ['冥想', '放松', '心理健康'],
        skillId: 'skill-health-001',
        totalDurationMinutes: 120,
      ),
      // 习惯3: 健身 (健康生活)
      Habit(
        id: 'habit-gym-001',
        title: '健身',
        notes: '力量训练，增强体质',
        group: '健康生活',
        icon: '59642', // Icons.fitness_center
        reminderDays: [2, 4, 6], // 周二、周四、周六
        intervalDays: 1, // 隔天
        durationMinutes: 60,
        tags: ['健身', '力量', '增肌'],
        skillId: 'skill-health-001',
        totalDurationMinutes: 180,
      ),
      // 习惯4: 阅读 (学习提升)
      Habit(
        id: 'habit-read-001',
        title: '阅读',
        notes: '每天阅读，拓展知识面',
        group: '学习提升',
        icon: '59544', // Icons.menu_book
        reminderDays: [0, 1, 2, 3, 4, 5, 6], // 每天提醒
        intervalDays: 0,
        durationMinutes: 30,
        tags: ['阅读', '知识', '自我提升'],
        skillId: 'skill-learning-001',
        totalDurationMinutes: 300,
      ),
      // 习惯5: 英语学习 (学习提升)
      Habit(
        id: 'habit-english-001',
        title: '英语学习',
        notes: '每天学习英语，提升语言能力',
        group: '学习提升',
        icon: '58834', // Icons.language
        reminderDays: [1, 2, 3, 4, 5], // 工作日
        intervalDays: 0,
        durationMinutes: 45,
        tags: ['英语', '语言', '学习'],
        skillId: 'skill-learning-001',
        totalDurationMinutes: 225,
      ),
      // 习惯6: 学习新技能 (学习提升)
      Habit(
        id: 'habit-newskill-001',
        title: '学习新技能',
        notes: '定期学习一项新技能',
        group: '学习提升',
        icon: '58373', // Icons.explore
        reminderDays: [0, 6], // 周末
        intervalDays: 0,
        durationMinutes: 90,
        tags: ['技能', '成长', '探索'],
        skillId: 'skill-learning-001',
        totalDurationMinutes: 180,
      ),
      // 习惯7: 写作 (创意写作)
      Habit(
        id: 'habit-write-001',
        title: '写作',
        notes: '每天写作，记录生活灵感',
        group: '创意写作',
        icon: '57975', // Icons.create
        reminderDays: [1, 2, 3, 4, 5], // 工作日
        intervalDays: 0,
        durationMinutes: 30,
        tags: ['写作', '日记', '创意'],
        skillId: 'skill-writing-001',
        totalDurationMinutes: 150,
      ),
      // 习惯8: 时间回顾 (工作效率)
      Habit(
        id: 'habit-review-001',
        title: '时间回顾',
        notes: '每天回顾时间使用情况',
        group: '工作效率',
        icon: '58845', // Icons.history
        reminderDays: [0, 1, 2, 3, 4, 5, 6], // 每天
        intervalDays: 0,
        durationMinutes: 15,
        tags: ['规划', '总结', '时间管理'],
        skillId: 'skill-productivity-001',
        totalDurationMinutes: 75,
      ),
    ];

    // ==================== 完成记录数据 ====================
    final records = <String, List<Map<String, dynamic>>>{
      // 晨跑的记录
      'habit-run-001': [
        CompletionRecord(
          id: uuid.v4(),
          parentId: 'habit-run-001',
          date: now.subtract(const Duration(days: 1, hours: 6, minutes: 30)),
          duration: const Duration(minutes: 32),
          notes: '天气不错，跑了5公里',
        ).toMap(),
        CompletionRecord(
          id: uuid.v4(),
          parentId: 'habit-run-001',
          date: now.subtract(const Duration(days: 3, hours: 6, minutes: 30)),
          duration: const Duration(minutes: 28),
          notes: '轻度跑，状态不错',
        ).toMap(),
        CompletionRecord(
          id: uuid.v4(),
          parentId: 'habit-run-001',
          date: now.subtract(const Duration(days: 5, hours: 6, minutes: 30)),
          duration: const Duration(minutes: 35),
          notes: '挑战跑，很累但很爽',
        ).toMap(),
        CompletionRecord(
          id: uuid.v4(),
          parentId: 'habit-run-001',
          date: now.subtract(const Duration(days: 7, hours: 6, minutes: 30)),
          duration: const Duration(minutes: 30),
          notes: '常规晨跑',
        ).toMap(),
        CompletionRecord(
          id: uuid.v4(),
          parentId: 'habit-run-001',
          date: now.subtract(const Duration(days: 10, hours: 6, minutes: 30)),
          duration: const Duration(minutes: 25),
          notes: '稍微有点累，缩短了时间',
        ).toMap(),
      ],
      // 冥想的记录
      'habit-meditate-001': [
        CompletionRecord(
          id: uuid.v4(),
          parentId: 'habit-meditate-001',
          date: now.subtract(const Duration(hours: 7)),
          duration: const Duration(minutes: 15),
          notes: '早晨冥想，感觉清醒',
        ).toMap(),
        CompletionRecord(
          id: uuid.v4(),
          parentId: 'habit-meditate-001',
          date: now.subtract(const Duration(days: 1, hours: 22)),
          duration: const Duration(minutes: 20),
          notes: '睡前冥想，帮助入睡',
        ).toMap(),
        CompletionRecord(
          id: uuid.v4(),
          parentId: 'habit-meditate-001',
          date: now.subtract(const Duration(days: 2, hours: 7)),
          duration: const Duration(minutes: 15),
          notes: '专注呼吸',
        ).toMap(),
        CompletionRecord(
          id: uuid.v4(),
          parentId: 'habit-meditate-001',
          date: now.subtract(const Duration(days: 3, hours: 7)),
          duration: const Duration(minutes: 15),
          notes: '身体扫描冥想',
        ).toMap(),
        CompletionRecord(
          id: uuid.v4(),
          parentId: 'habit-meditate-001',
          date: now.subtract(const Duration(days: 5, hours: 22)),
          duration: const Duration(minutes: 25),
          notes: '深度冥想，很放松',
        ).toMap(),
        CompletionRecord(
          id: uuid.v4(),
          parentId: 'habit-meditate-001',
          date: now.subtract(const Duration(days: 7, hours: 7)),
          duration: const Duration(minutes: 15),
          notes: '正念冥想',
        ).toMap(),
        CompletionRecord(
          id: uuid.v4(),
          parentId: 'habit-meditate-001',
          date: now.subtract(const Duration(days: 9, hours: 7)),
          duration: const Duration(minutes: 15),
          notes: '感恩冥想',
        ).toMap(),
      ],
      // 健身的记录
      'habit-gym-001': [
        CompletionRecord(
          id: uuid.v4(),
          parentId: 'habit-gym-001',
          date: now.subtract(const Duration(days: 2, hours: 19)),
          duration: const Duration(minutes: 60),
          notes: '胸肌训练',
        ).toMap(),
        CompletionRecord(
          id: uuid.v4(),
          parentId: 'habit-gym-001',
          date: now.subtract(const Duration(days: 4, hours: 18, minutes: 30)),
          duration: const Duration(minutes: 55),
          notes: '背肌训练',
        ).toMap(),
        CompletionRecord(
          id: uuid.v4(),
          parentId: 'habit-gym-001',
          date: now.subtract(const Duration(days: 7, hours: 19)),
          duration: const Duration(minutes: 65),
          notes: '腿部训练，强度很大',
        ).toMap(),
      ],
      // 阅读的记录
      'habit-read-001': [
        CompletionRecord(
          id: uuid.v4(),
          parentId: 'habit-read-001',
          date: now.subtract(const Duration(hours: 21)),
          duration: const Duration(minutes: 35),
          notes: '阅读《原子习惯》',
        ).toMap(),
        CompletionRecord(
          id: uuid.v4(),
          parentId: 'habit-read-001',
          date: now.subtract(const Duration(days: 1, hours: 21, minutes: 30)),
          duration: const Duration(minutes: 30),
          notes: '继续阅读《原子习惯》',
        ).toMap(),
        CompletionRecord(
          id: uuid.v4(),
          parentId: 'habit-read-001',
          date: now.subtract(const Duration(days: 2, hours: 20)),
          duration: const Duration(minutes: 40),
          notes: '读了很多，收获很大',
        ).toMap(),
        CompletionRecord(
          id: uuid.v4(),
          parentId: 'habit-read-001',
          date: now.subtract(const Duration(days: 3, hours: 21)),
          duration: const Duration(minutes: 30),
          notes: '技术文档阅读',
        ).toMap(),
        CompletionRecord(
          id: uuid.v4(),
          parentId: 'habit-read-001',
          date: now.subtract(const Duration(days: 4, hours: 20, minutes: 30)),
          duration: const Duration(minutes: 45),
          notes: '小说阅读，很放松',
        ).toMap(),
        CompletionRecord(
          id: uuid.v4(),
          parentId: 'habit-read-001',
          date: now.subtract(const Duration(days: 5, hours: 22)),
          duration: const Duration(minutes: 30),
          notes: '睡前阅读',
        ).toMap(),
        CompletionRecord(
          id: uuid.v4(),
          parentId: 'habit-read-001',
          date: now.subtract(const Duration(days: 6, hours: 20)),
          duration: const Duration(minutes: 35),
          notes: '周末阅读，时间充裕',
        ).toMap(),
        CompletionRecord(
          id: uuid.v4(),
          parentId: 'habit-read-001',
          date: now.subtract(const Duration(days: 7, hours: 21)),
          duration: const Duration(minutes: 30),
          notes: '技术文章阅读',
        ).toMap(),
        CompletionRecord(
          id: uuid.v4(),
          parentId: 'habit-read-001',
          date: now.subtract(const Duration(days: 8, hours: 20, minutes: 30)),
          duration: const Duration(minutes: 40),
          notes: '深入阅读，做笔记',
        ).toMap(),
      ],
      // 英语学习的记录
      'habit-english-001': [
        CompletionRecord(
          id: uuid.v4(),
          parentId: 'habit-english-001',
          date: now.subtract(const Duration(hours: 8)),
          duration: const Duration(minutes: 45),
          notes: '单词记忆',
        ).toMap(),
        CompletionRecord(
          id: uuid.v4(),
          parentId: 'habit-english-001',
          date: now.subtract(const Duration(days: 1, hours: 8)),
          duration: const Duration(minutes: 40),
          notes: '听力练习',
        ).toMap(),
        CompletionRecord(
          id: uuid.v4(),
          parentId: 'habit-english-001',
          date: now.subtract(const Duration(days: 2, hours: 8)),
          duration: const Duration(minutes: 50),
          notes: '口语练习，和外教对话',
        ).toMap(),
        CompletionRecord(
          id: uuid.v4(),
          parentId: 'habit-english-001',
          date: now.subtract(const Duration(days: 3, hours: 7, minutes: 30)),
          duration: const Duration(minutes: 45),
          notes: '阅读理解',
        ).toMap(),
        CompletionRecord(
          id: uuid.v4(),
          parentId: 'habit-english-001',
          date: now.subtract(const Duration(days: 5, hours: 8)),
          duration: const Duration(minutes: 45),
          notes: '语法练习',
        ).toMap(),
      ],
      // 学习新技能的记录
      'habit-newskill-001': [
        CompletionRecord(
          id: uuid.v4(),
          parentId: 'habit-newskill-001',
          date: now.subtract(const Duration(days: 1, hours: 14)),
          duration: const Duration(minutes: 90),
          notes: '学习Dart语言基础',
        ).toMap(),
        CompletionRecord(
          id: uuid.v4(),
          parentId: 'habit-newskill-001',
          date: now.subtract(const Duration(days: 8, hours: 13, minutes: 30)),
          duration: const Duration(minutes: 90),
          notes: 'Flutter组件学习',
        ).toMap(),
      ],
      // 写作的记录
      'habit-write-001': [
        CompletionRecord(
          id: uuid.v4(),
          parentId: 'habit-write-001',
          date: now.subtract(const Duration(hours: 20, minutes: 30)),
          duration: const Duration(minutes: 30),
          notes: '写一篇关于习惯养成的文章',
        ).toMap(),
        CompletionRecord(
          id: uuid.v4(),
          parentId: 'habit-write-001',
          date: now.subtract(const Duration(days: 1, hours: 21)),
          duration: const Duration(minutes: 35),
          notes: '写日记，记录今天的感受',
        ).toMap(),
        CompletionRecord(
          id: uuid.v4(),
          parentId: 'habit-write-001',
          date: now.subtract(const Duration(days: 2, hours: 20)),
          duration: const Duration(minutes: 30),
          notes: '整理写作思路',
        ).toMap(),
        CompletionRecord(
          id: uuid.v4(),
          parentId: 'habit-write-001',
          date: now.subtract(const Duration(days: 3, hours: 22)),
          duration: const Duration(minutes: 25),
          notes: '睡前写一段灵感',
        ).toMap(),
        CompletionRecord(
          id: uuid.v4(),
          parentId: 'habit-write-001',
          date: now.subtract(const Duration(days: 5, hours: 21)),
          duration: const Duration(minutes: 30),
          notes: '周末写随笔',
        ).toMap(),
      ],
      // 时间回顾的记录
      'habit-review-001': [
        CompletionRecord(
          id: uuid.v4(),
          parentId: 'habit-review-001',
          date: now.subtract(const Duration(hours: 23)),
          duration: const Duration(minutes: 15),
          notes: '今天效率不错，明天继续保持',
        ).toMap(),
        CompletionRecord(
          id: uuid.v4(),
          parentId: 'habit-review-001',
          date: now.subtract(const Duration(days: 1, hours: 23)),
          duration: const Duration(minutes: 15),
          notes: '今天有些拖延，明天要改进',
        ).toMap(),
        CompletionRecord(
          id: uuid.v4(),
          parentId: 'habit-review-001',
          date: now.subtract(const Duration(days: 2, hours: 22, minutes: 30)),
          duration: const Duration(minutes: 15),
          notes: '完成了重要任务，很满意',
        ).toMap(),
        CompletionRecord(
          id: uuid.v4(),
          parentId: 'habit-review-001',
          date: now.subtract(const Duration(days: 3, hours: 23)),
          duration: const Duration(minutes: 15),
          notes: '今天学习了很多新知识',
        ).toMap(),
        CompletionRecord(
          id: uuid.v4(),
          parentId: 'habit-review-001',
          date: now.subtract(const Duration(days: 4, hours: 22)),
          duration: const Duration(minutes: 15),
          notes: '休息日，没有计划时间',
        ).toMap(),
      ],
    };

    return {
      'skills': skills.map((s) => s.toMap()).toList(),
      'habits': habits.map((h) => h.toMap()).toList(),
      'records': records,
    };
  }

  /// 获取简化版示例数据（用于快速测试）
  static Map<String, dynamic> getSimplifiedSampleData() {
    final now = DateTime.now();

    final skills = [
      Skill(
        id: 'skill-simple-health',
        title: '健康生活',
        description: '保持身心健康',
        group: '健康',
        icon: '59512', // Icons.favorite
        targetMinutes: 10000,
      ),
      Skill(
        id: 'skill-simple-learning',
        title: '学习提升',
        description: '持续学习新知识',
        group: '学习',
        icon: '59544', // Icons.school
        targetMinutes: 5000,
      ),
    ];

    final habits = [
      Habit(
        id: 'habit-simple-run',
        title: '晨跑',
        notes: '每天跑步30分钟',
        group: '健康生活',
        icon: '58352', // Icons.directions_run
        durationMinutes: 30,
        tags: ['运动', '健康'],
        skillId: 'skill-simple-health',
        totalDurationMinutes: 30,
      ),
      Habit(
        id: 'habit-simple-read',
        title: '阅读',
        notes: '每天阅读30分钟',
        group: '学习提升',
        icon: '59544', // Icons.menu_book
        durationMinutes: 30,
        tags: ['阅读', '学习'],
        skillId: 'skill-simple-learning',
        totalDurationMinutes: 30,
      ),
    ];

    final records = <String, List<Map<String, dynamic>>>{
      'habit-simple-run': [
        CompletionRecord(
          id: uuid.v4(),
          parentId: 'habit-simple-run',
          date: now.subtract(const Duration(days: 1, hours: 6)),
          duration: const Duration(minutes: 30),
          notes: '天气不错',
        ).toMap(),
      ],
      'habit-simple-read': [
        CompletionRecord(
          id: uuid.v4(),
          parentId: 'habit-simple-read',
          date: now.subtract(const Duration(hours: 21)),
          duration: const Duration(minutes: 30),
          notes: '读了一章书',
        ).toMap(),
      ],
    };

    return {
      'skills': skills.map((s) => s.toMap()).toList(),
      'habits': habits.map((h) => h.toMap()).toList(),
      'records': records,
    };
  }

  /// 获取空白数据（仅创建默认技能，无习惯和记录）
  static Map<String, dynamic> getEmptyData() {
    final defaultSkill = Skill(
      id: 'skill-default',
      title: '我的技能',
      description: '点击添加你的第一个技能',
      group: '默认',
      icon: '59544', // Icons.school
      targetMinutes: 0,
    );

    return {
      'skills': [defaultSkill.toMap()],
      'habits': <Map<String, dynamic>>[],
      'records': <String, List<Map<String, dynamic>>>{},
    };
  }
}
