import 'package:get/get.dart';
import 'package:Memento/core/route/route_history_manager.dart';
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
  void initState() {
    super.initState();
    // 设置路由上下文
    _updateRouteContext();
  }

  /// 更新路由上下文,使"询问当前上下文"功能能获取到当前页面状态
  void _updateRouteContext() {
    final tabName = _selectedTabIndex == 0 ? '记录' : '统计';
    RouteHistoryManager.updateCurrentContext(
      pageId: '/skill_detail',
      title: '技能详情 - ${widget.skill.title} - $tabName',
      params: {
        'skillId': widget.skill.id,
        'skillTitle': widget.skill.title,
        'tab': tabName,
      },
    );
  }

  @override
  Widget build(BuildContext context) {

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
        onTap: (index) {
          setState(() => _selectedTabIndex = index);
          _updateRouteContext(); // 切换tab时更新路由上下文
        },
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.list),
            label: 'habits_records'.tr,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.bar_chart),
            label: 'habits_statistics'.tr,
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

    return showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('habits_deleteSkill'.tr),
            content: Text('habits_deleteSkillConfirmation'.tr),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('habits_cancel'.tr),
              ),
              TextButton(
                onPressed: () async {
                  await widget.skillController.deleteSkill(widget.skill.id);
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
                child: Text('habits_delete'.tr),
              ),
            ],
          ),
    );
  }
}
