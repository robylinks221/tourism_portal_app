import 'package:flutter/material.dart';

import '../models/catalog_item.dart';
import '../models/mood_discovery.dart';
import '../models/operator_management.dart';
import '../models/safari_mood.dart';
import '../services/mood_discovery_service.dart';
import 'activity_details_page.dart';
import 'destination_details_page.dart';
import 'experience_items_page.dart';
import 'tour_details_page.dart';

class SafariMoodPage extends StatefulWidget {
  const SafariMoodPage({super.key, required this.mood});

  final SafariMood mood;

  @override
  State<SafariMoodPage> createState() => _SafariMoodPageState();
}

class _SafariMoodPageState extends State<SafariMoodPage> {
  static const Color _primary = Color(0xFF165B5D);
  static const Color _background = Color(0xFFF4EEE1);

  int _selectedTab = 0;

  late Future<MoodDiscoveryData> _discovery;

  @override
  void initState() {
    super.initState();
    _discovery = _load();
  }

  Future<MoodDiscoveryData> _load() {
    return MoodDiscoveryService.instance.fetch(widget.mood.key);
  }

  void _retry() {
    MoodDiscoveryService.instance.invalidate(widget.mood.key);

    setState(() {
      _discovery = _load();
    });
  }

  void _selectTab(int index) {
    if (_selectedTab == index) return;

    setState(() {
      _selectedTab = index;
    });
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
      body: FutureBuilder<MoodDiscoveryData>(
        future: _discovery,
        builder: (context, snapshot) {
          final data = snapshot.data;

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: _ExperienceHero(
                  mood: data?.mood ?? widget.mood,
                  tourCount: data?.tours.length ?? 0,
                  activityCount: data?.activities.length ?? 0,
                  destinationCount: data?.destinations.length ?? 0,
                ),
              ),
              SliverToBoxAdapter(
                child: Transform.translate(
                  offset: const Offset(0, -22),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: _background,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(34),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 26, 18, 36),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Explore This Experience',
                            style: TextStyle(
                              color: _primary,
                              fontSize: 27,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.7,
                            ),
                          ),
                          const SizedBox(height: 18),
                          if (snapshot.connectionState != ConnectionState.done)
                            _LoadingPanel(mood: widget.mood)
                          else if (snapshot.hasError)
                            _ErrorPanel(onRetry: _retry)
                          else if (data != null) ...[
                            _ExperienceTabs(
                              selectedIndex: _selectedTab,
                              onChanged: _selectTab,
                            ),
                            const SizedBox(height: 22),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 280),
                              switchInCurve: Curves.easeOutCubic,
                              switchOutCurve: Curves.easeInCubic,
                              transitionBuilder: (child, animation) {
                                final offset = Tween<Offset>(
                                  begin: const Offset(.03, .02),
                                  end: Offset.zero,
                                ).animate(animation);

                                return FadeTransition(
                                  opacity: animation,
                                  child: SlideTransition(
                                    position: offset,
                                    child: child,
                                  ),
                                );
                              },
                              child: _buildSelectedContent(data),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSelectedContent(MoodDiscoveryData data) {
    switch (_selectedTab) {
      case 1:
        return _ExperienceListSection(
          key: ValueKey('activities-${data.mood.id}'),
          title: 'Safari activities for this experience',
          visibleCount: 4,
          totalCount: data.activities.length,
          showAll: false,
          onToggleAll: () {
            Navigator.push<void>(
              context,
              MaterialPageRoute<void>(
                builder:
                    (_) => ExperienceItemsPage(
                      mood: data.mood,
                      type: ExperienceItemsType.activities,
                      tours: data.tours,
                      activities: data.activities,
                      destinations: data.destinations,
                    ),
              ),
            );
          },
          emptyTitle: 'No activities yet',
          emptyMessage:
              'Activities for this experience are still being prepared.',
          children:
              data.activities
                  .take(4)
                  .map(
                    (item) => _CatalogRowCard(
                      item: item,
                      type: _ExperienceItemType.activity,
                      onTap: () => _openCatalogItem(item),
                    ),
                  )
                  .toList(),
        );

      case 2:
        return _ExperienceListSection(
          key: ValueKey('destinations-${data.mood.id}'),
          title: 'Destinations for this experience',
          visibleCount: 4,
          totalCount: data.destinations.length,
          showAll: false,
          onToggleAll: () {
            Navigator.push<void>(
              context,
              MaterialPageRoute<void>(
                builder:
                    (_) => ExperienceItemsPage(
                      mood: data.mood,
                      type: ExperienceItemsType.destinations,
                      tours: data.tours,
                      activities: data.activities,
                      destinations: data.destinations,
                    ),
              ),
            );
          },
          emptyTitle: 'No destinations yet',
          emptyMessage:
              'Destinations for this experience are still being prepared.',
          children:
              data.destinations
                  .take(4)
                  .map(
                    (item) => _CatalogRowCard(
                      item: item,
                      type: _ExperienceItemType.destination,
                      onTap: () => _openCatalogItem(item),
                    ),
                  )
                  .toList(),
        );

      case 0:
      default:
        return _ExperienceListSection(
          key: ValueKey('tours-${data.mood.id}'),
          title: 'Tours for this experience',
          visibleCount: 4,
          totalCount: data.tours.length,
          showAll: false,
          onToggleAll: () {
            Navigator.push<void>(
              context,
              MaterialPageRoute<void>(
                builder:
                    (_) => ExperienceItemsPage(
                      mood: data.mood,
                      type: ExperienceItemsType.tours,
                      tours: data.tours,
                      activities: data.activities,
                      destinations: data.destinations,
                    ),
              ),
            );
          },
          emptyTitle: 'No tours yet',
          emptyMessage:
              'Published tours for this experience are still being prepared.',
          children:
              data.tours
                  .take(4)
                  .map(
                    (tour) =>
                        _TourRowCard(tour: tour, onTap: () => _openTour(tour)),
                  )
                  .toList(),
        );
    }
  }
}

class _ExperienceHero extends StatelessWidget {
  const _ExperienceHero({
    required this.mood,
    required this.tourCount,
    required this.activityCount,
    required this.destinationCount,
  });

  final SafariMood mood;
  final int tourCount;
  final int activityCount;
  final int destinationCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasImage = mood.imageUrl.trim().isNotEmpty;

    return SizedBox(
      height: 405,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Hero(
            tag: 'safari-mood-${mood.id}',
            child:
                hasImage
                    ? Image.network(
                      mood.imageUrl,
                      fit: BoxFit.cover,
                      filterQuality: FilterQuality.medium,
                      errorBuilder: (_, __, ___) => _fallback(),
                    )
                    : _fallback(),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x24000000),
                  Color(0x5A000000),
                  Color(0xE6000000),
                ],
                stops: [0.08, 0.52, 1.0],
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
              child: Align(
                alignment: Alignment.topLeft,
                child: Material(
                  color: Colors.black.withValues(alpha: .30),
                  shape: const CircleBorder(),
                  child: IconButton(
                    tooltip: 'Back',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 22,
            right: 22,
            bottom: 44,
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 520),
              curve: Curves.easeOutCubic,
              tween: Tween<double>(begin: 0, end: 1),
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 18 * (1 - value)),
                    child: child,
                  ),
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mood.title,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      height: 1.04,
                      letterSpacing: -.8,
                    ),
                  ),
                  if (mood.subtitle.trim().isNotEmpty) ...[
                    const SizedBox(height: 7),
                    Text(
                      mood.subtitle,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: Colors.white.withValues(alpha: .88),
                        height: 1.35,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _HeroStat(
                        icon: Icons.route_outlined,
                        value: '$tourCount Tours',
                      ),
                      _HeroStat(
                        icon: Icons.explore_outlined,
                        value: '$activityCount Activities',
                      ),
                      _HeroStat(
                        icon: Icons.location_on_outlined,
                        value: '$destinationCount Destinations',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fallback() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF165B5D), Color(0xFF0D3D3F)],
        ),
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: .32),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: .20)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 15),
          const SizedBox(width: 5),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExperienceTabs extends StatelessWidget {
  const _ExperienceTabs({required this.selectedIndex, required this.onChanged});

  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    const labels = ['Tours', 'Activities', 'Destinations'];

    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: labels.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          return _ExperienceTabButton(
            title: labels[index],
            selected: selectedIndex == index,
            onTap: () => onChanged(index),
          );
        },
      ),
    );
  }
}

