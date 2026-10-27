import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/design/design.dart';
import '../../../../core/theme/app_theme.dart' show TagStyle;
import '../../../../core/widgets/app_widgets.dart';
import '../../../../core/widgets/hero_card.dart';
import '../../../../core/widgets/shimmer_widgets.dart';
import '../controllers/dues_controller.dart';
import 'dues_detail_sheet.dart';

/// Fees & dues (read-only). Teacher pattern: the Home hero summary (`design-kit-v1` `home_sections.dart` `ClassTeacherCard`,
/// `EmHeroCard` + ring) for the outstanding amount, white [EmCard] rows for the list (`ptm_widgets.dart:31-71` card style).
/// Amounts, "Rs" formatting, statuses and dates are exactly as before; only the layout changed.
class DuesScreen extends GetView<DuesController> {
  const DuesScreen({super.key});

  num _n(dynamic v) => v is num ? v : num.tryParse(v?.toString() ?? '') ?? 0;

  @override
  Widget build(BuildContext context) {
    return EmScaffold(
      appBar: EmAppBar(title: 'Fees & dues'),
      body: Obx(() {
        if (controller.loading.value && controller.invoices.isEmpty) {
          return AppShimmer(
            child: ListView(
              padding: EmSpacing.listPadding,
              children: [
                const ShimmerScreenIntroSkeleton(),
                const ShimmerHeroCardSkeleton(),
                const SizedBox(height: EmSpacing.s12),
                const ShimmerStatsRowSkeleton(count: 3),
                const SizedBox(height: EmSpacing.s12),
                const ShimmerProgressCardSkeleton(),
                const SizedBox(height: EmSpacing.s12),
                ...shimmerListRows(4),
              ],
            ),
          );
        }
        if (controller.error.value != null) {
          return AppErrorView(message: controller.error.value!, onRetry: controller.fetch);
        }

        final invoices = controller.invoices;

        final totalDue = invoices.fold<num>(0, (sum, i) => sum + _n(i['balanceDue']));
        final totalPaid = invoices.fold<num>(0, (sum, i) => sum + _n(i['paidAmount']));
        final totalLateFine = invoices.fold<num>(0, (sum, i) => sum + _n(i['lateFine']));
        final totalBilled = totalPaid + totalDue;
        final percentPaid = totalBilled > 0 ? ((totalPaid / totalBilled) * 100).clamp(0, 100).round() : 100;

        DateTime? earliestDue;
        for (final i in invoices) {
          if (_n(i['balanceDue']) <= 0) continue;
          final d = i['dueDate'] != null ? DateTime.tryParse(i['dueDate'].toString()) : null;
          if (d != null && (earliestDue == null || d.isBefore(earliestDue))) {
            earliestDue = d;
          }
        }
        final trendText = totalDue <= 0
            ? 'No dues outstanding'
            : (earliestDue != null ? 'Due by ${earliestDue.day}/${earliestDue.month}/${earliestDue.year}' : 'No due date on file');

        final academicYear = invoices.isNotEmpty ? invoices.first['academicYear']?.toString() : null;

        return RefreshIndicator(
          onRefresh: controller.fetch,
          child: ListView(
            padding: EmSpacing.listPadding,
            children: [
              ScreenIntro(caption: 'Clear, secure and transparent', selectLabel: academicYear),
              HeroCard(
                key: const Key('dues_hero'),
                kicker: 'Current outstanding',
                value: 'Rs ${totalDue.toStringAsFixed(0)}',
                trend: trendText,
                trendWarn: totalDue > 0,
                percent: percentPaid,
                ringColor: totalDue <= 0 ? EmColors.success : EmColors.primary,
              ),
              const SizedBox(height: EmSpacing.s12),
              StatsRow(items: [
                ('Rs ${totalPaid.toStringAsFixed(0)}', 'Paid', null),
                ('Rs ${totalDue.toStringAsFixed(0)}', 'Due', null),
                ('Rs ${totalLateFine.toStringAsFixed(0)}', 'Late fee', null),
              ]),
              const SizedBox(height: EmSpacing.s12),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Annual payment progress', style: EmType.label.copyWith(color: EmColors.ink)),
                    const SizedBox(height: EmSpacing.s4),
                    Text('Rs ${totalPaid.toStringAsFixed(0)} of Rs ${totalBilled.toStringAsFixed(0)} paid',
                        style: EmType.label.copyWith(color: EmColors.textSecondary, fontWeight: FontWeight.w400)),
                    const SizedBox(height: EmSpacing.s8),
                    AppProgressBar(percent: percentPaid, color: EmColors.success),
                  ],
                ),
              ),
              if (invoices.isEmpty)
                const AppEmptyView(icon: Icons.receipt_long_outlined, title: 'No invoices on file')
              else
                ...invoices.map((raw) {
                  final inv = Map<String, dynamic>.from(raw as Map);
                  final due = inv['dueDate'] != null ? DateTime.tryParse(inv['dueDate'].toString()) : null;
                  final isUnpaid = _n(inv['balanceDue']) > 0;
                  return ListCardRow(
                    icon: Icons.receipt_long_outlined,
                    iconColor: isUnpaid ? EmColors.warning : EmColors.success,
                    title: inv['invoiceNumber']?.toString() ?? 'Invoice',
                    subtitle: due != null ? 'Due ${due.day}/${due.month}/${due.year}' : '',
                    trailing: AppTag(isUnpaid ? 'Unpaid' : 'Paid', style: isUnpaid ? TagStyle.red : TagStyle.green),
                    onTap: () => showDuesDetailSheet(context, inv),
                  );
                }),
            ],
          ),
        );
      }),
    );
  }
}
