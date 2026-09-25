import 'package:flutter/material.dart';

import '../models/catalog_item.dart';
import '../models/operator_management.dart';
import '../models/safari_mood.dart';
import 'activity_details_page.dart';
import 'destination_details_page.dart';
import 'tour_details_page.dart';

enum ExperienceItemsType { tours, activities, destinations }

class ExperienceItemsPage extends StatefulWidget {
  const ExperienceItemsPage({
    super.key,
    required this.mood,
    required this.type,
    required this.tours,
    required this.activities,
    required this.destinations,
  });

  final SafariMood mood;
  final ExperienceItemsType type;
  final List<OperatorTour> tours;
  final List<CatalogItem> activities;
  final List<CatalogItem> destinations;

  @override
  State<ExperienceItemsPage> createState() => _ExperienceItemsPageState();
}

class _ExperienceItemsPageState extends State<ExperienceItemsPage> {
  static const Color _primary = Color(0xFF165B5D);
  static const Color _background = Color(0xFFF4EEE1);
  static const Color _ink = Color(0xFF17211F);

  final TextEditingController _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  String get _title {
    switch (widget.type) {
      case ExperienceItemsType.activities:
        return 'All Activities';
      case ExperienceItemsType.destinations:
        return 'All Destinations';
      case ExperienceItemsType.tours:
        return 'All Tours';
    }
  }

  String get _subtitle {
    switch (widget.type) {
      case ExperienceItemsType.activities:
        return 'Safari activities matched to ${widget.mood.title}.';
      case ExperienceItemsType.destinations:
        return 'Destinations matched to ${widget.mood.title}.';
      case ExperienceItemsType.tours:
        return 'Published tours matched to ${widget.mood.title}.';
    }
  }

  int get _totalCount {
    switch (widget.type) {
      case ExperienceItemsType.activities:
        return widget.activities.length;
      case ExperienceItemsType.destinations:
        return widget.destinations.length;
      case ExperienceItemsType.tours:
        return widget.tours.length;
    }
  }

  Future<void> _openTour(OperatorTour tour) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(builder: (_) => TourDetailsPage(tour: tour)),
    );
  }

  Future<void> _openCatalogItem(CatalogItem item) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder:
            (_) =>
                item.isActivity
                    ? ActivityDetailsPage(item: item)
                    : DestinationDetailsPage(item: item),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        surfaceTintColor: Colors.transparent,
        title: Text(
          _title,
          style: const TextStyle(color: _ink, fontWeight: FontWeight.w900),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.mood.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: _primary,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -.4,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _subtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: _ink.withValues(alpha: .60),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: _primary.withValues(alpha: .10),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: .05),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _search,
                      onChanged: (_) => setState(() {}),
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        hintText: 'Search $_title',
                        border: InputBorder.none,
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: _primary,
                        ),
                        suffixIcon:
                            _search.text.isEmpty
                                ? null
                                : IconButton(
                                  onPressed: () {
                                    _search.clear();
                                    setState(() {});
                                  },
                                  icon: const Icon(Icons.close_rounded),
                                ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 15,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '$_totalCount ${_totalCount == 1 ? 'result' : 'results'}',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: _primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: _buildList(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildList(BuildContext context) {
    final query = _search.text.trim().toLowerCase();

    if (widget.type == ExperienceItemsType.tours) {
      final items =
          widget.tours.where((tour) {
            final searchable =
                [
                  tour.name,
                  tour.overview,
                  tour.operatorName,
                  ...tour.destinationNames,
                  ...tour.activityNames,
                ].join(' ').toLowerCase();

            return query.isEmpty || searchable.contains(query);
          }).toList();

      if (items.isEmpty) {
        return const _EmptyResults(message: 'No matching tours found.');
      }

      return ListView.separated(
        padding: const EdgeInsets.fromLTRB(18, 4, 18, 32),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final tour = items[index];

          return _TourResultCard(tour: tour, onTap: () => _openTour(tour));
        },
      );
    }

    final source =
        widget.type == ExperienceItemsType.activities
            ? widget.activities
            : widget.destinations;

    final items =
        source.where((item) {
          final searchable =
              [
                item.name,
                item.tagline ?? '',
                item.location ?? '',
                item.country ?? '',
              ].join(' ').toLowerCase();

          return query.isEmpty || searchable.contains(query);
        }).toList();

    if (items.isEmpty) {
      return _EmptyResults(
        message:
            widget.type == ExperienceItemsType.activities
                ? 'No matching activities found.'
                : 'No matching destinations found.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 32),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = items[index];

        return _CatalogResultCard(
          item: item,
          isActivity: widget.type == ExperienceItemsType.activities,
          onTap: () => _openCatalogItem(item),
        );
      },
    );
  }
}

