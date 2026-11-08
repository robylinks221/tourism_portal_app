import 'package:flutter/material.dart';

import '../models/catalog_item.dart';
import '../models/discovery_item.dart';
import '../models/safari_mood.dart';
import '../pages/activity_details_page.dart';
import '../pages/destination_details_page.dart';
import '../pages/safari_mood_page.dart';
import '../services/catalog_service.dart';
import '../services/discovery_store.dart';
import 'app_ui.dart';
import 'premium_navigation.dart';
import 'premium_states.dart';

class CatalogHomeSections extends StatefulWidget {
  const CatalogHomeSections({
    super.key,
    this.countryName,
    this.countryMoodIds = const [],
    this.countryActivityIds = const [],
    this.countryDestinationIds = const [],
  });

  final String? countryName;
  final List<int> countryMoodIds;
  final List<int> countryActivityIds;
  final List<int> countryDestinationIds;

  @override
  State<CatalogHomeSections> createState() => _CatalogHomeSectionsState();
}

class _CatalogHomeSectionsState extends State<CatalogHomeSections> {
  late Future<TourismCatalog> _catalog;

  @override
  void initState() {
    super.initState();

    // Experiences open their own full page.
    // Clear any old selected Safari Mood state so the legacy
    // in-page mood panel can never reappear.
    SafariMoodController.instance.clear();

    _catalog = CatalogService.instance.fetchCatalog();
  }

