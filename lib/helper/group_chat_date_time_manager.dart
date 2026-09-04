
import 'package:intl/intl.dart';
import 'package:yoked_in/group_chat/group_chat_model.dart';

String getDateLabel(DateTime dateTime) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = today.subtract(const Duration(days: 1));
  final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

  if (messageDate == today) {
    return 'Today';
  } else if (messageDate == yesterday) {
    return 'Yesterday';
  } else if (messageDate.isAfter(today.subtract(const Duration(days: 7)))) {
    // Within last 7 days - show day name
    final dayNames = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return dayNames[dateTime.weekday - 1];
  } else {
    // Older than 7 days - show full date
    return DateFormat('MMMM d').format(dateTime); // e.g., "December 12"
  }
}

// Helper to check if we should show date separator for group message
bool shouldShowDateSeparator(
  int currentIndex,
  List<GroupMessageModel> messages,
) {
  if (currentIndex == messages.length - 1) {
    return true; // Always show for last message
  }

  final currentMsg = messages[currentIndex];
  final nextMsg = messages[currentIndex + 1];

  final currentDate = DateTime(
    currentMsg.timestamp!.year,
    currentMsg.timestamp!.month,
    currentMsg.timestamp!.day,
  );
  final nextDate = DateTime(
    nextMsg.timestamp!.year,
    nextMsg.timestamp!.month,
    nextMsg.timestamp!.day,
  );

  return currentDate != nextDate;
}
