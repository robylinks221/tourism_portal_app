import 'package:flutter/material.dart';

import '../models/catalog_item.dart';
import '../models/discovery_item.dart';
import '../models/mood_discovery.dart';
import '../models/operator_management.dart';
import '../models/safari_mood.dart';
import '../pages/catalog_detail_page.dart';
import '../services/catalog_service.dart';
import '../services/discovery_store.dart';
import '../services/mood_discovery_service.dart';
import '../utils/text_case.dart';
import 'app_ui.dart';
import 'premium_navigation.dart';
import 'premium_states.dart';
import 'safari_trail.dart';

class CatalogHomeSections extends StatefulWidget {
  const CatalogHomeSections({super.key});

  @override
  State<CatalogHomeSections> createState() => _CatalogHomeSectionsState();
}

class _CatalogHomeSectionsState extends State<CatalogHomeSections> {
  late Future<TourismCatalog> _catalog;

  @override
  void initState() {
    super.initState();
    _catalog = CatalogService.instance.fetchCatalog();
  }

  void _retry() {
    setState(() => _catalog = CatalogService.instance.fetchCatalog());
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
                'Check your connection to reload destinations and activities.',
            kind: AppStateKind.offline,
            onRetry: _retry,
          );
        }

        final catalog = snapshot.data!;
        return ValueListenableBuilder<String?>(
          valueListenable: SafariMoodController.instance,
          builder: (context, selectedKey, _) {
            final moods = catalog.moods;
            final selectedMood = safariMoodByKey(moods, selectedKey);
            final effectiveSelectedKey =
                selectedMood == null ? null : selectedKey;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _MoodHeading(selectedMood: selectedMood),
                const SizedBox(height: 16),
                if (moods.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest.withOpacity(.45),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Safari moods are being prepared. Explore the destinations below.',
                    ),
                  )
                else
                  SizedBox(
                    height: 218,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      clipBehavior: Clip.none,
                      itemCount: moods.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 13),
                      itemBuilder: (context, index) {
                        final mood = moods[index];
                        return _MoodCard(
                          mood: mood,
                          selected: mood.key == effectiveSelectedKey,
                          imageUrl: _moodImageUrl(catalog, mood.key),
                          onTap:
                              () => SafariMoodController.instance.select(
                                mood.key,
                              ),
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 24),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 280),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  child:
                      selectedMood == null
                          ? KeyedSubtree(
                            key: const ValueKey('all-destinations'),
                            child: _CatalogSection(
                              title: 'Explore destinations',
                              subtitle: 'Beautiful places across East Africa',
                              emptyText:
                                  'No published destinations are available yet.',
                              items: catalog.destinations,
                            ),
                          )
                          : KeyedSubtree(
                            key: ValueKey(effectiveSelectedKey),
                            child: _MoodDiscoveryResults(
                              mood: selectedMood,
                              future: MoodDiscoveryService.instance.fetch(
                                selectedMood.key,
                              ),
                              onRetry:
                                  () => setState(() {
                                    MoodDiscoveryService.instance.invalidate(
                                      selectedMood.key,
                                    );
                                  }),
                            ),
                          ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _moodImageUrl(TourismCatalog catalog, String moodKey) {
    final mood = safariMoodByKey(catalog.moods, moodKey);
    if (mood?.imageUrl.isNotEmpty == true) return mood!.imageUrl;
    for (final destination in catalog.destinations) {
      if (destination.moods.contains(moodKey) &&
          destination.imageUrl.isNotEmpty) {
        return destination.imageUrl;
      }
    }
    for (final activity in catalog.activities) {
      if (activity.moods.contains(moodKey) && activity.imageUrl.isNotEmpty) {
        return activity.imageUrl;
      }
    }
    return '';
  }
}

class _MoodDiscoveryResults extends StatefulWidget {
  const _MoodDiscoveryResults({
    required this.mood,
    required this.future,
    required this.onRetry,
  });

  final SafariMood mood;
  final Future<MoodDiscoveryData> future;
  final VoidCallback onRetry;

  @override
  State<_MoodDiscoveryResults> createState() => _MoodDiscoveryResultsState();
}

class _MoodDiscoveryResultsState extends State<_MoodDiscoveryResults> {
  int _selectedTab = 0;

  @override
  void didUpdateWidget(covariant _MoodDiscoveryResults oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.mood.id != widget.mood.id) {
      _selectedTab = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<MoodDiscoveryData>(
      future: widget.future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return _MoodDiscoveryLoading(mood: widget.mood);
        }

        if (snapshot.hasError) {
          return _MoodDiscoveryError(
            mood: widget.mood,
            onRetry: widget.onRetry,
          );
        }

        final discovery = snapshot.data!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SelectedMoodHero(
              mood: discovery.mood,
              selectedIndex: _selectedTab,
              activityCount: discovery.activities.length,
              destinationCount: discovery.destinations.length,
              tourCount: discovery.tours.length,
              onChanged: (index) {
                setState(() {
                  _selectedTab = index;
                });
              },
            ),
            const SizedBox(height: 22),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: _selectedContent(discovery),
            ),
          ],
        );
      },
    );
  }

  Widget _selectedContent(MoodDiscoveryData discovery) {
    switch (_selectedTab) {
      case 1:
        return KeyedSubtree(
          key: ValueKey('destinations-${discovery.mood.id}'),
          child: _CatalogSection(
            title: 'Destinations',
            subtitle: 'Places for ${discovery.mood.title.toLowerCase()}',
            emptyText:
                'No published destinations have been assigned to this Safari Mood yet.',
            items: discovery.destinations,
          ),
        );

      case 2:
        return KeyedSubtree(
          key: ValueKey('tours-${discovery.mood.id}'),
          child: _MoodTourSection(mood: discovery.mood, tours: discovery.tours),
        );

      case 0:
      default:
        return KeyedSubtree(
          key: ValueKey('activities-${discovery.mood.id}'),
          child: _CatalogSection(
            title: 'Safari Activities',
            subtitle: 'Experiences for ${discovery.mood.title.toLowerCase()}',
            emptyText:
                'No published activities have been assigned to this Safari Mood yet.',
            items: discovery.activities,
          ),
        );
    }
  }
}

