import 'package:flutter/material.dart';
import '../design/design.dart';

/// Big in-body tab title + caption (the shell header above it carries the child switcher). Copied from the teacher
/// app's tab-root pattern: `design-kit-v1` `lib/app/modules/classes/views/classes_screen.dart:59-72` (`TabHeading`).
class TabHeading extends StatelessWidget {
  final String title;
  final String? caption;
  const TabHeading({super.key, required this.title, this.caption});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsetsDirectional.only(top: EmSpacing.s8, bottom: EmSpacing.s4),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Semantics(header: true, child: Text(title, style: EmType.title.copyWith(color: EmColors.ink))),
          if (caption != null) Text(caption!, style: EmType.body.copyWith(color: EmColors.textSecondary, fontWeight: FontWeight.w400)),
        ]),
      );
}
