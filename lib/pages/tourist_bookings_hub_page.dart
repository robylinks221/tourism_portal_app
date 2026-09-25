import 'package:flutter/material.dart';

import '../models/car_hire_booking.dart';
import '../services/api_exception.dart';
import '../services/booking_service.dart';
import '../services/car_hire_booking_service.dart';

class TouristBookingsHubPage extends StatefulWidget {
  const TouristBookingsHubPage({
    super.key,
    this.initialSection = 0,
    this.carHireOnly = false,
  });

  /// 0 = Safari bookings
  /// 1 = Car hire bookings
  final int initialSection;

  /// Use this for Tourist Guides viewing vehicles they hired from
  /// another provider. It prevents the page from calling the normal
  /// tourist Safari booking endpoint, which is intentionally tourist-only.
  final bool carHireOnly;

  @override
  State<TouristBookingsHubPage> createState() =>
      _TouristBookingsHubPageState();
}

class _TouristBookingsHubPageState
    extends State<TouristBookingsHubPage> {
  static const _primary = Color(0xFF165B5D);
  static const _secondary = Color(0xFFF46627);
  static const _background = Color(0xFFF4EEE1);
  static const _ink = Color(0xFF17211F);
  static const _muted = Color(0xFF6F7975);

  late int _section;
  String _status = 'all';

  bool _loading = true;
  String? _error;

  List<BookingItem> _safariBookings = const [];
  List<CarHireBooking> _carHireBookings = const [];

  @override
  void initState() {
    super.initState();
    _section = widget.carHireOnly
        ? 1
        : widget.initialSection.clamp(0, 1);
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      if (widget.carHireOnly) {
        final carHire =
            await CarHireBookingService.instance.touristBookings();

        if (!mounted) return;

        setState(() {
          _safariBookings = const [];
          _carHireBookings = carHire;
          _section = 1;
          _loading = false;
        });
        return;
      }

      final results = await Future.wait<dynamic>([
        BookingService.instance.fetchTouristBookings(),
        CarHireBookingService.instance.touristBookings(),
      ]);

      if (!mounted) return;

      setState(() {
        _safariBookings = results[0] as List<BookingItem>;
        _carHireBookings =
            results[1] as List<CarHireBooking>;
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

  void _switchSection(int value) {
    if (_section == value) return;

    setState(() {
      _section = value;
      _status = 'all';
    });
  }

  List<BookingItem> get _filteredSafaris {
    if (_status == 'all') return _safariBookings;

    return _safariBookings
        .where((booking) => booking.status == _status)
        .toList();
  }

  List<CarHireBooking> get _filteredCarHire {
    if (_status == 'all') return _carHireBookings;

    return _carHireBookings
        .where((booking) => booking.status == _status)
        .toList();
  }

  Future<void> _cancelSafari(
    BookingItem booking,
  ) async {
    final confirmed = await _confirmCancellation(
      title: 'Cancel Safari Booking?',
      message:
          'This will send a cancellation for ${booking.title.isEmpty ? 'this safari' : booking.title}.',
    );

    if (!confirmed) return;

    try {
      await BookingService.instance
          .cancelTouristBooking(booking.id);

      if (!mounted) return;

      _message('Safari booking cancelled.');
      await _load();
    } on ApiException catch (error) {
      if (mounted) _message(error.message);
    }
  }

  Future<void> _cancelCarHire(
    CarHireBooking booking,
  ) async {
    final confirmed = await _confirmCancellation(
      title: 'Cancel Car Hire?',
      message:
          'This will cancel your vehicle hire request ${booking.reference}.',
    );

    if (!confirmed) return;

    try {
      await CarHireBookingService.instance
          .cancelTouristBooking(booking);

      if (!mounted) return;

      _message('Car hire booking cancelled.');
      await _load();
    } on ApiException catch (error) {
      if (mounted) _message(error.message);
    }
  }

  Future<bool> _confirmCancellation({
    required String title,
    required String message,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(26),
              ),
              title: Text(
                title,
                style: const TextStyle(
                  color: _primary,
                  fontWeight: FontWeight.w900,
                ),
              ),
              content: Text(message),
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
                    foregroundColor: Colors.white,
                    shape: const StadiumBorder(),
                  ),
                  child: const Text('Cancel Booking'),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  void _message(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _openSafariDetails(
    BookingItem booking,
  ) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => _TouristSafariBookingDetailsPage(
          booking: booking,
          onCancel:
              booking.isPending || booking.isConfirmed
                  ? () => _cancelSafari(booking)
                  : null,
        ),
      ),
    );

    await _load();
  }

  Future<void> _openCarHireDetails(
    CarHireBooking booking,
  ) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => _TouristCarHireBookingDetailsPage(
          booking: booking,
          onCancel:
              booking.isPending || booking.isConfirmed
                  ? () => _cancelCarHire(booking)
                  : null,
        ),
      ),
    );

    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding:
                  const EdgeInsets.fromLTRB(18, 14, 18, 0),
              child: _BookingHeader(
                safariCount: _safariBookings.length,
                carHireCount: _carHireBookings.length,
                carHireOnly: widget.carHireOnly,
              ),
            ),

            const SizedBox(height: 14),

            if (!widget.carHireOnly) ...[
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18),
                child: _BookingTypeSwitcher(
                  selected: _section,
                  safariCount: _safariBookings.length,
                  carHireCount: _carHireBookings.length,
                  onChanged: _switchSection,
                ),
              ),
              const SizedBox(height: 11),
            ],

            _StatusFilters(
              selected: _status,
              includeDeclined: _section == 1,
              onChanged: (value) {
                setState(() => _status = value);
              },
            ),

            const SizedBox(height: 8),

            Expanded(child: _content()),
          ],
        ),
      ),
    );
  }

  Widget _content() {
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

      if (bookings.isEmpty) {
        return _EmptyState(
          icon: Icons.landscape_outlined,
          title: 'No Safari Bookings',
          message: _status == 'all'
              ? 'When you book a published safari or accept a custom safari proposal, it will appear here.'
              : 'You have no $_status safari bookings.',
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
              onTap: () =>
                  _openSafariDetails(booking),
            );
          },
        ),
      );
    }

    final bookings = _filteredCarHire;

    if (bookings.isEmpty) {
      return _EmptyState(
        icon: Icons.directions_car_outlined,
        title: 'No Car Hire Bookings',
        message: _status == 'all'
            ? 'Your vehicle hire requests and confirmed car bookings will appear here.'
            : 'You have no $_status car hire bookings.',
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
            onTap: () =>
                _openCarHireDetails(booking),
          );
        },
      ),
    );
  }
}

