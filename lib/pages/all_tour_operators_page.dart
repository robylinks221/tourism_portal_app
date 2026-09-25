import 'package:flutter/material.dart';

import '../config/supported_countries.dart';
import '../models/community.dart';
import '../services/auth_service.dart';
import '../services/community_service.dart';
import '../theme/field_guide_theme.dart';
import '../widgets/guest_access_sheet.dart';
import '../widgets/provider_discovery_sections.dart';

class AllTourOperatorsPage extends StatefulWidget {
  const AllTourOperatorsPage({super.key});

  @override
  State<AllTourOperatorsPage> createState() => _AllTourOperatorsPageState();
}

class _AllTourOperatorsPageState extends State<AllTourOperatorsPage> {
  static const Color _primary = FieldGuidePalette.primary;

  static const Color _secondary = FieldGuidePalette.secondary;

  static const Color _background = FieldGuidePalette.background;

  final TextEditingController _searchController = TextEditingController();

  List<CommunityMember> _allOperators = [];
  List<CommunityMember> _filteredOperators = [];

  bool _loading = true;
  bool _isGuest = true;

  String _selectedCountry = 'All';
  String _selectedActivity = 'All';
  String _selectedDestination = 'All';

  double _minimumRating = 0;

  bool _verifiedOnly = false;
  bool _carHireOnly = false;

  @override
  void initState() {
    super.initState();

    _searchController.addListener(_applyFilters);

    _loadOperators();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ==============================================================
  // LOAD OPERATORS
  // ==============================================================

  Future<void> _loadOperators() async {
    if (mounted) {
      setState(() {
        _loading = true;
      });
    }

    try {
      final currentUser = await AuthService.instance.restoreSession();

      final isGuest = currentUser == null;

      final operators = isGuest
          ? (await CommunityService.instance.fetchGuestProviders()).operators
          : (await CommunityService.instance.fetchMembers())
              .where((member) => member.isOperator)
              .toList();

      if (!mounted) {
        return;
      }

      setState(() {
        _isGuest = isGuest;
        _allOperators = operators;
        _filteredOperators = operators;
        _loading = false;
      });

      _applyFilters();
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to load tour operators.')),
      );
    }
  }

  // ==============================================================
  // FILTER VALUES
  // ==============================================================

  List<String> get _countries => ['All', ...TourismCountries.names];

  List<String> get _activities {
    final values =
        _allOperators
            .expand((operator) => operator.activityNames)
            .map((value) => value.trim())
            .where((value) => value.isNotEmpty)
            .toSet()
            .toList()
          ..sort();

    return ['All', ...values];
  }

  List<String> get _destinations {
    final values =
        _allOperators
            .expand((operator) => operator.destinationNames)
            .map((value) => value.trim())
            .where((value) => value.isNotEmpty)
            .toSet()
            .toList()
          ..sort();

    return ['All', ...values];
  }

  // ==============================================================
  // APPLY FILTERS
  // ==============================================================

  void _applyFilters() {
    if (!mounted) {
      return;
    }

    final query = _searchController.text.trim().toLowerCase();

    final filtered =
        _allOperators.where((operator) {
          final name = operator.name.toLowerCase();

          final location = operator.location.toLowerCase();

          final country = operator.country.toLowerCase();

          final operatingCountries =
              operator.countriesServed.join(' ').toLowerCase();

          final biography = operator.biography.toLowerCase();

          final activities = operator.activityNames.join(' ').toLowerCase();

          final destinations =
              operator.destinationNames.join(' ').toLowerCase();

          final matchesSearch =
              query.isEmpty ||
              name.contains(query) ||
              location.contains(query) ||
              country.contains(query) ||
              operatingCountries.contains(query) ||
              biography.contains(query) ||
              activities.contains(query) ||
              destinations.contains(query);

          final matchesCountry =
              _selectedCountry == 'All' ||
              operator.operatesIn(_selectedCountry);

          final matchesActivity =
              _selectedActivity == 'All' ||
              operator.activityNames.contains(_selectedActivity);

          final matchesDestination =
              _selectedDestination == 'All' ||
              operator.destinationNames.contains(_selectedDestination);

          final matchesRating = operator.ratingAverage >= _minimumRating;

          final matchesVerified = !_verifiedOnly || operator.isVerified;

          final matchesCarHire = !_carHireOnly || operator.carHireEnabled;

          return matchesSearch &&
              matchesCountry &&
              matchesActivity &&
              matchesDestination &&
              matchesRating &&
              matchesVerified &&
              matchesCarHire;
        }).toList();

    setState(() {
      _filteredOperators = filtered;
    });
  }

  // ==============================================================
  // RESET FILTERS
  // ==============================================================

