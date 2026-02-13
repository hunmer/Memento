part of 'habits_plugin.dart';

/// 注册数据选择器
void _registerDataSelectors() {
  // 习惯选择器
  PluginDataSelectorService.instance.registerSelector(SelectorDefinition(
    id: 'habits.habit',
    pluginId: HabitsPlugin.instance.id,
    name: '选择习惯',
    icon: HabitsPlugin.instance.icon,
    color: HabitsPlugin.instance.color,
    searchable: true,
    selectionMode: SelectionMode.single,
    steps: [
      SelectorStep(
        id: 'habit',
        title: '选择习惯',
        viewType: SelectorViewType.list,
        isFinalStep: true,
        dataLoader: (_) async {
          final habits = HabitsPlugin.instance._habitController.getHabits();
          final List<SelectableItem> items = [];

          for (final habit in habits) {
            // 获取累计时长和完成次数作为副标题
            final duration = await HabitsPlugin.instance._recordController.getTotalDuration(habit.id);
            final count = await HabitsPlugin.instance._recordController.getCompletionCount(habit.id);

            items.add(SelectableItem(
              id: habit.id,
              title: habit.title,
              subtitle: '$duration 分钟 · $count 次完成',
              icon: habit.icon != null
                  ? IconData(int.parse(habit.icon!), fontFamily: 'MaterialIcons')
                  : Icons.auto_awesome,
              rawData: habit,
            ));
          }

          return items;
        },
        searchFilter: (items, query) {
          if (query.isEmpty) return items;
          final lowerQuery = query.toLowerCase();
          return items.where((item) =>
            item.title.toLowerCase().contains(lowerQuery) ||
            (item.rawData as Habit).group?.toLowerCase().contains(lowerQuery) == true ||
            (item.rawData as Habit).tags.any((tag) => tag.toLowerCase().contains(lowerQuery))
          ).toList();
        },
      ),
    ],
  ));

  // 活动统计配置选择器
  PluginDataSelectorService.instance.registerSelector(SelectorDefinition(
    id: 'habits.activity_stats.config',
    pluginId: HabitsPlugin.instance.id,
    name: '配置活动统计',
    icon: Icons.analytics,
    color: HabitsPlugin.instance.color,
    searchable: false,
    selectionMode: SelectionMode.single,
    steps: [
      SelectorStep(
        id: 'config',
        title: '配置活动统计',
        viewType: SelectorViewType.customForm,
        dataLoader: (_) async => [],
        isFinalStep: true,
        customFormBuilder: (context, previousSelections, onComplete) {
          return _ActivityStatsConfigForm(
            onComplete: (config) {
              onComplete(config);
            },
          );
        },
      ),
    ],
  ));

  // 习惯统计配置选择器
  PluginDataSelectorService.instance.registerSelector(SelectorDefinition(
    id: 'habits.habit_stats.config',
    pluginId: HabitsPlugin.instance.id,
    name: '配置习惯统计',
    icon: Icons.trending_up,
    color: HabitsPlugin.instance.color,
    searchable: false,
    selectionMode: SelectionMode.single,
    steps: [
      SelectorStep(
        id: 'config',
        title: '配置习惯统计',
        viewType: SelectorViewType.customForm,
        dataLoader: (_) async => [],
        isFinalStep: true,
        customFormBuilder: (context, previousSelections, onComplete) {
          return _HabitStatsConfigForm(
            onComplete: (config) {
              onComplete(config);
            },
          );
        },
      ),
    ],
  ));
}

/// 活动统计配置表单
class _ActivityStatsConfigForm extends StatefulWidget {
  final Function(Map<String, dynamic>) onComplete;

  const _ActivityStatsConfigForm({required this.onComplete});

  @override
  State<_ActivityStatsConfigForm> createState() => _ActivityStatsConfigFormState();
}

class _ActivityStatsConfigFormState extends State<_ActivityStatsConfigForm> {
  String _dateRange = 'week';
  int _maxCount = 5;

