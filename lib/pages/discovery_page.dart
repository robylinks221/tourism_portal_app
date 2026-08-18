import 'package:flutter/material.dart';

import '../models/catalog_item.dart';
import '../models/community.dart';
import '../models/discovery_item.dart';
import '../models/operator_management.dart';
import '../services/catalog_service.dart';
import '../services/community_service.dart';
import '../services/discovery_store.dart';
import '../services/operator_offerings_service.dart';
import '../theme/app_design_system.dart';
import '../widgets/app_ui.dart';
import '../widgets/premium_navigation.dart';
import '../widgets/provider_discovery_sections.dart';
import 'catalog_detail_page.dart';

class DiscoveryPage extends StatefulWidget {
  const DiscoveryPage({
    super.key,
    required this.isGuest,
    this.initialQuery = '',
  });

  final bool isGuest;
  final String initialQuery;

  @override
  State<DiscoveryPage> createState() => _DiscoveryPageState();
}

class _DiscoveryPageState extends State<DiscoveryPage> {
  late final TextEditingController _search = TextEditingController(
    text: widget.initialQuery,
  );
  late Future<_DiscoveryData> _data = _load();
  DiscoveryKind? _kind;
  String? _location;
  String? _activity;
  double _minimumRating = 0;
  RangeValues _price = const RangeValues(0, 5000);
  bool _priceEnabled = false;
  bool _availableOnly = false;

  @override
  void initState() {
    super.initState();
    DiscoveryStore.instance.ensureLoaded();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<_DiscoveryData> _load() async {
    final catalogFuture = CatalogService.instance.fetchCatalog();
    final offeringsFuture = OperatorOfferingsService.instance.fetch();
    final providersFuture = widget.isGuest
        ? Future.value(
            const FeaturedProviders(guides: [], operators: []),
          )
        : CommunityService.instance.fetchFeaturedProviders();
    return _DiscoveryData(
      catalog: await catalogFuture,
      offerings: await offeringsFuture,
      providers: await providersFuture,
    );
  }

  void _retry() => setState(() => _data = _load());

  int get _activeFilterCount => [
        _kind != null,
        _location != null,
        _activity != null,
        _minimumRating > 0,
        _priceEnabled,
        _availableOnly,
      ].where((active) => active).length;

  void _clearFilters() {
    setState(() {
      _kind = null;
      _location = null;
      _activity = null;
      _minimumRating = 0;
      _price = const RangeValues(0, 5000);
      _priceEnabled = false;
      _availableOnly = false;
    });
  }

  List<_DiscoveryCandidate> _filtered(_DiscoveryData data) {
    final query = _search.text.trim().toLowerCase();
    return data.candidates.where((candidate) {
      final record = candidate.record;
      final searchable = [
        record.title,
        record.subtitle,
        record.location,
        record.kindLabel,
        ...record.activities,
      ].join(' ').toLowerCase();
      if (query.isNotEmpty && !searchable.contains(query)) return false;
      if (_kind != null && record.kind != _kind) return false;
      if (_location != null &&
          !record.location.toLowerCase().contains(_location!.toLowerCase())) {
        return false;
      }
      if (_activity != null &&
          !record.activities.any(
            (value) => value.toLowerCase() == _activity!.toLowerCase(),
          )) {
        return false;
      }
      if (_minimumRating > 0 && record.rating < _minimumRating) return false;
      if (_priceEnabled &&
          (record.price == null ||
              record.price! < _price.start ||
              record.price! > _price.end)) {
        return false;
      }
      if (_availableOnly && !record.available) return false;
      return true;
    }).toList()
      ..sort((first, second) {
        final rating = second.record.rating.compareTo(first.record.rating);
        return rating == 0
            ? first.record.title.compareTo(second.record.title)
            : rating;
      });
  }

  bool _isOffline(Object? error) {
    final message = error.toString().toLowerCase();
    return message.contains('offline') ||
        message.contains('connection') ||
        message.contains('cannot reach') ||
        message.contains('timed out') ||
        message.contains('wi-fi');
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FutureBuilder<_DiscoveryData>(
        future: _data,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 32),
              children: const [
                AppSectionHeader(
                  title: 'Explore Uganda',
                  subtitle: 'Search trusted places, people and safaris.',
                ),
                SizedBox(height: AppSpacing.lg),
                AppDiscoverySkeleton(),
              ],
            );
          }
          if (snapshot.hasError) {
            final offline = _isOffline(snapshot.error);
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 32),
              children: [
                const AppSectionHeader(
                  title: 'Explore Uganda',
                  subtitle: 'Search trusted places, people and safaris.',
                ),
                const SizedBox(height: AppSpacing.md),
                if (offline) ...[
                  const AppOfflineBanner(
                    message:
                        'Discovery is offline. Check your connection and retry.',
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                AppStatePanel(
                  title: offline
                      ? 'Discovery is offline'
                      : 'Discovery could not be loaded',
                  message: offline
                      ? 'Reconnect to load guides, operators, tours and destinations.'
                      : 'Something interrupted discovery. Your saved items are still safe.',
                  kind: offline ? AppStateKind.offline : AppStateKind.error,
                  onRetry: _retry,
                ),
              ],
            );
          }

