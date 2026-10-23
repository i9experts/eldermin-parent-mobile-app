import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/models/early_years_models.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../components/custom_text.dart';
import '../controllers/early_years_controller.dart';
import 'early_years_media.dart';
import 'early_years_screen.dart' show eyDate;

AppBar _bar(String title) => AppBar(title: CustomText(text: title, color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700, maxLines: 1));

/// One shared portfolio entry. Opens with the list's copy and re-fetches the
/// entry so its photo links are fresh (they expire after ~15 minutes).
class EarlyYearsEntryScreen extends StatefulWidget {
  final EyPortfolioEntry? initial;
  const EarlyYearsEntryScreen({super.key, this.initial});

  @override
  State<EarlyYearsEntryScreen> createState() => _EarlyYearsEntryScreenState();
}

class _EarlyYearsEntryScreenState extends State<EarlyYearsEntryScreen> {
  final EarlyYearsController c = Get.find<EarlyYearsController>();
  late final EyPortfolioEntry? _seed = widget.initial ?? (Get.arguments is EyPortfolioEntry ? Get.arguments as EyPortfolioEntry : null);

  @override
  void initState() {
    super.initState();
    c.entry.value = _seed;
    c.entryError.value = null;
    final id = _seed?.id;
    if (id != null) WidgetsBinding.instance.addPostFrameCallback((_) => c.loadEntry(id));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: _bar('Portfolio entry'),
        body: Obx(() {
          final e = c.entry.value;
          if (e == null) {
            return c.entryError.value != null
                ? AppErrorView(message: c.entryError.value!)
                : const AppEmptyView(icon: Icons.photo_library_outlined, title: 'Entry not found');
          }
          return ListView(padding: const EdgeInsets.all(AppSpacing.md), children: [
            CustomText(text: e.title, color: AppColors.primaryColor, fontSize: 18, fontWeight: FontWeight.w800),
            const SizedBox(height: 4),
            CustomText(text: eyDate(e.createdAt), color: AppColors.faint, fontSize: 11),
            if (c.entryError.value != null) ...[
              const SizedBox(height: 8),
              CustomText(text: c.entryError.value!, color: AppColors.red, fontSize: 11),
            ],
            const SizedBox(height: AppSpacing.md),
            EyMediaStrip(media: e.media),
            if (e.media.isNotEmpty) const SizedBox(height: AppSpacing.md),
            CustomText(text: e.narrative, color: AppColors.black, fontSize: 14, height: 1.5),
            if (e.tryThisAtHome != null) ...[
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: AppColors.amberBg, borderRadius: BorderRadius.circular(AppRadius.md)),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Icon(Icons.lightbulb_outline_rounded, color: AppColors.amberDark),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const CustomText(text: 'Try this at home', color: AppColors.amberDark, fontWeight: FontWeight.w800, fontSize: 12.5),
                      const SizedBox(height: 4),
                      CustomText(text: e.tryThisAtHome!, color: AppColors.black, fontSize: 13),
                    ]),
                  ),
                ]),
              ),
            ],
          ]);
        }),
      );
}

/// One shared observation (taken from the list; its links are refreshed with the list).
class EarlyYearsObservationScreen extends StatefulWidget {
  final EyObservation? initial;
  const EarlyYearsObservationScreen({super.key, this.initial});

  @override
  State<EarlyYearsObservationScreen> createState() => _EarlyYearsObservationScreenState();
}

class _EarlyYearsObservationScreenState extends State<EarlyYearsObservationScreen> {
  final EarlyYearsController c = Get.find<EarlyYearsController>();
  late final EyObservation? _seed = widget.initial ?? (Get.arguments is EyObservation ? Get.arguments as EyObservation : null);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => c.refreshIfStale());
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: _bar('Observation'),
        body: Obx(() {
          // Prefer the freshest copy of this observation (same id) from the controller's list.
          final o = c.observations.firstWhereOrNull((x) => x.id == _seed?.id) ?? _seed;
          if (o == null) return const AppEmptyView(icon: Icons.visibility_outlined, title: 'Observation not found');
          return ListView(padding: const EdgeInsets.all(AppSpacing.md), children: [
            CustomText(text: eyDate(o.createdAt), color: AppColors.faint, fontSize: 11),
            const SizedBox(height: AppSpacing.sm),
            EyMediaStrip(media: o.media),
            if (o.media.isNotEmpty) const SizedBox(height: AppSpacing.md),
            CustomText(text: o.narrative, color: AppColors.black, fontSize: 14, height: 1.5),
            if (o.learningAreas.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              const SectionRow(title: 'Learning areas'),
              for (final a in o.learningAreas)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(children: [
                    Expanded(child: CustomText(text: a.skill, color: AppColors.black, fontSize: 13)),
                    if (a.level.isNotEmpty) AppTag(a.level),
                  ]),
                ),
            ],
            if (o.nextStep != null) ...[
              const SizedBox(height: AppSpacing.md),
              const SectionRow(title: 'Next step'),
              CustomText(text: o.nextStep!, color: AppColors.muted, fontSize: 13),
            ],
          ]);
        }),
      );
}
