/// "Good morning" (05:00-11:59), "Good afternoon" (12:00-16:59), else "Good evening" (same rule as the teacher app).
String greetingFor(DateTime now) {
  final h = now.hour;
  if (h >= 5 && h < 12) return 'Good morning';
  if (h >= 12 && h < 17) return 'Good afternoon';
  return 'Good evening';
}

/// "Now" for the greeting and the date line. A plain function so widget tests and goldens can pin the clock.
DateTime Function() uiNow = DateTime.now;
