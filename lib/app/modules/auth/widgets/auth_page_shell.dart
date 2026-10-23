import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/design/design.dart';

/// How much of the screen the photo takes on a signed-out screen.
enum AuthPhotoSize {
  /// Login: the photo fills the top ~55% and fades into the navy.
  tall(0.55, Alignment.topCenter),

  /// The screens pushed from it (OTP, create account, email sign in).
  short(0.34, Alignment(0, -0.78));

  const AuthPhotoSize(this.fraction, this.alignment);
  final double fraction;

  /// Where the photo sits in its box: the short box shows the photo shifted up a little so the faces stay
  /// above the overlay's ramp (and clear of the status bar).
  final Alignment alignment;
}

/// Shared layout of the signed-out screens: the first photo at the top fading
/// into the navy page with the logo tile on it, then the heading, the subtitle
/// and the form on the navy. The content rises and fades in; the photo collapses
/// to a strip when the keyboard opens so the fields and the button stay in view.
/// Scrolls. Everything below the photo's strong line ([EmPhotoOverlay]) is text
/// on the overlay, so the content starts there.
///
/// (Duplicated from the teacher app, see docs/PHOTO_AUTH_DUPLICATION.md.)
class AuthPageShell extends StatelessWidget {
  const AuthPageShell({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.eyebrow,
    this.showBack = false,
    this.photoSize = AuthPhotoSize.short,
    this.shake,
  });

  final String title;
  final String? subtitle;

  /// Small line above the heading (the old app bar title of a pushed screen).
  final String? eyebrow;
  final Widget child;
  final bool showBack;
  final AuthPhotoSize photoSize;

  /// Shakes the content whenever this changes (an error).
  final ValueListenable<int>? shake;

  /// Strong line of the photo's overlay as a fraction of the photo box: content starts here.
  static const double photoSafeTop = 0.78;
  static final double contentStart = EmPhotoOverlay.strongLine(photoSafeTop);

  static const double logoTile = 64, maxContentWidth = 420;

  @override
  Widget build(BuildContext context) {
    // read here, above the scaffold: it removes the keyboard inset from its body's MediaQuery
    final reduced = EmReduceMotion.of(context);
    final top = MediaQuery.paddingOf(context).top;
    final keyboard = MediaQuery.viewInsetsOf(context).bottom > 0;
    final full = MediaQuery.sizeOf(context).height * photoSize.fraction;
    // the keyboard collapses the photo to a strip that still holds the logo tile
    final collapsed = top + EmSpacing.s12 + logoTile + EmSpacing.s24;
    final photoHeight = keyboard ? (collapsed < full ? collapsed : full) : full;

    return EmEntranceHost(
      builder: (context, entrance) => EmEntrance(
        animation: entrance,
        child: AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle.light,
          child: Scaffold(
            backgroundColor: EmColors.primaryDark,
            body: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(end: photoHeight),
                    duration: reduced ? Duration.zero : EmMotion.slow,
                    curve: EmMotion.emphasized,
                    builder: (context, h, _) => Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // the photo is taller than this box; the content below overlaps its faded lower part
                        SizedBox(
                          height: h * contentStart,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Positioned(
                                top: 0,
                                left: 0,
                                right: 0,
                                height: h,
                                child: EmPhotoBackdrop(
                                  key: const Key('auth_photo'),
                                  image: EmAuthPhotos.provider(EmAuthPhotos.photo1),
                                  alignment: photoSize.alignment,
                                  safeTop: photoSafeTop,
                                  bottomAlpha: 1,
                                ),
                              ),
                              // top corner, clear of the people in the photo
                              PositionedDirectional(
                                top: top + EmSpacing.s12,
                                end: EmSpacing.s24,
                                child: const EmLogoTile(size: logoTile),
                              ),
                              if (showBack)
                                PositionedDirectional(
                                  top: top + EmSpacing.s8,
                                  start: EmSpacing.s16,
                                  child: const _BackCircle(),
                                ),
                            ],
                          ),
                        ),
                        SafeArea(
                          top: false,
                          child: Padding(
                            padding: const EdgeInsetsDirectional.fromSTEB(EmSpacing.s24, 0, EmSpacing.s24, EmSpacing.s24),
                            child: Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: maxContentWidth),
                                child: _rise(entrance, _content()),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Heading (accent), muted subtitle, then the form, all on the navy.
  Widget _content() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (eyebrow != null) ...[
          Text(eyebrow!, key: const Key('auth_eyebrow'), style: EmType.caption.copyWith(color: EmColors.primaryLight)),
          const SizedBox(height: EmSpacing.s4),
        ],
        Semantics(
          header: true,
          child: Text(title,
              key: const Key('auth_title'),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: EmType.photoTitle.copyWith(color: EmColors.accent)),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: EmSpacing.s8),
          Text(subtitle!, key: const Key('auth_subtitle'), style: EmType.body.copyWith(color: EmColors.primaryContainer, fontWeight: FontWeight.w400)),
        ],
        const SizedBox(height: EmSpacing.s20),
        child,
      ],
    );
  }

  /// The content rises [EmMotion.riseDistance] while it fades in; shakes on error.
  Widget _rise(Animation<double> entrance, Widget content) {
    final a = CurvedAnimation(parent: entrance, curve: EmEntrancePlan.card);
    Widget c = AnimatedBuilder(
      animation: a,
      child: content,
      builder: (context, child) => Opacity(
        opacity: a.value,
        child: Transform.translate(offset: Offset(0, EmMotion.riseDistance * (1 - a.value)), child: child),
      ),
    );
    if (shake != null) c = EmShake(trigger: shake!, child: c);
    return c;
  }
}

