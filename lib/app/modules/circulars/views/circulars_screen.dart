import 'package:flutter/material.dart';
import '../../../../core/design/design.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_date_picker.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../core/widgets/shimmer_widgets.dart';
import '../../../components/custom_text.dart';
import '../controllers/circulars_controller.dart';

class CircularsScreen extends GetView<CircularsController> {
  const CircularsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return EmScaffold(
      appBar: EmAppBar(title: 'School updates'),
      body: Obx(() {
        if (controller.loading.value && controller.circulars.isEmpty) {
          return AppShimmer(
            child: ListView(
              padding: EmSpacing.listPadding,
              children: [
                const ShimmerScreenIntroSkeleton(),
                const SizedBox(height: EmSpacing.s16),
                const ShimmerStatsRowSkeleton(count: 3),
                const SizedBox(height: EmSpacing.s16),
                ...shimmerListRows(6),
              ],
            ),
          );
        }
        if (controller.error.value != null) {
          return AppErrorView(
              message: controller.error.value!, onRetry: controller.fetch);
        }

        final circulars = controller.circulars;
        final selectedMonth = controller.selectedMonth.value;
        final circularsForSelectedMonth = circulars.where((raw) {
          final c = raw as Map;
          final d = DateTime.tryParse(
              (c['effectiveDate'] ?? c['createdAt'])?.toString() ?? '');
          return d != null &&
              d.year == selectedMonth.year &&
              d.month == selectedMonth.month;
        }).toList();
        final thisMonth = circularsForSelectedMonth.length;

        return RefreshIndicator(
          onRefresh: controller.fetch,
          child: ListView(
            padding: EmSpacing.listPadding,
            children: [
              ScreenIntro(
                caption: 'Circulars, notices and acknowledgements',
                selectLabel: DateFormat('MMMM yyyy').format(selectedMonth),
                onSelectTap: () async {
                  final picked = await showAppMonthPicker(
                    context,
                    initialMonth: selectedMonth,
                  );
                  if (picked != null) controller.changeMonth(picked);
                },
              ),
              StatsRow(items: [
                ('${circulars.length}', 'Published', null),
                ('$thisMonth', 'This month', null),
                (
                  '${circulars.where((c) => c['category'] == 'circular').length}',
                  'Circulars',
                  null
                ),
              ]),
              const SizedBox(height: EmSpacing.s16),
              const SectionRow(title: 'Notices'),
              if (circularsForSelectedMonth.isEmpty)
                const AppEmptyView(
                    icon: Icons.campaign_outlined,
                    title: 'No school updates yet')
              else
                ...circularsForSelectedMonth.map((raw) {
                  final c = Map<String, dynamic>.from(raw as Map);
                  final date = DateTime.tryParse(
                      (c['effectiveDate'] ?? c['createdAt'])?.toString() ?? '');
                  final category = c['category']?.toString() ?? 'notice';
                  return ListCardRow(
                    icon: Icons.description_outlined,
                    iconColor: EmColors.primary,
                    title: c['title']?.toString() ?? 'Notice',
                    subtitle: [
                      if (date != null)
                        '${date.day}/${date.month}/${date.year}',
                      category,
                    ].join(' • '),
                    trailing: AppTag(category, style: TagStyle.info),
                    onTap: () => _showCircular(context, c),
                  );
                }),
            ],
          ),
        );
      }),
    );
  }

  void _showCircular(BuildContext context, Map<String, dynamic> c) {
    final needsAck = c['requiresAcknowledgment'] == true && c['acknowledged'] != true;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EmSpacing.listPadding,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText(
                  text: c['title']?.toString() ?? 'Notice',
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: EmColors.primaryDark),
              const SizedBox(height: 10),
              CustomText(
                  text: (c['body']?.toString().isNotEmpty ?? false)
                      ? c['body'].toString()
                      : 'No further details.',
                  fontSize: 13,
                  color: EmColors.ink),
              if (needsAck && c['_id'] != null) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.of(ctx).pop();
                      await controller.acknowledge(c['_id'].toString());
                    },
                    child: const Text('Acknowledge'),
                  ),
                ),
              ],
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
