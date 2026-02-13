import 'package:Memento/core/services/plugin_widget_sync_helper.dart';
import 'package:Memento/core/storage/storage_manager.dart';
import 'package:Memento/core/event/event_manager.dart';
import 'package:Memento/core/event/event_args.dart';
import 'package:Memento/plugins/habits/models/completion_record.dart';
import 'package:Memento/plugins/habits/models/skill.dart';
import 'package:Memento/plugins/habits/utils/habits_utils.dart';
import 'package:Memento/plugins/habits/sample_data.dart';

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
    // 使用示例数据创建默认技能
    final sampleData = HabitsSampleData.getSampleData();
    final skillMaps = sampleData['skills'] as List<Map<String, dynamic>>;
    final defaultSkills = skillMaps.map((m) => Skill.fromMap(m)).toList();

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

    // 广播技能数据变更事件，同步小组件
    EventManager.instance.broadcast(
      'skill_data_changed',
      Value({'skill': skill}),
    );

    // 同步到小组件
    await _syncWidget();
  }

  Future<void> deleteSkill(String id) async {
    _skills.removeWhere((s) => s.id == id);
    await storage.writeJson(_skillsKey, _skills.map((s) => s.toMap()).toList());

    // 广播技能数据变更事件，同步小组件
    EventManager.instance.broadcast(
      'skill_data_changed',
      Value({'skillId': id}),
    );

    // 同步到小组件
    await _syncWidget();
  }

  Future<void> _syncWidget() async {
    await PluginWidgetSyncHelper.instance.syncHabits();
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