          final data = snapshot.data!;
          final visible = _filtered(data);
          return AnimatedBuilder(
            animation: DiscoveryStore.instance,
            builder: (context, _) => ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 36),
              children: [
                const AppSectionHeader(
                  title: 'Explore Uganda',
                  subtitle:
                      'Search guides, operators, tours, destinations and activities.',
                ),
                const SizedBox(height: AppSpacing.md),
                _DiscoverySearchField(
                  controller: _search,
                  filterCount: _activeFilterCount,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: AppSpacing.sm),
                _FilterBar(
                  kind: _kind,
                  location: _location,
                  activity: _activity,
                  minimumRating: _minimumRating,
                  priceEnabled: _priceEnabled,
                  price: _price,
                  availableOnly: _availableOnly,
                  onKind: () => _chooseKind(),
                  onLocation: () => _chooseLocation(data.locations),
                  onActivity: () => _chooseActivity(data.activities),
                  onRating: () => _chooseRating(),
                  onPrice: () => _choosePrice(data.maximumPrice),
                  onAvailability: (value) =>
                      setState(() => _availableOnly = value),
                  onClear: _activeFilterCount == 0 ? null : _clearFilters,
                ),
                if (DiscoveryStore.instance.recent.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xl),
                  AppSectionHeader(
                    title: 'Recently Viewed',
                    subtitle: 'Continue from where you left off.',
                    actionLabel: 'Clear',
                    onAction: DiscoveryStore.instance.clearRecent,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SizedBox(
                    height: 146,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: DiscoveryStore.instance.recent.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(width: AppSpacing.sm),
                      itemBuilder: (context, index) {
                        final record = DiscoveryStore.instance.recent[index];
                        final candidate = data.byKey[record.key];
                        return _RecentDiscoveryCard(
                          record: record,
                          onTap: () => candidate == null
                              ? _showRecord(context, record)
                              : _open(candidate),
                        );
                      },
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.xl),
                AppSectionHeader(
                  title: 'Discovery Results',
                  subtitle:
                      '${visible.length} ${visible.length == 1 ? 'match' : 'matches'} for your filters.',
                  showDivider: false,
                ),
                const SizedBox(height: AppSpacing.sm),
                if (visible.isEmpty)
                  AppStatePanel(
                    title: 'No matching experiences',
                    message:
                        'Try a wider price range or clear one of the active filters.',
                    kind: AppStateKind.empty,
                    onRetry: _clearFilters,
                    actionLabel: 'Clear filters',
                  )
                else
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final columns = constraints.maxWidth >= 760 ? 2 : 1;
                      final width = columns == 1
                          ? constraints.maxWidth
                          : (constraints.maxWidth - AppSpacing.sm) / 2;
                      return Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: visible
                            .map(
                              (candidate) => SizedBox(
                                width: width,
                                child: _DiscoveryResultCard(
                                  record: candidate.record,
                                  saved: DiscoveryStore.instance
                                      .isSaved(candidate.record),
                                  onTap: () => _open(candidate),
                                  onSave: () => _toggle(candidate.record),
                                ),
                              ),
                            )
                            .toList(),
                      );
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _toggle(DiscoveryRecord record) async {
    final saved = await DiscoveryStore.instance.toggleSaved(record);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(saved ? 'Saved for later.' : 'Removed from saved.')),
    );
  }

  Future<void> _open(_DiscoveryCandidate candidate) async {
    await DiscoveryStore.instance.recordView(candidate.record);
    if (!mounted) return;
    final source = candidate.source;
    if (source is CatalogItem) {
      await Navigator.push<void>(
        context,
        premiumPageRoute((_) => CatalogDetailPage(item: source)),
      );
    } else if (source is CommunityMember) {
      await Navigator.push<void>(
        context,
        premiumPageRoute((_) => ProviderProfilePage(member: source)),
      );
    } else if (source is OperatorTour) {
      await _showTour(context, source);
    }
  }

  Future<void> _chooseKind() async {
    final value = await _choiceSheet<String>(
      title: 'What are you looking for?',
      values: ['all', ...DiscoveryKind.values.map((value) => value.name)],
      label: (value) => switch (value) {
        'guide' => 'Tourist Guides',
        'operator' => 'Tour Operators',
        'tour' => 'Tours',
        'destination' => 'Destinations',
        'activity' => 'Activities',
        _ => 'Everything',
      },
      selected: _kind?.name ?? 'all',
    );
    if (value.didChoose && value.value != null) {
      setState(() {
        _kind = value.value == 'all'
            ? null
            : DiscoveryKind.values.firstWhere(
                (kind) => kind.name == value.value,
              );
      });
    }
  }

  Future<void> _chooseLocation(List<String> values) async {
    final value = await _choiceSheet<String>(
      title: 'Choose a location',
      values: ['', ...values],
      label: (value) => value.isEmpty ? 'All locations' : value,
      selected: _location ?? '',
    );
    if (value.didChoose && value.value != null) {
      setState(() => _location = value.value!.isEmpty ? null : value.value);
    }
  }

  Future<void> _chooseActivity(List<String> values) async {
    final value = await _choiceSheet<String>(
      title: 'Choose an activity',
      values: ['', ...values],
      label: (value) => value.isEmpty ? 'All activities' : value,
      selected: _activity ?? '',
    );
    if (value.didChoose && value.value != null) {
      setState(() => _activity = value.value!.isEmpty ? null : value.value);
    }
  }

  Future<void> _chooseRating() async {
    const values = [0.0, 3.0, 4.0, 4.5];
    final value = await _choiceSheet<double>(
      title: 'Minimum rating',
      values: values,
      label: (value) => value == 0 ? 'Any rating' : '$value stars and above',
      selected: _minimumRating,
    );
    if (value.didChoose && value.value != null) {
      setState(() => _minimumRating = value.value!);
    }
  }

  Future<void> _choosePrice(double maximumPrice) async {
    var draft = RangeValues(
      _price.start.clamp(0, maximumPrice).toDouble(),
      _price.end.clamp(0, maximumPrice).toDouble(),
    );
    final result = await showModalBottomSheet<RangeValues>(
      context: context,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Price Range',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'USD ${draft.start.toStringAsFixed(0)} – ${draft.end.toStringAsFixed(0)}',
                ),
                RangeSlider(
                  values: draft,
                  min: 0,
                  max: maximumPrice,
                  divisions: 20,
                  labels: RangeLabels(
                    draft.start.toStringAsFixed(0),
                    draft.end.toStringAsFixed(0),
                  ),
                  onChanged: (value) => setSheetState(() => draft = value),
                ),
                Row(
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Any price'),
                    ),
                    const Spacer(),
                    FilledButton(
                      onPressed: () => Navigator.pop(context, draft),
                      child: const Text('Apply'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (!mounted) return;
    setState(() {
      _priceEnabled = result != null;
      if (result != null) _price = result;
    });
  }

  Future<_ChoiceResult<T>> _choiceSheet<T>({
    required String title,
    required List<T> values,
    required String Function(T value) label,
    required T selected,
  }) async {
    var chosen = false;
    final value = await showModalBottomSheet<T>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * .72,
          ),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              for (final item in values)
                RadioListTile<T>(
                  value: item,
                  groupValue: selected,
                  title: Text(label(item)),
                  onChanged: (next) {
                    chosen = true;
                    Navigator.pop(context, next);
                  },
                ),
            ],
          ),
        ),
      ),
    );
    return _ChoiceResult(value: value, didChoose: chosen);
  }
}

