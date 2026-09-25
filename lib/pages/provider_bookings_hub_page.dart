import 'package:flutter/material.dart';

import '../models/car_hire_booking.dart';
import '../services/api_exception.dart';
import '../services/auth_service.dart';
import '../services/booking_service.dart';
import '../services/car_hire_booking_service.dart';
import 'operator_booking_details_page.dart';

class ProviderBookingsHubPage extends StatefulWidget {
  const ProviderBookingsHubPage({
    super.key,
    this.initialSection = 0,
  });

  /// 0 = Safari bookings
  /// 1 = Car Hire
  final int initialSection;

  @override
  State<ProviderBookingsHubPage> createState() =>
      _ProviderBookingsHubPageState();
}

class _ProviderBookingsHubPageState
    extends State<ProviderBookingsHubPage> {
  static const _primary = Color(0xFF165B5D);
  static const _secondary = Color(0xFFF46627);
  static const _background = Color(0xFFF4EEE1);
  static const _ink = Color(0xFF17211F);
  static const _muted = Color(0xFF6F7975);

  late int _section;

  // Tourist Guide sub-sections:
  // Safari:
  //   0 = bookings received as a guide/provider
  //   1 = safaris personally booked by the guide
  //
  // Car Hire:
  //   0 = requests received for the guide's vehicles
  //   1 = vehicles personally hired by the guide
  int _guideSafariMode = 0;
  int _guideCarHireMode = 0;

  String _status = 'all';

  bool _loading = true;
  String? _error;

  List<BookingItem> _incomingSafariBookings = const [];
  List<BookingItem> _outgoingSafariBookings = const [];

  List<CarHireBooking> _incomingCarHire = const [];
  List<CarHireBooking> _outgoingCarHire = const [];

  bool get _isGuide =>
      AuthService.instance.currentUser?.role == 'tourist_guide';

  @override
  void initState() {
    super.initState();
    _section = widget.initialSection.clamp(0, 1);
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      if (_isGuide) {
        final results = await Future.wait<dynamic>([
          BookingService.instance.fetchProviderBookings(),
          BookingService.instance.fetchTouristBookings(),
          CarHireBookingService.instance.operatorBookings(),
          CarHireBookingService.instance.touristBookings(),
        ]);

        if (!mounted) return;

        setState(() {
          _incomingSafariBookings =
              results[0] as List<BookingItem>;
          _outgoingSafariBookings =
              results[1] as List<BookingItem>;
          _incomingCarHire =
              results[2] as List<CarHireBooking>;
          _outgoingCarHire =
              results[3] as List<CarHireBooking>;
          _loading = false;
        });
        return;
      }

      final results = await Future.wait<dynamic>([
        BookingService.instance.fetchProviderBookings(),
        CarHireBookingService.instance.operatorBookings(),
      ]);

      if (!mounted) return;

      setState(() {
        _incomingSafariBookings =
            results[0] as List<BookingItem>;
        _outgoingSafariBookings = const [];
        _incomingCarHire =
            results[1] as List<CarHireBooking>;
        _outgoingCarHire = const [];
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
        _error = 'Bookings could not be loaded.';
        _loading = false;
      });
    }
  }

  void _switchSection(int value) {
    if (_section == value) return;

    setState(() {
      _section = value;
      _status = 'all';
      if (value == 0) {
        _guideCarHireMode = 0;
      } else {
        _guideSafariMode = 0;
      }
    });
  }

  void _switchGuideSafariMode(int value) {
    if (_guideSafariMode == value) return;

    setState(() {
      _guideSafariMode = value;
      _status = 'all';
    });
  }

  void _switchGuideCarHireMode(int value) {
    if (_guideCarHireMode == value) return;

    setState(() {
      _guideCarHireMode = value;
      _status = 'all';
    });
  }

  List<BookingItem> get _activeSafariSource {
    if (_isGuide && _guideSafariMode == 1) {
      return _outgoingSafariBookings;
    }

    return _incomingSafariBookings;
  }

  List<BookingItem> get _filteredSafaris {
    final source = _activeSafariSource;

    if (_status == 'all') return source;

    return source
        .where((booking) => booking.status == _status)
        .toList();
  }

  List<CarHireBooking> get _activeCarHireSource {
    if (_isGuide && _guideCarHireMode == 1) {
      return _outgoingCarHire;
    }
    return _incomingCarHire;
  }

  List<CarHireBooking> get _filteredCarHire {
    final source = _activeCarHireSource;
    if (_status == 'all') return source;
    return source
        .where((booking) => booking.status == _status)
        .toList();
  }

  Future<void> _openSafariBooking(
    BookingItem booking,
  ) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) =>
            OperatorBookingDetailsPage(booking: booking),
      ),
    );

    await _load();
  }

  Future<void> _confirmVehicle(
    CarHireBooking booking,
  ) async {
    final notes = await Navigator.push<String>(
      context,
      MaterialPageRoute<String>(
        builder: (_) => _CarHireDecisionPage(
          booking: booking,
          confirm: true,
        ),
      ),
    );

    if (notes == null) return;

    await _runVehicleAction(
      () => CarHireBookingService.instance.confirm(
        booking,
        operatorNotes: notes,
      ),
      'Car hire booking confirmed.',
    );
  }

  Future<void> _declineVehicle(
    CarHireBooking booking,
  ) async {
    final notes = await Navigator.push<String>(
      context,
      MaterialPageRoute<String>(
        builder: (_) => _CarHireDecisionPage(
          booking: booking,
          confirm: false,
        ),
      ),
    );

    if (notes == null) return;

    await _runVehicleAction(
      () => CarHireBookingService.instance.decline(
        booking,
        operatorNotes: notes,
      ),
      'Car hire request declined.',
    );
  }

  Future<void> _completeVehicle(
    CarHireBooking booking,
  ) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
        ),
        title: const Text(
          'Complete Car Hire?',
          style: TextStyle(
            color: _primary,
            fontWeight: FontWeight.w900,
          ),
        ),
        content: const Text(
          'Mark this booking completed only after the vehicle hire has finished.',
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(dialogContext, false),
            child: const Text('Not Yet'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(
              backgroundColor: _primary,
              shape: const StadiumBorder(),
            ),
            child: const Text('Complete'),
          ),
        ],
      ),
    );

    if (yes != true) return;

    await _runVehicleAction(
      () =>
          CarHireBookingService.instance.complete(booking),
      'Car hire booking completed.',
    );
  }

  Future<void> _cancelMySafariBooking(
    BookingItem booking,
  ) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
        ),
        title: const Text(
          'Cancel Safari Booking?',
          style: TextStyle(
            color: _primary,
            fontWeight: FontWeight.w900,
          ),
        ),
        content: Text(
          booking.title.trim().isEmpty
              ? 'This will cancel your personal safari booking.'
              : 'This will cancel your booking for ${booking.title}.',
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(dialogContext, false),
            child: const Text('Keep Booking'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, true),
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
      await BookingService.instance
          .cancelTouristBooking(booking.id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Safari booking cancelled.'),
          behavior: SnackBarBehavior.floating,
        ),
      );

      await _load();
    } on ApiException catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _cancelMyVehicleHire(
    CarHireBooking booking,
  ) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
        ),
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
            onPressed: () =>
                Navigator.pop(dialogContext, false),
            child: const Text('Keep Booking'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, true),
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

    await _runVehicleAction(
      () => CarHireBookingService.instance
          .cancelTouristBooking(booking),
      'Car hire booking cancelled.',
    );
  }

  Future<void> _runVehicleAction(
    Future<CarHireBooking> Function() action,
    String success,
  ) async {
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
    } on ApiException catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final safariCount =
        _incomingSafariBookings.length +
        (_isGuide ? _outgoingSafariBookings.length : 0);

    final carHireCount =
        _incomingCarHire.length +
        (_isGuide ? _outgoingCarHire.length : 0);

    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding:
                  const EdgeInsets.fromLTRB(18, 14, 18, 0),
              child: _Header(
                isGuide: _isGuide,
                safariCount: safariCount,
                carHireCount: carHireCount,
              ),
            ),

            const SizedBox(height: 14),

            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 18),
              child: _MainTabs(
                selected: _section,
                safariCount: safariCount,
                carHireCount: carHireCount,
                onChanged: _switchSection,
              ),
            ),

            if (_section == 0 && _isGuide) ...[
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                ),
                child: _GuideSafariTabs(
                  selected: _guideSafariMode,
                  receivedCount:
                      _incomingSafariBookings.length,
                  bookedCount:
                      _outgoingSafariBookings.length,
                  onChanged: _switchGuideSafariMode,
                ),
              ),
            ],

            if (_section == 1 && _isGuide) ...[
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                ),
                child: _GuideCarHireTabs(
                  selected: _guideCarHireMode,
                  requestCount: _incomingCarHire.length,
                  hireCount: _outgoingCarHire.length,
                  onChanged: _switchGuideCarHireMode,
                ),
              ),
            ],

            const SizedBox(height: 11),

            _StatusFilters(
              selected: _status,
              onChanged: (value) {
                setState(() => _status = value);
              },
              includeDeclined: _section == 1,
            ),

            const SizedBox(height: 8),

            Expanded(child: _body()),
          ],
        ),
      ),
    );
  }

  Widget _body() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(
          color: _primary,
        ),
      );
    }

    if (_error != null) {
      return _ErrorState(
        message: _error!,
        onRetry: _load,
      );
    }

    if (_section == 0) {
      final bookings = _filteredSafaris;
      final personalSafari =
          _isGuide && _guideSafariMode == 1;

      if (bookings.isEmpty) {
        return _EmptyState(
          icon: Icons.landscape_outlined,
          title: personalSafari
              ? 'No Safaris Booked'
              : 'No Safari Bookings',
          message: personalSafari
              ? 'Safaris you personally book from another provider will appear here.'
              : (_status == 'all'
                  ? 'Traveller safari bookings will appear here.'
                  : 'There are no $_status safari bookings.'),
        );
      }

      return RefreshIndicator(
        onRefresh: _load,
        color: _primary,
        child: ListView.separated(
          physics:
              const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding:
              const EdgeInsets.fromLTRB(18, 8, 18, 34),
          itemCount: bookings.length,
          separatorBuilder: (_, __) =>
              const SizedBox(height: 12),
          itemBuilder: (_, index) {
            final booking = bookings[index];

            return _SafariBookingCard(
              booking: booking,
              personal: personalSafari,
              onTap: personalSafari
                  ? null
                  : () => _openSafariBooking(booking),
              onCancel: personalSafari &&
                      (booking.isPending ||
                          booking.isConfirmed)
                  ? () => _cancelMySafariBooking(booking)
                  : null,
            );
          },
        ),
      );
    }

    final bookings = _filteredCarHire;
    final outgoing =
        _isGuide && _guideCarHireMode == 1;

    if (bookings.isEmpty) {
      return _EmptyState(
        icon: Icons.directions_car_outlined,
        title: outgoing
            ? 'No Vehicles Hired'
            : 'No Car Hire Requests',
        message: outgoing
            ? 'Vehicles you hire from another provider will appear here.'
            : 'Traveller requests for your vehicles will appear here.',
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: _primary,
      child: ListView.separated(
        physics:
            const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding:
            const EdgeInsets.fromLTRB(18, 8, 18, 34),
        itemCount: bookings.length,
        separatorBuilder: (_, __) =>
            const SizedBox(height: 12),
        itemBuilder: (_, index) {
          final booking = bookings[index];

          return _CarHireBookingCard(
            booking: booking,
            outgoing: outgoing,
            onConfirm:
                !outgoing && booking.isPending
                    ? () => _confirmVehicle(booking)
                    : null,
            onDecline:
                !outgoing && booking.isPending
                    ? () => _declineVehicle(booking)
                    : null,
            onComplete:
                !outgoing && booking.isConfirmed
                    ? () => _completeVehicle(booking)
                    : null,
            onCancel:
                outgoing &&
                        (booking.isPending ||
                            booking.isConfirmed)
                    ? () => _cancelMyVehicleHire(
                          booking,
                        )
                    : null,
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.isGuide,
    required this.safariCount,
    required this.carHireCount,
  });

  final bool isGuide;
  final int safariCount;
  final int carHireCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.fromLTRB(17, 17, 17, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color:
              _ProviderBookingsHubPageState._primary
                  .withOpacity(.06),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.05),
            blurRadius: 24,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color:
                  _ProviderBookingsHubPageState
                      ._primary
                      .withOpacity(.08),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.receipt_long_rounded,
              color:
                  _ProviderBookingsHubPageState
                      ._primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Bookings',
                  style:
                      theme.textTheme.titleLarge?.copyWith(
                    color:
                        _ProviderBookingsHubPageState._ink,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -.3,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  isGuide
                      ? 'Safari work and all your car hire activity'
                      : 'Safari and car hire reservations',
                  style:
                      theme.textTheme.bodySmall?.copyWith(
                    color:
                        _ProviderBookingsHubPageState
                            ._muted,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MainTabs extends StatelessWidget {
  const _MainTabs({
    required this.selected,
    required this.safariCount,
    required this.carHireCount,
    required this.onChanged,
  });

  final int selected;
  final int safariCount;
  final int carHireCount;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          Expanded(
            child: _TabButton(
              label: 'Safari',
              count: safariCount,
              selected: selected == 0,
              onTap: () => onChanged(0),
            ),
          ),
          const SizedBox(width: 5),
          Expanded(
            child: _TabButton(
              label: 'Car Hire',
              count: carHireCount,
              selected: selected == 1,
              onTap: () => onChanged(1),
            ),
          ),
        ],
      ),
    );
  }
}

class _GuideSafariTabs extends StatelessWidget {
  const _GuideSafariTabs({
    required this.selected,
    required this.receivedCount,
    required this.bookedCount,
    required this.onChanged,
  });

  final int selected;
  final int receivedCount;
  final int bookedCount;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    const primary =
        _ProviderBookingsHubPageState._primary;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: primary.withOpacity(.055),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SubTabButton(
              label: 'Received',
              count: receivedCount,
              selected: selected == 0,
              onTap: () => onChanged(0),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _SubTabButton(
              label: 'My Safaris',
              count: bookedCount,
              selected: selected == 1,
              onTap: () => onChanged(1),
            ),
          ),
        ],
      ),
    );
  }
}

