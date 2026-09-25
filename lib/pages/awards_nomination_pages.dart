import 'dart:async';
import 'package:flutter/material.dart';
import '../models/awards.dart';
import '../services/api_exception.dart';
import '../services/auth_service.dart';
import '../services/awards_service.dart';

const _primary = Color(0xFF165B5D);
const _accent = Color(0xFFF46627);

Future<void> _loginRequired(BuildContext context) async {
  await showDialog<void>(
    context: context,
    builder:
        (c) => AlertDialog(
          title: const Text('Login Required'),
          content: const Text(
            'Please sign in or create an account to nominate a tourist guide in the Tourist Guide Awards.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(c);
                Navigator.pushNamed(context, '/register');
              },
              child: const Text('Create Account'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(c);
                Navigator.pushNamed(context, '/login');
              },
              child: const Text('Login'),
            ),
          ],
        ),
  );
}

Future<void> openNominationFlow(BuildContext context) async {
  if (AuthService.instance.currentUser == null) {
    await _loginRequired(context);
    return;
  }
  if (!context.mounted) return;
  await Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const NominateGuidePage()),
  );
}

Future<void> openMyNominations(BuildContext context) async {
  if (AuthService.instance.currentUser == null) {
    await _loginRequired(context);
    return;
  }
  if (!context.mounted) return;
  await Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const MyNominationsPage()),
  );
}

class AwardsNominationCallout extends StatelessWidget {
  const AwardsNominationCallout({
    super.key,
    required this.isGuest,
    required this.onNominate,
    required this.onMyNominations,
  });
  final bool isGuest;
  final VoidCallback onNominate, onMyNominations;

  @override
  Widget build(BuildContext context) => Card(
    elevation: 1,
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.workspace_premium_outlined, color: _accent),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Nominations are open',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isGuest
                ? 'Know an outstanding tourist guide? Sign in to submit a nomination.'
                : 'Recognise an outstanding tourist guide in the category that best represents their work.',
            style: const TextStyle(height: 1.45),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onNominate,
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Nominate a Tourist Guide'),
            ),
          ),
          if (!isGuest) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onMyNominations,
                child: const Text('My Nominations'),
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

class NominateGuidePage extends StatefulWidget {
  const NominateGuidePage({super.key});
  @override
  State<NominateGuidePage> createState() => _NominateGuidePageState();
}

class _NominateGuidePageState extends State<NominateGuidePage> {
  late Future<AwardNominationOptions> _initialFuture;
  AwardNominationOptions? _options;
  AwardCategory? _category;
  AwardNominationGuide? _guide;

  final _search = TextEditingController();
  final _comment = TextEditingController();
  final Map<String, int> _ratings = {};

  Timer? _debounce;
  bool _searching = false;
  bool _submitting = false;
  List<AwardNominationGuide> _matches = [];

  @override
  void initState() {
    super.initState();
    _initialFuture = AwardsService.instance.fetchNominationOptions();
    _search.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.removeListener(_onSearchChanged);
    _search.dispose();
    _comment.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_guide != null) return;
    _debounce?.cancel();

    if (_category == null) {
      if (_search.text.isNotEmpty) {
        _search.clear();
        _snack('Please select an award category first.');
      }
      return;
    }

    final q = _search.text.trim();

    if (q.length < 2) {
      setState(() {
        _matches = [];
        _searching = false;
      });
      return;
    }