class SavedDiscoveryPage extends StatefulWidget {
  const SavedDiscoveryPage({super.key});

  @override
  State<SavedDiscoveryPage> createState() => _SavedDiscoveryPageState();
}

class _SavedDiscoveryPageState extends State<SavedDiscoveryPage> {
  @override
  void initState() {
    super.initState();
    DiscoveryStore.instance.ensureLoaded();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: AnimatedBuilder(
        animation: DiscoveryStore.instance,
        builder: (context, _) {
          final saved = DiscoveryStore.instance.saved;
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 36),
            children: [
              AppSectionHeader(
                title: 'Saved',
                subtitle: saved.isEmpty
                    ? 'Your shortlist will stay ready here.'
                    : '${saved.length} saved ${saved.length == 1 ? 'item' : 'items'} across your safari research.',
              ),
              const SizedBox(height: AppSpacing.md),
              if (!DiscoveryStore.instance.isLoaded)
                const AppDiscoverySkeleton()
              else if (saved.isEmpty)
                const AppStatePanel(
                  title: 'Nothing saved yet',
                  message:
                      'Use the heart on a guide, operator, tour or destination to keep it here.',
                  kind: AppStateKind.empty,
                )
              else
                ...saved.map(
                  (record) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: _DiscoveryResultCard(
                      record: record,
                      saved: true,
                      onTap: () => _showRecord(context, record),
                      onSave: () => DiscoveryStore.instance.toggleSaved(record),
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

class _DiscoveryData {
  _DiscoveryData({
    required this.catalog,
    required this.offerings,
    required this.providers,
  }) {
    candidates = [
      ...catalog.destinations.map(
        (item) => _DiscoveryCandidate(
          record: DiscoveryRecord.fromCatalog(item),
          source: item,
        ),
      ),
      ...catalog.activities.map(
        (item) => _DiscoveryCandidate(
          record: DiscoveryRecord.fromCatalog(item),
          source: item,
        ),
      ),
      ...providers.guides.map(
        (item) => _DiscoveryCandidate(
          record: DiscoveryRecord.fromProvider(item),
          source: item,
        ),
      ),
      ...providers.operators.map(
        (item) => _DiscoveryCandidate(
          record: DiscoveryRecord.fromProvider(item),
          source: item,
        ),
      ),
      ...offerings.tours.map(
        (item) => _DiscoveryCandidate(
          record: DiscoveryRecord.fromTour(item),
          source: item,
        ),
      ),
    ];
    byKey = {for (final candidate in candidates) candidate.record.key: candidate};
  }

  final TourismCatalog catalog;
  final OperatorOfferings offerings;
  final FeaturedProviders providers;
  late final List<_DiscoveryCandidate> candidates;
  late final Map<String, _DiscoveryCandidate> byKey;

  List<String> get locations => candidates
      .map((candidate) => candidate.record.location.trim())
      .where((value) => value.isNotEmpty)
      .toSet()
      .toList()
    ..sort();

  List<String> get activities => candidates
      .expand((candidate) => candidate.record.activities)
      .where((value) => value.trim().isNotEmpty)
      .toSet()
      .toList()
    ..sort();

  double get maximumPrice {
    final prices = candidates
        .map((candidate) => candidate.record.price)
        .whereType<double>()
        .where((value) => value > 0)
        .toList();
    if (prices.isEmpty) return 5000;
    final maximum = prices.reduce((first, second) => first > second ? first : second);
    return ((maximum / 100).ceil() * 100).clamp(100, 100000).toDouble();
  }
}

class _DiscoveryCandidate {
  const _DiscoveryCandidate({required this.record, required this.source});

  final DiscoveryRecord record;
  final Object source;
}

class _ChoiceResult<T> {
  const _ChoiceResult({required this.value, required this.didChoose});

  final T? value;
  final bool didChoose;
}

class _DiscoverySearchField extends StatelessWidget {
  const _DiscoverySearchField({
    required this.controller,
    required this.filterCount,
    required this.onChanged,
  });

  final TextEditingController controller;
  final int filterCount;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Search places, activities or providers',
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: controller.text.isEmpty
            ? filterCount == 0
                ? null
                : Padding(
                    padding: const EdgeInsets.all(12),
                    child: Badge(label: Text('$filterCount')),
                  )
            : IconButton(
                tooltip: 'Clear search',
                onPressed: () {
                  controller.clear();
                  onChanged('');
                },
                icon: const Icon(Icons.close_rounded),
              ),
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.kind,
    required this.location,
    required this.activity,
    required this.minimumRating,
    required this.priceEnabled,
    required this.price,
    required this.availableOnly,
    required this.onKind,
    required this.onLocation,
    required this.onActivity,
    required this.onRating,
    required this.onPrice,
    required this.onAvailability,
    required this.onClear,
  });

  final DiscoveryKind? kind;
  final String? location;
  final String? activity;
  final double minimumRating;
  final bool priceEnabled;
  final RangeValues price;
  final bool availableOnly;
  final VoidCallback onKind;
  final VoidCallback onLocation;
  final VoidCallback onActivity;
  final VoidCallback onRating;
  final VoidCallback onPrice;
  final ValueChanged<bool> onAvailability;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _FilterAction(
            label: kind?.name ?? 'Type',
            active: kind != null,
            onTap: onKind,
          ),
          _FilterAction(
            label: location ?? 'Location',
            active: location != null,
            onTap: onLocation,
          ),
          _FilterAction(
            label: activity ?? 'Activity',
            active: activity != null,
            onTap: onActivity,
          ),
          _FilterAction(
            label: minimumRating == 0 ? 'Rating' : '$minimumRating+ stars',
            active: minimumRating > 0,
            onTap: onRating,
          ),
          _FilterAction(
            label: priceEnabled
                ? 'USD ${price.start.toStringAsFixed(0)}–${price.end.toStringAsFixed(0)}'
                : 'Price',
            active: priceEnabled,
            onTap: onPrice,
          ),
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.xs),
            child: FilterChip(
              selected: availableOnly,
              label: const Text('Available'),
              avatar: const Icon(Icons.event_available_rounded, size: 17),
              onSelected: onAvailability,
            ),
          ),
          if (onClear != null)
            TextButton(onPressed: onClear, child: const Text('Clear')),
        ],
      ),
    );
  }
}