class _SelectedMoodHero extends StatelessWidget {
  const _SelectedMoodHero({
    required this.mood,
    required this.selectedIndex,
    required this.activityCount,
    required this.destinationCount,
    required this.tourCount,
    required this.onChanged,
  });

  final SafariMood mood;
  final int selectedIndex;
  final int activityCount;
  final int destinationCount;
  final int tourCount;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasImage = mood.imageUrl.trim().isNotEmpty;

    return Container(
      width: double.infinity,
      height: 310,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.16),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (hasImage)
            Image.network(
              mood.imageUrl,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.medium,
              errorBuilder: (_, __, ___) => _MoodHeroFallback(mood: mood),
            )
          else
            _MoodHeroFallback(mood: mood),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x22000000),
                  Color(0x42000000),
                  Color(0xE8000000),
                ],
                stops: [0, .48, 1],
              ),
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            top: 20,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(.34),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withOpacity(.26),
                    ),
                  ),
                  child: Icon(
                    mood.icon,
                    color: Colors.white,
                    size: 25,
                  ),
                ),
                const Spacer(),
                Material(
                  color: Colors.black.withOpacity(.34),
                  borderRadius: BorderRadius.circular(999),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: SafariMoodController.instance.clear,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 13,
                        vertical: 9,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.close_rounded,
                            color: Colors.white,
                            size: 17,
                          ),
                          SizedBox(width: 5),
                          Text(
                            'Show all',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 86,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mood.title.toTitleCase(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    height: 1.05,
                    letterSpacing: -.45,
                  ),
                ),
                if (mood.subtitle.trim().isNotEmpty) ...[
                  const SizedBox(height: 7),
                  Text(
                    mood.subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withOpacity(.84),
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Positioned(
            left: 14,
            right: 14,
            bottom: 14,
            child: Container(
              height: 58,
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(.38),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(.18),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _MoodHeroTab(
                      label: 'Activities',
                      count: activityCount,
                      selected: selectedIndex == 0,
                      onTap: () => onChanged(0),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: _MoodHeroTab(
                      label: 'Destinations',
                      count: destinationCount,
                      selected: selectedIndex == 1,
                      onTap: () => onChanged(1),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: _MoodHeroTab(
                      label: 'Tours',
                      count: tourCount,
                      selected: selectedIndex == 2,
                      onTap: () => onChanged(2),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MoodHeroFallback extends StatelessWidget {
  const _MoodHeroFallback({required this.mood});

  final SafariMood mood;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            mood.primaryColor,
            mood.secondaryColor,
          ],
        ),
      ),
    );
  }
}

class _MoodHeroTab extends StatelessWidget {
  const _MoodHeroTab({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? Colors.white : Colors.transparent,
      borderRadius: BorderRadius.circular(15),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 7,
            vertical: 8,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected ? const Color(0xFF153D36) : Colors.white,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$count',
                style: TextStyle(
                  color: selected
                      ? const Color(0xFF153D36).withOpacity(.68)
                      : Colors.white.withOpacity(.72),
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MoodDiscoveryLoading extends StatelessWidget {
  const _MoodDiscoveryLoading({required this.mood});

  final SafariMood mood;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            mood.primaryColor.withOpacity(.16),
            mood.secondaryColor.withOpacity(.06),
          ],
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: mood.primaryColor.withOpacity(.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: mood.primaryColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(mood.icon, color: Colors.white),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Finding ${mood.title.toLowerCase()}…',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Matching activities, destinations and tours',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 6,
              color: mood.primaryColor,
              backgroundColor: mood.primaryColor.withOpacity(.12),
            ),
          ),
        ],
      ),
    );
  }
}

