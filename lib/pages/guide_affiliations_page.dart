import 'dart:async';

import 'package:flutter/material.dart';

import '../models/community.dart';
import '../models/guide_affiliation.dart';
import '../services/api_exception.dart';
import '../services/community_service.dart';

class GuideAffiliationsPage extends StatefulWidget {
  const GuideAffiliationsPage({super.key});

  @override
  State<GuideAffiliationsPage> createState() => _GuideAffiliationsPageState();
}

class _GuideAffiliationsPageState extends State<GuideAffiliationsPage> {
  late Future<GuideAffiliationSummary> _summary;
  bool _working = false;

  @override
  void initState() {
    super.initState();
    _summary = CommunityService.instance.fetchGuideAffiliations();
  }

  void _reload() {
    setState(() {
      _summary = CommunityService.instance.fetchGuideAffiliations();
    });
  }

  Future<void> _requestAffiliation() async {
    final result = await showModalBottomSheet<_GuideRequestPayload>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _GuideAffiliationRequestSheet(),
    );

    if (result == null || !mounted) return;

    await _run(() async {
      await CommunityService.instance.requestGuideAffiliation(
        operatorUserId: result.operatorId,
        relationshipType: result.relationshipType,
        publicVisibility: result.publicVisibility,
      );

      _message('Affiliation request sent.');
      _reload();
    });
  }

  Future<void> _accept(GuideOperatorAffiliation affiliation) async {
    await _run(() async {
      await CommunityService.instance.acceptOperatorInvitation(affiliation.id);
      _message('Tour operator invitation accepted.');
      _reload();
    });
  }

  Future<void> _decline(GuideOperatorAffiliation affiliation) async {
    final confirmed = await _confirm(
      title: 'Decline invitation?',
      message:
          'This invitation will be marked as declined. You can still receive a new invitation later.',
      confirmLabel: 'Decline',
    );

    if (confirmed != true) return;

    await _run(() async {
      await CommunityService.instance.declineOperatorInvitation(affiliation.id);
      _message('Invitation declined.');
      _reload();
    });
  }

  Future<void> _toggleVisibility(GuideOperatorAffiliation affiliation) async {
    final next = affiliation.isPublic ? 'private' : 'public';

    await _run(() async {
      await CommunityService.instance.updateGuideAffiliationVisibility(
        affiliationId: affiliation.id,
        publicVisibility: next,
      );

      _message(
        next == 'public'
            ? 'Affiliation is now visible on your public profile.'
            : 'Affiliation is now private.',
      );
      _reload();
    });
  }

  Future<void> _end(GuideOperatorAffiliation affiliation) async {
    final confirmed = await _confirm(
      title:
          affiliation.isPending
              ? 'Withdraw this request?'
              : 'End this affiliation?',
      message:
          affiliation.isPending
              ? 'The pending affiliation request will be closed.'
              : 'This relationship will no longer be active on the platform.',
      confirmLabel: affiliation.isPending ? 'Withdraw' : 'End affiliation',
    );

    if (confirmed != true) return;

    await _run(() async {
      await CommunityService.instance.endGuideAffiliation(affiliation.id);
      _message(
        affiliation.isPending
            ? 'Affiliation request withdrawn.'
            : 'Affiliation ended.',
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
      if (mounted) _message('The affiliation action could not be completed.');
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<bool?> _confirm({
    required String title,
    required String message,
    required String confirmLabel,
  }) {
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
      appBar: AppBar(title: const Text('My Work & Affiliations')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _working ? null : _requestAffiliation,
        icon: const Icon(Icons.add_business_rounded),
        label: const Text('Request affiliation'),
      ),
      body: RefreshIndicator(
        onRefresh: () async => _reload(),
        child: FutureBuilder<GuideAffiliationSummary>(
          future: _summary,
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
                    Icons.cloud_off_outlined,
                    size: 52,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Your work status could not be loaded.',
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

            final summary = snapshot.data!;
            final pendingInvites =
                summary.affiliations
                    .where((item) => item.isPending && item.requestedByOperator)
                    .toList();
            final active =
                summary.affiliations.where((item) => item.isActive).toList();
            final requests =
                summary.affiliations
                    .where((item) => item.isPending && item.requestedByGuide)
                    .toList();
            final history =
                summary.affiliations
                    .where((item) => item.isEnded || item.isDeclined)
                    .toList();

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
              children: [
                _GuideStatusHero(summary: summary),
                const SizedBox(height: 18),
                const _IndependentWorkCard(),
                if (pendingInvites.isNotEmpty) ...[
                  const SizedBox(height: 26),
                  const _SectionTitle(
                    title: 'Operator Invitations',
                    subtitle:
                        'Tour operators who want to add you to their safari team.',
                  ),
                  const SizedBox(height: 12),
                  ...pendingInvites.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _GuideAffiliationCard(
                        affiliation: item,
                        working: _working,
                        onAccept: () => _accept(item),
                        onDecline: () => _decline(item),
                        onVisibility: null,
                        onEnd: null,
                      ),
                    ),
                  ),
                ],
                if (active.isNotEmpty) ...[
                  const SizedBox(height: 26),
                  const _SectionTitle(
                    title: 'Active Affiliations',
                    subtitle:
                        'Current professional relationships connected to your guide account.',
                  ),
                  const SizedBox(height: 12),
                  ...active.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _GuideAffiliationCard(
                        affiliation: item,
                        working: _working,
                        onAccept: null,
                        onDecline: null,
                        onVisibility: () => _toggleVisibility(item),
                        onEnd: () => _end(item),
                      ),
                    ),
                  ),
                ],
                if (requests.isNotEmpty) ...[
                  const SizedBox(height: 26),
                  const _SectionTitle(
                    title: 'Pending Requests',
                    subtitle: 'Requests you have sent to tour operators.',
                  ),
                  const SizedBox(height: 12),
                  ...requests.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _GuideAffiliationCard(
                        affiliation: item,
                        working: _working,
                        onAccept: null,
                        onDecline: null,
                        onVisibility: null,
                        onEnd: () => _end(item),
                      ),
                    ),
                  ),
                ],
                if (history.isNotEmpty) ...[
                  const SizedBox(height: 26),
                  const _SectionTitle(
                    title: 'History',
                    subtitle: 'Ended and declined affiliations.',
                  ),
                  const SizedBox(height: 12),
                  ...history.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _GuideAffiliationCard(
                        affiliation: item,
                        working: _working,
                        onAccept: null,
                        onDecline: null,
                        onVisibility: null,
                        onEnd: null,
                      ),
                    ),
                  ),
                ],
                if (summary.affiliations.isEmpty) ...[
                  const SizedBox(height: 26),
                  _EmptyAffiliations(onPressed: _requestAffiliation),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _GuideStatusHero extends StatelessWidget {
  const _GuideStatusHero({required this.summary});

  final GuideAffiliationSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final icon =
        summary.workStatus == 'operator_affiliated'
            ? Icons.business_center_rounded
            : summary.workStatus == 'operator_affiliated_freelance'
            ? Icons.hub_rounded
            : Icons.explore_rounded;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colors.primary,
            Color.lerp(colors.primary, colors.tertiary, .46)!,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.14),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(height: 18),
          Text(
            summary.workStatusLabel,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            summary.isIndependent
                ? 'You currently have no active tour operator affiliation.'
                : 'You have an active tour operator affiliation. Your independent tours, proposals, bookings and private marketplace activity remain separate from that relationship.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withOpacity(.80),
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _IndependentWorkCard extends StatelessWidget {
  const _IndependentWorkCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    const items = [
      ('Safari opportunities', Icons.travel_explore_rounded),
      ('Independent proposals', Icons.request_quote_outlined),
      ('Direct bookings', Icons.event_available_outlined),
      ('Guide-led tours', Icons.route_rounded),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(23),
        border: Border.all(color: colors.outlineVariant),
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
                  color: colors.primaryContainer.withOpacity(.65),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(Icons.shield_outlined, color: colors.primary),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'My Independent Work',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Your personal marketplace activity stays separate from operator affiliations.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurface.withOpacity(.60),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    size: 18,
                    color: colors.primary,
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    item.$2,
                    size: 17,
                    color: colors.onSurface.withOpacity(.60),
                  ),
                  const SizedBox(width: 7),
                  Text(
                    item.$1,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'An affiliated tour operator does not automatically see or control your independent proposals, bookings, messages or guide-led tours.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onSurface.withOpacity(.58),
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _GuideAffiliationCard extends StatelessWidget {
  const _GuideAffiliationCard({
    required this.affiliation,
    required this.working,
    required this.onAccept,
    required this.onDecline,
    required this.onVisibility,
    required this.onEnd,
  });

  final GuideOperatorAffiliation affiliation;
  final bool working;
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;
  final VoidCallback? onVisibility;
  final VoidCallback? onEnd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final operator = affiliation.operator;

    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(23),
        border: Border.all(color: colors.outlineVariant.withOpacity(.65)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _AffiliationAvatar(person: operator, operatorStyle: true),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      operator?.displayName ?? 'Tour operator',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
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
              _StatusChip(affiliation: affiliation),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoChip(
                icon:
                    affiliation.isPublic
                        ? Icons.public_rounded
                        : Icons.lock_outline_rounded,
                label: affiliation.isPublic ? 'Public' : 'Private',
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
          if (onVisibility != null || onEnd != null) ...[
            const SizedBox(height: 15),
            Row(
              children: [
                if (onVisibility != null)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: working ? null : onVisibility,
                      icon: Icon(
                        affiliation.isPublic
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                      label: Text(
                        affiliation.isPublic ? 'Make private' : 'Make public',
                      ),
                    ),
                  ),
                if (onVisibility != null && onEnd != null)
                  const SizedBox(width: 9),
                if (onEnd != null)
                  IconButton.filledTonal(
                    tooltip:
                        affiliation.isPending
                            ? 'Withdraw request'
                            : 'End affiliation',
                    onPressed: working ? null : onEnd,
                    icon: const Icon(Icons.link_off_rounded),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _GuideAffiliationRequestSheet extends StatefulWidget {
  const _GuideAffiliationRequestSheet();

  @override
  State<_GuideAffiliationRequestSheet> createState() =>
      _GuideAffiliationRequestSheetState();
}

class _GuideAffiliationRequestSheetState
    extends State<_GuideAffiliationRequestSheet> {
  final TextEditingController _operatorController = TextEditingController();

  Timer? _debounce;
  List<CommunityMember> _results = const [];
  CommunityMember? _selectedOperator;

  String _relationshipType = 'contractor';
  String _visibility = 'private';
  bool _searching = false;
  String _searchError = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _operatorController.dispose();
    super.dispose();
  }

  void _onOperatorChanged(String value) {
    _debounce?.cancel();

    if (_selectedOperator != null &&
        value.trim() != _selectedOperator!.name.trim()) {
      setState(() {
        _selectedOperator = null;
      });
    }

    final query = value.trim();

    if (query.length < 2) {
      setState(() {
        _results = const [];
        _searching = false;
        _searchError = '';
      });
      return;
    }

    setState(() {
      _searching = true;
      _searchError = '';
    });

    _debounce = Timer(const Duration(milliseconds: 350), () {
      _searchOperators(query);
    });
  }

  Future<void> _searchOperators(String query) async {
    try {
      final results = await CommunityService.instance.searchTourOperators(
        query,
      );

      if (!mounted) return;

      if (_operatorController.text.trim() != query) {
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
        _searchError = 'Tour operators could not be searched.';
      });
    }
  }

  void _selectOperator(CommunityMember operator) {
    setState(() {
      _selectedOperator = operator;
      _results = const [];
      _searchError = '';
      _operatorController.text = operator.name;
      _operatorController.selection = TextSelection.collapsed(
        offset: _operatorController.text.length,
      );
    });

    FocusScope.of(context).unfocus();
  }

  void _clearOperator() {
    setState(() {
      _selectedOperator = null;
      _results = const [];
      _searchError = '';
      _operatorController.clear();
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
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
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
                'Request Operator Affiliation',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Type the tour operator name. Matching companies will appear as you type.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurface.withOpacity(.62),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 22),

              TextField(
                controller: _operatorController,
                autofocus: true,
                onChanged: _onOperatorChanged,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  labelText: 'Tour operator',
                  hintText: 'Type at least 2 letters',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon:
                      _selectedOperator != null
                          ? IconButton(
                            tooltip: 'Change operator',
                            onPressed: _clearOperator,
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

              if (_selectedOperator != null) ...[
                const SizedBox(height: 10),
                _SelectedOperatorCard(
                  operator: _selectedOperator!,
                  onClear: _clearOperator,
                ),
              ],

              if (_selectedOperator == null && _searchError.isNotEmpty) ...[
                const SizedBox(height: 9),
                Text(
                  _searchError,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.error,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],

              if (_selectedOperator == null && _results.isNotEmpty) ...[
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
                      final operator = _results[index];

                      return _OperatorSearchResultCard(
                        operator: operator,
                        onTap: () => _selectOperator(operator),
                      );
                    },
                  ),
                ),
              ],

              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: _relationshipType,
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
                    setState(() => _relationshipType = value);
                  }
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
                  if (value != null) {
                    setState(() => _visibility = value);
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
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.privacy_tip_outlined, color: colors.primary),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'This affiliation describes your professional relationship only. Your independent safari opportunities, proposals, bookings and guide-led tours remain under your own account.',
                        style: TextStyle(height: 1.45),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton.icon(
                  onPressed:
                      _selectedOperator == null
                          ? null
                          : () {
                            Navigator.pop(
                              context,
                              _GuideRequestPayload(
                                operatorId: _selectedOperator!.id,
                                relationshipType: _relationshipType,
                                publicVisibility: _visibility,
                              ),
                            );
                          },
                  icon: const Icon(Icons.send_rounded),
                  label: Text(
                    _selectedOperator == null
                        ? 'Select an operator first'
                        : 'Send request',
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

class _SelectedOperatorCard extends StatelessWidget {
  const _SelectedOperatorCard({required this.operator, required this.onClear});

  final CommunityMember operator;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final country = operator.country.trim();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.primary.withOpacity(.065),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.primary.withOpacity(.22)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.035),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        children: [
          _OperatorSearchLogo(operator: operator, large: true),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        operator.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: -.2,
                        ),
                      ),
                    ),
                    if (operator.isVerified) ...[
                      const SizedBox(width: 5),
                      Icon(
                        Icons.verified_rounded,
                        size: 18,
                        color: colors.primary,
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
                  )
                else
                  Text(
                    'Tour operator selected',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurface.withOpacity(.62),
                    ),
                  ),
                if (operator.location.trim().isNotEmpty &&
                    operator.location.trim().toLowerCase() !=
                        country.toLowerCase()) ...[
                  const SizedBox(height: 3),
                  Text(
                    operator.location.trim(),
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
            tooltip: 'Change operator',
            onPressed: onClear,
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }
}

class _OperatorSearchResultCard extends StatelessWidget {
  const _OperatorSearchResultCard({
    required this.operator,
    required this.onTap,
  });

  final CommunityMember operator;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final country = operator.country.trim();
    final location = operator.location.trim();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
          child: Row(
            children: [
              _OperatorSearchLogo(operator: operator),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            operator.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        if (operator.isVerified) ...[
                          const SizedBox(width: 5),
                          Icon(
                            Icons.verified_rounded,
                            size: 17,
                            color: colors.primary,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        if (country.isNotEmpty) ...[
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
                        ] else
                          Text(
                            'Tour operator',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colors.onSurface.withOpacity(.56),
                            ),
                          ),
                      ],
                    ),
                    if (location.isNotEmpty &&
                        location.toLowerCase() != country.toLowerCase()) ...[
                      const SizedBox(height: 3),
                      Text(
                        location,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurface.withOpacity(.46),
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

class _OperatorSearchLogo extends StatelessWidget {
  const _OperatorSearchLogo({required this.operator, this.large = false});

  final CommunityMember operator;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final initials =
        operator.name
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
      width: large ? 70 : 58,
      height: large ? 52 : 44,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(5),
        child:
            operator.profilePhotoUrl.isEmpty
                ? fallback
                : Image.network(
                  operator.profilePhotoUrl,
                  fit: BoxFit.contain,
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

class _GuideRequestPayload {
  const _GuideRequestPayload({
    required this.operatorId,
    required this.relationshipType,
    required this.publicVisibility,
  });

  final int operatorId;
  final String relationshipType;
  final String publicVisibility;
}

class _AffiliationAvatar extends StatelessWidget {
  const _AffiliationAvatar({required this.person, required this.operatorStyle});

  final AffiliationPerson? person;
  final bool operatorStyle;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final url = person?.profilePhotoUrl ?? '';
    final name = person?.displayName ?? '';
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

    if (operatorStyle) {
      return Container(
        width: 64,
        height: 46,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colors.outlineVariant),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child:
              url.isEmpty
                  ? fallback
                  : Image.network(
                    url,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => fallback,
                  ),
        ),
      );
    }

    return Container(
      width: 50,
      height: 50,
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

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.affiliation});

  final GuideOperatorAffiliation affiliation;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final color =
        affiliation.isActive
            ? colors.primary
            : affiliation.isDeclined
            ? colors.error
            : affiliation.isEnded
            ? colors.outline
            : colors.secondary;

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

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withOpacity(.58),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: colors.primary),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});

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

class _EmptyAffiliations extends StatelessWidget {
  const _EmptyAffiliations({required this.onPressed});

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
          Icon(Icons.handshake_outlined, size: 46, color: colors.primary),
          const SizedBox(height: 12),
          const Text(
            'No operator affiliations yet',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            'You remain an independent guide until you request or accept an operator relationship.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.onSurface.withOpacity(.62),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onPressed,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Request affiliation'),
          ),
        ],
      ),
    );
  }
}
