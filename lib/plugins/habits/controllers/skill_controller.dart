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

  Future<void> saveCompletionRecord(
    String skillId,
    CompletionRecord record,
  ) async {
    final path = 'habits/records/$skillId.json';
    final existingRecords = await getCompletionRecords(skillId);
    existingRecords.add(record);

    await storage.writeJson(
      path,
      existingRecords.map((r) => r.toMap()).toList(),
    );
  }

  Future<List<CompletionRecord>> getCompletionRecords(String skillId) async {
    final path = 'habits/records/$skillId.json';
    final data = await storage.readJson(path, []);

    return List<Map<String, dynamic>>.from(
      data,
    ).map((e) => CompletionRecord.fromMap(e)).toList();
  }

  Future<List<Skill>> loadSkills() async {
    final data = await storage.readJson(_skillsKey, []);
    _skills =
        List<Map<String, dynamic>>.from(
          data,
        ).map((e) => Skill.fromMap(e)).toList();
    return _skills;
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
