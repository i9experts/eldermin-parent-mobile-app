import 'package:get/get.dart';
import '../../../../core/models/early_years_models.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/services/parent_api_service.dart';
import '../../students/controllers/student_controller.dart';

/// Read-only Early Years for the selected child. Registered once (permanent)
/// in InitialBinding so the "Early Years" tile in More can appear as soon as
/// the summary for the selected child says the child is in an Early Years
/// programme. Everything else (portfolio, shared observations) loads only when
/// the Early Years screen is opened.
///
/// Never calls a staff `/ece/*` route: only the parent-portal early-years
/// endpoints (see ApiConstants.earlyYears*).
///
/// Signed media links expire after about 15 minutes. Lists remember when they
/// were fetched; [refreshIfStale] (screen open / resume) and [onMediaFailed]
/// (an image failed to load) fetch fresh links. Nothing here writes a signed
/// URL to disk.
class EarlyYearsController extends GetxController {
  /// Refetch lists older than this (the server signs for 15 minutes).
  static const mediaTtl = Duration(minutes: 12);
  static const pageSize = 20;
  static const _failRefreshGap = Duration(seconds: 20);

  final ParentApiService _api;
  final StudentController _students;
  final DateTime Function() _now;

  EarlyYearsController({ParentApiService? api, StudentController? students, DateTime Function()? now})
      : _api = api ?? Get.find<ParentApiService>(),
        _students = students ?? Get.find<StudentController>(),
        _now = now ?? DateTime.now;

  // Summary (drives visibility)
  final summary = Rxn<EySummary>();
  final summaryLoading = false.obs;
  String? _summaryFor;

  // Portfolio
  final portfolio = <EyPortfolioEntry>[].obs;
  final portfolioLoading = false.obs;
  final portfolioLoadingMore = false.obs;
  final portfolioHasMore = false.obs;
  final RxnString portfolioError = RxnString();
  final portfolioLoaded = false.obs;
  int _portfolioPage = 0;
  DateTime? _portfolioFetchedAt;

  // Shared observations
  final observations = <EyObservation>[].obs;
  final observationsLoading = false.obs;
  final observationsLoadingMore = false.obs;
  final observationsHasMore = false.obs;
  final RxnString observationsError = RxnString();
  final observationsLoaded = false.obs;
  int _observationsPage = 0;
  DateTime? _observationsFetchedAt;

  // One entry (detail screen refresh)
  final entry = Rxn<EyPortfolioEntry>();
  final entryLoading = false.obs;
  final RxnString entryError = RxnString();

  DateTime? _lastFailRefresh;

  String? get _selectedId => _students.selectedStudent?.id;

  /// True only when the summary we hold is for the selected child and says
  /// the child is in an Early Years programme. Anything else (loading, error,
  /// not an Early Years child) keeps the tile hidden.
  bool get eligible {
    final s = summary.value;
    return s != null && s.isEarlyYears && s.studentId == _selectedId;
  }

  /// Show the shared-observations section when the summary counts any, or
  /// when the list already returned items.
  bool get showObservations => (summary.value?.sharedObservationCount ?? 0) > 0 || observations.isNotEmpty;

  @override
  void onInit() {
    super.onInit();
    ever(_students.selectedId, (_) => _onStudentChanged());
    // The children list arrives over the network after this controller exists.
    ever(_students.students, (_) => _onStudentChanged());
    _onStudentChanged();
  }

  void _onStudentChanged() {
    final id = _selectedId;
    if (id == null || id == _summaryFor) return;
    _clearLists();
    summary.value = null;
    _summaryFor = id;
    loadSummary();
  }

  Future<void> loadSummary() async {
    final id = _selectedId;
    if (id == null) return;
    summaryLoading.value = true;
    try {
      final s = EySummary.fromJson(await _api.getEarlyYearsSummary(id));
      if (_selectedId != id) return; // child changed while loading
      summary.value = s.studentId == id ? s : null;
    } catch (_) {
      // Silent on purpose: any failure (404/403/offline) just keeps Early Years hidden.
      if (_selectedId == id) summary.value = null;
    } finally {
      if (_selectedId == id) summaryLoading.value = false;
    }
  }

