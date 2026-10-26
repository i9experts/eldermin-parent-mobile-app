import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/design/design.dart';
import '../../core/theme/app_theme.dart';
import '../config/app_dimens.dart';

/// The app's long-standing text field, now a wrapper over the kit's [EmTextField] (same constructor, no call-site change).
///
/// Mapping: [label] (falls back to [hintText] when null, since the kit field is always labelled) -> label; [hintText] ->
/// hint (only when there is a label); [controller], [focusNode], [obscureText], [keyboardType], [maxLines], [validator],
/// [onChanged], [onFieldSubmitted] -> the same; [errorText] -> errorText; [suffixIcon] -> suffix; an [Icon] given as
/// [prefixIcon] -> prefixIcon; [inputFormatters] -> the same, plus a length limit for [maxLength] (the kit shows no
/// counter); [fillColor] -> fillColor; [borderBorderradius] -> radius.
///
/// No kit equivalent (accepted and ignored): [isDecoration], [color], [textColor], [filled], [borderRadius], [ispadding],
/// [isborder] (the kit field always has its own outline), [contentPadding], and a [prefixIcon] that is not an [Icon].

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
    this.borderBorderradius = AppDimen.borderRadius,
    this.label,
    this.hintText,
    this.prefixIcon,
    this.isDecoration = true,
    this.obscureText = false,
    this.suffixIcon,
    this.filled = true,
    this.fillColor = AppColors.white,
    this.borderRadius,
    this.ispadding = false,
    this.isborder = false,
    this.controller,
    this.focusNode,
    this.onChanged,
    this.color = AppColors.white,
    this.textColor = AppColors.black,
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
    // the kit field's prefix is an icon: an [Icon] passed here keeps its glyph
    final prefix = prefixIcon is Icon ? (prefixIcon as Icon).icon : null;
    return EmTextField(
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
      prefixIcon: prefix,
      suffix: suffixIcon,
      inputFormatters: [
        ...?inputFormatters,
        if (maxLength != null) LengthLimitingTextInputFormatter(maxLength),
      ],
      fillColor: fillColor,
      radius: borderBorderradius,
    );
  }
}
