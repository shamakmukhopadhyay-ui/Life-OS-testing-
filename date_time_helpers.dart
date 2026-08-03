/// Pure, stateless date/time helpers — no Flutter widgets, no database,
/// no side effects. Used by the Home dashboard for today's date and a
/// time-of-day greeting, but kept feature-agnostic in `core/utils` so any
/// other feature needing the same formatting later doesn't duplicate it.
library;

/// Returns "Good Morning" / "Good Afternoon" / "Good Evening" for the
/// given 24-hour clock hour.
String greetingForHour(int hour) {
  if (hour < 12) return 'Good Morning';
  if (hour < 17) return 'Good Afternoon';
  return 'Good Evening';
}

const List<String> _weekdayNames = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

const List<String> _monthNames = [
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

/// Formats a date as e.g. "Saturday, July 11".
String formatFullDate(DateTime date) {
  final weekday = _weekdayNames[date.weekday - 1];
  final month = _monthNames[date.month - 1];
  return '$weekday, $month ${date.day}';
}

/// Formats the time-of-day portion of a [DateTime] as e.g. "6:30 PM".
/// Used for a task's optional due time.
String formatTime(DateTime time) {
  final hour24 = time.hour;
  final minute = time.minute.toString().padLeft(2, '0');
  final period = hour24 >= 12 ? 'PM' : 'AM';
  final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
  return '$hour12:$minute $period';
}

/// Formats a date as e.g. "Jul 25, 2026" — compact and year-inclusive.
///
/// Sprint 16, added for Documents' "last modified" labels. Neither
/// existing formatter above fits: [formatFullDate] omits the year
/// (fine for Home's "today" context, where the year is implicit, but
/// not for a document that could have been modified last year) and
/// includes a full weekday name, which is more than a small list-row
/// label needs.
String formatCompactDate(DateTime date) {
  const monthAbbr = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${monthAbbr[date.month - 1]} ${date.day}, ${date.year}';
}
