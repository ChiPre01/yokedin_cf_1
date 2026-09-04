import 'package:yoked_in/chat/message_model.dart';

String formatDateHeader(DateTime? date) {
  // Use current time if date is null (for new messages)
  final messageDate = date ?? DateTime.now();

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = today.subtract(const Duration(days: 1));
  final msgDate = DateTime(
    messageDate.year,
    messageDate.month,
    messageDate.day,
  );

  if (msgDate == today) {
    return 'Today';
  } else if (msgDate == yesterday) {
    return 'Yesterday';
  } else if (now.difference(messageDate).inDays < 7) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return days[messageDate.weekday - 1];
  } else {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${messageDate.day} ${months[messageDate.month - 1]}';
  }
}
// shouldShowDateHeader

bool shouldShowDateHeader(List<MessageModel> messages, int index) {
  if (index == messages.length - 1) return true;

  final currentMessage = messages[index];
  final nextMessage = messages[index + 1];

  // Treat null timestamps as current time (today)
  final currentTime = currentMessage.timestamp ?? DateTime.now();
  final nextTime = nextMessage.timestamp ?? DateTime.now();

  final currentDate = DateTime(
    currentTime.year,
    currentTime.month,
    currentTime.day,
  );
  final nextDate = DateTime(nextTime.year, nextTime.month, nextTime.day);

  return currentDate != nextDate;
}
// bool shouldShowDateHeader(List<MessageModel> messages, int index) {
//   // For reversed ListView, index 0 is the latest message
//   if (index == 0) return true;

//   final currentMessage = messages[index];
//   final previousMessage = messages[index - 1];

//   final currentTime = currentMessage.timestamp ?? DateTime.now();
//   final previousTime = previousMessage.timestamp ?? DateTime.now();

//   final currentDate = DateTime(
//     currentTime.year,
//     currentTime.month,
//     currentTime.day,
//   );

//   final previousDate = DateTime(
//     previousTime.year,
//     previousTime.month,
//     previousTime.day,
//   );

//   return currentDate != previousDate;
// }
