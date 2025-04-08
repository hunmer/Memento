import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../l10n/chat_localizations.dart';

class DateFormatter {
  static String formatDateTime(DateTime dateTime, BuildContext context) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    final l10n = ChatLocalizations.of(context)!;
    if (difference.inMinutes < 1) {
      return l10n.justNow;
    } else if (difference.inHours < 1) {
      return l10n.minutesAgo(difference.inMinutes);
    } else if (difference.inDays < 1) {
      return l10n.hoursAgo(difference.inHours);
    } else if (difference.inDays < 7) {
      return l10n.daysAgo(difference.inDays);
    } else {
      final DateFormat formatter = DateFormat('MM-dd HH:mm');
      return formatter.format(dateTime);
    }
  }
}