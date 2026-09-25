import 'dart:async';
import 'package:flutter/material.dart';
import '../models/awards.dart';
import '../models/community.dart';
import 'awards_nomination_pages.dart';
import '../services/api_exception.dart';
import '../services/auth_service.dart';
import '../services/awards_service.dart';
import '../services/community_service.dart';
import '../theme/app_design_system.dart';
import '../widgets/app_ui.dart';
import '../widgets/provider_discovery_sections.dart';

const _primary = Color(0xFF165B5D);
const _accent = Color(0xFFF46627);

class AwardsHomePage extends StatefulWidget {
  const AwardsHomePage({super.key, this.isGuest = false});
  final bool isGuest;
  @override
  State<AwardsHomePage> createState() => _AwardsHomePageState();
}

class _AwardsHomePageState extends State<AwardsHomePage> {
  late Future<AwardsHomeData> _future;
  Timer? _timer;
  @override
  void initState() {
    super.initState();
    _future = AwardsService.instance.fetchHome();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _reload() =>
      setState(() => _future = AwardsService.instance.fetchHome());
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Tourist Guide Awards'),
      actions: [
        IconButton(
          tooltip: 'My Nominations',
          onPressed: () => openMyNominations(context),
          icon: const Icon(Icons.assignment_turned_in_outlined),
        ),
        IconButton(
          tooltip: 'My Votes',
          onPressed:
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MyVotesPage()),
              ),
          icon: const Icon(Icons.how_to_vote_outlined),
        ),
        IconButton(
          tooltip: 'Winners',
          onPressed:
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AwardsWinnersPage()),
              ),
          icon: const Icon(Icons.emoji_events_outlined),
        ),
      ],
    ),
    body: FutureBuilder<AwardsHomeData>(
      future: _future,
      builder: (context, s) {
        if (s.connectionState == ConnectionState.waiting)
          return const Center(child: CircularProgressIndicator());
        if (s.hasError)
          return _ErrorState(message: _msg(s.error), retry: _reload);
        final d = s.data!;
        return RefreshIndicator(
          onRefresh: () async {
            _reload();
            await _future;
          },
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              _Hero(award: d.award),
              if (d.award.stage == 'nominations_open') ...[
                const SizedBox(height: AppSpacing.md),
                AwardsNominationCallout(
                  isGuest: widget.isGuest,
                  onNominate: () => openNominationFlow(context),
                  onMyNominations: () => openMyNominations(context),
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              AppSectionHeader(
                title: 'Award Categories',
                subtitle:
                    'Explore the categories recognising excellence in tourist guiding.',
                actionLabel: 'View all',
                onAction:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AwardsCategoriesPage(),
                      ),
                    ),
              ),
              const SizedBox(height: AppSpacing.md),
              ...d.categories
                  .take(4)
                  .map(
                    (c) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _CategoryCard(category: c),
                    ),
                  ),
              const SizedBox(height: AppSpacing.md),
              AppSectionHeader(
                title: 'Leading Guides',
                subtitle:
                    'Top-performing finalists across this year’s award categories.',
                actionLabel: 'View all',
                onAction:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AwardsFinalistsPage(),
                      ),
                    ),
              ),
              const SizedBox(height: AppSpacing.md),
              const _LeadingGuidesCarousel(),
              const SizedBox(height: AppSpacing.md),
              AppSectionHeader(
                title: 'Previous Winners',
                subtitle:
                    'Celebrating guides recognised in earlier award years.',
                actionLabel: 'Winners',
                onAction:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AwardsWinnersPage(),
                      ),
                    ),
              ),
              const SizedBox(height: AppSpacing.md),
              if (d.previousWinners.isEmpty)
                const _EmptyCard(
                  icon: Icons.emoji_events_outlined,
                  text: 'Previous winners will appear here when published.',
                )
              else
                ...d.previousWinners.take(3).map((w) => _WinnerCard(winner: w)),
              const SizedBox(height: 40),
            ],
          ),
        );
      },
    ),
  );
}


class _LeadingGuidesCarousel extends StatefulWidget {
  const _LeadingGuidesCarousel();

  @override
  State<_LeadingGuidesCarousel> createState() => _LeadingGuidesCarouselState();
}

