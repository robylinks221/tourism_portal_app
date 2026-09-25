import 'dart:async';

import 'package:flutter/material.dart';

import '../services/booking_service.dart';
import '../theme/field_guide_theme.dart';

class OperatorBookingDetailsPage extends StatefulWidget {
  const OperatorBookingDetailsPage({super.key, required this.booking});

  final BookingItem booking;

  @override
  State<OperatorBookingDetailsPage> createState() =>
      _OperatorBookingDetailsPageState();
}

class _OperatorBookingDetailsPageState
    extends State<OperatorBookingDetailsPage> {
  late BookingItem _booking;
  BookingGuideAssignmentItem? _assignment;

  bool _loading = false;
  bool _assignmentLoading = false;
  String? _assignmentError;

  @override
  void initState() {
    super.initState();
    _booking = widget.booking;
    _refresh();
  }

  Future<void> _refresh() async {
    try {
      final booking = await BookingService.instance.fetchBooking(_booking.id);
      if (!mounted) return;
      setState(() => _booking = booking);
    } catch (_) {
      // Keep the already-loaded booking visible.
    }

    if (_booking.isTourOperator) {
      await _loadAssignment();
    }
  }

  Future<void> _loadAssignment() async {
    if (!_booking.isTourOperator) return;

    setState(() {
      _assignmentLoading = true;
      _assignmentError = null;
    });

    try {
      final assignment = await BookingService.instance
          .fetchBookingGuideAssignment(_booking.id);
      if (!mounted) return;
      setState(() {
        _assignment = assignment;
        _assignmentLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _assignmentLoading = false;
        _assignmentError = error.toString();
      });
    }
  }

  Future<void> _openAssignGuide() async {
    if (_loading || _booking.isCancelled || _booking.isCompleted) return;

    final result = await showModalBottomSheet<_GuideAssignmentDraft>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AssignGuideSheet(bookingId: _booking.id),
    );

    if (result == null) return;

    setState(() => _loading = true);

    try {
      final assignment = await BookingService.instance.assignGuideToBooking(
        bookingId: _booking.id,
        guideUserId: result.guide.id,
        assignmentNotes: result.notes,
      );
      if (!mounted) return;
      setState(() => _assignment = assignment);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${result.guide.name} has been sent the team assignment.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _cancelAssignment() async {
    final assignment = _assignment;
    if (assignment == null || !assignment.isOpen || _loading) return;

    final confirmed = await _confirmAction(
      title: 'Cancel Guide Assignment?',
      message:
          'This removes the guide from this safari assignment. The booking remains owned by your tour operator.',
      actionText: 'Cancel Assignment',
      destructive: true,
    );

    if (!confirmed) return;

    setState(() => _loading = true);

    try {
      final updated = await BookingService.instance
          .cancelBookingGuideAssignment(
            bookingId: _booking.id,
            assignmentId: assignment.id,
          );
      if (!mounted) return;
      setState(() => _assignment = updated);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Guide assignment cancelled.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _confirmBooking() async {
    if (_loading) return;

    final confirmed = await _confirmAction(
      title: 'Confirm Booking?',
      message: 'Confirm that you are accepting this safari booking.',
      actionText: 'Confirm Booking',
    );
    if (!confirmed) return;

    setState(() => _loading = true);
    try {
      final booking = await BookingService.instance.confirmBooking(_booking.id);
      if (!mounted) return;
      setState(() => _booking = booking);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking confirmed successfully.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _completeBooking() async {
    if (_loading) return;

    final confirmed = await _confirmAction(
      title: 'Complete Safari?',
      message:
          'Mark this booking as completed only after the safari has finished.',
      actionText: 'Mark Completed',
    );
    if (!confirmed) return;

    setState(() => _loading = true);
    try {
      final booking = await BookingService.instance.completeBooking(
        _booking.id,
      );
      if (!mounted) return;
      setState(() => _booking = booking);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Safari marked as completed.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _cancelBooking() async {
    if (_loading) return;

    final confirmed = await _confirmAction(
      title: 'Cancel Booking?',
      message:
          'This will cancel the safari booking for both you and the traveller.',
      actionText: 'Cancel Booking',
      destructive: true,
    );
    if (!confirmed) return;

    setState(() => _loading = true);
    try {
      final booking = await BookingService.instance.cancelOperatorBooking(
        _booking.id,
      );
      if (!mounted) return;
      setState(() => _booking = booking);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Booking cancelled.')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _editNotes() async {
    final controller = TextEditingController(
      text: _booking.operatorNotes ?? '',
    );

    final notes = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            decoration: const BoxDecoration(
              color: FieldGuidePalette.background,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: FieldGuidePalette.border,
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Operator Notes',
                  style: TextStyle(
                    color: FieldGuidePalette.ink,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  minLines: 4,
                  maxLines: 8,
                  decoration: const InputDecoration(
                    hintText: 'Add private notes about this booking...',
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 50,
                  child: FilledButton(
                    onPressed: () {
                      Navigator.pop(sheetContext, controller.text.trim());
                    },
                    child: const Text(
                      'Save Notes',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    controller.dispose();
    if (notes == null) return;

    try {
      final booking = await BookingService.instance.updateOperatorNotes(
        bookingId: _booking.id,
        notes: notes,
      );
      if (!mounted) return;
      setState(() => _booking = booking);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Booking notes updated.')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<bool> _confirmAction({
    required String title,
    required String message,
    required String actionText,
    bool destructive = false,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              backgroundColor: FieldGuidePalette.background,
              title: Text(
                title,
                style: const TextStyle(
                  color: FieldGuidePalette.ink,
                  fontWeight: FontWeight.w800,
                ),
              ),
              content: Text(
                message,
                style: const TextStyle(color: FieldGuidePalette.mutedText),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Not Now'),
                ),
                FilledButton(
                  style:
                      destructive
                          ? FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF9B4949),
                          )
                          : null,
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(actionText),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FieldGuidePalette.background,
      appBar: AppBar(
        backgroundColor: FieldGuidePalette.background,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Booking Details',
          style: TextStyle(
            color: FieldGuidePalette.ink,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: RefreshIndicator(
        color: FieldGuidePalette.primary,
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 34),
          children: [
            _BookingHeader(booking: _booking),
            const SizedBox(height: 16),
            _SectionCard(
              title: 'Traveller',
              children: [
                _DetailRow(
                  icon: Icons.person_outline_rounded,
                  label: 'Name',
                  value:
                      _booking.tourist.name.isEmpty
                          ? 'Traveller'
                          : _booking.tourist.name,
                ),
                _DetailRow(
                  icon: Icons.groups_outlined,
                  label: 'Travellers',
                  value: '${_booking.travellers}',
                ),
              ],
            ),
            const SizedBox(height: 14),
            _SectionCard(
              title: 'Safari',
              children: [
                _DetailRow(
                  icon: Icons.luggage_outlined,
                  label: 'Safari',
                  value: _booking.title,
                ),
                if (_booking.days != null)
                  _DetailRow(
                    icon: Icons.schedule_rounded,
                    label: 'Duration',
                    value: '${_booking.days} days',
                  ),
                _DetailRow(
                  icon: Icons.calendar_month_outlined,
                  label: 'Start Date',
                  value: _booking.startDate ?? 'Not specified',
                ),
                _DetailRow(
                  icon: Icons.calendar_month_outlined,
                  label: 'End Date',
                  value: _booking.endDate ?? 'Not specified',
                ),
              ],
            ),
            if (_booking.isTourOperator) ...[
              const SizedBox(height: 14),
              _GuideAssignmentCard(
                assignment: _assignment,
                loading: _assignmentLoading,
                error: _assignmentError,
                bookingClosed: _booking.isCancelled || _booking.isCompleted,
                busy: _loading,
                onAssign: _openAssignGuide,
                onRetry: _loadAssignment,
                onCancel: _cancelAssignment,
              ),
            ],
            if (_booking.destinations.isNotEmpty) ...[
              const SizedBox(height: 14),
              _SectionCard(
                title: 'Destinations',
                children: [
                  Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children:
                        _booking.destinations
                            .map((item) => _Tag(text: item.name))
                            .toList(),
                  ),
                ],
              ),
            ],
            if (_booking.activities.isNotEmpty) ...[
              const SizedBox(height: 14),
              _SectionCard(
                title: 'Activities',
                children: [
                  Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children:
                        _booking.activities
                            .map((item) => _Tag(text: item.name))
                            .toList(),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 14),
            _SectionCard(
              title: 'Proposal & Payment',
              children: [
                _DetailRow(
                  icon: Icons.payments_outlined,
                  label: 'Booking Total',
                  value:
                      '${_booking.currency} ${_booking.totalAmount.toStringAsFixed(0)}',
                  emphasize: true,
                ),
                _DetailRow(
                  icon: Icons.account_balance_wallet_outlined,
                  label: 'Payment',
                  value: _prettyStatus(_booking.paymentStatus),
                ),
                if ((_booking.vehicle ?? '').isNotEmpty)
                  _DetailRow(
                    icon: Icons.directions_car_outlined,
                    label: 'Vehicle',
                    value: _booking.vehicle!,
                  ),
                if ((_booking.accommodationLevel ?? '').isNotEmpty)
                  _DetailRow(
                    icon: Icons.hotel_outlined,
                    label: 'Accommodation',
                    value: _booking.accommodationLevel!,
                  ),
              ],
            ),
            if (_booking.inclusions.isNotEmpty) ...[
              const SizedBox(height: 14),
              _SectionCard(
                title: 'Includes',
                children:
                    _booking.inclusions
                        .map((item) => _ListItem(text: item, positive: true))
                        .toList(),
              ),
            ],
            if (_booking.exclusions.isNotEmpty) ...[
              const SizedBox(height: 14),
              _SectionCard(
                title: 'Excludes',
                children:
                    _booking.exclusions
                        .map((item) => _ListItem(text: item, positive: false))
                        .toList(),
              ),
            ],
            if ((_booking.operatorNotes ?? '').isNotEmpty) ...[
              const SizedBox(height: 14),
              _SectionCard(
                title: 'Your Notes',
                children: [
                  Text(
                    _booking.operatorNotes!,
                    style: const TextStyle(
                      color: FieldGuidePalette.mutedText,
                      fontSize: 12.5,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: _editNotes,
              icon: const Icon(Icons.edit_note_rounded),
              label: const Text(
                'Operator Notes',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 10),
            if (_booking.isPending)
              SizedBox(
                height: 52,
                child: FilledButton.icon(
                  onPressed: _loading ? null : _confirmBooking,
                  icon: const Icon(Icons.check_circle_outline_rounded),
                  label: Text(
                    _loading ? 'Please Wait...' : 'Confirm Booking',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            if (_booking.isConfirmed)
              SizedBox(
                height: 52,
                child: FilledButton.icon(
                  onPressed: _loading ? null : _completeBooking,
                  icon: const Icon(Icons.flag_outlined),
                  label: Text(
                    _loading ? 'Please Wait...' : 'Mark Safari Completed',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            if (!_booking.isCancelled && !_booking.isCompleted) ...[
              const SizedBox(height: 10),
              SizedBox(
                height: 50,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF9B4949),
                    side: const BorderSide(color: Color(0xFF9B4949)),
                  ),
                  onPressed: _loading ? null : _cancelBooking,
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text(
                    'Cancel Booking',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 10),
            SizedBox(
              height: 50,
              child: OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Traveller messaging will be connected to this booking next.',
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.chat_bubble_outline_rounded),
                label: const Text(
                  'Message Traveller',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GuideAssignmentCard extends StatelessWidget {
  const _GuideAssignmentCard({
    required this.assignment,
    required this.loading,
    required this.error,
    required this.bookingClosed,
    required this.busy,
    required this.onAssign,
    required this.onRetry,
    required this.onCancel,
  });

  final BookingGuideAssignmentItem? assignment;
  final bool loading;
  final String? error;
  final bool bookingClosed;
  final bool busy;
  final VoidCallback onAssign;
  final VoidCallback onRetry;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const _SectionCard(
        title: 'Safari Guide',
        children: [
          Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          ),
        ],
      );
    }

    if (error != null) {
      return _SectionCard(
        title: 'Safari Guide',
        children: [
          Text(
            error!,
            style: const TextStyle(
              color: FieldGuidePalette.mutedText,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
          ),
        ],
      );
    }

    final current = assignment;
    final guide = current?.guide;

    if (current == null || current.isDeclined || current.isCancelled) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .78),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: FieldGuidePalette.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: FieldGuidePalette.primary.withValues(alpha: .10),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.person_add_alt_1_rounded,
                    color: FieldGuidePalette.primary,
                  ),
                ),
                const SizedBox(width: 11),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Safari Guide',
                        style: TextStyle(
                          color: FieldGuidePalette.ink,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Assign a guide from your active safari team.',
                        style: TextStyle(
                          color: FieldGuidePalette.mutedText,
                          fontSize: 11.5,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (current != null) ...[
              const SizedBox(height: 13),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: FieldGuidePalette.secondary.withValues(alpha: .08),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Text(
                  current.isDeclined
                      ? '${guide?.name ?? 'The guide'} declined the previous assignment. You can select another team guide.'
                      : 'The previous guide assignment was cancelled. You can select another team guide.',
                  style: const TextStyle(
                    color: FieldGuidePalette.mutedText,
                    fontSize: 11,
                    height: 1.35,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                onPressed: bookingClosed || busy ? null : onAssign,
                icon: const Icon(Icons.person_search_rounded),
                label: Text(
                  current == null ? 'Assign Guide' : 'Assign Another Guide',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final statusColor = _assignmentStatusColor(current.status);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .80),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: FieldGuidePalette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Safari Guide',
                  style: TextStyle(
                    color: FieldGuidePalette.ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _StatusChip(
                text: _prettyStatus(current.status),
                color: statusColor,
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              _InitialAvatar(name: guide?.name ?? 'Guide'),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      guide?.name ?? 'Assigned Guide',
                      style: const TextStyle(
                        color: FieldGuidePalette.ink,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _guideMeta(guide),
                      style: const TextStyle(
                        color: FieldGuidePalette.mutedText,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if ((current.assignmentNotes ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: FieldGuidePalette.primary.withValues(alpha: .06),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                current.assignmentNotes!,
                style: const TextStyle(
                  color: FieldGuidePalette.mutedText,
                  fontSize: 11.5,
                  height: 1.4,
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          const Text(
            'The booking and payment remain under your tour operator. The guide only receives the safari work assignment.',
            style: TextStyle(
              color: FieldGuidePalette.mutedText,
              fontSize: 10.8,
              height: 1.4,
            ),
          ),
          if (!bookingClosed) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: busy ? null : onAssign,
                    icon: const Icon(Icons.swap_horiz_rounded),
                    label: const Text(
                      'Change Guide',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF9B4949),
                    ),
                    onPressed: busy ? null : onCancel,
                    icon: const Icon(Icons.person_remove_outlined),
                    label: const Text(
                      'Remove',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  static String _guideMeta(EligibleTeamGuide? guide) {
    if (guide == null) return 'Tourist Guide';
    final parts = <String>[];
    if (guide.country.trim().isNotEmpty) parts.add(guide.country.trim());
    if (guide.yearsExperience > 0) {
      parts.add('${guide.yearsExperience} yrs experience');
    }
    return parts.isEmpty ? 'Tourist Guide' : parts.join(' • ');
  }
}

class _AssignGuideSheet extends StatefulWidget {
  const _AssignGuideSheet({required this.bookingId});

  final int bookingId;

  @override
  State<_AssignGuideSheet> createState() => _AssignGuideSheetState();
}

class _AssignGuideSheetState extends State<_AssignGuideSheet> {
  final _searchController = TextEditingController();
  final _notesController = TextEditingController();
  Timer? _debounce;

  bool _loading = true;
  String? _error;
  List<EligibleTeamGuide> _guides = const [];
  EligibleTeamGuide? _selectedGuide;

  @override
  void initState() {
    super.initState();
    _loadGuides();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 350),
      () => _loadGuides(query: value),
    );
  }

  Future<void> _loadGuides({String query = ''}) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final guides = await BookingService.instance.fetchEligibleTeamGuides(
        bookingId: widget.bookingId,
        query: query,
      );
      if (!mounted) return;
      setState(() {
        _guides = guides;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final keyboardInset = MediaQuery.of(context).viewInsets.bottom;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      padding: EdgeInsets.only(bottom: keyboardInset),
      child: Material(
        color: FieldGuidePalette.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        clipBehavior: Clip.antiAlias,
        child: SafeArea(
          top: false,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * .88,
            ),
            child: Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: FieldGuidePalette.border,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 12, 10),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Assign Safari Guide',
                              style: TextStyle(
                                color: FieldGuidePalette.ink,
                                fontSize: 21,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              'Search only active guides on your safari team.',
                              style: TextStyle(
                                color: FieldGuidePalette.mutedText,
                                fontSize: 11.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    decoration: const InputDecoration(
                      hintText: 'Type guide name...',
                      prefixIcon: Icon(Icons.search_rounded),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(child: _buildGuideResults()),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                  child: Column(
                    children: [
                      TextField(
                        controller: _notesController,
                        minLines: 2,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'Assignment notes (optional)',
                          hintText:
                              'Meeting point, pickup time, special traveller needs...',
                          alignLabelWithHint: true,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: FilledButton.icon(
                          onPressed:
                              _selectedGuide == null
                                  ? null
                                  : () {
                                    Navigator.pop(
                                      context,
                                      _GuideAssignmentDraft(
                                        guide: _selectedGuide!,
                                        notes: _notesController.text.trim(),
                                      ),
                                    );
                                  },
                          icon: const Icon(Icons.assignment_turned_in_outlined),
                          label: Text(
                            _selectedGuide == null
                                ? 'Select a Guide'
                                : 'Send Assignment',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGuideResults() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: FieldGuidePalette.secondary,
                size: 35,
              ),
              const SizedBox(height: 10),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: FieldGuidePalette.mutedText),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => _loadGuides(query: _searchController.text),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_guides.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.group_off_outlined,
                color: FieldGuidePalette.primary,
                size: 42,
              ),
              SizedBox(height: 12),
              Text(
                'No matching team guides',
                style: TextStyle(
                  color: FieldGuidePalette.ink,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 5),
              Text(
                'Only active guides connected to your tour operator can be assigned.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: FieldGuidePalette.mutedText,
                  fontSize: 11.5,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      itemCount: _guides.length,
      separatorBuilder: (_, __) => const SizedBox(height: 9),
      itemBuilder: (context, index) {
        final guide = _guides[index];
        final selected = _selectedGuide?.id == guide.id;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => setState(() => _selectedGuide = guide),
            borderRadius: BorderRadius.circular(18),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color:
                    selected
                        ? FieldGuidePalette.primary.withValues(alpha: .08)
                        : Colors.white.withValues(alpha: .70),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color:
                      selected
                          ? FieldGuidePalette.primary
                          : FieldGuidePalette.border,
                ),
              ),
              child: Row(
                children: [
                  _InitialAvatar(name: guide.name, small: true),
                  const SizedBox(width: 11),
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
                                style: const TextStyle(
                                  color: FieldGuidePalette.ink,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            if (guide.isVerified) ...[
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.verified_rounded,
                                color: FieldGuidePalette.primary,
                                size: 16,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _eligibleGuideMeta(guide),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: FieldGuidePalette.mutedText,
                            fontSize: 10.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    selected
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color:
                        selected
                            ? FieldGuidePalette.primary
                            : FieldGuidePalette.mutedText,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _GuideAssignmentDraft {
  const _GuideAssignmentDraft({required this.guide, required this.notes});

  final EligibleTeamGuide guide;
  final String notes;
}

class _InitialAvatar extends StatelessWidget {
  const _InitialAvatar({required this.name, this.small = false});

  final String name;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final value =
        name.trim().isEmpty
            ? 'G'
            : name
                .trim()
                .split(RegExp(r'\s+'))
                .take(2)
                .map((part) => part.isEmpty ? '' : part[0].toUpperCase())
                .join();

    final size = small ? 44.0 : 52.0;

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: FieldGuidePalette.primary.withValues(alpha: .12),
        shape: BoxShape.circle,
        border: Border.all(
          color: FieldGuidePalette.primary.withValues(alpha: .20),
        ),
      ),
      child: Text(
        value,
        style: TextStyle(
          color: FieldGuidePalette.primary,
          fontSize: small ? 13 : 15,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _BookingHeader extends StatelessWidget {
  const _BookingHeader({required this.booking});

  final BookingItem booking;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .78),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: FieldGuidePalette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'BOOKING REFERENCE',
            style: TextStyle(
              color: FieldGuidePalette.mutedText,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  booking.reference,
                  style: const TextStyle(
                    color: FieldGuidePalette.ink,
                    fontSize: 23,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _StatusChip(
                text: _prettyStatus(booking.status),
                color: _statusColor(booking.status),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            booking.title,
            style: const TextStyle(
              color: FieldGuidePalette.ink,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .76),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: FieldGuidePalette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: FieldGuidePalette.ink,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: FieldGuidePalette.primary, size: 18),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: FieldGuidePalette.mutedText,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color:
                    emphasize
                        ? FieldGuidePalette.primary
                        : FieldGuidePalette.ink,
                fontSize: emphasize ? 15 : 12,
                fontWeight: emphasize ? FontWeight.w900 : FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: FieldGuidePalette.primary.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: FieldGuidePalette.primary,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ListItem extends StatelessWidget {
  const _ListItem({required this.text, required this.positive});

  final String text;
  final bool positive;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            positive
                ? Icons.check_circle_outline_rounded
                : Icons.remove_circle_outline_rounded,
            color:
                positive
                    ? FieldGuidePalette.primary
                    : FieldGuidePalette.secondary,
            size: 17,
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: FieldGuidePalette.mutedText,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

Color _statusColor(String status) {
  switch (status) {
    case 'confirmed':
      return const Color(0xFF2E7D32);
    case 'completed':
      return FieldGuidePalette.primary;
    case 'cancelled':
      return const Color(0xFF9B4949);
    default:
      return FieldGuidePalette.secondary;
  }
}

Color _assignmentStatusColor(String status) {
  switch (status) {
    case 'accepted':
      return const Color(0xFF2E7D32);
    case 'declined':
    case 'cancelled':
      return const Color(0xFF9B4949);
    default:
      return FieldGuidePalette.secondary;
  }
}

String _eligibleGuideMeta(EligibleTeamGuide guide) {
  final parts = <String>[];
  if (guide.country.trim().isNotEmpty) parts.add(guide.country.trim());
  if (guide.yearsExperience > 0) {
    parts.add('${guide.yearsExperience} yrs experience');
  }
  if (guide.languages.isNotEmpty) {
    parts.add(guide.languages.take(2).join(', '));
  }
  return parts.isEmpty ? 'Tourist Guide' : parts.join(' • ');
}

String _prettyStatus(String status) {
  if (status.isEmpty) return '';
  return status
      .replaceAll('_', ' ')
      .split(' ')
      .map(
        (word) =>
            word.isEmpty ? '' : '${word[0].toUpperCase()}${word.substring(1)}',
      )
      .join(' ');
}
