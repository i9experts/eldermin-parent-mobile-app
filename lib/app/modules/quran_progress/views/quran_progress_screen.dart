import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/design/design.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../core/widgets/locked_feature_view.dart';
import '../../../../core/widgets/shimmer_widgets.dart';
import '../controllers/quran_progress_controller.dart';
import 'nazra_section.dart';
import 'qaida_section.dart';

/// "Qur'an progress": the child's Qur'an journey as the school records it. A programme appears once the child has a record in it: Qaida
/// & Tajweed first, then Nazra as the child moves on, and both stay available (a tab each when both exist, Nazra - the later stage -
/// first). A child with no record in any programme gets an honest empty state, never made-up progress.
class QuranProgressScreen extends GetView<QuranProgressController> {
  const QuranProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return EmScaffold(
      appBar: EmAppBar(title: "Qur'an progress"),
      body: Obx(() {
        final qaida = controller.qaida.value;
        final nazra = controller.nazra.value;
        if (controller.loading.value && controller.isEmpty) return const _Loading();
        if (controller.error.value != null) return AppErrorView(message: controller.error.value!, onRetry: controller.fetch);
        if (controller.locked.value) return const LockedFeatureView();
        final seg = controller.segment;
        return RefreshIndicator(
          onRefresh: controller.fetch,
          child: ListView(
            padding: EmSpacing.listPadding,
            children: [
              const ScreenIntro(caption: 'Qaida & Tajweed, then Nazra, as your child moves on'),
              if (controller.isEmpty)
                const AppEmptyView(
                  key: Key('quran_empty'),
                  icon: Icons.menu_book_outlined,
                  title: 'No Qur\'an progress yet',
                  subtitle: "Your child's Qaida & Tajweed and Nazra progress will appear here once the teacher starts recording it.",
                )
              else ...[
                if (qaida != null && nazra != null) ...[
                  SegmentedControl(options: const ['Qaida & Tajweed', 'Nazra'], selectedIndex: seg, onChanged: controller.pick),
                  const SizedBox(height: EmSpacing.s16),
                ],
                if (seg == 1 && nazra != null) ...nazraSection(nazra) else if (qaida != null) ...qaidaSection(controller, qaida),
              ],
            ],
          ),
        );
      }),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) => ListView(
        padding: EmSpacing.listPadding,
        children: const [ShimmerHeroCardSkeleton(), SizedBox(height: EmSpacing.s16), ShimmerListRowSkeleton(), ShimmerListRowSkeleton()],
      );
}
