import 'package:get/get.dart';
import 'package:Memento/plugins/habits/widgets/skill_form.dart';
import 'package:flutter/material.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
import 'package:Memento/plugins/habits/controllers/completion_record_controller.dart';
import 'package:Memento/plugins/habits/controllers/skill_controller.dart';
import 'package:Memento/plugins/habits/models/skill.dart';
import 'package:Memento/plugins/habits/widgets/completion_records_tab.dart';
import 'package:Memento/plugins/habits/widgets/statistics_tab.dart';

class SkillDetailPage extends StatefulWidget {
  final Skill skill;
  final SkillController skillController;
  final CompletionRecordController recordController;

  const SkillDetailPage({
    super.key,
    required this.skill,
    required this.skillController,
    required this.recordController,
  });

  @override
  State<SkillDetailPage> createState() => _SkillDetailPageState();
}

class _SkillDetailPageState extends State<SkillDetailPage> {
  int _selectedTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = HabitsLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.skill.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _navigateToEdit(context),
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _confirmDelete(context),
            color: Theme.of(context).colorScheme.error,
          ),
        ],
      ),
      body: _buildTabContent(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedTabIndex,
        onTap: (index) => setState(() => _selectedTabIndex = index),
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.list),
            label: l10n.records,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.bar_chart),
            label: l10n.statistics,
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTabIndex) {
      case 0:
        return CompletionRecordsTab(
          skill: widget.skill,
          recordController: widget.recordController,
        );
      case 1:
        return StatisticsTab(
          skill: widget.skill,
          recordController: widget.recordController,
        );
      default:
        return Container();
    }
  }

  Future<void> _navigateToEdit(BuildContext context) async {
    HabitsLocalizations.of(context);
    await NavigationHelper.push(
      context,
      SkillForm(
        initialSkill: widget.skill,
        onSave: (skill) async {
          await widget.skillController.saveSkill(skill);
          Navigator.pop(context);
          setState(() {});
        },
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final l10n = HabitsLocalizations.of(context);
    return showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(l10n.deleteSkill),
            content: Text(l10n.deleteSkillConfirmation),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.cancel),
              ),
              TextButton(
                onPressed: () async {
                  await widget.skillController.deleteSkill(widget.skill.id);
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
                child: Text(l10n.delete),
              ),
            ],
          ),
    );
  }
}
