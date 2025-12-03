import 'package:Memento/core/storage/storage_manager.dart';
import 'package:Memento/plugins/habits/models/completion_record.dart';
import 'package:Memento/plugins/habits/models/skill.dart';
import 'package:Memento/plugins/habits/utils/habits_utils.dart';

class SkillController {
  final StorageManager storage;
  static const _skillsKey = 'habits/skills';
  List<Skill> _skills = [];
  static const String _initializedKey = 'habits/skills_initialized';

  SkillController(this.storage) {
    loadSkills();
  }

  Future<List<CompletionRecord>> getSkillCompletionRecords(
    String skillId,
  ) async {
    try {
      final data = await storage.readJson('habits/records/$skillId.json', []);
      List<Map<String, dynamic>> recordMaps = [];
      if (data is List) {
        recordMaps = List<Map<String, dynamic>>.from(
          data.whereType<Map>().where((m) => m.isNotEmpty),
        );
      }
      return recordMaps
          .map((e) => CompletionRecord.fromMap(e))
          .where((r) => r != null)
          .toList();
    } catch (e) {
      print('Error loading completion records: $e');
      return [];
    }
  }

  Future<List<Skill>> loadSkills() async {
    try {
      final data = await storage.readJson(_skillsKey, []);
      List<Map<String, dynamic>> skillMaps = [];
      if (data is List) {
        skillMaps = List<Map<String, dynamic>>.from(
          data.whereType<Map>().where((m) => m.isNotEmpty),
        );
      }

      _skills =
          skillMaps
              .map((e) => Skill.fromMap(e))
              .where((s) => s != null)
              .toList();

      // 如果没有技能数据且未初始化过，创建默认技能
      if (_skills.isEmpty) {
        final isInitialized = await storage.readJson(_initializedKey, false);
        if (isInitialized == false) {
          await _createDefaultSkills();
          await storage.writeJson(_initializedKey, true);
        }
      }

      return _skills;
    } catch (e) {
      print('Error loading skills: $e');
      return _skills = [];
    }
  }

  Future<void> _createDefaultSkills() async {
    final defaultSkills = [
      Skill(
        id: HabitsUtils.generateId(),
        title: '健康生活',
        description: '保持身体健康，养成良好的生活习惯',
        notes: '包括运动、饮食、睡眠等方面',
        group: '健康',
        icon: '59512',
        targetMinutes: 600, // 10小时目标
      ),
      Skill(
        id: HabitsUtils.generateId(),
        title: '学习提升',
        description: '持续学习新知识，提升个人能力',
        notes: '阅读、课程学习、技能训练等',
        group: '学习',
        icon: '59544',
        targetMinutes: 1200, // 20小时目标
      ),
      Skill(
        id: HabitsUtils.generateId(),
        title: '工作效率',
        description: '提高工作效率，优化工作时间',
        notes: '包括时间管理、任务规划、专注力训练',
        group: '工作',
        icon: '59509',
        targetMinutes: 480, // 8小时目标
      ),
      Skill(
        id: HabitsUtils.generateId(),
        title: '创意艺术',
        description: '培养创造力和艺术修养',
        notes: '绘画、音乐、写作、摄影等创意活动',
        group: '兴趣',
        icon: '59521',
        targetMinutes: 300, // 5小时目标
      ),
    ];

    _skills = defaultSkills;
    await storage.writeJson(_skillsKey, defaultSkills.map((s) => s.toMap()).toList());
    print('Created default skills: ${defaultSkills.length} items');
  }

  List<Skill> getSkills() {
    return _skills;
  }

  Skill? getSkillById(String id) {
    try {
      return _skills.firstWhere((s) => s.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<void> saveSkill(Skill skill) async {
    final index = _skills.indexWhere((s) => s.id == skill.id);

    if (index >= 0) {
      _skills[index] = skill;
    } else {
      _skills.add(skill);
    }
    await storage.writeJson(_skillsKey, _skills.map((s) => s.toMap()).toList());
  }

  Future<void> deleteSkill(String id) async {
    _skills.removeWhere((s) => s.id == id);
    await storage.writeJson(_skillsKey, _skills.map((s) => s.toMap()).toList());
  }

  /// Gets a skill by its title.
  /// Returns null if:
  /// - title is null or empty
  /// - no skill with matching title is found
  /// - multiple skills with same title exist (to avoid ambiguity)
  Skill? getSkillByTitle(String? title) {
    if (title == null || title.isEmpty) {
      return null;
    }

    final matchingSkills = _skills.where((s) => s.title == title).toList();

    if (matchingSkills.isEmpty) {
      return null;
    }

    if (matchingSkills.length > 1) {
      return null; // Avoid returning ambiguous results
    }

    return matchingSkills.first;
  }
}
