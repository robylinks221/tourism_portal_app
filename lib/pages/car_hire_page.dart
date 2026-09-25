import 'dart:async';

import 'package:flutter/material.dart';

import '../models/community.dart';
import '../models/operator_management.dart';
import '../services/community_service.dart';
import '../services/auth_service.dart';
import '../services/operator_offerings_service.dart';
import '../widgets/provider_discovery_sections.dart';
import 'car_hire_booking_page.dart';

enum _CarHireSort {
  latest,
  priceLowHigh,
  priceHighLow,
}

class CarHirePage extends StatefulWidget {
  const CarHirePage({
    super.key,
    this.vehicles = const <CarHireVehicle>[],
    this.initialVehicleId,
    this.initialQuery = '',
  });

  final List<CarHireVehicle> vehicles;
  final int? initialVehicleId;
  final String initialQuery;

  @override
  State<CarHirePage> createState() => _CarHirePageState();
}

class _CarHirePageState extends State<CarHirePage> {
  static const _background = Color(0xFFF4EEE1);
  static const _primary = Color(0xFF165B5D);

  late final TextEditingController _searchController;
  final _scrollController = ScrollController();
  Timer? _debounce;

  final List<CarHireVehicle> _vehicles = [];
  List<CommunityMember> _providers = const [];

  bool _loading = true;
  bool _loadingMore = false;
  String? _error;
  int _page = 1;
  int _total = 0;
  bool _hasMore = false;

  late String _query;
  String _transmission = 'All';
  String _fuelType = 'All';
  int _minimumSeats = 0;
  _CarHireSort _sort = _CarHireSort.latest;