class _LeadingGuidesCarouselState extends State<_LeadingGuidesCarousel> {
  late final PageController _controller;
  late Future<List<_LeadingGuideItem>> _future;
  Timer? _timer;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: .48);
    _future = _load();
  }

  Future<List<_LeadingGuideItem>> _load() async {
    final finalists = await AwardsService.instance.fetchFinalists();

    AwardResultsData? results;
    try {
      results = await AwardsService.instance.fetchResults();
    } catch (_) {
      results = null;
    }

    final resultByFinalist = <int, AwardFinalistResult>{};
    if (results != null && !results.isHidden) {
      for (final category in results.categories) {
        for (final result in category.finalists) {
          resultByFinalist[result.finalistId] = result;
        }
      }
    }

    // One leading guide per category. When public results are visible, the
    // finalist with the highest percentage leads that category. If results
    // are hidden, use the first published finalist without exposing rankings.
    final grouped = <int, List<AwardFinalist>>{};
    for (final finalist in finalists) {
      grouped.putIfAbsent(finalist.categoryId, () => []).add(finalist);
    }

    final items = <_LeadingGuideItem>[];
    for (final entry in grouped.entries) {
      final candidates = entry.value;
      if (candidates.isEmpty) continue;

      if (results != null && !results.isHidden) {
        candidates.sort((a, b) {
          final ap = resultByFinalist[a.id]?.percentage ?? 0;
          final bp = resultByFinalist[b.id]?.percentage ?? 0;
          return bp.compareTo(ap);
        });
      }

      final guide = candidates.first;
      items.add(
        _LeadingGuideItem(
          finalist: guide,
          result: resultByFinalist[guide.id],
          resultsMode: results?.mode ?? 'hidden',
        ),
      );
    }

    if (mounted && items.length > 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _start(items.length));
    }
    return items;
  }

  void _start(int count) {
    _timer?.cancel();
    if (count < 2) return;
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_controller.hasClients) return;
      final next = (_page + 1) % count;
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 650),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<_LeadingGuideItem>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 350,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final items = snapshot.data ?? const <_LeadingGuideItem>[];
        if (items.isEmpty) {
          return const _EmptyCard(
            icon: Icons.workspace_premium_outlined,
            text: 'Leading finalists will appear here once finalists are published.',
          );
        }

        return Column(
          children: [
            SizedBox(
              height: 320,
              child: PageView.builder(
                controller: _controller,
                padEnds: false,
                itemCount: items.length,
                onPageChanged: (value) => setState(() => _page = value),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return Padding(
                    padding: EdgeInsets.only(
                      right: index == items.length - 1 ? 0 : 12,
                    ),
                    child: _LeadingGuideCard(item: item),
                  );
                },
              ),
            ),
            if (items.length > 1) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  items.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: index == _page ? 24 : 7,
                    height: 7,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: index == _page
                          ? _primary
                          : _primary.withValues(alpha: .16),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _LeadingGuideItem {
  const _LeadingGuideItem({
    required this.finalist,
    required this.result,
    required this.resultsMode,
  });

  final AwardFinalist finalist;
  final AwardFinalistResult? result;
  final String resultsMode;
}

class _LeadingGuideCard extends StatelessWidget {
  const _LeadingGuideCard({required this.item});

  final _LeadingGuideItem item;

  @override
  Widget build(BuildContext context) {
    final finalist = item.finalist;
    final result = item.result;
    final name =
        finalist.name.trim().isEmpty ? 'Tourist Guide' : finalist.name.trim();

    String? resultText;
    if (result != null) {
      if (item.resultsMode == 'full' && result.votes != null) {
        resultText =
            '${result.votes} ${result.votes == 1 ? 'vote' : 'votes'} • ${result.percentage.toStringAsFixed(1)}%';
      } else if (item.resultsMode == 'percentage') {
        resultText = '${result.percentage.toStringAsFixed(1)}% of votes';
      }
    }

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () async {
          try {
            final categories = await AwardsService.instance.fetchCategories();
            AwardCategory? selected;

            for (final category in categories) {
              if (category.id == finalist.categoryId) {
                selected = category;
                break;
              }
            }

            if (!context.mounted) return;

            if (selected == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('This award category could not be opened.'),
                ),
              );
              return;
            }

            await Navigator.push<void>(
              context,
              MaterialPageRoute<void>(
                builder: (_) => AwardsFinalistsPage(category: selected),
              ),
            );
          } catch (_) {
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Unable to open this award category.'),
              ),
            );
          }
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _Photo(url: finalist.profilePhoto, height: double.infinity),
                  Positioned(
                    left: 9,
                    top: 9,
                    right: 38,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: _primary,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          finalist.categoryName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (finalist.verified)
                    Positioned(
                      right: 9,
                      top: 9,
                      child: Container(
                        width: 27,
                        height: 27,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.verified,
                          color: _primary,
                          size: 16,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 11),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        if (resultText != null) ...[
                          const SizedBox(height: 5),
                          Text(
                            resultText,
                            style: const TextStyle(
                              color: _primary,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 31,
                    height: 31,
                    decoration: const BoxDecoration(
                      color: _accent,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 19,
                    ),
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

class _Hero extends StatelessWidget {
  const _Hero({required this.award});
  final AwardCycle award;
  String _stage(String v) => v
      .split('_')
      .map((e) => e.isEmpty ? '' : e[0].toUpperCase() + e.substring(1))
      .join(' ');
  String _countdown() {
    final close = award.votingClosesAt;
    if (!award.votingIsOpen || close == null) return '';
    final x = close.difference(DateTime.now());
    if (x.isNegative) return 'Voting has closed';
    final d = x.inDays,
        h = x.inHours % 24,
        m = x.inMinutes % 60,
        s = x.inSeconds % 60;
    return '${d}d ${h}h ${m}m ${s}s remaining';
  }

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: _primary,
      borderRadius: BorderRadius.circular(AppRadii.hero),
      boxShadow: AppElevation.raised(context),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .13),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '${award.year} AWARDS',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
            const Spacer(),
            const Icon(Icons.workspace_premium, color: Colors.white),
          ],
        ),
        const SizedBox(height: 22),
        Text(
          award.title,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            height: 1.08,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          award.introduction,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.white.withValues(alpha: .82),
            height: 1.5,
          ),
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _Pill(text: _stage(award.stage)),
            _Pill(text: award.votingIsOpen ? 'Voting Open' : 'Voting Closed'),
            if (_countdown().isNotEmpty) _Pill(text: _countdown()),
          ],
        ),
      ],
    ),
  );
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .12),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w600,
        fontSize: 12,
      ),
    ),
  );
}

