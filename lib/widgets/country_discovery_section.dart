import 'package:flutter/material.dart';

import '../models/tourism_country.dart';
import '../pages/country_hub_page.dart';
import '../services/country_service.dart';
import 'app_ui.dart';

class CountryDiscoverySection extends StatefulWidget {
  const CountryDiscoverySection({
    super.key,
    this.isGuest = false,
  });

  final bool isGuest;

  @override
  State<CountryDiscoverySection> createState() =>
      _CountryDiscoverySectionState();
}

class _CountryDiscoverySectionState extends State<CountryDiscoverySection> {
  late Future<List<TourismCountry>> _countries;

  @override
  void initState() {
    super.initState();
    _countries = CountryService.instance.fetchCountries();
  }

  void _retry() {
    setState(() {
      _countries = CountryService.instance.fetchCountries();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<TourismCountry>>(
      future: _countries,
      builder: (context, snapshot) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppSectionHeader(
              title: 'Explore East Africa',
              subtitle:
                  'Discover unforgettable experiences across East Africa.',
            ),
            const SizedBox(height: 15),
            if (snapshot.connectionState != ConnectionState.done)
              const _CountryGridSkeleton()
            else if (snapshot.hasError)
              _CountryError(onRetry: _retry)
            else
              _CountryGrid(
                countries: snapshot.data ?? const [],
                isGuest: widget.isGuest,
              ),
          ],
        );
      },
    );
  }
}

class _CountryGrid extends StatelessWidget {
  const _CountryGrid({
    required this.countries,
    required this.isGuest,
  });

  final List<TourismCountry> countries;
  final bool isGuest;

  @override
  Widget build(BuildContext context) {
    if (countries.isEmpty) {
      return const Text('No countries are available yet.');
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 12.0;
        final width = (constraints.maxWidth - gap) / 2;
        final height = (width * 1.27).clamp(194.0, 235.0).toDouble();

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: countries.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: gap,
            mainAxisSpacing: gap,
            mainAxisExtent: height,
          ),
          itemBuilder: (context, index) {
            final country = countries[index];

            return _CountryCard(
              country: country,
              onTap: () => Navigator.push<void>(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => CountryHubPage(
                    country: country,
                    isGuest: isGuest,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _CountryCard extends StatelessWidget {
  const _CountryCard({
    required this.country,
    required this.onTap,
  });

  final TourismCountry country;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: const Color(0xFF165B5D),
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      elevation: 5,
      shadowColor: Colors.black.withValues(alpha: .14),
      child: InkWell(
        onTap: onTap,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _CountryPhoto(imageUrl: country.cardImageUrl),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x00000000),
                    Color(0x12000000),
                    Color(0x72000000),
                    Color(0xE0001918),
                  ],
                  stops: [0, .45, .70, 1],
                ),
              ),
            ),
            Positioned(
              left: 14,
              right: 12,
              bottom: 14,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    country.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      height: 1,
                      letterSpacing: -.45,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    country.tagline,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: .92),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 11),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 13,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .17),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: .48),
                        width: .8,
                      ),
                    ),
                    child: Text(
                      '${country.tourCount} ${country.tourCount == 1 ? 'Tour' : 'Tours'}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        height: 1,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CountryPhoto extends StatelessWidget {
  const _CountryPhoto({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) return const _ImageFallback();

    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => const _ImageFallback(),
    );
  }
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF487C79),
            Color(0xFF165B5D),
            Color(0xFF0B3D3F),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.landscape_outlined,
          color: Colors.white.withValues(alpha: .18),
          size: 48,
        ),
      ),
    );
  }
}

class _CountryGridSkeleton extends StatelessWidget {
  const _CountryGridSkeleton();

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: .79,
      children: List.generate(
        4,
        (_) => Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .72),
            borderRadius: BorderRadius.circular(24),
          ),
        ),
      ),
    );
  }
}

class _CountryError extends StatelessWidget {
  const _CountryError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          const Text('Countries could not be loaded.'),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: onRetry,
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }
}
