import 'package:Memento/l10n/app_localizations.dart';
import 'package:Memento/plugins/timer/l10n/timer_localizations.dart';
import 'package:Memento/plugins/timer/views/add_timer_item_dialog.dart';
import 'package:Memento/widgets/group_selector_dialog.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/timer_task.dart' show TimerTask;
import '../models/timer_item.dart';
import '../../../widgets/icon_picker_dialog.dart';

class AddTimerTaskDialog extends StatefulWidget {
  final List<String> groups;
  final TimerTask? initialTask;

  const AddTimerTaskDialog({super.key, required this.groups, this.initialTask});

  @override
  _AddTimerTaskDialogState createState() => _AddTimerTaskDialogState();
}

class _AddTimerTaskDialogState extends State<AddTimerTaskDialog> {
  bool _enableNotification = false;
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final List<TimerItem> _timerItems;
  late final String _id;
  late Color _selectedColor;
  late IconData _selectedIcon;
  late String? _selectedGroup;
  late int _repeatCount;

  final List<IconData> _presetIcons = [
    Icons.psychology,
    Icons.auto_stories,
    Icons.code,
    Icons.fitness_center,
    Icons.edit,
    Icons.more_horiz,
  ];

  @override
  void initState() {
    super.initState();
    final initialTask = widget.initialTask;
    if (initialTask != null) {
      _id = initialTask.id;
      _nameController = TextEditingController(text: initialTask.name);
      _timerItems = List.from(initialTask.timerItems);
      _selectedColor = initialTask.color;
      _selectedIcon = initialTask.icon;
      _selectedGroup = initialTask.group;
      _repeatCount = initialTask.repeatCount;
      _enableNotification = initialTask.enableNotification;
    } else {
      _id = const Uuid().v4();
      _nameController = TextEditingController();
      _timerItems = [];
      _selectedColor = const Color(0xFF607AFB);
      _selectedIcon = Icons.psychology;
      _selectedGroup = null;
      _repeatCount = 1;
      _enableNotification = true;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF0F1323) : const Color(0xFFF5F6F8);
    final cardColor = isDark ? const Color(0xFF181D2C) : Colors.white;
    final primaryColor = const Color(0xFF607AFB);

    return Dialog(
      insetPadding: EdgeInsets.zero,
      backgroundColor: backgroundColor,
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: backgroundColor,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new,
              color: isDark ? Colors.white : Colors.grey[600],
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            widget.initialTask != null ? '编辑计时器' : '添加计时器',
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF0F172A),
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Section 1: Basic Info
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel(context, '图标'),
                      const SizedBox(height: 8),
                      _buildIconGrid(primaryColor, isDark),
                      const SizedBox(height: 24),

                      _buildLabel(context, TimerLocalizations.of(context).taskName),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _nameController,
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black,
                        ),
                        decoration: _buildInputDecoration(
                          context,
                          hint: '例如: 晨间专注',
                          isDark: isDark,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '请输入${TimerLocalizations.of(context).taskName}';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel(
                                  context,
                                  TimerLocalizations.of(context).repeatCount,
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  initialValue: _repeatCount.toString(),
                                  keyboardType: TextInputType.number,
                                  style: TextStyle(
                                    color: isDark ? Colors.white : Colors.black,
                                  ),
                                  decoration: _buildInputDecoration(
                                    context,
                                    isDark: isDark,
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return '必填';
                                    }
                                    final count = int.tryParse(value);
                                    if (count == null || count < 1) {
                                      return '> 0';
                                    }
                                    return null;
                                  },
                                  onChanged: (value) {
                                    if (value.isNotEmpty) {
                                      final count = int.tryParse(value) ?? 1;
                                      setState(() {
                                        _repeatCount = count.clamp(1, 100);
                                      });
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel(
                                  context,
                                  TimerLocalizations.of(context).selectGroup,
                                ),
                                const SizedBox(height: 8),
                                InkWell(
                                  onTap: _showGroupSelector,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 14, // Match text field height approx
                                    ),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? Colors.grey[800]
                                          : Colors.grey[50],
                                      border: Border.all(
                                        color: isDark
                                            ? Colors.grey[600]!
                                            : Colors.grey[300]!,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            _selectedGroup ?? '选择分组',
                                            style: TextStyle(
                                              color: isDark
                                                  ? Colors.white
                                                  : Colors.black,
                                            ),
                                          ),
                                        ),
                                        Icon(
                                          Icons.arrow_drop_down,
                                          color: isDark
                                              ? Colors.white70
                                              : Colors.black54,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Section 2: Sub-timers
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '子计时器',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_timerItems.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Center(
                            child: Text(
                              '暂无子计时器',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        ),
                      ..._timerItems.map(
                        (timer) => _buildSubTimerItem(context, timer, isDark),
                      ),
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: _showAddTimerDialog,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.grey[800] : Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add,
                                size: 20,
                                color: isDark ? Colors.white : Colors.grey[700],
                              ),
                              const SizedBox(width: 8),
                              Text(
                                TimerLocalizations.of(context).addTimer,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? Colors.white
                                      : Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Section 3: Notifications
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.notifications, color: primaryColor),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          TimerLocalizations.of(context).enableNotification,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF1E293B),
                          ),
                        ),
                      ),
                      Switch.adaptive(
                        value: _enableNotification,
                        activeColor: primaryColor,
                        onChanged:
                            (value) => setState(() => _enableNotification = value),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 80), // Space for bottom bar
              ],
            ),
          ),
        ),
        bottomNavigationBar: Container(
          padding: const EdgeInsets.all(16),
          color: backgroundColor,
          child: SafeArea(
            child: ElevatedButton(
              onPressed: _timerItems.isEmpty ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
                shadowColor: primaryColor.withValues(alpha: 0.4),
              ),
              child: Text(
                AppLocalizations.of(context)!.save,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(BuildContext context, String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      text,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: isDark ? Colors.grey[500] : Colors.grey[600],
      ),
    );
  }

  InputDecoration _buildInputDecoration(
    BuildContext context, {
    String? hint,
    bool isDark = false,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: isDark ? Colors.grey[600] : Colors.grey[500],
      ),
      filled: true,
      fillColor: isDark ? Colors.grey[800] : Colors.grey[50],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: isDark ? Colors.grey[600]! : Colors.grey[300]!,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: isDark ? Colors.grey[600]! : Colors.grey[300]!,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF607AFB), width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _buildIconGrid(Color primaryColor, bool isDark) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 6,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 1.0,
      children: _presetIcons.map((icon) {
        final isSelected = _selectedIcon == icon;
        return InkWell(
          onTap: () {
            if (icon == Icons.more_horiz) {
              // Open full picker
              _openFullIconPicker();
            } else {
              setState(() {
                _selectedIcon = icon;
              });
            }
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected
                  ? primaryColor
                  : (isDark ? Colors.grey[800] : Colors.grey[100]),
              borderRadius: BorderRadius.circular(8),
              border: isSelected
                  ? Border.all(color: primaryColor, width: 2)
                  : null,
            ),
            child: Icon(
              icon,
              color: isSelected
                  ? Colors.white
                  : (isDark ? Colors.grey[400] : Colors.grey[600]),
              size: 24,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSubTimerItem(BuildContext context, TimerItem timer, bool isDark) {
    String typeText;
    switch (timer.type) {
      case TimerType.countUp:
        typeText = TimerLocalizations.of(context).countUpTimer;
        break;
      case TimerType.countDown:
        typeText = TimerLocalizations.of(context).countDownTimer;
        break;
      case TimerType.pomodoro:
        typeText = TimerLocalizations.of(context).pomodoroTimer;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800]!.withValues(alpha: 0.5) : Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.drag_indicator,
            color: isDark ? Colors.grey[600] : Colors.grey[400],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  timer.name.isEmpty ? typeText : timer.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
                Text(
                  _formatDuration(timer.duration),
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey[500] : Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          IconButton(
             icon: const Icon(Icons.edit, size: 20),
             color: isDark ? Colors.grey[500] : Colors.grey[500],
             onPressed: () => _editTimerItem(timer),
          ),
          IconButton(
            icon: const Icon(Icons.delete, size: 20),
            color: isDark ? Colors.grey[500] : Colors.grey[500],
            onPressed: () => setState(() => _timerItems.remove(timer)),
          ),
        ],
      ),
    );
  }

  Future<void> _openFullIconPicker() async {
    final result = await showIconPickerDialog(context, _selectedIcon);
    if (result != null) {
      setState(() {
        _selectedIcon = result;
      });
    }
  }

  Future<void> _showGroupSelector() async {
    final selectedGroup = await showDialog<String>(
      context: context,
      builder: (context) => GroupSelectorDialog(
        groups: widget.groups,
        initialSelectedGroup: _selectedGroup,
        onGroupRenamed: (oldName, newName) {
          setState(() {
            if (_selectedGroup == oldName) {
              _selectedGroup = newName;
            }
          });
        },
        onGroupDeleted: (groupName) {
          setState(() {
            if (_selectedGroup == groupName) {
              _selectedGroup = null;
            }
          });
        },
      ),
    );
    if (selectedGroup != null) {
      setState(() {
        _selectedGroup = selectedGroup;
      });
    }
  }

  void _showAddTimerDialog() {
    showDialog(
      context: context,
      builder: (context) => AddTimerItemDialog(),
    ).then((editedTimer) {
      if (editedTimer != null) {
        setState(() => _timerItems.add(editedTimer));
      }
    });
  }

  void _editTimerItem(TimerItem timer) {
    final index = _timerItems.indexOf(timer);
    showDialog(
      context: context,
      builder: (context) => AddTimerItemDialog(initialItem: timer),
    ).then((editedTimer) {
      if (editedTimer != null) {
        setState(() {
          _timerItems[index] = editedTimer;
        });
      }
    });
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      final task = TimerTask.create(
        id: _id,
        name: _nameController.text,
        color: _selectedColor,
        icon: _selectedIcon,
        timerItems: _timerItems,
        group: _selectedGroup,
        repeatCount: _repeatCount,
        enableNotification: _enableNotification,
      );
      Navigator.of(context).pop(task);
    }
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m';
    } else {
      return '${seconds}s';
    }
  }
}
