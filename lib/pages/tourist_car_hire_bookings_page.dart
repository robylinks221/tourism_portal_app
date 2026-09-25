import 'package:flutter/material.dart';

import '../models/car_hire_booking.dart';
import '../services/api_exception.dart';
import '../services/car_hire_booking_service.dart';

class TouristCarHireBookingsPage extends StatefulWidget {
  const TouristCarHireBookingsPage({super.key});

  @override
  State<TouristCarHireBookingsPage> createState() =>
      _TouristCarHireBookingsPageState();
}

class _TouristCarHireBookingsPageState
    extends State<TouristCarHireBookingsPage> {
  static const _primary = Color(0xFF165B5D);
  static const _secondary = Color(0xFFF46627);
  static const _background = Color(0xFFF4EEE1);

  bool _loading = true;
  String? _error;
  List<CarHireBooking> _items = const [];

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
      final items =
          await CarHireBookingService.instance.touristBookings();

      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  Future<void> _cancel(CarHireBooking booking) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Cancel Car Hire?',
          style: TextStyle(
            color: _primary,
            fontWeight: FontWeight.w900,
          ),
        ),
        content: const Text(
          'This will cancel your vehicle hire request.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep Booking'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: _secondary,
              shape: const StadiumBorder(),
            ),
            child: const Text('Cancel Booking'),
          ),
        ],
      ),
    );

    if (yes != true) return;

    try {
      await CarHireBookingService.instance
          .cancelTouristBooking(booking);
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'My Car Hire',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: _primary),
            )
          : _error != null
              ? Center(
                  child: FilledButton(
                    onPressed: _load,
                    child: Text(_error!),
                  ),
                )
              : _items.isEmpty
                  ? const Center(
                      child: Text(
                        'You have no car hire bookings yet.',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(
                          18,
                          8,
                          18,
                          30,
                        ),
                        itemCount: _items.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 12),
                        itemBuilder: (_, index) {
                          final booking = _items[index];

                          return _TouristBookingCard(
                            booking: booking,
                            onCancel: booking.isPending ||
                                    booking.isConfirmed
                                ? () => _cancel(booking)
                                : null,
                          );
                        },
                      ),
                    ),
    );
  }
}

class _TouristBookingCard extends StatelessWidget {
  const _TouristBookingCard({
    required this.booking,
    this.onCancel,
  });

  final CarHireBooking booking;
  final VoidCallback? onCancel;

  static const _primary = Color(0xFF165B5D);
  static const _secondary = Color(0xFFF46627);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final vehicle = booking.vehicle;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _primary.withOpacity(.06),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 160,
            child: Stack(
              fit: StackFit.expand,
              children: [
                vehicle?.imageUrl.isNotEmpty == true
                    ? Image.network(
                        vehicle!.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _placeholder(),
                      )
                    : _placeholder(),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0x00000000),
                        Color(0xBB000000),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 14,
                  right: 14,
                  bottom: 13,
                  child: Text(
                    vehicle?.name ?? 'Safari Vehicle',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 14, 15, 15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _StatusPill(status: booking.status),
                    const Spacer(),
                    Text(
                      booking.reference,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: const Color(0xFF737D79),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 13),
                Text(
                  '${_date(booking.pickupDate)} → ${_date(booking.returnDate)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  booking.pickupLocation,
                  style: const TextStyle(
                    color: Color(0xFF66716E),
                  ),
                ),
                const SizedBox(height: 11),
                Row(
                  children: [
                    Text(
                      '${booking.currency} ${booking.estimatedTotal.toStringAsFixed(0)}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: _primary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const Spacer(),
                    if (onCancel != null)
                      TextButton(
                        onPressed: onCancel,
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            color: _secondary,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                  ],
                ),
                if ((booking.operatorNotes ?? '').trim().isNotEmpty) ...[
                  Divider(
                    color: _primary.withOpacity(.07),
                  ),
                  Text(
                    'Operator note: ${booking.operatorNotes!.trim()}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF66716E),
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: _primary.withOpacity(.08),
      child: const Icon(
        Icons.directions_car_filled_rounded,
        color: _primary,
        size: 44,
      ),
    );
  }

  static String _date(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/'
      '${value.month.toString().padLeft(2, '0')}/'
      '${value.year}';
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF165B5D);
    const accent = Color(0xFFF46627);

    final color = status == 'confirmed'
        ? primary
        : status == 'pending'
            ? accent
            : const Color(0xFF6E7774);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(.09),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 9.5,
          fontWeight: FontWeight.w900,
          letterSpacing: .35,
        ),
      ),
    );
  }
}
