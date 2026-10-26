import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/design/design.dart';
import '../config/app_font_size.dart';
import '../config/app_text_styles.dart';

/// The app's long-standing text widget, now on the kit's type scale (`EmType`): the requested [fontSize] snaps to the
/// nearest kit size at or above it, so nothing renders below the kit's 12 sp minimum (caption 12, label 13, body 14,
/// body-large 16, heading 18, title 22). Weight, colour, line limits and alignment are honoured as given; the font is
/// the bundled Plus Jakarta Sans. [height] is ignored (the kit sets line heights), as it was before.
class CustomText extends StatelessWidget {
  final String text;
  final String fontFamily;
  final Color color;
  final double fontSize;
  final FontWeight fontWeight;
  final TextOverflow? overflow;
  final int? maxLines;
  final FontStyle fontStyle;
  final double? height;
  final double? letterSpacing;
  final TextDecoration? textDecoration;
  final TextDirection? textDirection;
  final TextAlign? textAlign;

  const CustomText({
    super.key,
    required this.text,
    this.color = EmColors.ink,
    this.fontSize = AppFontSize.extraSmall,
    this.fontWeight = FontWeight.w400,
    this.overflow,
    this.maxLines,
    this.textAlign,
    this.fontStyle = FontStyle.normal,
    this.height,
    this.letterSpacing,
    this.fontFamily = AppTextStyles.fontFamily,
    this.textDecoration,
    this.textDirection,
  });

  /// The kit style for a requested size.
  static TextStyle styleFor(double size) {
    if (size <= 12) return EmType.caption;
    if (size <= 13.5) return EmType.label;
    if (size <= 15) return EmType.body;
    if (size <= 17) return EmType.bodyLarge;
    if (size <= 21) return EmType.heading;
    return EmType.title;
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      text.tr,
      textAlign: textAlign,
      overflow: overflow ?? TextOverflow.visible,
      maxLines: maxLines,
      textDirection: textDirection,
      style: styleFor(fontSize).copyWith(
        color: color,
        fontWeight: fontWeight,
        letterSpacing: letterSpacing,
        fontStyle: fontStyle,
        decoration: textDecoration,
      ),
    );
  }
}