class _MoodDiscoveryError extends StatelessWidget {
  const _MoodDiscoveryError({required this.mood, required this.onRetry});

  final SafariMood mood;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer.withOpacity(.42),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.error.withOpacity(.18)),
      ),
      child: Row(
        children: [
          Icon(Icons.cloud_off_rounded, color: theme.colorScheme.error),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${mood.title} could not be loaded',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                const Text('Check the connection and try again.'),
              ],
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _MoodHeading extends StatelessWidget {
  const _MoodHeading({required this.selectedMood});

  final SafariMood? selectedMood;

  @override
  Widget build(BuildContext context) {
    return const AppSectionHeader(
      title: 'Choose Your Safari Mood',
      subtitle: 'Start with how you want the journey to feel.',
    );
  }
}

class _MoodCard extends StatelessWidget {
  const _MoodCard({
    required this.mood,
    required this.selected,
    required this.imageUrl,
    required this.onTap,
  });

  final SafariMood mood;
  final bool selected;
  final String imageUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final visual = _MoodVisual.fromMood(mood);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      width: selected ? 194 : 178,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(27),
        border: Border.all(
          color: selected ? Colors.white : Colors.transparent,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: visual.colors.last.withOpacity(selected ? .32 : .2),
            blurRadius: selected ? 25 : 17,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(27),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (imageUrl.isNotEmpty)
                Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors:
                        imageUrl.isEmpty
                            ? [visual.colors.first, visual.colors.last]
                            : [
                              visual.colors.first.withOpacity(.18),
                              visual.colors.last.withOpacity(.94),
                            ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(.18),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.white.withOpacity(.23),
                            ),
                          ),
                          child: Icon(
                            visual.icon,
                            color: Colors.white,
                            size: 23,
                          ),
                        ),
                        AnimatedOpacity(
                          opacity: selected ? 1 : 0,
                          duration: const Duration(milliseconds: 160),
                          child: const Icon(
                            Icons.check_circle_rounded,
                            color: Colors.white,
                            size: 23,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      mood.title.toTitleCase(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        height: 1.08,
                        letterSpacing: -.25,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      mood.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white.withOpacity(.78),
                        height: 1.3,
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
}

class _MoodTourSection extends StatelessWidget {
  const _MoodTourSection({required this.mood, required this.tours});

  final SafariMood mood;
  final List<OperatorTour> tours;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppSectionHeader(
          title: 'Tours for This Mood',
          subtitle: 'Published by local guides and tour operators',
        ),
        const SizedBox(height: 14),
        if (tours.isEmpty)
          _MoodEmptyResult(
            icon: Icons.route_rounded,
            message: 'No published tour has been assigned to this mood yet.',
          )
        else
          SizedBox(
            height: 304,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              itemCount: tours.length,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder:
                  (context, index) =>
                      _MoodTourCard(tour: tours[index], mood: mood),
            ),
          ),
      ],
    );
  }
}

