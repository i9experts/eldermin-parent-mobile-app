/// Date / money formatting shared by the record detail sheets.
const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

/// "5 Nov 2026".
String formatDay(DateTime d) => '${d.day} ${_months[d.month - 1]} ${d.year}';

/// [formatDay] of an ISO string, or null when it is missing / unparsable. [utcDay] keeps the UTC calendar date (a date-only value stored as
/// midnight UTC), otherwise the date is shown in local time.
String? formatDayOf(Object? iso, {bool utcDay = false}) {
  final d = DateTime.tryParse(iso?.toString() ?? '');
  if (d == null) return null;
  return formatDay(utcDay ? d.toUtc() : d.toLocal());
}

/// "Feb 2025" from "2025-02", or null.
String? formatMonthOf(Object? yyyyMm) {
  final m = RegExp(r'^(\d{4})-(\d{1,2})').firstMatch(yyyyMm?.toString() ?? '');
  if (m == null) return null;
  final i = int.parse(m.group(2)!);
  return i < 1 || i > 12 ? null : '${_months[i - 1]} ${m.group(1)}';
}

/// "Rs 5000" (no decimals for whole amounts, two otherwise).
String formatMoney(num v, {String currency = 'Rs'}) => '$currency ${v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2)}';
