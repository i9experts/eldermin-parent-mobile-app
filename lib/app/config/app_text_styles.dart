import '../../core/design/tokens/em_typography.dart';

/// The app-wide font family: the bundled Plus Jakarta Sans (see pubspec.yaml `fonts:`), the same family
/// the Eldermin theme sets on [ThemeData.fontFamily]. A bare family string only resolves when the font is
/// bundled under exactly this name, which is why it points at [EmType.family] instead of a literal.
class AppTextStyles {
  AppTextStyles._();

  static const String fontFamily = EmType.family;
  static const String headingFontFamily = EmType.family;
}