class _ExperienceTabButton extends StatelessWidget {
  const _ExperienceTabButton({
    required this.title,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final bool selected;
  final VoidCallback onTap;

  static const Color _primary = Color(0xFF165B5D);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? _primary : Colors.white,
      elevation: selected ? 2 : 0,
      shadowColor: Colors.black.withValues(alpha: .08),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          constraints: const BoxConstraints(minWidth: 112),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? _primary : const Color(0xFFD8D5CC),
            ),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? Colors.white : const Color(0xFF17211F),
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

class _ExperienceListSection extends StatelessWidget {
  const _ExperienceListSection({
    super.key,
    required this.title,
    required this.visibleCount,
    required this.totalCount,
    required this.showAll,
    required this.onToggleAll,
    required this.children,
    required this.emptyTitle,
    required this.emptyMessage,
  });

  final String title;
  final int visibleCount;
  final int totalCount;
  final bool showAll;
  final VoidCallback onToggleAll;
  final List<Widget> children;
  final String emptyTitle;
  final String emptyMessage;

  static const Color _primary = Color(0xFF165B5D);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF17211F),
                  letterSpacing: -.25,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onToggleAll,
                borderRadius: BorderRadius.circular(999),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'View All',
                        style: TextStyle(
                          color: _primary,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: _primary,
                        size: 21,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (children.isEmpty)
          _EmptyState(title: emptyTitle, message: emptyMessage)
        else
          ...children.expand((child) => [child, const SizedBox(height: 12)]),
      ],
    );
  }
}

