import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_date_picker.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../core/widgets/shimmer_widgets.dart';
import '../../../components/custom_text.dart';
import '../controllers/library_controller.dart';

class LibraryScreen extends GetView<LibraryController> {
  const LibraryScreen({super.key});

  TagStyle _styleFor(String status) {
    switch (status) {
      case 'returned':
        return TagStyle.green;
      case 'overdue':
      case 'lost':
      case 'damaged':
        return TagStyle.red;
      default:
        return TagStyle.info;
    }
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Expanded(
          child: CustomText(
              text: label,
              color: AppColors.muted,
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const CustomText(
              text: 'Learning library',
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700)),
      body: Obx(() {
        if (controller.loading.value && controller.issues.isEmpty) {
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
                ...shimmerListRows(5),
              ],
            ),
          );
        }
        if (controller.error.value != null) {
          return AppErrorView(
              message: controller.error.value!, onRetry: controller.fetch);
        }

        final issues = controller.issuesForSelectedMonth;
        final active = issues
            .where((i) => i['status'] == 'issued' || i['status'] == 'overdue')
            .length;
        final overdue = issues.where((i) => i['status'] == 'overdue').length;
        final returned = issues.where((i) => i['status'] == 'returned').length;

        return RefreshIndicator(
          onRefresh: controller.fetch,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              ScreenHeader(
                title: 'Learning library',
                caption: 'Resources, reading and borrowed books',
                selectLabel:
                    DateFormat('MMMM yyyy').format(controller.selectedMonth.value),
                onSelectTap: () async {
                  final picked = await showAppMonthPicker(
                    context,
                    initialMonth: controller.selectedMonth.value,
                  );
                  if (picked != null) controller.changeMonth(picked);
                },
              ),
              const AppWeekDateStrip(),
              const SizedBox(height: AppSpacing.lg),
              StatsRow(items: [
                ('$active', 'Borrowed', null),
                ('$overdue', 'Overdue', overdue > 0 ? null : 'Clear'),
                ('$returned', 'Returned', null),
              ]),
              const SizedBox(height: AppSpacing.lg),
              if (issues.isNotEmpty) ...[
                AppCard(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      DonutRing(
                        percent: ((returned / issues.length) * 100).round(),
                        color: AppColors.purple,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const CustomText(
                                text: 'Books completed',
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                                color: AppColors.primaryColor),
                            const SizedBox(height: 4),
                            CustomText(
                                text:
                                    '$returned of ${issues.length} borrowed books returned',
                                color: AppColors.muted,
                                fontSize: 10.5,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 10),
                            _legendItem(AppColors.purple, 'Returned · $returned'),
                            const SizedBox(height: 6),
                            _legendItem(AppColors.line, 'Outstanding · ${issues.length - returned}'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
              const SectionRow(title: 'Borrowed & returned books'),
              if (issues.isEmpty)
                const AppEmptyView(
                    icon: Icons.local_library_outlined,
                    title: 'No library activity yet')
              else
                ...issues.map((raw) {
                  final b = Map<String, dynamic>.from(raw as Map);
                  final status = b['status']?.toString() ?? '';
                  final due = b['dueDate'] != null
                      ? DateTime.tryParse(b['dueDate'].toString())
                      : null;
                  final returnedDate = b['returnDate'] != null
                      ? DateTime.tryParse(b['returnDate'].toString())
                      : null;
                  final subtitle = status == 'returned' && returnedDate != null
                      ? 'Returned ${returnedDate.day}/${returnedDate.month}/${returnedDate.year}'
                      : (due != null
                          ? 'Due ${due.day}/${due.month}/${due.year}'
                          : '');
                  return ListCardRow(
                    icon: Icons.menu_book_rounded,
                    iconColor: AppColors.purple,
                    title: b['bookTitle']?.toString() ?? 'Book',
                    subtitle: subtitle,
                    trailing: AppTag(
                        status.isEmpty
                            ? '—'
                            : status[0].toUpperCase() + status.substring(1),
                        style: _styleFor(status)),
                  );
                }),
            ],
          ),
        );
      }),
    );
  }
}
