import 'package:flutter/material.dart';

import '../services/safari_request_service.dart';
import '../theme/field_guide_theme.dart';

class OperatorSafariOpportunitiesPage extends StatefulWidget {
  const OperatorSafariOpportunitiesPage({
    super.key,
  });

  @override
  State<OperatorSafariOpportunitiesPage> createState() =>
      _OperatorSafariOpportunitiesPageState();
}

class _OperatorSafariOpportunitiesPageState
    extends State<OperatorSafariOpportunitiesPage> {
  static const Color _primary = FieldGuidePalette.primary;
  static const Color _secondary = FieldGuidePalette.secondary;
  static const Color _background = FieldGuidePalette.background;

  final TextEditingController _searchController =
  TextEditingController();

  List<SafariRequestItem> _allRequests = [];
  List<SafariRequestItem> _filteredRequests = [];

  bool _loading = true;

  String _statusFilter = 'all';

  @override
  void initState() {
    super.initState();

    _searchController.addListener(
      _applyFilters,
    );

    _loadRequests();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRequests() async {
    if (mounted) {
      setState(() {
        _loading = true;
      });
    }

    try {
      final requests =
      await SafariRequestService.instance.fetchOperatorRequests();

      if (!mounted) {
        return;
      }

      setState(() {
        _allRequests = requests;
        _filteredRequests = requests;
        _loading = false;
      });

      _applyFilters();
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

  void _applyFilters() {
    if (!mounted) {
      return;
    }

    final query =
    _searchController.text.trim().toLowerCase();

    final results =
    _allRequests.where(
          (item) {
        final searchText = [
          item.title,
          item.notes ?? '',
          item.accommodationLevel ?? '',
          item.transportPreference ?? '',
          ...item.activities.map((item) => item.name),
          ...item.destinations.map((item) => item.name),
        ].join(' ').toLowerCase();

        final matchesSearch =
            query.isEmpty ||
                searchText.contains(query);

        final matchesStatus =
            _statusFilter == 'all' ||
                (_statusFilter == 'not_sent' &&
                    item.myProposal == null) ||
                (_statusFilter == 'sent' &&
                    item.myProposal != null);

        return matchesSearch &&
            matchesStatus;
      },
    ).toList();

    results.sort(
          (a, b) =>
          b.matchPercentage.compareTo(
            a.matchPercentage,
          ),
    );

    setState(() {
      _filteredRequests = results;
    });
  }

  Future<void> _openRequest(
      SafariRequestItem item,
      ) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) =>
            OperatorSafariRequestDetailPage(
              request: item,
            ),
      ),
    );

    await _loadRequests();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        surfaceTintColor:
        Colors.transparent,
        elevation: 0,
        title: const Text(
          'Safari Opportunities',
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
        onRefresh: _loadRequests,
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
                  16,
                ),
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Find matching safari requests',
                      style: TextStyle(
                        color:
                        FieldGuidePalette.ink,
                        fontSize: 26,
                        fontWeight:
                        FontWeight.w800,
                        letterSpacing: -.6,
                      ),
                    ),
                    const SizedBox(
                      height: 6,
                    ),
                    const Text(
                      'Review requests that match your destinations and safari activities, then send a proposal.',
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

                    // Search
                    TextField(
                      controller:
                      _searchController,
                      textInputAction:
                      TextInputAction.search,
                      decoration:
                      InputDecoration(
                        hintText:
                        'Search destinations, activities or safari title',
                        prefixIcon:
                        const Icon(
                          Icons.search_rounded,
                          color: _primary,
                        ),
                        filled: true,
                        fillColor:
                        Colors.white.withOpacity(
                          .75,
                        ),
                        border:
                        OutlineInputBorder(
                          borderRadius:
                          BorderRadius.circular(
                            18,
                          ),
                          borderSide:
                          BorderSide.none,
                        ),
                        enabledBorder:
                        OutlineInputBorder(
                          borderRadius:
                          BorderRadius.circular(
                            18,
                          ),
                          borderSide:
                          const BorderSide(
                            color:
                            FieldGuidePalette.border,
                          ),
                        ),
                        focusedBorder:
                        OutlineInputBorder(
                          borderRadius:
                          BorderRadius.circular(
                            18,
                          ),
                          borderSide:
                          const BorderSide(
                            color: _primary,
                            width: 1.4,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 14,
                    ),

                    // Filters
                    SingleChildScrollView(
                      scrollDirection:
                      Axis.horizontal,
                      child: Row(
                        children: [
                          _FilterChip(
                            label: 'All',
                            selected:
                            _statusFilter ==
                                'all',
                            onTap: () {
                              setState(() {
                                _statusFilter =
                                'all';
                              });

                              _applyFilters();
                            },
                          ),
                          const SizedBox(
                            width: 8,
                          ),
                          _FilterChip(
                            label:
                            'Proposal Not Sent',
                            selected:
                            _statusFilter ==
                                'not_sent',
                            onTap: () {
                              setState(() {
                                _statusFilter =
                                'not_sent';
                              });

                              _applyFilters();
                            },
                          ),
                          const SizedBox(
                            width: 8,
                          ),
                          _FilterChip(
                            label:
                            'Proposal Sent',
                            selected:
                            _statusFilter ==
                                'sent',
                            onTap: () {
                              setState(() {
                                _statusFilter =
                                'sent';
                              });

                              _applyFilters();
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(
                      height: 15,
                    ),

                    Row(
                      children: [
                        Text(
                          '${_filteredRequests.length} opportunit${_filteredRequests.length == 1 ? 'y' : 'ies'}',
                          style:
                          const TextStyle(
                            color:
                            FieldGuidePalette.mutedText,
                            fontSize: 12,
                            fontWeight:
                            FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        const Row(
                          children: [
                            Icon(
                              Icons
                                  .auto_awesome_rounded,
                              color:
                              _secondary,
                              size: 15,
                            ),
                            SizedBox(
                              width: 5,
                            ),
                            Text(
                              'Best matches first',
                              style:
                              TextStyle(
                                color:
                                _secondary,
                                fontSize:
                                11,
                                fontWeight:
                                FontWeight.w700,
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

            if (_loading)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child:
                  CircularProgressIndicator(
                    color: _primary,
                  ),
                ),
              )
            else if (_filteredRequests.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child:
                _EmptyOpportunities(),
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
                  _filteredRequests.length,
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
                    _filteredRequests[
                    index];

                    return _OpportunityCard(
                      request: item,
                      onTap: () =>
                          _openRequest(
                            item,
                          ),
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

class _OpportunityCard
    extends StatelessWidget {
  const _OpportunityCard({
    required this.request,
    required this.onTap,
  });

  final SafariRequestItem request;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final proposal =
        request.myProposal;

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
                  _MatchBadge(
                    percentage:
                    request.matchPercentage,
                  ),
                ],
              ),

              const SizedBox(
                height: 13,
              ),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (request.days != null)
                    _InfoChip(
                      icon:
                      Icons
                          .calendar_month_outlined,
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
                      Icons
                          .payments_outlined,
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
                        item,
                        ) =>
                        _Tag(
                          label:
                          item.name,
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
                        item,
                        ) =>
                        _Tag(
                          label:
                          item.name,
                        ),
                  )
                      .toList(),
                ),
              ],

              const SizedBox(
                height: 15,
              ),

              Container(
                width:
                double.infinity,
                padding:
                const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 11,
                ),
                decoration:
                BoxDecoration(
                  color: proposal == null
                      ? FieldGuidePalette
                      .primary
                      .withOpacity(
                    .07,
                  )
                      : FieldGuidePalette
                      .secondary
                      .withOpacity(
                    .07,
                  ),
                  borderRadius:
                  BorderRadius.circular(
                    14,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      proposal == null
                          ? Icons
                          .edit_note_rounded
                          : Icons
                          .check_circle_outline_rounded,
                      color: proposal == null
                          ? FieldGuidePalette
                          .primary
                          : FieldGuidePalette
                          .secondary,
                      size: 19,
                    ),
                    const SizedBox(
                      width: 8,
                    ),
                    Expanded(
                      child: Text(
                        proposal == null
                            ? 'Send your proposal'
                            : 'Proposal sent: ${proposal.currency} ${proposal.price.toStringAsFixed(0)}',
                        style:
                        TextStyle(
                          color: proposal == null
                              ? FieldGuidePalette
                              .primary
                              : FieldGuidePalette
                              .secondary,
                          fontSize: 11.5,
                          fontWeight:
                          FontWeight.w700,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons
                          .arrow_forward_rounded,
                      color:
                      FieldGuidePalette.ink,
                      size: 18,
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

class OperatorSafariRequestDetailPage
    extends StatefulWidget {
  const OperatorSafariRequestDetailPage({
    required this.request,
    super.key,
  });

  final SafariRequestItem request;

  @override
  State<OperatorSafariRequestDetailPage>
  createState() =>
      _OperatorSafariRequestDetailPageState();
}

class _OperatorSafariRequestDetailPageState
    extends State<OperatorSafariRequestDetailPage> {
  late SafariRequestItem _request;

  @override
  void initState() {
    super.initState();

    _request = widget.request;
  }

  Future<void> _openProposalForm() async {
    final result =
    await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (_) =>
            SendSafariProposalPage(
              request: _request,
            ),
      ),
    );

    if (result == true &&
        mounted) {
      Navigator.pop(
        context,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final proposal =
        _request.myProposal;

    return Scaffold(
      backgroundColor:
      FieldGuidePalette.background,
      appBar: AppBar(
        backgroundColor:
        FieldGuidePalette.background,
        surfaceTintColor:
        Colors.transparent,
        title: const Text(
          'Safari Opportunity',
          style: TextStyle(
            color:
            FieldGuidePalette.ink,
            fontWeight:
            FontWeight.w800,
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding:
          const EdgeInsets.fromLTRB(
            20,
            10,
            20,
            16,
          ),
          color:
          FieldGuidePalette.background,
          child: SizedBox(
            height: 52,
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
              _openProposalForm,
              child: Text(
                proposal == null
                    ? 'Send Proposal'
                    : 'Update Proposal',
                style:
                const TextStyle(
                  fontWeight:
                  FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
      ),
      body: ListView(
        padding:
        const EdgeInsets.fromLTRB(
          20,
          10,
          20,
          30,
        ),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
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
              ),
              const SizedBox(
                width: 10,
              ),
              _MatchBadge(
                percentage:
                _request.matchPercentage,
              ),
            ],
          ),

          const SizedBox(
            height: 20,
          ),

          _DetailCard(
            title: 'Safari Request',
            children: [
              _DetailRow(
                label: 'Duration',
                value:
                _request.days == null
                    ? 'Not specified'
                    : '${_request.days} days',
              ),
              _DetailRow(
                label: 'Travellers',
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
                _request
                    .accommodationLevel ??
                    'Not specified',
              ),
              _DetailRow(
                label:
                'Transport',
                value:
                _request
                    .transportPreference ??
                    'Not specified',
              ),
            ],
          ),

          if (_request.destinations
              .isNotEmpty) ...[
            const SizedBox(
              height: 14,
            ),
            _DetailCard(
              title: 'Destinations',
              children: [
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: _request
                      .destinations
                      .map(
                        (
                        item,
                        ) =>
                        _Tag(
                          label:
                          item.name,
                        ),
                  )
                      .toList(),
                ),
              ],
            ),
          ],

          if (_request.activities
              .isNotEmpty) ...[
            const SizedBox(
              height: 14,
            ),
            _DetailCard(
              title: 'Activities',
              children: [
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: _request
                      .activities
                      .map(
                        (
                        item,
                        ) =>
                        _Tag(
                          label:
                          item.name,
                        ),
                  )
                      .toList(),
                ),
              ],
            ),
          ],

          if (_request.notes != null &&
              _request.notes!
                  .trim()
                  .isNotEmpty) ...[
            const SizedBox(
              height: 14,
            ),
            _DetailCard(
              title:
              'Traveller Notes',
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

          if (proposal != null) ...[
            const SizedBox(
              height: 20,
            ),
            const Text(
              'Your Proposal',
              style:
              TextStyle(
                color:
                FieldGuidePalette.ink,
                fontSize: 19,
                fontWeight:
                FontWeight.w800,
              ),
            ),
            const SizedBox(
              height: 10,
            ),
            Container(
              padding:
              const EdgeInsets.all(
                17,
              ),
              decoration:
              BoxDecoration(
                color:
                Colors.white.withOpacity(
                  .75,
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
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${proposal.currency} ${proposal.price.toStringAsFixed(0)}',
                          style:
                          const TextStyle(
                            color:
                            FieldGuidePalette.primary,
                            fontSize: 22,
                            fontWeight:
                            FontWeight.w900,
                          ),
                        ),
                      ),
                      _ProposalStatusChip(
                        status:
                        proposal.status,
                      ),
                    ],
                  ),
                  if (proposal.message !=
                      null &&
                      proposal.message!
                          .trim()
                          .isNotEmpty) ...[
                    const SizedBox(
                      height: 12,
                    ),
                    Text(
                      proposal.message!,
                      style:
                      const TextStyle(
                        color:
                        FieldGuidePalette.mutedText,
                        fontSize: 12.5,
                        height: 1.45,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class SendSafariProposalPage
    extends StatefulWidget {
  const SendSafariProposalPage({
    required this.request,
    super.key,
  });

  final SafariRequestItem request;

  @override
  State<SendSafariProposalPage> createState() =>
      _SendSafariProposalPageState();
}

class _SendSafariProposalPageState
    extends State<SendSafariProposalPage> {
  final _formKey =
  GlobalKey<FormState>();

  final _priceController =
  TextEditingController();

  final _messageController =
  TextEditingController();

  final _vehicleController =
  TextEditingController();

  final _accommodationController =
  TextEditingController();

  final _inclusionsController =
  TextEditingController();

  final _exclusionsController =
  TextEditingController();

  bool _submitting = false;

  @override
  void initState() {
    super.initState();

    final proposal =
        widget.request.myProposal;

    if (proposal != null) {
      _priceController.text =
          proposal.price.toStringAsFixed(
            0,
          );

      _messageController.text =
          proposal.message ?? '';

      _vehicleController.text =
          proposal.vehicle ?? '';

      _accommodationController.text =
          proposal.accommodationNotes ??
              '';

      _inclusionsController.text =
          proposal.inclusions.join(
            '\n',
          );

      _exclusionsController.text =
          proposal.exclusions.join(
            '\n',
          );
    }
  }

  @override
  void dispose() {
    _priceController.dispose();
    _messageController.dispose();
    _vehicleController.dispose();
    _accommodationController.dispose();
    _inclusionsController.dispose();
    _exclusionsController.dispose();

    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate() ||
        _submitting) {
      return;
    }

    final price =
    double.tryParse(
      _priceController.text.trim(),
    );

    if (price == null) {
      return;
    }

    setState(() {
      _submitting = true;
    });

    try {
      await SafariRequestService.instance
          .submitProposal(
        requestId:
        widget.request.id,
        price: price,
        currency: 'USD',
        message:
        _messageController.text.trim(),
        vehicle:
        _vehicleController.text.trim(),
        accommodationNotes:
        _accommodationController.text.trim(),
        inclusions:
        _lines(
          _inclusionsController.text,
        ),
        exclusions:
        _lines(
          _exclusionsController.text,
        ),
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Proposal submitted successfully.',
          ),
        ),
      );

      Navigator.pop(
        context,
        true,
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
          _submitting = false;
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
        title: Text(
          widget.request.myProposal ==
              null
              ? 'Send Proposal'
              : 'Update Proposal',
          style:
          const TextStyle(
            color:
            FieldGuidePalette.ink,
            fontWeight:
            FontWeight.w800,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child:
        SingleChildScrollView(
          keyboardDismissBehavior:
          ScrollViewKeyboardDismissBehavior
              .onDrag,
          padding:
          const EdgeInsets.fromLTRB(
            20,
            10,
            20,
            34,
          ),
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.request.title,
                style:
                const TextStyle(
                  color:
                  FieldGuidePalette.ink,
                  fontSize: 20,
                  fontWeight:
                  FontWeight.w800,
                ),
              ),

              const SizedBox(
                height: 6,
              ),

              Text(
                '${widget.request.matchPercentage}% match with your services',
                style:
                const TextStyle(
                  color:
                  FieldGuidePalette.secondary,
                  fontSize: 12,
                  fontWeight:
                  FontWeight.w700,
                ),
              ),

              const SizedBox(
                height: 24,
              ),

              const _FormLabel(
                label:
                'Safari Price',
              ),

              const SizedBox(
                height: 8,
              ),

              TextFormField(
                controller:
                _priceController,
                keyboardType:
                const TextInputType
                    .numberWithOptions(
                  decimal: true,
                ),
                decoration:
                const InputDecoration(
                  hintText:
                  'Enter total price',
                  prefixText:
                  'USD ',
                  prefixIcon:
                  Icon(
                    Icons
                        .payments_outlined,
                    color:
                    FieldGuidePalette.primary,
                  ),
                ),
                validator: (value) {
                  final parsed =
                  double.tryParse(
                    value?.trim() ?? '',
                  );

                  if (parsed == null ||
                      parsed <= 0) {
                    return 'Enter a valid safari price.';
                  }

                  return null;
                },
              ),

              const SizedBox(
                height: 17,
              ),

              const _FormLabel(
                label:
                'Proposal Message',
              ),

              const SizedBox(
                height: 8,
              ),

              TextFormField(
                controller:
                _messageController,
                maxLines: 4,
                decoration:
                const InputDecoration(
                  hintText:
                  'Explain why your company is a good match for this safari...',
                ),
              ),

              const SizedBox(
                height: 17,
              ),

              const _FormLabel(
                label:
                'Safari Vehicle',
              ),

              const SizedBox(
                height: 8,
              ),

              TextFormField(
                controller:
                _vehicleController,
                decoration:
                const InputDecoration(
                  hintText:
                  'e.g. 4x4 Safari Land Cruiser',
                  prefixIcon:
                  Icon(
                    Icons
                        .directions_car_outlined,
                    color:
                    FieldGuidePalette.primary,
                  ),
                ),
              ),

              const SizedBox(
                height: 17,
              ),

              const _FormLabel(
                label:
                'Accommodation',
              ),

              const SizedBox(
                height: 8,
              ),

              TextFormField(
                controller:
                _accommodationController,
                maxLines: 3,
                decoration:
                const InputDecoration(
                  hintText:
                  'Describe the accommodation you will provide...',
                ),
              ),

              const SizedBox(
                height: 17,
              ),

              const _FormLabel(
                label:
                'What is Included?',
              ),

              const SizedBox(
                height: 5,
              ),

              const Text(
                'Enter one item per line.',
                style:
                TextStyle(
                  color:
                  FieldGuidePalette.mutedText,
                  fontSize: 11,
                ),
              ),

              const SizedBox(
                height: 8,
              ),

              TextFormField(
                controller:
                _inclusionsController,
                minLines: 4,
                maxLines: 8,
                decoration:
                const InputDecoration(
                  hintText:
                  'Accommodation\nPark entrance fees\nSafari vehicle\nProfessional guide',
                ),
              ),

              const SizedBox(
                height: 17,
              ),

              const _FormLabel(
                label:
                'What is Excluded?',
              ),

              const SizedBox(
                height: 5,
              ),

              const Text(
                'Enter one item per line.',
                style:
                TextStyle(
                  color:
                  FieldGuidePalette.mutedText,
                  fontSize: 11,
                ),
              ),

              const SizedBox(
                height: 8,
              ),

              TextFormField(
                controller:
                _exclusionsController,
                minLines: 3,
                maxLines: 7,
                decoration:
                const InputDecoration(
                  hintText:
                  'International flights\nTravel insurance\nPersonal expenses',
                ),
              ),

              const SizedBox(
                height: 25,
              ),

              SizedBox(
                height: 52,
                child:
                DecoratedBox(
                  decoration:
                  BoxDecoration(
                    gradient:
                    const LinearGradient(
                      begin:
                      Alignment.topCenter,
                      end:
                      Alignment.bottomCenter,
                      colors: [
                        Color(
                          0xFF165B5D,
                        ),
                        Color(
                          0xFF0A3D3F,
                        ),
                      ],
                    ),
                    borderRadius:
                    BorderRadius.circular(
                      100,
                    ),
                  ),
                  child: Material(
                    color:
                    Colors.transparent,
                    borderRadius:
                    BorderRadius.circular(
                      100,
                    ),
                    child: InkWell(
                      onTap:
                      _submitting
                          ? null
                          : _submit,
                      borderRadius:
                      BorderRadius.circular(
                        100,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Center(
                              child: Text(
                                _submitting
                                    ? 'Sending Proposal...'
                                    : widget.request.myProposal ==
                                    null
                                    ? 'Send Proposal'
                                    : 'Update Proposal',
                                style:
                                const TextStyle(
                                  color:
                                  Colors.white,
                                  fontSize: 14,
                                  fontWeight:
                                  FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          Container(
                            width: 40,
                            height: 40,
                            margin:
                            const EdgeInsets.only(
                              right: 6,
                            ),
                            decoration:
                            const BoxDecoration(
                              color:
                              Colors.white,
                              shape:
                              BoxShape.circle,
                            ),
                            alignment:
                            Alignment.center,
                            child: _submitting
                                ? const SizedBox(
                              width: 16,
                              height: 16,
                              child:
                              CircularProgressIndicator(
                                strokeWidth:
                                2,
                                color:
                                FieldGuidePalette.primary,
                              ),
                            )
                                : const Icon(
                              Icons
                                  .arrow_forward_rounded,
                              color:
                              Colors.black,
                              size: 19,
                            ),
                          ),
                        ],
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

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? FieldGuidePalette.primary
          : Colors.white.withOpacity(
        .72,
      ),
      borderRadius:
      BorderRadius.circular(
        100,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius:
        BorderRadius.circular(
          100,
        ),
        child: Container(
          padding:
          const EdgeInsets.symmetric(
            horizontal: 13,
            vertical: 8,
          ),
          decoration:
          BoxDecoration(
            borderRadius:
            BorderRadius.circular(
              100,
            ),
            border:
            Border.all(
              color: selected
                  ? FieldGuidePalette.primary
                  : FieldGuidePalette.border,
            ),
          ),
          child: Text(
            label,
            style:
            TextStyle(
              color: selected
                  ? Colors.white
                  : FieldGuidePalette.ink,
              fontSize: 11,
              fontWeight:
              FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _MatchBadge extends StatelessWidget {
  const _MatchBadge({
    required this.percentage,
  });

  final int percentage;

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
        FieldGuidePalette.secondary
            .withOpacity(
          .10,
        ),
        borderRadius:
        BorderRadius.circular(
          100,
        ),
      ),
      child: Text(
        '$percentage% match',
        style:
        const TextStyle(
          color:
          FieldGuidePalette.secondary,
          fontSize: 10,
          fontWeight:
          FontWeight.w800,
        ),
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
          .75,
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
            textAlign:
            TextAlign.right,
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

class _FormLabel extends StatelessWidget {
  const _FormLabel({
    required this.label,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style:
      const TextStyle(
        color:
        FieldGuidePalette.ink,
        fontSize: 13,
        fontWeight:
        FontWeight.w700,
      ),
    );
  }
}

class _ProposalStatusChip
    extends StatelessWidget {
  const _ProposalStatusChip({
    required this.status,
  });

  final String status;

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;

    switch (status) {
      case 'accepted':
        color =
            FieldGuidePalette.primary;
        label = 'Accepted';
        break;

      case 'declined':
        color =
        const Color(
          0xFF9B4949,
        );
        label = 'Declined';
        break;

      case 'withdrawn':
        color =
            FieldGuidePalette.mutedText;
        label = 'Withdrawn';
        break;

      default:
        color =
            FieldGuidePalette.secondary;
        label = 'Pending';
    }

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
          color: color,
          fontSize: 10,
          fontWeight:
          FontWeight.w800,
        ),
      ),
    );
  }
}

class _EmptyOpportunities
    extends StatelessWidget {
  const _EmptyOpportunities();

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
              'No matching requests yet',
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
              'New safari requests matching your activities and destinations will appear here.',
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
          ],
        ),
      ),
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

List<String> _lines(
    String value,
    ) {
  return value
      .split('\n')
      .map(
        (line) =>
        line.trim(),
  )
      .where(
        (line) =>
    line.isNotEmpty,
  )
      .toList();
}