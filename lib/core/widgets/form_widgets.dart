import 'package:flutter/material.dart';
import '../design/design.dart';

/// A tappable form field (a date, a time, a choice) in the kit's form style. Parent copy of the teacher app's `PickField`
/// (`design-kit-v1` `lib/app/modules/ptm/views/widgets/ptm_widgets.dart:80-110`): 48 dp minimum, an icon, the value (bold ink once
/// chosen, secondary while it is a prompt) and an error border.
class AppPickField extends StatelessWidget {
  const AppPickField({super.key, required this.icon, required this.text, required this.filled, required this.onTap, this.error});

  final IconData icon;
  final String text;
  final bool filled;
  final String? error;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: text,
      excludeSemantics: true,
      onTap: onTap,
      child: InkWell(
        borderRadius: EmRadius.mdAll,
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: EmSpacing.minTouch),
          padding: const EdgeInsetsDirectional.symmetric(horizontal: EmSpacing.s12, vertical: EmSpacing.s12),
          decoration: BoxDecoration(color: EmColors.surface, borderRadius: EmRadius.mdAll, border: Border.all(color: error == null ? EmColors.outline : EmColors.error)),
          child: Row(children: [
            ExcludeSemantics(child: Icon(icon, size: 20, color: EmColors.primary)),
            const SizedBox(width: EmSpacing.s12),
            Expanded(child: Text(text, style: EmType.label.copyWith(color: filled ? EmColors.ink : EmColors.textSecondary, fontWeight: filled ? FontWeight.w700 : FontWeight.w500))),
          ]),
        ),
      ),
    );
  }
}

/// A validation message: glyph + words in the error colour (readable at 1.3x, wraps instead of clipping). Teacher pattern:
/// `ptm_new_screen.dart:129-133` (`_error`).
class AppFieldError extends StatelessWidget {
  const AppFieldError(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsetsDirectional.only(top: EmSpacing.s4),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Padding(padding: EdgeInsetsDirectional.only(top: EmSpacing.s2), child: Icon(Icons.error_outline_rounded, size: 16, color: EmColors.error)),
          const SizedBox(width: EmSpacing.s4),
          Expanded(child: Semantics(liveRegion: true, child: Text(text, style: EmType.caption.copyWith(color: EmColors.error, fontWeight: FontWeight.w600)))),
        ]),
      );
}

/// A label above a form control (teacher `FormLabel`, `homework_widgets.dart:286-298`).
class AppFormLabel extends StatelessWidget {
  const AppFormLabel(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsetsDirectional.only(bottom: EmSpacing.s8, top: EmSpacing.s2),
        child: Text(text, style: EmType.label.copyWith(color: EmColors.textSecondary)),
      );
}

/// A label / value row of a details card (teacher `_kv`, `profile_screen.dart:155-164`). The value stays on screen even when
/// it is the placeholder the caller passes (the parent app shows "—" for a field the school has not filled in).
class AppKeyValueRow extends StatelessWidget {
  const AppKeyValueRow(this.label, this.value, {super.key});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsetsDirectional.symmetric(vertical: EmSpacing.s8),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(width: 120, child: Text(label, style: EmType.caption.copyWith(color: EmColors.textSecondary, fontWeight: FontWeight.w700))),
          Expanded(child: Text(value, style: EmType.label.copyWith(color: EmColors.ink, fontWeight: FontWeight.w600))),
        ]),
      );
}
