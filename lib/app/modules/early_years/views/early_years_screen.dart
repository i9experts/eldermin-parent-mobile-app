import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../core/models/early_years_models.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../core/widgets/shimmer_widgets.dart';
import '../../../components/custom_text.dart';
import '../../../routes/app_routes.dart';
import '../controllers/early_years_controller.dart';
import 'early_years_media.dart';

String eyDate(DateTime? d) => d == null ? '' : DateFormat('d MMM yyyy').format(d);

/// Early Years home for the selected child: summary card, then the portfolio
/// entries the school has shared and (only if there are any) shared observations.
class EarlyYearsScreen extends StatefulWidget {
  const EarlyYearsScreen({super.key});

  @override
  State<EarlyYearsScreen> createState() => _EarlyYearsScreenState();
}

class _EarlyYearsScreenState extends State<EarlyYearsScreen> with WidgetsBindingObserver {
  final EarlyYearsController c = Get.find<EarlyYearsController>();
  int _tab = 0;
  Worker? _summaryWorker;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // The summary can arrive after the screen opens (or change with the child): load the lists then too.
    _summaryWorker = ever(c.summary, (_) => c.ensureLists());
    WidgetsBinding.instance.addPostFrameCallback((_) => c.open());
  }

  @override
  void dispose() {
    _summaryWorker?.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) c.refreshIfStale();
  }

  Future<void> _refresh() => Future.wait([
        c.loadSummary(),
        c.loadPortfolio(),
        if (c.observationsLoaded.value || c.showObservations) c.loadObservations(),
      ]);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const CustomText(text: 'Early Years', color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700, maxLines: 1),
      ),
      body: Obx(() {
        if (!c.eligible) {
          return c.summaryLoading.value
              ? AppShimmer(key: const Key('ey_loading'), child: ListView(padding: const EdgeInsets.all(AppSpacing.md), children: [const ShimmerScreenHeaderSkeleton(), const SizedBox(height: AppSpacing.lg), ...shimmerListRows(3)]))
              : const AppEmptyView(icon: Icons.child_care_rounded, title: "Early Years isn't available for this child");
        }
        final showObs = c.showObservations;
        final tab = showObs ? _tab : 0;
        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              _SummaryCard(summary: c.summary.value!),
              const SizedBox(height: AppSpacing.md),
              if (showObs)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: SegmentedControl(
                    options: const ['Portfolio', 'Shared observations'],
                    selectedIndex: tab,
                    onChanged: (i) {
                      setState(() => _tab = i);
                      if (i == 1 && !c.observationsLoaded.value) c.loadObservations();
                    },
                  ),
                ),
              if (tab == 0) ..._portfolio() else ..._observations(),
            ],
          ),
        );
      }),
    );
  }

  List<Widget> _portfolio() {
    if (c.portfolioLoading.value && c.portfolio.isEmpty) return [AppShimmer(key: const Key('ey_loading'), child: Column(children: shimmerListRows(3)))];
    if (c.portfolioError.value != null && c.portfolio.isEmpty) {
      return [AppErrorView(message: c.portfolioError.value!, onRetry: c.loadPortfolio)];
    }
    if (c.portfolio.isEmpty) {
      return const [
        AppEmptyView(
          icon: Icons.photo_library_outlined,
          title: 'Nothing shared yet',
          subtitle: "When your child's teacher shares a portfolio entry, it will appear here.",
        )
      ];
    }
    return [
      for (final e in c.portfolio) _PortfolioCard(entry: e),
      _LoadMore(hasMore: c.portfolioHasMore.value, loading: c.portfolioLoadingMore.value, onTap: c.loadMorePortfolio, error: c.portfolioError.value),
    ];
  }

  List<Widget> _observations() {
    if (c.observationsLoading.value && c.observations.isEmpty) return [AppShimmer(key: const Key('ey_loading'), child: Column(children: shimmerListRows(3)))];
    if (c.observationsError.value != null && c.observations.isEmpty) {
      return [AppErrorView(message: c.observationsError.value!, onRetry: c.loadObservations)];
    }
    if (c.observations.isEmpty) {
      return const [AppEmptyView(icon: Icons.visibility_outlined, title: 'No shared observations yet')];
    }
    return [
      for (final o in c.observations) _ObservationCard(observation: o),
      _LoadMore(hasMore: c.observationsHasMore.value, loading: c.observationsLoadingMore.value, onTap: c.loadMoreObservations, error: c.observationsError.value),
    ];
  }
}