class _MoodTourCard extends StatelessWidget {
  const _MoodTourCard({required this.tour, required this.mood});

  final OperatorTour tour;
  final SafariMood mood;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final destination =
        tour.destinationNames.isEmpty
            ? 'Safari experience'
            : tour.destinationNames.first;

    return SizedBox(
      width: 236,
      child: Material(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(25),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _showMoodTour(context, tour, mood),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: theme.colorScheme.outlineVariant),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _MoodTourImage(tour: tour, mood: mood),
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Color(0x9E000000)],
                          ),
                        ),
                      ),
                      Positioned(
                        left: 12,
                        top: 12,
                        child: _MoodTourBadge(
                          icon: Icons.schedule_rounded,
                          label:
                              '${tour.days} ${tour.days == 1 ? 'day' : 'days'}',
                        ),
                      ),
                      Positioned(
                        right: 12,
                        top: 12,
                        child: AnimatedBuilder(
                          animation: DiscoveryStore.instance,
                          builder: (context, _) {
                            final record = DiscoveryRecord.fromTour(tour);
                            return AppSaveButton(
                              saved: DiscoveryStore.instance.isSaved(record),
                              onPressed:
                                  () => DiscoveryStore.instance.toggleSaved(
                                    record,
                                  ),
                            );
                          },
                        ),
                      ),
                      Positioned(
                        left: 13,
                        right: 13,
                        bottom: 12,
                        child: Text(
                          destination,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 13, 14, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tour.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          Icon(
                            tour.isGuideLed
                                ? Icons.person_outline_rounded
                                : Icons.business_outlined,
                            size: 16,
                            color: mood.primaryColor,
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              tour.operatorName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _tourPrice(tour),
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: mood.primaryColor,
                          fontWeight: FontWeight.w700,
                        ),
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
}

class _MoodTourImage extends StatelessWidget {
  const _MoodTourImage({required this.tour, required this.mood});

  final OperatorTour tour;
  final SafariMood mood;

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [mood.primaryColor, mood.secondaryColor],
        ),
      ),
      child: const Center(
        child: Icon(Icons.route_rounded, color: Colors.white, size: 48),
      ),
    );
    if (tour.imageUrl.isEmpty) return fallback;
    return Image.network(
      tour.imageUrl,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => fallback,
    );
  }
}

class _MoodTourBadge extends StatelessWidget {
  const _MoodTourBadge({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(.48),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _MoodSectionDivider extends StatelessWidget {
  const _MoodSectionDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Divider(
        height: 1,
        thickness: 1,
        color: Theme.of(context).colorScheme.outlineVariant,
      ),
    );
  }
}

class _MoodEmptyResult extends StatelessWidget {
  const _MoodEmptyResult({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return IllustratedEmptyState(
      title: 'The next trail is being prepared',
      message: message,
      icon: icon,
    );
  }
}

String _tourPrice(OperatorTour tour) {
  final amount =
      tour.price == tour.price.roundToDouble()
          ? tour.price.toStringAsFixed(0)
          : tour.price.toStringAsFixed(2);
  return '${tour.currency.isEmpty ? 'USD' : tour.currency} $amount';
}

Future<void> _showMoodTour(
  BuildContext context,
  OperatorTour tour,
  SafariMood mood,
) async {
  await DiscoveryStore.instance.recordView(DiscoveryRecord.fromTour(tour));
  if (!context.mounted) return;
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _MoodTourDetails(tour: tour, mood: mood),
  );
}

class _MoodTourDetails extends StatelessWidget {
  const _MoodTourDetails({required this.tour, required this.mood});