class _BookingHeader extends StatelessWidget {
  const _BookingHeader({
    required this.safariCount,
    required this.carHireCount,
    required this.carHireOnly,
  });

  final int safariCount;
  final int carHireCount;
  final bool carHireOnly;

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
          color: _TouristBookingsHubPageState._primary
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
          Material(
            color: _TouristBookingsHubPageState
                ._primary
                .withOpacity(.07),
            shape: const CircleBorder(),
            child: IconButton(
              onPressed: () =>
                  Navigator.maybePop(context),
              icon: const Icon(
                Icons.arrow_back_rounded,
                color:
                    _TouristBookingsHubPageState
                        ._primary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  carHireOnly ? 'My Car Hire' : 'My Bookings',
                  style:
                      theme.textTheme.titleLarge?.copyWith(
                    color:
                        _TouristBookingsHubPageState._ink,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -.3,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  carHireOnly
                      ? '$carHireCount vehicle booking${carHireCount == 1 ? '' : 's'}'
                      : '$safariCount safari • $carHireCount car hire',
                  style:
                      theme.textTheme.bodySmall?.copyWith(
                    color:
                        _TouristBookingsHubPageState
                            ._muted,
                    fontWeight: FontWeight.w700,
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

class _BookingTypeSwitcher extends StatelessWidget {
  const _BookingTypeSwitcher({
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
        border: Border.all(
          color: _TouristBookingsHubPageState._primary
              .withOpacity(.06),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _BookingTypeButton(
              title: 'Safaris',
              count: safariCount,
              selected: selected == 0,
              onTap: () => onChanged(0),
            ),
          ),
          const SizedBox(width: 5),
          Expanded(
            child: _BookingTypeButton(
              title: 'Car Hire',
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

class _BookingTypeButton extends StatelessWidget {
  const _BookingTypeButton({
    required this.title,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const primary =
        _TouristBookingsHubPageState._primary;

    return Material(
      color: selected ? primary : Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: SizedBox(
          height: 46,
          child: Row(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: TextStyle(
                  color:
                      selected ? Colors.white : primary,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 7),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 7,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: selected
                      ? Colors.white.withOpacity(.17)
                      : primary.withOpacity(.07),
                  borderRadius:
                      BorderRadius.circular(999),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    color:
                        selected ? Colors.white : primary,
                    fontSize: 10,
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

class _StatusFilters extends StatelessWidget {
  const _StatusFilters({
    required this.selected,
    required this.includeDeclined,
    required this.onChanged,
  });

  final String selected;
  final bool includeDeclined;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final filters = <(String, String)>[
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
        itemCount: filters.length,
        separatorBuilder: (_, __) =>
            const SizedBox(width: 7),
        itemBuilder: (_, index) {
          final filter = filters[index];
          final active =
              selected == filter.$1;

          return ChoiceChip(
            selected: active,
            showCheckmark: false,
            label: Text(filter.$2),
            onSelected: (_) =>
                onChanged(filter.$1),
            selectedColor:
                _TouristBookingsHubPageState._primary,
            backgroundColor: Colors.white,
            side: BorderSide(
              color: active
                  ? _TouristBookingsHubPageState
                      ._primary
                  : _TouristBookingsHubPageState
                      ._primary
                      .withOpacity(.07),
            ),
            shape: const StadiumBorder(),
            labelStyle: TextStyle(
              color: active
                  ? Colors.white
                  : _TouristBookingsHubPageState
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
    required this.onTap,
  });

  final BookingItem booking;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: _TouristBookingsHubPageState
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
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color:
                          _TouristBookingsHubPageState
                              ._primary
                              .withOpacity(.07),
                      borderRadius:
                          BorderRadius.circular(15),
                    ),
                    child: const Icon(
                      Icons.landscape_outlined,
                      color:
                          _TouristBookingsHubPageState
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
                          booking.title.isEmpty
                              ? 'Safari Booking'
                              : booking.title,
                          maxLines: 2,
                          overflow:
                              TextOverflow.ellipsis,
                          style: theme
                              .textTheme.titleMedium
                              ?.copyWith(
                            color:
                                _TouristBookingsHubPageState
                                    ._ink,
                            fontWeight: FontWeight.w900,
                            height: 1.12,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          booking.provider.name.isEmpty
                              ? booking.providerType
                              : booking.provider.name,
                          maxLines: 1,
                          overflow:
                              TextOverflow.ellipsis,
                          style: theme
                              .textTheme.bodySmall
                              ?.copyWith(
                            color:
                                _TouristBookingsHubPageState
                                    ._muted,
                            fontWeight: FontWeight.w700,
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
              const SizedBox(height: 13),
              Divider(
                height: 1,
                color: _TouristBookingsHubPageState
                    ._primary
                    .withOpacity(.06),
              ),
              const SizedBox(height: 11),
              _FactLine(
                icon:
                    Icons.calendar_month_outlined,
                text: _safariDateRange(
                  booking.startDate,
                  booking.endDate,
                ),
              ),
              const SizedBox(height: 7),
              _FactLine(
                icon: Icons.people_alt_outlined,
                text:
                    '${booking.travellers} traveller${booking.travellers == 1 ? '' : 's'}',
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    '${booking.currency} ${_money(booking.totalAmount)}',
                    style: theme
                        .textTheme.titleMedium
                        ?.copyWith(
                      color:
                          _TouristBookingsHubPageState
                              ._primary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    booking.reference,
                    style: theme
                        .textTheme.labelSmall
                        ?.copyWith(
                      color:
                          _TouristBookingsHubPageState
                              ._muted,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color:
                        _TouristBookingsHubPageState
                            ._primary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CarHireBookingCard extends StatelessWidget {
  const _CarHireBookingCard({
    required this.booking,
    required this.onTap,
  });

  final CarHireBooking booking;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final vehicle = booking.vehicle;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: _TouristBookingsHubPageState
                  ._primary
                  .withOpacity(.06),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 142,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    vehicle?.imageUrl.isNotEmpty ==
                            true
                        ? Image.network(
                            vehicle!.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder:
                                (_, __, ___) =>
                                    _vehicleFallback(),
                          )
                        : _vehicleFallback(),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0x00000000),
                            Color(0xC9000000),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 14,
                      right: 14,
                      bottom: 12,
                      child: Row(
                        crossAxisAlignment:
                            CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Text(
                              vehicle?.name ??
                                  'Safari Vehicle',
                              maxLines: 2,
                              overflow:
                                  TextOverflow.ellipsis,
                              style: theme
                                  .textTheme.titleMedium
                                  ?.copyWith(
                                color: Colors.white,
                                fontWeight:
                                    FontWeight.w900,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          _StatusPill(
                            status: booking.status,
                            onDark: true,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(
                  14,
                  13,
                  14,
                  14,
                ),
                child: Column(
                  children: [
                    _FactLine(
                      icon:
                          Icons.calendar_month_outlined,
                      text:
                          '${_date(booking.pickupDate)} → ${_date(booking.returnDate)}',
                    ),
                    const SizedBox(height: 7),
                    _FactLine(
                      icon: Icons.location_on_outlined,
                      text: booking.pickupLocation,
                    ),
                    const SizedBox(height: 7),
                    _FactLine(
                      icon: Icons.people_alt_outlined,
                      text:
                          '${booking.passengers} passenger${booking.passengers == 1 ? '' : 's'} • ${booking.hireTypeLabel}',
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text(
                          '${booking.currency} ${_money(booking.estimatedTotal)}',
                          style: theme
                              .textTheme.titleMedium
                              ?.copyWith(
                            color:
                                _TouristBookingsHubPageState
                                    ._primary,
                            fontWeight:
                                FontWeight.w900,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          booking.reference,
                          style: theme
                              .textTheme.labelSmall
                              ?.copyWith(
                            color:
                                _TouristBookingsHubPageState
                                    ._muted,
                          ),
                        ),
                        const SizedBox(width: 5),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color:
                              _TouristBookingsHubPageState
                                  ._primary,
                        ),
                      ],
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

  Widget _vehicleFallback() {
    return Container(
      color: _TouristBookingsHubPageState
          ._primary
          .withOpacity(.08),
      child: const Icon(
        Icons.directions_car_filled_rounded,
        color:
            _TouristBookingsHubPageState._primary,
        size: 42,
      ),
    );
  }
}

class _TouristSafariBookingDetailsPage
    extends StatelessWidget {
  const _TouristSafariBookingDetailsPage({
    required this.booking,
    this.onCancel,
  });

  final BookingItem booking;
  final Future<void> Function()? onCancel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          _TouristBookingsHubPageState._background,
      appBar: AppBar(
        backgroundColor:
            _TouristBookingsHubPageState._background,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Safari Booking',
          style: TextStyle(
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: ListView(
        padding:
            const EdgeInsets.fromLTRB(18, 8, 18, 110),
        children: [
          _DetailsHero(
            title: booking.title.isEmpty
                ? 'Safari Booking'
                : booking.title,
            reference: booking.reference,
            status: booking.status,
            amount:
                '${booking.currency} ${_money(booking.totalAmount)}',
          ),
          const SizedBox(height: 14),
          _DetailsCard(
            title: 'Trip Details',
            children: [
              _DetailsRow(
                label: 'Provider',
                value: booking.provider.name.isEmpty
                    ? booking.providerType
                    : booking.provider.name,
              ),
              _DetailsRow(
                label: 'Travel dates',
                value: _safariDateRange(
                  booking.startDate,
                  booking.endDate,
                ),
              ),
              _DetailsRow(
                label: 'Travellers',
                value: '${booking.travellers}',
              ),
              if ((booking.accommodationLevel ?? '')
                  .isNotEmpty)
                _DetailsRow(
                  label: 'Accommodation',
                  value: _pretty(
                    booking.accommodationLevel!,
                  ),
                ),
              _DetailsRow(
                label: 'Payment',
                value:
                    _pretty(booking.paymentStatus),
                last: true,
              ),
            ],
          ),
          if ((booking.providerNotes ?? '')
              .trim()
              .isNotEmpty) ...[
            const SizedBox(height: 14),
            _NoteCard(
              title: 'Provider Note',
              text: booking.providerNotes!.trim(),
            ),
          ],
          if ((booking.touristNotes ?? '')
              .trim()
              .isNotEmpty) ...[
            const SizedBox(height: 14),
            _NoteCard(
              title: 'Your Note',
              text: booking.touristNotes!.trim(),
            ),
          ],
        ],
      ),
      bottomNavigationBar: onCancel == null
          ? null
          : SafeArea(
              top: false,
              minimum: const EdgeInsets.fromLTRB(
                16,
                8,
                16,
                12,
              ),
              child: SizedBox(
                height: 52,
                child: OutlinedButton(
                  onPressed: () async {
                    await onCancel!();

                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor:
                        _TouristBookingsHubPageState
                            ._secondary,
                    side: const BorderSide(
                      color:
                          _TouristBookingsHubPageState
                              ._secondary,
                    ),
                    shape: const StadiumBorder(),
                  ),
                  child: const Text(
                    'Cancel Booking',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

class _TouristCarHireBookingDetailsPage
    extends StatelessWidget {
  const _TouristCarHireBookingDetailsPage({
    required this.booking,
    this.onCancel,
  });

  final CarHireBooking booking;
  final Future<void> Function()? onCancel;

  @override
  Widget build(BuildContext context) {
    final vehicle = booking.vehicle;

    return Scaffold(
      backgroundColor:
          _TouristBookingsHubPageState._background,
      appBar: AppBar(
        backgroundColor:
            _TouristBookingsHubPageState._background,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Car Hire Booking',
          style: TextStyle(
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: ListView(
        padding:
            const EdgeInsets.fromLTRB(18, 8, 18, 110),
        children: [
          Container(
            height: 210,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              color: _TouristBookingsHubPageState
                  ._primary
                  .withOpacity(.08),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                vehicle?.imageUrl.isNotEmpty == true
                    ? Image.network(
                        vehicle!.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (_, __, ___) =>
                                _vehicleDetailsFallback(),
                      )
                    : _vehicleDetailsFallback(),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0x10000000),
                        Color(0xD9000000),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 15,
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      _StatusPill(
                        status: booking.status,
                        onDark: true,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        vehicle?.name ??
                            'Safari Vehicle',
                        maxLines: 2,
                        overflow:
                            TextOverflow.ellipsis,
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(
                          color: Colors.white,
                          fontWeight:
                              FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        booking.reference,
                        style: TextStyle(
                          color:
                              Colors.white.withOpacity(.72),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _DetailsCard(
            title: 'Hire Details',
            children: [
              _DetailsRow(
                label: 'Provider',
                value: booking.operator?.name ??
                    'Safari Provider',
              ),
              _DetailsRow(
                label: 'Pickup',
                value: booking.pickupLocation,
              ),
              if ((booking.dropoffLocation ?? '')
                  .isNotEmpty)
                _DetailsRow(
                  label: 'Drop-off',
                  value: booking.dropoffLocation!,
                ),
              _DetailsRow(
                label: 'Dates',
                value:
                    '${_date(booking.pickupDate)} → ${_date(booking.returnDate)}',
              ),
              _DetailsRow(
                label: 'Passengers',
                value: '${booking.passengers}',
              ),
              _DetailsRow(
                label: 'Hire type',
                value: booking.hireTypeLabel,
              ),
              _DetailsRow(
                label: 'Daily rate',
                value:
                    '${booking.currency} ${_money(booking.pricePerDay)}',
              ),
              _DetailsRow(
                label: 'Estimated total',
                value:
                    '${booking.currency} ${_money(booking.estimatedTotal)}',
                last: true,
              ),
            ],
          ),
          if ((booking.operatorNotes ?? '')
              .trim()
              .isNotEmpty) ...[
            const SizedBox(height: 14),
            _NoteCard(
              title: 'Provider Note',
              text: booking.operatorNotes!.trim(),
            ),
          ],
          if ((booking.specialRequests ?? '')
              .trim()
              .isNotEmpty) ...[
            const SizedBox(height: 14),
            _NoteCard(
              title: 'Your Request',
              text:
                  booking.specialRequests!.trim(),
            ),
          ],
        ],
      ),
      bottomNavigationBar: onCancel == null
          ? null
          : SafeArea(
              top: false,
              minimum: const EdgeInsets.fromLTRB(
                16,
                8,
                16,
                12,
              ),
              child: SizedBox(
                height: 52,
                child: OutlinedButton(
                  onPressed: () async {
                    await onCancel!();

                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor:
                        _TouristBookingsHubPageState
                            ._secondary,
                    side: const BorderSide(
                      color:
                          _TouristBookingsHubPageState
                              ._secondary,
                    ),
                    shape: const StadiumBorder(),
                  ),
                  child: const Text(
                    'Cancel Booking',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _vehicleDetailsFallback() {
    return Container(
      color: _TouristBookingsHubPageState
          ._primary
          .withOpacity(.08),
      child: const Icon(
        Icons.directions_car_filled_rounded,
        color:
            _TouristBookingsHubPageState._primary,
        size: 52,
      ),
    );
  }
}

class _DetailsHero extends StatelessWidget {
  const _DetailsHero({
    required this.title,
    required this.reference,
    required this.status,
    required this.amount,
  });

  final String title;
  final String reference;
  final String status;
  final String amount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        color:
            _TouristBookingsHubPageState._primary,
        borderRadius: BorderRadius.circular(27),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          _StatusPill(
            status: status,
            onDark: true,
          ),
          const SizedBox(height: 11),
          Text(
            title,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            reference,
            style: TextStyle(
              color: Colors.white.withOpacity(.65),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            amount,
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailsCard extends StatelessWidget {
  const _DetailsCard({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        17,
        16,
        17,
        10,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color:
                  _TouristBookingsHubPageState
                      ._primary,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}

class _DetailsRow extends StatelessWidget {
  const _DetailsRow({
    required this.label,
    required this.value,
    this.last = false,
  });

  final String label;
  final String value;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding:
              const EdgeInsets.symmetric(vertical: 9),
          child: Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 105,
                child: Text(
                  label,
                  style: const TextStyle(
                    color:
                        _TouristBookingsHubPageState
                            ._muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  value,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color:
                        _TouristBookingsHubPageState
                            ._ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (!last)
          Divider(
            height: 1,
            color: _TouristBookingsHubPageState
                ._primary
                .withOpacity(.06),
          ),
      ],
    );
  }
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({
    required this.title,
    required this.text,
  });

  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
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
            title,
            style: const TextStyle(
              color:
                  _TouristBookingsHubPageState
                      ._primary,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            text,
            style: const TextStyle(
              color:
                  _TouristBookingsHubPageState._muted,
              height: 1.48,
            ),
          ),
        ],
      ),
    );
  }
}

class _FactLine extends StatelessWidget {
  const _FactLine({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 16,
          color:
              _TouristBookingsHubPageState._primary,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style:
                Theme.of(context).textTheme.bodySmall
                    ?.copyWith(
              color:
                  _TouristBookingsHubPageState._muted,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.status,
    this.onDark = false,
  });

  final String status;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'confirmed' =>
        _TouristBookingsHubPageState._primary,
      'pending' =>
        _TouristBookingsHubPageState._secondary,
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
        color: onDark
            ? Colors.white.withOpacity(.16)
            : color.withOpacity(.09),
        borderRadius: BorderRadius.circular(999),
        border: onDark
            ? Border.all(
                color: Colors.white.withOpacity(.16),
              )
            : null,
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: onDark ? Colors.white : color,
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
                    _TouristBookingsHubPageState
                        ._primary
                        .withOpacity(.07),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color:
                    _TouristBookingsHubPageState
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
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(
                color:
                    _TouristBookingsHubPageState._muted,
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
            const Icon(
              Icons.cloud_off_rounded,
              color:
                  _TouristBookingsHubPageState
                      ._secondary,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                backgroundColor:
                    _TouristBookingsHubPageState
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

String _safariDateRange(
  String? start,
  String? end,
) {
  final startText = start?.trim() ?? '';
  final endText = end?.trim() ?? '';

  if (startText.isEmpty) {
    return 'Travel dates to be confirmed';
  }

  if (endText.isEmpty || endText == startText) {
    return startText;
  }

  return '$startText → $endText';
}

String _date(DateTime value) {
  return '${value.day.toString().padLeft(2, '0')}/'
      '${value.month.toString().padLeft(2, '0')}/'
      '${value.year}';
}

String _money(double value) {
  return value.toStringAsFixed(
    value == value.roundToDouble() ? 0 : 2,
  );
}

String _pretty(String value) {
  return value
      .replaceAll('_', ' ')
      .split(' ')
      .map(
        (part) => part.isEmpty
            ? ''
            : '${part[0].toUpperCase()}${part.substring(1)}',
      )
      .join(' ');
}
