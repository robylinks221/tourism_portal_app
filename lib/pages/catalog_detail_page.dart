import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/catalog_item.dart';
import '../models/community.dart';
import '../services/catalog_service.dart';
import '../services/community_service.dart';
import '../utils/text_case.dart';
import '../widgets/provider_discovery_sections.dart';
import '../widgets/premium_navigation.dart';
import '../widgets/premium_states.dart';

class CatalogDetailPage extends StatelessWidget {
  const CatalogDetailPage({super.key, required this.item});

  final CatalogItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final place = [
      item.location,
      item.country,
    ].where((value) => value?.trim().isNotEmpty == true).join(', ');
    return Scaffold(
      backgroundColor: colors.surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: MediaQuery.sizeOf(context).height * .72,
            pinned: true,
            stretch: true,
            foregroundColor: Colors.white,
            backgroundColor: const Color(0xFF102E2A),
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              stretchModes: const [StretchMode.zoomBackground],
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: catalogHeroTag(item.type, item.id),
                    child: _CatalogImage(item: item),
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0x26000000),
                          Color(0x19000000),
                          Color(0xE6102522),
                        ],
                        stops: [0, .42, 1],
                      ),
                    ),
                  ),
                  if (item.imageUrl.isNotEmpty)
                    Positioned(
                      top: MediaQuery.paddingOf(context).top + 54,
                      right: 16,
                      child: Material(
                        color: Colors.black.withOpacity(.34),
                        shape: const CircleBorder(),
                        child: IconButton(
                          tooltip: 'View full-screen photo',
                          onPressed:
                              () => Navigator.push<void>(
                                context,
                                premiumPageRoute(
                                  (_) => _FullScreenCatalogPhoto(item: item),
                                ),
                              ),
                          icon: const Icon(
                            Icons.open_in_full_rounded,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    left: 22,
                    right: 22,
                    bottom: 28,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(.18),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(.28),
                            ),
                          ),
                          child: Text(
                            item.isActivity
                                ? 'Safari Activity'
                                : 'Safari Destination',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          item.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w300,
                            height: 1.05,
                            letterSpacing: -.8,
                          ),
                        ),
                        if (place.isNotEmpty) ...[
                          const SizedBox(height: 9),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on_outlined,
                                size: 18,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  place,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (!item.isActivity &&
                            item.latitude != null &&
                            item.longitude != null) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.explore_outlined,
                                size: 17,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                '${item.latitude!.toStringAsFixed(4)}°, ${item.longitude!.toStringAsFixed(4)}°',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: .4,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 52),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                if (item.tagline?.isNotEmpty == true) ...[
                  Text(
                    item.tagline!,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w300,
                      height: 1.2,
                      letterSpacing: -.45,
                    ),
                  ),
                  const SizedBox(height: 22),
                ],
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(color: colors.outlineVariant),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF102E2A).withOpacity(.06),
                        blurRadius: 26,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.isActivity
                            ? 'About this experience'
                            : 'Discover ${item.name}',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w300,
                          letterSpacing: -.3,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        item.description,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          height: 1.65,
                          color: colors.onSurface.withOpacity(.78),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 34),
                _CatalogConnections(item: item),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _CatalogImage extends StatelessWidget {
  const _CatalogImage({required this.item});

  final CatalogItem item;

  @override
  Widget build(BuildContext context) {
    if (item.imageUrl.isEmpty) {
      return Container(
        color: const Color(0xFF173F39),
        child: Icon(
          item.isActivity ? Icons.explore_outlined : Icons.landscape_outlined,
          color: Colors.white.withOpacity(.42),
          size: 94,
        ),
      );
    }

    return ColorFiltered(
      colorFilter: const ColorFilter.mode(
        Color(0x183E6B52),
        BlendMode.softLight,
      ),
      child: Image.network(
        item.imageUrl,
        fit: BoxFit.cover,
        errorBuilder:
            (_, __, ___) => Container(
              color: const Color(0xFF173F39),
              child: const Icon(
                Icons.image_not_supported_outlined,
                color: Colors.white54,
                size: 62,
              ),
            ),
      ),
    );
  }
}

class _FullScreenCatalogPhoto extends StatelessWidget {
  const _FullScreenCatalogPhoto({required this.item});

