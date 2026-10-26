import 'package:flutter/material.dart';
import '../design/design.dart';

/// Shown instead of a screen's normal content when the school has paused that premium feature for this parent +
/// child. A calm, expected state, not an error - no red styling, no retry button, no mention of why (fee default,
/// non-cooperation, etc. are an admin's internal decision, not something to put in front of the parent).
/// Drawn with the kit's empty state (lock icon, same copy).
class LockedFeatureView extends StatelessWidget {
  const LockedFeatureView({super.key});

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, c) => EmEmptyState(
          icon: Icons.lock_outline_rounded,
          title: 'This feature is currently paused',
          message: 'Please contact the school office for assistance.',
          scroll: c.hasBoundedHeight,
        ),
      );
}