    _debounce = Timer(
      const Duration(milliseconds: 450),
      () => _searchGuides(q),
    );
  }

  Future<void> _searchGuides(String q) async {
    setState(() => _searching = true);
    try {
      final result = await AwardsService.instance.fetchNominationOptions(
        search: q,
        categoryId: _category?.id,
      );
      if (!mounted || _search.text.trim() != q) return;
      setState(() {
        _matches = result.guides;
        _searching = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _searching = false);
      _snack(e.message);
    }
  }

  Future<void> _selectGuide(AwardNominationGuide guide) async {
    if (guide.alreadyNominatedInCategory) {
      final categoryName = _category?.name ?? 'this category';
      final year = _options?.award.year ?? DateTime.now().year;

      await showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder:
            (sheetContext) => SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 6, 22, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline, color: _accent, size: 34),
                    const SizedBox(height: 12),
                    const Text(
                      'Guide Already Nominated',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${guide.name} has already been nominated for '
                      '$categoryName in the $year Tourist Guide Awards. '
                      'A guide can only be nominated once in the same category.',
                      style: const TextStyle(height: 1.45),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () => Navigator.pop(sheetContext),
                        child: const Text('Choose Another Guide'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
      );
      return;
    }

    setState(() {
      _guide = guide;
      _matches = [];
      _search.clear();
    });
  }

  void _changeGuide() {
    setState(() {
      _guide = null;
      _matches = [];
    });
  }

  void _snack(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _review() async {
    final options = _options;
    if (options == null) return;
    if (_category == null) {
      _snack('Please select an award category.');
      return;
    }
    if (_guide == null) {
      _snack('Please search for and select a tourist guide.');
      return;
    }
    if (_ratings.isEmpty) {
      _snack('Please select at least one reason and rate it from 1 to 5.');
      return;
    }

    final selectedCriteria =
        options.criteria
            .where((criterion) => _ratings.containsKey(criterion.key))
            .toList();

    final ok =
        await showDialog<bool>(
          context: context,
          builder:
              (c) => AlertDialog(
                title: const Text('Review Nomination'),
                content: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _category!.name,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 8),
                      Text('Guide: ${_guide!.name}'),
                      const SizedBox(height: 16),
                      const Text(
                        'Your ratings',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 8),
                      ...selectedCriteria.map(
                        (criterion) => Padding(
                          padding: const EdgeInsets.only(bottom: 7),
                          child: Row(
                            children: [
                              Expanded(child: Text(criterion.name)),
                              Text(
                                '${_ratings[criterion.key]}/5',
                                style: const TextStyle(
                                  color: _primary,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_comment.text.trim().isNotEmpty) ...[
                        const SizedBox(height: 12),
                        const Text(
                          'Supporting comment',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 5),
                        Text(_comment.text.trim()),
                      ],
                      const SizedBox(height: 14),
                      const Text(
                        'This nomination will be sent for verification. These nomination ratings support the nomination and are not the final judging score.',
                        style: TextStyle(height: 1.4),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(c, false),
                    child: const Text('Go Back & Edit'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(c, true),
                    child: const Text('Submit Nomination'),
                  ),
                ],
              ),
        ) ??
        false;

    if (!ok) return;

    setState(() => _submitting = true);
    try {
      final record = await AwardsService.instance.submitNomination(
        categoryId: _category!.id,
        guideUserId: _guide!.id,
        ratings: _ratings,
        supportingComment: _comment.text,
      );
      if (!mounted) return;

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder:
            (c) => AlertDialog(
              icon: const Icon(Icons.check_circle, color: _primary, size: 42),
              title: const Text('Nomination Submitted'),
              content: Text(
                '${record.guideName} has been nominated for ${record.categoryName}. '
                'The nomination is awaiting verification.',
              ),
              actions: [
                FilledButton(
                  onPressed: () => Navigator.pop(c),
                  child: const Text('Done'),
                ),
              ],
            ),
      );

      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (mounted) _snack(e.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Nominate a Tourist Guide')),
    body: FutureBuilder<AwardNominationOptions>(
      future: _initialFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(snapshot.error.toString()),
            ),
          );
        }

        _options ??= snapshot.data!;
        final options = _options!;

        if (!options.nominationsAreOpen) {
          return const Center(
            child: Text('Nominations are not currently open.'),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              '${options.award.year} ${options.award.title}',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            const Text(
              'Choose an award category, search for the guide, then rate the reasons that support your nomination.',
              style: TextStyle(height: 1.45),
            ),
            const SizedBox(height: 24),

            const _StepTitle(number: '1', title: 'Award Category'),
            const SizedBox(height: 9),
            DropdownButtonFormField<int>(
              value: _category?.id,
              isExpanded: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Select a category',
              ),
              items:
                  options.categories
                      .map(
                        (c) => DropdownMenuItem<int>(
                          value: c.id,
                          child: Text(c.name, overflow: TextOverflow.ellipsis),
                        ),
                      )
                      .toList(),
              onChanged: (id) {
                setState(() {
                  _category = options.categories.firstWhere((x) => x.id == id);
                  _guide = null;
                  _matches = [];
                  _search.clear();
                });
              },
            ),
            if (_category?.description.isNotEmpty == true) ...[
              const SizedBox(height: 7),
              Text(_category!.description),
            ],
            const SizedBox(height: 28),

            const _StepTitle(number: '2', title: 'Select Tourist Guide'),
            const SizedBox(height: 6),
            const Text(
              'Type at least 2 letters of the guide’s name. We only show matching results.',
            ),
            const SizedBox(height: 10),
            if (_guide == null) ...[
              TextField(
                controller: _search,
                enabled: _category != null,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.search),
                  hintText:
                      _category == null
                          ? 'Select a category first'
                          : 'Type guide name',
                  suffixIcon:
                      _searching
                          ? const Padding(
                            padding: EdgeInsets.all(14),
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                          : null,
                ),
              ),
              if (_search.text.trim().length >= 2 && !_searching) ...[
                const SizedBox(height: 8),
                if (_matches.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Text(
                      'No matching eligible tourist guides found.',
                      textAlign: TextAlign.center,
                    ),
                  )
                else
                  ..._matches.map(
                    (guide) => _GuideSearchResult(
                      guide: guide,
                      onTap: () => _selectGuide(guide),
                    ),
                  ),
              ],
            ] else
              _SelectedGuideCard(guide: _guide!, onChange: _changeGuide),

            const SizedBox(height: 28),
            const _StepTitle(
              number: '3',
              title: 'Why are you nominating this guide?',
            ),
            const SizedBox(height: 6),
            const Text(
              'Select the reasons you know about and rate the guide from 1 to 5. You do not have to rate every reason.',
              style: TextStyle(height: 1.45),
            ),
            const SizedBox(height: 14),

            ...options.criteria.map(
              (criterion) => _CriterionRatingCard(
                criterion: criterion,
                rating: _ratings[criterion.key],
                onEnabledChanged: (enabled) {
                  setState(() {
                    if (enabled) {
                      _ratings[criterion.key] = 3;
                    } else {
                      _ratings.remove(criterion.key);
                    }
                  });
                },
                onRatingChanged: (value) {
                  setState(() => _ratings[criterion.key] = value);
                },
              ),
            ),

            const SizedBox(height: 20),
            const Text(
              'Supporting Comment (Optional)',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _comment,
              minLines: 4,
              maxLines: 7,
              maxLength: 1500,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText:
                    'Add a short example or comment that supports your ratings.',
              ),
            ),
            const SizedBox(height: 10),
            FilledButton(
              onPressed: _submitting ? null : _review,
              child: Text(_submitting ? 'SUBMITTING...' : 'Review Nomination'),
            ),
            const SizedBox(height: 30),
          ],
        );
      },
    ),
  );
}

