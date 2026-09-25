import 'package:flutter/material.dart';

import '../models/tourism_country.dart';
import '../widgets/catalog_home_sections.dart';
import '../widgets/operator_offerings_sections.dart';
import '../widgets/provider_discovery_sections.dart';
import '../widgets/recommended_for_you_section.dart';

class CountryHubPage extends StatelessWidget {
  const CountryHubPage({
    super.key,
    required this.country,
    this.isGuest = false,
  });

  final TourismCountry country;
  final bool isGuest;

  static const _background = Color(0xFFF4EEE1);
  static const _primary = Color(0xFF165B5D);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 300,
            backgroundColor: _primary,
            foregroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              background: _CountryHero(country: country),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 24, 18, 42),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                if (country.introduction.trim().isNotEmpty)
                  _CountryIntro(text: country.introduction),
                if (country.introduction.trim().isNotEmpty)
                  const SizedBox(height: 30),

                CatalogHomeSections(
                  countryName: country.name,
                  countryMoodIds: country.moodIds,
                  countryActivityIds: country.activityIds,
                  countryDestinationIds: country.destinationIds,
                ),
                const SizedBox(height: 30),

                RecommendedForYouSection(
                  isGuest: isGuest,
                  countryName: country.name,
                ),
                const SizedBox(height: 30),

                ProviderDiscoverySections(
                  enabled: true,
                  isGuest: isGuest,
                  countryName: country.name,
                ),
                const SizedBox(height: 30),

                OperatorOfferingsSections(countryName: country.name),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _CountryHero extends StatelessWidget {
  const _CountryHero({required this.country});

  final TourismCountry country;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (country.heroImageUrl.isNotEmpty)
          Image.network(
            country.heroImageUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const _HeroFallback(),
          )
        else
          const _HeroFallback(),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0x18000000),
                Color(0x28000000),
                Color(0xE0001D1B),
              ],
              stops: [0, .45, 1],
            ),
          ),
        ),
        Positioned(
          left: 24,
          right: 24,
          bottom: 28,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'EXPLORE',
                style: TextStyle(
                  color: Color(0xFFF4EEE1),
                  fontSize: 11,
                  letterSpacing: 2.2,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                country.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 38,
                  height: 1,
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (country.tagline.trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  country.tagline,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .92),
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _HeroFallback extends StatelessWidget {
  const _HeroFallback();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF487C79), Color(0xFF165B5D), Color(0xFF0B3D3F)],
        ),
      ),
    );
  }
}

class _CountryIntro extends StatelessWidget {
  const _CountryIntro({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF253D49),
          fontSize: 15,
          height: 1.55,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