  final CatalogItem item;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          InteractiveViewer(
            minScale: 1,
            maxScale: 4,
            child: ColorFiltered(
              colorFilter: const ColorFilter.mode(
                Color(0x183E6B52),
                BlendMode.softLight,
              ),
              child: Image.network(item.imageUrl, fit: BoxFit.contain),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Material(
                  color: Colors.black.withOpacity(.46),
                  shape: const CircleBorder(),
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: MediaQuery.paddingOf(context).bottom + 22,
            child: Text(
              item.name,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w300,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CatalogConnections extends StatefulWidget {
  const _CatalogConnections({required this.item});

  final CatalogItem item;

  @override
  State<_CatalogConnections> createState() => _CatalogConnectionsState();
}

class _CatalogConnectionsState extends State<_CatalogConnections> {
  late Future<CatalogItem> _detail;

  @override
  void initState() {
    super.initState();
    _detail = _load();
  }

  Future<CatalogItem> _load() =>
      widget.item.isActivity
          ? CatalogService.instance.fetchActivity(widget.item.slug)
          : CatalogService.instance.fetchDestination(widget.item.slug);

  void _retry() {
    setState(() => _detail = _load());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FutureBuilder<CatalogItem>(
      future: _detail,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Column(
            children: [
              PremiumSkeleton(height: 164),
              SizedBox(height: 18),
              PremiumSkeleton(height: 246),
              SizedBox(height: 18),
              PremiumSkeleton(height: 220),
            ],
          );
        }
        if (snapshot.hasError) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: theme.colorScheme.errorContainer.withOpacity(.45),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.cloud_off_outlined,
                  color: theme.colorScheme.error,
                  size: 36,
                ),
                const SizedBox(height: 10),
                Text(
                  'More discovery details could not be loaded.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 5),
                Text(
                  'Check your connection and try again.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: _retry,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Try again'),
                ),
              ],
            ),
          );
        }

        final detail = snapshot.data!;
        if (widget.item.isActivity) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DiscoveryOverview(
                title: 'Plan this experience',
                message:
                    'Explore where to enjoy ${detail.name} and meet the experts who can guide your safari.',
                facts: [
                  MapEntry('${detail.destinations.length}', 'Destinations'),
                  MapEntry('${detail.guides.length}', 'Tour guides'),
                  MapEntry('${detail.operators.length}', 'Operators'),
                ],
              ),
              const SizedBox(height: 36),
              _RelatedCatalogSection(
                title: 'Where to do this activity',
                subtitle: 'Destinations where ${detail.name} is available',
                emptyMessage:
                    'No published destination has been assigned to this activity yet.',
                items: detail.destinations,
              ),
              const SizedBox(height: 38),
              _ProviderSection(
                title: 'Guides for this activity',
                subtitle: 'Local professionals experienced in ${detail.name}',
                emptyMessage:
                    'No guide has added this activity to their profile yet.',
                providers: detail.guides,
              ),
              const SizedBox(height: 38),
              _ProviderSection(
                title: 'Tour operators',
                subtitle:
                    'Safari companies offering ${detail.name} experiences',
                emptyMessage:
                    'No tour operator currently offers this activity.',
                providers: detail.operators,
              ),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DiscoveryOverview(
              title: 'Explore ${detail.name}',
              message:
                  'Find signature activities, trusted safari operators and places to stay—all in one place.',
              facts: [
                MapEntry('${detail.activities.length}', 'Activities'),
                MapEntry('${detail.operators.length}', 'Operators'),
                MapEntry('${detail.accommodations.length}', 'Places to stay'),
              ],
            ),
            const SizedBox(height: 34),
            _DestinationTravelGuide(destination: detail),
            const SizedBox(height: 36),
            _RelatedCatalogSection(
              title: 'Activities available',
              subtitle: 'Experiences available in ${detail.name}',
              emptyMessage:
                  'No published safari activity has been assigned to this destination yet.',
              items: detail.activities,
            ),
            const SizedBox(height: 38),
            _DestinationOperatorSection(
              destination: detail,
              operators: detail.operators,
            ),
            const SizedBox(height: 38),
            _AccommodationSection(destination: detail),
          ],
        );
      },
    );
  }
}

class _DiscoveryOverview extends StatelessWidget {
  const _DiscoveryOverview({
    required this.title,
    required this.message,
    required this.facts,
  });

