import 'package:flutter/painting.dart';
import '../../theme/app_theme.dart';

/// Colours of the photo auth screens (splash, login, OTP, create account, email sign in).
///
/// Mapped onto the parent app's own palette ([AppColors], the approved mockup): the navy is the app's
/// navy and the accent its amber, so the auth screens sit with the rest of the app. The logomark keeps its
/// own colours ([EmLogoColors], logomark_geometry.dart). Accent text is allowed on navy only (never on
/// white / light surfaces); on this navy it is AA even at body size (see test/design/photo_overlay_contrast_test.dart).
class EmColors {
  EmColors._();

  static const Color primaryDark = AppColors.primaryColor; // navy 0A3158
  static const Color primary = Color(0xFF155D96);
  static const Color primaryMid = AppColors.primaryColorLight;
  static const Color primaryLight = Color(0xFFB5D3EC); // captions, borders on navy
  static const Color primaryContainer = Color(0xFFDCEAF7); // muted body text on navy
  static const Color accent = AppColors.accentColor; // amber F5A623

  static const Color surface = AppColors.white;
  static const Color ink = AppColors.black; // 10253A
  static const Color onPrimaryDark = AppColors.white;
  static const Color errorContainer = AppColors.failedBg; // error text on navy
}
