import 'package:flutter/material.dart';

import '../models/car_hire_booking.dart';
import '../services/api_exception.dart';
import '../services/car_hire_booking_service.dart';

class OperatorCarHireBookingsPage extends StatefulWidget {
  const OperatorCarHireBookingsPage({super.key});

  @override
  State<OperatorCarHireBookingsPage> createState() =>
      _OperatorCarHireBookingsPageState();
}

class _OperatorCarHireBookingsPageState
    extends State<OperatorCarHireBookingsPage> {
  static const _primary = Color(0xFF165B5D);
  static const _secondary = Color(0xFFF46627);
  static const _background = Color(0xFFF4EEE1);

  final _statuses = const [
    ('pending', 'Pending'),
    ('confirmed', 'Confirmed'),
    ('declined', 'Declined'),
    ('completed', 'Completed'),
  ];

  String _status = 'pending';
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
          await CarHireBookingService.instance.operatorBookings(
        status: _status,
      );

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
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _error = 'Car hire requests could not be loaded.';
        _loading = false;
      });
    }
  }

  Future<void> _changeStatus(String value) async {
    if (_status == value) return;
    setState(() => _status = value);
    await _load();
  }

  Future<void> _confirm(CarHireBooking booking) async {
    final notes = await Navigator.push<String>(
      context,
      MaterialPageRoute<String>(
        builder: (_) => _CarHireBookingDecisionPage(
          booking: booking,
          mode: _CarHireDecisionMode.confirm,
        ),
      ),
    );

    if (notes == null) return;

    await _runAction(
      () => CarHireBookingService.instance.confirm(
        booking,
        operatorNotes: notes,
      ),
      success: 'Booking confirmed.',
    );
  }

  Future<void> _decline(CarHireBooking booking) async {
    final notes = await Navigator.push<String>(
      context,
      MaterialPageRoute<String>(
        builder: (_) => _CarHireBookingDecisionPage(
          booking: booking,
          mode: _CarHireDecisionMode.decline,
        ),
      ),
    );

    if (notes == null) return;

    await _runAction(
      () => CarHireBookingService.instance.decline(
        booking,
        operatorNotes: notes,
      ),
      success: 'Booking declined.',
    );
  }

  Future<void> _complete(CarHireBooking booking) async {
    await _runAction(
      () => CarHireBookingService.instance.complete(booking),
      success: 'Booking completed.',
    );
  }

  Future<void> _runAction(
    Future<CarHireBooking> Function() action, {
    required String success,
  }) async {
    try {
      await action();
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success),
          behavior: SnackBarBehavior.floating,
        ),
      );

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
          'Car Hire Requests',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 48,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              scrollDirection: Axis.horizontal,
              itemCount: _statuses.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final item = _statuses[index];
                final selected = item.$1 == _status;

                return ChoiceChip(
                  selected: selected,
                  label: Text(item.$2),
                  onSelected: (_) => _changeStatus(item.$1),
                  selectedColor: _primary,
                  backgroundColor: Colors.white,
                  side: BorderSide(
                    color: selected
                        ? _primary
                        : _primary.withOpacity(.08),
                  ),
                  shape: const StadiumBorder(),
                  labelStyle: TextStyle(
                    color:
                        selected ? Colors.white : _primary,
                    fontWeight: FontWeight.w800,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Expanded(child: _body()),
        ],
      ),
    );
  }

  Widget _body() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: _primary),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _error!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _load,
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    if (_items.isEmpty) {
      return Center(
        child: Text(
          'No ${_statuses.firstWhere((e) => e.$1 == _status).$2.toLowerCase()} car hire requests.',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 30),
        itemCount: _items.length,
        separatorBuilder: (_, __) =>
            const SizedBox(height: 12),
        itemBuilder: (_, index) =>
            _OperatorBookingCard(
          booking: _items[index],
          onConfirm: _items[index].isPending
              ? () => _confirm(_items[index])
              : null,
          onDecline: _items[index].isPending
              ? () => _decline(_items[index])
              : null,
          onComplete: _items[index].isConfirmed
              ? () => _complete(_items[index])
              : null,
        ),
      ),
    );
  }
}


enum _CarHireDecisionMode {
  confirm,
  decline,
}

class _CarHireBookingDecisionPage extends StatefulWidget {
  const _CarHireBookingDecisionPage({
    required this.booking,
    required this.mode,
  });

  final CarHireBooking booking;
  final _CarHireDecisionMode mode;

  @override
  State<_CarHireBookingDecisionPage> createState() =>
      _CarHireBookingDecisionPageState();
}