class _FilterAction extends StatelessWidget {
  const _FilterAction({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.xs),
      child: ActionChip(
        onPressed: onTap,
        avatar: active ? const Icon(Icons.check_rounded, size: 17) : null,
        label: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 150),
          child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      ),
    );
  }
}

class _DiscoveryResultCard extends StatelessWidget {
  const _DiscoveryResultCard({
    required this.record,
    required this.saved,
    required this.onTap,
    required this.onSave,
  });

  final DiscoveryRecord record;
  final bool saved;
  final VoidCallback onTap;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppSurfaceCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      radius: AppRadii.medium,
      raised: true,
      child: SizedBox(
        height: 148,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 106,
              child: _DiscoveryImage(record: record),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            record.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              height: 1.2,
                            ),
                          ),
                        ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          tooltip: saved ? 'Remove from saved' : 'Save',
                          onPressed: onSave,
                          icon: Icon(
                            saved
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            color: saved ? theme.colorScheme.secondary : null,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      record.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(height: 1.35),
                    ),
                    const Spacer(),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        _RecordMeta(icon: Icons.category_outlined, text: record.kindLabel),
                        if (record.rating > 0)
                          _RecordMeta(
                            icon: Icons.star_rounded,
                            text: record.rating.toStringAsFixed(1),
                          ),
                        if (record.price != null)
                          _RecordMeta(
                            icon: Icons.payments_outlined,
                            text: 'USD ${record.price!.toStringAsFixed(0)}',
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
    );
  }
}