  @override
  void initState() {
    super.initState();
    _query = widget.initialQuery.trim();
    _searchController = TextEditingController(
      text: widget.initialQuery.trim(),
    );
    _scrollController.addListener(_handleScroll);
    _loadProviders();
    _load(reset: true);

    final initialId = widget.initialVehicleId;
    if (initialId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        for (final vehicle in widget.vehicles) {
          if (vehicle.id == initialId && mounted) {
            _openVehicle(vehicle);
            break;
          }
        }
      });
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    super.dispose();
  }

  Future<void> _loadProviders() async {
    try {
      final providers = await CommunityService.instance.fetchMembers();
      if (mounted) setState(() => _providers = providers);
    } catch (_) {}
  }

  void _handleScroll() {
    if (!_hasMore || _loading || _loadingMore) return;
    if (_scrollController.position.extentAfter < 650) _loadMore();
  }

  Future<void> _load({required bool reset}) async {
    if (reset) {
      setState(() {
        _loading = true;
        _error = null;
        _page = 1;
      });
    }

    try {
      final result = await OperatorOfferingsService.instance.fetchVehicles(
        page: 1,
        perPage: 20,
        query: _query,
        transmission: _transmission,
        fuelType: _fuelType,
        minimumSeats: _minimumSeats,
        sort: _sortParameter,
      );

      if (!mounted) return;

      setState(() {
        _vehicles
          ..clear()
          ..addAll(result.vehicles);
        _page = result.currentPage;
        _total = result.total;
        _hasMore = result.hasMore;
        _loading = false;
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.toString().replaceFirst('ApiException: ', '');
      });
    }
  }

  Future<void> _loadMore() async {
    if (!_hasMore || _loadingMore) return;
    setState(() => _loadingMore = true);

    try {
      final result = await OperatorOfferingsService.instance.fetchVehicles(
        page: _page + 1,
        perPage: 20,
        query: _query,
        transmission: _transmission,
        fuelType: _fuelType,
        minimumSeats: _minimumSeats,
        sort: _sortParameter,
      );

      if (!mounted) return;
      final ids = _vehicles.map((item) => item.id).toSet();

      setState(() {
        _vehicles.addAll(
          result.vehicles.where((item) => !ids.contains(item.id)),
        );
        _page = result.currentPage;
        _total = result.total;
        _hasMore = result.hasMore;
        _loadingMore = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  void _onSearch(String value) {
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), () {
      if (!mounted) return;
      _query = value.trim();
      _load(reset: true);
    });
  }

  void _setTransmission(String value) {
    if (_transmission == value) return;
    setState(() => _transmission = value);
    _load(reset: true);
  }

  void _setSeats(int value) {
    if (_minimumSeats == value) return;
    setState(() => _minimumSeats = value);
    _load(reset: true);
  }

  void _setFuelType(String value) {
    if (_fuelType == value) return;
    setState(() => _fuelType = value);
    _load(reset: true);
  }

  void _setSort(_CarHireSort value) {
    if (_sort == value) return;
    setState(() => _sort = value);
    _load(reset: true);
  }

  String get _sortParameter {
    switch (_sort) {
      case _CarHireSort.priceLowHigh:
        return 'price_low_high';
      case _CarHireSort.priceHighLow:
        return 'price_high_low';
      case _CarHireSort.latest:
        return 'latest';
    }
  }

  String get _sortLabel {
    switch (_sort) {
      case _CarHireSort.priceLowHigh:
        return 'Price: Low to High';
      case _CarHireSort.priceHighLow:
        return 'Price: High to Low';
      case _CarHireSort.latest:
        return 'Latest';
    }
  }

  Future<void> _showSortSheet() async {
    final selected = await showModalBottomSheet<_CarHireSort>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.fromLTRB(
              18,
              10,
              18,
              18,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD6DCD8),
                    borderRadius:
                        BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 16),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Sort Vehicles',
                    style: TextStyle(
                      color: _primary,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                _CarSortOption(
                  title: 'Latest',
                  selected: _sort == _CarHireSort.latest,
                  onTap: () => Navigator.pop(
                    context,
                    _CarHireSort.latest,
                  ),
                ),
                _CarSortOption(
                  title: 'Price: Low to High',
                  selected:
                      _sort == _CarHireSort.priceLowHigh,
                  onTap: () => Navigator.pop(
                    context,
                    _CarHireSort.priceLowHigh,
                  ),
                ),
                _CarSortOption(
                  title: 'Price: High to Low',
                  selected:
                      _sort == _CarHireSort.priceHighLow,
                  onTap: () => Navigator.pop(
                    context,
                    _CarHireSort.priceHighLow,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selected != null && mounted) {
      _setSort(selected);
    }
  }

  int get _activeFilterCount {
    var count = 0;
    if (_transmission != 'All') count++;
    if (_fuelType != 'All') count++;
    if (_minimumSeats > 0) count++;
    return count;
  }

  Future<void> _showFilterSheet() async {
    var transmission = _transmission;
    var fuelType = _fuelType;
    var minimumSeats = _minimumSeats;

    final result = await showModalBottomSheet<
        ({String transmission, String fuelType, int minimumSeats})>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              top: false,
              child: Container(
                margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                padding: EdgeInsets.fromLTRB(
                  20,
                  12,
                  20,
                  20 + MediaQuery.viewInsetsOf(context).bottom,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(32),
                    bottom: Radius.circular(32),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 42,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFD8DEDA),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Filter Vehicles',
                            style: TextStyle(
                              color: _primary,
                              fontSize: 21,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -.3,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setSheetState(() {
                              transmission = 'All';
                              fuelType = 'All';
                              minimumSeats = 0;
                            });
                          },
                          child: const Text(
                            'Clear',
                            style: TextStyle(
                              color: Color(0xFFF46627),
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Choose only what matters for your trip.',
                      style: TextStyle(
                        color: Color(0xFF6B7572),
                        height: 1.4,
                      ),
                    ),

                    const SizedBox(height: 22),

                    const _FilterSectionTitle(title: 'Transmission'),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _SheetChoice(
                          label: 'Any',
                          selected: transmission == 'All',
                          onTap: () => setSheetState(
                            () => transmission = 'All',
                          ),
                        ),
                        _SheetChoice(
                          label: 'Automatic',
                          selected:
                              transmission.toLowerCase() == 'automatic',
                          onTap: () => setSheetState(
                            () => transmission = 'Automatic',
                          ),
                        ),
                        _SheetChoice(
                          label: 'Manual',
                          selected:
                              transmission.toLowerCase() == 'manual',
                          onTap: () => setSheetState(
                            () => transmission = 'Manual',
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 22),

                    const _FilterSectionTitle(title: 'Seats'),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _SheetChoice(
                          label: 'Any',
                          selected: minimumSeats == 0,
                          onTap: () => setSheetState(
                            () => minimumSeats = 0,
                          ),
                          accent: true,
                        ),
                        _SheetChoice(
                          label: '5+ Seats',
                          selected: minimumSeats == 5,
                          onTap: () => setSheetState(
                            () => minimumSeats = 5,
                          ),
                          accent: true,
                        ),
                        _SheetChoice(
                          label: '7+ Seats',
                          selected: minimumSeats == 7,
                          onTap: () => setSheetState(
                            () => minimumSeats = 7,
                          ),
                          accent: true,
                        ),
                        _SheetChoice(
                          label: '9+ Seats',
                          selected: minimumSeats == 9,
                          onTap: () => setSheetState(
                            () => minimumSeats = 9,
                          ),
                          accent: true,
                        ),
                      ],
                    ),

                    const SizedBox(height: 22),

                    const _FilterSectionTitle(title: 'Fuel Type'),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _SheetChoice(
                          label: 'Any',
                          selected: fuelType == 'All',
                          onTap: () => setSheetState(
                            () => fuelType = 'All',
                          ),
                        ),
                        _SheetChoice(
                          label: 'Diesel',
                          selected: fuelType.toLowerCase() == 'diesel',
                          onTap: () => setSheetState(
                            () => fuelType = 'Diesel',
                          ),
                        ),
                        _SheetChoice(
                          label: 'Petrol',
                          selected: fuelType.toLowerCase() == 'petrol',
                          onTap: () => setSheetState(
                            () => fuelType = 'Petrol',
                          ),
                        ),
                        _SheetChoice(
                          label: 'Hybrid',
                          selected: fuelType.toLowerCase() == 'hybrid',
                          onTap: () => setSheetState(
                            () => fuelType = 'Hybrid',
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 26),

                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: FilledButton(
                        onPressed: () {
                          Navigator.pop(
                            context,
                            (
                              transmission: transmission,
                              fuelType: fuelType,
                              minimumSeats: minimumSeats,
                            ),
                          );
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: _primary,
                          shape: const StadiumBorder(),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Apply Filters',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (result == null || !mounted) return;

    setState(() {
      _transmission = result.transmission;
      _fuelType = result.fuelType;
      _minimumSeats = result.minimumSeats;
    });

    _load(reset: true);
  }

  CommunityMember? _providerFor(CarHireVehicle vehicle) {
    if (vehicle.operatorId > 0) {
      for (final provider in _providers) {
        if (provider.id == vehicle.operatorId) return provider;
      }
    }

    final target = _normalise(vehicle.operatorName);
    for (final provider in _providers) {
      if (_normalise(provider.name) == target ||
          _normalise(provider.companyName) == target ||
          _normalise(provider.fullName) == target) {
        return provider;
      }
    }
    return null;
  }

  Future<void> _openProvider(CarHireVehicle vehicle) async {
    final provider = _providerFor(vehicle);

    if (provider == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Provider profile is still loading. Please try again.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => ProviderProfilePage(member: provider),
      ),
    );
  }

  Future<void> _openVehicle(CarHireVehicle vehicle) {
    return Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => CarHireVehicleDetailsPage(
          vehicle: vehicle,
          provider: _providerFor(vehicle),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        surfaceTintColor: _background,
        foregroundColor: const Color(0xFF17211F),
        elevation: 0,
        title: Text(
          'Safari Car Hire',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: -.3,
          ),
        ),
      ),
      body: RefreshIndicator(
        color: _primary,
        onRefresh: () => _load(reset: true),
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 54,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: _primary.withOpacity(.08),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(.045),
                            blurRadius: 14,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: _onSearch,
                        textInputAction: TextInputAction.search,
                        decoration: InputDecoration(
                          hintText: 'Search safari vehicles',
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            color: _primary,
                          ),
                          suffixIcon: _searchController.text.isEmpty
                              ? null
                              : IconButton(
                                  onPressed: () {
                                    _searchController.clear();
                                    _query = '';
                                    setState(() {});
                                    _load(reset: true);
                                  },
                                  icon: const Icon(Icons.close_rounded),
                                ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 16,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: _ActionFilterButton(
                            label: _activeFilterCount == 0
                                ? 'Filters'
                                : 'Filters ($_activeFilterCount)',
                            icon: Icons.tune_rounded,
                            active: _activeFilterCount > 0,
                            onTap: _showFilterSheet,
                          ),
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: _ActionFilterButton(
                            label: _sortLabel,
                            icon: Icons.swap_vert_rounded,
                            active: _sort != _CarHireSort.latest,
                            onTap: _showSortSheet,
                          ),
                        ),
                      ],
                    ),

                    if (_activeFilterCount > 0) ...[
                      const SizedBox(height: 11),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            if (_transmission != 'All')
                              _ActiveFilterPill(
                                label: _transmission,
                                onRemove: () {
                                  setState(() {
                                    _transmission = 'All';
                                  });
                                  _load(reset: true);
                                },
                              ),
                            if (_transmission != 'All')
                              const SizedBox(width: 7),

                            if (_minimumSeats > 0)
                              _ActiveFilterPill(
                                label: '$_minimumSeats+ seats',
                                accent: true,
                                onRemove: () {
                                  setState(() {
                                    _minimumSeats = 0;
                                  });
                                  _load(reset: true);
                                },
                              ),
                            if (_minimumSeats > 0)
                              const SizedBox(width: 7),

                            if (_fuelType != 'All')
                              _ActiveFilterPill(
                                label: _fuelType,
                                onRemove: () {
                                  setState(() {
                                    _fuelType = 'All';
                                  });
                                  _load(reset: true);
                                },
                              ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.fromLTRB(20, 4, 18, 14),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _loading
                            ? 'Finding vehicles...'
                            : '$_total ${_total == 1 ? 'vehicle' : 'vehicles'}',
                        style:
                            theme.textTheme.titleMedium?.copyWith(
                          color: _primary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: _showSortSheet,
                      borderRadius:
                          BorderRadius.circular(999),
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(
                          horizontal: 11,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                              BorderRadius.circular(999),
                          border: Border.all(
                            color:
                                _primary.withOpacity(.09),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.swap_vert_rounded,
                              color: _primary,
                              size: 17,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              _sortLabel,
                              style: theme
                                  .textTheme.labelSmall
                                  ?.copyWith(
                                color: _primary,
                                fontWeight:
                                    FontWeight.w900,
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
            if (_loading)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: CircularProgressIndicator(color: _primary),
                ),
              )
            else if (_error != null)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: () => _load(reset: true),
                          child: const Text('Try Again'),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else if (_vehicles.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Text(
                    'No matching vehicles',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
                sliver: SliverList.separated(
                  itemCount: _vehicles.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final vehicle = _vehicles[index];
                    return _VehicleListCard(
                      vehicle: vehicle,
                      onTap: () => _openVehicle(vehicle),
                      onProviderTap: () => _openProvider(vehicle),
                    );
                  },
                ),
              ),
            if (_loadingMore)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(bottom: 28),
                  child: Center(
                    child: CircularProgressIndicator(color: _primary),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

}


class _ActionFilterButton extends StatelessWidget {
  const _ActionFilterButton({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF165B5D);

    return Material(
      color: active
          ? primary.withOpacity(.075)
          : Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: active
                  ? primary.withOpacity(.24)
                  : primary.withOpacity(.08),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: primary,
                size: 18,
              ),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: primary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
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

class _ActiveFilterPill extends StatelessWidget {
  const _ActiveFilterPill({
    required this.label,
    required this.onRemove,
    this.accent = false,
  });

  final String label;
  final VoidCallback onRemove;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final color = accent
        ? const Color(0xFFF46627)
        : const Color(0xFF165B5D);

    return Container(
      padding: const EdgeInsets.fromLTRB(11, 7, 7, 7),
      decoration: BoxDecoration(
        color: color.withOpacity(.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11.5,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 5),
          InkWell(
            onTap: onRemove,
            customBorder: const CircleBorder(),
            child: Icon(
              Icons.close_rounded,
              size: 16,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterSectionTitle extends StatelessWidget {
  const _FilterSectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: const Color(0xFF17211F),
            fontWeight: FontWeight.w900,
          ),
    );
  }
}

class _SheetChoice extends StatelessWidget {
  const _SheetChoice({
    required this.label,
    required this.selected,
    required this.onTap,
    this.accent = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final color = accent
        ? const Color(0xFFF46627)
        : const Color(0xFF165B5D);

    return Material(
      color: selected
          ? color.withOpacity(accent ? .12 : .09)
          : const Color(0xFFF7F5F0),
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
                  ? color.withOpacity(.30)
                  : const Color(0xFF165B5D).withOpacity(.06),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected
                  ? color
                  : const Color(0xFF46514E),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _CarSortOption extends StatelessWidget {
  const _CarSortOption({
    required this.title,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      title: Text(
        title,
        style: TextStyle(
          color: selected
              ? const Color(0xFF165B5D)
              : const Color(0xFF27322F),
          fontWeight:
              selected ? FontWeight.w900 : FontWeight.w700,
        ),
      ),
      trailing: selected
          ? const Icon(
              Icons.check_circle_rounded,
              color: Color(0xFF165B5D),
            )
          : null,
    );
  }
}

class _VehicleListCard extends StatelessWidget {
  const _VehicleListCard({
    required this.vehicle,
    required this.onTap,
    required this.onProviderTap,
  });

  final CarHireVehicle vehicle;
  final VoidCallback onTap;
  final VoidCallback onProviderTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      height: 188,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        clipBehavior: Clip.antiAlias,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(.10),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 116,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(19),
                    child: _VehicleImage(imageUrl: vehicle.imageUrl),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vehicle.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: const Color(0xFF111816),
                          fontWeight: FontWeight.w900,
                          height: 1.12,
                        ),
                      ),
                      const SizedBox(height: 7),
                      InkWell(
                        onTap: onProviderTap,
                        borderRadius: BorderRadius.circular(10),
                        child: Row(
                          children: [
                            _ProviderLogo(vehicle: vehicle),
                            const SizedBox(width: 7),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          vehicle.operatorName.isEmpty
                                              ? 'Tour Operator'
                                              : vehicle.operatorName,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                            color: const Color(0xFF165B5D),
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ),
                                      if (vehicle.operatorIsVerified) ...[
                                        const SizedBox(width: 3),
                                        const Icon(
                                          Icons.verified_rounded,
                                          color: Color(0xFF165B5D),
                                          size: 15,
                                        ),
                                      ],
                                    ],
                                  ),
                                  Text(
                                    _joinedAgo(vehicle.operatorJoinedAt),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: const Color(0xFF7A837F),
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.airline_seat_recline_normal_rounded,
                            color: Color(0xFF165B5D),
                            size: 17,
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              _specLine(vehicle),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: const Color(0xFF737B78),
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: Color(0xFF165B5D),
                            size: 27,
                          ),
                        ],
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          const Icon(
                            Icons.schedule_rounded,
                            color: Color(0xFFF46627),
                            size: 17,
                          ),
                          const SizedBox(width: 5),
                          const Text(
                            'Per day',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const Spacer(),
                          Text(
                            _money(vehicle),
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: const Color(0xFF165B5D),
                              fontWeight: FontWeight.w900,
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
        ),
      ),
    );
  }
}

class _ProviderLogo extends StatelessWidget {
  const _ProviderLogo({required this.vehicle});

  final CarHireVehicle vehicle;

  @override
  Widget build(BuildContext context) {
    final url = vehicle.operatorLogoUrl;

    return Container(
      width: 31,
      height: 31,
      decoration: BoxDecoration(
        color: const Color(0xFFF4EEE1),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      clipBehavior: Clip.antiAlias,
      child: url.isEmpty
          ? Center(
              child: Text(
                vehicle.operatorName.trim().isEmpty
                    ? 'T'
                    : vehicle.operatorName.trim()[0].toUpperCase(),
                style: const TextStyle(
                  color: Color(0xFF165B5D),
                  fontWeight: FontWeight.w900,
                ),
              ),
            )
          : Image.network(
              url,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.business_rounded,
                color: Color(0xFF165B5D),
                size: 17,
              ),
            ),
    );
  }
}

class CarHireVehicleDetailsPage extends StatelessWidget {
  const CarHireVehicleDetailsPage({
    super.key,
    required this.vehicle,
    this.provider,
  });

  final CarHireVehicle vehicle;
  final CommunityMember? provider;

  static const Color _primary = Color(0xFF165B5D);
  static const Color _secondary = Color(0xFFF46627);
  static const Color _background = Color(0xFFF4EEE1);
  static const Color _ink = Color(0xFF17211F);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUser = AuthService.instance.currentUser;
    final isOwner =
        currentUser != null &&
        vehicle.operatorId > 0 &&
        currentUser.id == vehicle.operatorId;
    final canBook =
        currentUser != null &&
        (currentUser.role == 'tourist' ||
            currentUser.role == 'tourist_guide') &&
        !isOwner;

    final specItems = <({IconData icon, String label})>[
      if (vehicle.seats != null)
        (
          icon: Icons.airline_seat_recline_normal_rounded,
          label: '${vehicle.seats} seats',
        ),
      if ((vehicle.transmission ?? '').trim().isNotEmpty)
        (
          icon: Icons.settings_outlined,
          label: vehicle.transmission!.trim(),
        ),
      if ((vehicle.fuelType ?? '').trim().isNotEmpty)
        (
          icon: Icons.local_gas_station_outlined,
          label: vehicle.fuelType!.trim(),
        ),
    ];

    return Scaffold(
      backgroundColor: _background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 350,
            pinned: true,
            stretch: true,
            backgroundColor: _primary,
            foregroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            title: const Text(
              'Vehicle Details',
              style: TextStyle(
                fontWeight: FontWeight.w900,
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              stretchModes: const [
                StretchMode.zoomBackground,
              ],
              background: Stack(
                fit: StackFit.expand,
                children: [
                  _VehicleImage(
                    imageUrl: vehicle.imageUrl,
                  ),

                  // Strong black gradient at the bottom so the vehicle
                  // name and price always stay readable.
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0x08000000),
                          Color(0x18000000),
                          Color(0x67000000),
                          Color(0xE7000000),
                        ],
                        stops: [0, .45, .72, 1],
                      ),
                    ),
                  ),

                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 25,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(.16),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: Colors.white.withOpacity(.22),
                            ),
                          ),
                          child: const Text(
                            'SAFARI CAR HIRE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: .65,
                            ),
                          ),
                        ),
                        const SizedBox(height: 9),
                        Text(
                          vehicle.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            height: 1.05,
                            letterSpacing: -.55,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Row(
                          children: [
                            Text(
                              _money(vehicle),
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              'per day',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.white.withOpacity(.72),
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
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              18,
              18,
              18,
              122,
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate(
                [
                  if (specItems.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: specItems
                          .map(
                            (item) => _VehicleSpecChip(
                              icon: item.icon,
                              label: item.label,
                            ),
                          )
                          .toList(),
                    ),

                  if (specItems.isNotEmpty)
                    const SizedBox(height: 18),

                  // Provider card
                  Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    clipBehavior: Clip.antiAlias,
                    elevation: 3,
                    shadowColor: Colors.black.withOpacity(.08),
                    child: InkWell(
                      onTap: provider == null
                          ? null
                          : () => Navigator.push<void>(
                                context,
                                MaterialPageRoute<void>(
                                  builder: (_) => ProviderProfilePage(
                                    member: provider!,
                                  ),
                                ),
                              ),
                      child: Padding(
                        padding: const EdgeInsets.all(15),
                        child: Row(
                          children: [
                            _ProviderLogo(vehicle: vehicle),
                            const SizedBox(width: 11),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    vehicle.operatorName.isEmpty
                                        ? 'Tour Operator'
                                        : vehicle.operatorName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(
                                      color: _primary,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _joinedAgo(
                                      vehicle.operatorJoinedAt,
                                    ),
                                    style:
                                        theme.textTheme.bodySmall?.copyWith(
                                      color: const Color(0xFF737D79),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (vehicle.operatorIsVerified)
                              const Padding(
                                padding: EdgeInsets.only(right: 7),
                                child: Icon(
                                  Icons.verified_rounded,
                                  color: _primary,
                                  size: 18,
                                ),
                              ),
                            if (provider != null)
                              const Icon(
                                Icons.chevron_right_rounded,
                                color: _primary,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  _PremiumVehicleDetailCard(
                    icon: Icons.directions_car_outlined,
                    title: 'Vehicle Details',
                    child: Column(
                      children: [
                        if (vehicle.seats != null)
                          _VehicleDetailRow(
                            label: 'Seats',
                            value: '${vehicle.seats}',
                          ),
                        if ((vehicle.transmission ?? '')
                            .trim()
                            .isNotEmpty)
                          _VehicleDetailRow(
                            label: 'Transmission',
                            value: vehicle.transmission!.trim(),
                          ),
                        if ((vehicle.fuelType ?? '')
                            .trim()
                            .isNotEmpty)
                          _VehicleDetailRow(
                            label: 'Fuel type',
                            value: vehicle.fuelType!.trim(),
                          ),
                        _VehicleDetailRow(
                          label: 'Daily rate',
                          value: '${_money(vehicle)} / day',
                          last: true,
                        ),
                      ],
                    ),
                  ),

                  if (vehicle.amenities.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    _PremiumVehicleDetailCard(
                      icon: Icons.auto_awesome_outlined,
                      title: 'Included Features',
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: vehicle.amenities
                            .map(
                              (amenity) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 11,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: _primary.withOpacity(.055),
                                  borderRadius:
                                      BorderRadius.circular(999),
                                ),
                                child: Text(
                                  amenity,
                                  style: theme.textTheme.labelMedium
                                      ?.copyWith(
                                    color: _primary,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ],

                  if ((vehicle.description ?? '').trim().isNotEmpty) ...[
                    const SizedBox(height: 14),
                    _PremiumVehicleDetailCard(
                      icon: Icons.notes_rounded,
                      title: 'About This Vehicle',
                      child: Text(
                        vehicle.description!.trim(),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: _ink.withOpacity(.76),
                          height: 1.55,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),

      // The booking CTA is now fixed inside SafeArea, so it cannot
      // be cut off by Android gesture/navigation bars.
      bottomNavigationBar: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.12),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              if (provider != null) ...[
                Material(
                  color: _primary.withOpacity(.07),
                  shape: const CircleBorder(),
                  child: IconButton(
                    tooltip: 'View provider',
                    onPressed: () => Navigator.push<void>(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => ProviderProfilePage(
                          member: provider!,
                        ),
                      ),
                    ),
                    icon: const Icon(
                      Icons.business_outlined,
                      color: _primary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: SizedBox(
                  height: 54,
                  child: isOwner
                      ? Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: _primary.withOpacity(.07),
                            borderRadius:
                                BorderRadius.circular(999),
                          ),
                          child: const Text(
                            'Your Vehicle',
                            style: TextStyle(
                              color: _primary,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        )
                      : canBook
                          ? FilledButton.icon(
                              onPressed: () {
                                Navigator.push<void>(
                                  context,
                                  MaterialPageRoute<void>(
                                    builder: (_) =>
                                        CarHireBookingPage(
                                      vehicle: vehicle,
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(
                                Icons.calendar_month_outlined,
                              ),
                              label: const Text(
                                'Book This Vehicle',
                                style: TextStyle(
                                  fontWeight:
                                      FontWeight.w900,
                                ),
                              ),
                              style: FilledButton.styleFrom(
                                backgroundColor: _primary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: const StadiumBorder(),
                              ),
                            )
                          : Container(
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: _primary.withOpacity(.07),
                                borderRadius:
                                    BorderRadius.circular(999),
                              ),
                              child: Text(
                                currentUser == null
                                    ? 'Sign in to Book'
                                    : 'Booking Not Available',
                                style: const TextStyle(
                                  color: _primary,
                                  fontWeight:
                                      FontWeight.w900,
                                ),
                              ),
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

class _VehicleSpecChip extends StatelessWidget {
  const _VehicleSpecChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 9,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: const Color(0xFF165B5D).withOpacity(.08),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: const Color(0xFF165B5D),
            size: 17,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF394541),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumVehicleDetailCard extends StatelessWidget {
  const _PremiumVehicleDetailCard({
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF165B5D).withOpacity(.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFF165B5D).withOpacity(.07),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFF165B5D),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: const Color(0xFF165B5D),
                      fontWeight: FontWeight.w900,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _VehicleDetailRow extends StatelessWidget {
  const _VehicleDetailRow({
    required this.label,
    required this.value,
    this.last = false,
  });

  final String label;
  final String value;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF66716E),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF17211F),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
        if (!last)
          Divider(
            height: 1,
            thickness: .7,
            color: const Color(0xFF165B5D).withOpacity(.07),
          ),
      ],
    );
  }
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: const Color(0xFF165B5D),
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _VehicleImage extends StatelessWidget {
  const _VehicleImage({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    if (imageUrl.trim().isEmpty) {
      return const _VehicleFallback();
    }
    return Image.network(
      imageUrl,
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => const _VehicleFallback(),
    );
  }
}

class _VehicleFallback extends StatelessWidget {
  const _VehicleFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF165B5D).withOpacity(.08),
      alignment: Alignment.center,
      child: const Icon(
        Icons.directions_car_filled_rounded,
        color: Color(0xFF165B5D),
        size: 46,
      ),
    );
  }
}

String _specLine(CarHireVehicle vehicle) {
  final parts = <String>[
    if ((vehicle.transmission ?? '').trim().isNotEmpty)
      vehicle.transmission!.trim(),
    if (vehicle.seats != null) '${vehicle.seats} seats',
    if ((vehicle.fuelType ?? '').trim().isNotEmpty)
      vehicle.fuelType!.trim(),
  ];
  return parts.isEmpty ? 'Safari vehicle' : parts.join(' • ');
}

String _money(CarHireVehicle vehicle) {
  final currency =
      vehicle.currency.trim().isEmpty ? 'USD' : vehicle.currency.toUpperCase();
  final amount = vehicle.pricePerDay.toStringAsFixed(
    vehicle.pricePerDay == vehicle.pricePerDay.roundToDouble() ? 0 : 2,
  );
  return '$currency $amount';
}

String _joinedAgo(DateTime? joinedAt) {
  if (joinedAt == null) return 'Local tour operator';
  final d = DateTime.now().difference(joinedAt);
  if (d.inHours < 24) {
    final hours = d.inHours < 1 ? 1 : d.inHours;
    return 'Joined $hours ${hours == 1 ? 'hour' : 'hours'} ago';
  }
  if (d.inDays < 30) {
    return 'Joined ${d.inDays} ${d.inDays == 1 ? 'day' : 'days'} ago';
  }
  if (d.inDays < 365) {
    final months = d.inDays ~/ 30;
    return 'Joined $months ${months == 1 ? 'month' : 'months'} ago';
  }
  final years = d.inDays ~/ 365;
  return 'Joined $years ${years == 1 ? 'year' : 'years'} ago';
}

String _normalise(String value) =>
    value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
