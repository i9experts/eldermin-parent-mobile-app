import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/design/design.dart';
import '../../../../core/models/early_years_models.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../controllers/early_years_controller.dart';
import 'early_years_media.dart';
import 'early_years_screen.dart' show eyDate;

/// One shared portfolio entry. Opens with the list's copy and re-fetches the entry so its photo links are fresh (they expire after
/// ~15 minutes). Teacher pattern (`design-kit-v1`): `ptm_detail_screen.dart:67-70` (`EmScaffold` + `EmAppBar`) with the content in
/// titled sections (`:119-136`, `SubHeading`).
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
  Widget build(BuildContext context) => EmScaffold(
        appBar: EmAppBar(title: 'Portfolio entry'),
        body: Obx(() {
          final e = c.entry.value;
          if (e == null) {
            return c.entryError.value != null
                ? AppErrorView(message: c.entryError.value!)
                : const AppEmptyView(icon: Icons.photo_library_outlined, title: 'Entry not found');
          }
          return ListView(padding: EmSpacing.listPadding, children: [
            Semantics(header: true, child: Text(e.title, style: EmType.title.copyWith(color: EmColors.ink))),
            const SizedBox(height: EmSpacing.s4),
            Text(eyDate(e.createdAt), style: EmType.body.copyWith(color: EmColors.textSecondary)),
            if (c.entryError.value != null) ...[
              const SizedBox(height: EmSpacing.s8),
              Text(c.entryError.value!, style: EmType.caption.copyWith(color: EmColors.error, fontWeight: FontWeight.w600)),
            ],
            const SizedBox(height: EmSpacing.s16),
            EyMediaStrip(media: e.media),
            if (e.media.isNotEmpty) const SizedBox(height: EmSpacing.s16),
            Text(e.narrative, style: EmType.bodyLarge.copyWith(color: EmColors.ink, fontWeight: FontWeight.w400, height: 1.5)),
            if (e.tryThisAtHome != null) ...[
              const SizedBox(height: EmSpacing.s16),
              Container(
                key: const Key('ey_try_at_home'),
                padding: EmSpacing.cardPad,
                decoration: BoxDecoration(color: EmTone.warning.background, borderRadius: EmRadius.mdAll),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  ExcludeSemantics(child: Icon(Icons.lightbulb_outline_rounded, color: EmTone.warning.foreground)),
                  const SizedBox(width: EmSpacing.s12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Try this at home', style: EmType.label.copyWith(color: EmTone.warning.foreground, fontWeight: FontWeight.w700)),
                      const SizedBox(height: EmSpacing.s4),
                      Text(e.tryThisAtHome!, style: EmType.body.copyWith(color: EmColors.ink, fontWeight: FontWeight.w400)),
                    ]),
                  ),
                ]),
              ),
            ],
          ]);
        }),
      );
}

/// One shared observation (taken from the list; its links are refreshed with the list). Same teacher pattern as the entry screen.
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
  Widget build(BuildContext context) => EmScaffold(
        appBar: EmAppBar(title: 'Observation'),
        body: Obx(() {
          // Prefer the freshest copy of this observation (same id) from the controller's list.
          final o = c.observations.firstWhereOrNull((x) => x.id == _seed?.id) ?? _seed;
          if (o == null) return const AppEmptyView(icon: Icons.visibility_outlined, title: 'Observation not found');
          return ListView(padding: EmSpacing.listPadding, children: [
            Text(eyDate(o.createdAt), style: EmType.body.copyWith(color: EmColors.textSecondary)),
            const SizedBox(height: EmSpacing.s8),
            EyMediaStrip(media: o.media),
            if (o.media.isNotEmpty) const SizedBox(height: EmSpacing.s16),
            Text(o.narrative, style: EmType.bodyLarge.copyWith(color: EmColors.ink, fontWeight: FontWeight.w400, height: 1.5)),
            if (o.learningAreas.isNotEmpty) ...[
              const SizedBox(height: EmSpacing.s16),
              const SectionRow(title: 'Learning areas'),
              for (final a in o.learningAreas)
                Padding(
                  padding: const EdgeInsetsDirectional.only(bottom: EmSpacing.s8),
                  child: Row(children: [
                    Expanded(child: Text(a.skill, style: EmType.body.copyWith(color: EmColors.ink, fontWeight: FontWeight.w400))),
                    if (a.level.isNotEmpty) ...[const SizedBox(width: EmSpacing.s8), AppTag(a.level)],
                  ]),
                ),
            ],
            if (o.nextStep != null) ...[
              const SizedBox(height: EmSpacing.s16),
              const SectionRow(title: 'Next step'),
              Text(o.nextStep!, style: EmType.body.copyWith(color: EmColors.textSecondary, fontWeight: FontWeight.w400)),
            ],
          ]);
        }),
      );
}
