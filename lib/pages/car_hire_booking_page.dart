import 'package:flutter/material.dart';

import '../models/car_hire_booking.dart';
import '../models/operator_management.dart';
import '../services/api_exception.dart';
import '../services/car_hire_booking_service.dart';

class CarHireBookingPage extends StatefulWidget {
  const CarHireBookingPage({
    super.key,
    required this.vehicle,
  });

  final CarHireVehicle vehicle;

  @override
  State<CarHireBookingPage> createState() =>
      _CarHireBookingPageState();
}

class _CarHireBookingPageState extends State<CarHireBookingPage> {
  static const _primary = Color(0xFF165B5D);
  static const _secondary = Color(0xFFF46627);
  static const _background = Color(0xFFF4EEE1);
  static const _ink = Color(0xFF17211F);

  final _formKey = GlobalKey<FormState>();

  final _pickupLocation = TextEditingController();
  final _dropoffLocation = TextEditingController();
  final _specialRequests = TextEditingController();

  DateTime? _pickupDate;
  DateTime? _returnDate;
  TimeOfDay? _pickupTime;
  TimeOfDay? _returnTime;

  int _passengers = 1;
  String _hireType = 'with_driver';
  bool _submitting = false;

  CarHireVehicle get vehicle => widget.vehicle;

  @override
  void dispose() {
    _pickupLocation.dispose();
    _dropoffLocation.dispose();
    _specialRequests.dispose();
    super.dispose();
  }

  int get _days {
    if (_pickupDate == null || _returnDate == null) return 1;

    return _returnDate!
            .difference(_pickupDate!)
            .inDays
            .clamp(0, 364) +
        1;
  }

  double get _estimatedTotal =>
      vehicle.pricePerDay * _days;

