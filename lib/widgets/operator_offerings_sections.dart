import 'package:flutter/material.dart';

import '../models/catalog_item.dart';
import '../models/community.dart';
import '../models/discovery_item.dart';
import '../models/operator_management.dart';
import '../models/safari_mood.dart';
import '../pages/car_hire_page.dart';
import '../services/catalog_service.dart';
import '../services/discovery_store.dart';
import '../services/operator_offerings_service.dart';
import '../utils/text_case.dart';
import 'app_ui.dart';
import 'provider_discovery_sections.dart';
import 'safari_trail.dart';

class OperatorOfferingsSections extends StatefulWidget {
  const OperatorOfferingsSections({super.key, this.countryName});

  final String? countryName;

  @override
  State<OperatorOfferingsSections> createState() =>
      _OperatorOfferingsSectionsState();
}

class _OperatorOfferingsSectionsState extends State<OperatorOfferingsSections> {
  late Future<_SafariOfferingsData> _data;
  int? _selectedActivityId;

  @override
  void initState() {
    super.initState();
    _data = _load();
  }

  Future<_SafariOfferingsData> _load() async {
    final offeringsFuture = OperatorOfferingsService.instance.fetch();
    final catalogFuture = CatalogService.instance.fetchCatalog();
    return _SafariOfferingsData(
      offerings: await offeringsFuture,
      catalog: await catalogFuture,
    );
  }

  void _retry() {
    setState(() => _data = _load());
  }

  Widget _buildSections({
    required OperatorOfferings offerings,
    required List<CatalogItem> activities,
    required List<OperatorTour> tours,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TourSection(
          tours: tours,
        ),
        const SizedBox(height: 30),
        _VehicleSection(vehicles: offerings.vehicles),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_SafariOfferingsData>(
      future: _data,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const AppDiscoverySkeleton();
        }
        if (snapshot.hasError) {
          return AppStatePanel(
            title: 'Tours and car hire could not be loaded',
            message: 'Check your connection and retry the offerings service.',
            kind: AppStateKind.offline,
            onRetry: _retry,
          );
        }

        final data = snapshot.data!;
        return ValueListenableBuilder<String?>(
          valueListenable: SafariMoodController.instance,
          builder: (context, selectedMoodKey, _) {
            final offerings = data.offerings;
            final catalog = data.catalog;
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
            final countryTours = country == null || country.isEmpty
                ? offerings.tours
                : offerings.tours
                    .where(
                      (tour) =>
                          tour.destinationIds.any(destinationIds.contains),
                    )
                    .toList();
            final activityIds =
                countryTours.expand((tour) => tour.activityIds).toSet();
            final countryActivities = country == null || country.isEmpty
                ? catalog.activities
                : catalog.activities
                    .where((activity) => activityIds.contains(activity.id))
                    .toList();
            final selectedMood = safariMoodByKey(
              catalog.moods,
              selectedMoodKey,
            );
            if (selectedMood != null) {
              return _VehicleSection(vehicles: offerings.vehicles);
            }
            return _buildSections(
              offerings: offerings,
              activities: countryActivities,
              tours: countryTours,
            );
          },
        );
      },
    );
  }
}

class _SafariOfferingsData {
  const _SafariOfferingsData({required this.offerings, required this.catalog});

  final OperatorOfferings offerings;
  final TourismCatalog catalog;
}

class _TourSection extends StatelessWidget {
  const _TourSection({
    required this.tours,
    this.selectedActivityName,
    this.selectedMoodTitle,
  });

  final List<OperatorTour> tours;
  final String? selectedActivityName;
  final String? selectedMoodTitle;