  final List<Map<String, dynamic>> _dateRangeOptions = [
    {'value': 'today', 'label': '本日', 'icon': Icons.today},
    {'value': 'week', 'label': '本周', 'icon': Icons.date_range},
    {'value': 'month', 'label': '本月', 'icon': Icons.calendar_month},
    {'value': 'year', 'label': '本年', 'icon': Icons.calendar_today},
  ];

  void _confirm() {
    widget.onComplete({
      'dateRange': _dateRange,
      'maxCount': _maxCount,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // 标题
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.analytics, color: Colors.amber),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '配置活动统计',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // 配置选项
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // 日期范围选择
                  _buildSectionTitle('日期范围'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _dateRangeOptions.map((option) {
                      final isSelected = _dateRange == option['value'];
                      return FilterChip(
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              option['icon'] as IconData,
                              size: 16,
                              color: isSelected ? Colors.white : Colors.amber,
                            ),
                            const SizedBox(width: 4),
                            Text(option['label'] as String),
                          ],
                        ),
                        selected: isSelected,
                        selectedColor: Colors.amber,
                        checkmarkColor: Colors.white,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _dateRange = option['value'] as String);
                          }
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // 显示数量
                  _buildSectionTitle('最多显示数量'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Slider(
                          value: _maxCount.toDouble(),
                          min: 1,
                          max: 10,
                          divisions: 9,
                          label: '$_maxCount',
                          activeColor: Colors.amber,
                          onChanged: (value) {
                            setState(() => _maxCount = value.round());
                          },
                        ),
                      ),
                      Container(
                        width: 48,
                        alignment: Alignment.center,
                        child: Text(
                          '$_maxCount',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // 底部按钮
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('取消'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _confirm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('确认'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 14,
      ),
    );
  }
}

/// 习惯统计配置表单
class _HabitStatsConfigForm extends StatefulWidget {
  final Function(Map<String, dynamic>) onComplete;

  const _HabitStatsConfigForm({required this.onComplete});

  @override
  State<_HabitStatsConfigForm> createState() => _HabitStatsConfigFormState();
}

class _HabitStatsConfigFormState extends State<_HabitStatsConfigForm> {
  String? _selectedHabitId;
  List<Habit> _habits = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHabits();
  }

  void _loadHabits() {
    final habits = HabitsPlugin.instance._habitController.getHabits();
    setState(() {
      _habits = habits;
      _isLoading = false;
      if (habits.isNotEmpty) {
        _selectedHabitId = habits.first.id;
      }
    });
  }

  void _confirm() {
    if (_selectedHabitId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请选择一个习惯')),
      );
      return;
    }
    widget.onComplete({
      'habitId': _selectedHabitId,
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // 标题
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.trending_up, color: Colors.amber),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '配置习惯统计',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // 习惯列表
            Expanded(
              child: _habits.isEmpty
                  ? const Center(child: Text('暂无习惯'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _habits.length,
                      itemBuilder: (context, index) {
                        final habit = _habits[index];
                        final isSelected = _selectedHabitId == habit.id;

                        return Card(
                          elevation: isSelected ? 2 : 0,
                          margin: const EdgeInsets.only(bottom: 8),
                          color: isSelected ? Colors.amber.shade50 : null,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: isSelected ? Colors.amber : Colors.grey.shade300,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: ListTile(
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.amber.withAlpha(30),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                habit.icon != null
                                    ? IconData(int.parse(habit.icon!), fontFamily: 'MaterialIcons')
                                    : Icons.auto_awesome,
                                color: Colors.amber,
                              ),
                            ),
                            title: Text(habit.title),
                            subtitle: Text(
                              habit.group ?? habit.skillId ?? '习惯',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                            trailing: isSelected
                                ? const Icon(Icons.check_circle, color: Colors.amber)
                                : null,
                            onTap: () {
                              setState(() => _selectedHabitId = habit.id);
                            },
                          ),
                        );
                      },
                    ),
            ),
            // 底部按钮
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('取消'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _selectedHabitId != null ? _confirm : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey.shade300,
                      ),
                      child: const Text('确认'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