class _GuideCarHireTabs extends StatelessWidget {
  const _GuideCarHireTabs({
    required this.selected,
    required this.requestCount,
    required this.hireCount,
    required this.onChanged,
  });

  final int selected;
  final int requestCount;
  final int hireCount;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    const primary =
        _ProviderBookingsHubPageState._primary;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: primary.withOpacity(.055),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SubTabButton(
              label: 'Requests to Me',
              count: requestCount,
              selected: selected == 0,
              onTap: () => onChanged(0),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _SubTabButton(
              label: 'My Hires',
              count: hireCount,
              selected: selected == 1,
              onTap: () => onChanged(1),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const primary =
        _ProviderBookingsHubPageState._primary;

    return Material(
      color: selected ? primary : Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: SizedBox(
          height: 45,
          child: Row(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  color:
                      selected ? Colors.white : primary,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 7),
              _CountPill(
                count: count,
                selected: selected,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SubTabButton extends StatelessWidget {
  const _SubTabButton({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const primary =
        _ProviderBookingsHubPageState._primary;

    return Material(
      color: selected ? Colors.white : Colors.transparent,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 9,
            vertical: 10,
          ),
          child: Row(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: primary,
                    fontWeight: selected
                        ? FontWeight.w900
                        : FontWeight.w700,
                    fontSize: 11.5,
                  ),
                ),
              ),
              const SizedBox(width: 5),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: primary.withOpacity(.08),
                  borderRadius:
                      BorderRadius.circular(999),
                ),
                child: Text(
                  '$count',
                  style: const TextStyle(
                    color: primary,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
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

class _CountPill extends StatelessWidget {
  const _CountPill({
    required this.count,
    required this.selected,
  });

  final int count;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    const primary =
        _ProviderBookingsHubPageState._primary;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 7,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: selected
            ? Colors.white.withOpacity(.17)
            : primary.withOpacity(.07),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$count',
        style: TextStyle(
          color: selected ? Colors.white : primary,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _StatusFilters extends StatelessWidget {
  const _StatusFilters({
    required this.selected,
    required this.onChanged,
    required this.includeDeclined,
  });

  final String selected;
  final ValueChanged<String> onChanged;
  final bool includeDeclined;

  @override
  Widget build(BuildContext context) {
    final values = <(String, String)>[
      ('all', 'All'),
      ('pending', 'Pending'),
      ('confirmed', 'Confirmed'),
      if (includeDeclined)
        ('declined', 'Declined'),
      ('completed', 'Completed'),
      ('cancelled', 'Cancelled'),
    ];

    return SizedBox(
      height: 39,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding:
            const EdgeInsets.symmetric(horizontal: 18),
        itemCount: values.length,
        separatorBuilder: (_, __) =>
            const SizedBox(width: 7),
        itemBuilder: (_, index) {
          final item = values[index];
          final active = selected == item.$1;

          return ChoiceChip(
            selected: active,
            showCheckmark: false,
            label: Text(item.$2),
            onSelected: (_) =>
                onChanged(item.$1),
            selectedColor:
                _ProviderBookingsHubPageState._primary,
            backgroundColor: Colors.white,
            side: BorderSide(
              color: active
                  ? _ProviderBookingsHubPageState
                      ._primary
                  : _ProviderBookingsHubPageState
                      ._primary
                      .withOpacity(.07),
            ),
            shape: const StadiumBorder(),
            labelStyle: TextStyle(
              color: active
                  ? Colors.white
                  : _ProviderBookingsHubPageState
                      ._primary,
              fontWeight: FontWeight.w800,
              fontSize: 11.5,
            ),
          );
        },
      ),
    );
  }
}

class _SafariBookingCard extends StatelessWidget {
  const _SafariBookingCard({
    required this.booking,
    required this.personal,
    this.onTap,
    this.onCancel,
  });

  final BookingItem booking;
  final bool personal;
  final VoidCallback? onTap;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final card = Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color:
              _ProviderBookingsHubPageState
                  ._primary
                  .withOpacity(.06),
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
                decoration: BoxDecoration(
                  color:
                      _ProviderBookingsHubPageState
                          ._primary
                          .withOpacity(.07),
                  borderRadius:
                      BorderRadius.circular(14),
                ),
                child: Icon(
                  personal
                      ? Icons.explore_outlined
                      : Icons.landscape_outlined,
                  color:
                      _ProviderBookingsHubPageState
                          ._primary,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      personal
                          ? (booking.provider.name.isEmpty
                              ? booking.providerType
                              : booking.provider.name)
                          : (booking.tourist.name.isEmpty
                              ? 'Traveller'
                              : booking.tourist.name),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color:
                            _ProviderBookingsHubPageState
                                ._ink,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      booking.reference,
                      style: theme.textTheme.labelSmall
                          ?.copyWith(
                        color:
                            _ProviderBookingsHubPageState
                                ._muted,
                      ),
                    ),
                  ],
                ),
              ),
              _StatusPill(
                status: booking.status,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            booking.title.trim().isEmpty
                ? 'Safari Booking'
                : booking.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style:
                theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                '${booking.travellers} traveller${booking.travellers == 1 ? '' : 's'}',
                style:
                    theme.textTheme.bodySmall?.copyWith(
                  color:
                      _ProviderBookingsHubPageState
                          ._muted,
                ),
              ),
              const Spacer(),
              Text(
                '${booking.currency} ${booking.totalAmount.toStringAsFixed(0)}',
                style:
                    theme.textTheme.titleSmall?.copyWith(
                  color:
                      _ProviderBookingsHubPageState
                          ._primary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          if (personal && onCancel != null) ...[
            const SizedBox(height: 10),
            Divider(
              height: 1,
              color:
                  _ProviderBookingsHubPageState
                      ._primary
                      .withOpacity(.06),
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onCancel,
                child: const Text(
                  'Cancel Booking',
                  style: TextStyle(
                    color:
                        _ProviderBookingsHubPageState
                            ._secondary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );

    if (onTap == null) {
      return card;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: card,
      ),
    );
  }
}

class _CarHireBookingCard extends StatelessWidget {
  const _CarHireBookingCard({
    required this.booking,
    required this.outgoing,
    this.onConfirm,
    this.onDecline,
    this.onComplete,
    this.onCancel,
  });

  final CarHireBooking booking;
  final bool outgoing;
  final VoidCallback? onConfirm;
  final VoidCallback? onDecline;
  final VoidCallback? onComplete;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final vehicle = booking.vehicle;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color:
              _ProviderBookingsHubPageState._primary
                  .withOpacity(.06),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  width: 82,
                  height: 72,
                  child:
                      vehicle?.imageUrl.isNotEmpty == true
                          ? Image.network(
                              vehicle!.imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder:
                                  (_, __, ___) =>
                                      _fallback(),
                            )
                          : _fallback(),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      vehicle?.name ??
                          'Safari Vehicle',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme
                          .textTheme.titleMedium
                          ?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      outgoing
                          ? (booking.operator?.name ??
                              'Safari Provider')
                          : (booking.tourist?.name ??
                              'Traveller'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(
                        color:
                            _ProviderBookingsHubPageState
                                ._primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      booking.reference,
                      style: theme.textTheme.labelSmall
                          ?.copyWith(
                        color:
                            _ProviderBookingsHubPageState
                                ._muted,
                      ),
                    ),
                  ],
                ),
              ),
              _StatusPill(status: booking.status),
            ],
          ),
          const SizedBox(height: 12),
          Divider(
            height: 1,
            color:
                _ProviderBookingsHubPageState._primary
                    .withOpacity(.06),
          ),
          const SizedBox(height: 10),
          Text(
            '${_date(booking.pickupDate)} → ${_date(booking.returnDate)}',
            style: const TextStyle(
              color:
                  _ProviderBookingsHubPageState._ink,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            booking.pickupLocation,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color:
                  _ProviderBookingsHubPageState._muted,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                '${booking.currency} ${booking.estimatedTotal.toStringAsFixed(0)}',
                style:
                    theme.textTheme.titleMedium?.copyWith(
                  color:
                      _ProviderBookingsHubPageState
                          ._primary,
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
                      color:
                          _ProviderBookingsHubPageState
                              ._secondary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              if (onDecline != null)
                TextButton(
                  onPressed: onDecline,
                  child: const Text(
                    'Decline',
                    style: TextStyle(
                      color:
                          _ProviderBookingsHubPageState
                              ._secondary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              if (onConfirm != null)
                FilledButton(
                  onPressed: onConfirm,
                  style: FilledButton.styleFrom(
                    backgroundColor:
                        _ProviderBookingsHubPageState
                            ._primary,
                    shape: const StadiumBorder(),
                  ),
                  child: const Text('Confirm'),
                ),
              if (onComplete != null)
                FilledButton(
                  onPressed: onComplete,
                  style: FilledButton.styleFrom(
                    backgroundColor:
                        _ProviderBookingsHubPageState
                            ._primary,
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

  Widget _fallback() {
    return Container(
      color:
          _ProviderBookingsHubPageState._primary
              .withOpacity(.07),
      child: const Icon(
        Icons.directions_car_filled_rounded,
        color:
            _ProviderBookingsHubPageState._primary,
      ),
    );
  }

  static String _date(DateTime value) {
    return '${value.day.toString().padLeft(2, '0')}/'
        '${value.month.toString().padLeft(2, '0')}/'
        '${value.year}';
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.status,
  });

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'confirmed' =>
        _ProviderBookingsHubPageState._primary,
      'pending' =>
        _ProviderBookingsHubPageState._secondary,
      'completed' => const Color(0xFF2B7A61),
      'declined' => const Color(0xFF9B4C39),
      'cancelled' => const Color(0xFF777777),
      _ => const Color(0xFF777777),
    };

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
          fontSize: 9,
          fontWeight: FontWeight.w900,
          letterSpacing: .35,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color:
                    _ProviderBookingsHubPageState
                        ._primary
                        .withOpacity(.07),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color:
                    _ProviderBookingsHubPageState
                        ._primary,
                size: 30,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(
                color:
                    _ProviderBookingsHubPageState._muted,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                backgroundColor:
                    _ProviderBookingsHubPageState
                        ._primary,
                shape: const StadiumBorder(),
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CarHireDecisionPage extends StatefulWidget {
  const _CarHireDecisionPage({
    required this.booking,
    required this.confirm,
  });

  final CarHireBooking booking;
  final bool confirm;

  @override
  State<_CarHireDecisionPage> createState() =>
      _CarHireDecisionPageState();
}

class _CarHireDecisionPageState
    extends State<_CarHireDecisionPage> {
  late final TextEditingController _notes;

  @override
  void initState() {
    super.initState();
    _notes = TextEditingController();
  }

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          _ProviderBookingsHubPageState._background,
      appBar: AppBar(
        backgroundColor:
            _ProviderBookingsHubPageState._background,
        surfaceTintColor: Colors.transparent,
        title: Text(
          widget.confirm
              ? 'Confirm Car Hire'
              : 'Decline Request',
          style: const TextStyle(
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: ListView(
        padding:
            const EdgeInsets.fromLTRB(18, 8, 18, 110),
        children: [
          Container(
            padding: const EdgeInsets.all(17),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  widget.booking.vehicle?.name ??
                      'Safari Vehicle',
                  style: const TextStyle(
                    color:
                        _ProviderBookingsHubPageState
                            ._primary,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.booking.reference,
                  style: const TextStyle(
                    color:
                        _ProviderBookingsHubPageState
                            ._muted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text(
            widget.confirm
                ? 'Message to Traveller'
                : 'Reason for Declining',
            style: const TextStyle(
              color:
                  _ProviderBookingsHubPageState._primary,
              fontWeight: FontWeight.w900,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 9),
          TextField(
            controller: _notes,
            minLines: 4,
            maxLines: 7,
            decoration: InputDecoration(
              hintText: widget.confirm
                  ? 'Optional pickup instructions or notes...'
                  : 'Optional reason...',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        minimum:
            const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: SizedBox(
          height: 54,
          child: FilledButton(
            onPressed: () => Navigator.pop(
              context,
              _notes.text.trim(),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: widget.confirm
                  ? _ProviderBookingsHubPageState
                      ._primary
                  : _ProviderBookingsHubPageState
                      ._secondary,
              shape: const StadiumBorder(),
            ),
            child: Text(
              widget.confirm
                  ? 'Confirm Booking'
                  : 'Decline Request',
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
