import 'package:flutter/material.dart';
import '../design/design.dart';

/// Section title row for a screen's scrolling content: heading on the left, an optional "See all" action on the
/// right. Parent composite built from kit tokens (the kit has no section header).
class EmSectionHeader extends StatelessWidget {
  const EmSectionHeader({super.key, required this.title, this.actionLabel = 'See all', this.onAction});

  final String title;
  final String actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(top: EmSpacing.s8, bottom: EmSpacing.s4),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: EmType.heading.copyWith(color: EmColors.ink)),
            ),
          ),
          if (onAction != null) EmTextAction(label: actionLabel, onPressed: onAction),
        ],
      ),
    );
  }
}