class _TourRowCard extends StatelessWidget {
  const _TourRowCard({required this.tour, required this.onTap});

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
      shadowColor: Colors.black.withValues(alpha: .18),
      borderRadius: BorderRadius.circular(22),
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 146,
          child: Row(
            children: [
              SizedBox(
                width: 120,
                height: double.infinity,
                child: _TourImage(tour: tour),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 13, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _primary.withValues(alpha: .08),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          'TOUR',
                          style: TextStyle(
                            color: _primary,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        tour.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          height: 1.17,
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
                      const Spacer(),
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
                      const SizedBox(height: 7),
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
            ],
          ),
        ),
      ),
    );
  }
}

enum _ExperienceItemType { activity, destination }

class _CatalogRowCard extends StatelessWidget {
  const _CatalogRowCard({
    required this.item,
    required this.type,
    required this.onTap,
  });

  final CatalogItem item;
  final _ExperienceItemType type;
  final VoidCallback onTap;

  static const Color _primary = Color(0xFF165B5D);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final relatedNames =
        type == _ExperienceItemType.activity
            ? item.destinations
                .map((destination) => destination.name.trim())
                .where((name) => name.isNotEmpty)
                .toList()
            : item.activities
                .map((activity) => activity.name.trim())
                .where((name) => name.isNotEmpty)
                .toList();

    final fallbackSubtitle =
        type == _ExperienceItemType.activity
            ? (item.tagline ?? '')
            : [item.location, item.country]
                .where((value) => value != null && value.trim().isNotEmpty)
                .join(', ');

    final subtitle =
        relatedNames.isEmpty ? fallbackSubtitle : relatedNames.first;
    final moreCount = relatedNames.length > 1 ? relatedNames.length - 1 : 0;

    return Material(
      elevation: 10,
      shadowColor: Colors.black.withValues(alpha: .18),
      borderRadius: BorderRadius.circular(22),
      color: Colors.white,
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
                child: _CatalogImage(item: item, type: type),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _primary.withValues(alpha: .08),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          type == _ExperienceItemType.activity
                              ? 'ACTIVITY'
                              : 'DESTINATION',
                          style: const TextStyle(
                            color: _primary,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(height: 7),
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
                                      type == _ExperienceItemType.activity
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
                padding: EdgeInsets.only(right: 12),
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 15,
                  color: _primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TourImage extends StatelessWidget {
  const _TourImage({required this.tour});

  final OperatorTour tour;

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      color: const Color(0xFFE4EFEC),
      alignment: Alignment.center,
      child: const Icon(
        Icons.landscape_outlined,
        color: Color(0xFF165B5D),
        size: 36,
      ),
    );

    final image =
        tour.imageUrl.isEmpty
            ? fallback
            : Image.network(
              tour.imageUrl,
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

class _CatalogImage extends StatelessWidget {
  const _CatalogImage({required this.item, required this.type});

  final CatalogItem item;
  final _ExperienceItemType type;

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      color: const Color(0xFFE4EFEC),
      alignment: Alignment.center,
      child: Icon(
        type == _ExperienceItemType.activity
            ? Icons.explore_outlined
            : Icons.landscape_outlined,
        color: const Color(0xFF165B5D),
        size: 32,
      ),
    );

    final image =
        item.imageUrl.isEmpty
            ? fallback
            : Image.network(
              item.imageUrl,
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

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .68),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF165B5D).withValues(alpha: .08),
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.explore_outlined,
            color: Color(0xFF165B5D),
            size: 42,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: const Color(0xFF17211F).withValues(alpha: .58),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingPanel extends StatelessWidget {
  const _LoadingPanel({required this.mood});

  final SafariMood mood;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .70),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Finding ${mood.title.toLowerCase()} experiences…',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 14),
          const ClipRRect(
            borderRadius: BorderRadius.all(Radius.circular(999)),
            child: LinearProgressIndicator(
              minHeight: 6,
              color: Color(0xFF165B5D),
              backgroundColor: Color(0xFFD9E7E3),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .70),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            color: Color(0xFFF46627),
            size: 42,
          ),
          const SizedBox(height: 12),
          Text(
            'This experience could not be loaded',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          const Text(
            'Check your connection and try again.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onRetry,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF165B5D),
              shape: const StadiumBorder(),
            ),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try Again'),
          ),
        ],
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
