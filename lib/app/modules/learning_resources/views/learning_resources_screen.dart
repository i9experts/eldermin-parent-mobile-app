import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../core/widgets/shimmer_widgets.dart';
import '../../../components/custom_text.dart';
import '../controllers/learning_resources_controller.dart';

class LearningResourcesScreen extends GetView<LearningResourcesController> {
  const LearningResourcesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const CustomText(
              text: 'Learning resources',
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700)),
      body: Obx(() {
        if (controller.loading.value && controller.plans.isEmpty) {
          return AppShimmer(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                const ShimmerScreenHeaderSkeleton(withChip: false),
                const SizedBox(height: AppSpacing.md),
                ...shimmerListRows(6),
              ],
            ),
          );
        }
        if (controller.error.value != null) {
          return AppErrorView(message: controller.error.value!, onRetry: controller.fetch);
        }

        final plans = controller.plans;

        return RefreshIndicator(
          onRefresh: controller.fetch,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              const ScreenHeader(title: 'Learning resources', caption: 'Lesson plans and shared materials'),
              const SizedBox(height: AppSpacing.lg),
              StatsRow(items: [
                ('${plans.length}', 'Lesson plans', null),
                (
                  '${plans.map((p) => Map<String, dynamic>.from(p as Map)['subject']?.toString() ?? '').toSet().length}',
                  'Subjects',
                  null
                ),
              ]),
              const SizedBox(height: AppSpacing.lg),
              if (plans.isEmpty)
                const AppEmptyView(
                  icon: Icons.folder_open_outlined,
                  title: 'No learning resources shared yet',
                  subtitle: "Materials your child's teachers share will appear here.",
                )
              else
                ...plans.map((raw) {
                  final p = Map<String, dynamic>.from(raw as Map);
                  final subject = p['subject']?.toString() ?? '';
                  final topic = p['topic']?.toString() ?? 'Lesson';
                  final planDate = DateTime.tryParse(p['planDate']?.toString() ?? '');
                  final resources = (p['resources'] as List<dynamic>?) ?? [];
                  return ListCardRow(
                    icon: Icons.menu_book_outlined,
                    iconColor: AppColors.blue,
                    title: topic,
                    subtitle: [
                      if (subject.isNotEmpty) subject,
                      if (planDate != null) '${planDate.day}/${planDate.month}/${planDate.year}',
                    ].join(' · '),
                    trailing: AppTag('${resources.length} resources',
                        style: resources.isEmpty ? TagStyle.neutral : TagStyle.info),
                  );
                }),
            ],
          ),
        );
      }),
    );
  }
}