  final String title;
  final String message;
  final List<MapEntry<String, String>> facts;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF123F38), Color(0xFF1F6B5C)],
        ),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toTitleCase(),
            style: theme.textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w300,
              letterSpacing: -.35,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withOpacity(.76),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 19),
          Row(
            children:
                facts
                    .map(
                      (fact) => Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          margin: EdgeInsets.only(
                            right: fact == facts.last ? 0 : 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(.1),
                            borderRadius: BorderRadius.circular(17),
                            border: Border.all(
                              color: Colors.white.withOpacity(.12),
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(
                                fact.key.toTitleCase(),
                                style: theme.textTheme.titleLarge?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w300,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                fact.value,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: Colors.white.withOpacity(.72),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                    .toList(),
          ),
        ],
      ),
    );
  }
}

class _DestinationTravelGuide extends StatelessWidget {
  const _DestinationTravelGuide({required this.destination});

  final CatalogItem destination;

  String _value(String? value) =>
      value?.trim().isNotEmpty == true
          ? value!.trim()
          : 'Ask an operator for local advice';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F0E4),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE4D4BC)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6B4C2F).withOpacity(.08),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFFB45F3D),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.explore_rounded,
                  color: Colors.white,
                  size: 25,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Plan Your Visit',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: const Color(0xFF2F2921),
                        fontWeight: FontWeight.w300,
                        letterSpacing: -.3,
                      ),
                    ),
                    Text(
                      'A field guide to ${destination.name}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF6B5B4B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 19),
          LayoutBuilder(
            builder: (context, constraints) {
              final tileWidth = (constraints.maxWidth - 10) / 2;
              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _TravelFact(
                    width: tileWidth,
                    icon: Icons.calendar_month_outlined,
                    label: 'Best months to visit',
                    value: _value(destination.bestMonthsToVisit),
                  ),
                  _TravelFact(
                    width: tileWidth,
                    icon: Icons.schedule_rounded,
                    label: 'Recommended trip',
                    value: _value(destination.recommendedTripLength),
                  ),
                  _TravelFact(
                    width: tileWidth,
                    icon: Icons.terrain_rounded,
                    label: 'Difficulty',
                    value: _value(destination.difficulty),
                  ),
                  _TravelFact(
                    width: tileWidth,
                    icon: Icons.cloud_outlined,
                    label: 'Weather',
                    value: _value(destination.weatherSummary),
                  ),
                ],
              );
            },
          ),
          if (destination.accessRoute?.trim().isNotEmpty == true ||
              (destination.latitude != null &&
                  destination.longitude != null)) ...[
            const SizedBox(height: 13),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: const Color(0xFF263E36),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.route_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Route & Coordinates',
                          style: TextStyle(
                            color: Color(0xFFB8D8CC),
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            letterSpacing: .8,
                          ),
                        ),
                        const SizedBox(height: 5),
                        if (destination.accessRoute?.trim().isNotEmpty == true)
                          Text(
                            destination.accessRoute!.trim(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              height: 1.4,
                            ),
                          ),
                        if (destination.latitude != null &&
                            destination.longitude != null) ...[
                          const SizedBox(height: 5),
                          Text(
                            '${destination.latitude!.toStringAsFixed(5)}°, ${destination.longitude!.toStringAsFixed(5)}°',
                            style: const TextStyle(
                              color: Color(0xFFD6E8E1),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const Icon(Icons.explore_outlined, color: Color(0xFFB8D8CC)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TravelFact extends StatelessWidget {
  const _TravelFact({
    required this.width,
    required this.icon,
    required this.label,
    required this.value,
  });

  final double width;
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: width,
      constraints: const BoxConstraints(minHeight: 126),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.72),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE7D8C3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: const Color(0xFF1F6B5C)),
          const SizedBox(height: 10),
          Text(
            label.toTitleCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: const Color(0xFF7B6957),
              fontWeight: FontWeight.w900,
              letterSpacing: .65,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF312B24),
              fontWeight: FontWeight.w800,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }
}

class _RelatedCatalogSection extends StatelessWidget {
  const _RelatedCatalogSection({
    required this.title,
    required this.subtitle,
    required this.emptyMessage,
    required this.items,
  });

  final String title;
  final String subtitle;
  final String emptyMessage;
  final List<CatalogItem> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toTitleCase(),
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w300,
            letterSpacing: -.45,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          subtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(.65),
            height: 1.35,
          ),
        ),
        const SizedBox(height: 18),
        if (items.isEmpty)
          IllustratedEmptyState(
            title: 'More discoveries are coming',
            message: emptyMessage,
            icon: Icons.explore_outlined,
          )
        else
          SizedBox(
            height: 244,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder:
                  (context, index) => _RelatedCatalogCard(item: items[index]),
            ),
          ),
      ],
    );
  }
}

