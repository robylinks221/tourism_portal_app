import 'package:flutter/material.dart';

import '../utils/text_case.dart';

class PremiumSkeleton extends StatefulWidget {
  const PremiumSkeleton({
    super.key,
    this.height = 120,
    this.borderRadius = 24,
  });

  final double height;
  final double borderRadius;

  @override
  State<PremiumSkeleton> createState() => _PremiumSkeletonState();
}

class _PremiumSkeletonState extends State<PremiumSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1050),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => Container(
        height: widget.height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              colors.surfaceContainerHighest.withOpacity(.58),
              colors.surfaceContainerHighest.withOpacity(
                .82 + (_controller.value * .18),
              ),
              colors.surfaceContainerHighest.withOpacity(.58),
            ],
            begin: Alignment(-1 + _controller.value, -1),
            end: Alignment(1 + _controller.value, 1),
          ),
          borderRadius: BorderRadius.circular(widget.borderRadius),
        ),
      ),
    );
  }
}

class DiscoverySkeleton extends StatelessWidget {
  const DiscoverySkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PremiumSkeleton(height: 24, borderRadius: 10),
        const SizedBox(height: 12),
        SizedBox(
          height: 224,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 3,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (_, __) => const SizedBox(
              width: 194,
              child: PremiumSkeleton(height: 224),
            ),
          ),
        ),
      ],
    );
  }
}

class IllustratedEmptyState extends StatelessWidget {
  const IllustratedEmptyState({
    super.key,
    required this.message,
    this.title = 'Nothing here yet',
    this.icon = Icons.explore_rounded,
  });

  final String title;
  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withOpacity(.42),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 82,
            height: 76,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  right: 3,
                  top: 4,
                  child: Icon(
                    Icons.wb_sunny_outlined,
                    color: colors.secondary.withOpacity(.5),
                    size: 25,
                  ),
                ),
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: colors.onPrimaryContainer, size: 31),
                ),
                Positioned(
                  left: 0,
                  bottom: 3,
                  child: Icon(
                    Icons.route_rounded,
                    color: colors.primary,
                    size: 29,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.toTitleCase(),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w300,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: theme.textTheme.bodySmall?.copyWith(height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
