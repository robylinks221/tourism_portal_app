import 'package:flutter/material.dart';

import '../services/booking_service.dart';
import '../theme/field_guide_theme.dart';

class OperatorBookingDetailsPage extends StatefulWidget {
  const OperatorBookingDetailsPage({
    super.key,
    required this.booking,
  });

  final BookingItem booking;

  @override
  State<OperatorBookingDetailsPage> createState() =>
      _OperatorBookingDetailsPageState();
}

class _OperatorBookingDetailsPageState
    extends State<OperatorBookingDetailsPage> {
  late BookingItem _booking;

  bool _loading = false;

  @override
  void initState() {
    super.initState();

    _booking = widget.booking;

    _refresh();
  }

  Future<void> _refresh() async {
    try {
      final booking =
      await BookingService.instance.fetchBooking(
        _booking.id,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _booking = booking;
      });
    } catch (_) {
      // Keep the already-loaded booking visible.
    }
  }

  Future<void> _confirmBooking() async {
    if (_loading) {
      return;
    }

    final confirmed = await _confirmAction(
      title: 'Confirm Booking?',
      message:
      'Confirm that you are accepting this safari booking.',
      actionText: 'Confirm Booking',
    );

    if (!confirmed) {
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      final booking =
      await BookingService.instance.confirmBooking(
        _booking.id,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _booking = booking;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Booking confirmed successfully.',
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
          _loading = false;
        });
      }
    }
  }

  Future<void> _completeBooking() async {
    if (_loading) {
      return;
    }

    final confirmed = await _confirmAction(
      title: 'Complete Safari?',
      message:
      'Mark this booking as completed only after the safari has finished.',
      actionText: 'Mark Completed',
    );

    if (!confirmed) {
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      final booking =
      await BookingService.instance.completeBooking(
        _booking.id,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _booking = booking;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Safari marked as completed.',
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
          _loading = false;
        });
      }
    }
  }

  Future<void> _cancelBooking() async {
    if (_loading) {
      return;
    }

    final confirmed = await _confirmAction(
      title: 'Cancel Booking?',
      message:
      'This will cancel the safari booking for both you and the traveller.',
      actionText: 'Cancel Booking',
      destructive: true,
    );

    if (!confirmed) {
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      final booking =
      await BookingService.instance.cancelOperatorBooking(
        _booking.id,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _booking = booking;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Booking cancelled.',
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
          _loading = false;
        });
      }
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
            bottom:
            MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(
              20,
              12,
              20,
              24,
            ),
            decoration: const BoxDecoration(
              color: FieldGuidePalette.background,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment:
              CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: FieldGuidePalette.border,
                      borderRadius:
                      BorderRadius.circular(30),
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
                    hintText:
                    'Add private notes about this booking...',
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 50,
                  child: FilledButton(
                    onPressed: () {
                      Navigator.pop(
                        sheetContext,
                        controller.text.trim(),
                      );
                    },
                    child: const Text(
                      'Save Notes',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                      ),
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

    if (notes == null) {
      return;
    }

    try {
      final booking =
      await BookingService.instance.updateOperatorNotes(
        bookingId: _booking.id,
        notes: notes,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _booking = booking;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Booking notes updated.',
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
          backgroundColor:
          FieldGuidePalette.background,
          title: Text(
            title,
            style: const TextStyle(
              color: FieldGuidePalette.ink,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: Text(
            message,
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
                'Not Now',
              ),
            ),
            FilledButton(
              style: destructive
                  ? FilledButton.styleFrom(
                backgroundColor:
                const Color(
                  0xFF9B4949,
                ),
              )
                  : null,
              onPressed: () {
                Navigator.pop(
                  context,
                  true,
                );
              },
              child: Text(
                actionText,
              ),
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
      backgroundColor:
      FieldGuidePalette.background,
      appBar: AppBar(
        backgroundColor:
        FieldGuidePalette.background,
        surfaceTintColor:
        Colors.transparent,
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
          padding: const EdgeInsets.fromLTRB(
            20,
            10,
            20,
            34,
          ),
          children: [
            _BookingHeader(
              booking: _booking,
            ),

            const SizedBox(height: 16),

            _SectionCard(
              title: 'Traveller',
              children: [
                _DetailRow(
                  icon: Icons.person_outline_rounded,
                  label: 'Name',
                  value: _booking.tourist.name.isEmpty
                      ? 'Traveller'
                      : _booking.tourist.name,
                ),
                _DetailRow(
                  icon: Icons.groups_outlined,
                  label: 'Travellers',
                  value:
                  '${_booking.travellers}',
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
                    value:
                    '${_booking.days} days',
                  ),
                _DetailRow(
                  icon:
                  Icons.calendar_month_outlined,
                  label: 'Start Date',
                  value:
                  _booking.startDate ??
                      'Not specified',
                ),
                _DetailRow(
                  icon:
                  Icons.calendar_month_outlined,
                  label: 'End Date',
                  value:
                  _booking.endDate ??
                      'Not specified',
                ),
              ],
            ),

            if (_booking.destinations.isNotEmpty) ...[
              const SizedBox(height: 14),
              _SectionCard(
                title: 'Destinations',
                children: [
                  Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children: _booking.destinations
                        .map(
                          (item) => _Tag(
                        text: item.name,
                      ),
                    )
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
                    children: _booking.activities
                        .map(
                          (item) => _Tag(
                        text: item.name,
                      ),
                    )
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
                  icon:
                  Icons.account_balance_wallet_outlined,
                  label: 'Payment',
                  value: _prettyStatus(
                    _booking.paymentStatus,
                  ),
                ),
                if ((_booking.vehicle ?? '')
                    .isNotEmpty)
                  _DetailRow(
                    icon:
                    Icons.directions_car_outlined,
                    label: 'Vehicle',
                    value: _booking.vehicle!,
                  ),
                if ((_booking.accommodationLevel ?? '')
                    .isNotEmpty)
                  _DetailRow(
                    icon: Icons.hotel_outlined,
                    label: 'Accommodation',
                    value:
                    _booking.accommodationLevel!,
                  ),
              ],
            ),

            if (_booking.inclusions.isNotEmpty) ...[
              const SizedBox(height: 14),
              _SectionCard(
                title: 'Includes',
                children: _booking.inclusions
                    .map(
                      (item) => _ListItem(
                    text: item,
                    positive: true,
                  ),
                )
                    .toList(),
              ),
            ],

            if (_booking.exclusions.isNotEmpty) ...[
              const SizedBox(height: 14),
              _SectionCard(
                title: 'Excludes',
                children: _booking.exclusions
                    .map(
                      (item) => _ListItem(
                    text: item,
                    positive: false,
                  ),
                )
                    .toList(),
              ),
            ],

            if ((_booking.operatorNotes ?? '')
                .isNotEmpty) ...[
              const SizedBox(height: 14),
              _SectionCard(
                title: 'Your Notes',
                children: [
                  Text(
                    _booking.operatorNotes!,
                    style: const TextStyle(
                      color:
                      FieldGuidePalette.mutedText,
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
              icon:
              const Icon(Icons.edit_note_rounded),
              label: const Text(
                'Operator Notes',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),

            const SizedBox(height: 10),

            if (_booking.isPending)
              SizedBox(
                height: 52,
                child: FilledButton.icon(
                  onPressed:
                  _loading ? null : _confirmBooking,
                  icon: const Icon(
                    Icons.check_circle_outline_rounded,
                  ),
                  label: Text(
                    _loading
                        ? 'Please Wait...'
                        : 'Confirm Booking',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),

            if (_booking.isConfirmed)
              SizedBox(
                height: 52,
                child: FilledButton.icon(
                  onPressed:
                  _loading ? null : _completeBooking,
                  icon: const Icon(
                    Icons.flag_outlined,
                  ),
                  label: Text(
                    _loading
                        ? 'Please Wait...'
                        : 'Mark Safari Completed',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),

            if (!_booking.isCancelled &&
                !_booking.isCompleted) ...[
              const SizedBox(height: 10),
              SizedBox(
                height: 50,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor:
                    const Color(0xFF9B4949),
                    side: const BorderSide(
                      color: Color(0xFF9B4949),
                    ),
                  ),
                  onPressed:
                  _loading ? null : _cancelBooking,
                  icon: const Icon(
                    Icons.cancel_outlined,
                  ),
                  label: const Text(
                    'Cancel Booking',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 10),

            SizedBox(
              height: 50,
              child: OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Traveller messaging will be connected to this booking next.',
                      ),
                    ),
                  );
                },
                icon: const Icon(
                  Icons.chat_bubble_outline_rounded,
                ),
                label: const Text(
                  'Message Traveller',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
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

class _BookingHeader extends StatelessWidget {
  const _BookingHeader({
    required this.booking,
  });

  final BookingItem booking;

  @override
  Widget build(BuildContext context) {
    final statusColor =
    _statusColor(
      booking.status,
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.78),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: FieldGuidePalette.border,
        ),
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          const Text(
            'BOOKING REFERENCE',
            style: TextStyle(
              color:
              FieldGuidePalette.mutedText,
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
                text:
                _prettyStatus(booking.status),
                color: statusColor,
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
  const _SectionCard({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.76),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: FieldGuidePalette.border,
        ),
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
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
      padding:
      const EdgeInsets.only(bottom: 11),
      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: FieldGuidePalette.primary,
            size: 18,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color:
                FieldGuidePalette.mutedText,
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
                color: emphasize
                    ? FieldGuidePalette.primary
                    : FieldGuidePalette.ink,
                fontSize: emphasize ? 15 : 12,
                fontWeight: emphasize
                    ? FontWeight.w900
                    : FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({
    required this.text,
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: FieldGuidePalette.primary
            .withOpacity(.08),
        borderRadius:
        BorderRadius.circular(100),
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
  const _ListItem({
    required this.text,
    required this.positive,
  });

  final String text;
  final bool positive;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
      const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Icon(
            positive
                ? Icons.check_circle_outline_rounded
                : Icons.remove_circle_outline_rounded,
            color: positive
                ? FieldGuidePalette.primary
                : FieldGuidePalette.secondary,
            size: 17,
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color:
                FieldGuidePalette.mutedText,
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
  const _StatusChip({
    required this.text,
    required this.color,
  });

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(.10),
        borderRadius:
        BorderRadius.circular(100),
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

Color _statusColor(
    String status,
    ) {
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

String _prettyStatus(
    String status,
    ) {
  if (status.isEmpty) {
    return '';
  }

  return status
      .replaceAll('_', ' ')
      .split(' ')
      .map(
        (word) => word.isEmpty
        ? ''
        : '${word[0].toUpperCase()}${word.substring(1)}',
  )
      .join(' ');
}