  void _resetFilters() {
    setState(() {
      _selectedCountry = 'All';
      _selectedActivity = 'All';
      _selectedDestination = 'All';

      _minimumRating = 0;

      _verifiedOnly = false;
      _carHireOnly = false;

      _searchController.clear();
    });

    _applyFilters();
  }

  // ==============================================================
  // OPEN OPERATOR
  // ==============================================================

  Future<void> _openOperator(CommunityMember operator) async {
    if (_isGuest) {
      await showGuestAccessSheet(
        context,
        title: 'View the full profile',
        message:
            "Login or create a free account to view ${operator.name}'s full profile, contact details, safari tours and booking options.",
      );

      return;
    }

    if (!mounted) {
      return;
    }

    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => ProviderProfilePage(member: operator),
      ),
    );
  }

  // ==============================================================
  // FILTER SHEET
  // ==============================================================

  Future<void> _showFilters() async {
    String country = _selectedCountry;

    String activity = _selectedActivity;

    String destination = _selectedDestination;

    double minimumRating = _minimumRating;

    bool verifiedOnly = _verifiedOnly;

    bool carHireOnly = _carHireOnly;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(.50),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, sheetSetState) {
            return SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
                decoration: const BoxDecoration(
                  color: _background,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(34),
                    topRight: Radius.circular(34),
                  ),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 44,
                          height: 4,
                          decoration: BoxDecoration(
                            color: const Color(0xFFD2CCC3),
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),

                      const SizedBox(height: 22),

                      const Text(
                        'Filter Tour Operators',
                        style: TextStyle(
                          color: FieldGuidePalette.ink,
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -.4,
                        ),
                      ),

                      const SizedBox(height: 5),

                      const Text(
                        'Find operators that match your safari plans.',
                        style: TextStyle(
                          color: FieldGuidePalette.mutedText,
                          fontSize: 12.5,
                        ),
                      ),

                      const SizedBox(height: 22),

                      _FilterDropdown(
                        label: 'Operates in country',
                        value: country,
                        values: _countries,
                        onChanged: (value) {
                          sheetSetState(() {
                            country = value ?? 'All';
                          });
                        },
                      ),

                      const SizedBox(height: 14),

                      _FilterDropdown(
                        label: 'Activity',
                        value: activity,
                        values: _activities,
                        onChanged: (value) {
                          sheetSetState(() {
                            activity = value ?? 'All';
                          });
                        },
                      ),

                      const SizedBox(height: 14),

                      _FilterDropdown(
                        label: 'Destination',
                        value: destination,
                        values: _destinations,
                        onChanged: (value) {
                          sheetSetState(() {
                            destination = value ?? 'All';
                          });
                        },
                      ),

                      const SizedBox(height: 21),

                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Minimum rating',
                              style: TextStyle(
                                color: FieldGuidePalette.ink,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),

                          Text(
                            minimumRating == 0
                                ? 'Any'
                                : '${minimumRating.toStringAsFixed(0)}+',
                            style: const TextStyle(
                              color: _secondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),

                      Slider(
                        value: minimumRating,
                        min: 0,
                        max: 5,
                        divisions: 5,
                        activeColor: _primary,
                        inactiveColor: _primary.withOpacity(.14),
                        onChanged: (value) {
                          sheetSetState(() {
                            minimumRating = value;
                          });
                        },
                      ),

                      SwitchListTile.adaptive(
                        value: verifiedOnly,
                        contentPadding: EdgeInsets.zero,
                        activeColor: _primary,
                        title: const Text(
                          'Verified operators only',
                          style: TextStyle(
                            color: FieldGuidePalette.ink,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: const Text(
                          'Show providers verified by the platform.',
                          style: TextStyle(
                            color: FieldGuidePalette.mutedText,
                            fontSize: 11.5,
                          ),
                        ),
                        onChanged: (value) {
                          sheetSetState(() {
                            verifiedOnly = value;
                          });
                        },
                      ),

                      SwitchListTile.adaptive(
                        value: carHireOnly,
                        contentPadding: EdgeInsets.zero,
                        activeColor: _primary,
                        title: const Text(
                          'Car hire available',
                          style: TextStyle(
                            color: FieldGuidePalette.ink,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: const Text(
                          'Only show operators offering vehicle hire.',
                          style: TextStyle(
                            color: FieldGuidePalette.mutedText,
                            fontSize: 11.5,
                          ),
                        ),
                        onChanged: (value) {
                          sheetSetState(() {
                            carHireOnly = value;
                          });
                        },
                      ),

                      const SizedBox(height: 18),

                      SizedBox(
                        height: 52,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: _primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(100),
                            ),
                          ),
                          onPressed: () {
                            setState(() {
                              _selectedCountry = country;

                              _selectedActivity = activity;

                              _selectedDestination = destination;

                              _minimumRating = minimumRating;

                              _verifiedOnly = verifiedOnly;

                              _carHireOnly = carHireOnly;
                            });

                            Navigator.pop(sheetContext);

                            _applyFilters();
                          },
                          child: const Text(
                            'Apply Filters',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),

                      const SizedBox(height: 6),

                      TextButton(
                        onPressed: () {
                          Navigator.pop(sheetContext);

                          _resetFilters();
                        },
                        child: const Text(
                          'Reset Filters',
                          style: TextStyle(
                            color: _secondary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ==============================================================
  // BUILD PAGE
  // ==============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,

      appBar: AppBar(
        backgroundColor: _background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,

        title: const Text(
          'Tour Operators',
          style: TextStyle(
            color: FieldGuidePalette.ink,
            fontSize: 21,
            fontWeight: FontWeight.w800,
          ),
        ),

        actions: [
          IconButton(
            tooltip: 'Filters',
            onPressed: _showFilters,
            icon: const Icon(Icons.tune_rounded, color: _primary),
          ),

          const SizedBox(width: 7),
        ],
      ),

      body: RefreshIndicator(
        color: _primary,
        onRefresh: _loadOperators,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),

          slivers: [
            // ======================================================
            // INTRO / SEARCH
            // ======================================================
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Plan with local experts',
                      style: TextStyle(
                        color: FieldGuidePalette.ink,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -.6,
                      ),
                    ),

                    const SizedBox(height: 6),

                    const Text(
                      'Discover tour operators by destination, activity, rating and services.',
                      style: TextStyle(
                        color: FieldGuidePalette.mutedText,
                        fontSize: 13,
                        height: 1.45,
                      ),
                    ),

                    const SizedBox(height: 18),

                    TextField(
                      controller: _searchController,
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        hintText:
                            'Search operators, destinations or activities',
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: _primary,
                        ),
                        suffixIcon: IconButton(
                          onPressed: _showFilters,
                          icon: const Icon(
                            Icons.tune_rounded,
                            color: _secondary,
                          ),
                        ),
                        filled: true,
                        fillColor: Colors.white.withOpacity(.74),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: const BorderSide(
                            color: FieldGuidePalette.border,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: const BorderSide(
                            color: _primary,
                            width: 1.4,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 13),

                    Row(
                      children: [
                        Text(
                          '${_filteredOperators.length} operator${_filteredOperators.length == 1 ? '' : 's'}',
                          style: const TextStyle(
                            color: FieldGuidePalette.mutedText,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                        const Spacer(),

                        if (_isGuest)
                          const Row(
                            children: [
                              Icon(
                                Icons.visibility_outlined,
                                color: _secondary,
                                size: 16,
                              ),
                              SizedBox(width: 5),
                              Text(
                                'Guest preview',
                                style: TextStyle(
                                  color: _secondary,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
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

            // ======================================================
            // LOADING
            // ======================================================
            if (_loading)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: CircularProgressIndicator(color: _primary),
                ),
              )
            // ======================================================
            // EMPTY
            // ======================================================
            else if (_filteredOperators.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _EmptyState(onReset: _resetFilters),
              )
            // ======================================================
            // OPERATOR LIST
            // ======================================================
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                sliver: SliverList.separated(
                  itemCount: _filteredOperators.length,
                  separatorBuilder:
                      (context, index) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final operator = _filteredOperators[index];

                    return PremiumProviderCard(
                      member: operator,
                      isGuest: _isGuest,
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

// ==================================================================
// FILTER DROPDOWN
// ==================================================================

class _FilterDropdown extends StatelessWidget {
  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.values,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<String> values;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final safeValue = values.contains(value) ? value : 'All';

    return DropdownButtonFormField<String>(
      value: safeValue,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white.withOpacity(.75),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: FieldGuidePalette.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: FieldGuidePalette.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: FieldGuidePalette.primary,
            width: 1.4,
          ),
        ),
      ),
      items:
          values
              .map(
                (item) => DropdownMenuItem<String>(
                  value: item,
                  child: Text(
                    item,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
      onChanged: onChanged,
    );
  }
}

// ==================================================================
// EMPTY STATE
// ==================================================================

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onReset});

  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: FieldGuidePalette.primary.withOpacity(.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.business_outlined,
                color: FieldGuidePalette.primary,
                size: 30,
              ),
            ),

            const SizedBox(height: 16),

            const Text(
              'No tour operators found',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: FieldGuidePalette.ink,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(height: 7),

            const Text(
              'Try changing your search or filters.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: FieldGuidePalette.mutedText,
                fontSize: 13,
              ),
            ),

            const SizedBox(height: 14),

            TextButton(
              onPressed: onReset,
              child: const Text(
                'Reset filters',
                style: TextStyle(
                  color: FieldGuidePalette.secondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================================================================
// INITIALS
// ==================================================================

String _initials(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .take(2);

  return parts.map((part) => part[0].toUpperCase()).join();
}
