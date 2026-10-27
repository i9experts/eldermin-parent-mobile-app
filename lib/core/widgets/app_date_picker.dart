import 'package:flutter/material.dart';
import '../utils/greeting.dart';
import '../design/design.dart';
import 'app_widgets.dart' show AppTag, AppTintIconButton;

/// The month / date / weekday pickers, shown in the kit's [EmBottomSheet] (surface, 28 dp top radius, drag handle) with
/// kit tokens. Behaviour is unchanged: same signatures, same results, same bounds rules.

/// Title row (with a close button) and body inside the sheet.
class _PickerSheetShell extends StatelessWidget {
  final String title;
  final Widget child;
  const _PickerSheetShell({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(EmSpacing.s24, EmSpacing.s8, EmSpacing.s24, EmSpacing.s24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(child: Semantics(header: true, child: Text(title, style: EmType.heading.copyWith(color: EmColors.ink)))),
                AppTintIconButton(icon: Icons.close_rounded, semanticLabel: 'Close', onTap: () => Navigator.of(context).pop()),
              ],
            ),
            const SizedBox(height: EmSpacing.s12),
            Flexible(child: SingleChildScrollView(child: child)),
          ],
        ),
      ),
    );
  }
}

Widget _navHeader({
  required String label,
  required VoidCallback? onPrev,
  required VoidCallback? onNext,
}) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      AppTintIconButton(icon: Icons.chevron_left_rounded, semanticLabel: 'Previous', onTap: onPrev),
      Flexible(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: EmType.bodyLarge.copyWith(color: EmColors.ink))),
      AppTintIconButton(icon: Icons.chevron_right_rounded, semanticLabel: 'Next', onTap: onNext),
    ],
  );
}

Widget _todayButton(String label, VoidCallback? onTap) {
  return Padding(
    padding: const EdgeInsetsDirectional.only(top: EmSpacing.s8),
    child: Center(child: EmTextAction(label: label, onPressed: onTap)),
  );
}

const _monthNames = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];
const _monthShort = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];
const _weekdayNames = [
  'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday',
];
const _weekdayShort = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

bool _monthWithinBounds(int year, int month, DateTime? min, DateTime? max) {
  final v = year * 12 + month;
  if (min != null && v < min.year * 12 + min.month) return false;
  if (max != null && v > max.year * 12 + max.month) return false;
  return true;
}

/// Opens a month/year picker as a bottom sheet. Returns the first day of the chosen month, or null if dismissed.
Future<DateTime?> showAppMonthPicker(
  BuildContext context, {
  required DateTime initialMonth,
  DateTime? minMonth,
  DateTime? maxMonth,
}) {
  return EmBottomSheet.showPanel<DateTime>(
    context,
    builder: (ctx) => _AppMonthPickerSheet(initialMonth: initialMonth, minMonth: minMonth, maxMonth: maxMonth),
  );
}

class _AppMonthPickerSheet extends StatefulWidget {
  final DateTime initialMonth;
  final DateTime? minMonth;
  final DateTime? maxMonth;
  const _AppMonthPickerSheet({required this.initialMonth, this.minMonth, this.maxMonth});

  @override
  State<_AppMonthPickerSheet> createState() => _AppMonthPickerSheetState();
}

class _AppMonthPickerSheetState extends State<_AppMonthPickerSheet> {
  late int _displayedYear;

  @override
  void initState() {
    super.initState();
    _displayedYear = widget.initialMonth.year;
  }

  bool get _canGoPrevYear => widget.minMonth == null || _displayedYear - 1 >= widget.minMonth!.year;
  bool get _canGoNextYear => widget.maxMonth == null || _displayedYear + 1 <= widget.maxMonth!.year;

