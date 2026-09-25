import 'dart:async';

import 'package:flutter/material.dart';

import '../models/catalog_item.dart';
import '../models/community.dart';
import '../models/operator_management.dart';
import '../services/catalog_service.dart';
import '../widgets/provider_discovery_sections.dart';
import 'destination_details_page.dart';
import 'tour_details_page.dart';

class ActivityDetailsPage extends StatefulWidget {
  const ActivityDetailsPage({
    super.key,
    required this.item,
  });

  final CatalogItem item;

  @override
  State<ActivityDetailsPage> createState() => _ActivityDetailsPageState();
}

class _ActivityDetailsPageState extends State<ActivityDetailsPage> {
  static const Color _background = Color(0xFFF4EEE1);

  late Future<_ActivityPageData> _data;

  @override
  void initState() {
    super.initState();
    _data = _load();
  }

  Future<_ActivityPageData> _load() async {
    final detailFuture =
        CatalogService.instance.fetchActivity(widget.item.slug);

    final toursFuture = CatalogService.instance.fetchActivityTours(
      slug: widget.item.slug,
      page: 1,
      perPage: 6,
    );

    final providersFuture = CatalogService.instance.fetchActivityProviders(
      slug: widget.item.slug,
      page: 1,
      perPage: 6,
      type: 'all',
    );

    final detail = await detailFuture;
    final tours = await toursFuture;
    final providers = await providersFuture;

    return _ActivityPageData(
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
        builder: (_) => item.isActivity
            ? ActivityDetailsPage(item: item)
            : DestinationDetailsPage(item: item),
      ),
    );
  }

  Future<void> _openTour(OperatorTour tour) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => TourDetailsPage(tour: tour),
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

  Future<void> _viewAllTours(CatalogItem activity) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => _MatchingSafarisPage(
          activity: activity,
          onOpenTour: _openTour,
        ),
      ),
    );
  }

  Future<void> _viewAllProviders(CatalogItem activity) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => _LocalExpertsPage(
          activity: activity,
          onOpenProvider: _openProvider,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: FutureBuilder<_ActivityPageData>(
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
                      child: snapshot.connectionState != ConnectionState.done
                          ? const _LoadingBody()
                          : snapshot.hasError
                              ? _ErrorBody(onRetry: _retry)
                              : _Content(
                                  data: snapshot.data!,
                                  onOpenRelated: _openRelated,
                                  onOpenTour: _openTour,
                                  onOpenProvider: _openProvider,
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

class _ActivityPageData {
  const _ActivityPageData({
    required this.detail,
    required this.tours,
    required this.providers,
  });

  final CatalogItem detail;
  final ActivityTourPage tours;
  final ActivityProviderPage providers;
}

class _Hero extends StatelessWidget {
  const _Hero({
    required this.item,
    required this.onBack,
  });

  final CatalogItem item;
  final VoidCallback onBack;

  static const Color _primary = Color(0xFF165B5D);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final place = [
      item.location,
      item.country,
    ]
        .where(
          (value) => value != null && value.trim().isNotEmpty,
        )
        .join(', ');

    final fallback = Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF165B5D),
            Color(0xFF0D3D3F),
          ],
        ),
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.explore_outlined,
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
                  child: const Text(
                    'SAFARI ACTIVITY',
                    style: TextStyle(
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
    required this.onViewAllTours,
    required this.onViewAllProviders,
  });

  final _ActivityPageData data;
  final ValueChanged<CatalogItem> onOpenRelated;
  final ValueChanged<OperatorTour> onOpenTour;
  final ValueChanged<CommunityMember> onOpenProvider;
  final VoidCallback onViewAllTours;
  final VoidCallback onViewAllProviders;

  static const Color _primary = Color(0xFF165B5D);
  static const Color _ink = Color(0xFF17211F);

  @override
  Widget build(BuildContext context) {
    final detail = data.detail;
    final theme = Theme.of(context);
    final related = detail.destinations;

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
          title: 'About this activity',
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
        const SizedBox(height: 18),
        _PremiumSection(
          icon: Icons.location_on_outlined,
          eyebrow: 'WHERE TO EXPERIENCE IT',
          title: 'Destinations for ${detail.name}',
          child: related.isEmpty
              ? Text(
                  'No destinations have been connected to this activity yet.',
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
          title: 'Tours featuring ${detail.name}',
          child: data.tours.items.isEmpty
              ? Text(
                  'There are no published tours connected to this activity yet.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: _ink.withValues(alpha: .58),
                  ),
                )
              : Column(
                  children: [
                    for (var index = 0;
                        index < data.tours.items.length;
                        index++) ...[
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
        if (data.providers.total > 0) ...[
          const SizedBox(height: 18),
          _PremiumSection(
            icon: Icons.verified_user_outlined,
            eyebrow: 'LOCAL EXPERTS',
            title: 'Guides & operators for this activity',
            child: Column(
              children: [
                for (var index = 0;
                    index < data.providers.items.length;
                    index++) ...[
                  _ProviderCard(
                    member: data.providers.items[index],
                    onTap: () =>
                        onOpenProvider(data.providers.items[index]),
                  ),
                  if (index != data.providers.items.length - 1)
                    const SizedBox(height: 11),
                ],
                if (data.providers.total > data.providers.items.length) ...[
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
        const SizedBox(height: 8),
      ],
    );
  }
}

class _MatchingSafarisPage extends StatefulWidget {
  const _MatchingSafarisPage({
    required this.activity,
    required this.onOpenTour,
  });

  final CatalogItem activity;
  final ValueChanged<OperatorTour> onOpenTour;

  @override
  State<_MatchingSafarisPage> createState() => _MatchingSafarisPageState();
}

class _MatchingSafarisPageState extends State<_MatchingSafarisPage> {
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
      if (_loadingMore || !_hasMore) return;
      setState(() => _loadingMore = true);
    }

    try {
      final result = await CatalogService.instance.fetchActivityTours(
        slug: widget.activity.slug,
        page: reset ? 1 : _page + 1,
        perPage: _pageSize,
        query: _searchController.text,
        sort: _sort,
      );

      if (!mounted) return;

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
      if (!mounted) return;
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
            widget.activity.name,
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
            hint: 'Search matching safaris',
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
              if (value == null || value == _sort) return;
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

enum _ProviderFilter {
  all,
  guides,
  operators,
}

class _LocalExpertsPage extends StatefulWidget {
  const _LocalExpertsPage({
    required this.activity,
    required this.onOpenProvider,
  });

  final CatalogItem activity;
  final ValueChanged<CommunityMember> onOpenProvider;

  @override
  State<_LocalExpertsPage> createState() => _LocalExpertsPageState();
}

class _LocalExpertsPageState extends State<_LocalExpertsPage> {
  static const Color _background = Color(0xFFF4EEE1);
  static const Color _primary = Color(0xFF165B5D);
  static const int _pageSize = 20;

  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  final List<CommunityMember> _items = [];

  _ProviderFilter _filter = _ProviderFilter.all;
  int _page = 1;
  int _total = 0;
  bool _hasMore = true;
  bool _loading = true;
  bool _loadingMore = false;
  Object? _error;

  String get _type {
    switch (_filter) {
      case _ProviderFilter.guides:
        return 'tourist_guide';
      case _ProviderFilter.operators:
        return 'tour_operator';
      case _ProviderFilter.all:
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
      if (_loadingMore || !_hasMore) return;
      setState(() => _loadingMore = true);
    }

    try {
      final result = await CatalogService.instance.fetchActivityProviders(
        slug: widget.activity.slug,
        page: reset ? 1 : _page + 1,
        perPage: _pageSize,
        query: _searchController.text,
        type: _type,
      );

      if (!mounted) return;

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
      if (!mounted) return;
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
            widget.activity.name,
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
                  selected: _filter == _ProviderFilter.all,
                  onTap: () {
                    setState(() => _filter = _ProviderFilter.all);
                    _load(reset: true);
                  },
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Guides',
                  selected: _filter == _ProviderFilter.guides,
                  onTap: () {
                    setState(() => _filter = _ProviderFilter.guides);
                    _load(reset: true);
                  },
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Operators',
                  selected: _filter == _ProviderFilter.operators,
                  onTap: () {
                    setState(() => _filter = _ProviderFilter.operators);
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
        border: Border.all(
          color: _primary.withValues(alpha: .08),
        ),
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
                child: Icon(
                  icon,
                  color: _primary,
                  size: 21,
                ),
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

class _RelatedCard extends StatelessWidget {
  const _RelatedCard({
    required this.item,
    required this.onTap,
  });

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
                  fallbackIcon: Icons.landscape_outlined,
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
                        style:
                            Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w900,
                                ),
                      ),
                      if (item.tagline?.trim().isNotEmpty == true) ...[
                        const SizedBox(height: 5),
                        Text(
                          item.tagline!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color: const Color(0xFF17211F)
                                    .withValues(alpha: .56),
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
  const _TourCard({
    required this.tour,
    required this.onTap,
  });

  final OperatorTour tour;
  final VoidCallback onTap;

  static const Color _primary = Color(0xFF165B5D);
  static const Color _secondary = Color(0xFFF46627);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final destination = tour.destinationNames.isEmpty
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
                                color: const Color(0xFF17211F)
                                    .withValues(alpha: .56),
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
  const _ProviderCard({
    required this.member,
    required this.onTap,
  });

  final CommunityMember member;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final fallback = Container(
      alignment: Alignment.center,
      color: const Color(0xFFE7F0ED),
      child: Icon(
        member.isGuide
            ? Icons.person_outline_rounded
            : Icons.business_outlined,
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
                  shape:
                      member.isGuide ? BoxShape.circle : BoxShape.rectangle,
                  borderRadius:
                      member.isGuide ? null : BorderRadius.circular(13),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: .08),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: member.isGuide
                      ? BorderRadius.circular(999)
                      : BorderRadius.circular(10),
                  child: member.profilePhotoUrl.isEmpty
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
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF165B5D),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BorderedImage extends StatelessWidget {
  const _BorderedImage({
    required this.imageUrl,
    required this.fallbackIcon,
  });

  final String imageUrl;
  final IconData fallbackIcon;

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      color: const Color(0xFFE4EFEC),
      alignment: Alignment.center,
      child: Icon(
        fallbackIcon,
        color: const Color(0xFF165B5D),
        size: 30,
      ),
    );

    final image = imageUrl.isEmpty
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
          border: Border.all(
            color: Colors.white,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .08),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: image,
        ),
      ),
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
  const _ErrorBody({
    required this.onRetry,
  });

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
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 17,
            ),
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
  final amount = tour.price == tour.price.roundToDouble()
      ? tour.price.toStringAsFixed(0)
      : tour.price.toStringAsFixed(2);

  return '${tour.currency.isEmpty ? 'USD' : tour.currency} $amount';
}