class _StepTitle extends StatelessWidget {
  const _StepTitle({required this.number, required this.title});
  final String number, title;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 30,
        height: 30,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: _primary,
          shape: BoxShape.circle,
        ),
        child: Text(
          number,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Text(
          title,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        ),
      ),
    ],
  );
}

class _GuideSearchResult extends StatelessWidget {
  const _GuideSearchResult({required this.guide, required this.onTap});
  final AwardNominationGuide guide;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      onTap: onTap,
      leading: _GuidePhoto(url: guide.profilePhoto, size: 52),
      title: Row(
        children: [
          Flexible(
            child: Text(
              guide.name,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          if (guide.verified) ...[
            const SizedBox(width: 5),
            const Icon(Icons.verified, color: _primary, size: 17),
          ],
        ],
      ),
      subtitle: Text(
        [
          if (guide.company.isNotEmpty) guide.company,
          if (guide.region.isNotEmpty) guide.region,
        ].join(' • '),
      ),
      trailing: const Icon(Icons.add_circle_outline, color: _primary),
    ),
  );
}

class _SelectedGuideCard extends StatelessWidget {
  const _SelectedGuideCard({required this.guide, required this.onChange});
  final AwardNominationGuide guide;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) => Card(
    elevation: 1,
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _GuidePhoto(url: guide.profilePhoto, size: 78),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        guide.name,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (guide.verified) ...[
                      const SizedBox(width: 5),
                      const Icon(Icons.verified, color: _primary, size: 18),
                    ],
                  ],
                ),
                if (guide.company.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(guide.company),
                ],
                if (guide.region.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(guide.region),
                ],
                if (guide.specialities.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    guide.specialities.take(3).join(' • '),
                    style: const TextStyle(
                      color: _primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: onChange,
                  icon: const Icon(Icons.swap_horiz, size: 18),
                  label: const Text('Change Guide'),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _GuidePhoto extends StatelessWidget {
  const _GuidePhoto({required this.url, required this.size});
  final String url;
  final double size;

  @override
  Widget build(BuildContext context) {
    final resolved = AuthService.storageUrl(url);
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: size,
        height: size,
        color: _primary.withValues(alpha: .08),
        child:
            resolved.isEmpty
                ? const Icon(Icons.person_outline, color: _primary)
                : Image.network(
                  resolved,
                  fit: BoxFit.cover,
                  errorBuilder:
                      (_, __, ___) =>
                          const Icon(Icons.person_outline, color: _primary),
                ),
      ),
    );
  }
}

