import 'package:flutter/material.dart';

import '../models/operator_management.dart';

class SafariTrail extends StatelessWidget {
  const SafariTrail({super.key, required this.stops, this.accent});

  final List<TourItineraryStop> stops;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    if (stops.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final trailColor = accent ?? colors.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Route, Day by Day',
          style: theme.textTheme.labelSmall?.copyWith(
            color: trailColor,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.25,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          'Safari trail',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w300,
            height: 1.05,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'A clear field plan for every stage of the journey.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colors.onSurfaceVariant,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 18),
        for (var index = 0; index < stops.length; index++) ...[
          _TrailStop(
            stop: stops[index],
            accent: trailColor,
            isLast: index == stops.length - 1,
          ),
          if (index != stops.length - 1) const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _TrailStop extends StatelessWidget {
  const _TrailStop({
    required this.stop,
    required this.accent,
    required this.isLast,
  });

  final TourItineraryStop stop;
  final Color accent;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 46,
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                if (!isLast)
                  Positioned(
                    top: 36,
                    bottom: -12,
                    child: Container(
                      width: 2,
                      decoration: BoxDecoration(
                        color: accent.withOpacity(.25),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(color: colors.surface, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: accent.withOpacity(.22),
                        blurRadius: 12,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Text(
                    '${stop.day}',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              decoration: BoxDecoration(
                color: colors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: colors.outlineVariant),
                boxShadow: [
                  BoxShadow(
                    color: colors.shadow.withOpacity(.045),
                    blurRadius: 18,
                    offset: const Offset(0, 7),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'DAY ${stop.day}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: accent,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    stop.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w300,
                      height: 1.22,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    stop.description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                      height: 1.55,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
