import 'package:flutter/material.dart';
import '../../core/design/design.dart';
import '../config/app_dimens.dart';
import '../config/app_font_size.dart';
import '../config/app_text_styles.dart';
import '../../core/theme/app_theme.dart';

/// The app's long-standing button, now a wrapper over the kit's [EmMorphButton] (same constructor, no call-site change).
///
/// Mapping: [label] -> label; [onPressed] / [enabled] -> `onPressed` (null while disabled: dimmed and not tappable);
/// [width] -> a fixed width (default: the available width). Loading: the call sites pass an empty [label] and a spinner
/// as [prefix] while the request runs - that pattern is the kit's loading phase (the button morphs into a spinner and
/// ignores taps).
///
/// No kit equivalent (accepted and ignored): [fontFamily], [color], [textColor], [fontSize], [fontWeight], [borderColor],
/// [borderRadius], [height] (the kit button is 52 dp, accent fill, ink label, 10 dp corners) and a [prefix] / [suffix]
/// next to a non-empty label (no call site does that).
class CustomButton extends StatelessWidget {
  const CustomButton({
    super.key,
    required this.label,
    this.fontFamily = AppTextStyles.fontFamily,
    this.color = AppColors.appBarColor,
    required this.onPressed,
    this.enabled = true,
    this.textColor = AppColors.white,
    this.fontSize = AppFontSize.small,
    this.fontWeight = FontWeight.w500,
    this.prefix,
    this.suffix,
    this.borderColor = AppColors.transparent,
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

  @override
  Widget build(BuildContext context) {
    final loading = label.isEmpty && prefix != null;
    final button = EmMorphButton(
      label: label,
      loadingLabel: 'Please wait',
      phase: loading ? EmMorphPhase.loading : EmMorphPhase.idle,
      onPressed: enabled ? onPressed : null,
    );
    return width == null ? button : SizedBox(width: width, child: button);
  }
}
