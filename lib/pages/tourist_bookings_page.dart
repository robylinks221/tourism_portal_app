import 'package:flutter/material.dart';

import '../services/api_exception.dart';
import '../services/booking_service.dart';

class TouristBookingsPage extends StatefulWidget {
  const TouristBookingsPage({super.key});

  @override
  State<TouristBookingsPage> createState() => _TouristBookingsPageState();
}

class _TouristBookingsPageState extends State<TouristBookingsPage> {
  List<BookingItem> _bookings = const [];
  bool _loading = true;
  String? _error;

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
      final bookings = await BookingService.instance.fetchTouristBookings();

      if (!mounted) return;

      setState(() {
        _bookings = bookings;
        _loading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;

      setState(() {
        _error = error.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _error = 'Your bookings could not be loaded.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Bookings',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child:
            _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(24),
                  children: [
                    const SizedBox(height: 120),
                    Icon(
                      Icons.cloud_off_rounded,
                      size: 58,
                      color: colors.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Bookings could not be loaded',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: colors.onSurfaceVariant),
                    ),
                    const SizedBox(height: 18),
                    Center(
                      child: FilledButton.icon(
                        onPressed: _load,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Try Again'),
                      ),
                    ),
                  ],
                )
                : _bookings.isEmpty
                ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(24),
                  children: [
                    const SizedBox(height: 120),
                    Icon(
                      Icons.luggage_outlined,
                      size: 66,
                      color: colors.primary,
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'No bookings yet',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'When you book a published safari or accept a custom safari proposal, it will appear here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: colors.onSurfaceVariant,
                        height: 1.45,
                      ),
                    ),
                  ],
                )
                : ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 32),
                  itemCount: _bookings.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    return _BookingCard(booking: _bookings[index]);
                  },
                ),
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  const _BookingCard({required this.booking});

  final BookingItem booking;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  booking.title.isEmpty ? 'Safari Booking' : booking.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    height: 1.2,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _StatusBadge(status: booking.status),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            booking.reference.isEmpty ? 'Booking' : booking.reference,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          _DetailRow(
            icon: Icons.business_outlined,
            label: 'Provider',
            value:
                booking.provider.name.isEmpty
                    ? booking.providerType
                    : booking.provider.name,
          ),
          if ((booking.startDate ?? '').isNotEmpty)
            _DetailRow(
              icon: Icons.calendar_month_outlined,
              label: 'Travel date',
              value: _dateRange(booking.startDate, booking.endDate),
            ),
          _DetailRow(
            icon: Icons.groups_outlined,
            label: 'Travellers',
            value: '${booking.travellers}',
          ),
          if ((booking.accommodationLevel ?? '').isNotEmpty)
            _DetailRow(
              icon: Icons.hotel_outlined,
              label: 'Accommodation',
              value: _accommodationLabel(booking.accommodationLevel!),
            ),
          _DetailRow(
            icon: Icons.payments_outlined,
            label: 'Total',
            value: '${booking.currency} ${_money(booking.totalAmount)}',
          ),
          _DetailRow(
            icon: Icons.credit_card_outlined,
            label: 'Payment',
            value: _pretty(booking.paymentStatus),
          ),
          if ((booking.touristNotes ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'Your notes',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              booking.touristNotes!.trim(),
              style: TextStyle(color: colors.onSurfaceVariant, height: 1.4),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final isPositive = status == 'confirmed' || status == 'completed';

    final background =
        isPositive
            ? colors.primary.withValues(alpha: 0.10)
            : status == 'cancelled'
            ? colors.error.withValues(alpha: 0.10)
            : colors.secondary.withValues(alpha: 0.12);

    final foreground =
        isPositive
            ? colors.primary
            : status == 'cancelled'
            ? colors.error
            : colors.secondary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        _pretty(status),
        style: TextStyle(
          color: foreground,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: colors.primary),
          const SizedBox(width: 9),
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

String _dateRange(String? start, String? end) {
  final startText = start ?? '';
  final endText = end ?? '';

  if (startText.isEmpty) {
    return 'To be confirmed';
  }

  if (endText.isEmpty || endText == startText) {
    return startText;
  }

  return '$startText – $endText';
}

String _money(double value) {
  return value.toStringAsFixed(value == value.roundToDouble() ? 0 : 2);
}

String _pretty(String value) {
  return value
      .replaceAll('_', ' ')
      .split(' ')
      .map(
        (part) =>
            part.isEmpty ? '' : '${part[0].toUpperCase()}${part.substring(1)}',
      )
      .join(' ');
}

String _accommodationLabel(String value) {
  switch (value) {
    case 'budget':
      return 'Budget Accommodation';
    case 'mid_range':
      return 'Mid-range Accommodation';
    case 'luxury':
      return 'Luxury Accommodation';
    default:
      return _pretty(value);
  }
}
