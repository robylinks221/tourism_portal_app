import 'package:flutter/material.dart';

import '../services/safari_request_service.dart';
import '../theme/field_guide_theme.dart';

class MySafariRequestsPage extends StatefulWidget {
  const MySafariRequestsPage({
    super.key,
  });

  @override
  State<MySafariRequestsPage> createState() =>
      _MySafariRequestsPageState();
}

class _MySafariRequestsPageState
    extends State<MySafariRequestsPage> {
  static const Color _primary =
      FieldGuidePalette.primary;

  static const Color _secondary =
      FieldGuidePalette.secondary;

  static const Color _background =
      FieldGuidePalette.background;

  List<SafariRequestItem> _requests = [];

  bool _loading = true;

  @override
  void initState() {
    super.initState();

    _loadRequests();
  }

  Future<void> _loadRequests() async {
    if (mounted) {
      setState(() {
        _loading = true;
      });
    }

    try {
      final requests =
      await SafariRequestService.instance
          .fetchMyRequests();

      if (!mounted) {
        return;
      }

      setState(() {
        _requests = requests;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.toString(),
          ),
        ),
      );
    }
  }

  Future<void> _cancelRequest(
      SafariRequestItem item,
      ) async {
    final confirmed =
    await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor:
          _background,
          title: const Text(
            'Cancel Safari Request?',
            style: TextStyle(
              color:
              FieldGuidePalette.ink,
              fontWeight:
              FontWeight.w800,
            ),
          ),
          content: const Text(
            'This request will no longer be visible to tour operators.',
            style: TextStyle(
              color:
              FieldGuidePalette.mutedText,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  false,
                );
              },
              child: const Text(
                'Keep Request',
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  true,
                );
              },
              child: const Text(
                'Cancel Request',
                style: TextStyle(
                  color:
                  _secondary,
                  fontWeight:
                  FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await SafariRequestService.instance
          .cancelRequest(
        item.id,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Safari request cancelled.',
          ),
        ),
      );

      await _loadRequests();
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.toString(),
          ),
        ),
      );
    }
  }

  Future<void> _submitDraft(
      SafariRequestItem item,
      ) async {
    try {
      final result =
      await SafariRequestService.instance
          .submitRequest(
        item.id,
      );

      if (!mounted) {
        return;
      }

      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor:
        Colors.transparent,
        barrierColor:
        Colors.black.withOpacity(.50),
        builder: (context) {
          return _SubmissionSuccessSheet(
            result: result,
          );
        },
      );

      await _loadRequests();
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.toString(),
          ),
        ),
      );
    }
  }

  Future<void> _openRequest(
      SafariRequestItem item,
      ) async {
    final updated =
    await SafariRequestService.instance
        .fetchRequest(
      item.id,
    );

    if (!mounted) {
      return;
    }

    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) =>
            SafariRequestDetailPage(
              request: updated,
            ),
      ),
    );

    await _loadRequests();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
      _background,
      appBar: AppBar(
        backgroundColor:
        _background,
        surfaceTintColor:
        Colors.transparent,
        elevation: 0,
        title: const Text(
          'My Safari Requests',
          style: TextStyle(
            color:
            FieldGuidePalette.ink,
            fontSize: 21,
            fontWeight:
            FontWeight.w800,
          ),
        ),
      ),
      body: RefreshIndicator(
        color: _primary,
        onRefresh:
        _loadRequests,
        child: CustomScrollView(
          physics:
          const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding:
                const EdgeInsets.fromLTRB(
                  20,
                  10,
                  20,
                  18,
                ),
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your safari plans',
                      style: TextStyle(
                        color:
                        FieldGuidePalette.ink,
                        fontSize: 27,
                        fontWeight:
                        FontWeight.w800,
                        letterSpacing:
                        -.6,
                      ),
                    ),
                    const SizedBox(
                      height: 6,
                    ),
                    const Text(
                      'Manage safari drafts, requests for quotes and accepted proposals.',
                      style: TextStyle(
                        color:
                        FieldGuidePalette.mutedText,
                        fontSize: 13,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(
                      height: 18,
                    ),
                    _SummaryRow(
                      requests:
                      _requests,
                    ),
                  ],
                ),
              ),
            ),
            if (_loading)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child:
                  CircularProgressIndicator(
                    color:
                    _primary,
                  ),
                ),
              )
            else if (_requests.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _EmptyRequests(
                  onBuildSafari: () {
                    Navigator.pop(
                      context,
                    );
                  },
                ),
              )
            else
              SliverPadding(
                padding:
                const EdgeInsets.fromLTRB(
                  20,
                  0,
                  20,
                  32,
                ),
                sliver:
                SliverList.separated(
                  itemCount:
                  _requests.length,
                  separatorBuilder:
                      (
                      context,
                      index,
                      ) =>
                  const SizedBox(
                    height: 14,
                  ),
                  itemBuilder:
                      (
                      context,
                      index,
                      ) {
                    final item =
                    _requests[index];

                    return _SafariRequestCard(
                      request:
                      item,
                      onTap: () =>
                          _openRequest(
                            item,
                          ),
                      onSubmit:
                      item.status ==
                          'draft'
                          ? () =>
                          _submitDraft(
                            item,
                          )
                          : null,
                      onCancel:
                      _canCancel(
                        item.status,
                      )
                          ? () =>
                          _cancelRequest(
                            item,
                          )
                          : null,
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  bool _canCancel(
      String status,
      ) {
    return status == 'draft' ||
        status == 'open' ||
        status ==
            'proposals_received';
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.requests,
  });

  final List<SafariRequestItem> requests;

  @override
  Widget build(BuildContext context) {
    final drafts =
        requests.where(
              (item) =>
          item.status ==
              'draft',
        ).length;

    final active =
        requests.where(
              (item) =>
          item.status ==
              'open' ||
              item.status ==
                  'proposals_received',
        ).length;

    final awarded =
        requests.where(
              (item) =>
          item.status ==
              'awarded',
        ).length;

    return Row(
      children: [
        Expanded(
          child: _MiniStat(
            value: '$drafts',
            label: 'Drafts',
          ),
        ),
        const SizedBox(
          width: 10,
        ),
        Expanded(
          child: _MiniStat(
            value: '$active',
            label: 'Active',
          ),
        ),
        const SizedBox(
          width: 10,
        ),
        Expanded(
          child: _MiniStat(
            value: '$awarded',
            label: 'Awarded',
          ),
        ),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.value,
    required this.label,
  });

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
      const EdgeInsets.symmetric(
        vertical: 14,
      ),
      decoration:
      BoxDecoration(
        color:
        Colors.white.withOpacity(
          .72,
        ),
        borderRadius:
        BorderRadius.circular(
          18,
        ),
        border:
        Border.all(
          color:
          FieldGuidePalette.border,
        ),
      ),
      child: Column(
        children: [
          Text(
            value,
            style:
            const TextStyle(
              color:
              FieldGuidePalette.primary,
              fontSize: 19,
              fontWeight:
              FontWeight.w800,
            ),
          ),
          const SizedBox(
            height: 3,
          ),
          Text(
            label,
            style:
            const TextStyle(
              color:
              FieldGuidePalette.mutedText,
              fontSize: 10.5,
              fontWeight:
              FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SafariRequestCard
    extends StatelessWidget {
  const _SafariRequestCard({
    required this.request,
    required this.onTap,
    this.onSubmit,
    this.onCancel,
  });

  final SafariRequestItem request;
  final VoidCallback onTap;
  final VoidCallback? onSubmit;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final status =
    _statusDetails(
      request.status,
    );

    return Material(
      color:
      Colors.white.withOpacity(
        .76,
      ),
      elevation: 3,
      shadowColor:
      Colors.black.withOpacity(
        .07,
      ),
      borderRadius:
      BorderRadius.circular(
        22,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius:
        BorderRadius.circular(
          22,
        ),
        child: Container(
          padding:
          const EdgeInsets.all(
            17,
          ),
          decoration:
          BoxDecoration(
            borderRadius:
            BorderRadius.circular(
              22,
            ),
            border:
            Border.all(
              color:
              FieldGuidePalette.border,
            ),
          ),
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      request.title,
                      maxLines: 2,
                      overflow:
                      TextOverflow.ellipsis,
                      style:
                      const TextStyle(
                        color:
                        FieldGuidePalette.ink,
                        fontSize: 17,
                        height: 1.2,
                        fontWeight:
                        FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  _StatusChip(
                    label:
                    status.label,
                    color:
                    status.color,
                  ),
                ],
              ),
              const SizedBox(
                height: 12,
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (request.days != null)
                    _InfoChip(
                      icon:
                      Icons.calendar_today_outlined,
                      label:
                      '${request.days} days',
                    ),
                  _InfoChip(
                    icon:
                    Icons.group_outlined,
                    label:
                    '${request.travellers} traveller${request.travellers == 1 ? '' : 's'}',
                  ),
                  if (request.budgetMin !=
                      null ||
                      request.budgetMax !=
                          null)
                    _InfoChip(
                      icon:
                      Icons.payments_outlined,
                      label:
                      _budget(
                        request,
                      ),
                    ),
                ],
              ),
              if (request.destinations
                  .isNotEmpty) ...[
                const SizedBox(
                  height: 14,
                ),
                const Text(
                  'Destinations',
                  style:
                  TextStyle(
                    color:
                    FieldGuidePalette.mutedText,
                    fontSize: 10,
                    fontWeight:
                    FontWeight.w700,
                  ),
                ),
                const SizedBox(
                  height: 6,
                ),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: request
                      .destinations
                      .take(3)
                      .map(
                        (
                        destination,
                        ) =>
                        _Tag(
                          label:
                          destination.name,
                        ),
                  )
                      .toList(),
                ),
              ],
              if (request.activities
                  .isNotEmpty) ...[
                const SizedBox(
                  height: 12,
                ),
                const Text(
                  'Activities',
                  style:
                  TextStyle(
                    color:
                    FieldGuidePalette.mutedText,
                    fontSize: 10,
                    fontWeight:
                    FontWeight.w700,
                  ),
                ),
                const SizedBox(
                  height: 6,
                ),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: request
                      .activities
                      .take(3)
                      .map(
                        (
                        activity,
                        ) =>
                        _Tag(
                          label:
                          activity.name,
                        ),
                  )
                      .toList(),
                ),
              ],
              const SizedBox(
                height: 15,
              ),
              Row(
                children: [
                  if (request.status ==
                      'proposals_received') ...[
                    const Icon(
                      Icons
                          .local_offer_outlined,
                      color:
                      FieldGuidePalette.secondary,
                      size: 17,
                    ),
                    const SizedBox(
                      width: 5,
                    ),
                    Text(
                      '${request.proposalCount} proposal${request.proposalCount == 1 ? '' : 's'}',
                      style:
                      const TextStyle(
                        color:
                        FieldGuidePalette.secondary,
                        fontSize: 11.5,
                        fontWeight:
                        FontWeight.w700,
                      ),
                    ),
                  ] else
                    Text(
                      status.subtitle,
                      style:
                      const TextStyle(
                        color:
                        FieldGuidePalette.mutedText,
                        fontSize: 11.5,
                      ),
                    ),
                  const Spacer(),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    color:
                    FieldGuidePalette.primary,
                    size: 20,
                  ),
                ],
              ),
              if (onSubmit != null ||
                  onCancel != null) ...[
                const SizedBox(
                  height: 14,
                ),
                Row(
                  children: [
                    if (onSubmit != null)
                      Expanded(
                        child:
                        FilledButton(
                          style:
                          FilledButton.styleFrom(
                            backgroundColor:
                            FieldGuidePalette.primary,
                            foregroundColor:
                            Colors.white,
                            shape:
                            RoundedRectangleBorder(
                              borderRadius:
                              BorderRadius.circular(
                                100,
                              ),
                            ),
                          ),
                          onPressed:
                          onSubmit,
                          child:
                          const Text(
                            'Request Quotes',
                            style:
                            TextStyle(
                              fontSize:
                              12,
                              fontWeight:
                              FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    if (onSubmit != null &&
                        onCancel != null)
                      const SizedBox(
                        width: 8,
                      ),
                    if (onCancel != null)
                      OutlinedButton(
                        style:
                        OutlinedButton.styleFrom(
                          foregroundColor:
                          FieldGuidePalette.secondary,
                          side:
                          const BorderSide(
                            color:
                            FieldGuidePalette.secondary,
                          ),
                          shape:
                          RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius.circular(
                              100,
                            ),
                          ),
                        ),
                        onPressed:
                        onCancel,
                        child:
                        const Text(
                          'Cancel',
                          style:
                          TextStyle(
                            fontSize:
                            12,
                            fontWeight:
                            FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class SafariRequestDetailPage
    extends StatefulWidget {
  const SafariRequestDetailPage({
    required this.request,
    super.key,
  });

  final SafariRequestItem request;

  @override
  State<SafariRequestDetailPage> createState() =>
      _SafariRequestDetailPageState();
}

class _SafariRequestDetailPageState
    extends State<SafariRequestDetailPage> {
  late SafariRequestItem _request;

  bool _accepting = false;

  @override
  void initState() {
    super.initState();

    _request = widget.request;
  }

  Future<void> _refresh() async {
    final updated =
    await SafariRequestService.instance
        .fetchRequest(
      _request.id,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _request = updated;
    });
  }

  Future<void> _accept(
      SafariProposalItem proposal,
      ) async {
    if (_accepting) {
      return;
    }

    final confirmed =
    await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor:
          FieldGuidePalette.background,
          title: const Text(
            'Accept this proposal?',
            style: TextStyle(
              color:
              FieldGuidePalette.ink,
              fontWeight:
              FontWeight.w800,
            ),
          ),
          content: Text(
            'You are selecting ${proposal.operatorName} for ${proposal.currency} ${proposal.price.toStringAsFixed(0)}.',
            style: const TextStyle(
              color:
              FieldGuidePalette.mutedText,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  false,
                );
              },
              child: const Text(
                'Not Yet',
              ),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  true,
                );
              },
              child: const Text(
                'Accept Proposal',
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    setState(() {
      _accepting = true;
    });

    try {
      await SafariRequestService.instance
          .acceptProposal(
        requestId:
        _request.id,
        proposalId:
        proposal.id,
      );

      await _refresh();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Proposal accepted successfully.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.toString(),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _accepting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
      FieldGuidePalette.background,
      appBar: AppBar(
        backgroundColor:
        FieldGuidePalette.background,
        surfaceTintColor:
        Colors.transparent,
        title: const Text(
          'Safari Request',
          style: TextStyle(
            color:
            FieldGuidePalette.ink,
            fontWeight:
            FontWeight.w800,
          ),
        ),
      ),
      body: RefreshIndicator(
        color:
        FieldGuidePalette.primary,
        onRefresh:
        _refresh,
        child: ListView(
          padding:
          const EdgeInsets.fromLTRB(
            20,
            10,
            20,
            32,
          ),
          children: [
            Text(
              _request.title,
              style:
              const TextStyle(
                color:
                FieldGuidePalette.ink,
                fontSize: 25,
                height: 1.12,
                fontWeight:
                FontWeight.w800,
              ),
            ),
            const SizedBox(
              height: 10,
            ),
            _StatusChip(
              label:
              _statusDetails(
                _request.status,
              ).label,
              color:
              _statusDetails(
                _request.status,
              ).color,
            ),
            const SizedBox(
              height: 20,
            ),
            _DetailCard(
              title: 'Safari Details',
              children: [
                _DetailRow(
                  label: 'Days',
                  value:
                  _request.days?.toString() ??
                      'Not specified',
                ),
                _DetailRow(
                  label:
                  'Travellers',
                  value:
                  '${_request.travellers}',
                ),
                _DetailRow(
                  label: 'Budget',
                  value:
                  _budget(
                    _request,
                  ),
                ),
                _DetailRow(
                  label:
                  'Accommodation',
                  value:
                  _request.accommodationLevel ??
                      'Not specified',
                ),
                _DetailRow(
                  label:
                  'Transport',
                  value:
                  _request.transportPreference ??
                      'Not specified',
                ),
              ],
            ),
            if (_request.notes != null &&
                _request.notes!
                    .trim()
                    .isNotEmpty) ...[
              const SizedBox(
                height: 14,
              ),
              _DetailCard(
                title:
                'Your Notes',
                children: [
                  Text(
                    _request.notes!,
                    style:
                    const TextStyle(
                      color:
                      FieldGuidePalette.mutedText,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(
              height: 22,
            ),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Operator Proposals',
                    style:
                    TextStyle(
                      color:
                      FieldGuidePalette.ink,
                      fontSize: 19,
                      fontWeight:
                      FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  '${_request.proposals.length}',
                  style:
                  const TextStyle(
                    color:
                    FieldGuidePalette.secondary,
                    fontWeight:
                    FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: 12,
            ),
            if (_request.proposals.isEmpty)
              Container(
                padding:
                const EdgeInsets.all(
                  20,
                ),
                decoration:
                BoxDecoration(
                  color:
                  Colors.white.withOpacity(
                    .72,
                  ),
                  borderRadius:
                  BorderRadius.circular(
                    20,
                  ),
                  border:
                  Border.all(
                    color:
                    FieldGuidePalette.border,
                  ),
                ),
                child:
                const Column(
                  children: [
                    Icon(
                      Icons
                          .hourglass_empty_rounded,
                      color:
                      FieldGuidePalette.primary,
                      size: 30,
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    Text(
                      'Waiting for proposals',
                      style:
                      TextStyle(
                        color:
                        FieldGuidePalette.ink,
                        fontWeight:
                        FontWeight.w800,
                      ),
                    ),
                    SizedBox(
                      height: 4,
                    ),
                    Text(
                      'Matching tour operators can review your safari and send you a quote.',
                      textAlign:
                      TextAlign.center,
                      style:
                      TextStyle(
                        color:
                        FieldGuidePalette.mutedText,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              )
            else
              ..._request.proposals.map(
                    (
                    proposal,
                    ) =>
                    Padding(
                      padding:
                      const EdgeInsets.only(
                        bottom: 12,
                      ),
                      child:
                      _ProposalCard(
                        proposal:
                        proposal,
                        requestStatus:
                        _request.status,
                        acceptedProposalId:
                        _request
                            .acceptedProposal
                            ?.id,
                        onAccept:
                        _request.status ==
                            'open' ||
                            _request.status ==
                                'proposals_received'
                            ? () =>
                            _accept(
                              proposal,
                            )
                            : null,
                      ),
                    ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ProposalCard extends StatelessWidget {
  const _ProposalCard({
    required this.proposal,
    required this.requestStatus,
    required this.acceptedProposalId,
    required this.onAccept,
  });

  final SafariProposalItem proposal;
  final String requestStatus;
  final int? acceptedProposalId;
  final VoidCallback? onAccept;

  @override
  Widget build(BuildContext context) {
    final accepted =
        proposal.id ==
            acceptedProposalId ||
            proposal.status ==
                'accepted';

    return Container(
      padding:
      const EdgeInsets.all(
        17,
      ),
      decoration:
      BoxDecoration(
        color:
        Colors.white.withOpacity(
          .76,
        ),
        borderRadius:
        BorderRadius.circular(
          22,
        ),
        border:
        Border.all(
          color: accepted
              ? FieldGuidePalette.primary
              : FieldGuidePalette.border,
          width:
          accepted ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration:
                BoxDecoration(
                  color:
                  FieldGuidePalette.primary
                      .withOpacity(
                    .09,
                  ),
                  shape:
                  BoxShape.circle,
                ),
                child:
                const Icon(
                  Icons.business_rounded,
                  color:
                  FieldGuidePalette.primary,
                ),
              ),
              const SizedBox(
                width: 11,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      proposal.operatorName,
                      style:
                      const TextStyle(
                        color:
                        FieldGuidePalette.ink,
                        fontSize: 15,
                        fontWeight:
                        FontWeight.w800,
                      ),
                    ),
                    const SizedBox(
                      height: 3,
                    ),
                    Text(
                      proposal.vehicle ??
                          'Safari proposal',
                      maxLines: 1,
                      overflow:
                      TextOverflow.ellipsis,
                      style:
                      const TextStyle(
                        color:
                        FieldGuidePalette.mutedText,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${proposal.currency} ${proposal.price.toStringAsFixed(0)}',
                style:
                const TextStyle(
                  color:
                  FieldGuidePalette.primary,
                  fontSize: 16,
                  fontWeight:
                  FontWeight.w900,
                ),
              ),
            ],
          ),
          if (proposal.message != null &&
              proposal.message!
                  .trim()
                  .isNotEmpty) ...[
            const SizedBox(
              height: 13,
            ),
            Text(
              proposal.message!,
              style:
              const TextStyle(
                color:
                FieldGuidePalette.mutedText,
                fontSize: 12,
                height: 1.45,
              ),
            ),
          ],
          if (proposal.inclusions
              .isNotEmpty) ...[
            const SizedBox(
              height: 13,
            ),
            const Text(
              'Includes',
              style:
              TextStyle(
                color:
                FieldGuidePalette.ink,
                fontSize: 11,
                fontWeight:
                FontWeight.w800,
              ),
            ),
            const SizedBox(
              height: 6,
            ),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: proposal
                  .inclusions
                  .take(4)
                  .map(
                    (
                    item,
                    ) =>
                    _Tag(
                      label: item,
                    ),
              )
                  .toList(),
            ),
          ],
          const SizedBox(
            height: 14,
          ),
          if (accepted)
            Container(
              width:
              double.infinity,
              padding:
              const EdgeInsets.symmetric(
                vertical: 11,
              ),
              decoration:
              BoxDecoration(
                color:
                FieldGuidePalette.primary
                    .withOpacity(
                  .09,
                ),
                borderRadius:
                BorderRadius.circular(
                  100,
                ),
              ),
              child:
              const Row(
                mainAxisAlignment:
                MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    color:
                    FieldGuidePalette.primary,
                    size: 18,
                  ),
                  SizedBox(
                    width: 7,
                  ),
                  Text(
                    'Accepted Proposal',
                    style:
                    TextStyle(
                      color:
                      FieldGuidePalette.primary,
                      fontSize: 12,
                      fontWeight:
                      FontWeight.w800,
                    ),
                  ),
                ],
              ),
            )
          else if (onAccept != null)
            SizedBox(
              width:
              double.infinity,
              height: 46,
              child:
              FilledButton(
                style:
                FilledButton.styleFrom(
                  backgroundColor:
                  FieldGuidePalette.primary,
                  foregroundColor:
                  Colors.white,
                  shape:
                  RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(
                      100,
                    ),
                  ),
                ),
                onPressed:
                onAccept,
                child:
                const Text(
                  'Accept Proposal',
                  style:
                  TextStyle(
                    fontSize: 12.5,
                    fontWeight:
                    FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SubmissionSuccessSheet
    extends StatelessWidget {
  const _SubmissionSuccessSheet({
    required this.result,
  });

  final SafariRequestSubmissionResult result;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding:
        const EdgeInsets.fromLTRB(
          22,
          12,
          22,
          26,
        ),
        decoration:
        const BoxDecoration(
          color:
          FieldGuidePalette.background,
          borderRadius:
          BorderRadius.only(
            topLeft:
            Radius.circular(
              34,
            ),
            topRight:
            Radius.circular(
              34,
            ),
          ),
        ),
        child: Column(
          mainAxisSize:
          MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 4,
              decoration:
              BoxDecoration(
                color:
                const Color(
                  0xFFD2CCC3,
                ),
                borderRadius:
                BorderRadius.circular(
                  20,
                ),
              ),
            ),
            const SizedBox(
              height: 22,
            ),
            Container(
              width: 58,
              height: 58,
              decoration:
              BoxDecoration(
                color:
                FieldGuidePalette.primary
                    .withOpacity(
                  .09,
                ),
                shape:
                BoxShape.circle,
              ),
              child:
              const Icon(
                Icons
                    .check_rounded,
                color:
                FieldGuidePalette.primary,
                size: 29,
              ),
            ),
            const SizedBox(
              height: 15,
            ),
            const Text(
              'Request Sent',
              style:
              TextStyle(
                color:
                FieldGuidePalette.ink,
                fontSize: 21,
                fontWeight:
                FontWeight.w800,
              ),
            ),
            const SizedBox(
              height: 7,
            ),
            Text(
              '${result.matchingOperators.length} matching tour operator${result.matchingOperators.length == 1 ? '' : 's'} found.',
              textAlign:
              TextAlign.center,
              style:
              const TextStyle(
                color:
                FieldGuidePalette.mutedText,
                fontSize: 13,
              ),
            ),
            if (result.matchingOperators
                .isNotEmpty) ...[
              const SizedBox(
                height: 18,
              ),
              ...result.matchingOperators
                  .take(3)
                  .map(
                    (
                    operator,
                    ) =>
                    Padding(
                      padding:
                      const EdgeInsets.only(
                        bottom: 8,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              operator.name,
                              style:
                              const TextStyle(
                                color:
                                FieldGuidePalette.ink,
                                fontSize:
                                13,
                                fontWeight:
                                FontWeight.w700,
                              ),
                            ),
                          ),
                          Text(
                            '${operator.matchPercentage}% match',
                            style:
                            const TextStyle(
                              color:
                              FieldGuidePalette.secondary,
                              fontSize:
                              11.5,
                              fontWeight:
                              FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
              ),
            ],
            const SizedBox(
              height: 18,
            ),
            SizedBox(
              width:
              double.infinity,
              height: 50,
              child:
              FilledButton(
                style:
                FilledButton.styleFrom(
                  backgroundColor:
                  FieldGuidePalette.primary,
                  foregroundColor:
                  Colors.white,
                  shape:
                  RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(
                      100,
                    ),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(
                    context,
                  );
                },
                child:
                const Text(
                  'Done',
                  style:
                  TextStyle(
                    fontWeight:
                    FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
      const EdgeInsets.all(
        17,
      ),
      decoration:
      BoxDecoration(
        color:
        Colors.white.withOpacity(
          .76,
        ),
        borderRadius:
        BorderRadius.circular(
          22,
        ),
        border:
        Border.all(
          color:
          FieldGuidePalette.border,
        ),
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style:
            const TextStyle(
              color:
              FieldGuidePalette.ink,
              fontSize: 14,
              fontWeight:
              FontWeight.w800,
            ),
          ),
          const SizedBox(
            height: 12,
          ),
          ...children,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
      const EdgeInsets.only(
        bottom: 9,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style:
              const TextStyle(
                color:
                FieldGuidePalette.mutedText,
                fontSize: 12,
              ),
            ),
          ),
          Text(
            value,
            style:
            const TextStyle(
              color:
              FieldGuidePalette.ink,
              fontSize: 12,
              fontWeight:
              FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
      const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),
      decoration:
      BoxDecoration(
        color:
        FieldGuidePalette.primary
            .withOpacity(
          .07,
        ),
        borderRadius:
        BorderRadius.circular(
          100,
        ),
      ),
      child: Row(
        mainAxisSize:
        MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color:
            FieldGuidePalette.primary,
          ),
          const SizedBox(
            width: 5,
          ),
          Text(
            label,
            style:
            const TextStyle(
              color:
              FieldGuidePalette.primary,
              fontSize: 10.5,
              fontWeight:
              FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({
    required this.label,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
      const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 5,
      ),
      decoration:
      BoxDecoration(
        color:
        FieldGuidePalette.secondary
            .withOpacity(
          .08,
        ),
        borderRadius:
        BorderRadius.circular(
          100,
        ),
      ),
      child: Text(
        label,
        style:
        const TextStyle(
          color:
          FieldGuidePalette.secondary,
          fontSize: 9.5,
          fontWeight:
          FontWeight.w600,
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
      const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),
      decoration:
      BoxDecoration(
        color:
        color.withOpacity(
          .10,
        ),
        borderRadius:
        BorderRadius.circular(
          100,
        ),
      ),
      child: Text(
        label,
        style:
        TextStyle(
          color:
          color,
          fontSize: 10,
          fontWeight:
          FontWeight.w800,
        ),
      ),
    );
  }
}

class _StatusDetails {
  const _StatusDetails({
    required this.label,
    required this.subtitle,
    required this.color,
  });

  final String label;
  final String subtitle;
  final Color color;
}

_StatusDetails _statusDetails(
    String status,
    ) {
  switch (status) {
    case 'draft':
      return const _StatusDetails(
        label: 'Draft',
        subtitle:
        'Continue building your safari.',
        color:
        Color(
          0xFF8C6A31,
        ),
      );

    case 'open':
      return const _StatusDetails(
        label: 'Open',
        subtitle:
        'Waiting for operator proposals.',
        color:
        FieldGuidePalette.primary,
      );

    case 'proposals_received':
      return const _StatusDetails(
        label:
        'Proposals Received',
        subtitle:
        'Compare your operator quotes.',
        color:
        FieldGuidePalette.secondary,
      );

    case 'awarded':
      return const _StatusDetails(
        label: 'Awarded',
        subtitle:
        'You selected a tour operator.',
        color:
        Color(
          0xFF2E7D32,
        ),
      );

    case 'completed':
      return const _StatusDetails(
        label: 'Completed',
        subtitle:
        'Safari completed.',
        color:
        Color(
          0xFF546E7A,
        ),
      );

    case 'cancelled':
      return const _StatusDetails(
        label: 'Cancelled',
        subtitle:
        'This safari request is closed.',
        color:
        Color(
          0xFF9B4949,
        ),
      );

    default:
      return _StatusDetails(
        label: status,
        subtitle: '',
        color:
        FieldGuidePalette.mutedText,
      );
  }
}

String _budget(
    SafariRequestItem item,
    ) {
  final min =
      item.budgetMin;

  final max =
      item.budgetMax;

  if (min == null &&
      max == null) {
    return 'Not specified';
  }

  if (min != null &&
      max != null) {
    return '${item.currency} ${min.toStringAsFixed(0)} - ${max.toStringAsFixed(0)}';
  }

  if (min != null) {
    return 'From ${item.currency} ${min.toStringAsFixed(0)}';
  }

  return 'Up to ${item.currency} ${max!.toStringAsFixed(0)}';
}

class _EmptyRequests extends StatelessWidget {
  const _EmptyRequests({
    required this.onBuildSafari,
  });

  final VoidCallback onBuildSafari;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding:
        const EdgeInsets.all(
          30,
        ),
        child: Column(
          mainAxisSize:
          MainAxisSize.min,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration:
              BoxDecoration(
                color:
                FieldGuidePalette.primary
                    .withOpacity(
                  .08,
                ),
                shape:
                BoxShape.circle,
              ),
              child:
              const Icon(
                Icons
                    .travel_explore_rounded,
                color:
                FieldGuidePalette.primary,
                size: 32,
              ),
            ),
            const SizedBox(
              height: 16,
            ),
            const Text(
              'No safari requests yet',
              style:
              TextStyle(
                color:
                FieldGuidePalette.ink,
                fontSize: 18,
                fontWeight:
                FontWeight.w800,
              ),
            ),
            const SizedBox(
              height: 7,
            ),
            const Text(
              'Build your first safari and request quotes from matching tour operators.',
              textAlign:
              TextAlign.center,
              style:
              TextStyle(
                color:
                FieldGuidePalette.mutedText,
                fontSize: 13,
                height: 1.45,
              ),
            ),
            const SizedBox(
              height: 16,
            ),
            FilledButton(
              style:
              FilledButton.styleFrom(
                backgroundColor:
                FieldGuidePalette.primary,
                foregroundColor:
                Colors.white,
                shape:
                RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(
                    100,
                  ),
                ),
              ),
              onPressed:
              onBuildSafari,
              child:
              const Text(
                'Build My Safari',
                style:
                TextStyle(
                  fontWeight:
                  FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}