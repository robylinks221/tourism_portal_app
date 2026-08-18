import 'package:flutter/material.dart';

import '../services/booking_service.dart';
import '../theme/field_guide_theme.dart';
import 'operator_booking_details_page.dart';

class GuideBookingsPage extends StatefulWidget {
  const GuideBookingsPage({super.key});

  @override
  State<GuideBookingsPage> createState() => _GuideBookingsPageState();
}

class _GuideBookingsPageState extends State<GuideBookingsPage> {
  bool _loading = true;

  String? _error;

  int _selectedFilter = 0;

  List<BookingItem> _bookings = [];

  ProviderBookingSummary _summary = const ProviderBookingSummary();

  static const List<String> _filters = [
    'All',
    'Pending',
    'Confirmed',
    'Completed',
    'Cancelled',
  ];

  @override
  void initState() {
    super.initState();

    _load();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final results = await Future.wait<dynamic>([
        BookingService.instance.fetchProviderBookings(),

        BookingService.instance.fetchProviderSummary(),
      ]);

      if (!mounted) {
        return;
      }

      setState(() {
        _bookings = results[0] as List<BookingItem>;

        _summary = results[1] as ProviderBookingSummary;

        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;
        _error = error.toString();
      });
    }
  }

  List<BookingItem> get _filteredBookings {
    if (_selectedFilter == 0) {
      return _bookings;
    }

    final status = _filters[_selectedFilter].toLowerCase();

    return _bookings.where((booking) => booking.status == status).toList();
  }

  Future<void> _openBooking(BookingItem booking) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => OperatorBookingDetailsPage(booking: booking),
      ),
    );

    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final bookings = _filteredBookings;

    return Scaffold(
      backgroundColor: FieldGuidePalette.background,
      appBar: AppBar(
        backgroundColor: FieldGuidePalette.background,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'My Bookings',
          style: TextStyle(
            color: FieldGuidePalette.ink,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        color: FieldGuidePalette.primary,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            const Text(
              'Safari bookings',
              style: TextStyle(
                color: FieldGuidePalette.ink,
                fontSize: 26,
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(height: 5),

            const Text(
              'Manage traveller bookings created from your safari proposals.',
              style: TextStyle(
                color: FieldGuidePalette.mutedText,
                fontSize: 13,
                height: 1.4,
              ),
            ),

            const SizedBox(height: 22),

            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 50),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              _ErrorCard(message: _error!, onRetry: _load)
            else ...[
              _SummaryGrid(summary: _summary),

              const SizedBox(height: 25),

              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _filters.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    return ChoiceChip(
                      label: Text(_filters[index]),
                      selected: _selectedFilter == index,
                      onSelected: (_) {
                        setState(() {
                          _selectedFilter = index;
                        });
                      },
                    );
                  },
                ),
              ),

              const SizedBox(height: 20),

              if (bookings.isEmpty)
                const _EmptyBookings()
              else
                ...bookings.map(
                  (booking) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _GuideBookingCard(
                      booking: booking,
                      onPressed: () {
                        _openBooking(booking);
                      },
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({required this.summary});

  final ProviderBookingSummary summary;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                icon: Icons.receipt_long_outlined,
                value: '${summary.totalBookings}',
                label: 'Bookings',
              ),
            ),

            const SizedBox(width: 11),

            Expanded(
              child: _SummaryCard(
                icon: Icons.schedule_rounded,
                value: '${summary.pendingBookings}',
                label: 'Pending',
              ),
            ),
          ],
        ),

        const SizedBox(height: 11),

        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                icon: Icons.groups_outlined,
                value: '${summary.travellers}',
                label: 'Travellers',
              ),
            ),

            const SizedBox(width: 11),

            Expanded(
              child: _SummaryCard(
                icon: Icons.payments_outlined,
                value:
                    '${summary.currency} ${summary.bookingValue.toStringAsFixed(0)}',
                label: 'Booking value',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;

  final String value;

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: FieldGuidePalette.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: FieldGuidePalette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: FieldGuidePalette.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: FieldGuidePalette.primary, size: 20),
          ),

          const SizedBox(height: 12),

          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: FieldGuidePalette.ink,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 3),

          Text(
            label,
            style: const TextStyle(
              color: FieldGuidePalette.mutedText,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _GuideBookingCard extends StatelessWidget {
  const _GuideBookingCard({required this.booking, required this.onPressed});

  final BookingItem booking;

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(booking.status);

    return Material(
      color: FieldGuidePalette.surface,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: FieldGuidePalette.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 45,
                    height: 45,
                    decoration: BoxDecoration(
                      color: FieldGuidePalette.primary.withValues(alpha: .09),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.luggage_outlined,
                      color: FieldGuidePalette.primary,
                    ),
                  ),

                  const SizedBox(width: 11),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          booking.tourist.name.isEmpty
                              ? 'Traveller'
                              : booking.tourist.name,
                          style: const TextStyle(
                            color: FieldGuidePalette.ink,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),

                        const SizedBox(height: 2),

                        Text(
                          booking.reference,
                          style: const TextStyle(
                            color: FieldGuidePalette.mutedText,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: .10),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      _prettyStatus(booking.status),
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 13),

              Text(
                booking.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: FieldGuidePalette.ink,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 11),

              Row(
                children: [
                  const Icon(
                    Icons.groups_outlined,
                    color: FieldGuidePalette.secondary,
                    size: 15,
                  ),

                  const SizedBox(width: 4),

                  Text(
                    '${booking.travellers} traveller${booking.travellers == 1 ? '' : 's'}',
                    style: const TextStyle(
                      color: FieldGuidePalette.mutedText,
                      fontSize: 11,
                    ),
                  ),

                  const Spacer(),

                  Text(
                    '${booking.currency} ${booking.totalAmount.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: FieldGuidePalette.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),

              if (booking.startDate != null) ...[
                const SizedBox(height: 8),

                Row(
                  children: [
                    const Icon(
                      Icons.calendar_month_outlined,
                      color: FieldGuidePalette.mutedText,
                      size: 14,
                    ),

                    const SizedBox(width: 4),

                    Text(
                      booking.startDate!,
                      style: const TextStyle(
                        color: FieldGuidePalette.mutedText,
                        fontSize: 11,
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

class _EmptyBookings extends StatelessWidget {
  const _EmptyBookings();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 42),
      decoration: BoxDecoration(
        color: FieldGuidePalette.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: FieldGuidePalette.border),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.event_available_outlined,
            color: FieldGuidePalette.primary,
            size: 42,
          ),

          SizedBox(height: 12),

          Text(
            'No bookings yet',
            style: TextStyle(
              color: FieldGuidePalette.ink,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),

          SizedBox(height: 6),

          Text(
            'When a traveller accepts one of your safari proposals, the booking will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: FieldGuidePalette.mutedText,
              fontSize: 12,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});

  final String message;

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF9B4949).withValues(alpha: .08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline_rounded, color: Color(0xFF9B4949)),

          const SizedBox(height: 8),

          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF9B4949), fontSize: 12),
          ),

          const SizedBox(height: 12),

          TextButton(
            onPressed: () {
              onRetry();
            },
            child: const Text('Try Again'),
          ),
        ],
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

String _prettyStatus(String status) {
  return status
      .replaceAll('_', ' ')
      .split(' ')
      .map(
        (word) =>
            word.isEmpty ? '' : '${word[0].toUpperCase()}${word.substring(1)}',
      )
      .join(' ');
}