class _RelatedCatalogCard extends StatelessWidget {
  const _RelatedCatalogCard({required this.item});

  final CatalogItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 238,
      child: Material(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap:
              () => Navigator.push(
                context,
                premiumPageRoute((_) => CatalogDetailPage(item: item)),
              ),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: theme.colorScheme.outlineVariant),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF102E2A).withOpacity(.055),
                  blurRadius: 20,
                  offset: const Offset(0, 9),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 146,
                      child: Hero(
                        tag: catalogHeroTag(item.type, item.id),
                        child:
                            item.imageUrl.isEmpty
                                ? Container(
                                  color: const Color(0xFFE2F1EB),
                                  child: Icon(
                                    item.isActivity
                                        ? Icons.explore_outlined
                                        : Icons.landscape_outlined,
                                    color: const Color(0xFF1F6B5C),
                                    size: 48,
                                  ),
                                )
                                : ColorFiltered(
                                  colorFilter: const ColorFilter.mode(
                                    Color(0x183E6B52),
                                    BlendMode.softLight,
                                  ),
                                  child: Image.network(
                                    item.imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (_, __, ___) => Container(
                                          color: const Color(0xFFE2F1EB),
                                          child: const Icon(
                                            Icons.image_not_supported_outlined,
                                            color: Color(0xFF1F6B5C),
                                            size: 42,
                                          ),
                                        ),
                                  ),
                                ),
                      ),
                    ),
                    Positioned(
                      right: 11,
                      top: 11,
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(.94),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.arrow_outward_rounded,
                          color: Color(0xFF173F39),
                          size: 19,
                        ),
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(15, 13, 15, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w300,
                            height: 1.15,
                          ),
                        ),
                        if (!item.isActivity &&
                            item.location?.trim().isNotEmpty == true) ...[
                          const Spacer(),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on_outlined,
                                size: 15,
                                color: Color(0xFF1F6B5C),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  item.location!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodySmall,
                                ),
                              ),
                            ],
                          ),
                        ] else
                          const Spacer(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProviderSection extends StatelessWidget {
  const _ProviderSection({
    required this.title,
    required this.subtitle,
    required this.emptyMessage,
    required this.providers,
  });

  final String title;
  final String subtitle;
  final String emptyMessage;
  final List<CommunityMember> providers;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toTitleCase(),
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w300,
            letterSpacing: -.45,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          subtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(.65),
            height: 1.35,
          ),
        ),
        const SizedBox(height: 18),
        if (providers.isEmpty)
          _CatalogEmptyState(message: emptyMessage)
        else
          SizedBox(
            height: premiumProviderCardHeight,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              itemCount: providers.length,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder:
                  (context, index) =>
                      PremiumProviderCard(member: providers[index]),
            ),
          ),
      ],
    );
  }
}

class _DestinationOperatorSection extends StatelessWidget {
  const _DestinationOperatorSection({
    required this.destination,
    required this.operators,
  });

