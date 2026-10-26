import 'package:flutter/material.dart';
import '../../core/design/design.dart';
import '../config/app_dimens.dart';
import '../config/app_font_size.dart';
import '../config/app_text_styles.dart';

/// The app's long-standing button, now a wrapper over the kit's buttons (same constructor, no call-site change). The
/// variant follows the colours a call site asks for:
///
/// * **danger** - [color] is an error colour (red, `delete`, `error`...) -> `EmPrimaryButton(destructive: true)`
///   (kit `em_buttons.dart:7`, error fill, on-error label);
/// * **secondary** - [color] is white / transparent / a tint or a muted grey, or [borderColor] is set (an outlined button)
///   -> `EmSecondaryButton` (kit `em_buttons.dart:51`, white with an accent border); with an error [textColor] or
///   [borderColor] it is `destructive: true`;
/// * **primary** (everything else, e.g. the navy `color` the forms pass) -> `EmMorphButton`, the accent button that morphs
///   into a spinner.
///
/// Mapping: [label], [onPressed] / [enabled] (null while disabled: dimmed or kit-disabled, not tappable), [width] (a fixed
/// width, default: the available width). Loading: the call sites pass an empty [label] and a spinner as [prefix] while the
/// request runs; that pattern is the kit's loading state in every variant (a spinner that ignores taps).
///
/// No kit equivalent (accepted and ignored): [fontFamily], [fontSize], [fontWeight] (no call site passes it), [borderRadius],
/// [height] (kit buttons are 52 dp), and a [prefix] / [suffix] next to a non-empty label (no call site does that). The exact
/// [color] / [textColor] only choose the variant; the kit fixes the fills.
class CustomButton extends StatelessWidget {
  const CustomButton({
    super.key,
    required this.label,
    this.fontFamily = AppTextStyles.fontFamily,
    this.color = EmColors.primaryDark,
    required this.onPressed,
    this.enabled = true,
    this.textColor = EmColors.surface,
    this.fontSize = AppFontSize.small,
    this.fontWeight = FontWeight.w500,
    this.prefix,
    this.suffix,
    this.borderColor = Colors.transparent,
    this.borderRadius = AppDimen.borderRadius,
    this.width,
    this.height = 45,
  });

  final String label;
  final String fontFamily;
  final Color color;
  final Color textColor;
  final Color borderColor;
  final bool enabled;
  final void Function()? onPressed;
  final double fontSize;
  final FontWeight fontWeight;
  final Widget? prefix;
  final Widget? suffix;
  final double? width;
  final double height;
  final double borderRadius;

  static bool _isError(Color c) =>
      c == EmColors.error || c == EmColors.onErrorContainer || c == EmColors.errorContainer;
  static bool _isNeutralFill(Color c) =>
      c == EmColors.surface ||
      c == EmColors.background ||
      c == EmColors.primaryTint ||
      c == EmColors.border ||
      c == EmColors.disabled ||
      c == EmColors.outline ||
      c == EmColors.textSecondary ||
      c == EmColors.textTertiary ||
      c == Colors.transparent ||
      c == Colors.white;

  @override
  Widget build(BuildContext context) {
    final loading = label.isEmpty && prefix != null;
    final onTap = enabled ? onPressed : null;
    final outlined = borderColor != Colors.transparent;
    final Widget button;
    if (_isError(color)) {
      button = EmPrimaryButton(label: label.isEmpty ? 'Please wait' : label, onPressed: onTap, loading: loading, destructive: true);
    } else if (_isNeutralFill(color) || outlined) {
      button = EmSecondaryButton(
        label: label.isEmpty ? 'Please wait' : label,
        onPressed: onTap,
        loading: loading,
        expand: true,
        destructive: _isError(textColor) || _isError(borderColor),
      );
    } else {
      button = EmMorphButton(
        label: label,
        loadingLabel: 'Please wait',
        phase: loading ? EmMorphPhase.loading : EmMorphPhase.idle,
        onPressed: onTap,
      );
    }
    return width == null ? button : SizedBox(width: width, child: button);
  }
}
