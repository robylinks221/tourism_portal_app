import 'dart:async';

import 'package:flutter/material.dart';

import '../models/operator_management.dart';
import '../services/catalog_service.dart';
import '../pages/tour_details_page.dart';
import 'app_ui.dart';

class MultiCountrySafarisSection extends StatefulWidget {
  const MultiCountrySafarisSection({
    super.key,
    this.isGuest = false,
  });

  final bool isGuest;

  @override
  State<MultiCountrySafarisSection> createState() =>
      _MultiCountrySafarisSectionState();
}

class _MultiCountrySafarisSectionState
    extends State<MultiCountrySafarisSection> {
  late Future<MultiCountryTourPage> _preview;

  @override
  void initState() {
    super.initState();
    _preview = _load();
  }

  Future<MultiCountryTourPage> _load() {
    return CatalogService.instance.fetchMultiCountryTours(
      page: 1,
      perPage: 6,
    );
  }

  void _retry() {
    setState(() {
      _preview = _load();
    });
  }

  Future<void> _openTour(OperatorTour tour) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => TourDetailsPage(tour: tour),
      ),
    );
  }

  Future<void> _viewAll() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => const _AllMultiCountrySafarisPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<MultiCountryTourPage>(
      future: _preview,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _SectionLoading();
        }

        if (snapshot.hasError) {
          return _SectionError(onRetry: _retry);
        }

        final page = snapshot.data!;
        if (page.items.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Header(
              total: page.total,
              onViewAll: _viewAll,
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 282,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: page.items.length,
                separatorBuilder: (_, __) => const SizedBox(width: 13),
                itemBuilder: (context, index) {
                  final tour = page.items[index];
                  return _PremiumTourCard(
                    tour: tour,
                    onTap: () => _openTour(tour),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.total,
    required this.onViewAll,
  });

  final int total;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const Expanded(
          child: AppSectionHeader(
            title: 'Multi-Country Safaris',
            subtitle:
                'Cross borders and discover more than one East African country in a single journey.',
          ),
        ),
        const SizedBox(width: 10),
        InkWell(
          onTap: onViewAll,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 7, 0, 5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'View All',
                      style: TextStyle(
                        color: Color(0xFF165B5D),
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(width: 2),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: Color(0xFF165B5D),
                      size: 18,
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Container(
                  width: 42,
                  height: 2,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF46627),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PremiumTourCard extends StatelessWidget {
  const _PremiumTourCard({
    required this.tour,
    required this.onTap,
  });

  final OperatorTour tour;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: 276,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        clipBehavior: Clip.antiAlias,
        elevation: 5,
        shadowColor: Colors.black.withValues(alpha: .13),
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _TourImage(url: tour.imageUrl),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0x00000000),
                            Color(0x10000000),
                            Color(0xB8000000),
                          ],
                          stops: [0, .55, 1],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 13,
                      right: 13,
                      bottom: 13,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: .18),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: .42),
                              ),
                            ),
                            child: Text(
                              tour.countryLabel.toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: .45,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            tour.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              height: 1.05,
                              letterSpacing: -.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 13),
                child: Row(
                  children: [
                    const Icon(
                      Icons.schedule_rounded,
                      size: 16,
                      color: Color(0xFFF46627),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '${tour.days} ${tour.days == 1 ? 'day' : 'days'}',
                      style: const TextStyle(
                        color: Color(0xFF53605D),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _price(tour),
                      style: const TextStyle(
                        color: Color(0xFF165B5D),
                        fontWeight: FontWeight.w900,
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

class _AllMultiCountrySafarisPage extends StatefulWidget {
  const _AllMultiCountrySafarisPage();

  @override
  State<_AllMultiCountrySafarisPage> createState() =>
      _AllMultiCountrySafarisPageState();
}

class _AllMultiCountrySafarisPageState
    extends State<_AllMultiCountrySafarisPage> {
  static const _background = Color(0xFFF4EEE1);
  static const _primary = Color(0xFF165B5D);

  final _search = TextEditingController();
  Timer? _debounce;

  final List<OperatorTour> _items = [];

  int _page = 1;
  int _total = 0;
  bool _hasMore = true;
  bool _loading = true;
  bool _loadingMore = false;
  String _country = '';
  String _sort = 'best_match';
  Object? _error;

  static const _countries = [
    '',
    'Uganda',
    'Rwanda',
    'Kenya',
    'Tanzania',
  ];

  @override
  void initState() {
    super.initState();
    _load(reset: true);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
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
      final result = await CatalogService.instance.fetchMultiCountryTours(
        page: reset ? 1 : _page + 1,
        perPage: 20,
        query: _search.text,
        country: _country,
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

  Future<void> _openTour(OperatorTour tour) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => TourDetailsPage(tour: tour),
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
        title: const Text(
          'Multi-Country Safaris',
          style: TextStyle(
            color: _primary,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 38),
        children: [
          Text(
            'Explore East Africa',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: _primary,
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 5),
          Text(
            '$_total cross-border ${_total == 1 ? 'safari' : 'safaris'}',
          ),
          const SizedBox(height: 17),
          TextField(
            controller: _search,
            onChanged: _searchChanged,
            decoration: InputDecoration(
              hintText: 'Search multi-country safaris',
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: _primary,
              ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(999),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _country,
                  decoration: InputDecoration(
                    labelText: 'Country',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: _countries
                      .map(
                        (country) => DropdownMenuItem(
                          value: country,
                          child: Text(
                            country.isEmpty ? 'All countries' : country,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null || value == _country) return;
                    setState(() => _country = value);
                    _load(reset: true);
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<String>(
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
                      child: Text('Price Low'),
                    ),
                    DropdownMenuItem(
                      value: 'price_high',
                      child: Text('Price High'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value == null || value == _sort) return;
                    setState(() => _sort = value);
                    _load(reset: true);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 55),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            _SectionError(onRetry: () => _load(reset: true))
          else if (_items.isEmpty)
            const _EmptyState()
          else ...[
            for (var index = 0; index < _items.length; index++) ...[
              _ListTourCard(
                tour: _items[index],
                onTap: () => _openTour(_items[index]),
              ),
              if (index != _items.length - 1)
                const SizedBox(height: 13),
            ],
            if (_hasMore) ...[
              const SizedBox(height: 18),
              SizedBox(
                height: 51,
                child: FilledButton(
                  onPressed: _loadingMore
                      ? null
                      : () => _load(reset: false),
                  style: FilledButton.styleFrom(
                    backgroundColor: _primary,
                    shape: const StadiumBorder(),
                  ),
                  child: _loadingMore
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'Load More • Showing ${_items.length} of $_total',
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _ListTourCard extends StatelessWidget {
  const _ListTourCard({
    required this.tour,
    required this.onTap,
  });

  final OperatorTour tour;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 142,
          child: Row(
            children: [
              SizedBox(
                width: 126,
                height: 126,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: _TourImage(url: tour.imageUrl),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 12, 13, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF46627)
                              .withValues(alpha: .10),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          tour.countryLabel.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFFF46627),
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        tour.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF17211F),
                          fontWeight: FontWeight.w900,
                          height: 1.15,
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Text(
                            '${tour.days} ${tour.days == 1 ? 'day' : 'days'}',
                            style: const TextStyle(
                              color: Color(0xFF66716E),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            _price(tour),
                            style: const TextStyle(
                              color: Color(0xFF165B5D),
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

class _TourImage extends StatelessWidget {
  const _TourImage({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) {
      return const _ImageFallback();
    }

    return Image.network(
      url,
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => const _ImageFallback(),
    );
  }
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF487C79),
            Color(0xFF165B5D),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.route_outlined,
          color: Colors.white.withValues(alpha: .26),
          size: 42,
        ),
      ),
    );
  }
}

class _SectionLoading extends StatelessWidget {
  const _SectionLoading();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppSectionHeader(
          title: 'Multi-Country Safaris',
          subtitle:
              'Cross borders and discover more than one East African country in a single journey.',
        ),
        const SizedBox(height: 14),
        Container(
          height: 260,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .65),
            borderRadius: BorderRadius.circular(25),
          ),
        ),
      ],
    );
  }
}

class _SectionError extends StatelessWidget {
  const _SectionError({
    required this.onRetry,
  });

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          const Text(
            'Multi-country safaris could not be loaded.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF17211F),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: onRetry,
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.route_outlined,
            color: Color(0xFF165B5D),
            size: 42,
          ),
          SizedBox(height: 10),
          Text(
            'No multi-country safaris yet',
            style: TextStyle(
              color: Color(0xFF17211F),
              fontWeight: FontWeight.w900,
              fontSize: 17,
            ),
          ),
          SizedBox(height: 5),
          Text(
            'Tours with destinations in two or more countries will appear here automatically.',
            textAlign: TextAlign.center,
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