class _CarHireBookingDecisionPageState
    extends State<_CarHireBookingDecisionPage> {
  static const _primary = Color(0xFF165B5D);
  static const _secondary = Color(0xFFF46627);
  static const _background = Color(0xFFF4EEE1);

  late final TextEditingController _notesController;

  bool get _isConfirm =>
      widget.mode == _CarHireDecisionMode.confirm;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;
    final vehicle = booking.vehicle;

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        surfaceTintColor: Colors.transparent,
        title: Text(
          _isConfirm ? 'Confirm Booking' : 'Decline Request',
          style: const TextStyle(
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 120),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: _primary.withOpacity(.06),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: _primary.withOpacity(.07),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: vehicle?.imageUrl.isNotEmpty == true
                      ? Image.network(
                          vehicle!.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const Icon(
                            Icons.directions_car_filled_rounded,
                            color: _primary,
                          ),
                        )
                      : const Icon(
                          Icons.directions_car_filled_rounded,
                          color: _primary,
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        vehicle?.name ?? 'Safari Vehicle',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        booking.reference,
                        style: const TextStyle(
                          color: Color(0xFF737D79),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          _DecisionFact(
            label: 'Tourist',
            value: booking.tourist?.name ?? 'Traveller',
          ),
          _DecisionFact(
            label: 'Dates',
            value:
                '${_decisionDate(booking.pickupDate)} → ${_decisionDate(booking.returnDate)}',
          ),
          _DecisionFact(
            label: 'Pickup',
            value: booking.pickupLocation,
          ),
          _DecisionFact(
            label: 'Passengers',
            value:
                '${booking.passengers} • ${booking.hireTypeLabel}',
          ),
          _DecisionFact(
            label: 'Estimated total',
            value:
                '${booking.currency} ${booking.estimatedTotal.toStringAsFixed(0)}',
            last: true,
          ),

          const SizedBox(height: 22),

          Text(
            _isConfirm
                ? 'Message to Tourist'
                : 'Reason for Declining',
            style: const TextStyle(
              color: _primary,
              fontWeight: FontWeight.w900,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _isConfirm
                ? 'Optional. Add pickup instructions or anything the tourist should know.'
                : 'Optional, but a short explanation is helpful to the tourist.',
            style: const TextStyle(
              color: Color(0xFF66716E),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _notesController,
            minLines: 4,
            maxLines: 7,
            decoration: InputDecoration(
              hintText: _isConfirm
                  ? 'e.g. Vehicle is available. We will meet you at the airport...'
                  : 'e.g. Vehicle is already committed for these dates...',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide(
                  color: _primary.withOpacity(.08),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: const BorderSide(
                  color: _primary,
                  width: 1.2,
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: SizedBox(
          height: 54,
          child: FilledButton(
            onPressed: () {
              Navigator.pop(
                context,
                _notesController.text.trim(),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor:
                  _isConfirm ? _primary : _secondary,
              foregroundColor: Colors.white,
              shape: const StadiumBorder(),
            ),
            child: Text(
              _isConfirm
                  ? 'Confirm This Booking'
                  : 'Decline This Request',
              style: const TextStyle(
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DecisionFact extends StatelessWidget {
  const _DecisionFact({
    required this.label,
    required this.value,
    this.last = false,
  });

  final String label;
  final String value;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 13,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: last
              ? BorderSide.none
              : BorderSide(
                  color:
                      const Color(0xFF165B5D).withOpacity(.06),
                ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 105,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF737D79),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Color(0xFF17211F),
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _decisionDate(DateTime value) {
  return '${value.day.toString().padLeft(2, '0')}/'
      '${value.month.toString().padLeft(2, '0')}/'
      '${value.year}';
}

class _OperatorBookingCard extends StatelessWidget {
  const _OperatorBookingCard({
    required this.booking,
    this.onConfirm,
    this.onDecline,
    this.onComplete,
  });

  final CarHireBooking booking;
  final VoidCallback? onConfirm;
  final VoidCallback? onDecline;
  final VoidCallback? onComplete;

  static const _primary = Color(0xFF165B5D);
  static const _secondary = Color(0xFFF46627);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final vehicle = booking.vehicle;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _primary.withOpacity(.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  width: 92,
                  height: 78,
                  child: vehicle?.imageUrl.isNotEmpty == true
                      ? Image.network(
                          vehicle!.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _vehiclePlaceholder(),
                        )
                      : _vehiclePlaceholder(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      vehicle?.name ?? 'Safari Vehicle',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      booking.tourist?.name ?? 'Tourist',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(
                        color: _primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      booking.reference,
                      style: theme.textTheme.labelSmall
                          ?.copyWith(
                        color: const Color(0xFF737D79),
                      ),
                    ),
                  ],
                ),
              ),
              _StatusPill(status: booking.status),
            ],
          ),
          const SizedBox(height: 14),
          Divider(
            height: 1,
            color: _primary.withOpacity(.07),
          ),
          const SizedBox(height: 12),
          _line(
            Icons.calendar_today_outlined,
            '${_date(booking.pickupDate)} → ${_date(booking.returnDate)}',
          ),
          const SizedBox(height: 8),
          _line(
            Icons.location_on_outlined,
            booking.pickupLocation,
          ),
          const SizedBox(height: 8),
          _line(
            Icons.people_alt_outlined,
            '${booking.passengers} passengers • ${booking.hireTypeLabel}',
          ),
          const SizedBox(height: 12),
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
              if (onDecline != null)
                TextButton(
                  onPressed: onDecline,
                  child: const Text(
                    'Decline',
                    style: TextStyle(
                      color: _secondary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              if (onConfirm != null)
                FilledButton(
                  onPressed: onConfirm,
                  style: FilledButton.styleFrom(
                    backgroundColor: _primary,
                    shape: const StadiumBorder(),
                  ),
                  child: const Text('Confirm'),
                ),
              if (onComplete != null)
                FilledButton(
                  onPressed: onComplete,
                  style: FilledButton.styleFrom(
                    backgroundColor: _primary,
                    shape: const StadiumBorder(),
                  ),
                  child: const Text('Complete'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _line(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 17, color: _primary),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _vehiclePlaceholder() {
    return Container(
      color: _primary.withOpacity(.07),
      child: const Icon(
        Icons.directions_car_filled_rounded,
        color: _primary,
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

    final isPending = status == 'pending';
    final isConfirmed = status == 'confirmed';
    final color = isConfirmed
        ? primary
        : isPending
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
