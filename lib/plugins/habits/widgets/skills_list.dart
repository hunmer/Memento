import 'dart:io';

import 'package:Memento/utils/image_utils.dart';
import 'package:flutter/material.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
import 'package:Memento/plugins/habits/controllers/completion_record_controller.dart';
import 'package:Memento/plugins/habits/controllers/skill_controller.dart';
import 'package:Memento/plugins/habits/l10n/habits_localizations.dart';
import 'package:Memento/plugins/habits/models/skill.dart';
import 'package:Memento/plugins/habits/utils/habits_utils.dart';
import 'package:Memento/plugins/habits/widgets/skill_form.dart';
import 'package:Memento/plugins/habits/widgets/skill_detail_page.dart';
import 'package:Memento/widgets/super_cupertino_navigation_wrapper.dart';

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

class _SkillsListState extends State<SkillsList> with WidgetsBindingObserver {
  List<Skill> _skills = [];
  int _refreshKey = 0; // 用于强制刷新统计数据

  @override
  void initState() {
    super.initState();
    // 添加生命周期监听
    WidgetsBinding.instance.addObserver(this);
    _loadSkills();
  }

  @override
  void dispose() {
    // 移除生命周期监听
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // 应用从后台恢复时重新加载数据并刷新统计
    if (state == AppLifecycleState.resumed) {
      debugPrint('SkillsList: 应用恢复，重新加载技能数据');
      _reloadSkills();
    }
  }

  /// 从存储重新加载技能数据（用于应用恢复时）
  Future<void> _reloadSkills() async {
    // 等待同步完成
    await Future.delayed(const Duration(milliseconds: 300));
    // 从存储重新加载
    final skills = await widget.skillController.loadSkills();
    if (mounted) {
      setState(() {
        _skills = skills;
        _refreshKey++; // 增加 key 强制刷新 FutureBuilder
      });
    }
  }

  Future<void> _loadSkills() async {
    final skills = widget.skillController.getSkills();
    if (mounted) {
      setState(() => _skills = skills);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = HabitsLocalizations.of(context);
    return SuperCupertinoNavigationWrapper(
      title: Text(l10n.skills),
      largeTitle: l10n.skills,
      enableLargeTitle: true,
      automaticallyImplyLeading: !(Platform.isAndroid || Platform.isIOS),
      actions: [
        IconButton(
          icon: const Icon(Icons.sort),
          onPressed: _showSortMenu,
        ),
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: () => _showSkillForm(context),
        ),
      ],
      body: _buildCardView(_skills, l10n),
    );
  }

  /// 显示排序菜单
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

  Widget _buildCardView(List<Skill> skills, HabitsLocalizations l10n) {
    // 按group分组
    final groupedSkills = <String, List<Skill>>{};
    for (final skill in skills) {
      final group = skill.group ?? '未分组';
      groupedSkills.putIfAbsent(group, () => []).add(skill);
    }

    return ListView(
      children:
          groupedSkills.entries.map((entry) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Text(
                    entry.key,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.8,
                  ),
                  itemCount: entry.value.length,
                  itemBuilder: (context, index) {
                    final skill = entry.value[index];
                    return FutureBuilder(
                      key: ValueKey('card_${skill.id}_$_refreshKey'),
                      future: Future.wait([
                        widget.recordController.getCompletionCount(skill.id),
                        widget.recordController.getTotalDuration(skill.id),
                      ]),
                      builder: (context, snapshot) {
                        final count = snapshot.data?[0] ?? 0;
                        final duration = snapshot.data?[1] ?? 0;

                        return Card(
                          child: InkWell(
                            onTap: () async {
                              await NavigationHelper.push(context, SkillDetailPage(
                                        skill: skill,
                                        skillController: widget.skillController,
                                        recordController:
                                            widget.recordController,),
                              );
                              if (mounted) _loadSkills();
                            },
                            child: Column(
                              children: [
                                Expanded(
                                  child:
                                      skill.image != null &&
                                              skill.image!.isNotEmpty
                                          ? FutureBuilder<String>(
                                            future:
                                                skill.image!.startsWith('http')
                                                    ? Future.value(skill.image!)
                                                    : ImageUtils.getAbsolutePath(
                                                      skill.image!,
                                                    ),
                                            builder: (context, snapshot) {
                                              if (snapshot.hasData) {
                                                return Container(
                                                  decoration: BoxDecoration(
                                                    image: DecorationImage(
                                                      image:
                                                          skill.image!
                                                                  .startsWith(
                                                                    'http',
                                                                  )
                                                              ? NetworkImage(
                                                                snapshot.data!,
                                                              )
                                                              : FileImage(
                                                                    File(
                                                                      snapshot
                                                                          .data!,
                                                                    ),
                                                                  )
                                                                  as ImageProvider,
                                                      fit: BoxFit.cover,
                                                      colorFilter:
                                                          ColorFilter.mode(
                                                            Colors.black
                                                                .withValues(
                                                                  alpha: 0.3,
                                                                ),
                                                            BlendMode.darken,
                                                          ),
                                                    ),
                                                  ),
                                                  child: Center(
                                                    child: Column(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        Text(
                                                          skill.title,
                                                          style: TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 18,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                        Text(
                                                          '$count completions',
                                                          style: TextStyle(
                                                            color: Colors.white,
                                                          ),
                                                        ),
                                                        Text(
                                                          HabitsUtils.formatDuration(
                                                            duration,
                                                          ),
                                                          style: TextStyle(
                                                            color: Colors.white,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                );
                                              } else if (snapshot.hasError) {
                                                return Container(
                                                  color: Colors.grey[200],
                                                  child: const Icon(
                                                    Icons.broken_image,
                                                  ),
                                                );
                                              } else {
                                                return const Center(
                                                  child:
                                                      CircularProgressIndicator(),
                                                );
                                              }
                                            },
                                          )
                                          : skill.icon != null
                                          ? CircleAvatar(
                                            radius: 24,
                                            backgroundColor:
                                                Theme.of(context).primaryColor,
                                            child: Icon(
                                              IconData(
                                                int.parse(skill.icon!),
                                                fontFamily: 'MaterialIcons',
                                              ),
                                              size: 24,
                                              color: Colors.white,
                                            ),
                                          )
                                          : const Icon(
                                            Icons.auto_awesome,
                                            size: 48,
                                          ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                    skill.title,
                                    style:
                                        Theme.of(context).textTheme.titleSmall,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: Text(
                                    '$count completions',
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            );
          }).toList(),
    );
  }

  Future<void> _showSkillForm(BuildContext context, [Skill? skill]) async {
    final l10n = HabitsLocalizations.of(context);
    await NavigationHelper.push(context, Scaffold(
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
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              body: SkillForm(
                initialSkill: skill,
                onSave: (skill) async {
                  await widget.skillController.saveSkill(skill);
                  Navigator.pop(context);
                  _loadSkills();
                },),
      ),
    );
  }
}
