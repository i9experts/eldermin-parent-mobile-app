import 'package:flutter/material.dart';
import '../design/design.dart';

/// Semantic color pairs (foreground + tinted background) for badges/tags; [tone] is the kit tone they render with.
class TagStyle {
  final Color fg;
  final Color bg;
  final EmTone tone;
  const TagStyle(this.fg, this.bg, {this.tone = EmTone.neutral});

  static const info = TagStyle(EmColors.onInfoContainer, EmColors.infoContainer, tone: EmTone.info);
  static const amber = TagStyle(EmColors.onWarningContainer, EmColors.warningContainer, tone: EmTone.warning);
  static const green = TagStyle(EmColors.onSuccessContainer, EmColors.successContainer, tone: EmTone.success);
  static const red = TagStyle(EmColors.onErrorContainer, EmColors.errorContainer, tone: EmTone.error);
  static const neutral = TagStyle(EmColors.textSecondary, EmColors.border, tone: EmTone.neutral);
}

class AppTheme {
  AppTheme._();

  /// Entry point used by `main.dart` and every widget test: the Eldermin design theme.
  static ThemeData get light => buildEmTheme();
}
