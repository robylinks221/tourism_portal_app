import 'dart:async';

import 'package:flutter/material.dart';

import '../models/catalog_item.dart';
import '../models/community.dart';
import '../models/operator_management.dart';
import '../services/catalog_service.dart';
import '../widgets/provider_discovery_sections.dart';
import 'tour_details_page.dart';
import 'activity_details_page.dart';
import 'accommodation_details_page.dart';

class DestinationDetailsPage extends StatefulWidget {
  const DestinationDetailsPage({super.key, required this.item});

  final CatalogItem item;

  @override
  State<DestinationDetailsPage> createState() => _DestinationDetailsPageState();
}

class _DestinationDetailsPageState extends State<DestinationDetailsPage> {
  static const Color _background = Color(0xFFF4EEE1);

  late Future<_CatalogPageData> _data;

  @override
  void initState() {
    super.initState();
    _data = _load();
  }

  Future<_CatalogPageData> _load() async {
    final detailFuture = CatalogService.instance.fetchDestination(
      widget.item.slug,
    );

    final toursFuture = CatalogService.instance.fetchDestinationTours(
      slug: widget.item.slug,
      page: 1,
      perPage: 6,
    );

    final providersFuture = CatalogService.instance.fetchDestinationProviders(
      slug: widget.item.slug,
      page: 1,
      perPage: 6,
      type: 'all',
    );

    final detail = await detailFuture;
    final tours = await toursFuture;
    final providers = await providersFuture;

    return _CatalogPageData(
      detail: detail,
      tours: tours,
      providers: providers,
    );
  }

  void _retry() {
    setState(() {
      _data = _load();
    });
  }