  void _retry() {
    setState(() {
      _catalog = CatalogService.instance.fetchCatalog();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<TourismCatalog>(
      future: _catalog,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const AppDiscoverySkeleton();
        }

        if (snapshot.hasError) {
          return AppStatePanel(
            title: 'Safari discovery could not be loaded',
            message:
                'Check your connection to reload experiences and destinations.',
            kind: AppStateKind.offline,
            onRetry: _retry,
          );
        }

        final rawCatalog = snapshot.data!;
        final hasCountry = widget.countryName?.trim().isNotEmpty == true;

        final destinations = !hasCountry
            ? rawCatalog.destinations
            : rawCatalog.destinations
                .where(
                  (item) => widget.countryDestinationIds.contains(item.id),
                )
                .toList();

        final activities = !hasCountry
            ? rawCatalog.activities
            : rawCatalog.activities
                .where(
                  (item) => widget.countryActivityIds.contains(item.id),
                )
                .toList();

        final catalog = TourismCatalog(
          moods: rawCatalog.moods,
          activities: activities,
          destinations: destinations,
        );
        final moods =
            widget.countryName == null || widget.countryName!.trim().isEmpty
                ? catalog.moods
                : catalog.moods
                    .where((mood) => widget.countryMoodIds.contains(mood.id))
                    .toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ============================================================
            // CHOOSE YOUR EXPERIENCE
            // LUXURY EDITORIAL CARDS
            // ============================================================

            const AppSectionHeader(
              title: 'Choose Your Experience',
              subtitle: 'Start with how you want the journey to feel.',
            ),

            const SizedBox(height: 16),

            if (moods.isEmpty)
              _ExperienceEmptyState()
            else
              SizedBox(
                height: 265,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  clipBehavior: Clip.none,
                  itemCount: moods.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 13),
                  itemBuilder: (context, index) {
                    final mood = moods[index];

                    return _ExperienceCard(
                      mood: mood,
                      imageUrl: _experienceImageUrl(
                        catalog,
                        mood.key,
                      ),
                      onTap: () => _openExperiencePage(
                        context,
                        mood,
                      ),
                    );
                  },
                ),
              ),

            const SizedBox(height: 30),

            // ============================================================
            // EXPLORE BY ACTIVITY
            // UNCHANGED
            // ============================================================

            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Expanded(
                  child: AppSectionHeader(
                    title: 'Explore by Activity',
                    subtitle: 'Find a safari around what you love doing.',
                  ),
                ),
                if (catalog.activities.isNotEmpty)
                  TextButton.icon(
                    onPressed: () {
                      Navigator.of(context).push<void>(
                        premiumPageRoute(
                          (_) => _AllActivitiesPage(
                            activities: catalog.activities,
                          ),
                        ),
                      );
                    },
                    iconAlignment: IconAlignment.end,
                    icon: const Icon(Icons.chevron_right_rounded, size: 20),
                    label: const Text(
                      'View All',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF165B5D),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 5,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 14),

            if (catalog.activities.isEmpty)
              const _CatalogEmptyResult(
                icon: Icons.hiking_rounded,
                message: 'No published activities are available yet.',
              )
            else
              SizedBox(
                height: 190,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  clipBehavior: Clip.none,
                  itemCount: catalog.activities.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    return _ActivityCard(
                      item: catalog.activities[index],
                    );
                  },
                ),
              ),

            const SizedBox(height: 30),

            // ============================================================
            // EXPLORE DESTINATIONS
            // REFINED COMPACT DESTINATION CARDS
            // ============================================================

            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Expanded(
                  child: AppSectionHeader(
                    title: 'Explore Destinations',
                    subtitle: 'Beautiful places across East Africa',
                  ),
                ),
                if (catalog.destinations.isNotEmpty)
                  TextButton.icon(
                    onPressed: () {
                      Navigator.of(context).push<void>(
                        premiumPageRoute(
                          (_) => _AllDestinationsPage(
                            destinations: catalog.destinations,
                            activities: catalog.activities,
                          ),
                        ),
                      );
                    },
                    iconAlignment: IconAlignment.end,
                    icon: const Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                    ),
                    label: const Text(
                      'View All',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF165B5D),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 5,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 14),

            if (catalog.destinations.isEmpty)
              const _CatalogEmptyResult(
                icon: Icons.landscape_rounded,
                message: 'No published destinations are available yet.',
              )
            else
              SizedBox(
                height: 222,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  clipBehavior: Clip.none,
                  padding: const EdgeInsets.only(
                    left: 1,
                    right: 12,
                  ),
                  itemCount: catalog.destinations.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    return _DestinationCard(
                      item: catalog.destinations[index],
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }

  Future<void> _openExperiencePage(
    BuildContext context,
    SafariMood mood,
  ) async {
    SafariMoodController.instance.clear();

    await Navigator.of(context).push<void>(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 420),
        reverseTransitionDuration: const Duration(milliseconds: 300),
        pageBuilder:
            (context, animation, secondaryAnimation) =>
                SafariMoodPage(mood: mood),
        transitionsBuilder: (
          context,
          animation,
          secondaryAnimation,
          child,
        ) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );

          return FadeTransition(
            opacity: curved,
            child: ScaleTransition(
              scale: Tween<double>(
                begin: .975,
                end: 1,
              ).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );
  }

  String _experienceImageUrl(
    TourismCatalog catalog,
    String moodKey,
  ) {
    final mood = safariMoodByKey(
      catalog.moods,
      moodKey,
    );

    if (mood?.imageUrl.isNotEmpty == true) {
      return mood!.imageUrl;
    }

    for (final destination in catalog.destinations) {
      if (destination.moods.contains(moodKey) &&
          destination.imageUrl.isNotEmpty) {
        return destination.imageUrl;
      }
    }

    for (final activity in catalog.activities) {
      if (activity.moods.contains(moodKey) &&
          activity.imageUrl.isNotEmpty) {
        return activity.imageUrl;
      }
    }

    return '';
  }
}

// ============================================================================
// EXPERIENCE CARD
// UNCHANGED
// ============================================================================

class _ExperienceCard extends StatelessWidget {
  const _ExperienceCard({
    required this.mood,
    required this.imageUrl,
    required this.onTap,
  });

  final SafariMood mood;
  final String imageUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final visual = _ExperienceVisual.fromMood(mood);
    return SizedBox(
      width: 205,
      child: Material(
        color: Colors.transparent,
        elevation: 7,
        shadowColor: Colors.black.withValues(alpha: .16),
        borderRadius: BorderRadius.circular(25),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (imageUrl.isNotEmpty)
                Hero(
                  tag: 'safari-mood-${mood.id}',
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _fallback(visual),
                  ),
                )
              else
                _fallback(visual),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: [0, .35, .67, 1],
                    colors: [
                      Color(0x08000000),
                      Color(0x14000000),
                      Color(0x8A000000),
                      Color(0xF0000000),
                    ],
                  ),
                ),
              ),
              // Subtle visual accent; the entire card remains the navigation target.
              Positioned(
                top: 13,
                right: 13,
                child: Container(
                  width: 33,
                  height: 33,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: .18),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: .25),
                    ),
                  ),
                  child: Icon(
                    Icons.favorite_border_rounded,
                    color: Colors.white.withValues(alpha: .80),
                    size: 18,
                  ),
                ),
              ),
              Positioned(
                left: 17,
                right: 17,
                bottom: 17,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      mood.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        height: 1.12,
                        letterSpacing: -.3,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      mood.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: .85),
                        fontSize: 11,
                        height: 1.32,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fallback(_ExperienceVisual visual) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: visual.colors,
        ),
      ),
    );
  }
}

