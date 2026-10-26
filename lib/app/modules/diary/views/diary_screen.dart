import 'package:flutter/material.dart';
import '../../../../core/design/design.dart';
import 'package:get/get.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../core/widgets/locked_feature_view.dart';
import '../../../../core/widgets/shimmer_widgets.dart';
import '../../../components/custom_text.dart';
import '../controllers/diary_controller.dart';

const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

class DiaryScreen extends GetView<DiaryController> {
  const DiaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return EmScaffold(
      appBar: EmAppBar(title: 'Class diary'),
      body: Obx(() {
        if (controller.loading.value && controller.entries.isEmpty) {
          return AppShimmer(
            child: ListView(
              padding: EmSpacing.listPadding,
              children: [
                const ShimmerScreenIntroSkeleton(withChip: false),
                const SizedBox(height: EmSpacing.s12),
                ...shimmerListRows(4),
              ],
            ),
          );
        }
        if (controller.error.value != null) {
          return AppErrorView(message: controller.error.value!, onRetry: controller.fetch);
        }
        if (controller.locked.value) {
          return const LockedFeatureView();
        }

        final entries = controller.entries;
        return RefreshIndicator(
          onRefresh: controller.fetch,
          child: ListView(
            padding: EmSpacing.listPadding,
            children: [
              const ScreenIntro(caption: "Daily classwork & homework from your child's teachers"),
              const SizedBox(height: EmSpacing.s16),
              if (entries.isEmpty)
                const AppEmptyView(
                  icon: Icons.auto_stories_outlined,
                  title: 'No diary entries yet',
                  subtitle: 'Entries your child\'s teachers share will appear here.',
                )
              else
                ...entries.map((raw) => _DiaryCard(entry: Map<String, dynamic>.from(raw as Map))),
            ],
          ),
        );
      }),
    );
  }
}

class _DiaryCard extends GetView<DiaryController> {
  final Map<String, dynamic> entry;
  const _DiaryCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final id = entry['_id']?.toString() ?? '';
    final date = DateTime.tryParse(entry['diaryDate']?.toString() ?? '')?.toLocal();
    final dateLabel = date == null
        ? ''
        : '${_weekdays[date.weekday - 1]}, ${date.day} ${_months[date.month - 1]} ${date.year}';
    final teacher = entry['teacherName']?.toString() ?? '';
    final periods = ((entry['periods'] as List<dynamic>?) ?? [])
        .map((p) => Map<String, dynamic>.from(p as Map))
        .toList();

    return AppCard(
      padding: EmSpacing.cardPad,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(text: dateLabel, fontSize: 15, fontWeight: FontWeight.w700, color: EmColors.ink),
                    if (teacher.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: CustomText(text: 'By $teacher', fontSize: 12, color: EmColors.textSecondary),
                      ),
                  ],
                ),
              ),
              AppTag('${periods.length} ${periods.length == 1 ? 'subject' : 'subjects'}'),
              const SizedBox(width: 4),
              Obx(() {
                final busy = controller.downloadingId.value == id;
                return busy
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                      )
                    : IconButton(
                        tooltip: 'Open PDF',
                        icon: const Icon(Icons.picture_as_pdf_outlined, color: EmColors.primary),
                        onPressed: id.isEmpty ? null : () => controller.openPdf(id),
                      );
              }),
            ],
          ),
          for (final p in periods) ...[
            const Divider(height: 20),
            _PeriodBlock(period: p),
          ],
        ],
      ),
    );
  }
}

class _PeriodBlock extends StatelessWidget {
  final Map<String, dynamic> period;
  const _PeriodBlock({required this.period});

  String _s(String key) => period[key]?.toString().trim() ?? '';

  @override
  Widget build(BuildContext context) {
    final title = _s('title');
    final description = _s('description');
    final classwork = _s('classworkDescription');
    final homework = _s('homeworkDescription');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(text: _s('subject'), fontSize: 14, fontWeight: FontWeight.w700, color: EmColors.primary),
        if (title.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: CustomText(text: title, fontSize: 13, fontWeight: FontWeight.w600, color: EmColors.ink),
          ),
        if (description.isNotEmpty) _line(null, description),
        if (classwork.isNotEmpty) _line('Classwork', classwork),
        if (homework.isNotEmpty) _line('Homework', homework),
      ],
    );
  }

  Widget _line(String? label, String text) => Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (label != null)
              CustomText(text: label, fontSize: 11, fontWeight: FontWeight.w700, color: EmColors.textSecondary),
            CustomText(text: text, fontSize: 13, color: EmColors.ink),
          ],
        ),
      );
}