class _TourResultCard extends StatelessWidget {
  const _TourResultCard({required this.tour, required this.onTap});

  final OperatorTour tour;
  final VoidCallback onTap;

  static const Color _primary = Color(0xFF165B5D);
  static const Color _secondary = Color(0xFFF46627);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final destination =
        tour.destinationNames.isEmpty
            ? 'East Africa'
            : tour.destinationNames.first;

    return Material(
      elevation: 10,
      shadowColor: Colors.black.withValues(alpha: .16),
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 132,
          child: Row(
            children: [
              SizedBox(
                width: 120,
                height: double.infinity,
                child: _BorderedImage(
                  imageUrl: tour.imageUrl,
                  fallbackIcon: Icons.landscape_outlined,
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 13, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tour.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          height: 1.18,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            tour.isGuideLed
                                ? Icons.badge_outlined
                                : Icons.business_outlined,
                            size: 14,
                            color: _primary,
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              '${tour.isGuideLed ? 'Guided by' : 'Offered by'} '
                              '${tour.operatorName.isEmpty ? (tour.isGuideLed ? 'Local Safari Guide' : 'Safari Operator') : tour.operatorName}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: _primary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: _primary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              destination,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: const Color(
                                  0xFF17211F,
                                ).withValues(alpha: .58),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          const Icon(
                            Icons.schedule_rounded,
                            size: 14,
                            color: _secondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${tour.days} ${tour.days == 1 ? 'day' : 'days'}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            _price(tour),
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: _primary,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(right: 10),
                child: Icon(Icons.chevron_right_rounded, color: _primary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CatalogResultCard extends StatelessWidget {
  const _CatalogResultCard({
    required this.item,
    required this.isActivity,
    required this.onTap,
  });

  final CatalogItem item;
  final bool isActivity;
  final VoidCallback onTap;

  static const Color _primary = Color(0xFF165B5D);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final relatedNames =
        isActivity
            ? item.destinations
                .map((destination) => destination.name.trim())
                .where((name) => name.isNotEmpty)
                .toList()
            : item.activities
                .map((activity) => activity.name.trim())
                .where((name) => name.isNotEmpty)
                .toList();

    final fallbackSubtitle =
        isActivity
            ? (item.tagline ?? '')
            : [item.location, item.country]
                .where((value) => value != null && value.trim().isNotEmpty)
                .join(', ');

    final subtitle =
        relatedNames.isEmpty ? fallbackSubtitle : relatedNames.first;
    final moreCount = relatedNames.length > 1 ? relatedNames.length - 1 : 0;

    return Material(
      elevation: 10,
      shadowColor: Colors.black.withValues(alpha: .15),
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 116,
          child: Row(
            children: [
              SizedBox(
                width: 112,
                height: double.infinity,
                child: _BorderedImage(
                  imageUrl: item.imageUrl,
                  fallbackIcon:
                      isActivity
                          ? Icons.explore_outlined
                          : Icons.landscape_outlined,
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          height: 1.17,
                        ),
                      ),
                      const Spacer(),
                      if (subtitle.trim().isNotEmpty)
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              size: 14,
                              color: _primary,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    subtitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: const Color(
                                        0xFF17211F,
                                      ).withValues(alpha: .58),
                                    ),
                                  ),
                                  if (moreCount > 0) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      isActivity
                                          ? '+$moreCount more destinations'
                                          : '+$moreCount more Activities',
                                      maxLines: 1,
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(
                                            color: _primary,
                                            fontWeight: FontWeight.w800,
                                          ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(right: 10),
                child: Icon(Icons.chevron_right_rounded, color: _primary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BorderedImage extends StatelessWidget {
  const _BorderedImage({required this.imageUrl, required this.fallbackIcon});

  final String imageUrl;
  final IconData fallbackIcon;

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      color: const Color(0xFFE4EFEC),
      alignment: Alignment.center,
      child: Icon(fallbackIcon, color: const Color(0xFF165B5D), size: 32),
    );

    final image =
        imageUrl.isEmpty
            ? fallback
            : Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => fallback,
            );

    return Padding(
      padding: const EdgeInsets.all(10),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .08),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(borderRadius: BorderRadius.circular(16), child: image),
      ),
    );
  }
}

class _EmptyResults extends StatelessWidget {
  const _EmptyResults({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.search_off_rounded,
              color: Color(0xFF165B5D),
              size: 46,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

String _price(OperatorTour tour) {
  final amount =
      tour.price == tour.price.roundToDouble()
          ? tour.price.toStringAsFixed(0)
          : tour.price.toStringAsFixed(2);

  return '${tour.currency.isEmpty ? 'USD' : tour.currency} $amount';
}