  final OperatorTour tour;
  final SafariMood mood;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: .86,
      minChildSize: .56,
      maxChildSize: .96,
      builder:
          (context, controller) => ListView(
            controller: controller,
            padding: EdgeInsets.zero,
            children: [
              SizedBox(
                height: 270,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _MoodTourImage(tour: tour, mood: mood),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Color(0xC7000000)],
                        ),
                      ),
                    ),
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Material(
                        color: Colors.black.withOpacity(.42),
                        shape: const CircleBorder(),
                        child: IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(
                            Icons.close_rounded,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 20,
                      right: 20,
                      bottom: 20,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            mood.title.toTitleCase(),
                            style: TextStyle(
                              color: Colors.white.withOpacity(.78),
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                              letterSpacing: 1.1,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            tour.name,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Chip(
                          avatar: const Icon(Icons.schedule_rounded, size: 17),
                          label: Text(
                            '${tour.days} ${tour.days == 1 ? 'day' : 'days'}',
                          ),
                        ),
                        Chip(
                          avatar: Icon(
                            tour.isGuideLed
                                ? Icons.person_outline_rounded
                                : Icons.business_outlined,
                            size: 17,
                          ),
                          label: Text(tour.operatorName),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    Text(
                      _tourPrice(tour),
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: mood.primaryColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      tour.overview,
                      style: theme.textTheme.bodyLarge?.copyWith(height: 1.55),
                    ),
                    if (tour.destinationNames.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      Text(
                        'Destinations',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(tour.destinationNames.join(' • ')),
                    ],
                    if (tour.itinerary.isNotEmpty) ...[
                      const SizedBox(height: 28),
                      SafariTrail(
                        stops: tour.itinerary,
                        accent: mood.primaryColor,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
    );
  }
}

class _CatalogSection extends StatelessWidget {
  const _CatalogSection({
    required this.title,
    required this.subtitle,
    required this.emptyText,
    required this.items,
  });

  final String title;
  final String subtitle;
  final String emptyText;
  final List<CatalogItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSectionHeader(title: title, subtitle: subtitle),
        const SizedBox(height: 14),
        if (items.isEmpty)
          _MoodEmptyResult(icon: Icons.search_off_rounded, message: emptyText)
        else
          SizedBox(
            height: 240,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (context, index) => _CatalogCard(item: items[index]),
            ),
          ),
      ],
    );
  }
}

class _CatalogCard extends StatelessWidget {
  const _CatalogCard({required this.item});

  final CatalogItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final record = DiscoveryRecord.fromCatalog(item);
    return SizedBox(
      width:
          (MediaQuery.sizeOf(context).width * .56).clamp(184, 220).toDouble(),
      child: Material(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(23),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () async {
            await DiscoveryStore.instance.recordView(record);

            try {
              final detail =
                  item.isActivity
                      ? await CatalogService.instance.fetchActivity(item.slug)
                      : await CatalogService.instance.fetchDestination(
                        item.slug,
                      );

              if (!context.mounted) return;

              Navigator.push(
                context,
                premiumPageRoute((_) => CatalogDetailPage(item: detail)),
              );
            } catch (_) {
              if (!context.mounted) return;

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'This safari page could not be loaded. Please try again.',
                  ),
                ),
              );
            }
          },
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: theme.colorScheme.outlineVariant),
              borderRadius: BorderRadius.circular(23),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Hero(
                        tag: catalogHeroTag(item.type, item.id),
                        child:
                            item.imageUrl.isEmpty
                                ? Container(
                                  width: double.infinity,
                                  color: theme.colorScheme.primaryContainer,
                                  child: Icon(
                                    item.isActivity
                                        ? Icons.hiking_rounded
                                        : Icons.landscape_rounded,
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
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (_, __, ___) => Container(
                                          color:
                                              theme
                                                  .colorScheme
                                                  .primaryContainer,
                                        ),
                                  ),
                                ),
                      ),
                      Positioned(
                        right: 10,
                        top: 10,
                        child: AnimatedBuilder(
                          animation: DiscoveryStore.instance,
                          builder:
                              (context, _) => AppSaveButton(
                                saved: DiscoveryStore.instance.isSaved(record),
                                onPressed:
                                    () => DiscoveryStore.instance.toggleSaved(
                                      record,
                                    ),
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
                        item.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.tagline ?? item.location ?? '',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall,
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
}

class _MoodVisual {
  const _MoodVisual(this.icon, this.colors);

  final IconData icon;
  final List<Color> colors;

  factory _MoodVisual.fromMood(SafariMood mood) =>
      _MoodVisual(mood.icon, [mood.primaryColor, mood.secondaryColor]);
}
