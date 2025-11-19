import 'package:flutter/material.dart';
import 'dart:io';
import '../models/memorial_day.dart';
import '../l10n/day_localizations.dart';
import '../../../utils/image_utils.dart';

class MemorialDayCard extends StatefulWidget {
  final MemorialDay memorialDay;
  final VoidCallback? onTap;
  final bool isDraggable;

  const MemorialDayCard({
    super.key,
    required this.memorialDay,
    this.onTap,
    this.isDraggable = false,
  });

  @override
  State<MemorialDayCard> createState() => _MemorialDayCardState();
}

class _MemorialDayCardState extends State<MemorialDayCard> {
  ImageProvider? _imageProvider;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(covariant MemorialDayCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.memorialDay.backgroundImageUrl !=
        widget.memorialDay.backgroundImageUrl) {
      _loadImage();
    }
  }

  Future<void> _loadImage() async {
    if (widget.memorialDay.backgroundImageUrl == null) {
      setState(() {
        _imageProvider = null;
      });
      return;
    }

    final url = widget.memorialDay.backgroundImageUrl!;
    if (url.startsWith('http://') || url.startsWith('https://')) {
      setState(() {
        _imageProvider = NetworkImage(url);
      });
    } else {
      try {
        final absolutePath = await ImageUtils.getAbsolutePath(url);
        setState(() {
          _imageProvider = FileImage(File(absolutePath));
        });
      } catch (e) {
        debugPrint('Error loading image: $e');
        setState(() {
          _imageProvider = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = DayLocalizations.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 4,
      child: InkWell(
        onTap: widget.onTap,
        child: Container(
          decoration: BoxDecoration(
            color: widget.memorialDay.backgroundColor,
            image:
                _imageProvider != null
                    ? DecorationImage(image: _imageProvider!, fit: BoxFit.cover)
                    : null,
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.memorialDay.title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        shadows: [
                          const Shadow(
                            offset: Offset(1, 1),
                            blurRadius: 3.0,
                            color: Colors.black45,
                          ),
                        ],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Text(
                      widget.memorialDay.formattedTargetDate,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white,
                        shadows: [
                          const Shadow(
                            offset: Offset(1, 1),
                            blurRadius: 3.0,
                            color: Colors.black45,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.memorialDay.isExpired
                          ? localizations.daysPassed(
                            widget.memorialDay.daysPassed,
                          )
                          : localizations.daysRemaining(
                            widget.memorialDay.daysRemaining,
                          ),
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          const Shadow(
                            offset: Offset(1, 1),
                            blurRadius: 3.0,
                            color: Colors.black45,
                          ),
                        ],
                      ),
                    ),
                    if (widget.memorialDay.notes.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        widget.memorialDay.notes.first,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white,
                          shadows: [
                            const Shadow(
                              offset: Offset(1, 1),
                              blurRadius: 3.0,
                              color: Colors.black45,
                            ),
                          ],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
