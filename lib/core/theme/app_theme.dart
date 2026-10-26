import 'package:flutter/material.dart';
import '../design/design.dart';

/// Legacy colour names, mapped onto the Eldermin design tokens ([EmColors], copied from the teacher app's
/// `design-kit-v1`). Both naming generations the app grew (the template names `primaryColor`, `grey`,
/// `lightGrey2`... and the mockup names `ink`, `muted`, `navy`...) resolve to the same tokens, so existing call
/// sites keep compiling and now render in the teacher palette. New code uses [EmColors] directly; these aliases
/// go away once the last module is migrated.
class AppColors {
  AppColors._();
  static const Gradient appbarGradient = LinearGradient(
    colors: [EmColors.primaryDark, lightgradianColor],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // ---- Brand ----
  static const Color primaryColor = EmColors.primaryDark; // navy
  static const Color primaryColorLight = EmColors.primaryMid; // sky
  static const Color secondryColor = EmColors.success; // green
  static const Color secondryColorLight = EmColors.successContainer;
  static const Color accentColor = EmColors.accent; // amber
  static const Color lightgradianColor = Color(0x3C4A89C8);

  // ---- Surfaces ----
  static const Color white = EmColors.surface;
  static const Color white2 = EmColors.background;
  static const Color background = EmColors.background;
  static const Color surface = EmColors.surface;
  static const Color canvas = EmColors.background;
  static const Color transparent = Colors.transparent;

  // ---- Text ----
  static const Color textPrimary = EmColors.ink;
  static const Color black = EmColors.ink;
  static const Color black2 = EmColors.ink;
  static const Color blackColor = EmColors.primaryDark;
  static const Color ink = EmColors.ink;
  static const Color grey = EmColors.textSecondary;
  static const Color muted = EmColors.textSecondary;
  static const Color greyColor = EmColors.textSecondary;
  static const Color gray600 = EmColors.textSecondary;
  static const Color fieldsHeadingColor = EmColors.textSecondary;
  static const Color textPrimaryColor = EmColors.textSecondary;
  static const Color dottedBorderColor = EmColors.textSecondary;
  static const Color iosGrey = EmColors.textSecondary;
  static const Color greyDefault = EmColors.textSecondary;
  static const Color greySwatch600 = EmColors.textSecondary;
  static const Color lightGrey = EmColors.textTertiary;
  static const Color lightGrey8 = EmColors.textTertiary;
  static const Color faint = EmColors.textTertiary;
  static const Color inactiveGrey = EmColors.textTertiary;
  static const Color multiSelectColor = EmColors.textTertiary;

  // ---- Neutral fills, lines ----
  static const Color lightGrey2 = EmColors.border;
  static const Color lightGrey3 = EmColors.background;
  static const Color lightGrey4 = EmColors.background;
  static const Color lightGrey5 = EmColors.disabled;
  static const Color lightGrey6 = EmColors.disabled;
  static const Color lightGrey7 = EmColors.outline;
  static const Color lightGrey9 = EmColors.outline;
  static const Color lightGrey10 = EmColors.background;
  static const Color lightGrey11 = EmColors.border;
  static const Color lightGrey12 = EmColors.disabled;
  static const Color lightGrey13 = EmColors.border;
  static const Color white10 = EmColors.background;
  static const Color textfldFillColor = EmColors.background;
  static const Color buttonDisableColor = EmColors.disabled;
  static const Color textFieldBorderColor = EmColors.border;
  static const Color dividerColor = EmColors.border;
  static const Color dividerColorApp = EmColors.border;
  static const Color separatorColor = EmColors.border;
  static const Color barrierColor = EmColors.scrim;
  static const Color bottomSheetDividerColor = EmColors.background;
  static const Color classBg = EmColors.background;
  static const Color classBg2 = EmColors.background;
  static const Color bgColorSearchField = EmColors.background;
  static const Color productPageBg = EmColors.background;
  static const Color greySwatch200 = EmColors.background;
  static const Color greySwatch400 = EmColors.disabled;
  static const Color lightBorder = EmColors.border;
  static const Color lightGreyColor = EmColors.border;
  static const Color line = EmColors.border;

  // ---- Semantic ----
  static const Color notificationCircleBg = EmColors.warningContainer;
  static const Color notificationBg = EmColors.warningContainer;
  static const Color languageBg = EmColors.primaryTint;
  static const Color accepted = EmColors.success;
  static const Color acceptedBg = EmColors.successContainer;
  static const Color failedBg = EmColors.errorContainer;
  static const Color delete = EmColors.error;
  static const Color green = EmColors.success;
  static const Color green2 = EmColors.success;
  static const Color red = EmColors.error;
  static const Color error = EmColors.error;
  static const Color orange = EmColors.accent;
  static const Color appBarColor = EmColors.primaryDark;
  static const Color lightPurple = EmColors.statusLeaveContainer;
  static const Color lightGreen = EmColors.successContainer;
  static const Color lightCameo = EmColors.warningContainer;
  static const Color lightRed = EmColors.errorContainer;
  static const Color seaGreen = EmColors.success;
  static const Color americanBlue = EmColors.primaryDark;
  static const Color lightPink = EmColors.errorContainer;
  static const Color lightBlue = EmColors.primaryTint;
  static const Color redStar = EmColors.error;
  static const Color greenContainerInnerColor = EmColors.successContainer;
  static const Color greenContainerBorderColor = EmColors.success;
  static const Color darkGreen = EmColors.onSuccessContainer;
  static const Color purpleColor = EmColors.statusLeave;
  static const Color greenSuccess = EmColors.success;
  static const Color iosBlue = EmColors.primary;
  static const Color iosOrange = EmColors.accent;
  static const Color yellowBg = EmColors.warningContainer;
  static const Color yellow = EmColors.accent;
  static const Color amberDark = EmColors.warning;
  static const Color materialAmber = EmColors.accent;

  // Dark-theme placeholders (the app is light-only)
  static const Color darkCard = EmColors.primaryDark;
  static const Color darkDivider = EmColors.primary;
  static const Color darkNavBar = EmColors.primaryDark;

  // Neutral overlays and third-party brand colour: not part of the palette
  static const Color black12 = Color(0x1F000000);
  static const Color black38 = Color(0x61000000);
  static const Color black54 = Color(0x8A000000);
  static const Color black87 = Color(0xDD000000);
  static const Color blackOverlay5 = Color(0x0D000000);
  static const Color blackOverlay10 = Color(0x1A000000);
  static const Color facebookBlue = Color(0xFF1877F2);

  // ---- Shimmer ----
  static const Color shimmerBase = EmColors.shimmerBase;
  static const Color shimmerHighlight = EmColors.shimmerHighlight;
  static const Color shimmerShape = EmColors.shimmerShape;
  static const Color shimmerShapeAlt = EmColors.shimmerShape;

  // ---- Categories ----
  static const Color categoryBlue = EmColors.primary;
  static const Color categoryPurple = EmColors.statusLeave;
  static const Color categoryTeal = EmColors.success;
  static const Color categoryCoral = EmColors.error;
  static const Color categoryBg1 = EmColors.primaryTint;
  static const Color categoryBg2 = EmColors.statusLeaveContainer;
  static const Color categoryBg3 = EmColors.successContainer;
  static const Color categoryBg4 = EmColors.errorContainer;

  // ---- Mockup names ----
  static const Color navy = EmColors.primaryDark;
  static const Color blue = EmColors.primary;
  static const Color sky = EmColors.primaryMid;
  static const Color pale = EmColors.primaryTint;
  static const Color amber = EmColors.accent;
  static const Color amberBg = EmColors.warningContainer;
  static const Color amberText = EmColors.warning;
  static const Color greenBg = EmColors.successContainer;
  static const Color greenText = EmColors.onSuccessContainer;
  static const Color redBg = EmColors.errorContainer;
  static const Color redText = EmColors.onErrorContainer;
  static const Color purple = EmColors.statusLeave;
  static const Color purpleBg = EmColors.statusLeaveContainer;

  static const List<Color> heroGradient = EmColors.heroGradient;
}

/// Radii of the old scale, aligned to [EmRadius].
class AppRadius {
  AppRadius._();
  static const double sm = EmRadius.control;
  static const double control = EmRadius.control; // every field and button
  static const double md = EmRadius.md;
  static const double lg = EmRadius.tile;
  static const double xl = EmRadius.card;
  static const double pill = EmRadius.pill;
}

/// Spacing of the old scale, aligned to [EmSpacing].
class AppSpacing {
  AppSpacing._();
  static const double xs = EmSpacing.s4;
  static const double sm = EmSpacing.s8;
  static const double md = EmSpacing.block;
  static const double lg = EmSpacing.screenH;
  static const double xl = EmSpacing.s24;
}

/// Semantic color pairs (foreground + tinted background) for badges/tags.
class TagStyle {
  final Color fg;
  final Color bg;
  const TagStyle(this.fg, this.bg);

  static const info = TagStyle(EmColors.onInfoContainer, EmColors.infoContainer);
  static const amber = TagStyle(EmColors.onWarningContainer, EmColors.warningContainer);
  static const green = TagStyle(EmColors.onSuccessContainer, EmColors.successContainer);
  static const red = TagStyle(EmColors.onErrorContainer, EmColors.errorContainer);
  static const neutral = TagStyle(EmColors.textSecondary, EmColors.border);
}

class AppTheme {
  AppTheme._();

  /// Entry point used by `main.dart` and every widget test: the Eldermin design theme.
  static ThemeData get light => buildEmTheme();
}