  @override
  Widget build(BuildContext context) {
    final now = uiNow();
    return _PickerSheetShell(
      title: 'Select month',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _navHeader(
            label: '$_displayedYear',
            onPrev: _canGoPrevYear ? () => setState(() => _displayedYear--) : null,
            onNext: _canGoNextYear ? () => setState(() => _displayedYear++) : null,
          ),
          const SizedBox(height: EmSpacing.s12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 12,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: 1.9),
            itemBuilder: (context, i) {
              final month = i + 1;
              final enabled = _monthWithinBounds(_displayedYear, month, widget.minMonth, widget.maxMonth);
              final isSelected = _displayedYear == widget.initialMonth.year && month == widget.initialMonth.month;
              final isCurrent = _displayedYear == now.year && month == now.month;
              return Semantics(
                button: true,
                selected: isSelected,
                enabled: enabled,
                label: '${_monthNames[i]} $_displayedYear',
                excludeSemantics: true,
                onTap: enabled ? () => Navigator.of(context).pop(DateTime(_displayedYear, month, 1)) : null,
                child: Material(
                  color: isSelected ? EmColors.primary : EmColors.background,
                  shape: RoundedRectangleBorder(
                    borderRadius: EmRadius.mdAll,
                    side: isCurrent && !isSelected ? const BorderSide(color: EmColors.primary, width: 2) : BorderSide.none,
                  ),
                  child: InkWell(
                    borderRadius: EmRadius.mdAll,
                    onTap: enabled ? () => Navigator.of(context).pop(DateTime(_displayedYear, month, 1)) : null,
                    child: Center(
                      child: Text(
                        _monthShort[i],
                        style: EmType.label.copyWith(color: !enabled ? EmColors.onDisabled : (isSelected ? EmColors.onPrimary : EmColors.ink)),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          _todayButton(
            'Jump to this month',
            _monthWithinBounds(now.year, now.month, widget.minMonth, widget.maxMonth) ? () => Navigator.of(context).pop(DateTime(now.year, now.month, 1)) : null,
          ),
        ],
      ),
    );
  }
}

/// Opens a day-level calendar picker as a bottom sheet (used in place of Flutter's default date picker). Returns the
/// picked date, or null if dismissed.
Future<DateTime?> showAppDatePicker(
  BuildContext context, {
  required DateTime initialDate,
  DateTime? firstDate,
  DateTime? lastDate,
}) {
  return EmBottomSheet.showPanel<DateTime>(
    context,
    builder: (ctx) => _AppDatePickerSheet(initialDate: initialDate, firstDate: firstDate, lastDate: lastDate),
  );
}

class _AppDatePickerSheet extends StatefulWidget {
  final DateTime initialDate;
  final DateTime? firstDate;
  final DateTime? lastDate;
  const _AppDatePickerSheet({required this.initialDate, this.firstDate, this.lastDate});

  @override
  State<_AppDatePickerSheet> createState() => _AppDatePickerSheetState();
}

class _AppDatePickerSheetState extends State<_AppDatePickerSheet> {
  late DateTime _displayedMonth;

  @override
  void initState() {
    super.initState();
    _displayedMonth = DateTime(widget.initialDate.year, widget.initialDate.month);
  }

  bool get _canGoPrev =>
      _monthWithinBounds(_displayedMonth.year, _displayedMonth.month - 1 == 0 ? 12 : _displayedMonth.month - 1, widget.firstDate, widget.lastDate) ||
      widget.firstDate == null;
  bool get _canGoNext =>
      widget.lastDate == null || (_displayedMonth.year * 12 + _displayedMonth.month) < (widget.lastDate!.year * 12 + widget.lastDate!.month);

  bool _dayEnabled(DateTime d) {
    if (widget.firstDate != null && d.isBefore(DateTime(widget.firstDate!.year, widget.firstDate!.month, widget.firstDate!.day))) {
      return false;
    }
    if (widget.lastDate != null && d.isAfter(DateTime(widget.lastDate!.year, widget.lastDate!.month, widget.lastDate!.day))) {
      return false;
    }
    return true;
  }

  void _shiftMonth(int delta) {
    setState(() {
      final total = _displayedMonth.year * 12 + (_displayedMonth.month - 1) + delta;
      _displayedMonth = DateTime(total ~/ 12, total % 12 + 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final now = uiNow();
    final today = DateTime(now.year, now.month, now.day);
    final daysInMonth = DateTime(_displayedMonth.year, _displayedMonth.month + 1, 0).day;
    final leadingBlanks = DateTime(_displayedMonth.year, _displayedMonth.month, 1).weekday - 1;
    final todayEnabled = _dayEnabled(today);

    return _PickerSheetShell(
      title: 'Select date',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _navHeader(
            label: '${_monthNames[_displayedMonth.month - 1]} ${_displayedMonth.year}',
            onPrev: _canGoPrev ? () => _shiftMonth(-1) : null,
            onNext: _canGoNext ? () => _shiftMonth(1) : null,
          ),
          const SizedBox(height: EmSpacing.s8),
          Row(
            children: [
              for (final d in _weekdayShort)
                Expanded(child: Center(child: Text(d, style: EmType.caption.copyWith(color: EmColors.textSecondary, fontWeight: FontWeight.w600)))),
            ],
          ),
          const SizedBox(height: EmSpacing.s4),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: leadingBlanks + daysInMonth,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, mainAxisSpacing: 4, crossAxisSpacing: 4),
            itemBuilder: (context, i) {
              if (i < leadingBlanks) return const SizedBox.shrink();
              final day = i - leadingBlanks + 1;
              final date = DateTime(_displayedMonth.year, _displayedMonth.month, day);
              final isToday = date == today;
              final isSelected = date.year == widget.initialDate.year && date.month == widget.initialDate.month && date.day == widget.initialDate.day;
              final enabled = _dayEnabled(date);
              return Semantics(
                button: true,
                selected: isSelected,
                enabled: enabled,
                label: '$day ${_monthNames[_displayedMonth.month - 1]} ${_displayedMonth.year}',
                excludeSemantics: true,
                onTap: enabled ? () => Navigator.of(context).pop(date) : null,
                child: Material(
                  color: isSelected ? EmColors.primary : Colors.transparent,
                  shape: CircleBorder(side: isToday && !isSelected ? const BorderSide(color: EmColors.primary, width: 2) : BorderSide.none),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: enabled ? () => Navigator.of(context).pop(date) : null,
                    child: Center(
                      child: Text(
                        '$day',
                        style: EmType.label.copyWith(
                          fontWeight: isToday || isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: !enabled ? EmColors.onDisabled : (isSelected ? EmColors.onPrimary : EmColors.ink),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          _todayButton('Jump to today', todayEnabled ? () => Navigator.of(context).pop(today) : null),
        ],
      ),
    );
  }
}

/// Opens a day-of-week picker (Mon-Sun) as a bottom sheet - for data that is a single already-loaded weekly structure
/// (e.g. a timetable), so picking means "which weekday of the fetched week to view". Returns a 0 (Monday) - 6 (Sunday) index.
Future<int?> showAppWeekdayPicker(
  BuildContext context, {
  required int initialWeekday,
}) {
  return EmBottomSheet.showPanel<int>(context, builder: (ctx) => _AppWeekdayPickerSheet(initialWeekday: initialWeekday));
}

class _AppWeekdayPickerSheet extends StatelessWidget {
  final int initialWeekday;
  const _AppWeekdayPickerSheet({required this.initialWeekday});

  @override
  Widget build(BuildContext context) {
    final todayIndex = uiNow().weekday - 1;
    return _PickerSheetShell(
      title: 'Select day',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < 7; i++)
            Padding(
              padding: const EdgeInsetsDirectional.only(bottom: EmSpacing.s4),
              child: Material(
                color: i == initialWeekday ? EmColors.primaryTint : Colors.transparent,
                borderRadius: EmRadius.mdAll,
                child: InkWell(
                  key: Key('weekday_$i'),
                  borderRadius: EmRadius.mdAll,
                  onTap: () => Navigator.of(context).pop(i),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: EmSpacing.minTouch),
                    child: Padding(
                      padding: const EdgeInsetsDirectional.symmetric(horizontal: EmSpacing.s12, vertical: EmSpacing.s8),
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(_weekdayNames[i], style: EmType.bodyLarge.copyWith(color: EmColors.ink, fontWeight: i == initialWeekday ? FontWeight.w700 : FontWeight.w500)),
                          ),
                          if (i == todayIndex) ...[const SizedBox(width: EmSpacing.s8), const AppTag('Today')],
                          const Spacer(),
                          if (i == initialWeekday) const Icon(Icons.check_rounded, size: 20, color: EmColors.primary),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
