import 'package:flutter/material.dart';
import 'package:animated_flip_counter/animated_flip_counter.dart';

/// 任务进度卡片示例
class TaskProgressCardExample extends StatelessWidget {
  const TaskProgressCardExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('任务进度卡片')),
      body: Container(
        color: isDark ? Colors.black : const Color(0xFFF2F2F7),
        child: const Center(
          child: TaskProgressCardWidget(
            title: 'Widgefy UI kit',
            subtitle: 'Graphics design',
            completedTasks: 7,
            totalTasks: 14,
            pendingTasks: [
              'Design search page for website',
              'Send an estimate budget for app',
              'Export assets for HTML developer',
            ],
            commentCount: 4,
            attachmentCount: 1,
            teamAvatars: [
              'https://lh3.googleusercontent.com/aida-public/AB6AXuC2E34rpRUxl41JgmYHEf1632M2dz9F_oHyMn1u_7r-NjLVTdySSTi5s7lu_cTAXGFLmZWp9kT0uLY51magEqProtp768PJrVo02zkPIXWrKsREg4NL-dmmUKOOD4hAfCgMokZmCopqoQt7RKjm7xlbEOYurKcdD3t4hq3PJgacmPs_iH-6oqGeI9TrmiH_yEgv1-T6l-RtbFcZUtoLrHgBuT0h2DvbL4WGT_fYukt5o_Q45rAE60lAnw44mCEIgdY2zbLktTzm4w',
              'https://lh3.googleusercontent.com/aida-public/AB6AXuCNJkHVLv3wQgstyElOSle3RMoSWr-1-UxEnZqmIBu6HVJBFhfwEVxfjSb2EF0y5TOd4smsVGfSs9IMuxBYcWba5SH3ut3dmhIZt4PTJ9lPt9zvKN-1WqcNhn_qh01gVD5mexs_LSv-VKtPHL-uWTAtIZgo6SIZb8VEAqcU4CO0Fjt6T6GoH3RCcJtUC3ydsN6XvV3NEuQ6XoUfBGVz3OIk6fS0gI1PKNBf7GMCpxk18IGtag0TydvjITBc3Hzl_V11JYxf1ZK3eQ',
              'https://lh3.googleusercontent.com/aida-public/AB6AXuDlpM5lz1d7uhYRxL_1Zq-0vrok0JRfmuwmk8k1AH5S0j3On58wmS5sl6qAEY38keWvk6Y3lV5spuIId3ctczvjAHLSffWkMokpQVJtnfFReI0-GAnsAFWuVXBuFWhQnAS843wwP2ejdTd63AdnT8U9WA7bgEXVdzwx2vMLkFoXFc_8srCGXrFi-YMung8i3c_kmxbJHOR55SQTZWvQZmM08P0GHpEcfeC8xe236NTw6HV5HFYaMqT_kN-v5mdmHplJIiv-KL0uNQ',
            ],
          ),
        ),
      ),
    );
  }
}

/// 任务进度数据模型
class TaskProgressData {
  final String title;
  final String subtitle;
  final int completedTasks;
  final int totalTasks;
  final List<String> pendingTasks;
  final int commentCount;
  final int attachmentCount;
  final List<String> teamAvatars;

  const TaskProgressData({
    required this.title,
    required this.subtitle,
    required this.completedTasks,
    required this.totalTasks,
    required this.pendingTasks,
    required this.commentCount,
    required this.attachmentCount,
    required this.teamAvatars,
  });

  double get progress => totalTasks > 0 ? completedTasks / totalTasks : 0;
}

/// 任务进度卡片小组件
class TaskProgressCardWidget extends StatefulWidget {
  final String title;
  final String subtitle;
  final int completedTasks;
  final int totalTasks;
  final List<String> pendingTasks;
  final int commentCount;
  final int attachmentCount;
  final List<String> teamAvatars;

  const TaskProgressCardWidget({
    super.key,
    required this.title,
    required this.subtitle,
    required this.completedTasks,
    required this.totalTasks,
    this.pendingTasks = const [],
    this.commentCount = 0,
    this.attachmentCount = 0,
    this.teamAvatars = const [],
  });

  @override
  State<TaskProgressCardWidget> createState() => _TaskProgressCardWidgetState();
}

