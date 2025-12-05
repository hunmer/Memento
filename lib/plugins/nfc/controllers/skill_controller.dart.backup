import 'package:Memento/core/storage/storage_manager.dart';
import 'package:Memento/plugins/habits/models/completion_record.dart';
import 'package:Memento/plugins/habits/models/skill.dart';

class SkillController {
  final StorageManager storage;
  static const _skillsKey = 'habits/skills';
  List<Skill> _skills = [];

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
      return _skills;
    } catch (e) {
      print('Error loading skills: $e');
      return _skills = [];
    }
  }

  List<Skill> getSkills() {
    return _skills;
  }

  getSkillById(String id) {
    return _skills.firstWhere((s) => s.id == id);
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