class AwardsCategoriesPage extends StatelessWidget {
  const AwardsCategoriesPage({super.key});
  @override
  Widget build(BuildContext context) => _FutureList<AwardCategory>(
    title: 'Award Categories',
    future: AwardsService.instance.fetchCategories(),
    empty: 'No award categories have been published.',
    builder: (c) => _CategoryCard(category: c),
  );
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.category});
  final AwardCategory category;
  @override
  Widget build(BuildContext context) => AppSurfaceCard(
    onTap:
        () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AwardsFinalistsPage(category: category),
          ),
        ),
    raised: true,
    child: Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: _primary.withValues(alpha: .08),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.workspace_premium_outlined, color: _primary),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                category.name,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              if (category.description.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  category.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 7),
              Text(
                '${category.finalistCount} finalists • ${category.votingStatus}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: _primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const Icon(Icons.chevron_right),
      ],
    ),
  );
}

class AwardsFinalistsPage extends StatefulWidget {
  const AwardsFinalistsPage({super.key, this.category});
  final AwardCategory? category;

  @override
  State<AwardsFinalistsPage> createState() => _AwardsFinalistsPageState();
}

class _AwardsFinalistsPageState extends State<AwardsFinalistsPage> {
  late Future<List<AwardFinalist>> _finalists;
  Future<AwardResultsData>? _results;
  final Set<int> _voting = <int>{};

