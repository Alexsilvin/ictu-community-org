String timeAgo(DateTime? dateTime) {
  if (dateTime == null) return '—';
  final diff = DateTime.now().difference(dateTime);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
  if (diff.inHours < 24) return '${diff.inHours} hours ago';
  if (diff.inDays < 7) return '${diff.inDays} days ago';
  final weeks = (diff.inDays / 7).floor();
  return '$weeks weeks ago';
}

String dueInText(DateTime deadline) {
  final diff = deadline.difference(DateTime.now());
  if (diff.isNegative) {
    final overdue = diff.abs();
    final days = overdue.inDays;
    final hours = overdue.inHours % 24;
    return 'Overdue by ${days}d ${hours}h';
  }
  final days = diff.inDays;
  final hours = diff.inHours % 24;
  return 'Due in $days days, $hours hours';
}

