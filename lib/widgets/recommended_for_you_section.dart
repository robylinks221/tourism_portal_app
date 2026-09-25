import 'package:flutter/material.dart';

import '../models/discovery_item.dart';
import '../models/operator_management.dart';
import '../models/catalog_item.dart';
import '../pages/tour_details_page.dart';
import '../services/discovery_store.dart';
import '../services/catalog_service.dart';
import '../services/operator_offerings_service.dart';
import 'app_ui.dart';
import 'guest_access_sheet.dart';
import 'premium_states.dart';

class RecommendedForYouSection extends StatefulWidget {
  const RecommendedForYouSection({
    super.key,
    this.isGuest = false,
    this.countryName,
  });

  final bool isGuest;
  final String? countryName;

  @override
  State<RecommendedForYouSection> createState() =>
      _RecommendedForYouSectionState();
}

class _RecommendedForYouSectionState extends State<RecommendedForYouSection> {
  late Future<OperatorOfferings> _offerings;
  late Future<TourismCatalog> _catalog;

  @override
  void initState() {
    super.initState();
    _offerings = OperatorOfferingsService.instance.fetch();
    _catalog = CatalogService.instance.fetchCatalog();
  }

  void _retry() {
    setState(() {
      _offerings = OperatorOfferingsService.instance.fetch();
      _catalog = CatalogService.instance.fetchCatalog();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Object>>(
      future: Future.wait<Object>([_offerings, _catalog]),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppSectionHeader(
                title: 'Recommended for you',
                subtitle: 'Curated by trusted local experts.',
              ),
              SizedBox(height: 14),
              PremiumSkeleton(height: 356),
            ],
          );
        }

        if (snapshot.hasError) {
          return AppStatePanel(
            title: 'Recommendations could not be loaded',
            message: 'Check your connection and try again.',
            kind: AppStateKind.offline,
            onRetry: _retry,
          );
        }

        final offerings = snapshot.data![0] as OperatorOfferings;
        final catalog = snapshot.data![1] as TourismCatalog;
        final country = widget.countryName?.trim().toLowerCase();
        final destinationIds = country == null || country.isEmpty
            ? <int>{}
            : catalog.destinations
                .where(
                  (destination) =>
                      (destination.country ?? '').trim().toLowerCase() ==
                      country,
                )
                .map((destination) => destination.id)
                .toSet();
        final allTours = offerings.tours.where((tour) {
          if (!tour.isActive) return false;
          if (country == null || country.isEmpty) return true;
          return tour.destinationIds.any(destinationIds.contains);
        }).toList();

        if (allTours.isEmpty) {
          return const SizedBox.shrink();
        }

        final tours = [...allTours]..sort((a, b) {
          final verifiedCompare = (b.isOperatorVerified ? 1 : 0).compareTo(
            a.isOperatorVerified ? 1 : 0,
          );

          if (verifiedCompare != 0) {
            return verifiedCompare;
          }

          final ratingCompare = b.operatorRatingAverage.compareTo(
            a.operatorRatingAverage,
          );

          if (ratingCompare != 0) {
            return ratingCompare;
          }

          return b.operatorRatingCount.compareTo(a.operatorRatingCount);
        });

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppSectionHeader(
              title: 'Recommended for you',
              subtitle: 'Curated by trusted local experts.',
              actionLabel: 'View all',
              onAction: () {
                Navigator.push<void>(
                  context,
                  MaterialPageRoute<void>(
                    builder:
                        (_) => _AllRecommendedToursPage(
                          tours: tours,
                          isGuest: widget.isGuest,
                        ),
                  ),
                );
              },
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 382,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                itemCount: tours.take(6).length,
                separatorBuilder: (_, __) => const SizedBox(width: 14),
                itemBuilder:
                    (context, index) => _RecommendedTourCard(
                      tour: tours[index],
                      featured: index == 0,
                      isGuest: widget.isGuest,
                    ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _RecommendedTourCard extends StatelessWidget {
  const _RecommendedTourCard({
    required this.tour,
    required this.featured,
    required this.isGuest,
  });

  final OperatorTour tour;
  final bool featured;
  final bool isGuest;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final width =
        (MediaQuery.sizeOf(context).width * .84).clamp(292, 342).toDouble();

    final destination =
        tour.destinationNames.isEmpty
            ? 'East Africa'
            : tour.destinationNames.first;

    return SizedBox(
      width: width,
      child: Material(
        color: colors.surface,
        surfaceTintColor: Colors.transparent,
        borderRadius: BorderRadius.circular(28),
        clipBehavior: Clip.antiAlias,
        elevation: 3,
        shadowColor: Colors.black.withOpacity(.16),
        child: InkWell(
          onTap: () => _openTour(context),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: colors.outlineVariant.withOpacity(.72)),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _TourImage(tour: tour),
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Color(0x08000000),
                              Color(0x16000000),
                              Color(0xC9000000),
                            ],
                            stops: [0, .48, 1],
                          ),
                        ),
                      ),
                      if (featured)
                        const Positioned(
                          left: 15,
                          top: 15,
                          child: _EditorsPickBadge(),
                        ),
                      Positioned(
                        right: 13,
                        top: 13,
                        child: _SaveTourButton(tour: tour, isGuest: isGuest),
                      ),
                      Positioned(
                        left: 17,
                        right: 17,
                        bottom: 15,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Text(
                                destination,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'From',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: Colors.white.withOpacity(.76),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  _price(tour),
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
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
                Padding(
                  padding: const EdgeInsets.fromLTRB(17, 16, 17, 17),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tour.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          height: 1.15,
                          letterSpacing: -.25,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Row(
                        children: [
                          Icon(
                            Icons.schedule_rounded,
                            size: 16,
                            color: colors.primary,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '${tour.days} ${tour.days == 1 ? 'day' : 'days'}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colors.onSurface.withOpacity(.62),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (destination.isNotEmpty) ...[
                            const SizedBox(width: 7),
                            Text(
                              '•',
                              style: TextStyle(
                                color: colors.onSurface.withOpacity(.38),
                              ),
                            ),
                            const SizedBox(width: 7),
                            Expanded(
                              child: Text(
                                destination,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colors.onSurface.withOpacity(.62),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 14),
                      Divider(
                        height: 1,
                        color: colors.outlineVariant.withOpacity(.62),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _ProviderLogo(tour: tour),
                          const SizedBox(width: 9),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tour.operatorName.isEmpty
                                      ? 'Local safari expert'
                                      : tour.operatorName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  tour.isGuideLed
                                      ? 'Tour Guide'
                                      : 'Tour Operator',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: colors.onSurface.withOpacity(.54),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (tour.operatorRatingCount > 0)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.star_rounded,
                                  size: 18,
                                  color: Color(0xFFD5A62A),
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  tour.operatorRatingAverage.toStringAsFixed(1),
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          if (tour.isOperatorVerified) ...[
                            const SizedBox(width: 7),
                            Icon(
                              Icons.verified_rounded,
                              size: 19,
                              color: colors.primary,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openTour(BuildContext context) async {
    await DiscoveryStore.instance.recordView(DiscoveryRecord.fromTour(tour));

    if (!context.mounted) {
      return;
    }

    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(builder: (_) => TourDetailsPage(tour: tour)),
    );
  }
}

class _TourImage extends StatelessWidget {
  const _TourImage({required this.tour});

  final OperatorTour tour;

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      color: Theme.of(context).colorScheme.primaryContainer,
      alignment: Alignment.center,
      child: Icon(
        Icons.landscape_outlined,
        size: 62,
        color: Theme.of(context).colorScheme.primary,
      ),
    );

    if (tour.imageUrl.isEmpty) {
      return fallback;
    }

    return Image.network(
      tour.imageUrl,
      fit: BoxFit.cover,
      filterQuality: FilterQuality.medium,
      errorBuilder: (_, __, ___) => fallback,
    );
  }
}

class _ProviderLogo extends StatelessWidget {
  const _ProviderLogo({required this.tour});

  final OperatorTour tour;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final fallback = Container(
      width: 38,
      height: 38,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        tour.isGuideLed
            ? Icons.person_outline_rounded
            : Icons.business_outlined,
        size: 19,
        color: colors.primary,
      ),
    );

    if (tour.operatorLogoUrl.isEmpty) {
      return fallback;
    }

    return Container(
      width: 38,
      height: 38,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.outlineVariant.withOpacity(.72)),
      ),
      child: Image.network(
        tour.operatorLogoUrl,
        fit: tour.isGuideLed ? BoxFit.cover : BoxFit.contain,
        errorBuilder: (_, __, ___) => fallback,
      ),
    );
  }
}

class _EditorsPickBadge extends StatelessWidget {
  const _EditorsPickBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFD7A842),
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Text(
        "EDITOR'S PICK",
        style: TextStyle(
          color: Color(0xFF102017),
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _SaveTourButton extends StatelessWidget {
  const _SaveTourButton({required this.tour, required this.isGuest});

  final OperatorTour tour;
  final bool isGuest;

  @override
  Widget build(BuildContext context) {
    final record = DiscoveryRecord.fromTour(tour);

    return AnimatedBuilder(
      animation: DiscoveryStore.instance,
      builder: (context, _) {
        final saved = DiscoveryStore.instance.isSaved(record);

        return Material(
          color: Colors.black.withOpacity(.46),
          shape: const CircleBorder(),
          child: IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: saved ? 'Remove from saved' : 'Save tour',
            onPressed: () async {
              if (isGuest) {
                await showGuestAccessSheet(
                  context,
                  title: 'Save this safari',
                  message:
                      'Login or create a free account to save tours and compare them later.',
                );
                return;
              }

              DiscoveryStore.instance.toggleSaved(record);
            },
            icon: Icon(
              saved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: Colors.white,
              size: 21,
            ),
          ),
        );
      },
    );
  }
}

class _AllRecommendedToursPage extends StatelessWidget {
  const _AllRecommendedToursPage({required this.tours, required this.isGuest});

  final List<OperatorTour> tours;
  final bool isGuest;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recommended Safaris')),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
        itemCount: tours.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder:
            (context, index) => SizedBox(
              height: 382,
              child: _RecommendedTourCard(
                tour: tours[index],
                featured: index == 0,
                isGuest: isGuest,
              ),
            ),
      ),
    );
  }
}

String _price(OperatorTour tour) {
  final value = tour.price.toStringAsFixed(
    tour.price == tour.price.roundToDouble() ? 0 : 2,
  );

  return '${tour.currency.isEmpty ? 'USD' : tour.currency} $value';
}
