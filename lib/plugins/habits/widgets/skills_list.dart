import 'package:Memento/core/plugin_manager.dart';
import 'package:flutter/material.dart';
import 'package:Memento/plugins/habits/controllers/completion_record_controller.dart';
import 'package:Memento/plugins/habits/controllers/skill_controller.dart';
import 'package:Memento/plugins/habits/l10n/habits_localizations.dart';
import 'package:Memento/plugins/habits/models/skill.dart';
import 'package:Memento/plugins/habits/utils/habits_utils.dart';
import 'package:Memento/plugins/habits/widgets/skill_form.dart';
import 'package:Memento/plugins/habits/widgets/skill_detail_page.dart';

class SkillsList extends StatefulWidget {
  final SkillController skillController;
  final CompletionRecordController recordController;

  const SkillsList({
    super.key,
    required this.skillController,
    required this.recordController,
  });

  @override
  State<SkillsList> createState() => _SkillsListState();
}

class _SkillsListState extends State<SkillsList> {
  List<Skill> _skills = [];
  String? _selectedGroup;
  bool _isCardView = false;

  @override
  void initState() {
    super.initState();
    _loadSkills();
  }

  Future<void> _loadSkills() async {
    final skills = await widget.skillController.getSkills();
    setState(() => _skills = skills);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = HabitsLocalizations.of(context);
    final groups = HabitsUtils.getGroups([], _skills);
    final filteredSkills =
        _selectedGroup == null
            ? _skills
            : _skills.where((s) => s.group == _selectedGroup).toList();

    return Column(
      children: [
        _buildAppBar(context, l10n, groups),
        Expanded(
          child:
              _isCardView
                  ? _buildCardView(filteredSkills, l10n)
                  : _buildListView(filteredSkills, l10n),
        ),
      ],
    );
  }

  AppBar _buildAppBar(
    BuildContext context,
    HabitsLocalizations l10n,
    List<String> groups,
  ) {
    return AppBar(
      title: Text(l10n.skills),
      leading: IconButton(
        icon: Icon(Icons.arrow_back),
        onPressed: () => PluginManager.toHomeScreen(context),
      ),
      actions: [
        if (groups.isNotEmpty)
          DropdownButton<String>(
            value: _selectedGroup,
            hint: Text(l10n.group),
            items: [
              const DropdownMenuItem(value: null, child: Text('All')),
              ...groups.map(
                (group) => DropdownMenuItem(value: group, child: Text(group)),
              ),
            ],
            onChanged: (group) => setState(() => _selectedGroup = group),
          ),
        IconButton(icon: const Icon(Icons.sort), onPressed: _showSortMenu),
        IconButton(
          icon: Icon(_isCardView ? Icons.list : Icons.grid_view),
          onPressed: () => setState(() => _isCardView = !_isCardView),
        ),
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: () => _showSkillForm(context),
        ),
      ],
    );
  }

  Widget _buildListView(List<Skill> skills, HabitsLocalizations l10n) {
    return ListView.builder(
      itemCount: skills.length,
      itemBuilder: (context, index) {
        final skill = skills[index];
        return FutureBuilder(
          future: Future.wait([
            widget.recordController.getCompletionCount(skill.id),
            widget.recordController.getTotalDuration(skill.id),
          ]),
          builder: (context, snapshot) {
            final count = snapshot.data?[0] ?? 0;
            final duration = snapshot.data?[1] ?? 0;

            return ListTile(
              leading:
                  skill.icon != null
                      ? Icon(
                        IconData(
                          int.parse(skill.icon!),
                          fontFamily: 'MaterialIcons',
                        ),
                      )
                      : null,
              title: Text(skill.title),
              subtitle: Text(
                '$count completions • ${HabitsUtils.formatDuration(duration)}',
              ),
              onTap:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => SkillDetailPage(
                            skill: skill,
                            skillController: widget.skillController,
                            recordController: widget.recordController,
                          ),
                    ),
                  ),
            );
          },
        );
      },
    );
  }

  Widget _buildCardView(List<Skill> skills, HabitsLocalizations l10n) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
      ),
      itemCount: skills.length,
      itemBuilder: (context, index) {
        final skill = skills[index];
        return FutureBuilder(
          future: Future.wait([
            widget.recordController.getCompletionCount(skill.id),
            widget.recordController.getTotalDuration(skill.id),
          ]),
          builder: (context, snapshot) {
            final count = snapshot.data?[0] ?? 0;
            final duration = snapshot.data?[1] ?? 0;

            return Card(
              child: Column(
                children: [
                  Expanded(
                    child:
                        skill.image != null
                            ? Image.network(skill.image!, fit: BoxFit.cover)
                            : skill.icon != null
                            ? Icon(
                              IconData(
                                int.parse(skill.icon!),
                                fontFamily: 'MaterialIcons',
                              ),
                              size: 48,
                            )
                            : const Icon(Icons.auto_awesome, size: 48),
                  ),
                  Text(skill.title),
                  Text('$count completions'),
                  Text(HabitsUtils.formatDuration(duration)),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showSortMenu() {
    final l10n = HabitsLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      builder:
          (context) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.sort_by_alpha),
                title: Text(l10n.sortByName),
                onTap: () {
                  setState(() {
                    _skills.sort((a, b) => a.title.compareTo(b.title));
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.format_list_numbered),
                title: Text(l10n.sortByCompletions),
                onTap: () async {
                  final counts = await Future.wait(
                    _skills.map(
                      (s) => widget.recordController.getCompletionCount(s.id),
                    ),
                  );
                  final sortedSkills =
                      _skills
                          .asMap()
                          .entries
                          .map((e) => (e.value, counts[e.key]))
                          .toList()
                        ..sort((a, b) => b.$2.compareTo(a.$2));
                  setState(() {
                    _skills = sortedSkills.map((e) => e.$1).toList();
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.timer),
                title: Text(l10n.sortByDuration),
                onTap: () async {
                  final durations = await Future.wait(
                    _skills.map(
                      (s) => widget.recordController.getTotalDuration(s.id),
                    ),
                  );
                  final sortedSkills =
                      _skills
                          .asMap()
                          .entries
                          .map((e) => (e.value, durations[e.key]))
                          .toList()
                        ..sort((a, b) => b.$2.compareTo(a.$2));
                  setState(() {
                    _skills = sortedSkills.map((e) => e.$1).toList();
                  });
                  Navigator.pop(context);
                },
              ),
            ],
          ),
    );
  }

  Future<void> _showSkillForm(BuildContext context, [Skill? skill]) async {
    final l10n = HabitsLocalizations.of(context);
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => Scaffold(
              appBar: AppBar(
                title: Text(skill == null ? l10n.createSkill : l10n.editSkill),
                actions: [
                  if (skill != null)
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () async {
                        await widget.skillController.deleteSkill(skill.id);
                        Navigator.pop(context);
                        _loadSkills();
                      },
                    ),
                ],
              ),
              body: SkillForm(
                initialSkill: skill,
                onSave: (skill) async {
                  await widget.skillController.saveSkill(skill);
                  Navigator.pop(context);
                  _loadSkills();
                },
              ),
            ),
      ),
    );
  }
}