  bool get _categoryPage => widget.category != null;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _finalists = AwardsService.instance.fetchFinalists(
      categoryId: widget.category?.id,
    );
    // Load public results on both All Finalists and category pages.
    // The backend still controls whether totals are hidden, percentage-only,
    // or fully visible.
    _results = AwardsService.instance.fetchResults();
  }

  Future<void> _refresh() async {
    setState(_load);
    await _finalists;
  }

  AwardFinalistResult? _result(AwardResultsData? data, AwardFinalist finalist) {
    if (data == null || data.isHidden) return null;
    for (final category in data.categories) {
      if (category.id != finalist.categoryId) continue;
      for (final item in category.finalists) {
        if (item.finalistId == finalist.id) return item;
      }
    }
    return null;
  }

  Future<void> _openCategory(AwardFinalist finalist) async {
    if (finalist.categoryId <= 0) return;
    try {
      final categories = await AwardsService.instance.fetchCategories();
      AwardCategory? selected;
      for (final category in categories) {
        if (category.id == finalist.categoryId) {
          selected = category;
          break;
        }
      }
      if (!mounted) return;
      if (selected == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This award category could not be opened.'),
          ),
        );
        return;
      }
      await Navigator.push<void>(
        context,
        MaterialPageRoute<void>(
          builder: (_) => AwardsFinalistsPage(category: selected),
        ),
      );
    } on Object catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_msg(e))));
      }
    }
  }

  Future<void> _openGuide(AwardFinalist finalist) async {
    if (finalist.guideUserId <= 0) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final CommunityMember guide = await CommunityService.instance.fetchMember(
        finalist.guideUserId,
      );
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      await Navigator.push<void>(
        context,
        MaterialPageRoute<void>(
          builder: (_) => ProviderProfilePage(member: guide),
        ),
      );
    } on Object catch (e) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_msg(e))));
    }
  }

  Future<void> _loginRequired() async {
    await showDialog<void>(
      context: context,
      builder:
          (c) => AlertDialog(
            title: const Text('Login Required'),
            content: const Text(
              'Please sign in or create an account to vote in the Tourist Guide Awards.',
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

  Future<void> _vote(AwardFinalist finalist) async {
    if (_voting.contains(finalist.id)) return;
    if (AuthService.instance.currentUser == null) {
      await _loginRequired();
      return;
    }
    if (finalist.hasVoted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You have already voted in this award category.'),
        ),
      );
      return;
    }
    if (!finalist.canVote) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Voting is not open for this category.')),
      );
      return;
    }

    final ok =
        await showDialog<bool>(
          context: context,
          builder:
              (c) => AlertDialog(
                title: Text('Vote for ${finalist.name}?'),
                content: Text(
                  'You are voting for ${finalist.name} in ${finalist.categoryName}. '
                  'Your vote cannot be changed after submission.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(c, false),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(c, true),
                    child: const Text('Confirm Vote'),
                  ),
                ],
              ),
        ) ??
        false;
    if (!ok || !mounted) return;

    setState(() => _voting.add(finalist.id));
    try {
      final response = await AwardsService.instance.vote(finalist.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            response['message']?.toString() ?? 'Your vote has been recorded.',
          ),
        ),
      );
      setState(_load);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _voting.remove(finalist.id));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF4EEE1),
    appBar: AppBar(title: Text(widget.category?.name ?? 'All Finalists')),
    body: FutureBuilder<List<AwardFinalist>>(
      future: _finalists,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _ErrorState(
            message: _msg(snapshot.error),
            retry: () => setState(_load),
          );
        }
        final finalists = snapshot.data ?? const <AwardFinalist>[];
        if (finalists.isEmpty) {
          return const Center(
            child: Text('No finalists have been published yet.'),
          );
        }

        return FutureBuilder<AwardResultsData>(
          future: _results,
          builder:
              (context, resultSnapshot) => _grid(
                finalists,
                resultSnapshot.data,
                resultSnapshot.connectionState == ConnectionState.waiting,
              ),
        );
      },
    ),
  );

  Widget _grid(
    List<AwardFinalist> finalists,
    AwardResultsData? results,
    bool loadingResults,
  ) {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final pad = constraints.maxWidth < 380 ? 12.0 : 16.0;
          final gap = constraints.maxWidth < 380 ? 10.0 : 14.0;
          return CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              if (_categoryPage)
                SliverToBoxAdapter(
                  child: _CategoryVotingSummary(
                    category: widget.category!,
                    finalistsCount: finalists.length,
                    results: results,
                    loading: loadingResults,
                  ),
                ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  pad,
                  _categoryPage ? 4 : 18,
                  pad,
                  32,
                ),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: gap,
                    mainAxisSpacing: gap,
                    childAspectRatio:
                        _categoryPage
                            ? (constraints.maxWidth < 380 ? .54 : .58)
                            : (constraints.maxWidth < 380 ? .55 : .59),
                  ),
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final finalist = finalists[index];
                    return _FinalistCard(
                      finalist: finalist,
                      isCategoryPage: _categoryPage,
                      result: _result(results, finalist),
                      resultsMode: results?.mode ?? 'hidden',
                      submitting: _voting.contains(finalist.id),
                      onVote: () => _vote(finalist),
                      onOpen:
                          () =>
                              _categoryPage
                                  ? _openGuide(finalist)
                                  : _openCategory(finalist),
                    );
                  }, childCount: finalists.length),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CategoryVotingSummary extends StatelessWidget {
  const _CategoryVotingSummary({
    required this.category,
    required this.finalistsCount,
    required this.results,
    required this.loading,
  });

  final AwardCategory category;
  final int finalistsCount;
  final AwardResultsData? results;
  final bool loading;

  String get _votingLabel {
    final value = category.votingStatus.trim();
    if (value.isEmpty) return 'Voting status';
    return value
        .replaceAll('_', ' ')
        .split(' ')
        .where((word) => word.isNotEmpty)
        .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }

  String _resultsLabel() {
    if (loading) return 'Loading results';
    if (results == null || results!.isHidden) return 'After voting closes';
    if (results!.mode == 'full') return 'Live vote totals';
    return 'Live percentages';
  }

  String _noticeText() {
    if (loading) return 'Loading voting statistics…';
    if (results == null || results!.isHidden) {
      return results?.message.trim().isNotEmpty == true
          ? results!.message
          : 'Voting results will be announced after voting closes.';
    }
    if (results!.mode == 'full') {
      var total = 0;
      for (final group in results!.categories) {
        if (group.id != category.id) continue;
        for (final item in group.finalists) {
          total += item.votes ?? 0;
        }
      }
      return '$total votes have been recorded in this category.';
    }
    return 'Live voting percentages are available for this category.';
  }

  @override
  Widget build(BuildContext context) {
    final description =
        category.description.trim().isEmpty
            ? 'Recognising outstanding tourist guides and the experiences they create.'
            : category.description.trim();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF124B4D),
                  Color(0xFF165B5D),
                  Color(0xFF1C696A),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: _primary.withValues(alpha: .18),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -28,
                  top: -36,
                  child: Container(
                    width: 125,
                    height: 125,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: .045),
                    ),
                  ),
                ),
                Positioned(
                  right: 34,
                  bottom: -54,
                  child: Container(
                    width: 105,
                    height: 105,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: .055),
                        width: 18,
                      ),
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: _accent,
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: const Icon(
                            Icons.workspace_premium_rounded,
                            color: Colors.white,
                            size: 23,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'TOURIST GUIDE AWARDS',
                            style: Theme.of(
                              context,
                            ).textTheme.labelMedium?.copyWith(
                              color: Colors.white.withValues(alpha: .78),
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.7,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    Text(
                      category.name,
                      style: Theme.of(
                        context,
                      ).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      description,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: .78),
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 22),
                    Container(
                      height: 1,
                      color: Colors.white.withValues(alpha: .12),
                    ),
                    const SizedBox(height: 17),
                    Row(
                      children: [
                        Expanded(
                          child: _CategoryHeroStat(
                            icon: Icons.groups_2_outlined,
                            value: '$finalistsCount',
                            label:
                                finalistsCount == 1 ? 'Finalist' : 'Finalists',
                          ),
                        ),
                        _CategoryHeroDivider(),
                        Expanded(
                          child: _CategoryHeroStat(
                            icon:
                                category.publicVotingEnabled
                                    ? Icons.how_to_vote_outlined
                                    : Icons.lock_outline_rounded,
                            value:
                                category.publicVotingEnabled
                                    ? 'Public'
                                    : 'Closed',
                            label: _votingLabel,
                          ),
                        ),
                        _CategoryHeroDivider(),
                        Expanded(
                          child: _CategoryHeroStat(
                            icon: Icons.bar_chart_rounded,
                            value:
                                results?.mode == 'full'
                                    ? 'Full'
                                    : results?.mode == 'percentage'
                                    ? '%'
                                    : 'Hidden',
                            label: _resultsLabel(),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .82),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _primary.withValues(alpha: .09)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _primary.withValues(alpha: .09),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    results != null && !results!.isHidden
                        ? Icons.insights_rounded
                        : Icons.info_outline_rounded,
                    color: _primary,
                    size: 19,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        results != null && !results!.isHidden
                            ? 'Voting statistics'
                            : 'Results announcement',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF1B1B1B),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _noticeText(),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.black.withValues(alpha: .62),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Text(
                'Finalists',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const Spacer(),
              Text(
                '$finalistsCount ${finalistsCount == 1 ? 'finalist' : 'finalists'}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: _primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CategoryHeroStat extends StatelessWidget {
  const _CategoryHeroStat({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Icon(icon, color: Colors.white, size: 20),
      const SizedBox(height: 6),
      Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w900,
        ),
      ),
      const SizedBox(height: 2),
      Text(
        label,
        maxLines: 2,
        textAlign: TextAlign.center,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Colors.white.withValues(alpha: .65),
          height: 1.15,
        ),
      ),
    ],
  );
}

class _CategoryHeroDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    width: 1,
    height: 54,
    color: Colors.white.withValues(alpha: .13),
  );
}

