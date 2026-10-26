import 'package:flutter/material.dart';
import '../design/design.dart';

/// Skeleton placeholders for the loading states, on the kit's [EmShimmer] / [EmSkeletonBox] / [EmSkeletonRow].
/// Wrap once per screen around the whole loading-state layout (one shimmer drives every bone, so the sweep stays
/// in sync). Each skeleton mirrors the shape of the widget it stands in for.

/// Wraps a skeleton layout in the shimmer sweep animation.
class AppShimmer extends StatelessWidget {
  final Widget child;
  const AppShimmer({super.key, required this.child});

  @override
  Widget build(BuildContext context) => EmShimmer(child: child);
}

/// The basic "line" placeholder bone.
class ShimmerBone extends StatelessWidget {
  final double? width;
  final double height;
  final double radius;
  const ShimmerBone({super.key, this.width, this.height = 14, this.radius = 6});

  @override
  Widget build(BuildContext context) => EmSkeletonBox(width: width, height: height, radius: radius);
}

/// A circular bone - icon badges, avatars.
class ShimmerCircle extends StatelessWidget {
  final double size;
  const ShimmerCircle({super.key, this.size = 38});

  @override
  Widget build(BuildContext context) => EmSkeletonBox(height: size, circle: true);
}

/// Mirrors a tab root's [TabHeading] - title + caption + optional trailing chip.
class ShimmerScreenHeaderSkeleton extends StatelessWidget {
  final bool withChip;
  const ShimmerScreenHeaderSkeleton({super.key, this.withChip = true});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: EmSpacing.block),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                EmSkeletonBox(width: 160, height: 24),
                SizedBox(height: EmSpacing.s8),
                EmSkeletonBox(width: 210, height: 14),
              ],
            ),
          ),
          if (withChip) ...[
            const SizedBox(width: EmSpacing.s12),
            const EmSkeletonBox(width: 78, height: 28, radius: EmRadius.pill),
          ],
        ],
      ),
    );
  }
}

/// Mirrors [ScreenIntro] - one caption line + optional chip (the title is the app bar's).
class ShimmerScreenIntroSkeleton extends StatelessWidget {
  final bool withChip;
  const ShimmerScreenIntroSkeleton({super.key, this.withChip = true});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: EmSpacing.block),
      child: Row(
        children: [
          const Expanded(child: Align(alignment: AlignmentDirectional.centerStart, child: EmSkeletonBox(width: 220, height: 14))),
          if (withChip) ...[
            const SizedBox(width: EmSpacing.s12),
            const EmSkeletonBox(width: 110, height: 28, radius: EmRadius.pill),
          ],
        ],
      ),
    );
  }
}

/// Mirrors [DateStripWidget] / [AppWeekDateStrip] - 7 equal day pills.
class ShimmerDateStripSkeleton extends StatelessWidget {
  const ShimmerDateStripSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < 7; i++) ...[
          if (i > 0) const SizedBox(width: EmSpacing.s4),
          const Expanded(child: EmSkeletonBox(height: 56, radius: EmRadius.pill)),
        ],
      ],
    );
  }
}

/// Mirrors [StatsRow] - N equal stat tiles, each a value bone + label bone.
class ShimmerStatsRowSkeleton extends StatelessWidget {
  final int count;
  const ShimmerStatsRowSkeleton({super.key, this.count = 3});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < count; i++) ...[
          if (i > 0) const SizedBox(width: EmSpacing.s8),
          Expanded(
            child: Container(
              padding: EmSpacing.cardPadCompact,
              decoration: const BoxDecoration(color: EmColors.surface, borderRadius: EmRadius.tileAll),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  EmSkeletonBox(width: 30, height: 18),
                  SizedBox(height: EmSpacing.s8),
                  EmSkeletonBox(width: 44, height: 10),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Mirrors [HeroCard] - one rounded block at the same radius as the real hero card.
class ShimmerHeroCardSkeleton extends StatelessWidget {
  const ShimmerHeroCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsetsDirectional.all(EmSpacing.s16),
      decoration: const BoxDecoration(color: EmColors.surface, borderRadius: EmRadius.heroAll),
      child: const Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    EmSkeletonBox(width: 120, height: 12),
                    SizedBox(height: EmSpacing.s12),
                    EmSkeletonBox(width: 90, height: 30),
                    SizedBox(height: EmSpacing.s12),
                    EmSkeletonBox(width: 150, height: 12),
                  ],
                ),
              ),
              EmSkeletonBox(height: 96, circle: true),
            ],
          ),
          SizedBox(height: EmSpacing.s16),
          Row(
            children: [
              Expanded(child: EmSkeletonBox(height: 96, radius: EmRadius.tile)),
              SizedBox(width: EmSpacing.s8),
              Expanded(child: EmSkeletonBox(height: 96, radius: EmRadius.tile)),
              SizedBox(width: EmSpacing.s8),
              Expanded(child: EmSkeletonBox(height: 96, radius: EmRadius.tile)),
            ],
          ),
        ],
      ),
    );
  }
}

