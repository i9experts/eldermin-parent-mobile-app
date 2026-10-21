import 'package:get/get.dart';
import '../../../../core/services/parent_api_service.dart';
import '../../../../core/network/api_exception.dart';
import '../../../utils/toast_util.dart';

class EventsController extends GetxController {
  final ParentApiService _api = Get.find<ParentApiService>();

  final loading = false.obs;
  final events = <dynamic>[].obs;
  final RxnString error = RxnString();

  /// The month the events calendar's month picker is currently focused on.
  /// Filtering happens client-side over the already-fetched [events],
  /// matched against each event's real `startDate` field.
  final selectedMonth = DateTime(DateTime.now().year, DateTime.now().month).obs;

  /// Day-of-month tapped on the grid; null shows the whole month's events.
  final RxnInt selectedDay = RxnInt();

  void changeMonth(DateTime month) {
    selectedMonth.value = DateTime(month.year, month.month);
    selectedDay.value = null;
  }

  void nextMonth() => changeMonth(DateTime(selectedMonth.value.year, selectedMonth.value.month + 1));
  void prevMonth() => changeMonth(DateTime(selectedMonth.value.year, selectedMonth.value.month - 1));

  /// Tapping the selected day again clears the filter.
  void toggleDay(int day) => selectedDay.value = selectedDay.value == day ? null : day;

  static DateTime _dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  /// An event's first and last calendar day (multi-day events like a term
  /// or a holiday block span from startDate to endDate).
  (DateTime, DateTime)? rangeOf(dynamic e) {
    final start = DateTime.tryParse(e['startDate']?.toString() ?? '')?.toLocal();
    if (start == null) return null;
    final end = DateTime.tryParse(e['endDate']?.toString() ?? '')?.toLocal() ?? start;
    final s = _dayOnly(start);
    final en = _dayOnly(end);
    return (s, en.isBefore(s) ? s : en);
  }

  bool _overlapsDay(dynamic e, DateTime day) {
    final r = rangeOf(e);
    if (r == null) return false;
    final d = _dayOnly(day);
    return !d.isBefore(r.$1) && !d.isAfter(r.$2);
  }

  /// Events that touch any day of [month].
  List<dynamic> eventsInMonth(DateTime month) {
    final first = DateTime(month.year, month.month, 1);
    final last = DateTime(month.year, month.month + 1, 0);
    return events.where((e) {
      final r = rangeOf(e);
      return r != null && !r.$1.isAfter(last) && !r.$2.isBefore(first);
    }).toList();
  }

  List<dynamic> eventsOnDay(DateTime month, int day) =>
      eventsInMonth(month).where((e) => _overlapsDay(e, DateTime(month.year, month.month, day))).toList();

  Set<int> daysWithEvents(DateTime month) {
    final days = <int>{};
    final last = DateTime(month.year, month.month + 1, 0).day;
    for (final e in eventsInMonth(month)) {
      for (var d = 1; d <= last; d++) {
        if (_overlapsDay(e, DateTime(month.year, month.month, d))) days.add(d);
      }
    }
    return days;
  }

  @override
  void onInit() {
    super.onInit();
    fetch();
  }

  Future<void> fetch() async {
    loading.value = true;
    error.value = null;
    try {
      events.value = await _api.getEvents();
    } on ApiException catch (e) {
      error.value = e.message;
      ToastUtil.showToast(e.message);
    } finally {
      loading.value = false;
    }
  }
}