  final CatalogItem destination;
  final List<CommunityMember> operators;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Safari Experts for This Destination',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w300,
                      letterSpacing: -.45,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Trusted tour operators offering safaris to ${destination.name}.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.onSurface.withOpacity(.65),
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            if (operators.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${operators.length}',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colors.onPrimaryContainer,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 18),
        if (operators.isEmpty)
          const _CatalogEmptyState(
            message: 'No tour operator currently lists this destination.',
          )
        else
          SizedBox(
            height: premiumProviderCardHeight,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              itemCount: operators.length,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (context, index) {
                final operator = operators[index];
                final cardWidth =
                    (MediaQuery.sizeOf(context).width * .84)
                        .clamp(280.0, 312.0)
                        .toDouble();

                return SizedBox(
                  width: cardWidth,
                  child: FutureBuilder<CommunityMember>(
                    future: CommunityService.instance.fetchMember(operator.id),
                    builder: (context, snapshot) {
                      final fullOperator = snapshot.data ?? operator;

                      return PremiumProviderCard(member: fullOperator);
                    },
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _CatalogEmptyState extends StatelessWidget {
  const _CatalogEmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return IllustratedEmptyState(
      title: 'The trail starts here',
      message: message,
      icon: Icons.route_rounded,
    );
  }
}

class _AccommodationSection extends StatefulWidget {
  const _AccommodationSection({required this.destination});

  final CatalogItem destination;

  @override
  State<_AccommodationSection> createState() => _AccommodationSectionState();
}

class _AccommodationSectionState extends State<_AccommodationSection> {
  static const int _pageSize = 10;
  int _visibleCount = _pageSize;

  @override
  void didUpdateWidget(covariant _AccommodationSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.destination.id != widget.destination.id) {
      _visibleCount = _pageSize;
    }
  }

  void _viewMore(int total) {
    setState(() {
      final nextCount = _visibleCount + _pageSize;
      _visibleCount = nextCount < total ? nextCount : total;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final destination = widget.destination;
    final accommodations = destination.accommodations;
    final end =
        _visibleCount < accommodations.length
            ? _visibleCount
            : accommodations.length;
    final visibleAccommodations = accommodations.take(end).toList();
    final remaining = accommodations.length - end;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Nearby accommodation',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w300,
                ),
              ),
            ),
            if (accommodations.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${accommodations.length} stays',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Places to stay in and around ${destination.name}',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(.65),
          ),
        ),
        const SizedBox(height: 16),
        if (accommodations.isEmpty)
          const IllustratedEmptyState(
            title: 'A place to rest is coming',
            message:
                'No accommodation has been published for this destination yet.',
            icon: Icons.hotel_outlined,
          )
        else ...[
          AnimatedSize(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: Container(
              key: ValueKey(end),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: theme.colorScheme.outline.withOpacity(.12),
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0D000000),
                    blurRadius: 20,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  for (
                    var index = 0;
                    index < visibleAccommodations.length;
                    index++
                  ) ...[
                    _AccommodationCard(
                      accommodation: visibleAccommodations[index],
                    ),
                    if (index < visibleAccommodations.length - 1)
                      Divider(
                        height: 1,
                        thickness: 1,
                        indent: 96,
                        color: theme.colorScheme.outline.withOpacity(.1),
                      ),
                  ],
                ],
              ),
            ),
          ),
          if (remaining > 0) ...[
            const SizedBox(height: 2),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _viewMore(accommodations.length),
                icon: const Icon(Icons.keyboard_arrow_down_rounded),
                label: Text(
                  'View more ($remaining remaining)',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ],
      ],
    );
  }
}

String _accommodationHeroTag(int id) => 'accommodation-photo-$id';

class _AccommodationCard extends StatelessWidget {
  const _AccommodationCard({required this.accommodation});