/// White 48 dp circle with a chevron (the pushed screens' way back).
class _BackCircle extends StatelessWidget {
  const _BackCircle();

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return Semantics(
      container: true,
      button: true,
      label: 'Back',
      excludeSemantics: true,
      onTap: () => Navigator.maybeOf(context)?.maybePop(),
      child: Tooltip(
        message: 'Back',
        child: DecoratedBox(
          decoration: BoxDecoration(color: EmColors.surface, shape: BoxShape.circle, boxShadow: EmShadows.soft),
          child: Material(
            type: MaterialType.transparency,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => Navigator.maybeOf(context)?.maybePop(),
              child: SizedBox(
                width: 48,
                height: 48,
                child: Icon(rtl ? Icons.chevron_right_rounded : Icons.chevron_left_rounded, color: EmColors.ink),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Inline message under a field: the error colour that reads on the navy.
class AuthMessage extends StatelessWidget {
  const AuthMessage(this.message, {super.key});
  final String message;

  @override
  Widget build(BuildContext context) => Semantics(
        liveRegion: true,
        child: Text(message, style: EmType.label.copyWith(color: EmColors.errorContainer)),
      );
}

/// White field label above a field.
class AuthLabel extends StatelessWidget {
  const AuthLabel(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsetsDirectional.only(bottom: EmSpacing.s8),
        child: Text(text, style: EmType.label.copyWith(color: EmColors.onPrimaryDark)),
      );
}

/// Outlined pill field for the navy: transparent, 1 px light border, white text, accent border when focused.
class AuthTextField extends StatelessWidget {
  const AuthTextField({
    super.key,
    required this.controller,
    this.hintText,
    this.prefixIcon,
    this.suffix,
    this.keyboardType,
    this.inputFormatters,
    this.obscureText = false,
    this.errorText,
    this.textInputAction,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String? hintText;
  final IconData? prefixIcon;
  final Widget? suffix;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final bool obscureText;
  final String? errorText;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder border(Color c, double w) =>
        OutlineInputBorder(borderRadius: BorderRadius.circular(EmRadius.pill), borderSide: BorderSide(color: c, width: w));
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      obscureText: obscureText,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      cursorColor: EmColors.accent,
      style: EmType.body.copyWith(color: EmColors.onPrimaryDark),
      decoration: InputDecoration(
        filled: false,
        hintText: hintText,
        hintStyle: EmType.body.copyWith(color: EmColors.primaryContainer, fontWeight: FontWeight.w400),
        errorText: errorText,
        errorMaxLines: 3,
        errorStyle: EmType.caption.copyWith(color: EmColors.errorContainer),
        prefixIcon: prefixIcon == null ? null : Icon(prefixIcon, size: 22, color: EmColors.onPrimaryDark),
        suffixIcon: suffix,
        contentPadding: const EdgeInsetsDirectional.symmetric(horizontal: 22, vertical: 14),
        constraints: const BoxConstraints(minHeight: 56),
        border: border(EmColors.primaryLight, 1),
        enabledBorder: border(EmColors.primaryLight, 1),
        focusedBorder: border(EmColors.accent, 2),
        errorBorder: border(EmColors.errorContainer, 1),
        focusedErrorBorder: border(EmColors.errorContainer, 2),
      ),
    );
  }
}

/// Eye button for password fields (48 dp target).
class AuthPasswordToggle extends StatelessWidget {
  const AuthPasswordToggle({super.key, required this.obscured, required this.onToggle});
  final bool obscured;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: obscured ? 'Show password' : 'Hide password',
        excludeSemantics: true,
        onTap: onToggle,
        child: InkResponse(
          onTap: onToggle,
          radius: 24,
          child: SizedBox(
            width: 48,
            height: 48,
            child: Icon(obscured ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20, color: EmColors.primaryContainer),
          ),
        ),
      );
}
