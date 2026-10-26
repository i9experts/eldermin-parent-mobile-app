import 'package:flutter/material.dart';
import '../design/design.dart';

/// The student's avatar: the real photo when the school has one on file, otherwise the initials. Wraps the kit's
/// circular [EmAvatar]; [radius], [fontSize], [initialsColor] and [fallbackDecoration] are kept for the call sites
/// but the kit avatar fixes the shape, text size and colours from the tokens, so they no longer change the look.
class StudentAvatar extends StatelessWidget {
  final String? photoUrl;
  final String initials;
  final double size;
  final double radius;
  final double fontSize;
  final Color initialsColor;
  final BoxDecoration fallbackDecoration;

  const StudentAvatar({
    super.key,
    required this.photoUrl,
    required this.initials,
    required this.size,
    required this.radius,
    required this.fontSize,
    required this.initialsColor,
    required this.fallbackDecoration,
  });

  @override
  Widget build(BuildContext context) => EmAvatar(initials: initials.isEmpty ? '—' : initials, imageUrl: photoUrl, size: size);
}
