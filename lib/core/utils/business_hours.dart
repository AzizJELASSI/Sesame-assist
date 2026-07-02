// ─── SEASAME Assist-Pro — Business Hours Utility ──────────────────────────────
// Mon–Fri, 08:00–18:00 (device local time).
// All DateTime inputs/outputs are treated as local time.

class BusinessHours {
  static const int _dayStart = 8;  // inclusive
  static const int _dayEnd   = 18; // exclusive (18:00 = end of business day)

  // ── helpers ───────────────────────────────────────────────────────────────

  static bool _isWeekend(DateTime dt) =>
      dt.weekday == DateTime.saturday || dt.weekday == DateTime.sunday;

  /// Returns [dt] snapped forward to the next business-hours moment.
  /// If [dt] is already within business hours it is returned unchanged.
  static DateTime snapToBusinessHours(DateTime dt) {
    // Skip weekends
    while (_isWeekend(dt)) {
      dt = _startOfDay(dt.add(const Duration(days: 1)));
    }
    // Before business hours → start of business day
    if (dt.hour < _dayStart) {
      dt = DateTime(dt.year, dt.month, dt.day, _dayStart, 0, 0);
    }
    // After or exactly at end of business hours → start of next business day
    if (dt.hour >= _dayEnd) {
      dt = _startOfDay(dt.add(const Duration(days: 1)));
      return snapToBusinessHours(dt); // recurse to skip potential weekend
    }
    return dt;
  }

  static DateTime _startOfDay(DateTime dt) =>
      DateTime(dt.year, dt.month, dt.day, _dayStart, 0, 0);

  static DateTime _endOfDay(DateTime dt) =>
      DateTime(dt.year, dt.month, dt.day, _dayEnd, 0, 0);

  // ── public API ────────────────────────────────────────────────────────────

  /// Adds [hours] business hours to [start].
  /// Returns the absolute DateTime deadline (local time).
  static DateTime addBusinessHours(DateTime start, int hours) {
    DateTime cur = snapToBusinessHours(start.toLocal());
    int minutesLeft = hours * 60;

    while (minutesLeft > 0) {
      final endOfDay = _endOfDay(cur);
      final minutesLeftToday = endOfDay.difference(cur).inMinutes;

      if (minutesLeft <= minutesLeftToday) {
        cur = cur.add(Duration(minutes: minutesLeft));
        minutesLeft = 0;
      } else {
        minutesLeft -= minutesLeftToday;
        // Jump to next business day start
        cur = snapToBusinessHours(endOfDay.add(const Duration(minutes: 1)));
      }
    }
    return cur;
  }

  /// Computes the number of business minutes elapsed between [from] and [to].
  /// [from] must be before or equal to [to].
  static int elapsedBusinessMinutes(DateTime from, DateTime to) {
    from = from.toLocal();
    to   = to.toLocal();
    if (!from.isBefore(to)) return 0;

    DateTime cur = snapToBusinessHours(from);
    int total = 0;

    while (cur.isBefore(to)) {
      if (_isWeekend(cur)) {
        cur = snapToBusinessHours(cur.add(const Duration(days: 1)));
        continue;
      }

      final endOfDay     = _endOfDay(cur);
      final effectiveEnd = to.isBefore(endOfDay) ? to : endOfDay;

      if (cur.isBefore(effectiveEnd)) {
        total += effectiveEnd.difference(cur).inMinutes;
      }

      cur = snapToBusinessHours(endOfDay.add(const Duration(minutes: 1)));
    }

    return total;
  }

  /// Returns remaining business minutes from [now] to [deadline].
  /// Negative when the deadline has passed.
  static int remainingBusinessMinutes(DateTime now, DateTime deadline) {
    if (now.isAfter(deadline)) {
      return -elapsedBusinessMinutes(deadline, now);
    }
    return elapsedBusinessMinutes(now, deadline);
  }

  /// Human-readable countdown string, e.g. "2h 15m", "45m", "Overdue 3h".
  static String formatRemaining(int remainingMinutes) {
    if (remainingMinutes < 0) {
      final over = -remainingMinutes;
      final h = over ~/ 60;
      final m = over % 60;
      if (h > 0) return 'Overdue ${h}h ${m}m';
      return 'Overdue ${m}m';
    }
    final h = remainingMinutes ~/ 60;
    final m = remainingMinutes % 60;
    if (h > 0 && m > 0) return '${h}h ${m}m';
    if (h > 0) return '${h}h';
    return '${m}m';
  }
}