// ============================================================================
// EXPERIENCE EMPTY STATE
// ============================================================================

class _ExperienceEmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withValues(alpha: .45),
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Text(
        'Experiences are being prepared. Explore the destinations below.',
      ),
    );
  }
}


class _AllActivitiesPage extends StatefulWidget {
  const _AllActivitiesPage({required this.activities});

  final List<CatalogItem> activities;

  @override
  State<_AllActivitiesPage> createState() => _AllActivitiesPageState();
}

class _AllActivitiesPageState extends State<_AllActivitiesPage> {
  static const _primary = Color(0xFF165B5D);
  static const _background = Color(0xFFF4EEE1);

  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<CatalogItem> get _items {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return widget.activities;

    return widget.activities.where((item) {
      final haystack = <String>[
        item.name,
        item.tagline ?? '',
        item.description,
        item.location ?? '',
        item.country ?? '',
        item.difficulty ?? '',
        item.bestMonthsToVisit ?? '',
        item.recommendedTripLength ?? '',
        ...item.moods,
      ].join(' ').toLowerCase();

      return haystack.contains(q);
    }).toList();
  }

  Future<void> _open(BuildContext context, CatalogItem item) async {
    final record = DiscoveryRecord.fromCatalog(item);
    await DiscoveryStore.instance.recordView(record);

    try {
      final detail = await CatalogService.instance.fetchActivity(item.slug);
      if (!context.mounted) return;

      Navigator.push<void>(
        context,
        premiumPageRoute(
          (_) => ActivityDetailsPage(item: detail),
        ),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This activity could not be loaded. Please try again.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = _items;

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'All Activities',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 10),
            child: Container(
              height: 54,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: _primary.withValues(alpha: .10)),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _query = value),
                decoration: InputDecoration(
                  hintText: 'Search safari activities',
                  border: InputBorder.none,
                  prefixIcon: const Icon(Icons.search_rounded, color: _primary),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _query = '');
                          },
                          icon: const Icon(Icons.close_rounded),
                        ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 2, 20, 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${items.length} ${items.length == 1 ? 'activity' : 'activities'}',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: _primary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          Expanded(
            child: items.isEmpty
                ? const Center(child: Text('No matching activities found.'))
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 30),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = items[index];

                      return Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        clipBehavior: Clip.antiAlias,
                        elevation: 4,
                        shadowColor: Colors.black.withValues(alpha: .09),
                        child: InkWell(
                          onTap: () => _open(context, item),
                          child: SizedBox(
                            height: 142,
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 126,
                                  height: double.infinity,
                                  child: Padding(
                                    padding: const EdgeInsets.all(9),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(16),
                                      child: item.imageUrl.isEmpty
                                          ? Container(
                                              color: _primary.withValues(alpha: .08),
                                              child: const Icon(
                                                Icons.hiking_rounded,
                                                color: _primary,
                                              ),
                                            )
                                          : Image.network(
                                              item.imageUrl,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) => Container(
                                                color: _primary.withValues(alpha: .08),
                                                child: const Icon(
                                                  Icons.hiking_rounded,
                                                  color: _primary,
                                                ),
                                              ),
                                            ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(12, 13, 8, 12),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.name,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: theme.textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.w900,
                                            height: 1.12,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        if ((item.tagline ?? '').trim().isNotEmpty)
                                          Text(
                                            item.tagline!.trim(),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: theme.textTheme.bodySmall?.copyWith(
                                              color: theme.colorScheme.onSurfaceVariant,
                                              height: 1.25,
                                            ),
                                          ),
                                        const Spacer(),
                                        Row(
                                          children: [
                                            if ((item.difficulty ?? '').trim().isNotEmpty)
                                              Text(
                                                item.difficulty!.trim(),
                                                style: theme.textTheme.labelSmall?.copyWith(
                                                  color: _primary,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                            const Spacer(),
                                            const Icon(
                                              Icons.chevron_right_rounded,
                                              color: _primary,
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
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// ACTIVITY CARD
// UNCHANGED
// ============================================================================

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({
    required this.item,
  });

  final CatalogItem item;

  static const Color _primary = Color(0xFF165B5D);
  static const Color _secondary = Color(0xFFF46627);

  @override
  Widget build(BuildContext context) {
    final record = DiscoveryRecord.fromCatalog(item);
    final screenWidth = MediaQuery.sizeOf(context).width;

    final cardWidth =
        (screenWidth * .39).clamp(142.0, 172.0).toDouble();

    return SizedBox(
      width: cardWidth,
      child: Material(
        elevation: 6,
        shadowColor: Colors.black.withValues(alpha: .13),
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _openActivity(
            context,
            record,
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Hero(
                tag: catalogHeroTag(
                  item.type,
                  item.id,
                ),
                child: item.imageUrl.isEmpty
                    ? Container(
                        color: _primary.withValues(alpha: .12),
                        child: const Center(
                          child: Icon(
                            Icons.hiking_rounded,
                            color: _primary,
                            size: 42,
                          ),
                        ),
                      )
                    : Image.network(
                        item.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) {
                          return Container(
                            color: _primary.withValues(alpha: .12),
                            child: const Center(
                              child: Icon(
                                Icons.hiking_rounded,
                                color: _primary,
                                size: 42,
                              ),
                            ),
                          );
                        },
                      ),
              ),

              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x05000000),
                      Color(0x20000000),
                      Color(0xD9000000),
                    ],
                    stops: [
                      0,
                      .48,
                      1,
                    ],
                  ),
                ),
              ),

              Positioned(
                right: 9,
                top: 9,
                child: AnimatedBuilder(
                  animation: DiscoveryStore.instance,
                  builder: (context, _) {
                    return _ActivitySaveButton(
                      saved: DiscoveryStore.instance.isSaved(record),
                      onPressed: () {
                        DiscoveryStore.instance.toggleSaved(record);
                      },
                    );
                  },
                ),
              ),

              Positioned(
                left: 13,
                right: 13,
                bottom: 14,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 24,
                      height: 3,
                      decoration: BoxDecoration(
                        color: _secondary,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      item.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        height: 1.08,
                        letterSpacing: -.25,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openActivity(
    BuildContext context,
    DiscoveryRecord record,
  ) async {
    await DiscoveryStore.instance.recordView(record);

    try {
      final detail =
          await CatalogService.instance.fetchActivity(item.slug);

      if (!context.mounted) {
        return;
      }

      Navigator.push(
        context,
        premiumPageRoute(
          (_) => ActivityDetailsPage(
            item: detail,
          ),
        ),
      );
    } catch (_) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'This activity could not be loaded. Please try again.',
          ),
        ),
      );
    }
  }
}

// ============================================================================
// ACTIVITY SAVE BUTTON
// ============================================================================

class _ActivitySaveButton extends StatelessWidget {
  const _ActivitySaveButton({
    required this.saved,
    required this.onPressed,
  });

  final bool saved;
  final VoidCallback onPressed;

  static const Color _secondary = Color(0xFFF46627);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: .93),
      shape: const CircleBorder(),
      elevation: 2,
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 38,
          height: 38,
          child: Icon(
            saved
                ? Icons.favorite_rounded
                : Icons.favorite_border_rounded,
            color: saved
                ? _secondary
                : const Color(0xFF263532),
            size: 21,
          ),
        ),
      ),
    );
  }
}


