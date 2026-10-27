import 'package:flutter/material.dart';
import '../../../../core/design/design.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../core/widgets/shimmer_widgets.dart';
import '../../../components/custom_text.dart';
import '../../../../core/utils/safe_text.dart';
import '../controllers/consent_controller.dart';
import 'consent_detail_sheet.dart';

class ConsentScreen extends GetView<ConsentController> {
  const ConsentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return EmScaffold(
      appBar: EmAppBar(title: 'Consent centre'),
      body: Obx(() {
        if (controller.loading.value && controller.requests.isEmpty) {
          return AppShimmer(
            child: ListView(
              padding: EmSpacing.listPadding,
              children: [
                const ShimmerScreenIntroSkeleton(),
                const SizedBox(height: EmSpacing.s16),
                const ShimmerStatsRowSkeleton(count: 3),
                const SizedBox(height: EmSpacing.s16),
                const ShimmerChartSkeleton(),
                const SizedBox(height: EmSpacing.s16),
                ...shimmerListRows(4),
              ],
            ),
          );
        }
        if (controller.error.value != null) {
          return AppErrorView(
              message: controller.error.value!, onRetry: controller.fetch);
        }

        final requests = controller.requests;
        final responded = requests.where((r) => r['response'] != null).length;
        final pending = requests.length - responded;

        return RefreshIndicator(
          onRefresh: controller.fetch,
          child: ListView(
            padding: EmSpacing.listPadding,
            children: [
              const ScreenIntro(
                caption: 'Review requests and protect your choices',
                selectLabel: '2026–27',
              ),
              StatsRow(items: [
                ('${requests.length}', 'Requests', null),
                ('$responded', 'Completed', null),
                ('$pending', 'Pending', pending == 0 ? 'None' : null),
              ]),
              const SizedBox(height: EmSpacing.s16),
              if (requests.isNotEmpty) ...[
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const CustomText(
                              text: 'Consent completion',
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                              color: EmColors.primaryDark),
                          AppTag(
                              '${((responded / requests.length) * 100).round()}%',
                              style: TagStyle.info),
                        ],
                      ),
                      const SizedBox(height: 10),
                      AppProgressBar(
                        percent: ((responded / requests.length) * 100).round(),
                        color: EmColors.primary,
                      ),
                      const SizedBox(height: 6),
                      CustomText(
                          text:
                              '$responded of ${requests.length} requests responded',
                          color: EmColors.textSecondary,
                          fontSize: 9.5,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                const SizedBox(height: EmSpacing.s16),
              ],
              const SectionRow(title: 'Consent requests'),
              if (requests.isEmpty)
                const AppEmptyView(
                    icon: Icons.verified_user_outlined,
                    title: 'No consent requests yet')
              else
                ...requests.map((raw) {
                  final r = Map<String, dynamic>.from(raw as Map);
                  final id = ConsentController.idOf(r);
                  final status = ConsentController.statusOf(r);
                  final due = DateTime.tryParse(r['dueDate']?.toString() ?? '')?.toUtc();
                  final decision = (r['response'] as Map?)?['decision']?.toString();
                  final preview = htmlToPlainText(r['description']?.toString() ?? '').replaceAll('\n', ' ');

                  return AppCard(
                    onTap: () => showConsentDetailSheet(context, controller, id),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                                child: CustomText(
                                    text: r['title']?.toString() ??
                                        'Consent request',
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
                                    color: EmColors.primaryDark,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis)),
                            switch (status) {
                              ConsentStatus.responded => AppTag(
                                  decision == 'granted' ? 'Granted' : 'Declined',
                                  style: decision == 'granted'
                                      ? TagStyle.green
                                      : TagStyle.red),
                              ConsentStatus.expired =>
                                const AppTag('Expired', style: TagStyle.red),
                              ConsentStatus.pending => AppTag(
                                  due != null ? 'Due ${due.day}/${due.month}' : 'Pending',
                                  style: TagStyle.amber),
                            },
                          ],
                        ),
                        const SizedBox(height: 4),
                        CustomText(
                            text: preview,
                            color: EmColors.textSecondary,
                            fontSize: 10.5,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  );
                }),
            ],
          ),
        );
      }),
    );
  }
}