class _FinalistCard extends StatelessWidget {
  const _FinalistCard({
    required this.finalist,
    this.isCategoryPage = false,
    this.result,
    this.resultsMode = 'hidden',
    this.submitting = false,
    this.onVote,
    this.onOpen,
  });
  final AwardFinalist finalist;
  final bool isCategoryPage, submitting;
  final AwardFinalistResult? result;
  final String resultsMode;
  final VoidCallback? onVote, onOpen;

  String get _buttonText {
    if (submitting) return 'VOTING...';
    if (finalist.votedForThisFinalist) return 'VOTED ✓';
    if (finalist.hasVoted) return 'VOTE CAST';
    if (!finalist.canVote) return 'VOTING CLOSED';
    return 'VOTE';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name =
        finalist.name.trim().isEmpty ? 'Tourist Guide' : finalist.name.trim();

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 12,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _Photo(url: finalist.profilePhoto, height: double.infinity),
                  if (finalist.verified)
                    Positioned(
                      top: 9,
                      right: 9,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .96),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.verified, size: 13, color: _primary),
                            SizedBox(width: 3),
                            Text(
                              'Verified',
                              style: TextStyle(
                                color: _primary,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              flex: 10,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(11, 10, 11, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      finalist.categoryName,
                      maxLines: isCategoryPage ? 1 : 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: _accent,
                        fontWeight: FontWeight.w700,
                        fontSize: 10.5,
                      ),
                    ),
                    if (result != null) ...[
                      const SizedBox(height: 7),
                      _VoteStatistic(result: result!, mode: resultsMode),
                    ],
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 38,
                      child: FilledButton(
                        onPressed:
                            (submitting ||
                                    finalist.hasVoted ||
                                    !finalist.canVote)
                                ? null
                                : onVote,
                        style: FilledButton.styleFrom(
                          backgroundColor:
                              finalist.canVote && !finalist.hasVoted
                                  ? _accent
                                  : finalist.votedForThisFinalist
                                  ? const Color(0xFF72B493)
                                  : const Color(0xFF9A9A9A),
                          disabledBackgroundColor:
                              finalist.votedForThisFinalist
                                  ? const Color(0xFF72B493)
                                  : const Color(0xFF9A9A9A),
                          disabledForegroundColor: Colors.white,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          shape: const StadiumBorder(),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!submitting &&
                                (finalist.canVote ||
                                    finalist.votedForThisFinalist)) ...[
                              Container(
                                width: 22,
                                height: 22,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.check_rounded,
                                  size: 16,
                                  color:
                                      finalist.votedForThisFinalist
                                          ? const Color(0xFF4D9B78)
                                          : _accent,
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            Flexible(
                              child: Text(
                                _buttonText,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 11,
                                ),
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
          ],
        ),
      ),
    );
  }
}