class _TaskProgressCardWidgetState extends State<TaskProgressCardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.grey.shade900;
    final secondaryTextColor = isDark ? Colors.grey.shade500 : Colors.grey.shade400;
    final dividerColor = isDark ? const Color(0xFF374151) : const Color(0xFFF3F4F6);
    final progressTrackColor = isDark ? const Color(0xFF374151) : const Color(0xFFF3F4F6);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - _animation.value)),
            child: Container(
              width: 320,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(36),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 标题部分
                  _HeaderSection(
                    title: widget.title,
                    subtitle: widget.subtitle,
                    textColor: textColor,
                    secondaryTextColor: secondaryTextColor,
                    animation: _animation,
                  ),
                  const SizedBox(height: 32),

                  // 进度条部分
                  _ProgressSection(
                    completedTasks: widget.completedTasks,
                    totalTasks: widget.totalTasks,
                    progressTrackColor: progressTrackColor,
                    animation: _animation,
                  ),
                  const SizedBox(height: 32),

                  // 待办任务列表
                  _PendingTasksSection(
                    tasks: widget.pendingTasks,
                    textColor: textColor,
                    secondaryTextColor: secondaryTextColor,
                    dividerColor: dividerColor,
                    animation: _animation,
                  ),
                  const SizedBox(height: 24),

                  // 底部操作栏
                  _ActionBar(
                    commentCount: widget.commentCount,
                    attachmentCount: widget.attachmentCount,
                    teamAvatars: widget.teamAvatars,
                    secondaryTextColor: secondaryTextColor,
                    isDark: isDark,
                    animation: _animation,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// 标题部分
class _HeaderSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color textColor;
  final Color secondaryTextColor;
  final Animation<double> animation;

  const _HeaderSection({
    required this.title,
    required this.subtitle,
    required this.textColor,
    required this.secondaryTextColor,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: animation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: textColor,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: secondaryTextColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// 进度条部分
class _ProgressSection extends StatelessWidget {
  final int completedTasks;
  final int totalTasks;
  final Color progressTrackColor;
  final Animation<double> animation;

  const _ProgressSection({
    required this.completedTasks,
    required this.totalTasks,
    required this.progressTrackColor,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final progress = totalTasks > 0 ? completedTasks / totalTasks : 0;

    final itemAnimation = CurvedAnimation(
      parent: animation,
      curve: const Interval(0.15, 0.75, curve: Curves.easeOutCubic),
    );

    return FadeTransition(
      opacity: itemAnimation,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.format_list_bulleted,
                    size: 18,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Progress',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
              // 使用 AnimatedFlipCounter 显示任务数
              SizedBox(
                height: 20,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 28,
                      height: 18,
                      child: AnimatedFlipCounter(
                        value: completedTasks * itemAnimation.value,
                        textStyle: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                          height: 1.0,
                        ),
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Text(
                      ' / ',
                      style: TextStyle(fontSize: 14),
                    ),
                    SizedBox(
                      width: 28,
                      height: 18,
                      child: AnimatedFlipCounter(
                        value: totalTasks.toDouble(),
                        textStyle: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                          height: 1.0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: progressTrackColor,
              borderRadius: BorderRadius.circular(3),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: progress * itemAnimation.value,
                  child: Container(
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 待办任务列表
class _PendingTasksSection extends StatelessWidget {
  final List<String> tasks;
  final Color textColor;
  final Color secondaryTextColor;
  final Color dividerColor;
  final Animation<double> animation;

  const _PendingTasksSection({
    required this.tasks,
    required this.textColor,
    required this.secondaryTextColor,
    required this.dividerColor,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < tasks.length; i++) ...[
          if (i == 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'Pending',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: secondaryTextColor,
                ),
              ),
            ),
          _TaskItem(
            task: tasks[i],
            textColor: textColor,
            dividerColor: dividerColor,
            showDivider: i < tasks.length - 1,
            animation: animation,
            index: i,
          ),
        ],
      ],
    );
  }
}

/// 任务项
class _TaskItem extends StatelessWidget {
  final String task;
  final Color textColor;
  final Color dividerColor;
  final bool showDivider;
  final Animation<double> animation;
  final int index;

  const _TaskItem({
    required this.task,
    required this.textColor,
    required this.dividerColor,
    required this.showDivider,
    required this.animation,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final itemAnimation = CurvedAnimation(
      parent: animation,
      curve: Interval(
        0.3 + index * 0.12,
        0.75 + index * 0.12,
        curve: Curves.easeOutCubic,
      ),
    );

    return FadeTransition(
      opacity: itemAnimation,
      child: Transform.translate(
        offset: Offset(0, 10 * (1 - itemAnimation.value)),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                task,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                  height: 1.3,
                ),
              ),
            ),
            if (showDivider)
              Container(
                height: 1,
                color: dividerColor,
              ),
          ],
        ),
      ),
    );
  }
}

/// 底部操作栏
class _ActionBar extends StatelessWidget {
  final int commentCount;
  final int attachmentCount;
  final List<String> teamAvatars;
  final Color secondaryTextColor;
  final bool isDark;
  final Animation<double> animation;

  const _ActionBar({
    required this.commentCount,
    required this.attachmentCount,
    required this.teamAvatars,
    required this.secondaryTextColor,
    required this.isDark,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    final itemAnimation = CurvedAnimation(
      parent: animation,
      curve: const Interval(0.5, 0.95, curve: Curves.easeOutCubic),
    );

    return FadeTransition(
      opacity: itemAnimation,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (commentCount > 0) ...[
                _ActionButton(
                  icon: Icons.chat_bubble_outline,
                  count: commentCount,
                  color: secondaryTextColor,
                ),
                const SizedBox(width: 20),
              ],
              if (attachmentCount > 0)
                _ActionButton(
                  icon: Icons.attach_file,
                  count: attachmentCount,
                  color: secondaryTextColor,
                  iconRotation: 45,
                ),
            ],
          ),
          if (teamAvatars.isNotEmpty)
            SizedBox(
              height: 32,
              child: Stack(
                children: [
                  for (int i = teamAvatars.length - 1; i >= 0; i--)
                    Transform.translate(
                      offset: Offset(-i * 12.0, 0),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark ? const Color(0xFF1E293B) : Colors.white,
                            width: 2,
                          ),
                        ),
                        child: ClipOval(
                          child: Image.network(
                            teamAvatars[i],
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey.shade300,
                                child: Icon(
                                  Icons.person,
                                  size: 20,
                                  color: Colors.grey.shade600,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// 操作按钮
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final int count;
  final Color color;
  final double? iconRotation;

  const _ActionButton({
    required this.icon,
    required this.count,
    required this.color,
    this.iconRotation,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Transform.rotate(
          angle: iconRotation != null ? (iconRotation! * 3.14159 / 180) : 0,
          child: Icon(
            icon,
            size: 18,
            color: color,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}