  @override
  Widget build(BuildContext context) {
    if (tours.isEmpty) {
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _LocalExpertSafarisHeader(total: 0),
          SizedBox(height: 14),
          AppStatePanel(
            title: 'No safaris published yet',
            message:
                'Safaris created by local guides and tour operators will appear here.',
            kind: AppStateKind.empty,
          ),
        ],
      );
    }

    final preview = tours.take(8).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _LocalExpertSafarisHeader(total: tours.length),
        const SizedBox(height: 15),
        SizedBox(
          height: 332,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: preview.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final tour = preview[index];

              return _PremiumLocalSafariCard(
                tour: tour,
                onTap: () => _openTour(context, tour),
                onProviderTap: tour.operatorId > 0
                    ? () => _showProvider(context, tour)
                    : null,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _LocalExpertSafarisHeader extends StatelessWidget {
  const _LocalExpertSafarisHeader({
    required this.total,
  });

  final int total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 35,
                height: 3,
                decoration: BoxDecoration(
                  color: const Color(0xFFF46627),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Safaris by Local Experts',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: const Color(0xFF165B5D),
                  fontWeight: FontWeight.w900,
                  height: 1.05,
                  letterSpacing: -.55,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Journeys created by experienced guides and tour operators.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF66716E),
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
        if (total > 0) ...[
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 11,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF165B5D).withOpacity(.07),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '$total ${total == 1 ? 'Safari' : 'Safaris'}',
              style: theme.textTheme.labelMedium?.copyWith(
                color: const Color(0xFF165B5D),
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _PremiumLocalSafariCard extends StatelessWidget {
  const _PremiumLocalSafariCard({
    required this.tour,
    required this.onTap,
    this.onProviderTap,
  });

  final OperatorTour tour;
  final VoidCallback onTap;
  final VoidCallback? onProviderTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final record = DiscoveryRecord.fromTour(tour);

    return SizedBox(
      width: (MediaQuery.sizeOf(context).width * .74)
          .clamp(260.0, 292.0)
          .toDouble(),
      child: Material(
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
        borderRadius: BorderRadius.circular(26),
        clipBehavior: Clip.antiAlias,
        elevation: 6,
        shadowColor: Colors.black.withOpacity(.13),
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 178,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _OfferingImage(
                      imageUrl: tour.imageUrl,
                      fallbackIcon: Icons.landscape_rounded,
                    ),

                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0x00000000),
                            Color(0x18000000),
                            Color(0xA8001716),
                          ],
                          stops: [0, .52, 1],
                        ),
                      ),
                    ),

                    Positioned(
                      left: 12,
                      right: 54,
                      bottom: 12,
                      child: _TourCountryBadge(tour: tour),
                    ),

                    Positioned(
                      right: 11,
                      top: 11,
                      child: AnimatedBuilder(
                        animation: DiscoveryStore.instance,
                        builder: (context, _) {
                          final saved =
                              DiscoveryStore.instance.isSaved(record);

                          return Material(
                            color: Colors.white.withOpacity(.92),
                            shape: const CircleBorder(),
                            elevation: 2,
                            child: InkWell(
                              onTap: () =>
                                  DiscoveryStore.instance.toggleSaved(record),
                              customBorder: const CircleBorder(),
                              child: SizedBox(
                                width: 39,
                                height: 39,
                                child: Icon(
                                  saved
                                      ? Icons.favorite_rounded
                                      : Icons.favorite_border_rounded,
                                  color: saved
                                      ? const Color(0xFFF46627)
                                      : const Color(0xFF165B5D),
                                  size: 20,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(15, 13, 15, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tour.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: const Color(0xFF17211F),
                          fontWeight: FontWeight.w900,
                          height: 1.12,
                          letterSpacing: -.25,
                        ),
                      ),

                      const SizedBox(height: 10),

                      if (tour.operatorName.trim().isNotEmpty)
                        InkWell(
                          onTap: onProviderTap,
                          borderRadius: BorderRadius.circular(14),
                          child: Row(
                            children: [
                              _ProviderLogo(
                                imageUrl: tour.operatorLogoUrl,
                                operatorName: tour.operatorName,
                              ),
                              const SizedBox(width: 9),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      tour.isGuideLed
                                          ? 'Guided by'
                                          : 'Created by',
                                      style:
                                          theme.textTheme.labelSmall?.copyWith(
                                        color: const Color(0xFF7A8380),
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 1),
                                    Text(
                                      tour.operatorName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style:
                                          theme.textTheme.labelLarge?.copyWith(
                                        color: const Color(0xFF165B5D),
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (onProviderTap != null)
                                const Icon(
                                  Icons.chevron_right_rounded,
                                  color: Color(0xFF165B5D),
                                  size: 19,
                                ),
                            ],
                          ),
                        ),

                      const Spacer(),

                      Divider(
                        height: 1,
                        color: const Color(0xFF165B5D).withOpacity(.08),
                      ),

                      const SizedBox(height: 10),

                      Row(
                        children: [
                          _TourMetaPill(
                            text:
                                '${tour.days} ${tour.days == 1 ? 'Day' : 'Days'}',
                          ),
                          const Spacer(),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'FROM',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: const Color(0xFF8A918E),
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: .55,
                                ),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                _usd(tour.price),
                                style: theme.textTheme.titleSmall?.copyWith(
                                  color: const Color(0xFFF46627),
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TourCountryBadge extends StatelessWidget {
  const _TourCountryBadge({
    required this.tour,
  });

  final OperatorTour tour;

  @override
  Widget build(BuildContext context) {
    final countries = tour.countryNames;

    final label = countries.isNotEmpty
        ? countries.join(' • ').toUpperCase()
        : tour.destinationNames.isNotEmpty
            ? tour.destinationNames.first.toUpperCase()
            : 'EAST AFRICA';

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 205),
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(.17),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: Colors.white.withOpacity(.40),
            width: .8,
          ),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 9.7,
            fontWeight: FontWeight.w900,
            letterSpacing: .45,
          ),
        ),
      ),
    );
  }
}

class _TourMetaPill extends StatelessWidget {
  const _TourMetaPill({
    required this.text,
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF165B5D).withOpacity(.07),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: const Color(0xFF165B5D),
              fontWeight: FontWeight.w900,
            ),
      ),
    );
  }
}

class _VehicleSection extends StatelessWidget {
  const _VehicleSection({required this.vehicles});

  final List<CarHireVehicle> vehicles;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final preview = vehicles.take(6).toList();

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
                  Container(
                    width: 34,
                    height: 3,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF46627),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Safari Car Hire',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: const Color(0xFF165B5D),
                      fontWeight: FontWeight.w900,
                      letterSpacing: -.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Reliable safari vehicles offered by local tour operators.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF66716E),
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            if (vehicles.isNotEmpty) ...[
              const SizedBox(width: 10),
              TextButton.icon(
                onPressed: () {
                  Navigator.push<void>(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => CarHirePage(vehicles: vehicles),
                    ),
                  );
                },
                iconAlignment: IconAlignment.end,
                icon: const Icon(Icons.chevron_right_rounded, size: 20),
                label: const Text(
                  'View All',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 14),

        if (vehicles.isEmpty)
          const AppStatePanel(
            title: 'No vehicles available yet',
            message:
                'Safari vehicles published by local tour operators will appear here.',
            kind: AppStateKind.empty,
          )
        else
          SizedBox(
            height: 272,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: preview.length,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (context, index) {
                final vehicle = preview[index];

                return _PremiumVehiclePreviewCard(
                  vehicle: vehicle,
                  onTap: () => Navigator.push<void>(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => CarHirePage(
                        vehicles: vehicles,
                        initialVehicleId: vehicle.id,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _PremiumVehiclePreviewCard extends StatelessWidget {
  const _PremiumVehiclePreviewCard({
    required this.vehicle,
    required this.onTap,
  });

  final CarHireVehicle vehicle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final details = <String>[
      if (vehicle.seats != null) '${vehicle.seats} seats',
      if (vehicle.transmission?.trim().isNotEmpty == true)
        vehicle.transmission!.trim(),
    ];

    return SizedBox(
      width: (MediaQuery.sizeOf(context).width * .68)
          .clamp(238.0, 270.0)
          .toDouble(),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        clipBehavior: Clip.antiAlias,
        elevation: 5,
        shadowColor: Colors.black.withOpacity(.12),
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 154,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _OfferingImage(
                      imageUrl: vehicle.imageUrl,
                      fallbackIcon: Icons.directions_car_filled_rounded,
                    ),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0x00000000),
                            Color(0x10000000),
                            Color(0x94001716),
                          ],
                          stops: [0, .55, 1],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 12,
                      bottom: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(.18),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: Colors.white.withOpacity(.38),
                          ),
                        ),
                        child: const Text(
                          'SAFARI READY',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9.5,
                            letterSpacing: .5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 13),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vehicle.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: const Color(0xFF17211F),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      if (vehicle.operatorName.trim().isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          vehicle.operatorName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF66716E),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                      const Spacer(),
                      Row(
                        children: [
                          if (details.isNotEmpty)
                            Expanded(
                              child: Text(
                                details.join(' • '),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: const Color(0xFF66716E),
                                ),
                              ),
                            ),
                          const SizedBox(width: 8),
                          Text(
                            '${_usd(vehicle.pricePerDay)}/day',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: const Color(0xFFF46627),
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OfferingSection extends StatelessWidget {
  const _OfferingSection({
    required this.title,
    required this.subtitle,
    required this.emptyText,
    required this.itemCount,
    required this.itemBuilder,
    this.cardHeight = 274,
  });

  final String title;
  final String subtitle;
  final String emptyText;
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final double cardHeight;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSectionHeader(title: title, subtitle: subtitle),
        const SizedBox(height: 14),
        if (itemCount == 0)
          AppStatePanel(
            title: 'Nothing available yet',
            message: emptyText,
            kind: AppStateKind.empty,
          )
        else
          SizedBox(
            height: cardHeight,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: itemCount,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: itemBuilder,
            ),
          ),
      ],
    );
  }
}

class _OfferingCard extends StatelessWidget {
  const _OfferingCard({
    required this.imageUrl,
    required this.fallbackIcon,
    required this.name,
    required this.operatorName,
    this.operatorLogoUrl = '',
    this.providerLabel = 'Offered by',
    required this.detail,
    required this.price,
    required this.onTap,
    this.discoveryRecord,
    this.onProviderTap,
  });

  final String imageUrl;
  final IconData fallbackIcon;
  final String name;
  final String operatorName;
  final String operatorLogoUrl;
  final String providerLabel;
  final String detail;
  final String price;
  final VoidCallback onTap;
  final DiscoveryRecord? discoveryRecord;
  final VoidCallback? onProviderTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SizedBox(
      width:
          (MediaQuery.sizeOf(context).width * .64).clamp(210, 250).toDouble(),
      child: Card(
        clipBehavior: Clip.antiAlias,
        elevation: 1,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: InkWell(
                onTap: onTap,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          _OfferingImage(
                            imageUrl: imageUrl,
                            fallbackIcon: fallbackIcon,
                          ),
                          if (discoveryRecord != null)
                            Positioned(
                              right: 10,
                              top: 10,
                              child: AnimatedBuilder(
                                animation: DiscoveryStore.instance,
                                builder:
                                    (context, _) => AppSaveButton(
                                      saved: DiscoveryStore.instance.isSaved(
                                        discoveryRecord!,
                                      ),
                                      onPressed:
                                          () => DiscoveryStore.instance
                                              .toggleSaved(discoveryRecord!),
                                    ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(13),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          if (onProviderTap == null &&
                              operatorName.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Text(
                              operatorName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                          const SizedBox(height: 5),
                          Text(
                            detail,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            price,
                            style: TextStyle(
                              color: colors.primary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (operatorName.isNotEmpty && onProviderTap != null) ...[
              Divider(height: 1, color: colors.outlineVariant.withOpacity(.55)),
              InkWell(
                onTap: onProviderTap,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 9, 9, 9),
                  child: Row(
                    children: [
                      _ProviderLogo(
                        imageUrl: operatorLogoUrl,
                        operatorName: operatorName,
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              providerLabel,
                              style: Theme.of(
                                context,
                              ).textTheme.labelSmall?.copyWith(
                                color: colors.onSurface.withOpacity(.6),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              operatorName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(
                                context,
                              ).textTheme.labelMedium?.copyWith(
                                color: colors.primary,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 20,
                        color: colors.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ProviderLogo extends StatelessWidget {
  const _ProviderLogo({required this.imageUrl, required this.operatorName});

  final String imageUrl;
  final String operatorName;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final initials =
        operatorName
            .trim()
            .split(RegExp(r'\s+'))
            .where((part) => part.isNotEmpty)
            .take(2)
            .map((part) => part[0].toUpperCase())
            .join();
    final fallback = Container(
      width: 38,
      height: 38,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Text(
        initials,
        style: TextStyle(
          color: colors.onPrimaryContainer,
          fontSize: 14,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
    if (imageUrl.isEmpty) return fallback;

    return Container(
      width: 38,
      height: 38,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Image.network(
        imageUrl,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => fallback,
      ),
    );
  }
}

class _OfferingImage extends StatelessWidget {
  const _OfferingImage({required this.imageUrl, required this.fallbackIcon});

  final String imageUrl;
  final IconData fallbackIcon;

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      width: double.infinity,
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Icon(fallbackIcon, size: 48),
    );
    if (imageUrl.isEmpty) return fallback;
    return Image.network(
      imageUrl,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => fallback,
    );
  }
}

Future<void> _openTour(BuildContext context, OperatorTour tour) async {
  await DiscoveryStore.instance.recordView(DiscoveryRecord.fromTour(tour));
  if (!context.mounted) return;
  return _showTour(context, tour);
}

Future<void> _showTour(BuildContext context, OperatorTour tour) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder:
        (context) => _DetailsSheet(
          imageUrl: tour.imageUrl,
          fallbackIcon: Icons.map_rounded,
          title: tour.name,
          operatorName: tour.operatorName,
          providerLabel: tour.isGuideLed ? 'Guided by' : 'Offered by',
          price: _usd(tour.price),
          facts: [
            '${tour.days} ${tour.days == 1 ? 'day' : 'days'}',
            if (tour.destinationNames.isNotEmpty)
              'Destinations: ${tour.destinationNames.join(', ')}',
            if (tour.activityNames.isNotEmpty)
              'Activities: ${tour.activityNames.join(', ')}',
          ],
          description: tour.overview,
          itinerary: tour.itinerary,
        ),
  );
}

Future<void> _showProvider(BuildContext context, OperatorTour tour) async {
  final member = CommunityMember(
    id: tour.operatorId,
    name: tour.operatorName,
    role: tour.providerRole,
    profilePhoto: tour.operatorLogo,
    location: tour.operatorLocation,
    biography: tour.operatorBiography,
    ratingAverage: tour.operatorRatingAverage,
    ratingCount: tour.operatorRatingCount,
    joinedAt: tour.operatorJoinedAt,
  );
  await DiscoveryStore.instance.recordView(
    DiscoveryRecord.fromProvider(member),
  );
  if (!context.mounted) return;
  Navigator.push<void>(
    context,
    MaterialPageRoute(builder: (_) => ProviderProfilePage(member: member)),
  );
}

Future<void> _showVehicle(BuildContext context, CarHireVehicle vehicle) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder:
        (context) => _DetailsSheet(
          imageUrl: vehicle.imageUrl,
          fallbackIcon: Icons.directions_car_filled_rounded,
          title: vehicle.name,
          operatorName: vehicle.operatorName,
          price: '${_usd(vehicle.pricePerDay)} / day',
          facts: [
            if (vehicle.seats != null) '${vehicle.seats} seats',
            if (vehicle.transmission?.isNotEmpty == true) vehicle.transmission!,
            if (vehicle.fuelType?.isNotEmpty == true) vehicle.fuelType!,
            if (vehicle.amenities.isNotEmpty)
              'Amenities: ${vehicle.amenities.join(', ')}',
          ],
          description: vehicle.description ?? '',
          descriptionTitle: 'About this vehicle',
        ),
  );
}

class _DetailsSheet extends StatelessWidget {
  const _DetailsSheet({
    required this.imageUrl,
    required this.fallbackIcon,
    required this.title,
    required this.operatorName,
    this.providerLabel = 'Offered by',
    required this.price,
    required this.facts,
    required this.description,
    this.itinerary = const [],
    this.descriptionTitle = 'About this tour',
  });

  final String imageUrl;
  final IconData fallbackIcon;
  final String title;
  final String operatorName;
  final String providerLabel;
  final String price;
  final List<String> facts;
  final String description;
  final List<TourItineraryStop> itinerary;
  final String descriptionTitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: .78,
      minChildSize: .48,
      maxChildSize: .94,
      builder:
          (context, controller) => ListView(
            controller: controller,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outline.withOpacity(.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: SizedBox(
                  height: 230,
                  child: _OfferingImage(
                    imageUrl: imageUrl,
                    fallbackIcon: fallbackIcon,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                title.toTitleCase(),
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (operatorName.isNotEmpty) ...[
                const SizedBox(height: 5),
                Text('$providerLabel $operatorName'),
              ],
              const SizedBox(height: 10),
              Text(
                price,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 18),
              ...facts.map(
                (fact) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        size: 18,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(fact)),
                    ],
                  ),
                ),
              ),
              if (itinerary.isNotEmpty) ...[
                const SizedBox(height: 22),
                SafariTrail(stops: itinerary),
              ],
              if (description.trim().isNotEmpty) ...[
                const SizedBox(height: 24),
                Text(
                  descriptionTitle.toTitleCase(),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(description, style: const TextStyle(height: 1.55)),
              ],
            ],
          ),
    );
  }
}

String _usd(double value) {
  final fixed = value.toStringAsFixed(value == value.roundToDouble() ? 0 : 2);
  final parts = fixed.split('.');
  final digits = parts.first;
  final buffer = StringBuffer();
  for (var index = 0; index < digits.length; index++) {
    if (index > 0 && (digits.length - index) % 3 == 0) buffer.write(',');
    buffer.write(digits[index]);
  }
  return 'USD $buffer${parts.length == 2 ? '.${parts[1]}' : ''}';
}