class _AllDestinationsPage extends StatefulWidget {
  const _AllDestinationsPage({
    required this.destinations,
    required this.activities,
  });

  final List<CatalogItem> destinations;
  final List<CatalogItem> activities;

  @override
  State<_AllDestinationsPage> createState() =>
      _AllDestinationsPageState();
}

class _AllDestinationsPageState extends State<_AllDestinationsPage> {
  static const Color _primary = Color(0xFF165B5D);
  static const Color _secondary = Color(0xFFF46627);
  static const Color _background = Color(0xFFF4EEE1);

  final TextEditingController _searchController = TextEditingController();

  String _query = '';
  String _country = 'All';
  int? _activityId;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<String> get _countries {
    final values = widget.destinations
        .map((item) => item.country?.trim() ?? '')
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    return ['All', ...values];
  }

  bool _matchesActivity(CatalogItem destination) {
    if (_activityId == null) return true;

    if (destination.activities.any((item) => item.id == _activityId)) {
      return true;
    }

    for (final activity in widget.activities) {
      if (activity.id == _activityId &&
          activity.destinationIds.contains(destination.id)) {
        return true;
      }
    }

    return false;
  }

  List<CatalogItem> get _filteredDestinations {
    final query = _query.trim().toLowerCase();

    return widget.destinations.where((item) {
      if (_country != 'All' &&
          (item.country ?? '').trim().toLowerCase() !=
              _country.toLowerCase()) {
        return false;
      }

      if (!_matchesActivity(item)) {
        return false;
      }

      if (query.isEmpty) return true;

      final activityNames = item.activities.map((activity) => activity.name);

      final searchable = <String>[
        item.name,
        item.tagline ?? '',
        item.description,
        item.location ?? '',
        item.country ?? '',
        item.bestMonthsToVisit ?? '',
        item.recommendedTripLength ?? '',
        item.weatherSummary ?? '',
        item.difficulty ?? '',
        ...item.moods,
        ...activityNames,
      ].join(' ').toLowerCase();

      return searchable.contains(query);
    }).toList();
  }

