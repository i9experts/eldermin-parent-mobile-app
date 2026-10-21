import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../app/components/custom_text.dart';

/// Rounded-square student avatar: the student's real photo when the school
/// has one on file, otherwise the initials on [fallback] decoration.
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
  Widget build(BuildContext context) {
    final fallback = Container(
      width: size,
      height: size,
      decoration: fallbackDecoration,
      child: Center(
          child: CustomText(
              text: initials.isEmpty ? '—' : initials,
              color: initialsColor,
              fontWeight: FontWeight.w800,
              fontSize: fontSize)),
    );
    final url = photoUrl;
    if (url == null || url.isEmpty) return fallback;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: CachedNetworkImage(
        imageUrl: url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholder: (_, __) => fallback,
        errorWidget: (_, __, ___) => fallback,
      ),
    );
  }
}
