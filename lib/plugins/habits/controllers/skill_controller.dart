import 'package:Memento/core/storage/storage_manager.dart';
import 'package:Memento/plugins/habits/models/skill.dart';

class SkillController {
  final StorageManager storage;

  SkillController(this.storage);

  Future<List<Skill>> getSkills() async {
    final data = await storage.readJson('skills');
    return data.map((e) => Skill.fromMap(e)).toList();
  }

  Future<void> saveSkill(Skill skill) async {
    final skills = await getSkills();
    final index = skills.indexWhere((s) => s.id == skill.id);

    if (index >= 0) {
      skills[index] = skill;
    } else {
      skills.add(skill);
    }

    await storage.writeJson('skills', skills.map((s) => s.toMap()).toList());
  }

  Future<void> deleteSkill(String id) async {
    final skills = await getSkills();
    skills.removeWhere((s) => s.id == id);
    await storage.writeJson('skills', skills.map((s) => s.toMap()).toList());
  }
}
