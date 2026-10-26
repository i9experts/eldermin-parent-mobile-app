import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../core/design/design.dart';
import '../../../../core/models/early_years_models.dart';
import '../../../../core/theme/app_theme.dart' show TagStyle;
import '../../../../core/widgets/app_widgets.dart';
import '../../../../core/widgets/shimmer_widgets.dart';
import '../../../routes/app_routes.dart';
import '../controllers/early_years_controller.dart';
import 'early_years_media.dart';

String eyDate(DateTime? d) => d == null ? '' : DateFormat('d MMM yyyy').format(d);

/// Early Years home for the selected child: summary card, then the portfolio entries the school has shared and (only if there are
/// any) shared observations.
///
/// Teacher patterns (`design-kit-v1`): the summary is a hero card, `home_sections.dart:112-132` (`ClassTeacherCard`, an `EmHeroCard`);
/// the two tabs are `EmSegmentedTabs`, `ptm_screen.dart:44-52`; the entries are white cards, `ptm_widgets.dart:31-71` (`PtmCard`);
/// scaffold and app bar `ptm_screen.dart:21-22`. Eligibility gating (the plain "not available" state) and everything the controller
/// does are unchanged.
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
    return EmScaffold(
      appBar: EmAppBar(title: 'Early Years'),
      body: Obx(() {
        if (!c.eligible) {
          return c.summaryLoading.value
              ? AppShimmer(
                  key: const Key('ey_loading'),
                  child: ListView(
                    padding: EmSpacing.listPadding,
                    children: const [ShimmerSummaryCardSkeleton(), SizedBox(height: EmSpacing.s16), ShimmerMediaCardSkeleton(), ShimmerMediaCardSkeleton()],
                  ),
                )
              : const AppEmptyView(icon: Icons.child_care_rounded, title: "Early Years isn't available for this child");
        }
        final showObs = c.showObservations;
        final tab = showObs ? _tab : 0;
        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EmSpacing.listPadding,
            children: [
              _SummaryCard(summary: c.summary.value!),
              const SizedBox(height: EmSpacing.s16),
              if (showObs)
                Padding(
                  padding: const EdgeInsetsDirectional.only(bottom: EmSpacing.s16),
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

  Widget _skeleton() => AppShimmer(key: const Key('ey_loading'), child: const Column(children: [ShimmerMediaCardSkeleton(), ShimmerMediaCardSkeleton()]));

  List<Widget> _portfolio() {
    if (c.portfolioLoading.value && c.portfolio.isEmpty) return [_skeleton()];
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
    if (c.observationsLoading.value && c.observations.isEmpty) return [_skeleton()];
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
    return EmHeroCard(
      key: const Key('ey_summary'),
      padding: const EdgeInsetsDirectional.all(EmSpacing.s16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const ExcludeSemantics(child: Icon(Icons.child_care_rounded, color: EmColors.primary)),
          const SizedBox(width: EmSpacing.s8),
          Expanded(child: Text('${summary.firstName} ${summary.lastName}'.trim(), style: EmType.heading.copyWith(color: EmColors.ink))),
          const SizedBox(width: EmSpacing.s8),
          const AppTag('Early Years', style: TagStyle.green),
        ]),
        const SizedBox(height: EmSpacing.s12),
        for (final l in lines)
          Padding(
            padding: const EdgeInsetsDirectional.only(bottom: EmSpacing.s4),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Padding(padding: const EdgeInsetsDirectional.only(top: EmSpacing.s2), child: ExcludeSemantics(child: Icon(l.$1, size: 16, color: EmColors.textSecondary))),
              const SizedBox(width: EmSpacing.s8),
              Expanded(child: Text(l.$2, style: EmType.label.copyWith(color: EmColors.ink, fontWeight: FontWeight.w500))),
            ]),
          ),
        const SizedBox(height: EmSpacing.s8),
        Wrap(spacing: EmSpacing.s8, runSpacing: EmSpacing.s8, children: [
          AppTag('${summary.sharedPortfolioCount} shared ${summary.sharedPortfolioCount == 1 ? 'entry' : 'entries'}'),
          if (summary.sharedObservationCount > 0)
            AppTag('${summary.sharedObservationCount} ${summary.sharedObservationCount == 1 ? 'observation' : 'observations'}'),
        ]),
        if (summary.lastSharedAt != null) ...[
          const SizedBox(height: EmSpacing.s8),
          Text('Last shared ${eyDate(summary.lastSharedAt)}', style: EmType.caption.copyWith(color: EmColors.textSecondary)),
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
      key: ValueKey('ey_entry_${entry.id}'),
      onTap: () => Get.toNamed(Routes.earlyYearsEntry, arguments: entry),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (photos.isNotEmpty) ...[
          EyMediaView(media: photos.first, height: 160, width: double.infinity),
          const SizedBox(height: EmSpacing.s12),
        ],
        Text(entry.title, style: EmType.bodyLarge.copyWith(color: EmColors.ink)),
        const SizedBox(height: EmSpacing.s2),
        Text(eyDate(entry.createdAt), style: EmType.caption.copyWith(color: EmColors.textSecondary)),
        const SizedBox(height: EmSpacing.s8),
        Text(entry.narrative, maxLines: 3, overflow: TextOverflow.ellipsis, style: EmType.body.copyWith(color: EmColors.textSecondary, fontWeight: FontWeight.w400)),
      ]),
    );
  }
}

class _ObservationCard extends StatelessWidget {
  final EyObservation observation;
  const _ObservationCard({required this.observation});

  @override
  Widget build(BuildContext context) => AppCard(
        key: ValueKey('ey_observation_${observation.id}'),
        onTap: () => Get.toNamed(Routes.earlyYearsObservation, arguments: observation),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(eyDate(observation.createdAt), style: EmType.caption.copyWith(color: EmColors.textSecondary)),
          const SizedBox(height: EmSpacing.s4),
          Text(observation.narrative, maxLines: 4, overflow: TextOverflow.ellipsis, style: EmType.body.copyWith(color: EmColors.ink, fontWeight: FontWeight.w400)),
          if (observation.learningAreas.isNotEmpty) ...[
            const SizedBox(height: EmSpacing.s8),
            Wrap(spacing: EmSpacing.s8, runSpacing: EmSpacing.s8, children: [for (final a in observation.learningAreas) AppTag(a.skill)]),
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
    if (loading) return const Padding(padding: EdgeInsetsDirectional.all(EmSpacing.s16), child: AppLoader());
    if (!hasMore) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(vertical: EmSpacing.s8),
      child: Column(children: [
        if (error != null) Padding(padding: const EdgeInsetsDirectional.only(bottom: EmSpacing.s8), child: Text(error!, textAlign: TextAlign.center, style: EmType.caption.copyWith(color: EmColors.error, fontWeight: FontWeight.w600))),
        EmSecondaryButton(key: const Key('ey_load_more'), label: 'Load more', onPressed: onTap, expand: true),
      ]),
    );
  }
}
