import 'package:flutter/material.dart';

/// 笔记列表卡片示例
class NotesListCardExample extends StatelessWidget {
  const NotesListCardExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('笔记列表卡片')),
      body: Container(
        color: isDark ? Colors.black : const Color(0xFFF2F2F7),
        child: const Center(
          child: NotesListCardWidget(
            notes: [
              NoteItem(
                title: 'Things to do in San Francisco',
                time: '8:12 AM',
                preview: 'San Francisco is a beautiful city with...',
                imageUrl:
                    'https://lh3.googleusercontent.com/aida-public/AB6AXuBykhyLQimYqgyqS7FAuZ85nBHtlSQUB_5dhHrI-q1jPlOTgTQL6KlVk6_hjzXy7qucN9kjhtEt924uP2WJpCSH03hMy0fQPzD_fNwuv0LddeoHfOtyehH2H0bgF-sm_ih6urXvD8hqSo7msdnOILRVWbDq3aQKSGSsXLFEgEP08f3Ywq49KY2XFbJHgrNGDlyTGezM_vDJ9Dc6-yybzXvNVtcv04ESHRjLJkT1K6Call5PufNQLUy7zyBdNUEmaPs3I9upyYTreg',
              ),
              NoteItem(
                title: 'The Best Places to Visit in Paris',
                time: 'Yesterday',
                preview: 'Paris is a city of love, romance...',
                imageUrl:
                    'https://lh3.googleusercontent.com/aida-public/AB6AXuAGQPD1Xp3dSJRxZPEHVjuJ6vKuTsdkjLexjj39r0wDPXma9pcKM7PIzj093abx_AFfcksbZwBcCO-nbXEL2SMCyB3B5O-ZDmZRWXKOPs9vddGAEKIf_t41jwL9dFD04mVLck3xYDPZKya_p7GWtKGh8J76hhhpLc8PTE-y-hnCqn3xXCmw5gJajThTnFbD-T6wkAOTeniQ-JLrlhgdPWitT4M2cwWGAYhgRFiFSovPWdlEGAdveRbIXjKmQUugEYkrrsCZXEsVdw',
              ),
              NoteItem(
                title: 'How to Write a Clear and Concise Emails',
                time: '6/4/24',
                preview: 'Email is a powerful tool that can be used...',
              ),
              NoteItem(
                title: 'The Importance of Taking Notes',
                time: '6/2/24',
                preview: 'Taking notes is an important skill that ca...',
              ),
              NoteItem(
                title: 'Designing for Accessibility',
                time: '5/31/24',
                preview: 'Accessibility is important for all users...',
              ),
              NoteItem(
                title: 'User Research Findings',
                time: '5/31/24',
                preview: 'Users want to be able to customize the...',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 笔记数据模型
class NoteItem {
  final String title;
  final String time;
  final String preview;
  final String? imageUrl;

  const NoteItem({
    required this.title,
    required this.time,
    required this.preview,
    this.imageUrl,
  });
}

/// 笔记列表卡片小组件
class NotesListCardWidget extends StatefulWidget {
  final List<NoteItem> notes;

  const NotesListCardWidget({
    super.key,
    required this.notes,
  });

  @override
  State<NotesListCardWidget> createState() => _NotesListCardWidgetState();
}

class _NotesListCardWidgetState extends State<NotesListCardWidget>
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

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - _animation.value)),
            child: Container(
              width: 360,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildHeader(context, isDark),
                  _buildDivider(isDark),
                  ...List.generate(widget.notes.length, (index) {
                    if (index > 0) {
                      return _buildNoteItem(
                        context,
                        widget.notes[index],
                        index,
                        hasDivider: true,
                        isDark: isDark,
                      );
                    }
                    return _buildNoteItem(
                      context,
                      widget.notes[index],
                      index,
                      hasDivider: true,
                      isDark: isDark,
                    );
                  }),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFC107),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.folder_open,
            color: Colors.white,
            size: 24,
          ),
          const SizedBox(width: 10),
          Text(
            'Notes',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Container(
      height: 2,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
            width: 2,
          ),
        ),
        // 使用虚线效果
      ),
      child: CustomPaint(
        painter: _DashedLinePainter(
          color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
        ),
      ),
    );
  }

  Widget _buildNoteItem(
    BuildContext context,
    NoteItem note,
    int index, {
    required bool hasDivider,
    required bool isDark,
  }) {
    // 计算每个元素的延迟动画
    final itemAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Interval(
        index * 0.1,
        0.5 + index * 0.1,
        curve: Curves.easeOutCubic,
      ),
    );

    return AnimatedBuilder(
      animation: itemAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: itemAnimation.value,
          child: Transform.translate(
            offset: Offset(0, 10 * (1 - itemAnimation.value)),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: hasDivider
                    ? Border(
                        bottom: BorderSide(
                          color: isDark
                              ? Colors.grey.shade800.withOpacity(0.5)
                              : Colors.grey.shade200,
                          width: 1,
                        ),
                      )
                    : null,
              ),
              child: InkWell(
                onTap: () {
                  // 点击处理
                },
                borderRadius: BorderRadius.circular(8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            note.title,
                            style: TextStyle(
                              color: isDark ? Colors.grey.shade100 : Colors.grey.shade900,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              height: 1.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${note.time} ${note.preview}',
                            style: TextStyle(
                              color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
                              fontSize: 12,
                              height: 1.4,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (note.imageUrl != null) ...[
                      const SizedBox(width: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          note.imageUrl!,
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// 虚线绘制器
class _DashedLinePainter extends CustomPainter {
  final Color color;

  _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    const dashWidth = 5.0;
    const dashSpace = 5.0;
    double startX = 0;

    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, size.height / 2),
        Offset(startX + dashWidth, size.height / 2),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
