import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AppTag extends StatelessWidget {
  final String label;
  final TagStyle style;
  const AppTag(this.label, {super.key, this.style = TagStyle.info});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: style.bg, borderRadius: BorderRadius.circular(AppRadius.pill)),
      child: Text(label, style: TextStyle(color: style.fg, fontSize: 9.5, fontWeight: FontWeight.w800)),
    );
  }
}

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final EdgeInsets margin;
  final VoidCallback? onTap;
  const AppCard({super.key, required this.child, this.padding = const EdgeInsets.all(14), this.margin = const EdgeInsets.only(bottom: 10), this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.line),
        boxShadow: [BoxShadow(color: AppColors.navy.withOpacity(0.035), blurRadius: 14, offset: const Offset(0, 4))],
      ),
      child: onTap == null
          ? Padding(padding: padding, child: child)
          : Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(AppRadius.lg), child: Padding(padding: padding, child: child)),
            ),
    );
  }
}

class StatsRow extends StatelessWidget {
  final List<(String value, String label, String? trend)> items;
  const StatsRow({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: items.asMap().entries.map((e) {
        final isLast = e.key == items.length - 1;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: isLast ? 0 : 8),
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 11),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.line)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(e.value.$1, style: const TextStyle(color: AppColors.navy, fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: -0.4)),
                const SizedBox(height: 2),
                Text(e.value.$2, style: const TextStyle(color: AppColors.muted, fontSize: 8.5)),
                if (e.value.$3 != null) ...[
                  const SizedBox(height: 3),
                  Text(e.value.$3!, style: const TextStyle(color: AppColors.green, fontSize: 8)),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class AppProgressBar extends StatelessWidget {
  final int percent;
  final Color color;
  const AppProgressBar({super.key, required this.percent, this.color = AppColors.blue});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: SizedBox(
        height: 7,
        child: LinearProgressIndicator(
          value: percent.clamp(0, 100) / 100,
          backgroundColor: const Color(0xFFEAF0F4),
          valueColor: AlwaysStoppedAnimation(color),
        ),
      ),
    );
  }
}

class ListCardRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  const ListCardRow({super.key, required this.icon, this.iconColor = AppColors.blue, required this.title, required this.subtitle, this.trailing, this.onTap});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(color: iconColor.withOpacity(0.1), borderRadius: BorderRadius.circular(13)),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: AppColors.navy))),
                    if (trailing != null) trailing!,
                  ],
                ),
                const SizedBox(height: 3),
                Text(subtitle, style: const TextStyle(color: AppColors.muted, fontSize: 9.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AppTimeline extends StatelessWidget {
  final List<(String time, String title, String meta, Color dotColor)> items;
  const AppTimeline({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: items.asMap().entries.map((e) {
        final isLast = e.key == items.length - 1;
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 28,
                child: Column(
                  children: [
                    Container(width: 12, height: 12, decoration: BoxDecoration(shape: BoxShape.circle, color: e.value.$4, border: Border.all(color: const Color(0xFFDCEDF8), width: 3))),
                    if (!isLast) Expanded(child: Container(width: 2, color: const Color(0xFFDCE7EF))),
                  ],
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(e.value.$1, style: const TextStyle(color: AppColors.muted, fontSize: 9, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text(e.value.$2, style: const TextStyle(color: AppColors.navy, fontSize: 11, fontWeight: FontWeight.w700)),
                      Text(e.value.$3, style: const TextStyle(color: AppColors.muted, fontSize: 9)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class SegmentedControl extends StatelessWidget {
  final List<String> options;
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  const SegmentedControl({super.key, required this.options, required this.selectedIndex, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(color: const Color(0xFFE5EDF3), borderRadius: BorderRadius.circular(13)),
      child: Row(
        children: options.asMap().entries.map((e) {
          final selected = e.key == selectedIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(e.key),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: selected ? [BoxShadow(color: AppColors.navy.withOpacity(0.09), blurRadius: 8, offset: const Offset(0, 2))] : null,
                ),
                child: Text(e.value, textAlign: TextAlign.center, style: TextStyle(color: selected ? AppColors.navy : AppColors.muted, fontSize: 9.5, fontWeight: FontWeight.w800)),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class DateStripWidget extends StatelessWidget {
  final List<DateTime> days;
  final DateTime selected;
  final Set<DateTime> highlighted;
  final ValueChanged<DateTime> onSelect;
  const DateStripWidget({super.key, required this.days, required this.selected, this.highlighted = const {}, required this.onSelect});

  static const _dayLetters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  bool _isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.line)),
      child: Row(
        children: days.map((d) {
          final isSelected = _isSameDay(d, selected);
          final hasEvent = highlighted.any((h) => _isSameDay(h, d));
          return Expanded(
            child: GestureDetector(
              onTap: () => onSelect(d),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 7),
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(color: isSelected ? AppColors.navy : Colors.transparent, borderRadius: BorderRadius.circular(12)),
                child: Column(
                  children: [
                    Text(_dayLetters[(d.weekday - 1) % 7], style: TextStyle(color: isSelected ? const Color(0xFFBFD8ED) : AppColors.muted, fontSize: 9, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text('${d.day}', style: TextStyle(color: isSelected ? Colors.white : AppColors.ink, fontSize: 12, fontWeight: FontWeight.w700)),
                    if (hasEvent && !isSelected) Container(margin: const EdgeInsets.only(top: 3), width: 4, height: 4, decoration: const BoxDecoration(color: AppColors.amber, shape: BoxShape.circle)),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class DonutRing extends StatelessWidget {
  final int percent;
  final Color color;
  final double size;
  const DonutRing({super.key, required this.percent, this.color = AppColors.blue, this.size = 84});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size, height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(size: Size(size, size), painter: _DonutPainter(percent: percent, color: color)),
          Text('$percent%', style: const TextStyle(color: AppColors.navy, fontSize: 18, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final int percent;
  final Color color;
  _DonutPainter({required this.percent, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2;
    final bgPaint = Paint()..color = const Color(0xFFEAF0F4)..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, bgPaint);

    final fgPaint = Paint()..color = color..style = PaintingStyle.fill;
    final sweep = 2 * 3.14159265 * (percent.clamp(0, 100) / 100);
    final path = Path()
      ..moveTo(center.dx, center.dy)
      ..arcTo(Rect.fromCircle(center: center, radius: radius), -3.14159265 / 2, sweep, false)
      ..close();
    canvas.drawPath(path, fgPaint);

    canvas.drawCircle(center, radius - 10, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) => oldDelegate.percent != percent || oldDelegate.color != color;
}

class AppLoader extends StatelessWidget {
  const AppLoader({super.key});
  @override
  Widget build(BuildContext context) => const Center(child: SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 3, color: AppColors.navy)));
}

class AppErrorView extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  const AppErrorView({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 52, height: 52, decoration: BoxDecoration(color: AppColors.redBg, borderRadius: BorderRadius.circular(16)), child: const Icon(Icons.error_outline_rounded, color: AppColors.red)),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.muted)),
          if (onRetry != null) ...[const SizedBox(height: 12), OutlinedButton(onPressed: onRetry, child: const Text('Try again'))],
        ]),
      ),
    );
  }
}

class AppEmptyView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  const AppEmptyView({super.key, required this.icon, required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 60, height: 60, decoration: const BoxDecoration(color: AppColors.background, shape: BoxShape.circle), child: Icon(icon, color: AppColors.faint, size: 28)),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.navy), textAlign: TextAlign.center),
          if (subtitle != null) ...[const SizedBox(height: 4), Text(subtitle!, style: const TextStyle(color: AppColors.faint, fontSize: 12), textAlign: TextAlign.center)],
        ]),
      ),
    );
  }
}

class SectionRow extends StatelessWidget {
  final String title;
  final VoidCallback? onSeeAll;
  const SectionRow({super.key, required this.title, this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(title, style: const TextStyle(color: AppColors.navy, fontSize: 13, fontWeight: FontWeight.w800)),
        if (onSeeAll != null) GestureDetector(onTap: onSeeAll, child: const Text('See all', style: TextStyle(color: AppColors.blue, fontSize: 10, fontWeight: FontWeight.w700))),
      ]),
    );
  }
}