  void _resetFilters() {
    _searchController.clear();
    setState(() {
      _query = '';
      _country = 'All';
      _activityId = null;
    });
  }

  Future<void> _openDestination(
    BuildContext context,
    CatalogItem item,
  ) async {
    final record = DiscoveryRecord.fromCatalog(item);
    await DiscoveryStore.instance.recordView(record);

    try {
      final detail =
          await CatalogService.instance.fetchDestination(item.slug);

      if (!context.mounted) return;

      Navigator.push<void>(
        context,
        premiumPageRoute(
          (_) => DestinationDetailsPage(item: detail),
        ),
      );
    } catch (_) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'This destination could not be loaded. Please try again.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final destinations = _filteredDestinations;
    final hasFilters =
        _query.isNotEmpty || _country != 'All' || _activityId != null;

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'All Destinations',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 10),
              child: Column(
                children: [
                  Container(
                    height: 54,
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
                      controller: _searchController,
                      onChanged: (value) {
                        setState(() => _query = value);
                      },
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        hintText:
                            'Search destination, activity, country or experience',
                        border: InputBorder.none,
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: _primary,
                        ),
                        suffixIcon: _query.isEmpty
                            ? null
                            : IconButton(
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _query = '');
                                },
                                icon: const Icon(Icons.close_rounded),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // COUNTRY FILTER
                  SizedBox(
                    height: 39,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _countries.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(width: 7),
                      itemBuilder: (context, index) {
                        final country = _countries[index];
                        final selected = _country == country;

                        return ChoiceChip(
                          label: Text(country),
                          selected: selected,
                          onSelected: (_) {
                            setState(() => _country = country);
                          },
                          selectedColor: _primary,
                          backgroundColor: Colors.white,
                          side: BorderSide(
                            color: selected
                                ? _primary
                                : _primary.withValues(alpha: .10),
                          ),
                          shape: const StadiumBorder(),
                          labelStyle: TextStyle(
                            color: selected
                                ? Colors.white
                                : const Color(0xFF394541),
                            fontWeight: FontWeight.w800,
                          ),
                        );
                      },
                    ),
                  ),