  Future<void> _pickPickupDate() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 730)),
      initialDate: _pickupDate ?? now,
    );

    if (selected == null || !mounted) return;

    setState(() {
      _pickupDate = selected;
      if (_returnDate != null &&
          _returnDate!.isBefore(selected)) {
        _returnDate = null;
      }
    });
  }

  Future<void> _pickReturnDate() async {
    final now = DateTime.now();
    final first =
        _pickupDate ?? DateTime(now.year, now.month, now.day);

    final selected = await showDatePicker(
      context: context,
      firstDate: first,
      lastDate: now.add(const Duration(days: 730)),
      initialDate: _returnDate ?? first,
    );

    if (selected == null || !mounted) return;

    setState(() => _returnDate = selected);
  }

  Future<void> _pickPickupTime() async {
    final selected = await showTimePicker(
      context: context,
      initialTime:
          _pickupTime ?? const TimeOfDay(hour: 8, minute: 0),
    );

    if (selected != null && mounted) {
      setState(() => _pickupTime = selected);
    }
  }

  Future<void> _pickReturnTime() async {
    final selected = await showTimePicker(
      context: context,
      initialTime:
          _returnTime ?? const TimeOfDay(hour: 17, minute: 0),
    );

    if (selected != null && mounted) {
      setState(() => _returnTime = selected);
    }
  }

  Future<void> _submit() async {
    if (_submitting) return;

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_pickupDate == null || _returnDate == null) {
      _snack('Please choose your pick-up and return dates.');
      return;
    }

    setState(() => _submitting = true);

    try {
      final booking =
          await CarHireBookingService.instance.createBooking(
        vehicle: vehicle,
        pickupDate: _pickupDate!,
        returnDate: _returnDate!,
        pickupLocation: _pickupLocation.text,
        dropoffLocation: _dropoffLocation.text,
        passengers: _passengers,
        hireType: _hireType,
        pickupTime: _apiTime(_pickupTime),
        returnTime: _apiTime(_returnTime),
        specialRequests: _specialRequests.text,
      );

      if (!mounted) return;

      await _showSuccess(booking);

      if (mounted) {
        Navigator.pop(context, booking);
      }
    } on ApiException catch (error) {
      if (mounted) {
        _snack(error.message);
      }
    } catch (_) {
      if (mounted) {
        _snack(
          'The booking request could not be sent. Please try again.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  Future<void> _showSuccess(
    CarHireBooking booking,
  ) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
          ),
          icon: Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: _primary.withOpacity(.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              color: _primary,
              size: 30,
            ),
          ),
          title: const Text(
            'Request Sent',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w900,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Booking ${booking.reference}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _primary,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'The tour operator will confirm vehicle availability for your dates. Your estimated price is not charged yet.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            FilledButton(
              onPressed: () =>
                  Navigator.pop(dialogContext),
              style: FilledButton.styleFrom(
                backgroundColor: _primary,
                shape: const StadiumBorder(),
              ),
              child: const Text('Done'),
            ),
          ],
        );
      },
    );
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Book Vehicle',
          style: TextStyle(
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            18,
            6,
            18,
            126,
          ),
          children: [
            _VehicleSummaryCard(vehicle: vehicle),

            const SizedBox(height: 20),

            const _SectionTitle(
              title: 'Your Trip',
              subtitle:
                  'Choose the dates and times you need the vehicle.',
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _SelectionCard(
                    label: 'Pick-up date',
                    value: _dateText(_pickupDate),
                    icon: Icons.calendar_today_outlined,
                    onTap: _pickPickupDate,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _SelectionCard(
                    label: 'Return date',
                    value: _dateText(_returnDate),
                    icon: Icons.event_available_outlined,
                    onTap: _pickReturnDate,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: _SelectionCard(
                    label: 'Pick-up time',
                    value: _timeText(_pickupTime),
                    icon: Icons.schedule_outlined,
                    onTap: _pickPickupTime,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _SelectionCard(
                    label: 'Return time',
                    value: _timeText(_returnTime),
                    icon: Icons.schedule_outlined,
                    onTap: _pickReturnTime,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            const _SectionTitle(
              title: 'Locations',
              subtitle:
                  'Tell the operator where the vehicle should meet you.',
            ),
            const SizedBox(height: 12),

            _PremiumTextField(
              controller: _pickupLocation,
              label: 'Pick-up location',
              hint: 'e.g. Entebbe International Airport',
              icon: Icons.trip_origin_rounded,
              validator: (value) =>
                  value == null || value.trim().isEmpty
                      ? 'Enter the pick-up location.'
                      : null,
            ),

            const SizedBox(height: 12),

            _PremiumTextField(
              controller: _dropoffLocation,
              label: 'Drop-off location',
              hint: 'Leave blank if same as pick-up',
              icon: Icons.location_on_outlined,
            ),

            const SizedBox(height: 24),

            const _SectionTitle(
              title: 'Hire Preference',
              subtitle:
                  'Choose how you want to use the vehicle.',
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _HireTypeCard(
                    title: 'With Driver',
                    subtitle: 'Safari driver included',
                    selected:
                        _hireType == 'with_driver',
                    onTap: () => setState(
                      () => _hireType = 'with_driver',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _HireTypeCard(
                    title: 'Self Drive',
                    subtitle: 'Subject to approval',
                    selected:
                        _hireType == 'self_drive',
                    onTap: () => setState(
                      () => _hireType = 'self_drive',
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Passengers',
                          style: TextStyle(
                            color: _ink,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Including children',
                          style: TextStyle(
                            color: Color(0xFF737D79),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _passengers > 1
                        ? () => setState(
                              () => _passengers--,
                            )
                        : null,
                    icon: const Icon(
                      Icons.remove_circle_outline,
                    ),
                    color: _primary,
                  ),
                  Text(
                    '$_passengers',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  IconButton(
                    onPressed: vehicle.seats == null ||
                            _passengers < vehicle.seats!
                        ? () => setState(
                              () => _passengers++,
                            )
                        : null,
                    icon: const Icon(
                      Icons.add_circle_outline,
                    ),
                    color: _primary,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            const _SectionTitle(
              title: 'Special Requests',
              subtitle:
                  'Optional details that will help the operator prepare.',
            ),
            const SizedBox(height: 12),

            _PremiumTextField(
              controller: _specialRequests,
              label: 'Trip notes',
              hint:
                  'Route, luggage, border crossing, child seats...',
              icon: Icons.notes_rounded,
              minLines: 4,
              maxLines: 6,
            ),

            const SizedBox(height: 22),

            _PriceSummary(
              vehicle: vehicle,
              days: _days,
              total: _estimatedTotal,
            ),
          ],
        ),
      ),

      bottomNavigationBar: SafeArea(
        top: false,
        minimum:
            const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.12),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: SizedBox(
            height: 54,
            child: FilledButton(
              onPressed: _submitting ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                shape: const StadiumBorder(),
              ),
              child: _submitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Send Booking Request',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  static String _dateText(DateTime? value) {
    if (value == null) return 'Choose date';

    return '${value.day.toString().padLeft(2, '0')}/'
        '${value.month.toString().padLeft(2, '0')}/'
        '${value.year}';
  }

  static String _timeText(TimeOfDay? value) {
    if (value == null) return 'Optional';

    final hour = value.hourOfPeriod == 0
        ? 12
        : value.hourOfPeriod;
    final minute =
        value.minute.toString().padLeft(2, '0');
    final period =
        value.period == DayPeriod.am ? 'AM' : 'PM';

    return '$hour:$minute $period';
  }

  static String? _apiTime(TimeOfDay? value) {
    if (value == null) return null;

    return '${value.hour.toString().padLeft(2, '0')}:'
        '${value.minute.toString().padLeft(2, '0')}';
  }
}

class _VehicleSummaryCard extends StatelessWidget {
  const _VehicleSummaryCard({
    required this.vehicle,
  });

  final CarHireVehicle vehicle;

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF165B5D);

    return Container(
      height: 132,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          SizedBox(
            width: 126,
            height: double.infinity,
            child: vehicle.imageUrl.isEmpty
                ? Container(
                    color: primary.withOpacity(.08),
                    child: const Icon(
                      Icons.directions_car_filled_rounded,
                      color: primary,
                      size: 42,
                    ),
                  )
                : Image.network(
                    vehicle.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        Container(
                      color: primary.withOpacity(.08),
                      child: const Icon(
                        Icons.directions_car_filled_rounded,
                        color: primary,
                        size: 42,
                      ),
                    ),
                  ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    vehicle.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 17,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    vehicle.operatorName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF66716E),
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${vehicle.currency.toUpperCase()} '
                    '${vehicle.pricePerDay.toStringAsFixed(0)} / day',
                    style: const TextStyle(
                      color: primary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style:
              Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: const Color(0xFF165B5D),
                    fontWeight: FontWeight.w900,
                  ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style:
              Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF737D79),
                    height: 1.4,
                  ),
        ),
      ],
    );
  }
}

class _SelectionCard extends StatelessWidget {
  const _SelectionCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color:
                  const Color(0xFF165B5D).withOpacity(.07),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                icon,
                color: const Color(0xFF165B5D),
                size: 19,
              ),
              const SizedBox(height: 9),
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF737D79),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HireTypeCard extends StatelessWidget {
  const _HireTypeCard({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF165B5D);

    return Material(
      color: selected
          ? primary.withOpacity(.07)
          : Colors.white,
      borderRadius: BorderRadius.circular(21),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(21),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(21),
            border: Border.all(
              color: selected
                  ? primary.withOpacity(.35)
                  : primary.withOpacity(.07),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (selected)
                const Align(
                  alignment: Alignment.centerRight,
                  child: Icon(
                    Icons.check_circle_rounded,
                    color: primary,
                    size: 19,
                  ),
                )
              else
                const SizedBox(height: 19),
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF17211F),
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Color(0xFF737D79),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PremiumTextField extends StatelessWidget {
  const _PremiumTextField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.validator,
    this.minLines = 1,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final String? Function(String?)? validator;
  final int minLines;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      minLines: minLines,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        alignLabelWithHint: maxLines > 1,
        prefixIcon: maxLines == 1
            ? Icon(icon)
            : null,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(
            color:
                const Color(0xFF165B5D).withOpacity(.07),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(
            color: Color(0xFF165B5D),
            width: 1.2,
          ),
        ),
      ),
    );
  }
}

class _PriceSummary extends StatelessWidget {
  const _PriceSummary({
    required this.vehicle,
    required this.days,
    required this.total,
  });

  final CarHireVehicle vehicle;
  final int days;
  final double total;

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF165B5D);

    final currency = vehicle.currency.toUpperCase();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: primary,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Booking Estimate',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ),
              Text(
                '$days ${days == 1 ? 'day' : 'days'}',
                style: TextStyle(
                  color: Colors.white.withOpacity(.72),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Text(
                '$currency ${vehicle.pricePerDay.toStringAsFixed(0)} × $days',
                style: TextStyle(
                  color: Colors.white.withOpacity(.72),
                ),
              ),
              const Spacer(),
              Text(
                '$currency ${total.toStringAsFixed(0)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          Divider(
            height: 1,
            color: Colors.white.withOpacity(.16),
          ),
          const SizedBox(height: 11),
          Text(
            'Estimated total only. The tour operator will confirm availability and the final price before the booking is confirmed.',
            style: TextStyle(
              color: Colors.white.withOpacity(.72),
              fontSize: 11.5,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
