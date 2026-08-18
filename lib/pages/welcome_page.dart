import 'package:flutter/material.dart';

import 'tourist_home_page.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final mutedText = colors.onSurface.withOpacity(0.64);
    final cardColor = colors.surface;
    final borderColor = colors.outline.withOpacity(isDark ? 0.65 : 0.75);

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 30),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 48,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: colors.primary,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Icon(
                            Icons.travel_explore_rounded,
                            color: colors.onPrimary,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Tourism Portal',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w300,
                                ),
                              ),
                              Text(
                                'Discover. Connect. Explore.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: mutedText,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: cardColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: borderColor),
                          ),
                          child: Icon(
                            isDark
                                ? Icons.dark_mode_rounded
                                : Icons.light_mode_rounded,
                            color: colors.primary,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    Container(
                      height: 280,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isDark
                              ? const [
                            Color(0xFF202B38),
                            Color(0xFF183D3B),
                          ]
                              : const [
                            Color(0xFFDFF7F3),
                            Color(0xFFBEECE5),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(
                            color: colors.primary.withOpacity(
                              isDark ? 0.12 : 0.18,
                            ),
                            blurRadius: 30,
                            offset: const Offset(0, 16),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(32),
                        child: Stack(
                          children: [
                            Positioned(
                              top: -45,
                              right: -35,
                              child: Container(
                                width: 150,
                                height: 150,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(
                                    isDark ? 0.04 : 0.26,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: -60,
                              left: -30,
                              child: Container(
                                width: 180,
                                height: 180,
                                decoration: BoxDecoration(
                                  color: colors.primary.withOpacity(
                                    isDark ? 0.12 : 0.16,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 22,
                              left: 22,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 13,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: cardColor.withOpacity(
                                    isDark ? 0.92 : 0.88,
                                  ),
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.location_on_rounded,
                                      color: colors.secondary,
                                      size: 17,
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      'Explore Uganda',
                                      style:
                                      theme.textTheme.labelSmall?.copyWith(
                                        color: colors.onSurface,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.7,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Positioned(
                              right: 25,
                              top: 68,
                              child: Transform.rotate(
                                angle: 0.25,
                                child: Icon(
                                  Icons.flight_rounded,
                                  color: colors.secondary,
                                  size: 45,
                                ),
                              ),
                            ),
                            Positioned(
                              left: 18,
                              right: 18,
                              bottom: 12,
                              child: Icon(
                                Icons.landscape_rounded,
                                color: colors.primary.withOpacity(
                                  isDark ? 0.78 : 0.72,
                                ),
                                size: 210,
                              ),
                            ),
                            Positioned(
                              right: 30,
                              bottom: 29,
                              child: Container(
                                width: 66,
                                height: 66,
                                decoration: BoxDecoration(
                                  color: colors.secondary,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: colors.secondary.withOpacity(0.3),
                                      blurRadius: 18,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.camera_alt_rounded,
                                  color: Colors.white,
                                  size: 29,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 34),
                    Text(
                      'Your journey\nstarts here.',
                      style: theme.textTheme.headlineLarge?.copyWith(
                        fontSize: 14,
                        height: 1.15,
                        fontWeight: FontWeight.w300,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Discover remarkable destinations, trusted local guides, '
                          'tour operators, and unforgettable travel experiences.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: mutedText,
                        height: 1.65,
                      ),
                    ),
                    const SizedBox(height: 22),
                    Wrap(
                      spacing: 9,
                      runSpacing: 9,
                      children: [
                        _FeatureChip(
                          icon: Icons.place_outlined,
                          label: 'Destinations',
                          color: colors.primary,
                        ),
                        _FeatureChip(
                          icon: Icons.hiking_outlined,
                          label: 'Local guides',
                          color: colors.secondary,
                        ),
                        _FeatureChip(
                          icon: Icons.luggage_outlined,
                          label: 'Tour packages',
                          color: const Color(0xFF7C6FEA),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      height: 56,
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.pushNamed(context, '/register');
                        },
                        icon: const Icon(Icons.explore_rounded),
                        label: const Text(
                          'Start Exploring',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 13),
                    SizedBox(
                      height: 54,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/login');
                        },
                        child: const Text(
                          'I already have an account',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute<void>(
                            builder: (_) => const TouristHomePage(
                              isGuest: true,
                            ),
                          ),
                          (route) => false,
                        );
                      },
                      icon: const Icon(Icons.person_outline_rounded),
                      label: const Text(
                        'Continue as a guest',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(height: 22),
                    Text(
                      'Plan • Book • Experience',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: mutedText,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  const _FeatureChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 13,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: colors.outline.withOpacity(isDark ? 0.65 : 0.7),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: color,
            size: 18,
          ),
          const SizedBox(width: 7),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
