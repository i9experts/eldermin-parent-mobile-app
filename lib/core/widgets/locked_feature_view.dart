import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../../app/components/custom_text.dart';

/// Shown instead of a screen's normal content when the school has paused
/// that premium feature for this parent + child. This is a calm, expected
/// state, not an error - no red styling, no retry button, no mention of
/// why (fee default, non-cooperation, etc. are an admin's internal
/// decision, not something to put in front of the parent).
class LockedFeatureView extends StatelessWidget {
  const LockedFeatureView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: const BoxDecoration(color: AppColors.background, shape: BoxShape.circle),
              child: const Icon(Icons.lock_outline_rounded, color: AppColors.faint, size: 28),
            ),
            const SizedBox(height: 12),
            const CustomText(
              text: 'This feature is currently paused',
              fontWeight: FontWeight.w700,
              color: AppColors.primaryColor,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            const CustomText(
              text: 'Please contact the school office for assistance.',
              color: AppColors.faint,
              fontSize: 12,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