  Future<void> _openRelated(CatalogItem item) async {
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

  Future<void> _openTour(OperatorTour tour) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(builder: (_) => TourDetailsPage(tour: tour)),
    );
  }

  Future<void> _openAccommodation(Accommodation accommodation) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => AccommodationDetailsPage(accommodation: accommodation),
      ),
    );
  }

  Future<void> _openProvider(CommunityMember member) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => ProviderProfilePage(member: member),
      ),
    );
  }

  Future<void> _viewAllTours(CatalogItem destination) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => _DestinationSafarisPage(
          destination: destination,
          onOpenTour: _openTour,
        ),
      ),
    );
  }

  Future<void> _viewAllProviders(CatalogItem destination) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => _DestinationExpertsPage(
          destination: destination,
          onOpenProvider: _openProvider,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: FutureBuilder<_CatalogPageData>(
        future: _data,
        builder: (context, snapshot) {
          final detail = snapshot.data?.detail ?? widget.item;

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: _Hero(
                  item: detail,
                  onBack: () => Navigator.pop(context),
                ),
              ),
              SliverToBoxAdapter(
                child: Transform.translate(
                  offset: const Offset(0, -24),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: _background,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(34),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 28, 18, 38),
                      child:
                          snapshot.connectionState != ConnectionState.done
                              ? const _LoadingBody()
                              : snapshot.hasError
                              ? _ErrorBody(onRetry: _retry)
                              : _Content(
                                data: snapshot.data!,
                                onOpenRelated: _openRelated,
                                onOpenTour: _openTour,
                                onOpenProvider: _openProvider,
                                onOpenAccommodation: _openAccommodation,
                                onViewAllTours: () =>
                                    _viewAllTours(snapshot.data!.detail),
                                onViewAllProviders: () =>
                                    _viewAllProviders(snapshot.data!.detail),
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
}

class _CatalogPageData {
  const _CatalogPageData({
    required this.detail,
    required this.tours,
    required this.providers,
  });

  final CatalogItem detail;
  final DestinationTourPage tours;
  final DestinationProviderPage providers;
}

class _Hero extends StatelessWidget {
  const _Hero({required this.item, required this.onBack});

  final CatalogItem item;
  final VoidCallback onBack;

  static const Color _primary = Color(0xFF165B5D);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final place = [
      item.location,
      item.country,
    ].where((value) => value != null && value.trim().isNotEmpty).join(', ');

    final fallback = Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF165B5D), Color(0xFF0D3D3F)],
        ),
      ),
      alignment: Alignment.center,
      child: Icon(
        item.isActivity ? Icons.explore_outlined : Icons.landscape_outlined,
        color: Colors.white.withValues(alpha: .24),
        size: 90,
      ),
    );

    return SizedBox(
      height: 390,
      child: Stack(
        fit: StackFit.expand,
        children: [
          item.imageUrl.isEmpty
              ? fallback
              : Hero(
                tag: 'catalog-${item.type}-${item.id}',
                child: Image.network(
                  item.imageUrl,
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.medium,
                  errorBuilder: (_, __, ___) => fallback,
                ),
              ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x22000000),
                  Color(0x4D000000),
                  Color(0xE6000000),
                ],
                stops: [0, .52, 1],
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
                    onPressed: onBack,
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: _primary.withValues(alpha: .92),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    item.isActivity ? 'SAFARI ACTIVITY' : 'SAFARI DESTINATION',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  item.name,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    height: 1.04,
                    letterSpacing: -.8,
                  ),
                ),
                if (place.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        color: Colors.white,
                        size: 18,
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({
    required this.data,
    required this.onOpenRelated,
    required this.onOpenTour,
    required this.onOpenProvider,
    required this.onOpenAccommodation,
    required this.onViewAllTours,
    required this.onViewAllProviders,
  });

  final _CatalogPageData data;
  final ValueChanged<CatalogItem> onOpenRelated;
  final ValueChanged<OperatorTour> onOpenTour;
  final ValueChanged<CommunityMember> onOpenProvider;
  final ValueChanged<Accommodation> onOpenAccommodation;
  final VoidCallback onViewAllTours;
  final VoidCallback onViewAllProviders;

  static const Color _primary = Color(0xFF165B5D);
  static const Color _ink = Color(0xFF17211F);

  @override
  Widget build(BuildContext context) {
    final detail = data.detail;
    final theme = Theme.of(context);

    final related = detail.isActivity ? detail.destinations : detail.activities;

    final providers = data.providers.items;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (detail.tagline?.trim().isNotEmpty == true) ...[
          Text(
            detail.tagline!,
            style: theme.textTheme.titleLarge?.copyWith(
              color: _primary,
              fontWeight: FontWeight.w900,
              height: 1.25,
              letterSpacing: -.25,
            ),
          ),
          const SizedBox(height: 18),
        ],
        _PremiumSection(
          icon: Icons.auto_awesome_outlined,
          eyebrow: 'OVERVIEW',
          title:
              detail.isActivity
                  ? 'About this activity'
                  : 'About this destination',
          child: Text(
            detail.description.trim().isEmpty
                ? 'More information will be added soon.'
                : detail.description.trim(),
            style: theme.textTheme.bodyLarge?.copyWith(
              color: _ink.withValues(alpha: .76),
              height: 1.62,
            ),
          ),
        ),
        if (!detail.isActivity) ...[
          const SizedBox(height: 18),
          _DestinationFacts(detail: detail),
        ],
        const SizedBox(height: 18),
        _PremiumSection(
          icon:
              detail.isActivity
                  ? Icons.location_on_outlined
                  : Icons.explore_outlined,
          eyebrow:
              detail.isActivity
                  ? 'WHERE TO EXPERIENCE IT'
                  : 'WHAT TO EXPERIENCE',
          title:
              detail.isActivity
                  ? 'Destinations for ${detail.name}'
                  : 'Activities in ${detail.name}',
          child:
              related.isEmpty
                  ? Text(
                    detail.isActivity
                        ? 'No destinations have been connected to this activity yet.'
                        : 'No activities have been connected to this destination yet.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: _ink.withValues(alpha: .58),
                    ),
                  )
                  : Column(
                    children: [
                      for (var index = 0; index < related.length; index++) ...[
                        _RelatedCard(
                          item: related[index],
                          onTap: () => onOpenRelated(related[index]),
                        ),
                        if (index != related.length - 1)
                          const SizedBox(height: 11),
                      ],
                    ],
                  ),
        ),
        const SizedBox(height: 18),
        _PremiumSection(
          icon: Icons.route_outlined,
          eyebrow: 'MATCHING SAFARIS',
          title:
              detail.isActivity
                  ? 'Tours featuring ${detail.name}'
                  : 'Tours visiting ${detail.name}',
          child:
              data.tours.items.isEmpty
                  ? Text(
                    'There are no published tours connected to this ${detail.isActivity ? 'activity' : 'destination'} yet.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: _ink.withValues(alpha: .58),
                    ),
                  )
                  : Column(
                    children: [
                      for (
                        var index = 0;
                        index < data.tours.items.length;
                        index++
                      ) ...[
                        _TourCard(
                          tour: data.tours.items[index],
                          onTap: () => onOpenTour(data.tours.items[index]),
                        ),
                        if (index != data.tours.items.length - 1)
                          const SizedBox(height: 12),
                      ],
                      if (data.tours.total > data.tours.items.length) ...[
                        const SizedBox(height: 16),
                        _ViewAllButton(
                          label:
                              'View All ${data.tours.total} Matching Safaris',
                          icon: Icons.route_rounded,
                          onPressed: onViewAllTours,
                        ),
                      ],
                    ],
                  ),
        ),
        if (providers.isNotEmpty) ...[
          const SizedBox(height: 18),
          _PremiumSection(
            icon: Icons.verified_user_outlined,
            eyebrow: 'LOCAL EXPERTS',
            title:
                detail.isActivity
                    ? 'Guides & operators for this activity'
                    : 'Tour operators for this destination',
            child: Column(
              children: [
                for (var index = 0; index < providers.length; index++) ...[
                  _ProviderCard(
                    member: providers[index],
                    onTap: () => onOpenProvider(providers[index]),
                  ),
                  if (index != providers.length - 1) const SizedBox(height: 11),
                ],
                if (data.providers.total > providers.length) ...[
                  const SizedBox(height: 16),
                  _ViewAllButton(
                    label:
                        'View All ${data.providers.total} Local Experts',
                    icon: Icons.groups_rounded,
                    onPressed: onViewAllProviders,
                  ),
                ],
              ],
            ),
          ),
        ],
        if (!detail.isActivity && detail.accommodations.isNotEmpty) ...[
          const SizedBox(height: 18),
          _PremiumSection(
            icon: Icons.hotel_outlined,
            eyebrow: 'PLACES TO STAY',
            title: 'Accommodation',
            child: Column(
              children: [
                for (
                  var index = 0;
                  index < detail.accommodations.length;
                  index++
                ) ...[
                  _AccommodationCard(
                    accommodation: detail.accommodations[index],
                    onTap: () => onOpenAccommodation(detail.accommodations[index]),
                  ),
                  if (index != detail.accommodations.length - 1)
                    const SizedBox(height: 11),
                ],
              ],
            ),
          ),
        ],
        const SizedBox(height: 8),
      ],
    );
  }
}