  final Accommodation accommodation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final images = accommodation.galleryUrls;
    final priceParts = accommodation.formattedPrice.split(' / ');
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showDetails(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(13),
                child: SizedBox(
                  width: 68,
                  height: 68,
                  child: Hero(
                    tag: _accommodationHeroTag(accommodation.id),
                    child: Material(
                      color: Colors.transparent,
                      child:
                          images.isNotEmpty
                              ? Image.network(
                                images.first,
                                fit: BoxFit.cover,
                                errorBuilder:
                                    (_, __, ___) => _imageFallback(theme),
                              )
                              : _imageFallback(theme),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      accommodation.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_rounded,
                          size: 14,
                          color: theme.colorScheme.onSurface.withOpacity(.62),
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            accommodation.location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(
                                .62,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Icon(
                          accommodation.amenities.isEmpty
                              ? Icons.photo_library_outlined
                              : Icons.auto_awesome_rounded,
                          size: 14,
                          color: const Color(0xFFE58A2B),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            accommodation.amenities.isEmpty
                                ? images.isEmpty
                                    ? 'View stay details'
                                    : '${images.length} photo${images.length == 1 ? '' : 's'}'
                                : accommodation.amenities.first,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    priceParts.first,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w300,
                      letterSpacing: -.4,
                    ),
                  ),
                  Text(
                    'night',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(.48),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _imageFallback(ThemeData theme) {
    return ColoredBox(
      color: theme.colorScheme.primaryContainer,
      child: Icon(
        Icons.hotel_rounded,
        color: theme.colorScheme.onPrimaryContainer,
        size: 42,
      ),
    );
  }

  void _showDetails(BuildContext context) {
    Navigator.push<void>(
      context,
      premiumPageRoute(
        (_) => _AccommodationDetailPage(accommodation: accommodation),
      ),
    );
  }
}

class _AccommodationDetailPage extends StatelessWidget {
  const _AccommodationDetailPage({required this.accommodation});

  final Accommodation accommodation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final contacts = _contacts;
    final quickContacts = contacts.take(3).toList();
    final primaryContact = _bookingContact;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F3E8),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: MediaQuery.sizeOf(context).height * .58,
            pinned: true,
            stretch: true,
            foregroundColor: Colors.white,
            backgroundColor: const Color(0xFF102E2A),
            clipBehavior: Clip.antiAlias,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(42)),
            ),
            leadingWidth: 72,
            leading: Padding(
              padding: const EdgeInsets.only(left: 16, top: 7, bottom: 7),
              child: _AccommodationHeroAction(
                icon: Icons.arrow_back_rounded,
                tooltip: 'Back',
                onTap: () => Navigator.pop(context),
              ),
            ),
            actions: [
              _AccommodationHeroAction(
                icon: Icons.ios_share_rounded,
                tooltip: 'Share accommodation',
                light: true,
                onTap: () => _shareAccommodation(context),
              ),
              const SizedBox(width: 8),
              if (_websiteContact != null)
                _AccommodationHeroAction(
                  icon: Icons.link_rounded,
                  tooltip: 'Open website',
                  onTap: () => _openContact(context, _websiteContact!),
                ),
              const SizedBox(width: 16),
            ],
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              stretchModes: const [StretchMode.zoomBackground],
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: _accommodationHeroTag(accommodation.id),
                    child: _AccommodationGallery(
                      accommodation: accommodation,
                      counterTop: 92,
                      indicatorBottom: 148,
                    ),
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0x19000000),
                          Color(0x26000000),
                          Color(0xE6102522),
                        ],
                        stops: [0, .43, 1],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 22,
                    right: 22,
                    bottom: 28,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(.18),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withOpacity(.28),
                            ),
                          ),
                          child: const Icon(
                            Icons.hotel_rounded,
                            color: Colors.white,
                            size: 23,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          accommodation.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w300,
                            height: 1.04,
                            letterSpacing: -.6,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              size: 18,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                accommodation.location,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.white.withOpacity(.86),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 38),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (accommodation.amenities.isNotEmpty) ...[
                    _sectionTitle(context, 'Popular amenities'),
                    const SizedBox(height: 13),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      clipBehavior: Clip.none,
                      child: Row(
                        children: [
                          for (
                            var index = 0;
                            index < accommodation.amenities.length;
                            index++
                          ) ...[
                            if (index > 0) const SizedBox(width: 9),
                            _AccommodationAmenityPill(
                              amenity: accommodation.amenities[index],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                  _sectionTitle(context, 'Description'),
                  const SizedBox(height: 11),
                  Text(
                    accommodation.description,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      height: 1.6,
                      color: colors.onSurface.withOpacity(.76),
                    ),
                  ),
                  if (quickContacts.isNotEmpty) ...[
                    const SizedBox(height: 30),
                    _sectionTitle(context, 'Quick actions'),
                    const SizedBox(height: 13),
                    Row(
                      children: [
                        for (
                          var index = 0;
                          index < quickContacts.length;
                          index++
                        ) ...[
                          if (index > 0) const SizedBox(width: 10),
                          Expanded(
                            child: _AccommodationQuickAction(
                              contact: quickContacts[index],
                              onTap:
                                  () => _openContact(
                                    context,
                                    quickContacts[index],
                                  ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                  if (contacts.isNotEmpty) ...[
                    const SizedBox(height: 28),
                    _sectionTitle(context, 'Contact & links'),
                    const SizedBox(height: 12),
                    ...contacts.map(
                      (contact) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Material(
                          color: colors.surface,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                            side: BorderSide(
                              color: colors.outline.withOpacity(.16),
                            ),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: ListTile(
                            onTap: () => _openContact(context, contact),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 15,
                              vertical: 5,
                            ),
                            leading: Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: colors.primaryContainer,
                                borderRadius: BorderRadius.circular(13),
                              ),
                              child: Icon(
                                contact.icon,
                                color: colors.onPrimaryContainer,
                              ),
                            ),
                            title: Text(
                              contact.label,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            subtitle: Text(
                              contact.value,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: Icon(
                              Icons.open_in_new_rounded,
                              size: 19,
                              color: colors.primary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar:
          primaryContact == null
              ? null
              : Container(
                decoration: BoxDecoration(
                  color: colors.surface,
                  border: Border(
                    top: BorderSide(color: colors.outline.withOpacity(.14)),
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x14000000),
                      blurRadius: 22,
                      offset: Offset(0, -6),
                    ),
                  ],
                ),
                child: SafeArea(
                  minimum: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'From',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colors.onSurface.withOpacity(.55),
                              ),
                            ),
                            Text(
                              accommodation.formattedPrice,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w300,
                              ),
                            ),
                          ],
                        ),
                      ),
                      FilledButton.icon(
                        onPressed: () => _openContact(context, primaryContact),
                        icon: const Icon(Icons.calendar_month_rounded),
                        label: const Text('Book now'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Text(
      title.toTitleCase(),
      style: Theme.of(
        context,
      ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w300),
    );
  }

  _AccommodationContact? get _websiteContact {
    for (final contact in _contacts) {
      if (contact.label == 'Website') return contact;
    }
    return null;
  }

  _AccommodationContact? get _bookingContact {
    for (final contact in _contacts) {
      if (contact.label == 'Phone' ||
          contact.label == 'Website' ||
          contact.label == 'Email') {
        return contact;
      }
    }
    return null;
  }

  Future<void> _shareAccommodation(BuildContext context) async {
    final lines = <String>[
      accommodation.name,
      accommodation.location,
      accommodation.formattedPrice,
      if (accommodation.website?.trim().isNotEmpty == true)
        accommodation.website!.trim(),
    ];
    await Clipboard.setData(ClipboardData(text: lines.join('\n')));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Accommodation details copied.')),
    );
  }

  List<_AccommodationContact> get _contacts {
    final contacts = <_AccommodationContact>[];
    final phone = accommodation.contactPhone?.trim() ?? '';
    final email = accommodation.contactEmail?.trim() ?? '';
    final website = accommodation.website?.trim() ?? '';
    final websiteUri = _websiteUri(website);

    if (phone.isNotEmpty) {
      contacts.add(
        _AccommodationContact(
          icon: Icons.phone_outlined,
          label: 'Phone',
          value: phone,
          uri: Uri(scheme: 'tel', path: phone),
        ),
      );
    }
    if (websiteUri != null) {
      contacts.add(
        _AccommodationContact(
          icon: Icons.language_rounded,
          label: 'Website',
          value: website,
          uri: websiteUri,
        ),
      );
    }
    if (email.isNotEmpty) {
      contacts.add(
        _AccommodationContact(
          icon: Icons.email_outlined,
          label: 'Email',
          value: email,
          uri: Uri(
            scheme: 'mailto',
            path: email,
            queryParameters: {
              'subject': 'Accommodation enquiry: ${accommodation.name}',
            },
          ),
        ),
      );
    }
    if (accommodation.location.trim().isNotEmpty) {
      contacts.add(
        _AccommodationContact(
          icon: Icons.directions_outlined,
          label: 'Directions',
          value: accommodation.location.trim(),
          uri: Uri.https('www.google.com', '/maps/search/', {
            'api': '1',
            'query': accommodation.location.trim(),
          }),
        ),
      );
    }
    return contacts;
  }

  Uri? _websiteUri(String value) {
    if (value.isEmpty) return null;
    final candidate = value.contains('://') ? value : 'https://$value';
    final uri = Uri.tryParse(candidate);
    if (uri == null || uri.host.isEmpty) return null;
    if (uri.scheme != 'http' && uri.scheme != 'https') return null;
    return uri;
  }

  Future<void> _openContact(
    BuildContext context,
    _AccommodationContact contact,
  ) async {
    try {
      final isWeb =
          contact.uri.scheme == 'http' || contact.uri.scheme == 'https';
      final opened = await launchUrl(
        contact.uri,
        mode:
            isWeb ? LaunchMode.externalApplication : LaunchMode.platformDefault,
      );
      if (!opened && context.mounted) {
        _showLinkError(context);
      }
    } catch (_) {
      if (context.mounted) {
        _showLinkError(context);
      }
    }
  }

  void _showLinkError(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('This link could not be opened on this device.'),
      ),
    );
  }
}

class _AccommodationContact {
  const _AccommodationContact({
    required this.icon,
    required this.label,
    required this.value,
    required this.uri,
  });

  final IconData icon;
  final String label;
  final String value;
  final Uri uri;
}

class _AccommodationQuickAction extends StatelessWidget {
  const _AccommodationQuickAction({required this.contact, required this.onTap});

  final _AccommodationContact contact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.primaryContainer.withOpacity(.6),
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 86,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(contact.icon, color: theme.colorScheme.onPrimaryContainer),
              const SizedBox(height: 8),
              Text(
                contact.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccommodationHeroAction extends StatelessWidget {
  const _AccommodationHeroAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.light = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool light;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: light ? Colors.white : Colors.black.withOpacity(.42),
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: 46,
            height: 46,
            child: Icon(
              icon,
              color: light ? const Color(0xFF162622) : Colors.white,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }
}

class _AccommodationAmenityPill extends StatelessWidget {
  const _AccommodationAmenityPill({required this.amenity});

  final String amenity;

  IconData get _icon {
    final value = amenity.toLowerCase();
    if (value.contains('wifi') || value.contains('internet')) {
      return Icons.wifi_rounded;
    }
    if (value.contains('bed') || value.contains('room')) {
      return Icons.bed_rounded;
    }
    if (value.contains('breakfast') ||
        value.contains('restaurant') ||
        value.contains('food')) {
      return Icons.restaurant_rounded;
    }
    if (value.contains('pool') || value.contains('swim')) {
      return Icons.pool_rounded;
    }
    if (value.contains('parking') || value.contains('car')) {
      return Icons.local_parking_rounded;
    }
    if (value.contains('spa')) return Icons.spa_rounded;
    if (value.contains('tv')) return Icons.tv_rounded;
    if (value.contains('bar')) return Icons.local_bar_rounded;
    return Icons.check_circle_outline_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(.12)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, size: 19, color: theme.colorScheme.primary),
          const SizedBox(width: 7),
          Text(
            amenity,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _AccommodationGallery extends StatefulWidget {
  const _AccommodationGallery({
    required this.accommodation,
    this.counterTop = 12,
    this.indicatorBottom = 12,
  });

  final Accommodation accommodation;
  final double counterTop;
  final double indicatorBottom;

  @override
  State<_AccommodationGallery> createState() => _AccommodationGalleryState();
}

class _AccommodationGalleryState extends State<_AccommodationGallery> {
  int _current = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final images = widget.accommodation.galleryUrls;
    if (images.isEmpty) {
      return Container(
        width: double.infinity,
        height: 210,
        color: theme.colorScheme.primaryContainer,
        child: const Icon(Icons.hotel_rounded, size: 62),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 220,
      child: Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            itemCount: images.length,
            onPageChanged: (index) => setState(() => _current = index),
            itemBuilder:
                (context, index) => Image.network(
                  images[index],
                  fit: BoxFit.cover,
                  errorBuilder:
                      (_, __, ___) => Container(
                        color: theme.colorScheme.primaryContainer,
                        child: const Icon(
                          Icons.broken_image_outlined,
                          size: 48,
                        ),
                      ),
                ),
          ),
          if (images.length > 1)
            Positioned(
              right: 12,
              top: widget.counterTop,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(.62),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.photo_library_outlined,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '${_current + 1}/${images.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (images.length > 1)
            Positioned(
              left: 0,
              right: 0,
              bottom: widget.indicatorBottom,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(images.length, (index) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: index == _current ? 22 : 7,
                    height: 7,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color:
                          index == _current
                              ? Colors.white
                              : Colors.white.withOpacity(.58),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }
}
