import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/note.dart';

class NoteCard extends StatelessWidget {
  final Note note;
  final VoidCallback onTap;

  const NoteCard({
    super.key,
    required this.note,
    required this.onTap,
  });

  // Pastel colors from the HTML reference
  static const List<Map<String, Color>> _colors = [
    // Greenish
    {'light': Color(0xFFDCFCE7), 'dark': Color(0xFF163A24), 'text': Color(0xFF14532D), 'textDark': Color(0xFFBBF7D0)},
    // Yellowish
    {'light': Color(0xFFFEF9C3), 'dark': Color(0xFF423910), 'text': Color(0xFF713F12), 'textDark': Color(0xFFFDE047)},
    // Pinkish
    {'light': Color(0xFFFFE4E6), 'dark': Color(0xFF521319), 'text': Color(0xFF881337), 'textDark': Color(0xFFFECDD3)},
    // Bluish
    {'light': Color(0xFFE0E7FF), 'dark': Color(0xFF1E284C), 'text': Color(0xFF3730A3), 'textDark': Color(0xFFC7D2FE)},
    // Purpleish
    {'light': Color(0xFFFAE8FF), 'dark': Color(0xFF43194A), 'text': Color(0xFF701A75), 'textDark': Color(0xFFF5D0FE)},
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Deterministic color based on note ID hash
    final colorIndex = note.id.hashCode.abs() % _colors.length;
    final colorSet = _colors[colorIndex];
    
    final bgColor = isDark ? colorSet['dark']! : colorSet['light']!;
    final textColor = isDark ? colorSet['textDark']! : colorSet['text']!;
    final subTextColor = isDark ? colorSet['textDark']!.withOpacity(0.7) : colorSet['text']!.withOpacity(0.7);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image placeholder - if we had image support in Note, we'd parse it here.
            // For now, we'll skip the image part unless we parse markdown for image links.
            
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    note.title.isEmpty ? 'No Title' : note.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    note.content,
                    maxLines: 8, // Allow more lines for masonry feel
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      color: subTextColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: [
                      if (note.tags.isNotEmpty)
                        ...note.tags.take(3).map((tag) => _buildChip(tag, textColor, isDark)),
                      if (note.tags.isEmpty)
                         _buildDateChip(note.updatedAt, textColor, isDark),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(String label, Color textColor, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.label_outline, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateChip(DateTime date, Color textColor, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.calendar_today, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(
            DateFormat('MMM d').format(date),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