  // ── Opening the screen ──────────────────────────────────────
  Future<void> open() async {
    final summaryDone = loadSummary();
    await ensureLists();
    await summaryDone;
  }

  /// Load (or refresh when stale) the lists that matter for the selected child. Safe to call
  /// repeatedly and before the summary exists: it does nothing until the child is eligible, and
  /// never starts a second fetch while one is running. The screen calls it again whenever the
  /// summary changes, so opening the screen before the summary arrives still loads the lists.
  Future<void> ensureLists() async {
    if (!eligible) return;
    await Future.wait([
      if (!portfolioLoading.value && (!portfolioLoaded.value || _isStale(_portfolioFetchedAt))) loadPortfolio(),
      if (showObservations && !observationsLoading.value && (!observationsLoaded.value || _isStale(_observationsFetchedAt))) loadObservations(),
    ]);
  }

  bool _isStale(DateTime? at) => at == null || _now().difference(at) >= mediaTtl;

  /// Re-fetch every list that already loaded and has gone stale (fresh signed links).
  Future<void> refreshIfStale() async {
    await Future.wait([
      if (portfolioLoaded.value && _isStale(_portfolioFetchedAt)) loadPortfolio(),
      if (observationsLoaded.value && _isStale(_observationsFetchedAt)) loadObservations(),
    ]);
  }

  /// An image failed to load (most likely an expired link): fetch fresh links, at most once every 20 s.
  Future<void> onMediaFailed() async {
    final now = _now();
    if (_lastFailRefresh != null && now.difference(_lastFailRefresh!) < _failRefreshGap) return;
    _lastFailRefresh = now;
    await Future.wait([
      if (portfolioLoaded.value) loadPortfolio(silent: true),
      if (observationsLoaded.value) loadObservations(silent: true),
    ]);
  }

  // ── Portfolio ───────────────────────────────────────────────
  Future<void> loadPortfolio({bool silent = false}) async {
    final id = _selectedId;
    if (id == null) return;
    if (!silent) portfolioLoading.value = true;
    portfolioError.value = null;
    try {
      final page = EyPage.parse(await _api.getEarlyYearsPortfolio(id, page: 1, limit: pageSize),
          EyPortfolioEntry.fromJson, (e) => e.id);
      if (_selectedId != id) return;
      portfolio.assignAll(page.items);
      _portfolioPage = 1;
      portfolioHasMore.value = page.hasMore;
      portfolioLoaded.value = true;
      _portfolioFetchedAt = _now();
    } on ApiException catch (e) {
      if (_selectedId == id && !silent) portfolioError.value = messageFor(e);
    } catch (_) {
      if (_selectedId == id && !silent) portfolioError.value = 'Something went wrong. Please try again.';
    } finally {
      if (_selectedId == id) portfolioLoading.value = false;
    }
  }

  Future<void> loadMorePortfolio() async {
    final id = _selectedId;
    if (id == null || !portfolioHasMore.value || portfolioLoadingMore.value || portfolioLoading.value) return;
    portfolioLoadingMore.value = true;
    try {
      final page = EyPage.parse(await _api.getEarlyYearsPortfolio(id, page: _portfolioPage + 1, limit: pageSize),
          EyPortfolioEntry.fromJson, (e) => e.id);
      if (_selectedId != id) return;
      final known = portfolio.map((e) => e.id).toSet();
      portfolio.addAll(page.items.where((e) => !known.contains(e.id)));
      _portfolioPage += 1;
      portfolioHasMore.value = page.hasMore;
    } on ApiException catch (e) {
      portfolioError.value = messageFor(e);
    } catch (_) {
      portfolioError.value = 'Something went wrong. Please try again.';
    } finally {
      portfolioLoadingMore.value = false;
    }
  }

