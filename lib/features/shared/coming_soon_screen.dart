import 'package:flutter/material.dart';
import '../../core/widgets/app_widgets.dart';

/// Used only for screens genuinely not built yet - never a substitute
/// for a real screen with fabricated data. Every entry point in the app
/// either shows real data or honestly says "not built yet", never
/// something in between.
class ComingSoonScreen extends StatelessWidget {
  final String title;
  const ComingSoonScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: const AppEmptyView(
        icon: Icons.construction_rounded,
        title: 'This screen is still being built',
        subtitle: "It'll be wired up to real data in the next update.",
      ),
    );
  }
}