class _DiscoveryImage extends StatelessWidget {
  const _DiscoveryImage({required this.record});

  final DiscoveryRecord record;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final fallback = Container(
      color: colors.primaryContainer,
      alignment: Alignment.center,
      child: Icon(
        switch (record.kind) {
          DiscoveryKind.guide => Icons.badge_outlined,
          DiscoveryKind.operator => Icons.business_outlined,
          DiscoveryKind.tour => Icons.route_outlined,
          DiscoveryKind.destination => Icons.landscape_outlined,
          DiscoveryKind.activity => Icons.hiking_outlined,
        },
        color: colors.onPrimaryContainer,
        size: 36,
      ),
    );
    if (record.imageUrl.isEmpty) return fallback;
    return Image.network(
      record.imageUrl,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => fallback,
    );
  }
}

class _RecordMeta extends StatelessWidget {
  const _RecordMeta({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 3),
        Text(
          text,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }
}

class _RecentDiscoveryCard extends StatelessWidget {
  const _RecentDiscoveryCard({required this.record, required this.onTap});

  final DiscoveryRecord record;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 210,
      child: AppSurfaceCard(
        onTap: onTap,
        padding: const EdgeInsets.all(AppSpacing.sm),
        radius: AppRadii.medium,
        child: Row(
          children: [
            SizedBox(
              width: 72,
              height: double.infinity,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadii.small),
                child: _DiscoveryImage(record: record),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    record.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    record.kindLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _showRecord(BuildContext context, DiscoveryRecord record) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              record.title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(record.kindLabel),
            if (record.location.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(record.location),
            ],
            const SizedBox(height: AppSpacing.md),
            Text(record.subtitle),
          ],
        ),
      ),
    ),
  );
}

Future<void> _showTour(BuildContext context, OperatorTour tour) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tour.name,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text('${tour.days} days • ${tour.operatorName}'),
            const SizedBox(height: AppSpacing.md),
            Text(tour.overview),
            const SizedBox(height: AppSpacing.md),
            Text(
              '${tour.currency} ${tour.price.toStringAsFixed(0)}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
      ),
    ),
  );
}
