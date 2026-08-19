import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../core/widgets/shimmer_widgets.dart';
import '../../../components/custom_app_snack_bar.dart';
import '../../../components/custom_button.dart';
import '../../../components/custom_text.dart';
import '../controllers/consent_controller.dart';

class ConsentScreen extends GetView<ConsentController> {
  const ConsentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const CustomText(
              text: 'Consent centre',
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 18)),
      body: Obx(() {
        if (controller.loading.value && controller.requests.isEmpty) {
          return AppShimmer(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                const ShimmerScreenHeaderSkeleton(),
                const SizedBox(height: AppSpacing.lg),
                const ShimmerDateStripSkeleton(),
                const SizedBox(height: AppSpacing.lg),
                const ShimmerStatsRowSkeleton(count: 3),
                const SizedBox(height: AppSpacing.lg),
                const ShimmerChartSkeleton(),
                const SizedBox(height: AppSpacing.lg),
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
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              const ScreenHeader(
                title: 'Consent centre',
                caption: 'Review requests and protect your choices',
                selectLabel: '2026–27',
              ),
              const AppWeekDateStrip(),
              const SizedBox(height: AppSpacing.lg),
              StatsRow(items: [
                ('${requests.length}', 'Requests', null),
                ('$responded', 'Completed', null),
                ('$pending', 'Pending', pending == 0 ? 'None' : null),
              ]),
              const SizedBox(height: AppSpacing.lg),
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
                              color: AppColors.primaryColor),
                          AppTag(
                              '${((responded / requests.length) * 100).round()}%',
                              style: TagStyle.info),
                        ],
                      ),
                      const SizedBox(height: 10),
                      AppProgressBar(
                        percent: ((responded / requests.length) * 100).round(),
                        color: AppColors.blue,
                      ),
                      const SizedBox(height: 6),
                      CustomText(
                          text:
                              '$responded of ${requests.length} requests responded',
                          color: AppColors.muted,
                          fontSize: 9.5,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
              const SectionRow(title: 'Consent requests'),
              if (requests.isEmpty)
                const AppEmptyView(
                    icon: Icons.verified_user_outlined,
                    title: 'No consent requests yet')
              else
                ...requests.map((raw) {
                  final r = Map<String, dynamic>.from(raw as Map);
                  final id = r['_id']?.toString() ?? r['id']?.toString() ?? '';
                  final response = r['response'] as Map<dynamic, dynamic>?;
                  final due = DateTime.tryParse(r['dueDate']?.toString() ?? '');
                  final decision = response?['decision']?.toString();

                  return AppCard(
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
                                    color: AppColors.primaryColor,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis)),
                            if (decision != null)
                              AppTag(
                                  decision == 'granted'
                                      ? 'Granted'
                                      : 'Declined',
                                  style: decision == 'granted'
                                      ? TagStyle.green
                                      : TagStyle.red)
                            else
                              AppTag(
                                  due != null
                                      ? 'Due ${due.day}/${due.month}'
                                      : 'Pending',
                                  style: TagStyle.amber),
                          ],
                        ),
                        const SizedBox(height: 4),
                        CustomText(
                            text: r['description']?.toString() ?? '',
                            color: AppColors.muted,
                            fontSize: 10.5,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis),
                        if (response == null) ...[
                          const SizedBox(height: 12),
                          Obx(() {
                            final busy = controller.respondingId.value == id;
                            return Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: busy
                                        ? null
                                        : () async {
                                            final ok = await controller
                                                .respond(id, 'declined');
                                            if (ok) {
                                              CustomAppSnackbar.success(
                                                  'Response recorded — consent declined.');
                                            } else {
                                              CustomAppSnackbar.error(
                                                  'Could not submit your response. Please try again.');
                                            }
                                          },
                                    child: const CustomText(text: 'Decline'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: CustomButton(
                                    label: busy ? '' : 'Grant consent',
                                    height: 42,
                                    color: AppColors.primaryColor,
                                    enabled: !busy,
                                    onPressed: () async {
                                      final ok = await controller.respond(
                                          id, 'granted');
                                      if (ok) {
                                        CustomAppSnackbar.success(
                                            'Response recorded — consent granted.');
                                      } else {
                                        CustomAppSnackbar.error(
                                            'Could not submit your response. Please try again.');
                                      }
                                    },
                                    prefix: busy
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white))
                                        : null,
                                  ),
                                ),
                              ],
                            );
                          }),
                        ],
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