class _SummaryCard extends StatelessWidget {
  final EySummary summary;
  const _SummaryCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final lines = <(IconData, String)>[
      if (summary.classLabel.isNotEmpty) (Icons.class_outlined, summary.classLabel),
      if (summary.keyPerson != null) (Icons.person_outline_rounded, 'Key person: ${summary.keyPerson}'),
      if (summary.academicYear != null) (Icons.calendar_today_outlined, summary.academicYear!),
    ];
    return AppCard(
      margin: EdgeInsets.zero,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.child_care_rounded, color: AppColors.blue),
          const SizedBox(width: 8),
          Expanded(child: CustomText(text: '${summary.firstName} ${summary.lastName}'.trim(), color: AppColors.primaryColor, fontSize: 15, fontWeight: FontWeight.w800)),
          const AppTag('Early Years', style: TagStyle.green),
        ]),
        const SizedBox(height: 8),
        for (final l in lines)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(children: [Icon(l.$1, size: 14, color: AppColors.faint), const SizedBox(width: 6), Expanded(child: CustomText(text: l.$2, color: AppColors.muted, fontSize: 12))]),
          ),
        const SizedBox(height: 6),
        Row(children: [
          AppTag('${summary.sharedPortfolioCount} shared ${summary.sharedPortfolioCount == 1 ? 'entry' : 'entries'}'),
          const SizedBox(width: 6),
          if (summary.sharedObservationCount > 0)
            AppTag('${summary.sharedObservationCount} ${summary.sharedObservationCount == 1 ? 'observation' : 'observations'}'),
        ]),
        if (summary.lastSharedAt != null) ...[
          const SizedBox(height: 6),
          CustomText(text: 'Last shared ${eyDate(summary.lastSharedAt)}', color: AppColors.faint, fontSize: 10.5),
        ],
      ]),
    );
  }
}

class _PortfolioCard extends StatelessWidget {
  final EyPortfolioEntry entry;
  const _PortfolioCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final photos = entry.media.where((m) => m.isPhoto).toList();
    return AppCard(
      onTap: () => Get.toNamed(Routes.earlyYearsEntry, arguments: entry),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (photos.isNotEmpty) ...[
          EyMediaView(media: photos.first, height: 140, width: double.infinity),
          const SizedBox(height: 10),
        ],
        CustomText(text: entry.title, color: AppColors.primaryColor, fontSize: 14, fontWeight: FontWeight.w800),
        const SizedBox(height: 3),
        CustomText(text: eyDate(entry.createdAt), color: AppColors.faint, fontSize: 10.5),
        const SizedBox(height: 6),
        CustomText(text: entry.narrative, color: AppColors.muted, fontSize: 12.5, maxLines: 3, overflow: TextOverflow.ellipsis),
      ]),
    );
  }
}

class _ObservationCard extends StatelessWidget {
  final EyObservation observation;
  const _ObservationCard({required this.observation});

  @override
  Widget build(BuildContext context) => AppCard(
        onTap: () => Get.toNamed(Routes.earlyYearsObservation, arguments: observation),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          CustomText(text: eyDate(observation.createdAt), color: AppColors.faint, fontSize: 10.5),
          const SizedBox(height: 4),
          CustomText(text: observation.narrative, color: AppColors.black, fontSize: 13, maxLines: 4, overflow: TextOverflow.ellipsis),
          if (observation.learningAreas.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(spacing: 6, runSpacing: 6, children: [for (final a in observation.learningAreas) AppTag(a.skill)]),
          ],
        ]),
      );
}

class _LoadMore extends StatelessWidget {
  final bool hasMore;
  final bool loading;
  final VoidCallback onTap;
  final String? error;
  const _LoadMore({required this.hasMore, required this.loading, required this.onTap, this.error});

  @override
  Widget build(BuildContext context) {
    if (loading) return const Padding(padding: EdgeInsets.all(AppSpacing.md), child: AppLoader());
    if (!hasMore) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Column(children: [
        if (error != null) CustomText(text: error!, color: AppColors.red, fontSize: 11, textAlign: TextAlign.center),
        OutlinedButton(onPressed: onTap, child: const CustomText(text: 'Load more')),
      ]),
    );
  }
}
