import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../core/widgets/hero_card.dart';
import '../../../../core/widgets/shimmer_widgets.dart';
import '../../../components/custom_text.dart';
import '../../shared/views/coming_soon_screen.dart';
import '../controllers/dues_controller.dart';

class DuesScreen extends GetView<DuesController> {
  const DuesScreen({super.key});

  num _n(dynamic v) => v is num ? v : num.tryParse(v?.toString() ?? '') ?? 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const CustomText(
        text: 'Fees & dues',
        color: Colors.white,
        fontWeight: FontWeight.w700,
        fontSize: 18,
      )),
      body: Obx(() {
        if (controller.loading.value && controller.invoices.isEmpty) {
          return AppShimmer(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                const ShimmerScreenHeaderSkeleton(),
                const SizedBox(height: AppSpacing.lg),
                const ShimmerDateStripSkeleton(),
                const SizedBox(height: AppSpacing.md),
                const ShimmerHeroCardSkeleton(),
                const SizedBox(height: AppSpacing.md),
                const ShimmerStatsRowSkeleton(count: 3),
                const SizedBox(height: AppSpacing.md),
                const ShimmerChartSkeleton(),
                const SizedBox(height: AppSpacing.md),
                ...shimmerListRows(4),
              ],
            ),
          );
        }
        if (controller.error.value != null) {
          return AppErrorView(
              message: controller.error.value!, onRetry: controller.fetch);
        }

        final invoices = controller.invoices;

        final totalDue =
            invoices.fold<num>(0, (sum, i) => sum + _n(i['balanceDue']));
        final totalPaid =
            invoices.fold<num>(0, (sum, i) => sum + _n(i['paidAmount']));
        final totalLateFine =
            invoices.fold<num>(0, (sum, i) => sum + _n(i['lateFine']));
        final totalBilled = totalPaid + totalDue;
        final percentPaid = totalBilled > 0
            ? ((totalPaid / totalBilled) * 100).clamp(0, 100).round()
            : 100;

        DateTime? earliestDue;
        for (final i in invoices) {
          if (_n(i['balanceDue']) <= 0) continue;
          final d = i['dueDate'] != null
              ? DateTime.tryParse(i['dueDate'].toString())
              : null;
          if (d != null && (earliestDue == null || d.isBefore(earliestDue))) {
            earliestDue = d;
          }
        }
        final trendText = totalDue <= 0
            ? 'No dues outstanding'
            : (earliestDue != null
                ? 'Due by ${earliestDue.day}/${earliestDue.month}/${earliestDue.year}'
                : 'No due date on file');

        final academicYear = invoices.isNotEmpty
            ? invoices.first['academicYear']?.toString()
            : null;

        return RefreshIndicator(
          onRefresh: controller.fetch,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              ScreenHeader(
                title: 'Fees & payments',
                caption: 'Clear, secure and transparent',
                selectLabel: academicYear,
              ),
              const AppWeekDateStrip(),
              const SizedBox(height: AppSpacing.md),
              HeroCard(
                kicker: 'Current outstanding',
                value: 'Rs ${totalDue.toStringAsFixed(0)}',
                trend: trendText,
                trendWarn: totalDue > 0,
                percent: percentPaid,
                ringColor: totalDue <= 0 ? AppColors.secondryColor : AppColors.amber,
              ),
              const SizedBox(height: 10),
              Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  onTap: () => Get.to(
                      () => const ComingSoonScreen(title: 'Secure Payment')),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    decoration: BoxDecoration(
                        color: AppColors.amber,
                        borderRadius: BorderRadius.circular(AppRadius.md)),
                    child: const Center(
                      child: CustomText(
                        text: 'Pay securely →',
                        color: AppColors.primaryColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              StatsRow(items: [
                ('Rs ${totalPaid.toStringAsFixed(0)}', 'Paid', null),
                ('Rs ${totalDue.toStringAsFixed(0)}', 'Due', null),
                ('Rs ${totalLateFine.toStringAsFixed(0)}', 'Late fee', null),
              ]),
              const SizedBox(height: AppSpacing.md),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CustomText(
                      text: 'Annual payment progress',
                      color: AppColors.primaryColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                    const SizedBox(height: 8),
                    CustomText(
                      text:
                          'Rs ${totalPaid.toStringAsFixed(0)} of Rs ${totalBilled.toStringAsFixed(0)} paid',
                      color: AppColors.muted,
                      fontSize: 10,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    AppProgressBar(percent: percentPaid, color: AppColors.secondryColor),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              if (invoices.isEmpty)
                const AppEmptyView(
                    icon: Icons.receipt_long_outlined,
                    title: 'No invoices on file')
              else
                ...invoices.map((inv) {
                  final due = inv['dueDate'] != null
                      ? DateTime.tryParse(inv['dueDate'].toString())
                      : null;
                  final isUnpaid = _n(inv['balanceDue']) > 0;
                  return AppCard(
                    child: Row(children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustomText(
                              text: inv['invoiceNumber']?.toString() ?? 'Invoice',
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                              color: AppColors.primaryColor,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            CustomText(
                              text: due != null
                                  ? 'Due ${due.day}/${due.month}/${due.year}'
                                  : '',
                              color: AppColors.muted,
                              fontSize: 10,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      AppTag(isUnpaid ? 'Unpaid' : 'Paid',
                          style: isUnpaid ? TagStyle.red : TagStyle.green),
                    ]),
                  );
                }),
            ],
          ),
        );
      }),
    );
  }
}
