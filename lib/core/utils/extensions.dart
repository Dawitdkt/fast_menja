extension DateTimeExtension on DateTime {
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year &&
        month == yesterday.month &&
        day == yesterday.day;
  }

  String toFormattedString() {
    if (isToday) {
      return 'Today at ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
    } else if (isYesterday) {
      return 'Yesterday';
    } else {
      return '${day}/${month}/${year}';
    }
  }
}
