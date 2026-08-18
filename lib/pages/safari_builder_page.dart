import 'package:flutter/material.dart';

import '../config/supported_countries.dart';
import '../models/catalog_item.dart';
import '../services/api_exception.dart';
import '../services/catalog_service.dart';
import '../services/safari_request_service.dart';
import '../widgets/premium_navigation.dart';
import '../widgets/premium_states.dart';
import 'my_safari_requests_page.dart';

// ============================================================================
// HOME PAGE SAFARI BUILDER BANNER
// ============================================================================

class SafariBuilderBanner extends StatelessWidget {
  const SafariBuilderBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final deepPrimary =
        Color.lerp(colors.primary, Colors.black, isDark ? .36 : .46)!;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(30),
      clipBehavior: Clip.antiAlias,
      elevation: 10,
      shadowColor: colors.primary.withValues(alpha: .30),
      child: InkWell(
        onTap: () {
          Navigator.push<void>(
            context,
            premiumPageRoute((_) => const SafariBuilderPage()),
          );
        },
        splashColor: Colors.white.withValues(alpha: .10),
        highlightColor: Colors.white.withValues(alpha: .04),
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [deepPrimary, colors.primary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -44,
                top: -58,
                child: Container(
                  width: 154,
                  height: 154,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: .10),
                      width: 22,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: -34,
                bottom: -48,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: .035),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 21, 22, 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Customize My Safari',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        height: 1.12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -.45,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Personalised Safari Planner',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: .86),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Choose your destinations, activities and travel style, then receive quotes from matching guides and tour operators.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: .78),
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 17),
                    const Wrap(
                      spacing: 7,
                      runSpacing: 7,
                      children: [
                        _SafariBuilderFeaturePill(
                          icon: Icons.explore_outlined,
                          label: 'Activities',
                        ),
                        _SafariBuilderFeaturePill(
                          icon: Icons.location_on_outlined,
                          label: 'Destinations',
                        ),
                        _SafariBuilderFeaturePill(
                          icon: Icons.account_balance_wallet_outlined,
                          label: 'Budget',
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Start Planning',
                            style: TextStyle(
                              color: deepPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            Icons.arrow_forward_rounded,
                            color: deepPrimary,
                            size: 18,
                          ),
                        ],
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

class _SafariBuilderFeaturePill extends StatelessWidget {
  const _SafariBuilderFeaturePill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: .16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 13),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// SAFARI BUILDER PAGE
// ============================================================================

class SafariBuilderPage extends StatefulWidget {
  const SafariBuilderPage({super.key});

  @override
  State<SafariBuilderPage> createState() => _SafariBuilderPageState();
}

class _SafariBuilderPageState extends State<SafariBuilderPage> {
  final _formKey = GlobalKey<FormState>();

  late Future<TourismCatalog> _catalog;

  final Set<int> _activities = {};
  final Set<int> _destinations = {};
  final Set<int> _moods = {};

  final TextEditingController _destinationSearchController =
      TextEditingController();

  final TextEditingController _notesController = TextEditingController();

  String _destinationSearch = '';

  late DateTimeRange _dates;

  int _travellers = 2;

  double _budgetMin = 2000;
  double _budgetMax = 4000;

  String _accommodationLevel = 'Mid-range';

  String _transportPreference = '4x4 Safari Vehicle';

  bool _working = false;

  @override
  void initState() {
    super.initState();

    _catalog = CatalogService.instance.fetchCatalog();

    final start = DateTime.now().add(const Duration(days: 30));

    _dates = DateTimeRange(
      start: start,
      end: start.add(const Duration(days: 6)),
    );
  }

  @override
  void dispose() {
    _destinationSearchController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  int get _tripDays => _dates.end.difference(_dates.start).inDays + 1;

  // ==========================================================================
  // DATES
  // ==========================================================================

  Future<void> _chooseDates() async {
    final now = DateTime.now();

    final value = await showDateRangePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 730)),
      initialDateRange: _dates,
      helpText: 'Choose Safari Dates',
      confirmText: 'Use These Dates',
    );

    if (value == null || !mounted) {
      return;
    }

    setState(() {
      _dates = value;
    });
  }

  // ==========================================================================
  // TRAVELLERS
  // ==========================================================================

  void _changeTravellers(int amount) {
    final next = _travellers + amount;

    if (next < 1 || next > 100) {
      return;
    }

    setState(() {
      _travellers = next;
    });
  }

  // ==========================================================================
  // SUBMIT SAFARI REQUEST
  // ==========================================================================

  Future<void> _submitSafariRequest() async {
    FocusScope.of(context).unfocus();

    if (_working) {
      return;
    }

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    if (_activities.isEmpty) {
      _message('Choose at least one safari activity.');
      return;
    }

    if (_destinations.isEmpty) {
      _message('Choose at least one safari destination.');
      return;
    }

    if (_budgetMax < _budgetMin) {
      _message('Maximum budget cannot be lower than minimum budget.');
      return;
    }

    setState(() {
      _working = true;
    });

    try {
      final title = '$_tripDays Day${_tripDays == 1 ? '' : 's'} Custom Safari';

      final activityIds = _activities.toList()..sort();

      final destinationIds = _destinations.toList()..sort();

      // Do not send negative fallback mood IDs to Laravel.
      final moodIds = _moods.where((id) => id > 0).toList()..sort();

      final request = await SafariRequestService.instance.createRequest(
        title: title,
        travellers: _travellers,
        requestType: 'build',
        startDate: _apiDate(_dates.start),
        endDate: _apiDate(_dates.end),
        days: _tripDays,
        budgetMin: _budgetMin,
        budgetMax: _budgetMax,
        currency: 'USD',
        accommodationLevel: _accommodationLevel,
        transportPreference: _transportPreference,
        notes:
            _notesController.text.trim().isEmpty
                ? null
                : _notesController.text.trim(),
        activityIds: activityIds,
        destinationIds: destinationIds,
        moodIds: moodIds,
      );

      final result = await SafariRequestService.instance.submitRequest(
        request.id,
      );

      if (!mounted) {
        return;
      }

      await _showSuccess(result);
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }

      _message(error.message);
    } catch (_) {
      if (!mounted) {
        return;
      }

      _message('Unable to submit your safari request. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _working = false;
        });
      }
    }
  }

  void _message(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  // ==========================================================================
  // SUCCESS
  // ==========================================================================

  Future<void> _showSuccess(SafariRequestSubmissionResult result) async {
    final providers = result.matchingProviders;

    final guides =
        providers.where((provider) => provider.isTouristGuide).length;

    final operators =
        providers.where((provider) => provider.isTourOperator).length;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);

        final colors = theme.colorScheme;

        return Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: colors.onSurface.withValues(alpha: .16),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: .12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle_rounded,
                  color: colors.primary,
                  size: 38,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Safari Request Sent',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                providers.isEmpty
                    ? 'Your request is open for quotes. Matching tourist guides and tour operators can respond when available.'
                    : 'We found ${providers.length} matching safari provider${providers.length == 1 ? '' : 's'}.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurface.withValues(alpha: .68),
                  height: 1.5,
                ),
              ),
              if (providers.isNotEmpty) ...[
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _SuccessMetric(
                        icon: Icons.person_pin_circle_outlined,
                        value: '$guides',
                        label: guides == 1 ? 'Guide' : 'Guides',
                      ),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: _SuccessMetric(
                        icon: Icons.business_outlined,
                        value: '$operators',
                        label: operators == 1 ? 'Operator' : 'Operators',
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(sheetContext);

                    Navigator.pushReplacement<void, void>(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => const MySafariRequestsPage(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.receipt_long_outlined),
                  label: const Text(
                    'View My Safari Requests',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  Navigator.pop(sheetContext);

                  Navigator.pop(context);
                },
                child: const Text('Back to Home'),
              ),
            ],
          ),
        );
      },
    );
  }

  // ==========================================================================
  // PAGE
  // ==========================================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Customize My Safari')),
      body: FutureBuilder<TourismCatalog>(
        future: _catalog,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  PremiumSkeleton(height: 142),
                  SizedBox(height: 16),
                  PremiumSkeleton(height: 260),
                  SizedBox(height: 16),
                  PremiumSkeleton(height: 170),
                ],
              ),
            );
          }

          if (snapshot.hasError) {
            return const Center(
              child: IllustratedEmptyState(
                title: 'The safari builder is offline',
                message: 'Check your connection and try again.',
                icon: Icons.cloud_off_outlined,
              ),
            );
          }

          final catalog = snapshot.data!;

          final searchedDestinations = _searchDestinations(
            catalog.destinations,
          );

          return Form(
            key: _formKey,
            child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
              children: [
                // ============================================================
                // HERO
                // ============================================================
                Container(
                  padding: const EdgeInsets.all(21),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0B443B), Color(0xFF1E8068)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(27),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.route_rounded,
                        color: Colors.white,
                        size: 34,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'A safari shaped around you',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Build your ideal trip and request personalised quotes from matching guides and tour operators.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: .80),
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),

                // ============================================================
                // ACTIVITIES
                // ============================================================
                const SizedBox(height: 27),

                const _BuilderHeading(number: '01', title: 'Choose activities'),

                const SizedBox(height: 7),

                Text(
                  'Select everything you would like to experience.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurface.withValues(alpha: .62),
                  ),
                ),

                const SizedBox(height: 12),

                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                      catalog.activities.map((activity) {
                        final selected = _activities.contains(activity.id);

                        return FilterChip(
                          selected: selected,
                          avatar: const Icon(Icons.explore_outlined, size: 18),
                          label: Text(activity.name),
                          onSelected: (value) {
                            setState(() {
                              if (value) {
                                _activities.add(activity.id);
                              } else {
                                _activities.remove(activity.id);
                              }
                            });
                          },
                        );
                      }).toList(),
                ),

                // ============================================================
                // SEARCH REAL DESTINATIONS
                // ============================================================
                const SizedBox(height: 30),

                const _BuilderHeading(
                  number: '02',
                  title: 'Where would you like to go?',
                ),

                const SizedBox(height: 7),

                Text(
                  'Search and select one or more safari destinations.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurface.withValues(alpha: .62),
                  ),
                ),

                const SizedBox(height: 13),

                TextField(
                  controller: _destinationSearchController,
                  onChanged: (value) {
                    setState(() {
                      _destinationSearch = value.trim().toLowerCase();
                    });
                  },
                  decoration: InputDecoration(
                    labelText: 'Search destination',
                    hintText: 'Type Bwindi, Murchison, Queen Elizabeth...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon:
                        _destinationSearch.isNotEmpty
                            ? IconButton(
                              onPressed: () {
                                setState(() {
                                  _destinationSearch = '';
                                  _destinationSearchController.clear();
                                });
                              },
                              icon: const Icon(Icons.close_rounded),
                            )
                            : null,
                  ),
                ),

                // ============================================================
                // SELECTED DESTINATIONS
                // ============================================================
                if (_destinations.isNotEmpty) ...[
                  const SizedBox(height: 14),

                  Text(
                    'Selected destinations',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  const SizedBox(height: 9),

                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        catalog.destinations
                            .where(
                              (destination) =>
                                  _destinations.contains(destination.id),
                            )
                            .map(
                              (destination) => InputChip(
                                avatar: Text(
                                  TourismCountries.flagForCountry(
                                    destination.country,
                                  ),
                                  style: const TextStyle(fontSize: 16),
                                ),
                                label: Text(destination.name),
                                onDeleted: () {
                                  setState(() {
                                    _destinations.remove(destination.id);
                                  });
                                },
                              ),
                            )
                            .toList(),
                  ),
                ],

                // ============================================================
                // SEARCH RESULTS
                // ============================================================
                if (_destinationSearch.isNotEmpty) ...[
                  const SizedBox(height: 14),

                  if (searchedDestinations.isEmpty)
                    const _InlineMessage(
                      icon: Icons.search_off_rounded,
                      message: 'No destination matches your search.',
                    )
                  else
                    ...searchedDestinations.map(
                      (destination) => Padding(
                        padding: const EdgeInsets.only(bottom: 9),
                        child: _DestinationSearchResult(
                          destination: destination,
                          onPressed: () {
                            setState(() {
                              _destinations.add(destination.id);

                              _destinationSearch = '';

                              _destinationSearchController.clear();
                            });
                          },
                        ),
                      ),
                    ),
                ],

                // ============================================================
                // SAFARI STYLE
                // ============================================================
                if (catalog.moods.isNotEmpty) ...[
                  const SizedBox(height: 30),

                  const _BuilderHeading(number: '03', title: 'Safari style'),

                  const SizedBox(height: 7),

                  Text(
                    'What kind of safari atmosphere are you looking for?',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurface.withValues(alpha: .62),
                    ),
                  ),

                  const SizedBox(height: 12),

                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        catalog.moods.map((mood) {
                          final selected = _moods.contains(mood.id);

                          return FilterChip(
                            selected: selected,
                            avatar: Icon(mood.icon, size: 18),
                            label: Text(mood.title),
                            onSelected: (value) {
                              setState(() {
                                if (value) {
                                  _moods.add(mood.id);
                                } else {
                                  _moods.remove(mood.id);
                                }
                              });
                            },
                          );
                        }).toList(),
                  ),
                ],

                // ============================================================
                // DATES
                // ============================================================
                const SizedBox(height: 30),

                _BuilderHeading(
                  number: catalog.moods.isNotEmpty ? '04' : '03',
                  title: 'Travel dates',
                ),

                const SizedBox(height: 12),

                _BuilderSelectionCard(
                  icon: Icons.calendar_month_outlined,
                  title:
                      '${_dateLabel(_dates.start)} – ${_dateLabel(_dates.end)}',
                  subtitle: '$_tripDays day${_tripDays == 1 ? '' : 's'} safari',
                  onTap: _chooseDates,
                ),

                // ============================================================
                // TRAVELLERS
                // ============================================================
                const SizedBox(height: 30),

                _BuilderHeading(
                  number: catalog.moods.isNotEmpty ? '05' : '04',
                  title: 'Travellers',
                ),

                const SizedBox(height: 12),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: colors.outlineVariant),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: colors.primary.withValues(alpha: .10),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          Icons.groups_outlined,
                          color: colors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '$_travellers traveller${_travellers == 1 ? '' : 's'}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed:
                            _travellers > 1
                                ? () => _changeTravellers(-1)
                                : null,
                        icon: const Icon(Icons.remove_circle_outline_rounded),
                      ),
                      IconButton(
                        onPressed: () => _changeTravellers(1),
                        icon: const Icon(Icons.add_circle_outline_rounded),
                      ),
                    ],
                  ),
                ),

                // ============================================================
                // BUDGET
                // ============================================================
                const SizedBox(height: 30),

                _BuilderHeading(
                  number: catalog.moods.isNotEmpty ? '06' : '05',
                  title: 'Safari budget',
                ),

                const SizedBox(height: 12),

                _BudgetCard(
                  title: 'Minimum budget',
                  value: _budgetMin,
                  min: 250,
                  max: 15000,
                  onChanged: (value) {
                    setState(() {
                      _budgetMin = value;

                      if (_budgetMax < _budgetMin) {
                        _budgetMax = _budgetMin;
                      }
                    });
                  },
                ),

                const SizedBox(height: 12),

                _BudgetCard(
                  title: 'Maximum budget',
                  value: _budgetMax,
                  min: 250,
                  max: 20000,
                  onChanged: (value) {
                    setState(() {
                      _budgetMax = value;
                    });
                  },
                ),

                // ============================================================
                // ACCOMMODATION
                // ============================================================
                const SizedBox(height: 30),

                _BuilderHeading(
                  number: catalog.moods.isNotEmpty ? '07' : '06',
                  title: 'Accommodation',
                ),

                const SizedBox(height: 7),

                Text(
                  'Choose the general accommodation level you prefer.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurface.withValues(alpha: .62),
                  ),
                ),

                const SizedBox(height: 12),

                _OptionSelector(
                  values: const ['Budget', 'Mid-range', 'Luxury'],
                  selected: _accommodationLevel,
                  onSelected: (value) {
                    setState(() {
                      _accommodationLevel = value;
                    });
                  },
                ),

                // ============================================================
                // TRANSPORT
                // ============================================================
                const SizedBox(height: 30),

                _BuilderHeading(
                  number: catalog.moods.isNotEmpty ? '08' : '07',
                  title: 'Transport',
                ),

                const SizedBox(height: 12),

                _OptionSelector(
                  values: const [
                    '4x4 Safari Vehicle',
                    'Safari Van',
                    'Self Drive',
                    'Flexible',
                  ],
                  selected: _transportPreference,
                  onSelected: (value) {
                    setState(() {
                      _transportPreference = value;
                    });
                  },
                ),

                // ============================================================
                // NOTES
                // ============================================================
                const SizedBox(height: 30),

                _BuilderHeading(
                  number: catalog.moods.isNotEmpty ? '09' : '08',
                  title: 'Anything else?',
                ),

                const SizedBox(height: 12),

                TextFormField(
                  controller: _notesController,
                  minLines: 4,
                  maxLines: 7,
                  decoration: const InputDecoration(
                    labelText: 'Special requests',
                    hintText:
                        'Children, dietary needs, airport pickup, photography interests, gorilla permits or anything important.',
                    alignLabelWithHint: true,
                  ),
                ),

                // ============================================================
                // INFO
                // ============================================================
                const SizedBox(height: 28),

                Container(
                  padding: const EdgeInsets.all(17),
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: .07),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: colors.primary.withValues(alpha: .15),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: colors.primary,
                        size: 21,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Matching uses your real selected destinations and activities. Tourist guides and tour operators whose profiles match your choices can send proposals.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ============================================================
                // SUBMIT
                // ============================================================
                const SizedBox(height: 22),

                SizedBox(
                  height: 56,
                  child: FilledButton.icon(
                    onPressed: _working ? null : _submitSafariRequest,
                    icon:
                        _working
                            ? const SizedBox(
                              width: 19,
                              height: 19,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                            : const Icon(Icons.send_rounded),
                    label: Text(
                      _working
                          ? 'Sending Safari Request...'
                          : 'Request Safari Quotes',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  'You are not committing to a booking yet.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurface.withValues(alpha: .55),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ==========================================================================
  // SEARCH DESTINATIONS
  // ==========================================================================

  List<CatalogItem> _searchDestinations(List<CatalogItem> destinations) {
    if (_destinationSearch.isEmpty) {
      return const [];
    }

    return destinations
        .where((destination) => !_destinations.contains(destination.id))
        .where((destination) {
          final name = destination.name.toLowerCase();

          final location = (destination.location ?? '').toLowerCase();

          final country = (destination.country ?? '').toLowerCase();

          final description = destination.description.toLowerCase();

          return name.contains(_destinationSearch) ||
              location.contains(_destinationSearch) ||
              country.contains(_destinationSearch) ||
              description.contains(_destinationSearch);
        })
        .take(8)
        .toList();
  }

  // ==========================================================================
  // DATE HELPERS
  // ==========================================================================

  String _dateLabel(DateTime value) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${value.day} ${months[value.month - 1]} ${value.year}';
  }

  String _apiDate(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');

    final day = value.day.toString().padLeft(2, '0');

    return '${value.year}-$month-$day';
  }
}

// ============================================================================
// DESTINATION SEARCH RESULT
// ============================================================================

class _DestinationSearchResult extends StatelessWidget {
  const _DestinationSearchResult({
    required this.destination,
    required this.onPressed,
  });

  final CatalogItem destination;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final locationParts =
        [destination.location, destination.country]
            .where((value) => value != null && value!.trim().isNotEmpty)
            .map((value) => value!.trim())
            .toList();

    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: colors.outlineVariant),
          ),
          child: Row(
            children: [
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: .10),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Text(
                  TourismCountries.flagForCountry(destination.country),
                  style: const TextStyle(fontSize: 25),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      destination.name,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (locationParts.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        locationParts.join(' • '),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurface.withValues(alpha: .58),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.add_circle_outline_rounded, color: colors.primary),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// SECTION HEADING
// ============================================================================

class _BuilderHeading extends StatelessWidget {
  const _BuilderHeading({required this.number, required this.title});

  final String number;
  final String title;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: colors.primary.withValues(alpha: .10),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Text(
            number,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: colors.primary,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// SELECTION CARD
// ============================================================================

class _BuilderSelectionCard extends StatelessWidget {
  const _BuilderSelectionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            border: Border.all(color: theme.colorScheme.outlineVariant),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: .10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: theme.colorScheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 3),
                    Text(subtitle),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// BUDGET CARD
// ============================================================================

class _BudgetCard extends StatelessWidget {
  const _BudgetCard({
    required this.title,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final String title;
  final double value;
  final double min;
  final double max;

  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final safeValue = value.clamp(min, max).toDouble();

    return Container(
      padding: const EdgeInsets.fromLTRB(17, 16, 17, 9),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: .62),
            ),
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              Icon(Icons.payments_outlined, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'USD ${safeValue.toStringAsFixed(0)}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          Slider(
            value: safeValue,
            min: min,
            max: max,
            divisions: 59,
            label: 'USD ${safeValue.toStringAsFixed(0)}',
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// OPTION SELECTOR
// ============================================================================

class _OptionSelector extends StatelessWidget {
  const _OptionSelector({
    required this.values,
    required this.selected,
    required this.onSelected,
  });

  final List<String> values;
  final String selected;

  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children:
          values.map((value) {
            return ChoiceChip(
              label: Text(value),
              selected: selected == value,
              onSelected: (_) {
                onSelected(value);
              },
            );
          }).toList(),
    );
  }
}

// ============================================================================
// SUCCESS METRIC
// ============================================================================

class _SuccessMetric extends StatelessWidget {
  const _SuccessMetric({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: .07),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(icon, color: theme.colorScheme.primary),
          const SizedBox(height: 7),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

// ============================================================================
// INLINE MESSAGE
// ============================================================================

class _InlineMessage extends StatelessWidget {
  const _InlineMessage({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(icon, color: colors.primary),
          const SizedBox(width: 10),
          Expanded(child: Text(message)),
        ],
      ),
    );
  }
}