/// Mirrors a one-bar progress card ("Requests approved", "Profile completeness"): a title bone and a thin bar bone.
class ShimmerProgressCardSkeleton extends StatelessWidget {
  const ShimmerProgressCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EmSpacing.cardPad,
      decoration: const BoxDecoration(color: EmColors.surface, borderRadius: EmRadius.cardAll),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EmSkeletonBox(width: 130, height: 14),
          SizedBox(height: EmSpacing.s12),
          EmSkeletonBox(width: double.infinity, height: 8, radius: EmRadius.pill),
        ],
      ),
    );
  }
}

/// Mirrors a summary hero card (name + tag, a few detail lines, count tags): the Early Years summary.
class ShimmerSummaryCardSkeleton extends StatelessWidget {
  const ShimmerSummaryCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsetsDirectional.all(EmSpacing.s16),
      decoration: const BoxDecoration(color: EmColors.surface, borderRadius: EmRadius.heroAll),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            EmSkeletonBox(height: 40, circle: true),
            SizedBox(width: EmSpacing.s12),
            Expanded(child: EmSkeletonBox(height: 20)),
            SizedBox(width: EmSpacing.s12),
            EmSkeletonBox(width: 80, height: 24, radius: EmRadius.pill),
          ]),
          SizedBox(height: EmSpacing.s16),
          EmSkeletonBox(width: 150, height: 14),
          SizedBox(height: EmSpacing.s8),
          EmSkeletonBox(width: 190, height: 14),
          SizedBox(height: EmSpacing.s16),
          Row(children: [
            EmSkeletonBox(width: 110, height: 26, radius: EmRadius.pill),
            SizedBox(width: EmSpacing.s8),
            EmSkeletonBox(width: 110, height: 26, radius: EmRadius.pill),
          ]),
        ],
      ),
    );
  }
}

/// Mirrors a media card (a photo block, a title, a date and two text lines): the Early Years portfolio entry.
class ShimmerMediaCardSkeleton extends StatelessWidget {
  const ShimmerMediaCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsetsDirectional.only(bottom: EmSpacing.row),
      padding: EmSpacing.cardPad,
      decoration: const BoxDecoration(color: EmColors.surface, borderRadius: EmRadius.cardAll),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EmSkeletonBox(width: double.infinity, height: 150, radius: EmRadius.md),
          SizedBox(height: EmSpacing.s12),
          EmSkeletonBox(width: 160, height: 16),
          SizedBox(height: EmSpacing.s8),
          EmSkeletonBox(width: 90, height: 12),
          SizedBox(height: EmSpacing.s8),
          EmSkeletonBox(width: double.infinity, height: 12),
        ],
      ),
    );
  }
}

/// Mirrors the profile header card: avatar circle, name and one line.
class ShimmerProfileHeaderSkeleton extends StatelessWidget {
  const ShimmerProfileHeaderSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EmSpacing.cardPad,
      decoration: const BoxDecoration(color: EmColors.surface, borderRadius: EmRadius.cardAll),
      child: const Column(
        children: [
          EmSkeletonBox(height: 96, circle: true),
          SizedBox(height: EmSpacing.s12),
          EmSkeletonBox(width: 150, height: 18),
          SizedBox(height: EmSpacing.s8),
          EmSkeletonBox(width: 190, height: 12),
        ],
      ),
    );
  }
}

/// Mirrors the `AppCard`-wrapped chart cards - a title bone above a full-width chart-shaped block.
class ShimmerChartSkeleton extends StatelessWidget {
  const ShimmerChartSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EmSpacing.cardPad,
      decoration: const BoxDecoration(color: EmColors.surface, borderRadius: EmRadius.cardAll),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EmSkeletonBox(width: 90, height: 14),
          SizedBox(height: EmSpacing.s12),
          EmSkeletonBox(width: double.infinity, height: 120, radius: EmRadius.control),
        ],
      ),
    );
  }
}

/// Mirrors [ListCardRow] / [AppCard] - the workhorse for every list screen (the kit's [EmSkeletonRow]).
class ShimmerListRowSkeleton extends StatelessWidget {
  const ShimmerListRowSkeleton({super.key});

  @override
  Widget build(BuildContext context) => const EmSkeletonRow();
}

/// Convenience: N [ShimmerListRowSkeleton]s in a row of their own.
List<Widget> shimmerListRows([int count = 6]) => List.generate(count, (_) => const ShimmerListRowSkeleton());