class _VoteStatistic extends StatelessWidget {
  const _VoteStatistic({required this.result, required this.mode});
  final AwardFinalistResult result;
  final String mode;

  @override
  Widget build(BuildContext context) {
    final percentage = result.percentage.clamp(0, 100).toDouble();
    final label =
        mode == 'full' && result.votes != null
            ? '${result.votes} ${result.votes == 1 ? 'vote' : 'votes'} • ${percentage.toStringAsFixed(1)}%'
            : '${percentage.toStringAsFixed(1)}% of votes';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: _primary,
            fontWeight: FontWeight.w800,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: percentage / 100,
            minHeight: 5,
            backgroundColor: _primary.withValues(alpha: .10),
            valueColor: const AlwaysStoppedAnimation<Color>(_primary),
          ),
        ),
      ],
    );
  }
}

class FinalistProfilePage extends StatefulWidget {
  const FinalistProfilePage({super.key, required this.finalistId});
  final int finalistId;
  @override
  State<FinalistProfilePage> createState() => _FinalistProfilePageState();
}

class _FinalistProfilePageState extends State<FinalistProfilePage> {
  late Future<AwardFinalist> f;
  bool submitting = false;
  @override
  void initState() {
    super.initState();
    f = AwardsService.instance.fetchFinalist(widget.finalistId);
  }