  // ── Shared observations ─────────────────────────────────────
  Future<void> loadObservations({bool silent = false}) async {
    final id = _selectedId;
    if (id == null) return;
    if (!silent) observationsLoading.value = true;
    observationsError.value = null;
    try {
      final page = EyPage.parse(await _api.getEarlyYearsObservations(id, page: 1, limit: pageSize),
          EyObservation.fromJson, (e) => e.id);
      if (_selectedId != id) return;
      observations.assignAll(page.items);
      _observationsPage = 1;
      observationsHasMore.value = page.hasMore;
      observationsLoaded.value = true;
      _observationsFetchedAt = _now();
    } on ApiException catch (e) {
      if (_selectedId == id && !silent) observationsError.value = messageFor(e);
    } catch (_) {
      if (_selectedId == id && !silent) observationsError.value = 'Something went wrong. Please try again.';
    } finally {
      if (_selectedId == id) observationsLoading.value = false;
    }
  }

  Future<void> loadMoreObservations() async {
    final id = _selectedId;
    if (id == null || !observationsHasMore.value || observationsLoadingMore.value || observationsLoading.value) return;
    observationsLoadingMore.value = true;
    try {
      final page = EyPage.parse(await _api.getEarlyYearsObservations(id, page: _observationsPage + 1, limit: pageSize),
          EyObservation.fromJson, (e) => e.id);
      if (_selectedId != id) return;
      final known = observations.map((e) => e.id).toSet();
      observations.addAll(page.items.where((e) => !known.contains(e.id)));
      _observationsPage += 1;
      observationsHasMore.value = page.hasMore;
    } on ApiException catch (e) {
      observationsError.value = messageFor(e);
    } catch (_) {
      observationsError.value = 'Something went wrong. Please try again.';
    } finally {
      observationsLoadingMore.value = false;
    }
  }

  // ── One entry (fresh links for the detail screen) ───────────
  Future<void> loadEntry(String entryId) async {
    final id = _selectedId;
    if (id == null) return;
    entryLoading.value = true;
    entryError.value = null;
    try {
      final e = EyPortfolioEntry.fromJson(await _api.getEarlyYearsEntry(id, entryId));
      if (_selectedId != id) return;
      if (e.id.isEmpty) {
        entryError.value = 'This entry is no longer available.';
      } else {
        entry.value = e;
      }
    } on ApiException catch (e) {
      entryError.value = e.statusCode == 404 ? 'This entry is no longer shared with you.' : messageFor(e);
    } catch (_) {
      entryError.value = 'Something went wrong. Please try again.';
    } finally {
      entryLoading.value = false;
    }
  }

  /// 404 = not an Early Years child / entry gone, 403 = not your child; both get plain wording.
  static String messageFor(ApiException e) {
    switch (e.statusCode) {
      case 404:
        return "Early Years isn't available for this child.";
      case 403:
        return "You don't have access to this child's Early Years record.";
      default:
        return e.message;
    }
  }

  void _clearLists() {
    portfolio.clear();
    portfolioLoaded.value = false;
    portfolioHasMore.value = false;
    portfolioError.value = null;
    portfolioLoading.value = false;
    portfolioLoadingMore.value = false;
    _portfolioPage = 0;
    _portfolioFetchedAt = null;
    observations.clear();
    observationsLoaded.value = false;
    observationsHasMore.value = false;
    observationsError.value = null;
    observationsLoading.value = false;
    observationsLoadingMore.value = false;
    _observationsPage = 0;
    _observationsFetchedAt = null;
    entry.value = null;
    entryError.value = null;
    entryLoading.value = false;
    _lastFailRefresh = null;
  }

  /// Logout: forget everything about the previous account.
  void reset() {
    _clearLists();
    summary.value = null;
    summaryLoading.value = false;
    _summaryFor = null;
  }
}