enum _DestinationProviderFilter {
  all,
  guides,
  operators,
}

class _DestinationSafarisPage extends StatefulWidget {
  const _DestinationSafarisPage({
    required this.destination,
    required this.onOpenTour,
  });

  final CatalogItem destination;
  final ValueChanged<OperatorTour> onOpenTour;

  @override
  State<_DestinationSafarisPage> createState() =>
      _DestinationSafarisPageState();
}

class _DestinationSafarisPageState extends State<_DestinationSafarisPage> {
  static const Color _background = Color(0xFFF4EEE1);
  static const Color _primary = Color(0xFF165B5D);
  static const int _pageSize = 20;

  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  final List<OperatorTour> _items = [];

  int _page = 1;
  int _total = 0;
  bool _hasMore = true;
  bool _loading = true;
  bool _loadingMore = false;
  String _sort = 'best_match';
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load(reset: true);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load({required bool reset}) async {
    if (reset) {
      setState(() {
        _loading = true;
        _error = null;
        _page = 1;
        _hasMore = true;
      });
    } else {
      if (_loadingMore || !_hasMore) {
        return;
      }
      setState(() => _loadingMore = true);
    }

    try {
      final result = await CatalogService.instance.fetchDestinationTours(
        slug: widget.destination.slug,
        page: reset ? 1 : _page + 1,
        perPage: _pageSize,
        query: _searchController.text,
        sort: _sort,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        if (reset) {
          _items
            ..clear()
            ..addAll(result.items);
        } else {
          _items.addAll(result.items);
        }

        _page = result.currentPage;
        _total = result.total;
        _hasMore = result.hasMore;
        _loading = false;
        _loadingMore = false;
        _error = null;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;
        _loadingMore = false;
        _error = error;
      });
    }
  }

  void _searchChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 450),
      () => _load(reset: true),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Matching Safaris',
          style: TextStyle(
            color: _primary,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 36),
        children: [
          Text(
            widget.destination.name,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: _primary,
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 5),
          Text(
            '$_total matching ${_total == 1 ? 'safari' : 'safaris'}',
          ),
          const SizedBox(height: 16),
          _SearchField(
            controller: _searchController,
            hint: 'Search safaris to this destination',
            onChanged: _searchChanged,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _sort,
            decoration: InputDecoration(
              labelText: 'Sort',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
            ),
            items: const [
              DropdownMenuItem(
                value: 'best_match',
                child: Text('Best Match'),
              ),
              DropdownMenuItem(
                value: 'newest',
                child: Text('Newest'),
              ),
              DropdownMenuItem(
                value: 'price_low',
                child: Text('Price: Low to High'),
              ),
              DropdownMenuItem(
                value: 'price_high',
                child: Text('Price: High to Low'),
              ),
            ],
            onChanged: (value) {
              if (value == null || value == _sort) {
                return;
              }

              setState(() => _sort = value);
              _load(reset: true);
            },
          ),
          const SizedBox(height: 20),
          if (_loading)
            const _PageLoader()
          else if (_error != null)
            _InlineError(onRetry: () => _load(reset: true))
          else if (_items.isEmpty)
            const _EmptySearchState(
              icon: Icons.route_outlined,
              title: 'No matching safaris',
              message: 'Try another search.',
            )
          else ...[
            for (var index = 0; index < _items.length; index++) ...[
              _TourCard(
                tour: _items[index],
                onTap: () => widget.onOpenTour(_items[index]),
              ),
              if (index != _items.length - 1)
                const SizedBox(height: 13),
            ],
            if (_hasMore) ...[
              const SizedBox(height: 18),
              _LoadMoreButton(
                shown: _items.length,
                total: _total,
                loading: _loadingMore,
                onPressed: () => _load(reset: false),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _DestinationExpertsPage extends StatefulWidget {
  const _DestinationExpertsPage({
    required this.destination,
    required this.onOpenProvider,
  });

  final CatalogItem destination;
  final ValueChanged<CommunityMember> onOpenProvider;

  @override
  State<_DestinationExpertsPage> createState() =>
      _DestinationExpertsPageState();
}

class _DestinationExpertsPageState extends State<_DestinationExpertsPage> {
  static const Color _background = Color(0xFFF4EEE1);
  static const Color _primary = Color(0xFF165B5D);
  static const int _pageSize = 20;

  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  final List<CommunityMember> _items = [];

  _DestinationProviderFilter _filter = _DestinationProviderFilter.all;
  int _page = 1;
  int _total = 0;
  bool _hasMore = true;
  bool _loading = true;
  bool _loadingMore = false;
  Object? _error;

  String get _type {
    switch (_filter) {
      case _DestinationProviderFilter.guides:
        return 'tourist_guide';
      case _DestinationProviderFilter.operators:
        return 'tour_operator';
      case _DestinationProviderFilter.all:
        return 'all';
    }
  }

  @override
  void initState() {
    super.initState();
    _load(reset: true);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load({required bool reset}) async {
    if (reset) {
      setState(() {
        _loading = true;
        _error = null;
        _page = 1;
        _hasMore = true;
      });
    } else {
      if (_loadingMore || !_hasMore) {
        return;
      }
      setState(() => _loadingMore = true);
    }

    try {
      final result = await CatalogService.instance.fetchDestinationProviders(
        slug: widget.destination.slug,
        page: reset ? 1 : _page + 1,
        perPage: _pageSize,
        query: _searchController.text,
        type: _type,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        if (reset) {
          _items
            ..clear()
            ..addAll(result.items);
        } else {
          _items.addAll(result.items);
        }

        _page = result.currentPage;
        _total = result.total;
        _hasMore = result.hasMore;
        _loading = false;
        _loadingMore = false;
        _error = null;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;
        _loadingMore = false;
        _error = error;
      });
    }
  }

  void _searchChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 450),
      () => _load(reset: true),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Local Experts',
          style: TextStyle(
            color: _primary,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 36),
        children: [
          Text(
            widget.destination.name,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: _primary,
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 5),
          Text(
            '$_total local ${_total == 1 ? 'expert' : 'experts'}',
          ),
          const SizedBox(height: 16),
          _SearchField(
            controller: _searchController,
            hint: 'Search guides and operators',
            onChanged: _searchChanged,
          ),
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterChip(
                  label: 'All',
                  selected: _filter == _DestinationProviderFilter.all,
                  onTap: () {
                    setState(() => _filter = _DestinationProviderFilter.all);
                    _load(reset: true);
                  },
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Guides',
                  selected: _filter == _DestinationProviderFilter.guides,
                  onTap: () {
                    setState(() => _filter = _DestinationProviderFilter.guides);
                    _load(reset: true);
                  },
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Operators',
                  selected: _filter == _DestinationProviderFilter.operators,
                  onTap: () {
                    setState(
                      () => _filter = _DestinationProviderFilter.operators,
                    );
                    _load(reset: true);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (_loading)
            const _PageLoader()
          else if (_error != null)
            _InlineError(onRetry: () => _load(reset: true))
          else if (_items.isEmpty)
            const _EmptySearchState(
              icon: Icons.groups_outlined,
              title: 'No local experts found',
              message: 'Try another search or provider filter.',
            )
          else ...[
            for (var index = 0; index < _items.length; index++) ...[
              _ProviderCard(
                member: _items[index],
                onTap: () => widget.onOpenProvider(_items[index]),
              ),
              if (index != _items.length - 1)
                const SizedBox(height: 11),
            ],
            if (_hasMore) ...[
              const SizedBox(height: 18),
              _LoadMoreButton(
                shown: _items.length,
                total: _total,
                loading: _loadingMore,
                onPressed: () => _load(reset: false),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _ViewAllButton extends StatelessWidget {
  const _ViewAllButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  static const Color _primary = Color(0xFF165B5D);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 51,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: _primary,
          side: BorderSide(
            color: _primary.withValues(alpha: .22),
          ),
          shape: const StadiumBorder(),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 5),
            const Icon(Icons.arrow_forward_rounded, size: 17),
          ],
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.hint,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(
          Icons.search_rounded,
          color: Color(0xFF165B5D),
        ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  static const Color _primary = Color(0xFF165B5D);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? _primary : Colors.white,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 15,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? _primary
                  : _primary.withValues(alpha: .12),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : _primary,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class _LoadMoreButton extends StatelessWidget {
  const _LoadMoreButton({
    required this.shown,
    required this.total,
    required this.loading,
    required this.onPressed,
  });

  final int shown;
  final int total;
  final bool loading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final remaining = total - shown;
    final next = remaining > 20 ? 20 : remaining;

    return Column(
      children: [
        Text(
          'Showing $shown of $total',
          style: const TextStyle(
            color: Color(0xFF165B5D),
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 9),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: FilledButton.icon(
            onPressed: loading ? null : onPressed,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF165B5D),
              shape: const StadiumBorder(),
            ),
            icon: loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.expand_more_rounded),
            label: Text(
              loading ? 'Loading...' : 'Load $next More',
              style: const TextStyle(
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptySearchState extends StatelessWidget {
  const _EmptySearchState({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 40,
            color: const Color(0xFF165B5D),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            message,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _PageLoader extends StatelessWidget {
  const _PageLoader();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 50),
      child: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({
    required this.onRetry,
  });

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return _ErrorBody(onRetry: onRetry);
  }
}


class _PremiumSection extends StatelessWidget {
  const _PremiumSection({
    required this.icon,
    required this.eyebrow,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String eyebrow;
  final String title;
  final Widget child;

  static const Color _primary = Color(0xFF165B5D);
  static const Color _secondary = Color(0xFFF46627);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: _primary.withValues(alpha: .08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _primary.withValues(alpha: .08),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: _primary, size: 21),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      eyebrow,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: _secondary,
                        fontWeight: FontWeight.w900,
                        letterSpacing: .8,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: const Color(0xFF17211F),
                        fontWeight: FontWeight.w900,
                        letterSpacing: -.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _DestinationFacts extends StatelessWidget {
  const _DestinationFacts({required this.detail});

  final CatalogItem detail;

  @override
  Widget build(BuildContext context) {
    final facts = <({IconData icon, String label, String value})>[
      if (detail.bestMonthsToVisit?.trim().isNotEmpty == true)
        (
          icon: Icons.calendar_month_outlined,
          label: 'Best time',
          value: detail.bestMonthsToVisit!,
        ),
      if (detail.recommendedTripLength?.trim().isNotEmpty == true)
        (
          icon: Icons.schedule_outlined,
          label: 'Trip length',
          value: detail.recommendedTripLength!,
        ),
      if (detail.difficulty?.trim().isNotEmpty == true)
        (
          icon: Icons.terrain_outlined,
          label: 'Difficulty',
          value: detail.difficulty!,
        ),
    ];

    if (facts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Row(
      children: [
        for (var index = 0; index < facts.length; index++) ...[
          Expanded(
            child: _FactCard(
              icon: facts[index].icon,
              label: facts[index].label,
              value: facts[index].value,
            ),
          ),
          if (index != facts.length - 1) const SizedBox(width: 10),
        ],
      ],
    );
  }
}

class _FactCard extends StatelessWidget {
  const _FactCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFF165B5D).withValues(alpha: .08),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF165B5D), size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: theme.textTheme.labelSmall?.copyWith(
              color: const Color(0xFF17211F).withValues(alpha: .52),
            ),
          ),
        ],
      ),
    );
  }
}

class _RelatedCard extends StatelessWidget {
  const _RelatedCard({required this.item, required this.onTap});

  final CatalogItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: .12),
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 106,
          child: Row(
            children: [
              SizedBox(
                width: 106,
                child: _BorderedImage(
                  imageUrl: item.imageUrl,
                  fallbackIcon:
                      item.isActivity
                          ? Icons.explore_outlined
                          : Icons.landscape_outlined,
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        item.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      if (item.tagline?.trim().isNotEmpty == true) ...[
                        const SizedBox(height: 5),
                        Text(
                          item.tagline!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(
                            color: const Color(
                              0xFF17211F,
                            ).withValues(alpha: .56),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(right: 10),
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF165B5D),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TourCard extends StatelessWidget {
  const _TourCard({required this.tour, required this.onTap});

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
          height: 150,
          child: Row(
            children: [
              SizedBox(
                width: 122,
                height: 122,
                child: _BorderedImage(
                  imageUrl: tour.imageUrl,
                  fallbackIcon: Icons.landscape_outlined,
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(13, 12, 10, 11),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (tour.countryNames.isNotEmpty) ...[
                        Container(
                          constraints: const BoxConstraints(maxWidth: 210),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: tour.isMultiCountry
                                ? const Color(0xFFF46627)
                                    .withValues(alpha: .12)
                                : const Color(0xFF165B5D)
                                    .withValues(alpha: .08),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            tour.isMultiCountry
                                ? '${tour.countryCount} COUNTRIES • ${tour.countryLabel.toUpperCase()}'
                                : tour.countryLabel.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: tour.isMultiCountry
                                  ? const Color(0xFFF46627)
                                  : const Color(0xFF165B5D),
                              fontSize: 9.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: .3,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                      ],
                      Text(
                        tour.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          height: 1.16,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${tour.isGuideLed ? 'Guided by' : 'Offered by'} '
                        '${tour.operatorName.isEmpty ? (tour.isGuideLed ? 'Local Safari Guide' : 'Safari Operator') : tour.operatorName}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: _primary,
                          fontWeight: FontWeight.w800,
                        ),
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
                                ).withValues(alpha: .56),
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
            ],
          ),
        ),
      ),
    );
  }
}

class _ProviderCard extends StatelessWidget {
  const _ProviderCard({required this.member, required this.onTap});

  final CommunityMember member;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final fallback = Container(
      alignment: Alignment.center,
      color: const Color(0xFFE7F0ED),
      child: Icon(
        member.isGuide ? Icons.person_outline_rounded : Icons.business_outlined,
        color: const Color(0xFF165B5D),
      ),
    );

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF165B5D).withValues(alpha: .08),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: member.isGuide ? BoxShape.circle : BoxShape.rectangle,
                  borderRadius:
                      member.isGuide ? null : BorderRadius.circular(13),
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: .08),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius:
                      member.isGuide
                          ? BorderRadius.circular(999)
                          : BorderRadius.circular(10),
                  child:
                      member.profilePhotoUrl.isEmpty
                          ? fallback
                          : Image.network(
                            member.profilePhotoUrl,
                            fit: member.isGuide ? BoxFit.cover : BoxFit.contain,
                            errorBuilder: (_, __, ___) => fallback,
                          ),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            member.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        if (member.isVerified) ...[
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.verified_rounded,
                            size: 17,
                            color: Color(0xFF165B5D),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      member.roleLabel,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF165B5D),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (member.ratingCount > 0) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: Color(0xFFF46627),
                            size: 15,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '${member.ratingAverage.toStringAsFixed(1)} (${member.ratingCount})',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFF165B5D)),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccommodationCard extends StatelessWidget {
  const _AccommodationCard({required this.accommodation, required this.onTap});

  final Accommodation accommodation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: const Color(0xFFF8F7F2),
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F7F2),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFF165B5D).withValues(alpha: .07),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            height: 72,
            child: _BorderedImage(
              imageUrl: accommodation.imageUrl,
              fallbackIcon: Icons.hotel_outlined,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  accommodation.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (accommodation.location.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    accommodation.location,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
                const SizedBox(height: 5),
                Text(
                  accommodation.formattedPrice,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: const Color(0xFF165B5D),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: Color(0xFF165B5D)),
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
      child: Icon(fallbackIcon, color: const Color(0xFF165B5D), size: 30),
    );

    final image =
        imageUrl.isEmpty
            ? fallback
            : Image.network(
              imageUrl,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => fallback,
            );

    return Padding(
      padding: const EdgeInsets.all(8),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .08),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(borderRadius: BorderRadius.circular(14), child: image),
      ),
    );
  }
}

class _LoadingBody extends StatelessWidget {
  const _LoadingBody();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < 4; index++) ...[
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .68),
              borderRadius: BorderRadius.circular(24),
            ),
          ),
          if (index != 3) const SizedBox(height: 14),
        ],
      ],
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            size: 42,
            color: Color(0xFFF46627),
          ),
          const SizedBox(height: 12),
          const Text(
            'This page could not be loaded',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17),
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