  void reload() => setState(
    () => f = AwardsService.instance.fetchFinalist(widget.finalistId),
  );
  Future<void> vote(AwardFinalist x) async {
    if (AuthService.instance.currentUser == null) {
      await _loginRequired();
      return;
    }
    final ok =
        await showDialog<bool>(
          context: context,
          builder:
              (c) => AlertDialog(
                title: Text('Vote for ${x.name}?'),
                content: Text(
                  'You are voting for ${x.name} in ${x.categoryName}. Your vote cannot be changed after submission.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(c, false),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(c, true),
                    child: const Text('Confirm Vote'),
                  ),
                ],
              ),
        ) ??
        false;
    if (!ok) return;
    setState(() => submitting = true);
    try {
      final r = await AwardsService.instance.vote(x.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            r['message']?.toString() ?? 'Your vote has been recorded.',
          ),
        ),
      );
      reload();
    } on ApiException catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => submitting = false);
    }
  }

  Future<void> _loginRequired() async {
    await showDialog<void>(
      context: context,
      builder:
          (c) => AlertDialog(
            title: const Text('Login Required'),
            content: const Text(
              'Please sign in or create an account to vote in the Tourist Guide Awards.',
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

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Finalist Profile')),
    body: FutureBuilder<AwardFinalist>(
      future: f,
      builder: (context, s) {
        if (s.connectionState == ConnectionState.waiting)
          return const Center(child: CircularProgressIndicator());
        if (s.hasError)
          return _ErrorState(message: _msg(s.error), retry: reload);
        final x = s.data!;
        return ListView(
          padding: const EdgeInsets.only(bottom: 110),
          children: [
            _Photo(url: x.profilePhoto, height: 330),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          x.name,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                      if (x.verified) ...[
                        const Icon(Icons.verified, color: _primary),
                        const SizedBox(width: 4),
                        const Text(
                          'Verified Guide',
                          style: TextStyle(
                            color: _primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    x.categoryName,
                    style: const TextStyle(
                      color: _accent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _Info(label: 'Company / Association', value: x.company),
                  _Info(label: 'Region', value: x.region),
                  _Info(
                    label: 'Experience',
                    value:
                        x.yearsExperience > 0
                            ? '${x.yearsExperience} years'
                            : '',
                  ),
                  _Info(label: 'Languages', value: x.languages.join(', ')),
                  _Info(
                    label: 'Guiding Specialities',
                    value: x.specialities.join(', '),
                  ),
                  if (x.introduction.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      x.introduction,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        height: 1.45,
                      ),
                    ),
                  ],
                  if (x.biography.isNotEmpty) ...[
                    const SizedBox(height: 22),
                    const AppSectionHeader(title: 'Guide Story'),
                    const SizedBox(height: 10),
                    Text(x.biography, style: const TextStyle(height: 1.55)),
                  ],
                  if (x.achievements.isNotEmpty) ...[
                    const SizedBox(height: 22),
                    const AppSectionHeader(title: 'Recognition & Achievements'),
                    const SizedBox(height: 10),
                    Text(x.achievements, style: const TextStyle(height: 1.55)),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    ),
    bottomNavigationBar: FutureBuilder<AwardFinalist>(
      future: f,
      builder: (context, s) {
        if (!s.hasData) return const SizedBox.shrink();
        final x = s.data!;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton(
              onPressed:
                  (submitting || x.hasVoted || !x.canVote)
                      ? null
                      : () => vote(x),
              child: Text(
                submitting
                    ? 'SUBMITTING...'
                    : x.votedForThisFinalist
                    ? 'VOTED ✓'
                    : x.hasVoted
                    ? 'VOTE CAST'
                    : !x.canVote
                    ? 'VOTING CLOSED'
                    : 'VOTE FOR ${x.name.toUpperCase()}',
              ),
            ),
          ),
        );
      },
    ),
  );
}

class MyVotesPage extends StatelessWidget {
  const MyVotesPage({super.key});
  @override
  Widget build(BuildContext context) {
    if (AuthService.instance.currentUser == null)
      return Scaffold(
        appBar: AppBar(title: const Text('My Votes')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text('Please sign in to view your Awards votes.'),
          ),
        ),
      );
    return _FutureList<AwardVoteRecord>(
      title: 'My Votes',
      future: AwardsService.instance.fetchMyVotes(),
      empty: 'You have not voted in any award category yet.',
      builder:
          (v) => AppSurfaceCard(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(
                child: Icon(Icons.how_to_vote_outlined),
              ),
              title: Text(v.guideName),
              subtitle: Text('${v.categoryName}\n${_date(v.votedAt)}'),
              isThreeLine: true,
              trailing: Text(
                v.status,
                style: const TextStyle(
                  color: _primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
    );
  }
}

class AwardsWinnersPage extends StatelessWidget {
  const AwardsWinnersPage({super.key});
  @override
  Widget build(BuildContext context) => _FutureList<AwardWinner>(
    title: 'Award Winners',
    future: AwardsService.instance.fetchWinners(),
    empty: 'Winners have not been announced yet.',
    builder: (w) => _WinnerCard(winner: w),
  );
}

class _WinnerCard extends StatelessWidget {
  const _WinnerCard({required this.winner});
  final AwardWinner winner;
  @override
  Widget build(BuildContext context) => AppSurfaceCard(
    raised: true,
    child: Row(
      children: [
        SizedBox(
          width: 72,
          height: 72,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: _Photo(url: winner.profilePhoto, height: 72),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.emoji_events, color: _accent, size: 18),
                  const SizedBox(width: 5),
                  Text(
                    winner.year > 0 ? '${winner.year} WINNER' : 'WINNER',
                    style: const TextStyle(
                      color: _accent,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                winner.name,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              Text(winner.categoryName),
              if (winner.statement.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  winner.statement,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ],
    ),
  );
}

class _Info extends StatelessWidget {
  const _Info({required this.label, required this.value});
  final String label, value;
  @override
  Widget build(BuildContext context) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: .55),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _Photo extends StatelessWidget {
  const _Photo({required this.url, required this.height});
  final String url;
  final double height;
  @override
  Widget build(BuildContext context) {
    final u = AuthService.storageUrl(url);
    return Container(
      height: height,
      width: double.infinity,
      color: _primary.withValues(alpha: .08),
      child:
          u.isEmpty
              ? const Icon(Icons.person_outline, size: 64, color: _primary)
              : Image.network(
                u,
                fit: BoxFit.cover,
                errorBuilder:
                    (_, __, ___) => const Icon(
                      Icons.person_outline,
                      size: 64,
                      color: _primary,
                    ),
              ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.icon, required this.text});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => AppSurfaceCard(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Column(
        children: [
          Icon(icon, size: 34, color: _primary),
          const SizedBox(height: 10),
          Text(text, textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.retry});
  final String message;
  final VoidCallback retry;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 42),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton(onPressed: retry, child: const Text('Try Again')),
        ],
      ),
    ),
  );
}

class _FutureList<T> extends StatelessWidget {
  const _FutureList({
    required this.title,
    required this.future,
    required this.empty,
    required this.builder,
  });
  final String title, empty;
  final Future<List<T>> future;
  final Widget Function(T) builder;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: FutureBuilder<List<T>>(
      future: future,
      builder: (context, s) {
        if (s.connectionState == ConnectionState.waiting)
          return const Center(child: CircularProgressIndicator());
        if (s.hasError)
          return _ErrorState(
            message: _msg(s.error),
            retry:
                () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => this),
                ),
          );
        final items = s.data ?? [];
        if (items.isEmpty)
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(empty, textAlign: TextAlign.center),
            ),
          );
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, i) => builder(items[i]),
        );
      },
    ),
  );
}

String _msg(Object? e) =>
    e is ApiException ? e.message : e?.toString() ?? 'Something went wrong.';
String _date(DateTime? d) =>
    d == null
        ? ''
        : '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
