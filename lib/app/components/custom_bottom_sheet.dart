import 'package:flutter/material.dart';
import '../../core/design/design.dart';

/// Content of a modal bottom sheet opened with a transparent `showModalBottomSheet` background: the kit's sheet
/// chrome (surface, 28 dp top radius, drag handle, title, scrolling body) around [widget]. [height] caps the sheet's
/// height (default: the kit's 90% of the screen). Dismiss by dragging, tapping outside or the system back.
class CustomBottomSheet extends StatelessWidget {
  const CustomBottomSheet({super.key, required this.title, required this.widget, this.height});
  final double? height;
  final Widget widget;
  final String title;

  @override
  Widget build(BuildContext context) {
    final sheet = DecoratedBox(
      decoration: const BoxDecoration(color: EmColors.surface, borderRadius: BorderRadius.vertical(top: Radius.circular(EmRadius.hero))),
      child: SafeArea(top: false, child: EmBottomSheet(title: title, child: widget)),
    );
    return EmKeyboardAccessory.overlay(
      child: height == null ? sheet : ConstrainedBox(constraints: BoxConstraints(maxHeight: height!), child: sheet),
    );
  }
}
