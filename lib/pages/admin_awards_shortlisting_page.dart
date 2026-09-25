import 'package:flutter/material.dart';

import '../models/admin_award_shortlisting.dart';
import '../services/admin_awards_service.dart';
import '../services/auth_service.dart';

class AdminAwardsShortlistingPage extends StatefulWidget {
  const AdminAwardsShortlistingPage({super.key, this.awardCycleId = 1});
  final int awardCycleId;

  @override
  State<AdminAwardsShortlistingPage> createState() =>
      _AdminAwardsShortlistingPageState();
}

class _AdminAwardsShortlistingPageState
    extends State<AdminAwardsShortlistingPage> {
  static const _green = Color(0xFF165B5D);
  static const _orange = Color(0xFFF46627);
  static const _background = Color(0xFFF4EEE1);

  bool _loading = true;
  bool _calculating = false;
  int? _confirmingCategoryId;
  String? _error;
  AdminAwardShortlistingData? _data;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await AdminAwardsService.instance.shortlisting(
        widget.awardCycleId,
      );
      if (!mounted) return;
      setState(() => _data = data);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('ApiException: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _calculate() async {
    if (_calculating) return;
    setState(() => _calculating = true);
    try {
      final data = await AdminAwardsService.instance.calculateShortlisting(
        widget.awardCycleId,
      );
      if (!mounted) return;
      setState(() => _data = data);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Shortlisting scores recalculated.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (mounted) _errorSnack(e);
    } finally {
      if (mounted) setState(() => _calculating = false);
    }
  }

  Future<void> _confirm(
    AdminAwardCategorySummary category,
    List<AdminAwardShortlistingScore> scores,
  ) async {
    final eligible =
        scores.where((e) => e.eligible).toList()
          ..sort((a, b) => a.ranking.compareTo(b.ranking));
    final selected = eligible.take(category.finalistLimit).toList();

    if (selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No eligible ranked nominees to confirm.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final ok = await showDialog<bool>(
      context: context,
      builder:
          (c) => AlertDialog(
            title: Text('Confirm ${category.name} finalists?'),
            content: Text(
              'This will confirm ${selected.length} eligible '
              '${selected.length == 1 ? 'nominee' : 'nominees'} as finalists.\n\n'
              'Finalist limit: ${category.finalistLimit}\n\n'
              'The automated ranking supports the review process; '
              'the final confirmation is an admin decision.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(c, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(c, true),
                child: const Text('Confirm Finalists'),
              ),
            ],
          ),
    );
    if (ok != true) return;

    setState(() => _confirmingCategoryId = category.id);
    try {
      await AdminAwardsService.instance.confirmFinalists(
        category.id,
        nominationIds: selected.map((e) => e.nominationId).toList(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${category.name} finalists confirmed.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      await _load();
    } catch (e) {
      if (mounted) _errorSnack(e);
    } finally {
      if (mounted) setState(() => _confirmingCategoryId = null);
    }
  }

  void _errorSnack(Object e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(e.toString().replaceFirst('ApiException: ', '')),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String? _photo(String? path) {
    if (path == null || path.trim().isEmpty) return null;
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    return AuthService.storageUrl(path);
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _green,
        foregroundColor: Colors.white,
        title: const Text('Judging & Shortlisting'),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 32),
          children: [
            if (data != null) _header(data),
            if (data != null) const SizedBox(height: 15),
            if (data != null) _controls(data),
            const SizedBox(height: 15),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(44),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              _message(_error!)
            else if (data != null)
              ...data.categories
                  .where((e) => e.isActive)
                  .map((category) => _category(data, category)),
          ],
        ),
      ),
    );
  }

  Widget _header(AdminAwardShortlistingData data) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: _green,
      borderRadius: BorderRadius.circular(22),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.military_tech_outlined, color: Colors.white, size: 35),
        const SizedBox(height: 10),
        Text(
          data.award.title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 21,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          '${data.award.year} • ${data.award.stage.replaceAll('_', ' ').toUpperCase()}',
          style: const TextStyle(
            color: Colors.white70,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          '${data.scores.length} ranked nominations',
          style: const TextStyle(color: Colors.white70),
        ),
      ],
    ),
  );

  Widget _controls(AdminAwardShortlistingData data) => Container(
    padding: const EdgeInsets.all(17),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Automated assessment',
          style: TextStyle(
            color: _green,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 5),
        const Text(
          'Scores support judging. They do not automatically create finalists.',
          style: TextStyle(color: Color(0xFF667068), height: 1.4),
        ),
        const SizedBox(height: 13),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed:
                data.award.stage == 'judging' && !_calculating
                    ? _calculate
                    : null,
            icon:
                _calculating
                    ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                    : const Icon(Icons.refresh),
            label: Text(_calculating ? 'Calculating...' : 'Recalculate Scores'),
          ),
        ),
      ],
    ),
  );

  Widget _category(
    AdminAwardShortlistingData data,
    AdminAwardCategorySummary category,
  ) {
    final scores =
        data.scores.where((e) => e.categoryId == category.id).toList()
          ..sort((a, b) => a.ranking.compareTo(b.ranking));
    final eligible = scores.where((e) => e.eligible).length;
    final confirming = _confirmingCategoryId == category.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 17, vertical: 8),
        childrenPadding: const EdgeInsets.fromLTRB(15, 0, 15, 16),
        title: Text(
          category.name,
          style: const TextStyle(color: _green, fontWeight: FontWeight.w800),
        ),
        subtitle: Text(
          '${scores.length} ranked • $eligible eligible • '
          'Limit ${category.finalistLimit}',
          style: const TextStyle(fontSize: 12, color: Color(0xFF737D75)),
        ),
        children: [
          if (scores.isEmpty)
            const Padding(
              padding: EdgeInsets.all(15),
              child: Text(
                'No verified nominees ranked in this category.',
                textAlign: TextAlign.center,
              ),
            )
          else ...[
            ...scores.map(_score),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: _orange),
                onPressed:
                    data.award.stage == 'judging' && !confirming
                        ? () => _confirm(category, scores)
                        : null,
                icon:
                    confirming
                        ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                        : const Icon(Icons.workspace_premium_outlined),
                label: Text(
                  confirming ? 'Confirming...' : 'Confirm Top Finalists',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _score(AdminAwardShortlistingScore score) {
    final image = _photo(score.profilePhoto);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _background.withValues(alpha: .55),
        borderRadius: BorderRadius.circular(17),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 19,
                backgroundColor: _green,
                child: Text(
                  '#${score.ranking}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 9),
              CircleAvatar(
                radius: 24,
                backgroundColor: _green.withValues(alpha: .1),
                backgroundImage: image == null ? null : NetworkImage(image),
                child:
                    image == null
                        ? const Icon(Icons.person_outline, color: _green)
                        : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      score.guideName,
                      style: const TextStyle(
                        color: _green,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      [
                        if ((score.country ?? '').isNotEmpty) score.country!,
                        if (score.yearsExperience > 0)
                          '${score.yearsExperience} yrs',
                        score.providerVerificationStatus == 'verified'
                            ? 'Verified provider'
                            : 'Provider ${score.providerVerificationStatus}',
                      ].join(' • '),
                      style: const TextStyle(
                        color: Color(0xFF737D75),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                score.totalScore.toStringAsFixed(2),
                style: const TextStyle(
                  color: _green,
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color:
                  score.eligible
                      ? _green.withValues(alpha: .08)
                      : _orange.withValues(alpha: .10),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Text(
              score.eligibilityReason,
              style: TextStyle(
                color: score.eligible ? _green : _orange,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            dense: true,
            title: const Text(
              'Score breakdown',
              style: TextStyle(
                color: _green,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
            children: [
              _row('Profile & verification', score.profileScore, 15),
              _row('Professional experience', score.experienceScore, 15),
              _row('Category relevance', score.categoryRelevanceScore, 25),
              _row('Visitor reputation', score.visitorReputationScore, 25),
              _row(
                'Nomination assessment',
                score.nominationAssessmentScore,
                10,
              ),
              _row('Supporting evidence', score.supportingEvidenceScore, 10),
            ],
          ),
        ],
      ),
    );
  }

  Widget _row(String label, double score, int max) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Expanded(child: Text(label, style: const TextStyle(fontSize: 12.5))),
        Text(
          '${_num(score)} / $max',
          style: const TextStyle(
            color: _green,
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );

  String _num(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(2);

  Widget _message(String text) => Container(
    padding: const EdgeInsets.all(25),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      children: [
        const Icon(Icons.error_outline, size: 40, color: Color(0xFF9EAAA1)),
        const SizedBox(height: 8),
        Text(text, textAlign: TextAlign.center),
        TextButton.icon(
          onPressed: _load,
          icon: const Icon(Icons.refresh),
          label: const Text('Try Again'),
        ),
      ],
    ),
  );
}
