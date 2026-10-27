import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/design/design.dart';

/// The app's long-standing text field, now a wrapper over the kit's [EmTextField] (same constructor, no call-site change).
///
/// Mapping: [label] (falls back to [hintText] when null, since the kit field is always labelled) -> label; [hintText] ->
/// hint (only when there is a label); [controller], [focusNode], [obscureText], [keyboardType], [maxLines], [validator],
/// [onChanged], [onFieldSubmitted] -> the same; [errorText] -> errorText; [suffixIcon] -> suffix; an [Icon] given as
/// [prefixIcon] -> prefixIcon; [inputFormatters] -> the same, plus a length limit for [maxLength] (the kit shows no
/// counter); [fillColor] -> fillColor; [borderBorderradius] -> radius.
///
/// No kit equivalent (accepted and ignored): [isDecoration], [color], [textColor], [filled], [borderRadius], [ispadding],
/// [isborder] (the kit field always has its own outline) and [contentPadding]. A [prefixIcon] that is not an [Icon] is shown
/// in front of the field. A multi-line field keeps its label at the top (wrapper adaptation: `alignLabelWithHint`).

// ignore: must_be_immutable
class CustomTextField extends StatelessWidget {
  final void Function(String)? onChanged;
  final String? Function(String?)? validator;
  final Function(String)? onFieldSubmitted;
  final String? label;
  final bool isDecoration;
  final int? maxLength;
  final int? maxLines;
  final String? hintText;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final bool? filled;
  final Color? fillColor;
  final Color color;
  final Color textColor;
  final BorderRadiusGeometry? borderRadius;
  final bool ispadding;
  final bool isborder;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final double borderBorderradius;
  final EdgeInsetsGeometry? contentPadding;
  final List<TextInputFormatter>? inputFormatters;
  final String? errorText;

  const CustomTextField({
    super.key,
    this.borderBorderradius = EmRadius.control,
    this.label,
    this.hintText,
    this.prefixIcon,
    this.isDecoration = true,
    this.obscureText = false,
    this.suffixIcon,
    this.filled = true,
    this.fillColor = EmColors.surface,
    this.borderRadius,
    this.ispadding = false,
    this.isborder = false,
    this.controller,
    this.focusNode,
    this.onChanged,
    this.color = EmColors.surface,
    this.textColor = EmColors.ink,
    this.keyboardType,
    this.validator,
    this.maxLines = 1,
    this.onFieldSubmitted,
    this.maxLength,
    this.contentPadding,
    this.inputFormatters,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    // the kit field's prefix slot is an icon: an [Icon] passed here keeps its glyph
    final iconPrefix = prefixIcon is Icon ? (prefixIcon as Icon).icon : null;
    Widget field = EmTextField(
      label: label ?? hintText ?? '',
      hint: label == null ? null : hintText,
      controller: controller,
      focusNode: focusNode,
      obscureText: obscureText,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      onChanged: onChanged,
      onSubmitted: onFieldSubmitted == null ? null : (v) => onFieldSubmitted!(v),
      errorText: errorText,
      prefixIcon: iconPrefix,
      suffix: suffixIcon,
      inputFormatters: [
        ...?inputFormatters,
        if (maxLength != null) LengthLimitingTextInputFormatter(maxLength),
      ],
      fillColor: fillColor,
      radius: borderBorderradius,
    );
    // a multi-line field keeps its label / hint at the top-left (the single-line default centres it vertically)
    if (maxLines == null || maxLines! > 1) {
      final theme = Theme.of(context);
      field = Theme(
        data: theme.copyWith(inputDecorationTheme: theme.inputDecorationTheme.copyWith(alignLabelWithHint: true)),
        child: field,
      );
    }
    // a prefix that is not an icon (a country code, a currency, a unit) carries meaning: it is shown in front of the field
    if (prefixIcon != null && prefixIcon is! Icon) {
      field = Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Padding(padding: const EdgeInsetsDirectional.only(end: EmSpacing.s8), child: Align(alignment: AlignmentDirectional.centerStart, widthFactor: 1, child: prefixIcon)),
        ),
        Expanded(child: field),
      ]);
    }
    return field;
  }
}
