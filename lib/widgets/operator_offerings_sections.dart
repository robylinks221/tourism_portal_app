import 'package:flutter/material.dart';

import '../models/catalog_item.dart';
import '../models/community.dart';
import '../models/discovery_item.dart';
import '../models/operator_management.dart';
import '../models/safari_mood.dart';
import '../services/catalog_service.dart';
import '../services/discovery_store.dart';
import '../services/operator_offerings_service.dart';
import '../utils/text_case.dart';
import 'app_ui.dart';
import 'provider_discovery_sections.dart';
import 'safari_trail.dart';

class OperatorOfferingsSections extends StatefulWidget {
  const OperatorOfferingsSections({super.key});

  @override
  State<OperatorOfferingsSections> createState() =>
      _OperatorOfferingsSectionsState();
}

class _OperatorOfferingsSectionsState
    extends State<OperatorOfferingsSections> {
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
    CatalogItem? selectedActivity;
    for (final activity in activities) {
      if (activity.id == _selectedActivityId) {
        selectedActivity = activity;
        break;
      }
    }
    final selectedActivityId = selectedActivity?.id;
    final visibleTours = tours.where((tour) {
      return selectedActivityId == null ||
          tour.activityIds.contains(selectedActivityId);
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SafariActivityTabs(
          activities: activities,
          selectedActivityId: selectedActivityId,
          onSelected: (activityId) =>
              setState(() => _selectedActivityId = activityId),
        ),
        const SizedBox(height: 24),
        _TourSection(
          tours: visibleTours,
          selectedActivityName: selectedActivity?.name,
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
            final selectedMood = safariMoodByKey(catalog.moods, selectedMoodKey);
            if (selectedMood != null) {
              return _VehicleSection(vehicles: offerings.vehicles);
            }
            return _buildSections(
              offerings: offerings,
              activities: catalog.activities,
              tours: offerings.tours,
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

class _SafariActivityTabs extends StatelessWidget {
  const _SafariActivityTabs({
    required this.activities,
    required this.selectedActivityId,
    required this.onSelected,
  });

  final List<CatalogItem> activities;
  final int? selectedActivityId;
  final ValueChanged<int?> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final tabs = <({int? id, String label})>[
      (id: null, label: 'All Safaris'),
      ...activities.map<({int? id, String label})>(
        (activity) => (id: activity.id, label: activity.name),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSectionHeader(
          title: 'Safaris by Activity',
          subtitle: activities.isEmpty
              ? 'Published safari activities will appear here.'
              : 'Choose an activity to find matching tours from operators.',
        ),
        const SizedBox(height: 15),
        SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: tabs.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final tab = tabs[index];
              final selected = tab.id == selectedActivityId;
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => onSelected(tab.id),
                  borderRadius: BorderRadius.circular(999),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    decoration: BoxDecoration(
                      color: selected ? colors.primary : colors.surface,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: selected
                            ? colors.primary
                            : colors.outlineVariant.withOpacity(
                                isDark ? .7 : .62,
                              ),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: selected
                              ? colors.primary.withOpacity(isDark ? .3 : .22)
                              : Colors.black.withOpacity(isDark ? .12 : .045),
                          blurRadius: selected ? 14 : 8,
                          offset: Offset(0, selected ? 5 : 3),
                        ),
                      ],
                    ),
                    child: Text(
                      tab.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: selected
                            ? colors.onPrimary
                            : colors.onSurface.withOpacity(.86),
                        fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                      ),
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
    return _OfferingSection(
      title: selectedActivityName == null
          ? selectedMoodTitle == null
              ? 'Safaris from local providers'
              : '$selectedMoodTitle safaris'
          : '$selectedActivityName safaris',
      subtitle: selectedActivityName == null
          ? selectedMoodTitle == null
              ? 'Published tours from operators and professional guides'
              : 'Published tours matched to your selected safari mood'
          : 'Published tours that include $selectedActivityName',
      emptyText: selectedActivityName == null
          ? selectedMoodTitle == null
              ? 'No provider safaris have been published yet.'
              : 'No published safari matches this mood yet.'
          : 'No published safari currently includes $selectedActivityName.',
      cardHeight: 334,
      itemCount: tours.length,
      itemBuilder: (context, index) {
        final tour = tours[index];
        return _OfferingCard(
          discoveryRecord: DiscoveryRecord.fromTour(tour),
          imageUrl: tour.imageUrl,
          fallbackIcon: Icons.map_rounded,
          name: tour.name,
          operatorName: tour.operatorName,
          operatorLogoUrl: tour.operatorLogoUrl,
          providerLabel: tour.isGuideLed ? 'Guided by' : 'Offered by',
          detail: [
            if (tour.isGuideLed) 'Guide-led',
            '${tour.days} ${tour.days == 1 ? 'day' : 'days'}',
          ].join(' • '),
          price: _usd(tour.price),
          onTap: () => _openTour(context, tour),
          onProviderTap: tour.operatorId > 0
              ? () => _showProvider(context, tour)
              : null,
        );
      },
    );
  }
}

class _VehicleSection extends StatelessWidget {
  const _VehicleSection({required this.vehicles});

  final List<CarHireVehicle> vehicles;

  @override
  Widget build(BuildContext context) {
    return _OfferingSection(
      title: 'Car hire',
      subtitle: 'Available safari vehicles from tour operators',
      emptyText: 'No car hire vehicles are available yet.',
      itemCount: vehicles.length,
      itemBuilder: (context, index) {
        final vehicle = vehicles[index];
        final details = [
          if (vehicle.seats != null) '${vehicle.seats} seats',
          if (vehicle.transmission?.isNotEmpty == true) vehicle.transmission!,
        ];
        return _OfferingCard(
          imageUrl: vehicle.imageUrl,
          fallbackIcon: Icons.directions_car_filled_rounded,
          name: vehicle.name,
          operatorName: vehicle.operatorName,
          detail: details.isEmpty ? 'Safari vehicle' : details.join(' • '),
          price: '${_usd(vehicle.pricePerDay)} / day',
          onTap: () => _showVehicle(context, vehicle),
        );
      },
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
        AppSectionHeader(
          title: title,
          subtitle: subtitle,
        ),
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
      width: (MediaQuery.sizeOf(context).width * .64).clamp(210, 250).toDouble(),
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
                                builder: (context, _) => AppSaveButton(
                                  saved: DiscoveryStore.instance
                                      .isSaved(discoveryRecord!),
                                  onPressed: () => DiscoveryStore.instance
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
              Divider(
                height: 1,
                color: colors.outlineVariant.withOpacity(.55),
              ),
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
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: colors.onSurface.withOpacity(.6),
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            Text(
                              operatorName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelMedium
                                  ?.copyWith(
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
    final initials = operatorName
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
    builder: (context) => _DetailsSheet(
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
    MaterialPageRoute(
      builder: (_) => ProviderProfilePage(member: member),
    ),
  );
}

Future<void> _showVehicle(BuildContext context, CarHireVehicle vehicle) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => _DetailsSheet(
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
      builder: (context, controller) => ListView(
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
