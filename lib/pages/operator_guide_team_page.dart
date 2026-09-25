import 'dart:async';

import 'package:flutter/material.dart';

import '../models/community.dart';
import '../models/guide_affiliation.dart';
import '../services/api_exception.dart';
import '../services/community_service.dart';

class OperatorGuideTeamPage extends StatefulWidget {
  const OperatorGuideTeamPage({super.key});

  @override
  State<OperatorGuideTeamPage> createState() => _OperatorGuideTeamPageState();
}

class _OperatorGuideTeamPageState extends State<OperatorGuideTeamPage> {
  late Future<OperatorGuideTeamSummary> _team;
  bool _working = false;

  @override
  void initState() {
    super.initState();
    _team = CommunityService.instance.fetchOperatorGuideTeam();
  }

  void _reload() {
    setState(() {
      _team = CommunityService.instance.fetchOperatorGuideTeam();
    });
  }

  Future<void> _inviteGuide() async {
    final result = await showModalBottomSheet<_OperatorInvitePayload>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _InviteGuideSheet(),
    );

    if (result == null || !mounted) return;

    await _run(() async {
      await CommunityService.instance.inviteGuideToOperator(
        guideUserId: result.guideId,
        relationshipType: result.relationshipType,
        publicVisibility: result.publicVisibility,
      );

      _message('Guide invitation sent.');
      _reload();
    });
  }

  Future<void> _acceptRequest(GuideOperatorAffiliation item) async {
    await _run(() async {
      await CommunityService.instance.acceptGuideAffiliationRequest(item.id);
      _message('Guide affiliation request accepted.');
      _reload();
    });
  }

  Future<void> _declineRequest(GuideOperatorAffiliation item) async {
    final confirmed = await _confirm(
      'Decline this guide request?',
      'The request will be marked as declined.',
      'Decline',
    );

    if (confirmed != true) return;

    await _run(() async {
      await CommunityService.instance.declineGuideAffiliationRequest(item.id);
      _message('Guide affiliation request declined.');
      _reload();
    });
  }

  Future<void> _editPermissions(GuideOperatorAffiliation item) async {
    final result = await showModalBottomSheet<_OperatorPermissionsPayload>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _OperatorPermissionsSheet(affiliation: item),
    );

    if (result == null || !mounted) return;

    await _run(() async {
      await CommunityService.instance.updateOperatorGuidePermissions(
        affiliationId: item.id,
        relationshipType: result.relationshipType,
      );

      _message('Guide relationship updated.');
      _reload();
    });
  }

  Future<void> _end(GuideOperatorAffiliation item) async {
    final confirmed = await _confirm(
      item.isPending ? 'Cancel this invitation?' : 'Remove guide from team?',
      item.isPending
          ? 'The pending invitation will be closed.'
          : 'This professional affiliation will be ended.',
      item.isPending ? 'Cancel invitation' : 'End affiliation',
    );

    if (confirmed != true) return;

    await _run(() async {
      await CommunityService.instance.endOperatorGuideAffiliation(item.id);
      _message(
        item.isPending ? 'Invitation cancelled.' : 'Guide affiliation ended.',
      );
      _reload();
    });
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_working) return;

    setState(() => _working = true);

    try {
      await action();
    } on ApiException catch (error) {
      if (mounted) _message(error.message);
    } catch (_) {
      if (mounted) _message('The guide-team action could not be completed.');
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<bool?> _confirm(String title, String message, String confirmLabel) {
    return showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(confirmLabel),
              ),
            ],
          ),
    );
  }

  void _message(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      appBar: AppBar(title: const Text('Our Safari Team')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _working ? null : _inviteGuide,
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('Invite guide'),
      ),
      body: RefreshIndicator(
        onRefresh: () async => _reload(),
        child: FutureBuilder<OperatorGuideTeamSummary>(
          future: _team,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError || !snapshot.hasData) {
              return ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  const SizedBox(height: 110),
                  Icon(
                    Icons.groups_outlined,
                    size: 52,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Your safari team could not be loaded.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Center(
                    child: OutlinedButton.icon(
                      onPressed: _reload,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Try again'),
                    ),
                  ),
                ],
              );
            }

            final team = snapshot.data!;
            final guideRequests =
                team.pending.where((item) => item.requestedByGuide).toList();
            final operatorInvites =
                team.pending.where((item) => item.requestedByOperator).toList();

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
              children: [
                _TeamHero(
                  activeCount: team.activeTeam.length,
                  pendingCount: team.pending.length,
                ),
                if (guideRequests.isNotEmpty) ...[
                  const SizedBox(height: 26),
                  const _TeamSectionTitle(
                    title: 'Guide Requests',
                    subtitle:
                        'Guides who have asked to be affiliated with your company.',
                  ),
                  const SizedBox(height: 12),
                  ...guideRequests.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _OperatorTeamCard(
                        affiliation: item,
                        working: _working,
                        onAccept: () => _acceptRequest(item),
                        onDecline: () => _declineRequest(item),
                        onEdit: null,
                        onEnd: null,
                      ),
                    ),
                  ),
                ],
                if (team.activeTeam.isNotEmpty) ...[
                  const SizedBox(height: 26),
                  const _TeamSectionTitle(
                    title: 'Active Safari Team',
                    subtitle:
                        'Guides currently affiliated with your tour company.',
                  ),
                  const SizedBox(height: 12),
                  ...team.activeTeam.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _OperatorTeamCard(
                        affiliation: item,
                        working: _working,
                        onAccept: null,
                        onDecline: null,
                        onEdit: () => _editPermissions(item),
                        onEnd: () => _end(item),
                      ),
                    ),
                  ),
                ],
                if (operatorInvites.isNotEmpty) ...[
                  const SizedBox(height: 26),
                  const _TeamSectionTitle(
                    title: 'Pending Invitations',
                    subtitle: 'Guides you invited who have not responded yet.',
                  ),
                  const SizedBox(height: 12),
                  ...operatorInvites.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _OperatorTeamCard(
                        affiliation: item,
                        working: _working,
                        onAccept: null,
                        onDecline: null,
                        onEdit: null,
                        onEnd: () => _end(item),
                      ),
                    ),
                  ),
                ],
                if (team.affiliations.isEmpty) ...[
                  const SizedBox(height: 26),
                  _NoTeamCard(onPressed: _inviteGuide),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _TeamHero extends StatelessWidget {
  const _TeamHero({required this.activeCount, required this.pendingCount});

  final int activeCount;
  final int pendingCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colors.primary,
            Color.lerp(colors.primary, colors.secondary, .44)!,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.diversity_3_rounded, color: Colors.white, size: 34),
          const SizedBox(height: 15),
          Text(
            'Build Your Safari Team',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            'Invite trusted guides, confirm guide requests, and control independent-work permissions.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withOpacity(.78),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _HeroMetric(value: '$activeCount', label: 'Active guides'),
              const SizedBox(width: 10),
              _HeroMetric(value: '$pendingCount', label: 'Pending'),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(.12),
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: Colors.white.withOpacity(.16)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(.72),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OperatorTeamCard extends StatelessWidget {
  const _OperatorTeamCard({
    required this.affiliation,
    required this.working,
    required this.onAccept,
    required this.onDecline,
    required this.onEdit,
    required this.onEnd,
  });

  final GuideOperatorAffiliation affiliation;
  final bool working;
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;
  final VoidCallback? onEdit;
  final VoidCallback? onEnd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final guide = affiliation.guide;

    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(23),
        border: Border.all(color: colors.outlineVariant.withOpacity(.65)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _GuideAvatar(guide: guide),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      guide?.displayName ?? 'Tourist guide',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      affiliation.relationshipLabel,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurface.withOpacity(.58),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              _TeamStatusChip(affiliation: affiliation),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: colors.primary.withOpacity(.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colors.primary.withOpacity(.14)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.shield_outlined, size: 18, color: colors.primary),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'This team relationship does not control the guide’s independent tours, proposals or bookings.',
                    style: TextStyle(
                      fontSize: 11.5,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                affiliation.isPublic
                    ? Icons.public_rounded
                    : Icons.lock_outline_rounded,
                color: colors.primary,
                size: 17,
              ),
              const SizedBox(width: 6),
              Text(
                affiliation.isPublic
                    ? 'Public affiliation'
                    : 'Private affiliation',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          if (onAccept != null || onDecline != null) ...[
            const SizedBox(height: 15),
            Row(
              children: [
                if (onDecline != null)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: working ? null : onDecline,
                      child: const Text('Decline'),
                    ),
                  ),
                if (onDecline != null && onAccept != null)
                  const SizedBox(width: 9),
                if (onAccept != null)
                  Expanded(
                    child: FilledButton(
                      onPressed: working ? null : onAccept,
                      child: const Text('Accept'),
                    ),
                  ),
              ],
            ),
          ],
          if (onEdit != null || onEnd != null) ...[
            const SizedBox(height: 15),
            Row(
              children: [
                if (onEdit != null)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: working ? null : onEdit,
                      icon: const Icon(Icons.tune_rounded),
                      label: const Text('Permissions'),
                    ),
                  ),
                if (onEdit != null && onEnd != null) const SizedBox(width: 9),
                if (onEnd != null)
                  IconButton.filledTonal(
                    tooltip:
                        affiliation.isPending
                            ? 'Cancel invitation'
                            : 'End affiliation',
                    onPressed: working ? null : onEnd,
                    icon: const Icon(Icons.person_remove_alt_1_outlined),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _InviteGuideSheet extends StatefulWidget {
  const _InviteGuideSheet();

  @override
  State<_InviteGuideSheet> createState() => _InviteGuideSheetState();
}

class _InviteGuideSheetState extends State<_InviteGuideSheet> {
  final TextEditingController _searchController = TextEditingController();

  Timer? _debounce;
  CommunityMember? _selectedGuide;
  List<CommunityMember> _results = const [];
  bool _searching = false;
  String _searchError = '';

  String _relationship = 'employee';
  String _visibility = 'private';

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();

    if (_selectedGuide != null && value.trim() != _selectedGuide!.name.trim()) {
      setState(() {
        _selectedGuide = null;
      });
    }

    final query = value.trim();

    if (query.length < 2) {
      setState(() {
        _results = const [];
        _searchError = '';
        _searching = false;
      });
      return;
    }

    setState(() {
      _searching = true;
      _searchError = '';
    });

    _debounce = Timer(const Duration(milliseconds: 350), () {
      _searchGuides(query);
    });
  }

  Future<void> _searchGuides(String query) async {
    try {
      final results = await CommunityService.instance.searchTouristGuides(
        query,
      );

      if (!mounted) return;

      if (_searchController.text.trim() != query) {
        return;
      }

      setState(() {
        _results = results;
        _searching = false;
        _searchError = '';
      });
    } on ApiException catch (error) {
      if (!mounted) return;

      setState(() {
        _results = const [];
        _searching = false;
        _searchError = error.message;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _results = const [];
        _searching = false;
        _searchError = 'Tourist guides could not be searched.';
      });
    }
  }

  void _selectGuide(CommunityMember guide) {
    setState(() {
      _selectedGuide = guide;
      _results = const [];
      _searchError = '';
      _searchController.text = guide.name;
      _searchController.selection = TextSelection.collapsed(
        offset: _searchController.text.length,
      );
    });

    FocusScope.of(context).unfocus();
  }

  void _clearGuide() {
    setState(() {
      _selectedGuide = null;
      _results = const [];
      _searchError = '';
      _searchController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Material(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        clipBehavior: Clip.antiAlias,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                    color: colors.onSurface.withOpacity(.16),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Invite a Tourist Guide',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Type the guide name. Matching registered guides will appear as you type.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurface.withOpacity(.62),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),

              TextField(
                controller: _searchController,
                autofocus: true,
                onChanged: _onSearchChanged,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  labelText: 'Search tourist guide',
                  hintText: 'Type at least 2 letters',
                  prefixIcon: const Icon(Icons.person_search_outlined),
                  suffixIcon:
                      _selectedGuide != null
                          ? IconButton(
                            tooltip: 'Change guide',
                            onPressed: _clearGuide,
                            icon: const Icon(Icons.close_rounded),
                          )
                          : _searching
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

              if (_selectedGuide != null) ...[
                const SizedBox(height: 10),
                _SelectedGuideCard(
                  guide: _selectedGuide!,
                  onClear: _clearGuide,
                ),
              ],

              if (_selectedGuide == null && _searchError.isNotEmpty) ...[
                const SizedBox(height: 9),
                Text(
                  _searchError,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.error,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],

              if (_selectedGuide == null && _results.isNotEmpty) ...[
                const SizedBox(height: 9),
                Container(
                  constraints: const BoxConstraints(maxHeight: 300),
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: colors.outlineVariant.withOpacity(.72),
                    ),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    itemCount: _results.length,
                    separatorBuilder:
                        (_, __) => Divider(
                          height: 1,
                          color: colors.outlineVariant.withOpacity(.62),
                        ),
                    itemBuilder: (context, index) {
                      final guide = _results[index];

                      return _GuideSearchResultCard(
                        guide: guide,
                        onTap: () => _selectGuide(guide),
                      );
                    },
                  ),
                ),
              ],

              const SizedBox(height: 18),

              DropdownButtonFormField<String>(
                value: _relationship,
                decoration: const InputDecoration(
                  labelText: 'Relationship',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
                items: const [
                  DropdownMenuItem(value: 'employee', child: Text('Employee')),
                  DropdownMenuItem(
                    value: 'contractor',
                    child: Text('Contractor'),
                  ),
                  DropdownMenuItem(value: 'partner', child: Text('Partner')),
                  DropdownMenuItem(
                    value: 'associate',
                    child: Text('Associate'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _relationship = value);
                },
              ),
              const SizedBox(height: 14),

              DropdownButtonFormField<String>(
                value: _visibility,
                decoration: const InputDecoration(
                  labelText: 'Public profile visibility',
                  prefixIcon: Icon(Icons.visibility_outlined),
                ),
                items: const [
                  DropdownMenuItem(value: 'private', child: Text('Private')),
                  DropdownMenuItem(value: 'public', child: Text('Public')),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _visibility = value);
                },
              ),

              const SizedBox(height: 12),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest.withOpacity(.45),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Text(
                  'This invitation creates a professional team relationship only. The guide keeps control of their own independent marketplace activity.',
                  style: TextStyle(height: 1.45),
                ),
              ),

              const SizedBox(height: 18),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton.icon(
                  onPressed:
                      _selectedGuide == null
                          ? null
                          : () {
                            Navigator.pop(
                              context,
                              _OperatorInvitePayload(
                                guideId: _selectedGuide!.id,
                                relationshipType: _relationship,
                                publicVisibility: _visibility,
                              ),
                            );
                          },
                  icon: const Icon(Icons.send_rounded),
                  label: Text(
                    _selectedGuide == null
                        ? 'Select a guide first'
                        : 'Send invitation',
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

class _SelectedGuideCard extends StatelessWidget {
  const _SelectedGuideCard({required this.guide, required this.onClear});

  final CommunityMember guide;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final country = guide.country.trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.primary.withOpacity(.065),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.primary.withOpacity(.22)),
      ),
      child: Row(
        children: [
          _GuideSearchAvatar(guide: guide, large: true),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        guide.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    if (guide.isVerified) ...[
                      const SizedBox(width: 5),
                      Icon(
                        Icons.verified_rounded,
                        color: colors.primary,
                        size: 18,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 5),
                if (country.isNotEmpty)
                  Row(
                    children: [
                      Text(
                        _countryFlag(country),
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Based in $country',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.onSurface.withOpacity(.62),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                if (guide.languages.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    guide.languages.take(3).join(' • '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurface.withOpacity(.50),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: colors.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              color: Colors.white,
              size: 19,
            ),
          ),
          const SizedBox(width: 2),
          IconButton(
            tooltip: 'Change guide',
            onPressed: onClear,
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }
}

class _GuideSearchResultCard extends StatelessWidget {
  const _GuideSearchResultCard({required this.guide, required this.onTap});

  final CommunityMember guide;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final country = guide.country.trim();

    final details = <String>[
      if (guide.languages.isNotEmpty) guide.languages.take(2).join(', '),
      if (guide.yearsExperience > 0)
        '${guide.yearsExperience} yr${guide.yearsExperience == 1 ? '' : 's'} experience',
    ];

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
          child: Row(
            children: [
              _GuideSearchAvatar(guide: guide),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            guide.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        if (guide.isVerified) ...[
                          const SizedBox(width: 5),
                          Icon(
                            Icons.verified_rounded,
                            color: colors.primary,
                            size: 17,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 5),
                    if (country.isNotEmpty)
                      Row(
                        children: [
                          Text(
                            _countryFlag(country),
                            style: const TextStyle(fontSize: 15),
                          ),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              'Based in $country',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colors.onSurface.withOpacity(.62),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    if (details.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        details.join(' • '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurface.withOpacity(.48),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: colors.primaryContainer.withOpacity(.72),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.add_rounded, color: colors.primary, size: 19),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GuideSearchAvatar extends StatelessWidget {
  const _GuideSearchAvatar({required this.guide, this.large = false});

  final CommunityMember guide;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final initials =
        guide.name
            .trim()
            .split(RegExp(r'\s+'))
            .where((part) => part.isNotEmpty)
            .take(2)
            .map((part) => part[0].toUpperCase())
            .join();

    final fallback = Container(
      alignment: Alignment.center,
      color: colors.primaryContainer,
      child: Text(
        initials,
        style: TextStyle(
          color: colors.onPrimaryContainer,
          fontWeight: FontWeight.w900,
        ),
      ),
    );

    return Container(
      width: large ? 54 : 46,
      height: large ? 54 : 46,
      padding: const EdgeInsets.all(1.5),
      decoration: BoxDecoration(color: colors.primary, shape: BoxShape.circle),
      child: ClipOval(
        child:
            guide.profilePhotoUrl.isEmpty
                ? fallback
                : Image.network(
                  guide.profilePhotoUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => fallback,
                ),
      ),
    );
  }
}

String _countryFlag(String country) {
  const codes = <String, String>{
    'uganda': 'UG',
    'kenya': 'KE',
    'tanzania': 'TZ',
    'rwanda': 'RW',
    'burundi': 'BI',
    'congo': 'CD',
    'democratic republic of the congo': 'CD',
    'dr congo': 'CD',
    'south africa': 'ZA',
    'zambia': 'ZM',
    'zimbabwe': 'ZW',
    'botswana': 'BW',
    'namibia': 'NA',
    'ethiopia': 'ET',
    'canada': 'CA',
    'united states': 'US',
    'united states of america': 'US',
    'usa': 'US',
    'united kingdom': 'GB',
    'uk': 'GB',
    'spain': 'ES',
    'germany': 'DE',
    'france': 'FR',
    'italy': 'IT',
    'australia': 'AU',
    'japan': 'JP',
    'china': 'CN',
    'india': 'IN',
  };

  final code = codes[country.trim().toLowerCase()];
  if (code == null || code.length != 2) return '🌍';

  return String.fromCharCodes(code.codeUnits.map((unit) => unit + 127397));
}

class _OperatorPermissionsSheet extends StatefulWidget {
  const _OperatorPermissionsSheet({required this.affiliation});

  final GuideOperatorAffiliation affiliation;

  @override
  State<_OperatorPermissionsSheet> createState() =>
      _OperatorPermissionsSheetState();
}

class _OperatorPermissionsSheetState extends State<_OperatorPermissionsSheet> {
  late String _relationship = widget.affiliation.relationshipType;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Material(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        clipBehavior: Clip.antiAlias,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                    color: colors.onSurface.withOpacity(.16),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Team Relationship',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Update how this guide is connected to your tour operator team.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurface.withOpacity(.62),
                ),
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: _relationship,
                decoration: const InputDecoration(
                  labelText: 'Relationship',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
                items: const [
                  DropdownMenuItem(value: 'employee', child: Text('Employee')),
                  DropdownMenuItem(
                    value: 'contractor',
                    child: Text('Contractor'),
                  ),
                  DropdownMenuItem(value: 'partner', child: Text('Partner')),
                  DropdownMenuItem(
                    value: 'associate',
                    child: Text('Associate'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _relationship = value);
                  }
                },
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colors.primary.withOpacity(.06),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: colors.primary.withOpacity(.16)),
                ),
                child: const Text(
                  'A team relationship does not give your company access to or control over the guide’s independent proposals, bookings, messages or guide-led tours.',
                  style: TextStyle(height: 1.45),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(
                      context,
                      _OperatorPermissionsPayload(
                        relationshipType: _relationship,
                      ),
                    );
                  },
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Save relationship'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OperatorInvitePayload {
  const _OperatorInvitePayload({
    required this.guideId,
    required this.relationshipType,
    required this.publicVisibility,
  });

  final int guideId;
  final String relationshipType;
  final String publicVisibility;
}

class _OperatorPermissionsPayload {
  const _OperatorPermissionsPayload({required this.relationshipType});

  final String relationshipType;
}

class _GuideAvatar extends StatelessWidget {
  const _GuideAvatar({required this.guide});

  final AffiliationPerson? guide;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final url = guide?.profilePhotoUrl ?? '';
    final name = guide?.displayName ?? '';
    final initials =
        name
            .split(RegExp(r'\s+'))
            .where((item) => item.isNotEmpty)
            .take(2)
            .map((item) => item[0].toUpperCase())
            .join();

    final fallback = Container(
      alignment: Alignment.center,
      color: colors.primaryContainer,
      child: Text(
        initials,
        style: TextStyle(
          color: colors.onPrimaryContainer,
          fontWeight: FontWeight.w900,
        ),
      ),
    );

    return Container(
      width: 54,
      height: 54,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(color: colors.primary, shape: BoxShape.circle),
      child: ClipOval(
        child:
            url.isEmpty
                ? fallback
                : Image.network(
                  url,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => fallback,
                ),
      ),
    );
  }
}

class _PermissionTile extends StatelessWidget {
  const _PermissionTile({
    required this.icon,
    required this.title,
    required this.allowed,
  });

  final IconData icon;
  final String title;
  final bool allowed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withOpacity(.45),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            allowed ? Icons.check_circle_rounded : Icons.block_rounded,
            color: allowed ? colors.primary : colors.error,
            size: 19,
          ),
          const SizedBox(height: 6),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _TeamStatusChip extends StatelessWidget {
  const _TeamStatusChip({required this.affiliation});

  final GuideOperatorAffiliation affiliation;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final color =
        affiliation.isActive
            ? colors.primary
            : affiliation.isPending
            ? colors.secondary
            : colors.outline;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        affiliation.statusLabel,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _TeamSectionTitle extends StatelessWidget {
  const _TeamSectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(.58),
            height: 1.35,
          ),
        ),
      ],
    );
  }
}

class _NoTeamCard extends StatelessWidget {
  const _NoTeamCard({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        children: [
          Icon(Icons.groups_outlined, size: 48, color: colors.primary),
          const SizedBox(height: 12),
          const Text(
            'Build your first safari team',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            'Invite registered tourist guides and manage their relationship with your company.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.onSurface.withOpacity(.62),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onPressed,
            icon: const Icon(Icons.person_add_alt_1_rounded),
            label: const Text('Invite guide'),
          ),
        ],
      ),
    );
  }
}