                  if (widget.activities.isNotEmpty) ...[
                    const SizedBox(height: 9),

                    // ACTIVITY FILTER
                    SizedBox(
                      height: 39,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: widget.activities.length + 1,
                        separatorBuilder: (_, __) =>
                            const SizedBox(width: 7),
                        itemBuilder: (context, index) {
                          final isAll = index == 0;
                          final activity =
                              isAll ? null : widget.activities[index - 1];
                          final selected = isAll
                              ? _activityId == null
                              : _activityId == activity!.id;

                          return ChoiceChip(
                            label: Text(
                              isAll ? 'All Activities' : activity!.name,
                            ),
                            selected: selected,
                            onSelected: (_) {
                              setState(() {
                                _activityId =
                                    isAll ? null : activity!.id;
                              });
                            },
                            selectedColor:
                                _secondary.withValues(alpha: .14),
                            backgroundColor: Colors.white,
                            side: BorderSide(
                              color: selected
                                  ? _secondary.withValues(alpha: .28)
                                  : _primary.withValues(alpha: .08),
                            ),
                            shape: const StadiumBorder(),
                            labelStyle: TextStyle(
                              color: selected
                                  ? _secondary
                                  : const Color(0xFF394541),
                              fontWeight: FontWeight.w800,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 2, 20, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${destinations.length} '
                      '${destinations.length == 1 ? 'destination' : 'destinations'}',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: _primary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  if (hasFilters)
                    TextButton(
                      onPressed: _resetFilters,
                      child: const Text(
                        'Reset filters',
                        style: TextStyle(
                          color: _secondary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            Expanded(
              child: destinations.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(28),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.travel_explore_rounded,
                              color: _primary,
                              size: 44,
                            ),
                            SizedBox(height: 10),
                            Text(
                              'No matching destinations',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 17,
                              ),
                            ),
                            SizedBox(height: 5),
                            Text(
                              'Try another activity, country or search.',
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(
                        18,
                        0,
                        18,
                        30,
                      ),
                      itemCount: destinations.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = destinations[index];

                        return Material(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          clipBehavior: Clip.antiAlias,
                          elevation: 4,
                          shadowColor:
                              Colors.black.withValues(alpha: .09),
                          child: InkWell(
                            onTap: () =>
                                _openDestination(context, item),
                            child: SizedBox(
                              height: 142,
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 126,
                                    height: double.infinity,
                                    child: Padding(
                                      padding: const EdgeInsets.all(9),
                                      child: ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(16),
                                        child: item.imageUrl.isEmpty
                                            ? Container(
                                                color: _primary
                                                    .withValues(alpha: .08),
                                                child: const Icon(
                                                  Icons.landscape_rounded,
                                                  color: _primary,
                                                ),
                                              )
                                            : Image.network(
                                                item.imageUrl,
                                                fit: BoxFit.cover,
                                                errorBuilder:
                                                    (_, __, ___) =>
                                                        Container(
                                                  color: _primary
                                                      .withValues(alpha: .08),
                                                  child: const Icon(
                                                    Icons.landscape_rounded,
                                                    color: _primary,
                                                  ),
                                                ),
                                              ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Padding(
                                      padding:
                                          const EdgeInsets.fromLTRB(
                                        12,
                                        13,
                                        8,
                                        12,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.name,
                                            maxLines: 2,
                                            overflow:
                                                TextOverflow.ellipsis,
                                            style: theme
                                                .textTheme.titleMedium
                                                ?.copyWith(
                                              fontWeight:
                                                  FontWeight.w900,
                                              height: 1.12,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            <String>[
                                              if ((item.location ?? '')
                                                  .trim()
                                                  .isNotEmpty)
                                                item.location!.trim(),
                                              if ((item.country ?? '')
                                                  .trim()
                                                  .isNotEmpty)
                                                item.country!.trim(),
                                            ].join(', '),
                                            maxLines: 1,
                                            overflow:
                                                TextOverflow.ellipsis,
                                            style: theme
                                                .textTheme.bodySmall
                                                ?.copyWith(
                                              color: theme.colorScheme
                                                  .onSurfaceVariant,
                                            ),
                                          ),
                                          const Spacer(),
                                          if (item.activities.isNotEmpty)
                                            Text(
                                              item.activities
                                                  .take(2)
                                                  .map(
                                                    (activity) =>
                                                        activity.name,
                                                  )
                                                  .join(' • '),
                                              maxLines: 1,
                                              overflow:
                                                  TextOverflow.ellipsis,
                                              style: theme
                                                  .textTheme.labelSmall
                                                  ?.copyWith(
                                                color: _primary,
                                                fontWeight:
                                                    FontWeight.w800,
                                              ),
                                            )
                                          else if ((item.tagline ?? '')
                                              .trim()
                                              .isNotEmpty)
                                            Text(
                                              item.tagline!.trim(),
                                              maxLines: 1,
                                              overflow:
                                                  TextOverflow.ellipsis,
                                              style: theme
                                                  .textTheme.bodySmall,
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const Padding(
                                    padding:
                                        EdgeInsets.only(right: 10),
                                    child: Icon(
                                      Icons.chevron_right_rounded,
                                      color: _primary,
                                    ),
                                  ),
                                ],
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
    );
  }
}

// ============================================================================
// DESTINATION CARD
// NEW CLEANER DESIGN
// ============================================================================

class _DestinationCard extends StatelessWidget {
  const _DestinationCard({
    required this.item,
  });

  final CatalogItem item;

  static const Color _primary = Color(0xFF165B5D);
  static const Color _secondary = Color(0xFFF46627);

  @override
  Widget build(BuildContext context) {
    final record = DiscoveryRecord.fromCatalog(item);
    final screenWidth = MediaQuery.sizeOf(context).width;

    final cardWidth =
        (screenWidth * .50).clamp(178.0, 205.0).toDouble();

    final theme = Theme.of(context);

    return SizedBox(
      width: cardWidth,
      child: Material(
        elevation: 5,
        shadowColor: Colors.black.withValues(alpha: .10),
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _openDestination(
            context,
            record,
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: theme.colorScheme.outlineVariant,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --------------------------------------------------------
                // DESTINATION IMAGE
                // --------------------------------------------------------

                Expanded(
                  flex: 6,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Hero(
                        tag: catalogHeroTag(
                          item.type,
                          item.id,
                        ),
                        child: item.imageUrl.isEmpty
                            ? Container(
                                color: _primary.withValues(alpha: .10),
                                child: const Center(
                                  child: Icon(
                                    Icons.landscape_rounded,
                                    color: _primary,
                                    size: 42,
                                  ),
                                ),
                              )
                            : Image.network(
                                item.imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) {
                                  return Container(
                                    color:
                                        _primary.withValues(alpha: .10),
                                    child: const Center(
                                      child: Icon(
                                        Icons.landscape_rounded,
                                        color: _primary,
                                        size: 42,
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),

                      Positioned(
                        top: 10,
                        right: 10,
                        child: AnimatedBuilder(
                          animation: DiscoveryStore.instance,
                          builder: (context, _) {
                            return _DestinationSaveButton(
                              saved:
                                  DiscoveryStore.instance.isSaved(record),
                              onPressed: () {
                                DiscoveryStore.instance
                                    .toggleSaved(record);
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                // --------------------------------------------------------
                // DESTINATION INFORMATION
                // --------------------------------------------------------

                Expanded(
                  flex: 4,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      13,
                      11,
                      13,
                      12,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 23,
                          height: 3,
                          decoration: BoxDecoration(
                            color: _secondary,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),

                        const SizedBox(height: 7),

                        Text(
                          item.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                            height: 1.1,
                            letterSpacing: -.15,
                          ),
                        ),

                        const SizedBox(height: 5),

                        Expanded(
                          child: Text(
                            item.tagline ??
                                item.location ??
                                '',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              height: 1.28,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
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

  Future<void> _openDestination(
    BuildContext context,
    DiscoveryRecord record,
  ) async {
    await DiscoveryStore.instance.recordView(record);

    try {
      final detail =
          await CatalogService.instance.fetchDestination(item.slug);

      if (!context.mounted) {
        return;
      }

      Navigator.push(
        context,
        premiumPageRoute(
          (_) => DestinationDetailsPage(
            item: detail,
          ),
        ),
      );
    } catch (_) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'This destination could not be loaded. Please try again.',
          ),
        ),
      );
    }
  }
}

// ============================================================================
// DESTINATION SAVE BUTTON
// ============================================================================

class _DestinationSaveButton extends StatelessWidget {
  const _DestinationSaveButton({
    required this.saved,
    required this.onPressed,
  });

  final bool saved;
  final VoidCallback onPressed;

  static const Color _secondary = Color(0xFFF46627);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: .94),
      elevation: 2,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 38,
          height: 38,
          child: Icon(
            saved
                ? Icons.favorite_rounded
                : Icons.favorite_border_rounded,
            color: saved
                ? _secondary
                : const Color(0xFF263532),
            size: 21,
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// EMPTY RESULT
// ============================================================================

class _CatalogEmptyResult extends StatelessWidget {
  const _CatalogEmptyResult({
    required this.icon,
    required this.message,
  });

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest
            .withValues(alpha: .48),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: theme.colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: theme.colorScheme.primary,
            size: 32,
          ),
          const SizedBox(height: 9),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// EXPERIENCE VISUAL
// ============================================================================

class _ExperienceVisual {
  const _ExperienceVisual(
    this.icon,
    this.colors,
  );

  final IconData icon;
  final List<Color> colors;

  factory _ExperienceVisual.fromMood(
    SafariMood mood,
  ) {
    return _ExperienceVisual(
      mood.icon,
      [
        mood.primaryColor,
        mood.secondaryColor,
      ],
    );
  }
}