class _CriterionRatingCard extends StatelessWidget {
  const _CriterionRatingCard({
    required this.criterion,
    required this.rating,
    required this.onEnabledChanged,
    required this.onRatingChanged,
  });

  final AwardNominationCriterion criterion;
  final int? rating;
  final ValueChanged<bool> onEnabledChanged;
  final ValueChanged<int> onRatingChanged;

  @override
  Widget build(BuildContext context) {
    final enabled = rating != null;
    final current = rating ?? 3;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  value: enabled,
                  onChanged: (value) => onEnabledChanged(value ?? false),
                ),
                const SizedBox(width: 3),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          criterion.name,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          criterion.description,
                          style: const TextStyle(height: 1.35),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (enabled) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Text('1'),
                  Expanded(
                    child: Slider(
                      min: 1,
                      max: 5,
                      divisions: 4,
                      value: current.toDouble(),
                      label: '$current',
                      onChanged: (value) => onRatingChanged(value.round()),
                    ),
                  ),
                  const Text('5'),
                  const SizedBox(width: 10),
                  Container(
                    width: 42,
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _primary.withValues(alpha: .08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$current/5',
                      style: const TextStyle(
                        color: _primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class MyNominationsPage extends StatefulWidget {
  const MyNominationsPage({super.key});
  @override
  State<MyNominationsPage> createState() => _MyNominationsPageState();
}

class _MyNominationsPageState extends State<MyNominationsPage> {
  late Future<List<AwardNominationRecord>> future;

  @override
  void initState() {
    super.initState();
    future = AwardsService.instance.fetchMyNominations();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('My Nominations')),
    body: FutureBuilder<List<AwardNominationRecord>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(snapshot.error.toString()),
            ),
          );
        }

        final nominations = snapshot.data ?? [];
        if (nominations.isEmpty) {
          return const Center(
            child: Text('You have not submitted any nominations yet.'),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: nominations.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) {
            final nomination = nominations[i];
            final status =
                nomination.status.isEmpty
                    ? 'Pending'
                    : nomination.status[0].toUpperCase() +
                        nomination.status.substring(1);

            return Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nomination.guideName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(nomination.categoryName),
                    const SizedBox(height: 10),
                    Chip(label: Text(status)),
                  ],
                ),
              ),
            );
          },
        );
      },
    ),
  );
}
